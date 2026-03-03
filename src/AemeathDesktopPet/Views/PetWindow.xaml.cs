using System.IO;
using System.Windows;
using System.Windows.Controls;
using System.Windows.Input;
using System.Windows.Interop;
using System.Windows.Media;
using System.Windows.Threading;
using AemeathDesktopPet.Engine;
using AemeathDesktopPet.Interop;
using AemeathDesktopPet.Models;
using AemeathDesktopPet.ViewModels;

namespace AemeathDesktopPet.Views;

public partial class PetWindow : Window
{
    private readonly PetViewModel _vm;
    private readonly DispatcherTimer _hoverTimer;
    private readonly DispatcherTimer _idleBubbleTimer;
    private Hardcodet.Wpf.TaskbarNotification.TaskbarIcon? _trayIcon;

    // Child windows
    private CatWindow? _catWindow;
    private ChatWindow? _chatWindow;

    // Particle TextBlocks pool
    private readonly Dictionary<Particle, TextBlock> _particleElements = new();

    // Click-through state
    private bool _isClickThrough;
    private MenuItem? _clickThroughTrayItem;

    // Drag state
    private Point _dragClickOffset;

    // Activity monitor time tracking
    private DateTime _lastSpeechTime = DateTime.Now;
    private DateTime _workStartedTime = DateTime.Now;

    public PetWindow()
    {
        InitializeComponent();

        _vm = new PetViewModel();
        DataContext = _vm;

        // Hover timer for PET_HAPPY (2 second hover)
        _hoverTimer = new DispatcherTimer
        {
            Interval = TimeSpan.FromSeconds(2)
        };
        _hoverTimer.Tick += (_, _) =>
        {
            _hoverTimer.Stop();
            _vm.OnPetHappy();
        };

        // Idle speech bubble timer (random chatter every 30-90 seconds)
        _idleBubbleTimer = new DispatcherTimer(DispatcherPriority.Background)
        {
            Interval = TimeSpan.FromSeconds(45)
        };
        _idleBubbleTimer.Tick += OnIdleBubbleTick;

        // Bind position to window location
        _vm.PropertyChanged += (_, args) =>
        {
            if (args.PropertyName is nameof(PetViewModel.PetX) or nameof(PetViewModel.PetY))
            {
                Left = _vm.PetX;
                Top = _vm.PetY;
            }
            if (args.PropertyName == nameof(PetViewModel.SpriteSize))
            {
                Width = _vm.SpriteSize;
                Height = _vm.SpriteSize;
            }
        };

        Loaded += OnLoaded;
        Closing += OnClosing;
    }

    private void OnLoaded(object sender, RoutedEventArgs e)
    {
        // Make tool window (hidden from Alt+Tab)
        var hwnd = new WindowInteropHelper(this).Handle;
        Win32Api.SetToolWindow(hwnd);

        // Set window size to match sprite
        Width = _vm.SpriteSize;
        Height = _vm.SpriteSize;

        // Initialize and start engines
        _vm.Initialize();
        Left = _vm.PetX;
        Top = _vm.PetY;

        // Set up system tray
        SetupTrayIcon();

        // Subscribe to particle updates
        _vm.Particles.ParticlesChanged += OnParticlesChanged;

        // Subscribe to glitch effect
        _vm.Glitch.GlitchFrameChanged += OnGlitchFrame;
        _vm.Glitch.GlitchEnded += OnGlitchEnded;

        // Create cat window if enabled
        if (_vm.Config.Config.EnableBlackCat)
            CreateCatWindow();

        // Start idle bubble timer
        _idleBubbleTimer.Start();

        // Show greeting bubble
        var greeting = OfflineResponses.GetGreeting(_vm.CurrentStats, DateTime.Now);
        SpeechBubbleControl.ShowMessage(greeting, 5.0);

        // Set up global hotkey for push-to-talk
        SetupGlobalHotkey();

        // Set up pomodoro integration
        SetupPomodoroIntegration();

        // Suppress auto-singing when no music folder configured
        UpdateSuppressSinging();

        // Screen awareness indicator
        UpdateScreenWatchBadge();
    }

