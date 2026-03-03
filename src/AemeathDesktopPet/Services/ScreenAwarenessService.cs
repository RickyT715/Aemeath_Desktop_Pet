using System.Diagnostics;
using System.Drawing;
using System.Drawing.Imaging;
using System.IO;
using System.Net.Http;
using System.Text;
using System.Text.Json;
using AemeathDesktopPet.Engine;
using AemeathDesktopPet.Models;

namespace AemeathDesktopPet.Services;

/// <summary>
/// Screen awareness service — periodically captures screenshots, analyzes via vision AI,
/// and caches commentary for idle chatter consumption.
/// Privacy pipeline: Layer 0 (protected windows) → Layer 1 (app blacklist) → fullscreen skip →
/// budget check → Layer 3 (privacy downscale) → perceptual hash dedup → vision analysis →
/// Layer 7 (PII scan).
/// </summary>
public class ScreenAwarenessService : IScreenAwarenessService
{
    private readonly Func<ScreenAwarenessConfig> _getConfig;
    private readonly Func<AemeathStats> _getStats;
    private readonly Func<string> _getCatName;
    private readonly EnvironmentDetector _environment;
    private readonly HttpClient _http;

    private CancellationTokenSource? _cts;
    private Task? _timerTask;
    private string? _lastCommentary;
    private ulong _lastHash;
    private double _monthlySpend;
    private DateTime _monthlySpendResetDate = DateTime.UtcNow;

    private static readonly JsonSerializerOptions JsonOpts = new()
    {
        PropertyNamingPolicy = JsonNamingPolicy.CamelCase,
    };

    public ScreenAwarenessService(
        Func<ScreenAwarenessConfig> getConfig,
        Func<AemeathStats> getStats,
        Func<string> getCatName,
        EnvironmentDetector environment)
    {
        _getConfig = getConfig;
        _getStats = getStats;
        _getCatName = getCatName;
        _environment = environment;
        _http = new HttpClient { Timeout = TimeSpan.FromSeconds(30) };
    }

    // Internal constructor for unit testing (injectable HttpClient)
    internal ScreenAwarenessService(
        Func<ScreenAwarenessConfig> getConfig,
        Func<AemeathStats> getStats,
        Func<string> getCatName,
        EnvironmentDetector environment,
        HttpClient httpClient)
    {
        _getConfig = getConfig;
        _getStats = getStats;
        _getCatName = getCatName;
        _environment = environment;
        _http = httpClient;
    }

    public bool IsEnabled => _getConfig().Enabled;

    public string? ConsumeLatestCommentary()
    {
        var result = _lastCommentary;
        _lastCommentary = null;
        return result;
    }

    public void Start()
    {
        if (_timerTask != null)
            return;
        _cts = new CancellationTokenSource();
        _timerTask = TimerLoop(_cts.Token);
    }

    public void Stop()
    {
        _cts?.Cancel();
        try
        { _timerTask?.Wait(); }
        catch { }
        _cts?.Dispose();
        _cts = null;
        _timerTask = null;
    }

    public void Dispose()
    {
        Stop();
        _http.Dispose();
    }

    public async Task<string?> CaptureAndCommentAsync()
    {
        if (!IsEnabled)
            return null;
        var config = _getConfig();
        if (!IsProviderConfigured(config))
            return null;

        try
        {
            // Layer 0: Protected window check
            if (config.EnableProtectedWindowCheck && _environment.HasProtectedWindowVisible())
                return null;

            // Layer 3: Privacy downscale
            int captureWidth = config.EnablePrivacyDownscale ? config.PrivacyDownscaleMaxWidth : 768;
            var screenshot = ScreenCaptureService.CaptureAndDownscale(captureWidth);

            var commentary = await AnalyzeScreenshot(screenshot, config);

            // Layer 7: PII scan
            if (config.EnableResponsePiiScan && PiiScanner.ContainsPii(commentary))
                return null;

            return commentary;
        }
        catch
        {
            return null;
        }
    }

