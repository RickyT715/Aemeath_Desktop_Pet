using System.IO;
using NAudio.Wave;

namespace AemeathDesktopPet.Services;

/// <summary>
/// Microphone recording service using NAudio.
/// Records 16kHz/16bit/mono WAV suitable for speech-to-text APIs.
/// </summary>
public class VoiceInputService : IDisposable
{
    private WaveInEvent? _waveIn;
    private MemoryStream? _buffer;
    private WaveFileWriter? _writer;
    private bool _isRecording;

    private static readonly WaveFormat RecordFormat = new(16000, 16, 1); // 16kHz, 16-bit, mono

    public bool IsRecording => _isRecording;

    public event Action<bool>? RecordingStateChanged;
    public event Action<float>? AudioLevelChanged;

    public void StartRecording()
    {
        if (_isRecording)
            return;

        _buffer = new MemoryStream();
        _waveIn = new WaveInEvent
        {
            WaveFormat = RecordFormat,
            BufferMilliseconds = 100
        };

        _writer = new WaveFileWriter(_buffer, RecordFormat);

        _waveIn.DataAvailable += OnDataAvailable;
        _waveIn.RecordingStopped += OnRecordingStopped;

        _waveIn.StartRecording();
        _isRecording = true;
        RecordingStateChanged?.Invoke(true);
    }

    /// <summary>
    /// Stops recording and returns the WAV bytes.
    /// </summary>
    public byte[] StopRecording()
    {
        if (!_isRecording || _waveIn == null)
            return [];

        _waveIn.StopRecording();
        _isRecording = false;
        RecordingStateChanged?.Invoke(false);

        // Flush and return buffer
        _writer?.Flush();

        var result = _buffer?.ToArray() ?? [];

        _writer?.Dispose();
        _writer = null;
        _buffer?.Dispose();
        _buffer = null;
        _waveIn.Dispose();
        _waveIn = null;

        return result;
    }

    private void OnDataAvailable(object? sender, WaveInEventArgs e)
    {
        _writer?.Write(e.Buffer, 0, e.BytesRecorded);

        // Calculate audio level (RMS of 16-bit samples)
        float max = 0;
        for (int i = 0; i < e.BytesRecorded - 1; i += 2)
        {
            short sample = (short)(e.Buffer[i] | (e.Buffer[i + 1] << 8));
            float abs = Math.Abs(sample / 32768f);
            if (abs > max)
                max = abs;
        }
        AudioLevelChanged?.Invoke(max);
    }

    private void OnRecordingStopped(object? sender, StoppedEventArgs e)
    {
        // Already handled in StopRecording
    }

    public void Dispose()
    {
        if (_isRecording)
            StopRecording();
        _waveIn?.Dispose();
        _writer?.Dispose();
        _buffer?.Dispose();
    }
}
