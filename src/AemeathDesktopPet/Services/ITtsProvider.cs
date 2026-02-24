namespace AemeathDesktopPet.Services;

/// <summary>
/// Internal interface for TTS synthesis backends.
/// Each provider converts text to audio bytes; playback is handled by TtsVoiceService.
/// </summary>
internal interface ITtsProvider : IDisposable
{
    string Name { get; }

    bool IsAvailable { get; }

    Task<byte[]?> SynthesizeAsync(string text, CancellationToken ct);
}
