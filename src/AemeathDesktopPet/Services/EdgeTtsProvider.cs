using AemeathDesktopPet.Models;
using Edge_tts_sharp;
using Edge_tts_sharp.Model;

namespace AemeathDesktopPet.Services;

/// <summary>
/// Edge TTS provider — free neural TTS via Microsoft Edge's WebSocket endpoint.
/// Returns MP3 bytes. No API key required.
/// </summary>
internal class EdgeTtsProvider : ITtsProvider
{
    private readonly Func<TtsConfig> _getConfig;

    public string Name => "Edge TTS";
    public bool IsAvailable => true;

    public EdgeTtsProvider(Func<TtsConfig> getConfig)
    {
        _getConfig = getConfig;
    }

    public async Task<byte[]?> SynthesizeAsync(string text, CancellationToken ct)
    {
        if (string.IsNullOrWhiteSpace(text))
            return null;

        var config = _getConfig();
        var voiceName = config.EdgeTtsVoice;

        return await Task.Run(() =>
        {
            ct.ThrowIfCancellationRequested();

            var voices = Edge_tts.GetVoice();
            var voice = voices.FirstOrDefault(v =>
                v.ShortName == voiceName || v.Name.Contains(voiceName, StringComparison.OrdinalIgnoreCase));

            if (voice == null)
                voice = voices.FirstOrDefault(v => v.ShortName.Contains("en-US", StringComparison.OrdinalIgnoreCase));

            if (voice == null && voices.Count > 0)
                voice = voices[0];

            if (voice == null)
                return null;

            var option = new PlayOption
            {
                Text = text,
                Rate = 0,
                Volume = 1.0f
            };

            byte[]? result = null;
            var done = new ManualResetEventSlim(false);

            // Edge_tts.Await = true is bugged (callback never fires).
            // Use Await = false and wait manually via ManualResetEventSlim.
            Edge_tts.Await = false;
            Edge_tts.Invoke(option, voice, bytes =>
            {
                if (!ct.IsCancellationRequested)
                    result = bytes.ToArray();
                done.Set();
            });

            // Wait for callback or cancellation
            try
            {
                done.Wait(ct);
            }
            catch (OperationCanceledException)
            {
                throw;
            }

            return result;
        }, ct);
    }

    public void Dispose() { }
}
