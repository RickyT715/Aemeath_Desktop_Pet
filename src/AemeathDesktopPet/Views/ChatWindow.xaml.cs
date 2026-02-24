using System.ComponentModel;
using System.Windows;
using System.Windows.Input;
using AemeathDesktopPet.ViewModels;

namespace AemeathDesktopPet.Views;

public partial class ChatWindow : Window
{
    private readonly ChatViewModel _vm;
    private const string Placeholder = "Write something... the cat is watching~";

    public ChatWindow(ChatViewModel viewModel)
    {
        InitializeComponent();
        _vm = viewModel;
        DataContext = _vm;

        _vm.Messages.CollectionChanged += (_, _) =>
        {
            UpdateEmptyState();
            // Auto-scroll to bottom
            if (MessageList.Items.Count > 0)
                MessageList.ScrollIntoView(MessageList.Items[^1]);
        };

        _vm.PropertyChanged += OnVmPropertyChanged;

        Loaded += (_, _) =>
        {
            UpdateEmptyState();
            ShowPlaceholder();
        };
    }

    private void OnVmPropertyChanged(object? sender, PropertyChangedEventArgs e)
    {
        if (e.PropertyName == nameof(ChatViewModel.StatusText))
        {
            Dispatcher.Invoke(() =>
            {
                var text = _vm.StatusText;
                if (string.IsNullOrEmpty(text))
                {
                    StatusBar.Visibility = Visibility.Collapsed;
                }
                else
                {
                    StatusLabel.Text = text;
                    StatusBar.Visibility = Visibility.Visible;
                }
            });
        }
        else if (e.PropertyName == nameof(ChatViewModel.IsRecording))
        {
            Dispatcher.Invoke(() =>
            {
                // Visual feedback: change mic button background when recording
                // The button template doesn't use dynamic binding, so we just update StatusBar
                if (_vm.IsRecording)
                {
                    StatusBar.Visibility = Visibility.Visible;
                    StatusLabel.Text = "Recording...";
                }
            });
        }
    }

    private void UpdateEmptyState()
    {
        EmptyState.Visibility = _vm.Messages.Count == 0 ? Visibility.Visible : Visibility.Collapsed;
    }

    private async void SendButton_Click(object sender, RoutedEventArgs e)
    {
        await _vm.SendMessageAsync();
    }

    private async void InputBox_KeyDown(object sender, KeyEventArgs e)
    {
        if (e.Key == Key.Enter && !e.KeyboardDevice.Modifiers.HasFlag(ModifierKeys.Shift))
        {
            e.Handled = true;
            await _vm.SendMessageAsync();
        }
    }

    private void InputBox_GotFocus(object sender, RoutedEventArgs e)
    {
        if (InputBox.Text == Placeholder)
        {
            InputBox.Text = "";
            InputBox.Foreground = (System.Windows.Media.Brush)FindResource("TextBrush");
        }
    }

    private void InputBox_LostFocus(object sender, RoutedEventArgs e)
    {
        ShowPlaceholder();
    }

    private void ShowPlaceholder()
    {
        if (string.IsNullOrWhiteSpace(InputBox.Text))
        {
            InputBox.Text = Placeholder;
            InputBox.Foreground = new System.Windows.Media.SolidColorBrush(
                System.Windows.Media.Color.FromRgb(0x66, 0x66, 0x66));
        }
    }

    private void MicButton_MouseDown(object sender, MouseButtonEventArgs e)
    {
        e.Handled = true;
        _vm.StartRecording();
    }

    private async void MicButton_MouseUp(object sender, MouseButtonEventArgs e)
    {
        e.Handled = true;
        await _vm.StopRecordingAndSendAsync();
    }

    private void TitleBar_MouseDown(object sender, MouseButtonEventArgs e)
    {
        if (e.ChangedButton == MouseButton.Left)
            DragMove();
    }
}