    private void OnClosing(object? sender, System.ComponentModel.CancelEventArgs e)
    {
        _idleBubbleTimer.Stop();
        _catWindow?.Close();
        _chatWindow?.Close();
        _vm.Shutdown();
        _trayIcon?.Dispose();
    }

    // --- Mouse Interactions ---

    protected override void OnMouseLeftButtonDown(MouseButtonEventArgs e)
    {
        base.OnMouseLeftButtonDown(e);

        if (e.ClickCount == 2)
        {
            OpenChat();
            return;
        }

        _dragClickOffset = e.GetPosition(this);
        _vm.OnDragStart();
        CaptureMouse();
        e.Handled = true;
    }

    protected override void OnMouseMove(MouseEventArgs e)
    {
        base.OnMouseMove(e);

        if (IsMouseCaptured && e.LeftButton == MouseButtonState.Pressed)
        {
            var currentPos = e.GetPosition(this);
            double newLeft = Left + (currentPos.X - _dragClickOffset.X);
            double newTop = Top + (currentPos.Y - _dragClickOffset.Y);
            _vm.OnDragMove(newLeft, newTop);
        }
    }

    protected override void OnMouseLeftButtonUp(MouseButtonEventArgs e)
    {
        base.OnMouseLeftButtonUp(e);

        if (IsMouseCaptured)
        {
            ReleaseMouseCapture();
            _vm.OnDragEnd();
        }
        else
        {
            _vm.OnLeftClick();
        }
    }

    protected override void OnMouseEnter(MouseEventArgs e)
    {
        base.OnMouseEnter(e);
        _hoverTimer.Start();
    }

    protected override void OnMouseLeave(MouseEventArgs e)
    {
        base.OnMouseLeave(e);
        _hoverTimer.Stop();
    }

    protected override void OnMouseRightButtonUp(MouseButtonEventArgs e)
    {
        base.OnMouseRightButtonUp(e);
        ShowContextMenu();
    }

    // --- Context Menu (expanded per design Section 4.4) ---

    private void ShowContextMenu()
    {
        var menu = new ContextMenu();

        // Sing
        var singItem = new MenuItem { Header = "Sing a Song" };
        if (_vm.Music.HasSongs)
            singItem.Click += (_, _) => _vm.OnSingRequested();
        else
        {
            singItem.Header = "Sing a Song (no music folder set)";
            singItem.IsEnabled = false;
        }

        // Chat
        var chatItem = new MenuItem { Header = "Chat with Aemeath" };
        chatItem.Click += (_, _) => OpenChat();

        // Paper Plane
        var planeItem = new MenuItem { Header = "Throw Paper Plane" };
        planeItem.Click += (_, _) => _vm.OnPaperPlaneRequested();

        menu.Items.Add(singItem);
        menu.Items.Add(chatItem);
        menu.Items.Add(planeItem);
        menu.Items.Add(new Separator());

        // Call Cat
        if (_vm.Config.Config.EnableBlackCat)
        {
            var callCatItem = new MenuItem { Header = $"Call {_vm.Config.Config.CatName}" };
            callCatItem.Click += (_, _) => _vm.OnCallCat();
            menu.Items.Add(callCatItem);
        }

        menu.Items.Add(new Separator());

        // How's Aemeath?
        var statsItem = new MenuItem { Header = "How's Aemeath?" };
        statsItem.Click += (_, _) =>
        {
            var popup = new StatsPopup(_vm.CurrentStats);
            popup.Show();
        };
        menu.Items.Add(statsItem);

        menu.Items.Add(new Separator());

        // Click-Through toggle
        var clickThroughItem = new MenuItem
        {
            Header = "Click-Through Mode",
            IsCheckable = true,
            IsChecked = _isClickThrough,
        };
        clickThroughItem.Click += (_, _) => ToggleClickThrough();
        menu.Items.Add(clickThroughItem);

        menu.Items.Add(new Separator());

        // Settings
        var settingsItem = new MenuItem { Header = "Settings" };
        settingsItem.Click += (_, _) => OpenSettings();
        menu.Items.Add(settingsItem);

        // Hide
        var hideItem = new MenuItem { Header = "See you later!" };
        hideItem.Click += (_, _) =>
        {
            Hide();
            _catWindow?.Hide();
            _trayIcon?.ShowBalloonTip("Aemeath", "I'm still here~ Find me in the system tray!",
                Hardcodet.Wpf.TaskbarNotification.BalloonIcon.Info);
        };
        menu.Items.Add(hideItem);

        menu.Items.Add(new Separator());

        // Quit
        var quitItem = new MenuItem { Header = "Quit" };
        quitItem.Click += (_, _) => Application.Current.Shutdown();
        menu.Items.Add(quitItem);

        menu.IsOpen = true;
    }

