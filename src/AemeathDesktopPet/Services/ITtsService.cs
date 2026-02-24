namespace AemeathDesktopPet.Services;

/// <summary>
/// Interface for text-to-speech service (GPT-SoVITS, cloud TTS, or stub).
/// </summary>
public interface ITtsService
{
    bool IsAvailable { get; }

    Task SpeakAsync(string text);

    void Stop();

    void SetVolume(double volume);
}
