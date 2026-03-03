using System.Net.Http;
using System.Net.Http.Headers;

namespace AemeathDesktopPet.Services;

/// <summary>
/// Speech-to-text service that delegates to the Python FastAPI backend's /stt/transcribe endpoint.
/// Sends audio as multipart form data and returns the transcription text.
/// </summary>
public class BackendSttService : ISpeechToTextService
{
    private readonly BackendProcessManager _backend;
    private readonly HttpClient _http;

    public BackendSttService(BackendProcessManager backend)
    {
        _backend = backend;
        _http = new HttpClient { Timeout = TimeSpan.FromSeconds(30) };
    }

    public bool IsAvailable => _backend.IsReady;

    public async Task<string> TranscribeAsync(byte[] audioWav, string language = "en")
    {
        if (!IsAvailable)
            return "";

        using var form = new MultipartFormDataContent();

        var audioContent = new ByteArrayContent(audioWav);
        audioContent.Headers.ContentType = new MediaTypeHeaderValue("audio/wav");
        form.Add(audioContent, "file", "recording.wav");
        form.Add(new StringContent(language), "language");

        var response = await _http.PostAsync(
            $"http://localhost:{_backend.Port}/stt/transcribe", form);
        response.EnsureSuccessStatusCode();

        var json = await response.Content.ReadAsStringAsync();
        using var doc = System.Text.Json.JsonDocument.Parse(json);
        return doc.RootElement.GetProperty("text").GetString() ?? "";
    }
}