    private void OpenSettings()
    {
        var settings = new SettingsWindow(_vm.Config, _vm.Music)
        {
            Owner = this
        };
        if (settings.ShowDialog() == true)
        {
            _vm.ApplySettings();
            UpdateScreenWatchBadge();

            // Handle cat window enable/disable
            if (_vm.Config.Config.EnableBlackCat && _catWindow == null)
                CreateCatWindow();
            else if (!_vm.Config.Config.EnableBlackCat && _catWindow != null)
            {
                _catWindow.Close();
                _catWindow = null;
            }
        }
    }

    private void OpenChat()
    {
        if (_chatWindow != null && _chatWindow.IsVisible)
        {
            _chatWindow.Activate();
            return;
        }

        _vm.OnChatRequested();

        var chatVm = new ChatViewModel(
            _vm.Chat, _vm.Memory, _vm.Stats,
            _vm.Tts, _vm.VoiceInput, _vm.Stt,
            () => _vm.Config.Config);
        _chatWindow = new ChatWindow(chatVm);
        _chatWindow.Closed += (_, _) =>
        {
            _vm.OnChatClosed();
            _chatWindow = null;
        };
        _chatWindow.Show();
    }

    // --- Global Hotkey (Push-to-Talk) ---

    private ChatViewModel? _hotkeyVm;

    private void SetupGlobalHotkey()
    {
        var vi = _vm.Config.Config.VoiceInput;
        if (!vi.Enabled)
            return;

        _vm.GlobalHotkey.Configure(vi.Hotkey);
        _vm.GlobalHotkey.HotkeyPressed += () =>
        {
            Dispatcher.Invoke(() =>
            {
                // Open chat if not open, and start recording
                OpenChat();
                if (_chatWindow?.DataContext is ChatViewModel vm)
                {
                    _hotkeyVm = vm;
                    vm.StartRecording();
                }
            });
        };
        _vm.GlobalHotkey.HotkeyReleased += () =>
        {
            Dispatcher.Invoke(async () =>
            {
                if (_hotkeyVm != null)
                {
                    await _hotkeyVm.StopRecordingAndSendAsync();
                    _hotkeyVm = null;
                }
            });
        };
        _vm.GlobalHotkey.Start();
    }

    // --- Pomodoro Integration ---

    private async Task<string> GetPomodoroAiResponseAsync(string prompt, string[] fallbackPool, string? taskTitle = null)
    {
        if (_vm.Chat.IsAvailable)
        {
            try
            {
                var response = await _vm.Chat.SendMessageAsync(prompt, Array.Empty<ChatMessage>());
                if (!string.IsNullOrWhiteSpace(response))
                    return response;
            }
            catch { /* fall through to offline */ }
        }
        return OfflineResponses.GetPomodoroLine(fallbackPool, taskTitle);
    }