    private async Task TimerLoop(CancellationToken ct)
    {
        while (!ct.IsCancellationRequested)
        {
            var config = _getConfig();
            try
            {
                await Task.Delay(config.IntervalSeconds * 1000, ct);
            }
            catch (OperationCanceledException) { break; }

            if (!IsEnabled)
                continue;
            if (!IsProviderConfigured(config))
                continue;

            // Layer 0: Protected window check
            if (config.EnableProtectedWindowCheck)
            {
                try
                {
                    if (_environment.HasProtectedWindowVisible())
                        continue;
                }
                catch { /* ignore Win32 errors */ }
            }

            // Layer 1: App/title blacklist (existing)
            if (IsBlacklisted(config))
                continue;

            // Fullscreen skip (existing)
            if (_environment.IsFullscreenAppActive())
                continue;

            // Budget check (existing)
            if (IsOverBudget(config))
                continue;

            try
            {
                // Layer 3: Privacy downscale (configurable resolution)
                int captureWidth = config.EnablePrivacyDownscale ? config.PrivacyDownscaleMaxWidth : 768;
                var screenshot = ScreenCaptureService.CaptureAndDownscale(captureWidth);

                // Perceptual hash dedup (existing)
                if (!HasScreenChanged(screenshot))
                    continue;

                var commentary = await AnalyzeScreenshot(screenshot, config);
                if (!string.IsNullOrEmpty(commentary))
                {
                    // Layer 7: PII scan
                    if (config.EnableResponsePiiScan && PiiScanner.ContainsPii(commentary))
                        continue;

                    _lastCommentary = commentary;
                    TrackCost(screenshot.Length, config);
                }
            }
            catch
            {
                // Silently skip on any error — will retry next interval
            }
        }
    }

    // --- Provider Configuration Check ---

    internal static bool IsProviderConfigured(ScreenAwarenessConfig config)
    {
        // Ollama and local_hybrid don't need VisionApiKey
        if (config.VisionProvider is "ollama")
            return true;

        if (config.VisionProvider is "local_hybrid")
        {
            // Hybrid needs a cloud API key for the text-only step
            return !string.IsNullOrWhiteSpace(config.HybridCloudApiKey);
        }

        // Cloud providers (gemini, claude) need VisionApiKey
        return !string.IsNullOrWhiteSpace(config.VisionApiKey);
    }

    // --- Tier 1: App Blacklist ---

    internal bool IsBlacklisted(ScreenAwarenessConfig config)
    {
        var (processName, title) = _environment.GetForegroundAppInfo();
        if (string.IsNullOrEmpty(processName))
            return false;

        foreach (var entry in config.BlacklistedApps)
        {
            var parts = entry.Split(':', 2);
            var appPattern = parts[0].Trim();

            // Match process name (case-insensitive)
            bool processMatch = string.Equals(processName + ".exe", appPattern, StringComparison.OrdinalIgnoreCase)
                || string.Equals(processName, appPattern, StringComparison.OrdinalIgnoreCase);

            if (!processMatch)
                continue;

            // If no title pattern, block all windows of this process
            if (parts.Length < 2)
                return true;

            // Match title pattern (glob with * wildcards)
            var titlePattern = parts[1].Trim();
            if (MatchGlob(title, titlePattern))
                return true;
        }

        return false;
    }

    internal static bool MatchGlob(string input, string pattern)
    {
        // Simple glob: * matches any sequence of characters
        if (pattern == "*")
            return true;

        var parts = pattern.Split('*');
        int pos = 0;

        for (int i = 0; i < parts.Length; i++)
        {
            var part = parts[i];
            if (string.IsNullOrEmpty(part))
                continue;

            int idx = input.IndexOf(part, pos, StringComparison.OrdinalIgnoreCase);
            if (idx < 0)
                return false;

            // First segment must match at start (unless pattern starts with *)
            if (i == 0 && !pattern.StartsWith("*") && idx != 0)
                return false;

            pos = idx + part.Length;
        }

        // Last segment must match at end (unless pattern ends with *)
        if (parts.Length > 0 && !pattern.EndsWith("*"))
        {
            var lastPart = parts[^1];
            if (!string.IsNullOrEmpty(lastPart))
                return input.EndsWith(lastPart, StringComparison.OrdinalIgnoreCase);
        }

        return true;
    }

