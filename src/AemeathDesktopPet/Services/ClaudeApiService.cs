using System.IO;
using System.Net.Http;
using System.Text;
using System.Text.Json;
using System.Threading.Channels;
using AemeathDesktopPet.Models;

namespace AemeathDesktopPet.Services;

/// <summary>
/// Claude API chat service with streaming support.
/// Falls back to OfflineResponses when no API key is configured.
/// </summary>
public class ClaudeApiService : IChatService
{
    private readonly HttpClient _http;
    private readonly Func<AppConfig> _getConfig;
    private readonly Func<AemeathStats> _getStats;

    private static readonly JsonSerializerOptions JsonOpts = new()
    {
        PropertyNamingPolicy = JsonNamingPolicy.CamelCase,
    };

    public ClaudeApiService(Func<AppConfig> getConfig, Func<AemeathStats> getStats)
    {
        _getConfig = getConfig;
        _getStats = getStats;
        _http = new HttpClient
        {
            BaseAddress = new Uri("https://api.anthropic.com"),
            Timeout = TimeSpan.FromSeconds(30)
        };
    }

    public bool IsAvailable => !string.IsNullOrWhiteSpace(_getConfig().ApiKey);

    public async Task<string> SendMessageAsync(string userMessage, IReadOnlyList<ChatMessage> history)
    {
        if (!IsAvailable)
            return OfflineResponses.GetContextual(_getStats(), DateTime.Now);

        try
        {
            var payload = BuildPayload(userMessage, history, stream: false);
            var response = await PostAsync(payload);
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
                string payload = BuildPayload(userMessage, history, stream: true);
                var request = new HttpRequestMessage(HttpMethod.Post, "/v1/messages")
                {
                    Content = new StringContent(payload, Encoding.UTF8, "application/json")
                };
                request.Headers.Add("x-api-key", config.ApiKey);
                request.Headers.Add("anthropic-version", "2023-06-01");

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
                            if (root.TryGetProperty("type", out var typeProp))
                            {
                                if (typeProp.GetString() == "content_block_delta" &&
                                    root.TryGetProperty("delta", out var delta) &&
                                    delta.TryGetProperty("text", out var text))
                                {
                                    await channel.Writer.WriteAsync(text.GetString() ?? "");
                                }
                            }
                        }
                        catch { /* skip malformed SSE events */ }
                    }
                }
            }
            catch
            {
                // On error, yield an offline fallback
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

    private string BuildPayload(string userMessage, IReadOnlyList<ChatMessage> history, bool stream, byte[]? screenshot = null)
    {
        var config = _getConfig();
        var stats = _getStats();
        var systemPrompt = ChatPromptBuilder.BuildSystemPrompt(stats, config.CatName);

        var messages = new List<object>();
        foreach (var msg in history)
        {
            messages.Add(new { role = msg.Role, content = msg.Content });
        }

        // Build user message content — with optional screenshot
        if (screenshot is { Length: > 0 })
        {
            var contentParts = new object[]
            {
                new { type = "image", source = new { type = "base64", media_type = "image/jpeg", data = Convert.ToBase64String(screenshot) } },
                new { type = "text", text = userMessage }
            };
            messages.Add(new { role = "user", content = contentParts });
        }
        else
        {
            messages.Add(new { role = "user", content = userMessage });
        }

        var payload = new
        {
            model = "claude-sonnet-4-5-20250929",
            max_tokens = 300,
            system = systemPrompt,
            messages,
            stream,
        };

        return JsonSerializer.Serialize(payload, JsonOpts);
    }

    private async Task<string> PostAsync(string payload)
    {
        var config = _getConfig();
        var request = new HttpRequestMessage(HttpMethod.Post, "/v1/messages")
        {
            Content = new StringContent(payload, Encoding.UTF8, "application/json")
        };
        request.Headers.Add("x-api-key", config.ApiKey);
        request.Headers.Add("anthropic-version", "2023-06-01");

        var response = await _http.SendAsync(request);
        response.EnsureSuccessStatusCode();
        return await response.Content.ReadAsStringAsync();
    }

    private static string ExtractContent(string json)
    {
        try
        {
            using var doc = JsonDocument.Parse(json);
            var content = doc.RootElement.GetProperty("content");
            if (content.GetArrayLength() > 0)
            {
                return content[0].GetProperty("text").GetString() ?? "";
            }
        }
        catch { }
        return "";
    }

    public async Task<string> SendMessageAsync(string userMessage, IReadOnlyList<ChatMessage> history, byte[]? screenshot)
    {
        if (!IsAvailable)
            return OfflineResponses.GetContextual(_getStats(), DateTime.Now);

        try
        {
            var payload = BuildPayload(userMessage, history, stream: false, screenshot);
            var response = await PostAsync(payload);
            return ExtractContent(response);
        }
        catch
        {
            return OfflineResponses.GetContextual(_getStats(), DateTime.Now);
        }
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
                string payload = BuildPayload(userMessage, history, stream: true, screenshot);
                var request = new HttpRequestMessage(HttpMethod.Post, "/v1/messages")
                {
                    Content = new StringContent(payload, Encoding.UTF8, "application/json")
                };
                request.Headers.Add("x-api-key", config.ApiKey);
                request.Headers.Add("anthropic-version", "2023-06-01");

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
                            if (root.TryGetProperty("type", out var typeProp))
                            {
                                if (typeProp.GetString() == "content_block_delta" &&
                                    root.TryGetProperty("delta", out var delta) &&
                                    delta.TryGetProperty("text", out var text))
                                {
                                    await channel.Writer.WriteAsync(text.GetString() ?? "");
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
}
