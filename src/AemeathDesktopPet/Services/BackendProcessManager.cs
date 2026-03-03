using System.Diagnostics;
using System.IO;
using System.Net.Http;
using System.Text.Json;

namespace AemeathDesktopPet.Services;

/// <summary>
/// Manages the Python FastAPI backend process lifecycle.
/// Auto-detects bundled exe vs dev mode, monitors health, handles crash recovery.
/// </summary>
public class BackendProcessManager : IDisposable
{
    private readonly Models.BackendConfig _config;
    private readonly HttpClient _http;
    private Process? _process;
    private CancellationTokenSource? _cts;
    private int _crashCount;
    private bool _disposed;

    public bool IsReady { get; private set; }
    public int Port => _config.Port;
    public string? LastError { get; private set; }

    public event EventHandler? BackendReady;
    public event EventHandler<string>? BackendCrashed;

    public BackendProcessManager(Models.BackendConfig config)
    {
        _config = config;
        _http = new HttpClient { Timeout = TimeSpan.FromSeconds(5) };
    }

    public async Task StartAsync()
    {
        _cts = new CancellationTokenSource();
        _crashCount = 0;
        await LaunchProcessAsync();
    }

    public async Task StopAsync()
    {
        _cts?.Cancel();
        IsReady = false;

        if (_process is { HasExited: false })
        {
            // Try graceful shutdown
            try
            {
                await _http.PostAsync($"http://localhost:{_config.Port}/shutdown", null);
                var exited = _process.WaitForExit(5000);
                if (!exited)
                    _process.Kill(entireProcessTree: true);
            }
            catch
            {
                try { _process.Kill(entireProcessTree: true); } catch { }
            }
        }

        _process?.Dispose();
        _process = null;
    }

    private async Task LaunchProcessAsync()
    {
        var (fileName, arguments) = ResolveStartInfo();

        var psi = new ProcessStartInfo
        {
            FileName = fileName,
            Arguments = arguments,
            UseShellExecute = false,
            RedirectStandardOutput = true,
            RedirectStandardError = true,
            CreateNoWindow = true,
            WorkingDirectory = Path.GetDirectoryName(fileName) ?? ""
        };

        psi.EnvironmentVariables["AEMEATH_PORT"] = _config.Port.ToString();
        psi.EnvironmentVariables["AEMEATH_INTERNAL_PORT"] = _config.InternalPort.ToString();

        if (!string.IsNullOrEmpty(_config.TavilyApiKey))
            psi.EnvironmentVariables["TAVILY_API_KEY"] = _config.TavilyApiKey;
        if (!string.IsNullOrEmpty(_config.OpenWeatherMapApiKey))
            psi.EnvironmentVariables["OPENWEATHERMAP_API_KEY"] = _config.OpenWeatherMapApiKey;

        try
        {
            _process = Process.Start(psi);
            if (_process == null)
            {
                LastError = "Failed to start backend process";
                BackendCrashed?.Invoke(this, LastError);
                return;
            }

            _process.EnableRaisingEvents = true;
            _process.Exited += OnProcessExited;

            // Read stdout for READY signal
            _ = ReadOutputAsync(_process);

            // Poll health endpoint
            await PollHealthAsync();
        }
        catch (Exception ex)
        {
            LastError = ex.Message;
            BackendCrashed?.Invoke(this, LastError);
        }
    }

    private (string fileName, string arguments) ResolveStartInfo()
    {
        var mode = _config.Mode;

        if (mode == "auto")
        {
            // Check for bundled exe first
            var bundledPath = Path.Combine(
                AppDomain.CurrentDomain.BaseDirectory,
                "python-backend", "dist", "aemeath-agent", "aemeath-agent.exe");

            if (File.Exists(bundledPath))
                return (bundledPath, "");

            // Fall back to dev mode
            return (_config.PythonPath, "-m aemeath_agent.main");
        }

        if (mode == "bundled")
        {
            var bundledPath = Path.Combine(
                AppDomain.CurrentDomain.BaseDirectory,
                "python-backend", "dist", "aemeath-agent", "aemeath-agent.exe");
            return (bundledPath, "");
        }

        // Dev mode
        return (_config.PythonPath, "-m aemeath_agent.main");
    }

    private async Task ReadOutputAsync(Process process)
    {
        try
        {
            while (!process.HasExited && _cts is { IsCancellationRequested: false })
            {
                var line = await process.StandardOutput.ReadLineAsync();
                if (line == null) break;

                if (line.StartsWith("READY:"))
                {
                    // Backend signaled ready
                    break;
                }
            }
        }
        catch { /* Process exited */ }
    }

    private async Task PollHealthAsync()
    {
        var delays = new[] { 200, 400, 800, 1600, 3200, 5000, 10000, 10000, 10000, 10000 };

        foreach (var delay in delays)
        {
            if (_cts is { IsCancellationRequested: true }) return;

            try
            {
                await Task.Delay(delay, _cts?.Token ?? CancellationToken.None);
                var response = await _http.GetAsync($"http://localhost:{_config.Port}/health");
                if (response.IsSuccessStatusCode)
                {
                    IsReady = true;
                    LastError = null;
                    BackendReady?.Invoke(this, EventArgs.Empty);
                    return;
                }
            }
            catch (OperationCanceledException)
            {
                return;
            }
            catch
            {
                // Keep polling
            }
        }

        LastError = "Backend failed health check after all retries";
        BackendCrashed?.Invoke(this, LastError);
    }

    private async void OnProcessExited(object? sender, EventArgs e)
    {
        IsReady = false;
        _crashCount++;

        var exitCode = _process?.ExitCode ?? -1;
        LastError = $"Backend process exited with code {exitCode}";

        if (_cts is { IsCancellationRequested: true }) return;

        if (_crashCount <= _config.MaxRetries)
        {
            BackendCrashed?.Invoke(this, $"{LastError} (retry {_crashCount}/{_config.MaxRetries})");

            try
            {
                await Task.Delay(5000, _cts?.Token ?? CancellationToken.None);
                _process?.Dispose();
                _process = null;
                await LaunchProcessAsync();
            }
            catch (OperationCanceledException) { }
        }
        else
        {
            BackendCrashed?.Invoke(this, $"{LastError} (max retries exceeded)");
        }
    }

    public void Dispose()
    {
        if (_disposed) return;
        _disposed = true;
        _cts?.Cancel();
        _cts?.Dispose();

        if (_process is { HasExited: false })
        {
            try { _process.Kill(entireProcessTree: true); } catch { }
        }
        _process?.Dispose();
        _http.Dispose();
    }
}
