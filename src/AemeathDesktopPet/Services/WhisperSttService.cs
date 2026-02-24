using System.Net.Http;
using System.Net.Http.Headers;
using System.Text.Json;

namespace AemeathDesktopPet.Services;

/// <summary>
/// OpenAI Whisper API speech-to-text service.
/// POST multipart to api.openai.com/v1/audio/transcriptions.
/// </summary>
public class WhisperSttService : ISpeechToTextService
{
    private readonly HttpClient _http;
    private readonly Func<string> _getApiKey;

    public WhisperSttService(Func<string> getApiKey)
    {
        _getApiKey = getApiKey;
        _http = new HttpClient
        {
            BaseAddress = new Uri("https://api.openai.com"),
            Timeout = TimeSpan.FromSeconds(30)
        };
    }

    public bool IsAvailable => !string.IsNullOrWhiteSpace(_getApiKey());

    public async Task<string> TranscribeAsync(byte[] audioWav, string language = "en")
    {
        if (!IsAvailable)
            return "";

        var apiKey = _getApiKey();

        using var content = new MultipartFormDataContent();

        var audioContent = new ByteArrayContent(audioWav);
        audioContent.Headers.ContentType = new MediaTypeHeaderValue("audio/wav");
        content.Add(audioContent, "file", "recording.wav");
        content.Add(new StringContent("whisper-1"), "model");
        content.Add(new StringContent(language), "language");

        var request = new HttpRequestMessage(HttpMethod.Post, "/v1/audio/transcriptions")
        {
            Content = content
        };
        request.Headers.Authorization = new AuthenticationHeaderValue("Bearer", apiKey);

        var response = await _http.SendAsync(request);
        response.EnsureSuccessStatusCode();

        var json = await response.Content.ReadAsStringAsync();
        using var doc = JsonDocument.Parse(json);
        return doc.RootElement.GetProperty("text").GetString() ?? "";
    }
}