    private string BuildPomodoroPrompt(string template, string? taskTitle = null, int? duration = null, string? breakType = null)
    {
        return template
            .Replace("{taskTitle}", taskTitle ?? "my task")
            .Replace("{duration}", (duration ?? 25).ToString())
            .Replace("{breakType}", breakType ?? "short");
    }

    private string AppendActivitySummary(string prompt, DateTime from)
    {
        if (!_vm.ActivityMonitor.IsAvailable)
            return prompt;
        var summary = _vm.ActivityMonitor.GetActivitySummary(from, DateTime.Now);
        if (!string.IsNullOrEmpty(summary))
            prompt += "\n\n" + summary;
        var cameraSummary = _vm.ActivityMonitor.GetCameraSummary(from, DateTime.Now);
        if (!string.IsNullOrEmpty(cameraSummary))
            prompt += "\n\n" + cameraSummary;
        return prompt;
    }

    private void SetupPomodoroIntegration()
    {
        var pomo = _vm.PomodoroIntegration;
        if (pomo == null)
            return;

        pomo.WorkStarted += async (taskTitle, duration) =>
        {
            _workStartedTime = DateTime.Now;
            UpdateSuppressSinging();
            var prompt = BuildPomodoroPrompt(
                _vm.Config.Config.PomodoroIntegration.WorkStartedPrompt,
                taskTitle, duration);
            prompt = AppendActivitySummary(prompt, DateTime.Now.AddMinutes(-5));
            var text = await GetPomodoroAiResponseAsync(prompt, OfflineResponses.PomodoroWorkStarted, taskTitle);
            SpeechBubbleControl.ShowMessage(text, 6.0);
            _lastSpeechTime = DateTime.Now;
            _vm.OnPetHappy();
        };

        pomo.WorkFinished += async (taskTitle) =>
        {
            UpdateSuppressSinging();
            var prompt = BuildPomodoroPrompt(
                _vm.Config.Config.PomodoroIntegration.WorkFinishedPrompt,
                taskTitle);
            prompt = AppendActivitySummary(prompt, _workStartedTime);
            var text = await GetPomodoroAiResponseAsync(prompt, OfflineResponses.PomodoroWorkFinished, taskTitle);
            SpeechBubbleControl.ShowMessage(text, 6.0);
            _lastSpeechTime = DateTime.Now;
            _vm.Stats.Stats.Adjust(StatType.Mood, 3);
            _vm.Particles.Emit(ParticleType.Sparkle, _vm.PetX + _vm.SpriteSize / 2, _vm.PetY, 5);
            if (_vm.Tts.IsAvailable)
                _ = _vm.Tts.SpeakAsync(text);
        };

        pomo.BreakStarted += async (breakType, duration) =>
        {
            UpdateSuppressSinging();
            var prompt = BuildPomodoroPrompt(
                _vm.Config.Config.PomodoroIntegration.BreakStartedPrompt,
                breakType: breakType == "long" ? "long" : "short",
                duration: duration ?? 5);
            prompt = AppendActivitySummary(prompt, DateTime.Now.AddMinutes(-5));
            var text = await GetPomodoroAiResponseAsync(prompt, OfflineResponses.PomodoroBreakStarted);
            SpeechBubbleControl.ShowMessage(text, 5.0);
            _lastSpeechTime = DateTime.Now;
            if (_vm.Tts.IsAvailable)
                _ = _vm.Tts.SpeakAsync(text);
        };

        pomo.BreakFinished += async () =>
        {
            UpdateSuppressSinging();
            var prompt = BuildPomodoroPrompt(
                _vm.Config.Config.PomodoroIntegration.BreakFinishedPrompt);
            prompt = AppendActivitySummary(prompt, DateTime.Now.AddMinutes(-5));
            var text = await GetPomodoroAiResponseAsync(prompt, OfflineResponses.PomodoroBreakFinished);
            SpeechBubbleControl.ShowMessage(text, 4.0);
            _lastSpeechTime = DateTime.Now;
        };

        pomo.TaskAdded += async (taskTitle) =>
        {
            var prompt = BuildPomodoroPrompt(
                _vm.Config.Config.PomodoroIntegration.TaskAddedPrompt,
                taskTitle);
            prompt = AppendActivitySummary(prompt, DateTime.Now.AddMinutes(-5));
            var text = await GetPomodoroAiResponseAsync(prompt, OfflineResponses.TaskAddedReactions, taskTitle);
            SpeechBubbleControl.ShowMessage(text, 4.0);
            _lastSpeechTime = DateTime.Now;
        };
    }

