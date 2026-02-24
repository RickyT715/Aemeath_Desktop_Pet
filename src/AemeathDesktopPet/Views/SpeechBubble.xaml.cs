using System.Windows;
using System.Windows.Controls;
using System.Windows.Threading;

namespace AemeathDesktopPet.Views;

public partial class SpeechBubble : UserControl
{
    private readonly DispatcherTimer _dismissTimer;
    private readonly DispatcherTimer _typingTimer;
    private string _fullText = "";
    private int _typingIndex;

    public event Action? Dismissed;

    public SpeechBubble()
    {
        InitializeComponent();

        _dismissTimer = new DispatcherTimer
        {
            Interval = TimeSpan.FromSeconds(4)
        };
        _dismissTimer.Tick += (_, _) =>
        {
            _dismissTimer.Stop();
            Hide();
        };

        _typingTimer = new DispatcherTimer
        {
            Interval = TimeSpan.FromMilliseconds(30)
        };
        _typingTimer.Tick += OnTypingTick;
    }

    /// <summary>
    /// Shows a message immediately (for pre-scripted responses).
    /// Auto-dismisses after the specified duration.
    /// </summary>
    public void ShowMessage(string text, double dismissSeconds = 4.0)
    {
        _typingTimer.Stop();
        MessageText.Text = text;
        Visibility = Visibility.Visible;

        _dismissTimer.Interval = TimeSpan.FromSeconds(dismissSeconds);
        _dismissTimer.Start();
    }

    /// <summary>
    /// Shows a message with typing effect (for AI streaming responses).
    /// </summary>
    public void ShowStreaming(string text, double dismissSeconds = 8.0)
    {
        _typingTimer.Stop();
        _dismissTimer.Stop();

        _fullText = text;
        _typingIndex = 0;
        MessageText.Text = "";
        Visibility = Visibility.Visible;

        _typingTimer.Start();
        _dismissTimer.Interval = TimeSpan.FromSeconds(dismissSeconds);
    }

    /// <summary>
    /// Appends streamed text chunk (for real-time streaming).
    /// </summary>
    public void AppendStreamChunk(string chunk)
    {
        MessageText.Text += chunk;

        // Reset dismiss timer on new content
        _dismissTimer.Stop();
        _dismissTimer.Interval = TimeSpan.FromSeconds(8);
        _dismissTimer.Start();

        Visibility = Visibility.Visible;
    }

    /// <summary>
    /// Finalizes a streaming message display.
    /// </summary>
    public void FinalizeStream(double dismissSeconds = 6.0)
    {
        _typingTimer.Stop();
        _dismissTimer.Interval = TimeSpan.FromSeconds(dismissSeconds);
        _dismissTimer.Start();
    }

    public void Hide()
    {
        _typingTimer.Stop();
        _dismissTimer.Stop();
        Visibility = Visibility.Collapsed;
        Dismissed?.Invoke();
    }

    private void OnTypingTick(object? sender, EventArgs e)
    {
        if (_typingIndex < _fullText.Length)
        {
            _typingIndex++;
            MessageText.Text = _fullText[.._typingIndex];
        }
        else
        {
            _typingTimer.Stop();
            _dismissTimer.Start();
        }
    }
}
