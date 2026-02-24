using System.IO;
using System.IO.Pipes;
using System.Text.Json;
using System.Windows.Threading;
using AemeathDesktopPet.Models;

namespace AemeathDesktopPet.Services;

public class PomodoroIntegrationService : IDisposable
{
    private readonly string _pipeName;
    private readonly Dispatcher _dispatcher;
    private CancellationTokenSource? _cts;
    private static readonly JsonSerializerOptions _jsonOptions = new()
    {
        PropertyNameCaseInsensitive = true
    };

    // State
    public bool IsWorkMode { get; private set; }
    public bool IsBreakMode { get; private set; }
    public bool IsConnected { get; private set; }

    // Events (dispatched on UI thread)
    public event Action<string?, int?>? WorkStarted;      // taskTitle, durationMin
    public event Action<string?>? WorkFinished;            // taskTitle
    public event Action<string?, int?>? BreakStarted;      // breakType, durationMin
    public event Action? BreakFinished;
    public event Action<string>? TaskAdded;                // taskTitle

    public PomodoroIntegrationService(string pipeName, Dispatcher dispatcher)
    {
        _pipeName = pipeName;
        _dispatcher = dispatcher;
    }

    public void Start()
    {
        _cts = new CancellationTokenSource();
        _ = ListenLoop(_cts.Token);
    }

    public void Dispose()
    {
        _cts?.Cancel();
        _cts?.Dispose();
        _cts = null;
    }

    private async Task ListenLoop(CancellationToken ct)
    {
        while (!ct.IsCancellationRequested)
        {
            try
            {
                using var pipe = new NamedPipeServerStream(
                    _pipeName,
                    PipeDirection.In,
                    1,
                    PipeTransmissionMode.Byte,
                    PipeOptions.Asynchronous);

                await pipe.WaitForConnectionAsync(ct);
                IsConnected = true;

                await HandleClient(pipe, ct);
            }
            catch (OperationCanceledException)
            {
                break;
            }
            catch (Exception)
            {
                // Client disconnected or pipe error — restart
                IsConnected = false;
                try
                {
                    await Task.Delay(500, ct);
                }
                catch (OperationCanceledException)
                {
                    break;
                }
            }
        }

        IsConnected = false;
    }

    private async Task HandleClient(NamedPipeServerStream pipe, CancellationToken ct)
    {
        using var reader = new StreamReader(pipe);

        while (!ct.IsCancellationRequested && pipe.IsConnected)
        {
            string? line;
            try
            {
                line = await reader.ReadLineAsync(ct);
            }
            catch (OperationCanceledException)
            {
                break;
            }
            catch (Exception)
            {
                break;
            }

            if (line == null) break; // client disconnected

            try
            {
                var evt = JsonSerializer.Deserialize<PomodoroEvent>(line, _jsonOptions);
                if (evt != null)
                    DispatchEvent(evt);
            }
            catch (JsonException)
            {
                // Ignore malformed messages
            }
        }

        IsConnected = false;
    }

    private void DispatchEvent(PomodoroEvent evt)
    {
        _dispatcher.BeginInvoke(() =>
        {
            switch (evt.Event)
            {
                case "work_started":
                    IsWorkMode = true;
                    IsBreakMode = false;
                    WorkStarted?.Invoke(evt.TaskTitle, evt.Duration);
                    break;

                case "work_finished":
                    IsWorkMode = false;
                    WorkFinished?.Invoke(evt.TaskTitle);
                    break;

                case "break_started":
                    IsBreakMode = true;
                    IsWorkMode = false;
                    BreakStarted?.Invoke(evt.BreakType, evt.Duration);
                    break;

                case "break_finished":
                    IsBreakMode = false;
                    BreakFinished?.Invoke();
                    break;

                case "task_added":
                    TaskAdded?.Invoke(evt.TaskTitle ?? "Untitled");
                    break;
            }
        });
    }
}