    private void UpdateSuppressSinging()
    {
        var pomo = _vm.PomodoroIntegration;
        bool isWorkMode = pomo is { IsWorkMode: true };
        _vm.Behavior.SuppressSinging = isWorkMode || !_vm.Music.HasSongs;
    }

    // --- Screen Awareness Badge ---

    private void UpdateScreenWatchBadge()
    {
        var saConfig = _vm.Config.Config.ScreenAwareness;
        ScreenWatchBadge.Visibility = (saConfig.Enabled && saConfig.ShowScreenWatchIndicator)
            ? Visibility.Visible : Visibility.Collapsed;
    }

    // --- Cat Window ---

    private void CreateCatWindow()
    {
        _catWindow = new CatWindow(_vm.CatBehavior);
        _catWindow.Show();
    }

    // --- Particles ---

    private void OnParticlesChanged()
    {
        // Remove expired particle elements
        var expiredKeys = _particleElements.Keys
            .Where(p => !_vm.Particles.Particles.Contains(p)).ToList();
        foreach (var key in expiredKeys)
        {
            ParticleCanvas.Children.Remove(_particleElements[key]);
            _particleElements.Remove(key);
        }

        // Add/update particle elements
        foreach (var p in _vm.Particles.Particles)
        {
            if (!_particleElements.TryGetValue(p, out var tb))
            {
                tb = new TextBlock
                {
                    Text = p.Glyph,
                    FontSize = 16,
                    IsHitTestVisible = false,
                    Foreground = GetParticleBrush(p.Type),
                };
                ParticleCanvas.Children.Add(tb);
                _particleElements[p] = tb;
            }

            // Position relative to canvas — particles have world-space coords,
            // offset by pet position to get canvas-local coords
            Canvas.SetLeft(tb, p.X - _vm.PetX + 40);
            Canvas.SetTop(tb, p.Y - _vm.PetY + 80);
            tb.Opacity = p.Opacity;
        }
    }

    private static SolidColorBrush GetParticleBrush(ParticleType type) => type switch
    {
        ParticleType.MusicNote => new SolidColorBrush(Color.FromRgb(0x5C, 0xB8, 0xE6)),
        ParticleType.Heart => new SolidColorBrush(Color.FromRgb(0xF2, 0xA0, 0xB5)),
        ParticleType.Sparkle => new SolidColorBrush(Color.FromRgb(0xF5, 0xE0, 0x6D)),
        ParticleType.SleepZ => new SolidColorBrush(Color.FromRgb(0xA8, 0xE0, 0xF0)),
        ParticleType.PawPrint => new SolidColorBrush(Color.FromRgb(0x2D, 0x2D, 0x3D)),
        ParticleType.FurPuff => new SolidColorBrush(Color.FromRgb(0xE8, 0xE8, 0xF0)),
        _ => Brushes.White,
    };

    // --- Glitch Effect ---