    // --- Perceptual Hash (change detection) ---

    internal bool HasScreenChanged(byte[] screenshot)
    {
        var hash = ComputePerceptualHash(screenshot);
        var distance = HammingDistance(_lastHash, hash);
        if (distance < 10)
            return false;
        _lastHash = hash;
        return true;
    }

    internal static ulong ComputePerceptualHash(byte[] jpegBytes)
    {
        using var ms = new MemoryStream(jpegBytes);
        using var original = new Bitmap(ms);

        // Downscale to 8x8 grayscale
        using var small = new Bitmap(8, 8, PixelFormat.Format24bppRgb);
        using (var g = Graphics.FromImage(small))
        {
            g.InterpolationMode = System.Drawing.Drawing2D.InterpolationMode.HighQualityBicubic;
            g.DrawImage(original, 0, 0, 8, 8);
        }

        // Compute average brightness
        double total = 0;
        var pixels = new double[64];
        for (int y = 0; y < 8; y++)
        {
            for (int x = 0; x < 8; x++)
            {
                var c = small.GetPixel(x, y);
                double gray = c.R * 0.299 + c.G * 0.587 + c.B * 0.114;
                pixels[y * 8 + x] = gray;
                total += gray;
            }
        }
        double avg = total / 64.0;

        // Build 64-bit hash
        ulong hash = 0;
        for (int i = 0; i < 64; i++)
        {
            if (pixels[i] >= avg)
                hash |= 1UL << i;
        }

        return hash;
    }

    internal static int HammingDistance(ulong a, ulong b)
    {
        ulong xor = a ^ b;
        int count = 0;
        while (xor != 0)
        {
            count++;
            xor &= xor - 1;
        }
        return count;
    }

    // --- Budget Tracking ---

    internal bool IsOverBudget(ScreenAwarenessConfig config)
    {
        // Reset monthly spend on new month
        if (DateTime.UtcNow.Month != _monthlySpendResetDate.Month
            || DateTime.UtcNow.Year != _monthlySpendResetDate.Year)
        {
            _monthlySpend = 0;
            _monthlySpendResetDate = DateTime.UtcNow;
        }

        return _monthlySpend >= config.MonthlyBudgetCap;
    }

    private void TrackCost(int screenshotBytes, ScreenAwarenessConfig config)
    {
        // Rough cost estimate: ~443 tokens per 768px JPEG screenshot
        // Gemini Flash: $0.10/1M input tokens → ~$0.000044/screenshot
        // Claude Haiku: $1.00/1M input → ~$0.000443/screenshot
        // Ollama: $0 (local)
        // Local hybrid: ~$0.000005 (text-only cloud call)
        double costPerShot = config.VisionProvider switch
        {
            "gemini" => 0.000044,
            "ollama" => 0.0,
            "local_hybrid" => 0.000005,
            _ => 0.00133 // Claude Haiku estimate
        };

        _monthlySpend += costPerShot;
    }

    // For testing
    internal double MonthlySpend
    {
        get => _monthlySpend;
        set => _monthlySpend = value;
    }

    // --- Vision API ---

    private async Task<string?> AnalyzeScreenshot(byte[] screenshot, ScreenAwarenessConfig config)
    {
        var stats = _getStats();
        var catName = _getCatName();
        var systemPrompt = ChatPromptBuilder.BuildSystemPrompt(stats, catName);
        var analysisPrompt = config.AnalysisPrompt;

        return config.VisionProvider switch
        {
            "gemini" => await AnalyzeWithGemini(screenshot, systemPrompt, analysisPrompt, config.VisionApiKey),
            "ollama" => await AnalyzeWithOllama(screenshot, systemPrompt, analysisPrompt, config),
            "local_hybrid" => await AnalyzeWithLocalHybrid(screenshot, systemPrompt, analysisPrompt, config),
            _ => await AnalyzeWithClaude(screenshot, systemPrompt, analysisPrompt, config.VisionApiKey),
        };
    }

