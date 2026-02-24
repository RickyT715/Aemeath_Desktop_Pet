namespace AemeathDesktopPet.Services;

/// <summary>
/// Interface for screen awareness (screenshot capture + LLM commentary).
/// </summary>
public interface IScreenAwarenessService : IDisposable
{
    bool IsEnabled { get; }

    Task<string?> CaptureAndCommentAsync();

    /// <summary>
    /// Returns and clears the most recent cached commentary from background analysis.
    /// </summary>
    string? ConsumeLatestCommentary();

    /// <summary>
    /// Starts the background screenshot analysis timer.
    /// </summary>
    void Start();

    /// <summary>
    /// Stops the background screenshot analysis timer.
    /// </summary>
    void Stop();
}