    private void OnGlitchFrame(double opacity, double hOffset, bool rgbSplit)
    {
        PetSprite.Opacity = opacity * _vm.PetOpacity;

        // Horizontal displacement via RenderTransform
        PetSprite.RenderTransform = new TranslateTransform(hOffset, 0);

        if (rgbSplit)
        {
            // Show overlay with slight offset and tint for RGB split effect
            GlitchOverlay.Visibility = Visibility.Visible;
            GlitchOverlay.Source = _vm.CurrentFrame;
            GlitchOverlay.RenderTransform = new TranslateTransform(-hOffset * 0.5, 0);
            GlitchOverlay.Opacity = 0.3;
        }
        else
        {
            GlitchOverlay.Visibility = Visibility.Collapsed;
        }
    }

    private void OnGlitchEnded()
    {
        PetSprite.Opacity = _vm.PetOpacity;
        PetSprite.RenderTransform = Transform.Identity;
        GlitchOverlay.Visibility = Visibility.Collapsed;
    }

    // --- Idle Speech Bubbles ---

    private ActivityContext ResolveActivityContext()
    {
        var pomo = _vm.PomodoroIntegration;
        if (pomo is { IsWorkMode: true })
            return ActivityContext.PomodoroWork;
        if (pomo is { IsBreakMode: true })
            return ActivityContext.PomodoroBreak;

        if (_vm.ActivityMonitor.IsAvailable)
        {
            var detected = _vm.ActivityMonitor.DetectActivityContext();
            if (detected != ActivityContext.Default)
                return detected;
        }

        return ActivityContext.Default;
    }

    private async void OnIdleBubbleTick(object? sender, EventArgs e)
    {
        var rng = new Random();

        // Resolve context and look up configured frequency
        var context = ResolveActivityContext();
        var level = _vm.Config.Config.SpeechFrequency.GetLevel(context);
        var interval = SpeechFrequencyConfig.GetInterval(level);

        if (interval == null)
        {
            // Silent: re-check context in 30s but don't speak
            _idleBubbleTimer.Interval = TimeSpan.FromSeconds(30);
            return;
        }

        var (min, max) = interval.Value;
        _idleBubbleTimer.Interval = TimeSpan.FromSeconds(min + rng.NextDouble() * (max - min));

        // Don't show bubble during certain states
        var state = _vm.CurrentState;
        if (state is PetState.Drag or PetState.Thrown or PetState.Fall
            or PetState.Chat or PetState.Sleep or PetState.Speaking)
            return;

        // Try screen awareness commentary first
        var screenComment = _vm.ScreenAwareness.ConsumeLatestCommentary();
        if (!string.IsNullOrEmpty(screenComment))
        {
            SpeechBubbleControl.ShowMessage(screenComment, 5.0);
            _lastSpeechTime = DateTime.Now;
            if (_vm.Config.Config.Tts.SpeakIdleChatter && _vm.Tts.IsAvailable)
                _ = _vm.Tts.SpeakAsync(screenComment);
            return;
        }

        // Try activity-aware AI chatter when available
        if (_vm.ActivityMonitor.IsAvailable && _vm.Chat.IsAvailable)
        {
            var activitySummary = _vm.ActivityMonitor.GetActivitySummary(_lastSpeechTime, DateTime.Now);
            var cameraSummary = _vm.ActivityMonitor.GetCameraSummary(_lastSpeechTime, DateTime.Now);
            if (!string.IsNullOrEmpty(activitySummary) || !string.IsNullOrEmpty(cameraSummary))
            {
                var activityContext = string.Join(" ", new[] { activitySummary, cameraSummary }.Where(s => !string.IsNullOrEmpty(s)));
                var prompt = $"[Idle Chatter] You're Aemeath, commenting on what the user has been doing recently and how they seem. {activityContext} Say something short (1-2 sentences) — react to their activity or emotional state, make a casual observation, or ask a related question. Stay in character.";
                var text = await GetPomodoroAiResponseAsync(prompt, OfflineResponses.IdleChatter);
                SpeechBubbleControl.ShowMessage(text, 5.0);
                _lastSpeechTime = DateTime.Now;
                return;
            }
        }

        // Fallback: offline idle chatter
        var fallbackText = _vm.GetIdleBubbleText();
        SpeechBubbleControl.ShowMessage(fallbackText, 5.0);
        _lastSpeechTime = DateTime.Now;
    }

