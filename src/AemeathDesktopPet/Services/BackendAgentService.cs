using System.IO;
using System.Net.Http;
using System.Text;
using System.Text.Json;
using System.Threading.Channels;
using AemeathDesktopPet.Models;

namespace AemeathDesktopPet.Services;

/// <summary>
/// Chat service that delegates to the Python FastAPI backend agent.
/// Supports both invoke (single response) and streaming (SSE) modes.
/// </summary>
public class BackendAgentService : IChatService
{
    private readonly BackendProcessManager _backend;
    private readonly HttpClient _http;
    private readonly Func<AemeathStats> _getStats;
    private readonly string _threadId = Guid.NewGuid().ToString("N")[..12];

    private static readonly JsonSerializerOptions JsonOpts = new()
    {
        PropertyNamingPolicy = JsonNamingPolicy.CamelCase,
    };

    public BackendAgentService(BackendProcessManager backend, Func<AemeathStats> getStats)
    {
        _backend = backend;
        _getStats = getStats;
        _http = new HttpClient { Timeout = TimeSpan.FromSeconds(60) };
    }

    public bool IsAvailable => _backend.IsReady;

    public async Task<string> SendMessageAsync(string userMessage, IReadOnlyList<ChatMessage> history)
    {
        return await SendMessageAsync(userMessage, history, null);
    }

    public async Task<string> SendMessageAsync(string userMessage, IReadOnlyList<ChatMessage> history, byte[]? screenshot)
    {
        if (!IsAvailable)
            return OfflineResponses.GetContextual(_getStats(), DateTime.Now);

        try
        {
            var payload = BuildPayload(userMessage, screenshot);
            var content = new StringContent(
                JsonSerializer.Serialize(payload, JsonOpts),
                Encoding.UTF8,
                "application/json");

            var response = await _http.PostAsync(
                $"http://localhost:{_backend.Port}/agent/invoke", content);
            response.EnsureSuccessStatusCode();

            var json = await response.Content.ReadAsStringAsync();
            using var doc = JsonDocument.Parse(json);
            return doc.RootElement.GetProperty("response").GetString() ?? "";
        }
        catch
        {
            return OfflineResponses.GetContextual(_getStats(), DateTime.Now);
        }
    }

    public IAsyncEnumerable<string> StreamMessageAsync(string userMessage, IReadOnlyList<ChatMessage> history)
    {
        return StreamMessageAsync(userMessage, history, null);
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
                var payload = BuildPayload(userMessage, screenshot);
                var request = new HttpRequestMessage(HttpMethod.Post,
                    $"http://localhost:{_backend.Port}/agent/stream")
                {
                    Content = new StringContent(
                        JsonSerializer.Serialize(payload, JsonOpts),
                        Encoding.UTF8,
                        "application/json")
                };

                httpResponse = await _http.SendAsync(request, HttpCompletionOption.ResponseHeadersRead);
                httpResponse.EnsureSuccessStatusCode();

                using var stream = await httpResponse.Content.ReadAsStreamAsync();
                using var reader = new StreamReader(stream);

                while (!reader.EndOfStream)
                {
                    var line = await reader.ReadLineAsync();
                    if (line is null) break;

                    if (!line.StartsWith("data: ")) continue;

                    var data = line["data: ".Length..];
                    if (data == "[DONE]") break;

                    try
                    {
                        using var doc = JsonDocument.Parse(data);
                        var root = doc.RootElement;
                        var type = root.GetProperty("type").GetString();

                        switch (type)
                        {
                            case "token":
                                var tokenContent = root.GetProperty("content").GetString() ?? "";
                                await channel.Writer.WriteAsync(tokenContent);
                                break;
                            case "tool_call":
                                var toolName = root.GetProperty("data").GetProperty("name").GetString() ?? "unknown";
                                await channel.Writer.WriteAsync($"\n[Using tool: {toolName}...]\n");
                                break;
                            case "done":
                                goto done;
                            // "tool_result" — skip
                        }
                    }
                    catch { /* skip malformed SSE events */ }
                }
                done:;
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

    private object BuildPayload(string message, byte[]? screenshot)
    {
        var stats = _getStats();
        var context = new
        {
            mood = stats.Mood,
            energy = stats.Energy,
            affection = stats.Affection,
            days_together = stats.DaysTogether
        };

        if (screenshot is { Length: > 0 })
        {
            return new
            {
                message,
                thread_id = _threadId,
                context,
                screenshot = Convert.ToBase64String(screenshot)
            };
        }

        return new
        {
            message,
            thread_id = _threadId,
            context
        };
    }
}