    private async Task<string?> AnalyzeWithGemini(byte[] screenshot, string systemPrompt, string analysisPrompt, string apiKey)
    {
        var base64 = Convert.ToBase64String(screenshot);
        var payload = new
        {
            systemInstruction = new { parts = new object[] { new { text = systemPrompt } } },
            contents = new[]
            {
                new
                {
                    role = "user",
                    parts = new object[]
                    {
                        new
                        {
                            inlineData = new
                            {
                                mimeType = "image/jpeg",
                                data = base64
                            }
                        },
                        new { text = analysisPrompt }
                    }
                }
            },
            generationConfig = new
            {
                maxOutputTokens = 100,
                temperature = 0.8,
            }
        };

        var json = JsonSerializer.Serialize(payload, JsonOpts);
        var url = $"https://generativelanguage.googleapis.com/v1beta/models/gemini-2.5-flash:generateContent?key={apiKey}";

        var request = new HttpRequestMessage(HttpMethod.Post, url)
        {
            Content = new StringContent(json, Encoding.UTF8, "application/json")
        };

        var response = await _http.SendAsync(request);
        response.EnsureSuccessStatusCode();

        var responseBody = await response.Content.ReadAsStringAsync();
        return ExtractGeminiContent(responseBody);
    }

    private async Task<string?> AnalyzeWithClaude(byte[] screenshot, string systemPrompt, string analysisPrompt, string apiKey)
    {
        var base64 = Convert.ToBase64String(screenshot);
        var payload = new
        {
            model = "claude-haiku-4-5-20251001",
            max_tokens = 100,
            system = systemPrompt,
            messages = new[]
            {
                new
                {
                    role = "user",
                    content = new object[]
                    {
                        new
                        {
                            type = "image",
                            source = new
                            {
                                type = "base64",
                                media_type = "image/jpeg",
                                data = base64
                            }
                        },
                        new { type = "text", text = analysisPrompt }
                    }
                }
            }
        };

        var json = JsonSerializer.Serialize(payload, JsonOpts);
        var request = new HttpRequestMessage(HttpMethod.Post, "https://api.anthropic.com/v1/messages")
        {
            Content = new StringContent(json, Encoding.UTF8, "application/json")
        };
        request.Headers.Add("x-api-key", apiKey);
        request.Headers.Add("anthropic-version", "2023-06-01");

        var response = await _http.SendAsync(request);
        response.EnsureSuccessStatusCode();

        var responseBody = await response.Content.ReadAsStringAsync();
        return ExtractClaudeContent(responseBody);
    }

    // --- Ollama (Local Vision) ---

    private async Task<string?> AnalyzeWithOllama(byte[] screenshot, string systemPrompt, string analysisPrompt, ScreenAwarenessConfig config)
    {
        var base64 = Convert.ToBase64String(screenshot);
        var payload = new
        {
            model = config.OllamaModelName,
            messages = new object[]
            {
                new { role = "system", content = systemPrompt },
                new { role = "user", content = analysisPrompt, images = new[] { base64 } }
            },
            stream = false
        };

        var json = JsonSerializer.Serialize(payload, JsonOpts);
        var url = $"{config.OllamaBaseUrl.TrimEnd('/')}/api/chat";

        var request = new HttpRequestMessage(HttpMethod.Post, url)
        {
            Content = new StringContent(json, Encoding.UTF8, "application/json")
        };

        var response = await _http.SendAsync(request);
        response.EnsureSuccessStatusCode();

        var responseBody = await response.Content.ReadAsStringAsync();
        return ExtractOllamaContent(responseBody);
    }

    // --- Local + Cloud Hybrid ---

