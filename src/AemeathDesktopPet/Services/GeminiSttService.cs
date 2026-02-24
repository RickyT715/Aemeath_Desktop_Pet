using System.Net.Http;
using System.Text;
using System.Text.Json;

namespace AemeathDesktopPet.Services;

/// <summary>
/// Gemini multimodal speech-to-text: sends audio as inlineData with a transcription prompt.
/// Reuses the user's Gemini API key.
/// </summary>
public class GeminiSttService : ISpeechToTextService
{
    private readonly HttpClient _http;
    private readonly Func<string> _getApiKey;

    private const string BaseUrl = "https://generativelanguage.googleapis.com";
    private const string Model = "gemini-2.5-flash";

    public GeminiSttService(Func<string> getApiKey)
    {
        _getApiKey = getApiKey;
        _http = new HttpClient
        {
            BaseAddress = new Uri(BaseUrl),
            Timeout = TimeSpan.FromSeconds(30)
        };
    }

    public bool IsAvailable => !string.IsNullOrWhiteSpace(_getApiKey());

    public async Task<string> TranscribeAsync(byte[] audioWav, string language = "en")
    {
        if (!IsAvailable)
            return "";

        var apiKey = _getApiKey();
        var audioBase64 = Convert.ToBase64String(audioWav);

        var payload = new
        {
            contents = new[]
            {
                new
                {
                    parts = new object[]
                    {
                        new
                        {
                            inlineData = new
                            {
                                mimeType = "audio/wav",
                                data = audioBase64
                            }
                        },
                        new
                        {
                            text = $"Transcribe this audio to text. The spoken language is {language}. Return only the transcribed text, nothing else."
                        }
                    }
                }
            },
            generationConfig = new
            {
                maxOutputTokens = 500,
                temperature = 0.1
            }
        };

        var json = JsonSerializer.Serialize(payload);
        var url = $"/v1beta/models/{Model}:generateContent?key={apiKey}";
        var request = new HttpRequestMessage(HttpMethod.Post, url)
        {
            Content = new StringContent(json, Encoding.UTF8, "application/json")
        };

        var response = await _http.SendAsync(request);
        response.EnsureSuccessStatusCode();

        var responseJson = await response.Content.ReadAsStringAsync();
        using var doc = JsonDocument.Parse(responseJson);
        var candidates = doc.RootElement.GetProperty("candidates");
        if (candidates.GetArrayLength() > 0)
        {
            var content = candidates[0].GetProperty("content");
            var parts = content.GetProperty("parts");
            if (parts.GetArrayLength() > 0)
            {
                return parts[0].GetProperty("text").GetString()?.Trim() ?? "";
            }
        }

        return "";
    }
}