    // --- Click-Through Mode ---

    private void ToggleClickThrough()
    {
        SetClickThrough(!_isClickThrough);
    }

    private void SetClickThrough(bool enabled)
    {
        _isClickThrough = enabled;
        var hwnd = new WindowInteropHelper(this).Handle;
        Win32Api.SetClickThrough(hwnd, enabled);

        // Also apply to cat window if it exists
        if (_catWindow != null)
        {
            var catHwnd = new WindowInteropHelper(_catWindow).Handle;
            if (catHwnd != IntPtr.Zero)
                Win32Api.SetClickThrough(catHwnd, enabled);
        }

        // Update tray menu item checkmark
        if (_clickThroughTrayItem != null)
            _clickThroughTrayItem.IsChecked = enabled;

        // Visual feedback: ghost-like reduced opacity when click-through is on
        ClickThroughIndicator.Visibility = enabled ? Visibility.Visible : Visibility.Collapsed;

        if (enabled)
        {
            _trayIcon?.ShowBalloonTip("Aemeath", "Click-through mode ON — use the tray icon to toggle back!",
                Hardcodet.Wpf.TaskbarNotification.BalloonIcon.Info);
        }
    }

    // --- System Tray (expanded) ---

    private void SetupTrayIcon()
    {
        var icoPath = Path.Combine(AppDomain.CurrentDomain.BaseDirectory, "Resources", "Icons", "tray_icon.ico");
        System.Drawing.Icon? trayIco = null;
        if (File.Exists(icoPath))
            trayIco = new System.Drawing.Icon(icoPath);

        _trayIcon = new Hardcodet.Wpf.TaskbarNotification.TaskbarIcon
        {
            Icon = trayIco,
            ToolTipText = "Aemeath Desktop Pet",
        };

        // Tray context menu
        var trayMenu = new ContextMenu();

        var showItem = new MenuItem { Header = "Show Aemeath" };
        showItem.Click += (_, _) =>
        {
            Show();
            _catWindow?.Show();
            Activate();
        };

        var chatTrayItem = new MenuItem { Header = "Chat" };
        chatTrayItem.Click += (_, _) =>
        {
            Show();
            OpenChat();
        };

        var planeTrayItem = new MenuItem { Header = "Paper Plane" };
        planeTrayItem.Click += (_, _) =>
        {
            Show();
            _vm.OnPaperPlaneRequested();
        };

        _clickThroughTrayItem = new MenuItem
        {
            Header = "Click-Through Mode",
            IsCheckable = true,
            IsChecked = _isClickThrough,
        };
        _clickThroughTrayItem.Click += (_, _) => ToggleClickThrough();

        var settingsTrayItem = new MenuItem { Header = "Settings" };
        settingsTrayItem.Click += (_, _) =>
        {
            Show();
            OpenSettings();
        };

        var quitItem = new MenuItem { Header = "Quit" };
        quitItem.Click += (_, _) => Application.Current.Shutdown();

        trayMenu.Items.Add(showItem);
        trayMenu.Items.Add(chatTrayItem);
        trayMenu.Items.Add(planeTrayItem);
        trayMenu.Items.Add(new Separator());
        trayMenu.Items.Add(_clickThroughTrayItem);
        trayMenu.Items.Add(settingsTrayItem);
        trayMenu.Items.Add(new Separator());
        trayMenu.Items.Add(quitItem);

        _trayIcon.ContextMenu = trayMenu;
        _trayIcon.TrayMouseDoubleClick += (_, _) =>
        {
            Show();
            _catWindow?.Show();
            Activate();
        };
    }
}