    private async Task<string?> AnalyzeWithLocalHybrid(byte[] screenshot, string systemPrompt, string analysisPrompt, ScreenAwarenessConfig config)
    {
        // Step 1: Local Ollama generates a text description (raw pixels never leave device)
        var localDescription = await AnalyzeWithOllama(
            screenshot, "You are a screen content describer. Describe what you see in 2-3 sentences. Do not include any personal information, passwords, or specific text visible on screen.",
            "Describe the general activity shown in this screenshot.", config);

        if (string.IsNullOrEmpty(localDescription))
            return null;

        // Step 2: Text-only cloud call for personality commentary (no image sent)
        var textPrompt = $"{analysisPrompt}\n\nContext from screen observation: {localDescription}";

        return config.HybridCloudProvider switch
        {
            "claude" => await AnalyzeTextWithClaude(systemPrompt, textPrompt, config.HybridCloudApiKey),
            _ => await AnalyzeTextWithGemini(systemPrompt, textPrompt, config.HybridCloudApiKey),
        };
    }

    // Text-only cloud calls (no image) for hybrid mode

    internal async Task<string?> AnalyzeTextWithGemini(string systemPrompt, string textPrompt, string apiKey)
    {
        var payload = new
        {
            systemInstruction = new { parts = new object[] { new { text = systemPrompt } } },
            contents = new[]
            {
                new
                {
                    role = "user",
                    parts = new object[]
                    {
                        new { text = textPrompt }
                    }
                }
            },
            generationConfig = new
            {
                maxOutputTokens = 100,
                temperature = 0.8,
            }
        };

        var json = JsonSerializer.Serialize(payload, JsonOpts);
        var url = $"https://generativelanguage.googleapis.com/v1beta/models/gemini-2.5-flash:generateContent?key={apiKey}";

        var request = new HttpRequestMessage(HttpMethod.Post, url)
        {
            Content = new StringContent(json, Encoding.UTF8, "application/json")
        };

        var response = await _http.SendAsync(request);
        response.EnsureSuccessStatusCode();

        var responseBody = await response.Content.ReadAsStringAsync();
        return ExtractGeminiContent(responseBody);
    }

    internal async Task<string?> AnalyzeTextWithClaude(string systemPrompt, string textPrompt, string apiKey)
    {
        var payload = new
        {
            model = "claude-haiku-4-5-20251001",
            max_tokens = 100,
            system = systemPrompt,
            messages = new[]
            {
                new
                {
                    role = "user",
                    content = textPrompt
                }
            }
        };

        var json = JsonSerializer.Serialize(payload, JsonOpts);
        var request = new HttpRequestMessage(HttpMethod.Post, "https://api.anthropic.com/v1/messages")
        {
            Content = new StringContent(json, Encoding.UTF8, "application/json")
        };
        request.Headers.Add("x-api-key", apiKey);
        request.Headers.Add("anthropic-version", "2023-06-01");

        var response = await _http.SendAsync(request);
        response.EnsureSuccessStatusCode();

        var responseBody = await response.Content.ReadAsStringAsync();
        return ExtractClaudeContent(responseBody);
    }

    // --- Response Parsing ---

    internal static string? ExtractGeminiContent(string json)
    {
        try
        {
            using var doc = JsonDocument.Parse(json);
            var candidates = doc.RootElement.GetProperty("candidates");
            if (candidates.GetArrayLength() > 0)
            {
                var content = candidates[0].GetProperty("content");
                var parts = content.GetProperty("parts");
                if (parts.GetArrayLength() > 0)
                    return parts[0].GetProperty("text").GetString();
            }
        }
        catch { }
        return null;
    }

    internal static string? ExtractClaudeContent(string json)
    {
        try
        {
            using var doc = JsonDocument.Parse(json);
            var content = doc.RootElement.GetProperty("content");
            if (content.GetArrayLength() > 0)
                return content[0].GetProperty("text").GetString();
        }
        catch { }
        return null;
    }

    internal static string? ExtractOllamaContent(string json)
    {
        try
        {
            using var doc = JsonDocument.Parse(json);
            var message = doc.RootElement.GetProperty("message");
            return message.GetProperty("content").GetString();
        }
        catch { }
        return null;
    }
}
