using System.IO;
using System.Net.Http;
using System.Text;
using System.Text.Json;
using System.Threading.Channels;
using AemeathDesktopPet.Models;

namespace AemeathDesktopPet.Services;

/// <summary>
/// Google Gemini API chat service with streaming support.
/// Falls back to OfflineResponses when no API key is configured.
/// </summary>
public class GeminiApiService : IChatService
{
    private readonly HttpClient _http;
    private readonly Func<AppConfig> _getConfig;
    private readonly Func<AemeathStats> _getStats;

    private const string BaseUrl = "https://generativelanguage.googleapis.com";
    private const string Model = "gemini-2.5-flash";

    private static readonly JsonSerializerOptions JsonOpts = new()
    {
        PropertyNamingPolicy = JsonNamingPolicy.CamelCase,
    };

    public GeminiApiService(Func<AppConfig> getConfig, Func<AemeathStats> getStats)
    {
        _getConfig = getConfig;
        _getStats = getStats;
        _http = new HttpClient
        {
            BaseAddress = new Uri(BaseUrl),
            Timeout = TimeSpan.FromSeconds(30)
        };
    }

    public bool IsAvailable => !string.IsNullOrWhiteSpace(_getConfig().GeminiApiKey);

    public async Task<string> SendMessageAsync(string userMessage, IReadOnlyList<ChatMessage> history)
    {
        if (!IsAvailable)
            return OfflineResponses.GetContextual(_getStats(), DateTime.Now);

        try
        {
            var payload = BuildPayload(userMessage, history);
            var response = await PostAsync(payload, stream: false);
            return ExtractContent(response);
        }
        catch
        {
            return OfflineResponses.GetContextual(_getStats(), DateTime.Now);
        }
    }

    public async Task<string> SendMessageAsync(string userMessage, IReadOnlyList<ChatMessage> history, byte[]? screenshot)
    {
        if (!IsAvailable)
            return OfflineResponses.GetContextual(_getStats(), DateTime.Now);

        try
        {
            var payload = BuildPayload(userMessage, history, screenshot);
            var response = await PostAsync(payload, stream: false);
            return ExtractContent(response);
        }
        catch
        {
            return OfflineResponses.GetContextual(_getStats(), DateTime.Now);
        }
    }

    public async IAsyncEnumerable<string> StreamMessageAsync(
        string userMessage,
        IReadOnlyList<ChatMessage> history)
    {
        await foreach (var chunk in StreamMessageAsync(userMessage, history, null))
            yield return chunk;
    }

    public async IAsyncEnumerable<string> StreamMessageAsync(
        string userMessage,
        IReadOnlyList<ChatMessage> history,
        byte[]? screenshot)
    {
        if (!IsAvailable)
        {
            yield return OfflineResponses.GetContextual(_getStats(), DateTime.Now);
            yield break;
        }

        var channel = Channel.CreateUnbounded<string>();

        _ = Task.Run(async () =>
        {
            HttpResponseMessage? httpResponse = null;
            try
            {
                var config = _getConfig();
                string payload = BuildPayload(userMessage, history, screenshot);
                var url = $"/v1beta/models/{Model}:streamGenerateContent?alt=sse&key={config.GeminiApiKey}";
                var request = new HttpRequestMessage(HttpMethod.Post, url)
                {
                    Content = new StringContent(payload, Encoding.UTF8, "application/json")
                };

                httpResponse = await _http.SendAsync(request, HttpCompletionOption.ResponseHeadersRead);
                httpResponse.EnsureSuccessStatusCode();

                using var stream = await httpResponse.Content.ReadAsStreamAsync();
                using var reader = new StreamReader(stream);

                while (!reader.EndOfStream)
                {
                    var line = await reader.ReadLineAsync();
                    if (line is null)
                        break;

                    if (line.StartsWith("data: "))
                    {
                        var data = line["data: ".Length..];
                        if (data == "[DONE]")
                            break;

                        try
                        {
                            using var doc = JsonDocument.Parse(data);
                            var root = doc.RootElement;
                            if (root.TryGetProperty("candidates", out var candidates) &&
                                candidates.GetArrayLength() > 0)
                            {
                                var candidate = candidates[0];
                                if (candidate.TryGetProperty("content", out var content) &&
                                    content.TryGetProperty("parts", out var parts) &&
                                    parts.GetArrayLength() > 0)
                                {
                                    var text = parts[0].GetProperty("text").GetString();
                                    if (!string.IsNullOrEmpty(text))
                                        await channel.Writer.WriteAsync(text);
                                }
                            }
                        }
                        catch { /* skip malformed SSE events */ }
                    }
                }
            }
            catch
            {
                await channel.Writer.WriteAsync(
                    OfflineResponses.GetContextual(_getStats(), DateTime.Now));
            }
            finally
            {
                httpResponse?.Dispose();
                channel.Writer.Complete();
            }
        });

        await foreach (var chunk in channel.Reader.ReadAllAsync())
        {
            yield return chunk;
        }
    }

    private string BuildPayload(string userMessage, IReadOnlyList<ChatMessage> history, byte[]? screenshot = null)
    {
        var config = _getConfig();
        var stats = _getStats();
        var systemPrompt = ChatPromptBuilder.BuildSystemPrompt(stats, config.CatName);

        // Build contents array (Gemini format: role "user" / "model")
        var contents = new List<object>();
        foreach (var msg in history)
        {
            var role = msg.Role == "assistant" ? "model" : "user";
            contents.Add(new { role, parts = new object[] { new { text = msg.Content } } });
        }

        // Build user message parts (with optional screenshot)
        var userParts = new List<object>();
        if (screenshot is { Length: > 0 })
        {
            userParts.Add(new
            {
                inlineData = new
                {
                    mimeType = "image/jpeg",
                    data = Convert.ToBase64String(screenshot)
                }
            });
        }
        userParts.Add(new { text = userMessage });

        contents.Add(new { role = "user", parts = userParts });

        var payload = new
        {
            systemInstruction = new { parts = new object[] { new { text = systemPrompt } } },
            contents,
            generationConfig = new
            {
                maxOutputTokens = 300,
                temperature = 0.8,
            }
        };

        return JsonSerializer.Serialize(payload, JsonOpts);
    }

    private async Task<string> PostAsync(string payload, bool stream)
    {
        var config = _getConfig();
        var endpoint = stream
            ? $"/v1beta/models/{Model}:streamGenerateContent?alt=sse&key={config.GeminiApiKey}"
            : $"/v1beta/models/{Model}:generateContent?key={config.GeminiApiKey}";

        var request = new HttpRequestMessage(HttpMethod.Post, endpoint)
        {
            Content = new StringContent(payload, Encoding.UTF8, "application/json")
        };

        var response = await _http.SendAsync(request);
        response.EnsureSuccessStatusCode();
        return await response.Content.ReadAsStringAsync();
    }

    private static string ExtractContent(string json)
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
                {
                    return parts[0].GetProperty("text").GetString() ?? "";
                }
            }
        }
        catch { }
        return "";
    }
}
