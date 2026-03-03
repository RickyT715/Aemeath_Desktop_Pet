using System.Net.Http;
using System.Text;
using System.Text.Json;

namespace AemeathDesktopPet.Services;

/// <summary>
/// Vision analysis service that delegates to the Python FastAPI backend's /vision/analyze endpoint.
/// Posts a base64 screenshot with a prompt and returns the analysis text.
/// </summary>
public class BackendVisionService
{
    private readonly BackendProcessManager _backend;
    private readonly HttpClient _http;

    private static readonly JsonSerializerOptions JsonOpts = new()
    {
        PropertyNamingPolicy = JsonNamingPolicy.CamelCase,
    };

    public BackendVisionService(BackendProcessManager backend)
    {
        _backend = backend;
        _http = new HttpClient { Timeout = TimeSpan.FromSeconds(30) };
    }

    public bool IsAvailable => _backend.IsReady;

    /// <summary>
    /// Analyzes a screenshot using the backend vision provider.
    /// </summary>
    public async Task<string> AnalyzeAsync(byte[] screenshot, string prompt)
    {
        if (!IsAvailable)
            return "";

        var payload = new
        {
            image_base64 = Convert.ToBase64String(screenshot),
            prompt
        };

        var content = new StringContent(
            JsonSerializer.Serialize(payload, JsonOpts),
            Encoding.UTF8,
            "application/json");

        var response = await _http.PostAsync(
            $"http://localhost:{_backend.Port}/vision/analyze", content);
        response.EnsureSuccessStatusCode();

        var json = await response.Content.ReadAsStringAsync();
        using var doc = JsonDocument.Parse(json);
        return doc.RootElement.GetProperty("analysis").GetString() ?? "";
    }
}
