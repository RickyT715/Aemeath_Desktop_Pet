using System.Net.Http;
using System.Text;
using System.Text.Json;
using AemeathDesktopPet.Models;

namespace AemeathDesktopPet.Services;

/// <summary>
/// ElevenLabs TTS provider — cloud text-to-speech API.
/// Returns MP3 bytes from the ElevenLabs v1 API.
/// </summary>
internal class ElevenLabsTtsProvider : ITtsProvider
{
    private readonly Func<TtsConfig> _getConfig;
    private readonly HttpClient _http = new() { Timeout = TimeSpan.FromSeconds(30) };

    public string Name => "ElevenLabs";

    public bool IsAvailable
    {
        get
        {
            var config = _getConfig();
            return !string.IsNullOrWhiteSpace(config.ElevenLabsApiKey);
        }
    }

    public ElevenLabsTtsProvider(Func<TtsConfig> getConfig)
    {
        _getConfig = getConfig;
    }

    public async Task<byte[]?> SynthesizeAsync(string text, CancellationToken ct)
    {
        if (string.IsNullOrWhiteSpace(text))
            return null;

        var config = _getConfig();
        var voiceId = string.IsNullOrWhiteSpace(config.ElevenLabsVoiceId)
            ? "21m00Tcm4TlvDq8ikWAM"
            : config.ElevenLabsVoiceId;
        var modelId = string.IsNullOrWhiteSpace(config.ElevenLabsModelId)
            ? "eleven_multilingual_v2"
            : config.ElevenLabsModelId;

        var url = $"https://api.elevenlabs.io/v1/text-to-speech/{voiceId}";

        var payload = new
        {
            text,
            model_id = modelId,
            voice_settings = new
            {
                stability = 0.5,
                similarity_boost = 0.75
            }
        };

        var json = JsonSerializer.Serialize(payload);
        var request = new HttpRequestMessage(HttpMethod.Post, url)
        {
            Content = new StringContent(json, Encoding.UTF8, "application/json")
        };
        request.Headers.Add("xi-api-key", config.ElevenLabsApiKey);

        var response = await _http.SendAsync(request, ct);
        response.EnsureSuccessStatusCode();

        return await response.Content.ReadAsByteArrayAsync(ct);
    }

    public void Dispose()
    {
        _http.Dispose();
    }
}
