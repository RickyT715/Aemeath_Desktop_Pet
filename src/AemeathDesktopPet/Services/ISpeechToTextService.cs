namespace AemeathDesktopPet.Services;

/// <summary>
/// Interface for speech-to-text transcription services.
/// </summary>
public interface ISpeechToTextService
{
    bool IsAvailable { get; }

    /// <summary>
    /// Transcribes WAV audio bytes to text.
    /// </summary>
    Task<string> TranscribeAsync(byte[] audioWav, string language = "en");
}
