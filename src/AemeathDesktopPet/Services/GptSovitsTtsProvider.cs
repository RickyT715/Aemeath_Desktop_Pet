using System.Net.Http;
using System.Text;
using System.Text.Json;
using AemeathDesktopPet.Models;

namespace AemeathDesktopPet.Services;

/// <summary>
/// GPT-SoVITS TTS provider — connects to a local GPT-SoVITS server.
/// Supports model profiles for switching GPT/SoVITS weights, reference audio,
/// and synthesis parameters. Falls back to legacy mode when no profile is active.
/// </summary>
internal class GptSovitsTtsProvider : ITtsProvider
{
    private readonly Func<TtsConfig> _getConfig;
    private readonly HttpClient _http = new() { Timeout = TimeSpan.FromSeconds(60) };
    private string? _lastLoadedProfile;

    public string Name => "GPT-SoVITS";

    public bool IsAvailable
    {
        get
        {
            var url = _getConfig().GptsovitsUrl;
            return !string.IsNullOrWhiteSpace(url);
        }
    }

    public GptSovitsTtsProvider(Func<TtsConfig> getConfig)
    {
        _getConfig = getConfig;
    }

    public async Task<byte[]?> SynthesizeAsync(string text, CancellationToken ct)
    {
        if (string.IsNullOrWhiteSpace(text)) return null;

        var config = _getConfig();
        var baseUrl = config.GptsovitsUrl.TrimEnd('/');
        var profile = ResolveActiveProfile(config);

        if (profile != null)
        {
            await EnsureModelLoadedAsync(baseUrl, profile, ct);
            return await SynthesizeWithProfileAsync(baseUrl, text, profile, ct);
        }

        return await SynthesizeLegacyAsync(baseUrl, text, ct);
    }

    private static GptSovitsProfile? ResolveActiveProfile(TtsConfig config)
    {
        if (string.IsNullOrEmpty(config.GptsovitsActiveProfile)
            || config.GptsovitsProfiles == null
            || config.GptsovitsProfiles.Count == 0)
            return null;

        return config.GptsovitsProfiles
            .FirstOrDefault(p => p.Name == config.GptsovitsActiveProfile);
    }

    private async Task EnsureModelLoadedAsync(string baseUrl, GptSovitsProfile profile, CancellationToken ct)
    {
        if (profile.Name == _lastLoadedProfile)
            return;

        if (!string.IsNullOrWhiteSpace(profile.GptWeightsPath))
        {
            var url = $"{baseUrl}/set_gpt_weights?weights_path={Uri.EscapeDataString(profile.GptWeightsPath)}";
            var resp = await _http.GetAsync(url, ct);
            resp.EnsureSuccessStatusCode();
        }

        if (!string.IsNullOrWhiteSpace(profile.SovitsWeightsPath))
        {
            var url = $"{baseUrl}/set_sovits_weights?weights_path={Uri.EscapeDataString(profile.SovitsWeightsPath)}";
            var resp = await _http.GetAsync(url, ct);
            resp.EnsureSuccessStatusCode();
        }

        _lastLoadedProfile = profile.Name;
    }

    private async Task<byte[]?> SynthesizeWithProfileAsync(
        string baseUrl, string text, GptSovitsProfile profile, CancellationToken ct)
    {
        var payload = new Dictionary<string, object>
        {
            ["text"] = text,
            ["text_lang"] = string.IsNullOrWhiteSpace(profile.TextLang) ? "auto" : profile.TextLang,
            ["media_type"] = "wav"
        };

        if (!string.IsNullOrWhiteSpace(profile.RefAudioPath))
            payload["ref_audio_path"] = profile.RefAudioPath;

        if (!string.IsNullOrWhiteSpace(profile.PromptText))
            payload["prompt_text"] = profile.PromptText;

        if (!string.IsNullOrWhiteSpace(profile.PromptLang))
            payload["prompt_lang"] = profile.PromptLang;

        if (profile.SpeedFactor is > 0 and not 1.0)
            payload["speed_factor"] = profile.SpeedFactor;

        var json = JsonSerializer.Serialize(payload);
        var content = new StringContent(json, Encoding.UTF8, "application/json");

        var response = await _http.PostAsync($"{baseUrl}/tts", content, ct);
        response.EnsureSuccessStatusCode();

        return await response.Content.ReadAsByteArrayAsync(ct);
    }

    private async Task<byte[]?> SynthesizeLegacyAsync(string baseUrl, string text, CancellationToken ct)
    {
        var payload = new { text, text_language = "auto" };
        var json = JsonSerializer.Serialize(payload);
        var content = new StringContent(json, Encoding.UTF8, "application/json");

        var response = await _http.PostAsync($"{baseUrl}/tts", content, ct);
        response.EnsureSuccessStatusCode();

        return await response.Content.ReadAsByteArrayAsync(ct);
    }

    public void Dispose()
    {
        _http.Dispose();
    }
}
