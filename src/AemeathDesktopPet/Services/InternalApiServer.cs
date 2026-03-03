using System.Net;
using System.Text;
using System.Text.Json;
using AemeathDesktopPet.Engine;

namespace AemeathDesktopPet.Services;

/// <summary>
/// Lightweight HTTP server exposing WPF app data to the Python backend.
/// Runs on a configurable port (default 18901).
/// </summary>
public class InternalApiServer : IDisposable
{
    private readonly int _port;
    private readonly StatsService _stats;
    private readonly MusicService _music;
    private readonly BehaviorEngine _behavior;
    private readonly PomodoroIntegrationService? _pomodoro;

    private HttpListener? _listener;
    private CancellationTokenSource? _cts;
    private Task? _listenTask;

    private static readonly JsonSerializerOptions JsonOpts = new()
    {
        PropertyNamingPolicy = JsonNamingPolicy.SnakeCaseLower,
        WriteIndented = false
    };

    public InternalApiServer(
        int port,
        StatsService stats,
        MusicService music,
        BehaviorEngine behavior,
        PomodoroIntegrationService? pomodoro)
    {
        _port = port;
        _stats = stats;
        _music = music;
        _behavior = behavior;
        _pomodoro = pomodoro;
    }

    public void StartAsync()
    {
        _cts = new CancellationTokenSource();
        _listener = new HttpListener();
        _listener.Prefixes.Add($"http://localhost:{_port}/");
        _listener.Start();
        _listenTask = ListenLoop(_cts.Token);
    }

    public void Stop()
    {
        _cts?.Cancel();
        _listener?.Stop();
        _listener?.Close();
    }

    private async Task ListenLoop(CancellationToken ct)
    {
        while (!ct.IsCancellationRequested)
        {
            try
            {
                var context = await _listener!.GetContextAsync();
                _ = HandleRequestAsync(context);
            }
            catch (HttpListenerException) when (ct.IsCancellationRequested)
            {
                break;
            }
            catch (ObjectDisposedException)
            {
                break;
            }
            catch
            {
                // Unexpected error, continue listening
            }
        }
    }

    private async Task HandleRequestAsync(HttpListenerContext context)
    {
        var request = context.Request;
        var response = context.Response;

        try
        {
            var path = request.Url?.AbsolutePath ?? "";
            var method = request.HttpMethod;

            string json = path switch
            {
                "/internal/stats" when method == "GET" => HandleGetStats(),
                "/internal/screen" when method == "GET" => HandleGetScreen(),
                "/internal/music/control" when method == "POST" => await HandleMusicControlAsync(request),
                "/internal/pet/state" when method == "GET" => HandleGetPetState(),
                _ => throw new InvalidOperationException("Not found")
            };

            var bytes = Encoding.UTF8.GetBytes(json);
            response.ContentType = "application/json";
            response.StatusCode = 200;
            response.ContentLength64 = bytes.Length;
            await response.OutputStream.WriteAsync(bytes);
        }
        catch (InvalidOperationException)
        {
            response.StatusCode = 404;
            var bytes = Encoding.UTF8.GetBytes("{\"error\":\"not found\"}");
            response.ContentType = "application/json";
            response.ContentLength64 = bytes.Length;
            await response.OutputStream.WriteAsync(bytes);
        }
        catch (Exception ex)
        {
            response.StatusCode = 500;
            var errorJson = JsonSerializer.Serialize(new { error = ex.Message });
            var bytes = Encoding.UTF8.GetBytes(errorJson);
            response.ContentType = "application/json";
            response.ContentLength64 = bytes.Length;
            await response.OutputStream.WriteAsync(bytes);
        }
        finally
        {
            response.Close();
        }
    }

    private string HandleGetStats()
    {
        var stats = _stats.Stats;
        var result = new
        {
            mood = stats.Mood,
            energy = stats.Energy,
            affection = stats.Affection,
            current_state = _behavior.CurrentState.ToString(),
            days_together = stats.DaysTogether,
            total_chats = stats.TotalChats
        };
        return JsonSerializer.Serialize(result, JsonOpts);
    }

    private string HandleGetScreen()
    {
        var screenshot = ScreenCaptureService.CaptureAndDownscale(1280);
        var result = new { image_base64 = Convert.ToBase64String(screenshot) };
        return JsonSerializer.Serialize(result, JsonOpts);
    }

    private async Task<string> HandleMusicControlAsync(HttpListenerRequest request)
    {
        using var reader = new System.IO.StreamReader(request.InputStream);
        var body = await reader.ReadToEndAsync();
        using var doc = JsonDocument.Parse(body);
        var action = doc.RootElement.GetProperty("action").GetString() ?? "";

        switch (action)
        {
            case "play":
                _music.PlayRandom();
                break;
            case "stop":
                _music.Stop();
                break;
            case "next":
                _music.Stop();
                _music.PlayRandom();
                break;
            default:
                return JsonSerializer.Serialize(new { error = $"Unknown action: {action}" });
        }

        return JsonSerializer.Serialize(new { status = "ok", action });
    }

    private string HandleGetPetState()
    {
        var result = new
        {
            state = _behavior.CurrentState.ToString(),
            is_pomodoro_work = _pomodoro?.IsWorkMode ?? false,
            is_pomodoro_break = _pomodoro?.IsBreakMode ?? false,
            is_music_playing = _music.IsPlaying,
            current_song = _music.CurrentSongName
        };
        return JsonSerializer.Serialize(result, JsonOpts);
    }

    public void Dispose()
    {
        Stop();
    }
}
