using System.Net.Http;
using System.Net.Http.Headers;
using System.Text;
using System.Text.Json;
using AemeathDesktopPet.Models;

namespace AemeathDesktopPet.Services;

/// <summary>
/// Fish Audio TTS provider — cloud voice cloning and text-to-speech API.
/// Supports zero-shot voice cloning via reference_id (pre-uploaded voice model).
/// Returns WAV bytes from the Fish Audio v1 TTS endpoint.
/// </summary>
internal class FishAudioTtsProvider : ITtsProvider
{
    private readonly Func<TtsConfig> _getConfig;
    private readonly HttpClient _http = new() { Timeout = TimeSpan.FromSeconds(60) };

    public string Name => "Fish Audio";

    public bool IsAvailable
    {
        get
        {
            var config = _getConfig();
            return !string.IsNullOrWhiteSpace(config.FishAudioApiKey);
        }
    }

    public FishAudioTtsProvider(Func<TtsConfig> getConfig)
    {
        _getConfig = getConfig;
    }

    public async Task<byte[]?> SynthesizeAsync(string text, CancellationToken ct)
    {
        if (string.IsNullOrWhiteSpace(text))
            return null;

        var config = _getConfig();
        var baseUrl = string.IsNullOrWhiteSpace(config.FishAudioBaseUrl)
            ? "https://api.fish.audio"
            : config.FishAudioBaseUrl.TrimEnd('/');

        var payload = new Dictionary<string, object>
        {
            ["text"] = text,
            ["format"] = "wav",
            ["latency"] = "normal"
        };

        if (!string.IsNullOrWhiteSpace(config.FishAudioModelId))
            payload["reference_id"] = config.FishAudioModelId;

        var json = JsonSerializer.Serialize(payload);
        var request = new HttpRequestMessage(HttpMethod.Post, $"{baseUrl}/v1/tts")
        {
            Content = new StringContent(json, Encoding.UTF8, "application/json")
        };
        request.Headers.Authorization = new AuthenticationHeaderValue("Bearer", config.FishAudioApiKey);

        var response = await _http.SendAsync(request, HttpCompletionOption.ResponseContentRead, ct);
        response.EnsureSuccessStatusCode();

        return await response.Content.ReadAsByteArrayAsync(ct);
    }

    public void Dispose()
    {
        _http.Dispose();
    }
}
