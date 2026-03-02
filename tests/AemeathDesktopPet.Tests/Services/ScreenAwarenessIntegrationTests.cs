using System.Net;
using System.Net.Http;
using System.Text.Json;
using AemeathDesktopPet.Engine;
using AemeathDesktopPet.Models;
using AemeathDesktopPet.Services;

namespace AemeathDesktopPet.Tests.Services;

/// <summary>
/// Integration tests for the Screen Awareness privacy pipeline.
/// Uses mock HTTP handlers to simulate vision API responses and tests
/// that components work together correctly.
/// </summary>
public class ScreenAwarenessIntegrationTests : IDisposable
{
    private readonly string _tempDir;

    public ScreenAwarenessIntegrationTests()
    {
        _tempDir = Path.Combine(Path.GetTempPath(), "AemeathInteg_" + Guid.NewGuid().ToString("N")[..8]);
    }

    public void Dispose()
    {
        if (Directory.Exists(_tempDir))
            Directory.Delete(_tempDir, recursive: true);
    }

    // --- Config Persistence Roundtrip ---

    [Fact]
    public void ConfigRoundTrip_PrivacyLayerSettings_Persist()
    {
        var svc = new ConfigService(_tempDir);
        svc.Load();

        svc.Config.ScreenAwareness.EnableProtectedWindowCheck = false;
        svc.Config.ScreenAwareness.EnablePrivacyDownscale = false;
        svc.Config.ScreenAwareness.PrivacyDownscaleMaxWidth = 320;
        svc.Config.ScreenAwareness.EnableResponsePiiScan = false;
        svc.Save();

        var svc2 = new ConfigService(_tempDir);
        svc2.Load();

        Assert.False(svc2.Config.ScreenAwareness.EnableProtectedWindowCheck);
        Assert.False(svc2.Config.ScreenAwareness.EnablePrivacyDownscale);
        Assert.Equal(320, svc2.Config.ScreenAwareness.PrivacyDownscaleMaxWidth);
        Assert.False(svc2.Config.ScreenAwareness.EnableResponsePiiScan);
    }

    [Fact]
    public void ConfigRoundTrip_OllamaSettings_Persist()
    {
        var svc = new ConfigService(_tempDir);
        svc.Load();

        svc.Config.ScreenAwareness.VisionProvider = "ollama";
        svc.Config.ScreenAwareness.OllamaBaseUrl = "http://gpu-server:11434";
        svc.Config.ScreenAwareness.OllamaModelName = "llava:13b";
        svc.Save();

        var svc2 = new ConfigService(_tempDir);
        svc2.Load();

        Assert.Equal("ollama", svc2.Config.ScreenAwareness.VisionProvider);
        Assert.Equal("http://gpu-server:11434", svc2.Config.ScreenAwareness.OllamaBaseUrl);
        Assert.Equal("llava:13b", svc2.Config.ScreenAwareness.OllamaModelName);
    }

    [Fact]
    public void ConfigRoundTrip_HybridSettings_Persist()
    {
        var svc = new ConfigService(_tempDir);
        svc.Load();

        svc.Config.ScreenAwareness.VisionProvider = "local_hybrid";
        svc.Config.ScreenAwareness.HybridCloudProvider = "claude";
        svc.Config.ScreenAwareness.HybridCloudApiKey = "sk-hybrid-key";
        svc.Save();

        var svc2 = new ConfigService(_tempDir);
        svc2.Load();

        Assert.Equal("local_hybrid", svc2.Config.ScreenAwareness.VisionProvider);
        Assert.Equal("claude", svc2.Config.ScreenAwareness.HybridCloudProvider);
        Assert.Equal("sk-hybrid-key", svc2.Config.ScreenAwareness.HybridCloudApiKey);
    }

    [Fact]
    public void ConfigRoundTrip_ExpandedBlacklist_Persist()
    {
        var svc = new ConfigService(_tempDir);
        svc.Load();

        // Default should have 17 entries
        Assert.Equal(17, svc.Config.ScreenAwareness.BlacklistedApps.Count);

        // Add a custom entry
        svc.Config.ScreenAwareness.BlacklistedApps.Add("custom.exe:*secret*");
        svc.Save();

        var svc2 = new ConfigService(_tempDir);
        svc2.Load();

        Assert.Equal(18, svc2.Config.ScreenAwareness.BlacklistedApps.Count);
        Assert.Contains("custom.exe:*secret*", svc2.Config.ScreenAwareness.BlacklistedApps);
        Assert.Contains("bitwarden.exe", svc2.Config.ScreenAwareness.BlacklistedApps);
    }

    // --- Mock HTTP Provider Tests ---

    [Fact]
    public async Task GeminiProvider_ParsesResponseCorrectly()
    {
        var geminiResponse = """
        {
            "candidates": [{
                "content": {
                    "parts": [{ "text": "Looks like you're coding in an IDE!" }]
                }
            }]
        }
        """;

        var handler = new MockHttpHandler(geminiResponse);
        var config = new ScreenAwarenessConfig
        {
            Enabled = true,
            VisionProvider = "gemini",
            VisionApiKey = "test-key"
        };

        var svc = new ScreenAwarenessService(
            () => config, () => new AemeathStats(), () => "Kuro",
            new EnvironmentDetector(), new HttpClient(handler));

        var result = await svc.AnalyzeTextWithGemini("system prompt", "what do you see?", "test-key");
        Assert.Equal("Looks like you're coding in an IDE!", result);
    }

