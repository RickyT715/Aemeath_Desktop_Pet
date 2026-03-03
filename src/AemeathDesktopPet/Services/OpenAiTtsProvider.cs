using System.Net.Http;
using System.Net.Http.Headers;
using System.Text;
using System.Text.Json;
using AemeathDesktopPet.Models;

namespace AemeathDesktopPet.Services;

/// <summary>
/// OpenAI TTS provider — cloud text-to-speech via the OpenAI /v1/audio/speech endpoint.
/// Supports tts-1, tts-1-hd, and gpt-4o-mini-tts models.
/// Returns MP3 bytes by default.
/// </summary>
internal class OpenAiTtsProvider : ITtsProvider
{
    private readonly Func<TtsConfig> _getConfig;
    private readonly HttpClient _http = new() { Timeout = TimeSpan.FromSeconds(30) };

    public string Name => "OpenAI TTS";

    public bool IsAvailable
    {
        get
        {
            var config = _getConfig();
            return !string.IsNullOrWhiteSpace(config.OpenAiTtsApiKey);
        }
    }

    public OpenAiTtsProvider(Func<TtsConfig> getConfig)
    {
        _getConfig = getConfig;
    }

    public async Task<byte[]?> SynthesizeAsync(string text, CancellationToken ct)
    {
        if (string.IsNullOrWhiteSpace(text))
            return null;

        var config = _getConfig();
        var model = string.IsNullOrWhiteSpace(config.OpenAiTtsModel)
            ? "tts-1"
            : config.OpenAiTtsModel;
        var voice = string.IsNullOrWhiteSpace(config.OpenAiTtsVoice)
            ? "alloy"
            : config.OpenAiTtsVoice;

        var payload = new Dictionary<string, object>
        {
            ["model"] = model,
            ["input"] = text,
            ["voice"] = voice,
            ["response_format"] = "mp3"
        };

        if (config.OpenAiTtsSpeed is > 0 and not 1.0)
            payload["speed"] = config.OpenAiTtsSpeed;

        var json = JsonSerializer.Serialize(payload);
        var request = new HttpRequestMessage(HttpMethod.Post, "https://api.openai.com/v1/audio/speech")
        {
            Content = new StringContent(json, Encoding.UTF8, "application/json")
        };
        request.Headers.Authorization = new AuthenticationHeaderValue("Bearer", config.OpenAiTtsApiKey);

        var response = await _http.SendAsync(request, HttpCompletionOption.ResponseContentRead, ct);
        response.EnsureSuccessStatusCode();

        return await response.Content.ReadAsByteArrayAsync(ct);
    }

    public void Dispose()
    {
        _http.Dispose();
    }
}
