using System.Collections.ObjectModel;
using System.ComponentModel;
using System.Runtime.CompilerServices;
using System.Windows.Input;
using AemeathDesktopPet.Models;
using AemeathDesktopPet.Services;

namespace AemeathDesktopPet.ViewModels;

/// <summary>
/// ViewModel for the chat window. Manages message display, input, AI service interaction,
/// voice recording, and screenshot attachment.
/// </summary>
public class ChatViewModel : INotifyPropertyChanged
{
    private readonly IChatService _chat;
    private readonly MemoryService _memory;
    private readonly StatsService _stats;
    private readonly ITtsService? _tts;
    private readonly VoiceInputService? _voiceInput;
    private readonly ISpeechToTextService? _stt;
    private readonly Func<AppConfig>? _getConfig;

    private string _inputText = "";
    private bool _isSending;
    private bool _isRecording;
    private float _audioLevel;
    private string _statusText = "";
    private bool _includeScreenshot;

    public ObservableCollection<ChatMessage> Messages { get; } = new();

    public string InputText
    {
        get => _inputText;
        set { _inputText = value; OnPropertyChanged(); OnPropertyChanged(nameof(CanSend)); }
    }

    public bool IsSending
    {
        get => _isSending;
        set { _isSending = value; OnPropertyChanged(); OnPropertyChanged(nameof(CanSend)); }
    }

    public bool IsRecording
    {
        get => _isRecording;
        private set { _isRecording = value; OnPropertyChanged(); }
    }

    public float AudioLevel
    {
        get => _audioLevel;
        private set { _audioLevel = value; OnPropertyChanged(); }
    }

    public string StatusText
    {
        get => _statusText;
        private set { _statusText = value; OnPropertyChanged(); }
    }

    public bool IncludeScreenshot
    {
        get => _includeScreenshot;
        set { _includeScreenshot = value; OnPropertyChanged(); }
    }

    public bool CanSend => !IsSending && !string.IsNullOrWhiteSpace(InputText);

    public bool HasVoiceInput => _voiceInput != null && _stt is { IsAvailable: true };

    public ChatViewModel(IChatService chat, MemoryService memory, StatsService stats,
        ITtsService? tts = null,
        VoiceInputService? voiceInput = null,
        ISpeechToTextService? stt = null,
        Func<AppConfig>? getConfig = null)
    {
        _chat = chat;
        _memory = memory;
        _stats = stats;
        _tts = tts;
        _voiceInput = voiceInput;
        _stt = stt;
        _getConfig = getConfig;

        if (_voiceInput != null)
        {
            _voiceInput.AudioLevelChanged += level =>
            {
                AudioLevel = level;
            };
        }

        if (_getConfig != null)
        {
            _includeScreenshot = _getConfig().VoiceInput.IncludeScreenshot;
        }

        LoadHistory();
    }

    /// <summary>
    /// Sends the current input as a user message (text chat).
    /// </summary>
    public async Task SendMessageAsync()
    {
        if (!CanSend) return;

        var userText = InputText.Trim();
        InputText = "";

        byte[]? screenshot = null;
        if (_includeScreenshot)
        {
            try { screenshot = ScreenCaptureService.CaptureAndDownscale(); }
            catch { /* ignore capture failures */ }
        }

        await SendCoreAsync(userText, screenshot);
    }

    /// <summary>
    /// Starts voice recording.
    /// </summary>
    public void StartRecording()
    {
        if (_voiceInput == null || IsRecording) return;

        _voiceInput.StartRecording();
        IsRecording = true;
        StatusText = "Recording...";
    }

    /// <summary>
    /// Stops recording, transcribes, optionally captures screenshot, and sends to AI.
    /// </summary>
    public async Task StopRecordingAndSendAsync()
    {
        if (_voiceInput == null || !IsRecording) return;

        var audioData = _voiceInput.StopRecording();
        IsRecording = false;
        AudioLevel = 0;

        if (audioData.Length == 0)
        {
            StatusText = "";
            return;
        }

        if (_stt == null || !_stt.IsAvailable)
        {
            StatusText = "STT not configured";
            await Task.Delay(2000);
            StatusText = "";
            return;
        }

        StatusText = "Transcribing...";

        try
        {
            var language = _getConfig?.Invoke().VoiceInput.Language ?? "en";
            var transcribed = await _stt.TranscribeAsync(audioData, language);
            StatusText = "";

            if (string.IsNullOrWhiteSpace(transcribed))
                return;

            // Capture screenshot if enabled
            byte[]? screenshot = null;
            if (_includeScreenshot)
            {
                try { screenshot = ScreenCaptureService.CaptureAndDownscale(); }
                catch { /* ignore capture failures */ }
            }

            await SendCoreAsync(transcribed, screenshot);
        }
        catch
        {
            StatusText = "Transcription failed";
            await Task.Delay(2000);
            StatusText = "";
        }
    }

    /// <summary>
    /// Core method: adds user message, streams AI response.
    /// </summary>
    private async Task SendCoreAsync(string userText, byte[]? screenshot)
    {
        // Stop any ongoing TTS before sending new message
        _tts?.Stop();

        var userMsg = new ChatMessage("user", userText);
        Messages.Add(userMsg);
        _memory.AddMessage(userMsg);

        var assistantMsg = new ChatMessage("assistant", "") { IsStreaming = true };
        Messages.Add(assistantMsg);

        IsSending = true;
        try
        {
            var history = _memory.GetContextWindow();

            await foreach (var chunk in _chat.StreamMessageAsync(userText, history, screenshot))
            {
                assistantMsg.Content += chunk;
                int idx = Messages.IndexOf(assistantMsg);
                if (idx >= 0)
                {
                    Messages[idx] = assistantMsg;
                }
            }

            assistantMsg.IsStreaming = false;
            _memory.AddMessage(new ChatMessage("assistant", assistantMsg.Content));
            _memory.Save();
            _stats.OnChatted();

            // Auto-speak response via TTS
            if (_tts != null && _getConfig?.Invoke().Tts is { Enabled: true, SpeakChatResponses: true })
            {
                _ = _tts.SpeakAsync(assistantMsg.Content);
            }
        }
        catch
        {
            assistantMsg.Content = OfflineResponses.GetContextual(_stats.Stats, DateTime.Now);
            assistantMsg.IsStreaming = false;
        }
        finally
        {
            IsSending = false;
        }
    }

    private void LoadHistory()
    {
        _memory.Load();
        foreach (var msg in _memory.Messages)
        {
            Messages.Add(msg);
        }
    }

    public event PropertyChangedEventHandler? PropertyChanged;

    protected void OnPropertyChanged([CallerMemberName] string? name = null)
    {
        PropertyChanged?.Invoke(this, new PropertyChangedEventArgs(name));
    }
}