    [Fact]
    public async Task ClaudeProvider_ParsesResponseCorrectly()
    {
        var claudeResponse = """
        {
            "content": [{ "type": "text", "text": "Oh you're watching a video!" }]
        }
        """;

        var handler = new MockHttpHandler(claudeResponse);
        var config = new ScreenAwarenessConfig
        {
            Enabled = true,
            VisionProvider = "claude",
            VisionApiKey = "test-key"
        };

        var svc = new ScreenAwarenessService(
            () => config, () => new AemeathStats(), () => "Kuro",
            new EnvironmentDetector(), new HttpClient(handler));

        var result = await svc.AnalyzeTextWithClaude("system prompt", "what do you see?", "test-key");
        Assert.Equal("Oh you're watching a video!", result);
    }

    [Fact]
    public void OllamaResponseParsing_ComplexResponse()
    {
        var json = """
        {
            "model": "qwen2.5vl:3b",
            "created_at": "2024-01-01T00:00:00Z",
            "message": {
                "role": "assistant",
                "content": "The user appears to be writing code in a dark-themed IDE."
            },
            "done": true,
            "total_duration": 5000000000
        }
        """;
        var result = ScreenAwarenessService.ExtractOllamaContent(json);
        Assert.Equal("The user appears to be writing code in a dark-themed IDE.", result);
    }

    [Fact]
    public void OllamaResponseParsing_UnicodeContent()
    {
        var json = """{"message":{"role":"assistant","content":"用户正在写代码！看起来很有趣~"},"done":true}""";
        var result = ScreenAwarenessService.ExtractOllamaContent(json);
        Assert.Equal("用户正在写代码！看起来很有趣~", result);
    }

    // --- Provider Config Integration ---

    [Fact]
    public void ProviderConfig_AllProvidersHaveCorrectKeyRequirements()
    {
        // Gemini: needs VisionApiKey
        var gemini = new ScreenAwarenessConfig { VisionProvider = "gemini", VisionApiKey = "key" };
        Assert.True(ScreenAwarenessService.IsProviderConfigured(gemini));
        gemini.VisionApiKey = "";
        Assert.False(ScreenAwarenessService.IsProviderConfigured(gemini));

        // Claude: needs VisionApiKey
        var claude = new ScreenAwarenessConfig { VisionProvider = "claude", VisionApiKey = "key" };
        Assert.True(ScreenAwarenessService.IsProviderConfigured(claude));
        claude.VisionApiKey = "";
        Assert.False(ScreenAwarenessService.IsProviderConfigured(claude));

        // Ollama: no key needed
        var ollama = new ScreenAwarenessConfig { VisionProvider = "ollama", VisionApiKey = "" };
        Assert.True(ScreenAwarenessService.IsProviderConfigured(ollama));

        // Hybrid: needs HybridCloudApiKey (not VisionApiKey)
        var hybrid = new ScreenAwarenessConfig
        {
            VisionProvider = "local_hybrid",
            VisionApiKey = "", // this should NOT matter
            HybridCloudApiKey = "key"
        };
        Assert.True(ScreenAwarenessService.IsProviderConfigured(hybrid));
        hybrid.HybridCloudApiKey = "";
        Assert.False(ScreenAwarenessService.IsProviderConfigured(hybrid));
    }

    [Fact]
    public void ProviderConfig_WhitespaceKeyTreatedAsEmpty()
    {
        var config = new ScreenAwarenessConfig { VisionProvider = "gemini", VisionApiKey = "   " };
        Assert.False(ScreenAwarenessService.IsProviderConfigured(config));

        var hybrid = new ScreenAwarenessConfig { VisionProvider = "local_hybrid", HybridCloudApiKey = "  \t  " };
        Assert.False(ScreenAwarenessService.IsProviderConfigured(hybrid));
    }

    // --- Blacklist Integration ---

    [Fact]
    public void Blacklist_AllDefaultPatterns_MatchCorrectly()
    {
        var defaults = new ScreenAwarenessConfig();

        // Password managers should block unconditionally
        // (We test glob matching since IsBlacklisted requires Win32)
        Assert.True(ScreenAwarenessService.MatchGlob("Chase Bank - Personal", "*bank*"));
        Assert.True(ScreenAwarenessService.MatchGlob("Login to your account", "*login*"));
        Assert.True(ScreenAwarenessService.MatchGlob("Change Password", "*password*"));
        Assert.True(ScreenAwarenessService.MatchGlob("PayPal - Send Money", "*paypal*"));
        Assert.True(ScreenAwarenessService.MatchGlob("My Bank Account - Chrome", "*account*"));

        // Normal titles should NOT match
        Assert.False(ScreenAwarenessService.MatchGlob("Visual Studio Code", "*bank*"));
        Assert.False(ScreenAwarenessService.MatchGlob("YouTube - Music Video", "*login*"));
    }

    // --- Mock HTTP Handler ---

    private class MockHttpHandler : HttpMessageHandler
    {
        private readonly string _responseBody;
        private readonly HttpStatusCode _statusCode;

        public MockHttpHandler(string responseBody, HttpStatusCode statusCode = HttpStatusCode.OK)
        {
            _responseBody = responseBody;
            _statusCode = statusCode;
        }

        protected override Task<HttpResponseMessage> SendAsync(HttpRequestMessage request, CancellationToken ct)
        {
            return Task.FromResult(new HttpResponseMessage(_statusCode)
            {
                Content = new StringContent(_responseBody, System.Text.Encoding.UTF8, "application/json")
            });
        }
    }
}
