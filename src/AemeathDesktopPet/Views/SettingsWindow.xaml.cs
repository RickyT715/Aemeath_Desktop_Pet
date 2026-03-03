using System.IO;
using System.Windows;
using System.Windows.Controls;
using AemeathDesktopPet.Models;
using AemeathDesktopPet.Services;

namespace AemeathDesktopPet.Views;

public partial class SettingsWindow : Window
{
    private readonly ConfigService _config;
    private readonly MusicService _music;
    private bool _apiKeyVisible;
    private bool _geminiApiKeyVisible;
    private List<GptSovitsProfile> _sovitsProfiles = new();
    private bool _suppressProfileComboEvent;
    private List<McpServerDefinition> _mcpServers = new();
    private bool _suppressMcpEvent;

    public SettingsWindow(ConfigService config, MusicService music)
    {
        InitializeComponent();
        _config = config;
        _music = music;

        LoadSettings();
    }

    private void LoadSettings()
    {
        var c = _config.Config;

        // General
        StartWithWindowsCheck.IsChecked = c.StartWithWindows;
        CloseToTrayCheck.IsChecked = c.CloseToTray;
        SelectComboByTag(BehaviorFreqCombo, c.BehaviorFrequency);
        EnablePomodoroIntegrationCheck.IsChecked = c.PomodoroIntegration.Enabled;
        PomoWorkStartedPromptBox.Text = c.PomodoroIntegration.WorkStartedPrompt;
        PomoWorkFinishedPromptBox.Text = c.PomodoroIntegration.WorkFinishedPrompt;
        PomoBreakStartedPromptBox.Text = c.PomodoroIntegration.BreakStartedPrompt;
        PomoBreakFinishedPromptBox.Text = c.PomodoroIntegration.BreakFinishedPrompt;
        PomoTaskAddedPromptBox.Text = c.PomodoroIntegration.TaskAddedPrompt;
        EnablePomodoroIntegrationCheck.Checked += PomodoroToggled;
        EnablePomodoroIntegrationCheck.Unchecked += PomodoroToggled;
        UpdatePomodoroPromptsPanel();

        // Companion Apps
        LaunchMonitorCheck.IsChecked = c.CompanionApps.LaunchMonitor;
        MonitorPathBox.Text = c.CompanionApps.MonitorPath;
        LaunchTodoCheck.IsChecked = c.CompanionApps.LaunchTodoList;
        TodoPathBox.Text = c.CompanionApps.TodoListPath;

        // Activity Monitor
        EnableActivityMonitorCheck.IsChecked = c.ActivityMonitor.Enabled;
        ActivityDbPathBox.Text = c.ActivityMonitor.DatabasePath;
        UpdateActivityMonitorPanel();

        // Speech Frequency
        SelectComboByTag(FreqPomodoroWorkCombo, c.SpeechFrequency.PomodoroWork);
        SelectComboByTag(FreqPomodoroBreakCombo, c.SpeechFrequency.PomodoroBreak);
        SelectComboByTag(FreqGamingCombo, c.SpeechFrequency.Gaming);
        SelectComboByTag(FreqWatchingVideosCombo, c.SpeechFrequency.WatchingVideos);
        SelectComboByTag(FreqStudyCodingCombo, c.SpeechFrequency.StudyingCoding);
        SelectComboByTag(FreqDefaultCombo, c.SpeechFrequency.Default);

        // Appearance
        SelectComboByTag(SizeCombo, c.PetSize.ToString());
        OpacitySlider.Value = c.Opacity * 100;
        OpacityLabel.Text = $"{(int)OpacitySlider.Value}%";
        EnableGlitchCheck.IsChecked = c.EnableGlitchEffect;
        EnableCatCheck.IsChecked = c.EnableBlackCat;
        CatNameBox.Text = c.CatName;
        EnableAmbientPlanesCheck.IsChecked = c.EnableAmbientPaperPlanes;
        SelectComboByTag(PlaneFreqCombo, c.PaperPlaneFrequencyMinutes.ToString());

        // Music
        MusicFolderBox.Text = c.MusicFolderPath;
        UpdateSongCount();

        // AI
        SelectComboByTag(AiProviderCombo, c.AiProvider);
        ApiKeyBox.Password = c.ApiKey;
        GeminiApiKeyBox.Password = c.GeminiApiKey;
        ProxyBaseUrlBox.Text = c.ProxyBaseUrl;
        SelectComboByTag(ProxyModelCombo, c.ProxyModel);
        UpdateAiProviderPanels();
        EnableSingingBubblesCheck.IsChecked = c.EnableSinging;

        // Voice Input (STT)
        EnableVoiceInputCheck.IsChecked = c.VoiceInput.Enabled;
        SelectComboByTag(SttProviderCombo, c.VoiceInput.SttProvider);
        WhisperApiKeyBox.Password = c.VoiceInput.SttApiKey;
        SelectComboByTag(SttLanguageCombo, c.VoiceInput.Language);
        VoiceIncludeScreenshotCheck.IsChecked = c.VoiceInput.IncludeScreenshot;
        HotkeyBox.Text = c.VoiceInput.Hotkey;
        UpdateVoiceInputPanel();
        UpdateSttProviderPanels();

        // Screen Awareness
        EnableScreenCheck.IsChecked = c.ScreenAwareness.Enabled;
        ShowScreenIndicatorCheck.IsChecked = c.ScreenAwareness.ShowScreenWatchIndicator;
        EnableProtectedWindowCheck.IsChecked = c.ScreenAwareness.EnableProtectedWindowCheck;
        EnablePrivacyDownscaleCheck.IsChecked = c.ScreenAwareness.EnablePrivacyDownscale;
        SelectComboByTag(DownscaleResolutionCombo, c.ScreenAwareness.PrivacyDownscaleMaxWidth.ToString());
        EnableResponsePiiScanCheck.IsChecked = c.ScreenAwareness.EnableResponsePiiScan;
        SelectComboByTag(VisionProviderCombo, c.ScreenAwareness.VisionProvider);
        VisionApiKeyBox.Password = c.ScreenAwareness.VisionApiKey;
        OllamaBaseUrlBox.Text = c.ScreenAwareness.OllamaBaseUrl;
        OllamaModelNameBox.Text = c.ScreenAwareness.OllamaModelName;
        SelectComboByTag(HybridCloudProviderCombo, c.ScreenAwareness.HybridCloudProvider);
        HybridCloudApiKeyBox.Password = c.ScreenAwareness.HybridCloudApiKey;
        SelectComboByTag(ScreenIntervalCombo, c.ScreenAwareness.IntervalSeconds.ToString());
        ScreenBudgetBox.Text = c.ScreenAwareness.MonthlyBudgetCap.ToString("F2");
        ScreenPromptBox.Text = c.ScreenAwareness.AnalysisPrompt;
        ScreenBlacklistBox.Text = string.Join("\n", c.ScreenAwareness.BlacklistedApps);
        UpdateScreenAwarenessPanel();
        UpdateVisionProviderPanels();
        UpdateDownscalePanel();

        // Voice (TTS)
        EnableTtsCheck.IsChecked = c.Tts.Enabled;
        SelectComboByTag(TtsProviderCombo, c.Tts.Provider);
        EdgeTtsVoiceBox.Text = c.Tts.EdgeTtsVoice;
        SovitsUrlBox.Text = c.Tts.GptsovitsUrl;
        _sovitsProfiles = c.Tts.GptsovitsProfiles
            .Select(p => new GptSovitsProfile
            {
                Name = p.Name,
                GptWeightsPath = p.GptWeightsPath,
                SovitsWeightsPath = p.SovitsWeightsPath,
                RefAudioPath = p.RefAudioPath,
                PromptText = p.PromptText,
                PromptLang = p.PromptLang,
                TextLang = p.TextLang,
                SpeedFactor = p.SpeedFactor
            }).ToList();
        PopulateSovitsProfileCombo(c.Tts.GptsovitsActiveProfile);
        ElevenLabsApiKeyBox.Password = c.Tts.ElevenLabsApiKey;
        ElevenLabsVoiceIdBox.Text = c.Tts.ElevenLabsVoiceId;
        FishAudioApiKeyBox.Password = c.Tts.FishAudioApiKey;
        FishAudioModelIdBox.Text = c.Tts.FishAudioModelId;
        FishAudioBaseUrlBox.Text = c.Tts.FishAudioBaseUrl;
        OpenAiTtsApiKeyBox.Password = c.Tts.OpenAiTtsApiKey;
        SelectComboByTag(OpenAiTtsModelCombo, c.Tts.OpenAiTtsModel);
        SelectComboByTag(OpenAiTtsVoiceCombo, c.Tts.OpenAiTtsVoice);
        OpenAiTtsSpeedSlider.Value = c.Tts.OpenAiTtsSpeed * 100;
        OpenAiTtsSpeedLabel.Text = $"{c.Tts.OpenAiTtsSpeed:F2}x";
        TtsVolumeSlider.Value = c.Tts.Volume * 100;
        TtsVolumeLabel.Text = $"{(int)TtsVolumeSlider.Value}%";
        SpeakChatResponsesCheck.IsChecked = c.Tts.SpeakChatResponses;
        SpeakIdleChatterCheck.IsChecked = c.Tts.SpeakIdleChatter;
        AutoMuteFullscreenCheck.IsChecked = c.Tts.AutoMuteFullscreen;
        UpdateTtsPanel();
        UpdateTtsProviderPanels();

        // Backend
        EnableBackendCheck.IsChecked = c.Backend.Enabled;
        SelectComboByTag(BackendModeCombo, c.Backend.Mode);
        BackendPortBox.Text = c.Backend.Port.ToString();
        InternalPortBox.Text = c.Backend.InternalPort.ToString();
        PythonPathBox.Text = c.Backend.PythonPath;
        TavilyApiKeyBox.Password = c.Backend.TavilyApiKey;
        WeatherApiKeyBox.Password = c.Backend.OpenWeatherMapApiKey;
        MaxRetriesBox.Text = c.Backend.MaxRetries.ToString();
        UpdateBackendPanel();

        // MCP
        EnableMcpClientCheck.IsChecked = c.Mcp.Enabled;
        EnableMcpServerCheck.IsChecked = c.Mcp.ExposeAsServer;
        _mcpServers = c.Mcp.Servers
            .Select(s => new McpServerDefinition
            {
                Id = s.Id,
                Name = s.Name,
                Command = s.Command,
                Arguments = s.Arguments,
                TransportType = s.TransportType,
                Enabled = s.Enabled
            }).ToList();
        PopulateMcpServerList();
    }

    private void SelectComboByTag(ComboBox combo, string value)
    {
        foreach (ComboBoxItem item in combo.Items)
        {
            if (item.Tag is string tag && tag == value)
            {
                combo.SelectedItem = item;
                return;
            }
        }
        // Try Content match for numeric combos
        foreach (ComboBoxItem item in combo.Items)
        {
            if (item.Content?.ToString() == value)
            {
                combo.SelectedItem = item;
                return;
            }
        }
        if (combo.Items.Count > 0 && combo.SelectedItem == null)
            combo.SelectedIndex = combo.Items.Count > 1 ? 1 : 0;
    }

    private static string GetComboTag(ComboBox combo, string fallback)
    {
        if (combo.SelectedItem is ComboBoxItem item && item.Tag is string tag)
            return tag;
        return fallback;
    }

    private void UpdateSongCount()
    {
        string folder = MusicFolderBox.Text;
        if (!string.IsNullOrEmpty(folder) && Directory.Exists(folder))
        {
            var extensions = new[] { ".mp3", ".wav", ".wma", ".m4a", ".flac", ".aac" };
            int count = Directory.GetFiles(folder)
                .Count(f => extensions.Contains(Path.GetExtension(f).ToLowerInvariant()));
            SongCountLabel.Text = $"({count} song{(count != 1 ? "s" : "")} found)";
        }
        else
        {
            SongCountLabel.Text = string.IsNullOrEmpty(folder) ? "" : "(folder not found)";
        }
    }

    private void OpacitySlider_ValueChanged(object sender, RoutedPropertyChangedEventArgs<double> e)
    {
        if (OpacityLabel != null)
            OpacityLabel.Text = $"{(int)e.NewValue}%";
    }

    private void BrowseFolder_Click(object sender, RoutedEventArgs e)
    {
        var dialog = new Microsoft.Win32.OpenFileDialog
        {
            Title = "Select any file in your music folder",
            Filter = "Audio files|*.mp3;*.wav;*.wma;*.m4a;*.flac;*.aac|All files|*.*",
            CheckFileExists = true
        };

        if (!string.IsNullOrEmpty(MusicFolderBox.Text) && Directory.Exists(MusicFolderBox.Text))
            dialog.InitialDirectory = MusicFolderBox.Text;

        if (dialog.ShowDialog(this) == true)
        {
            MusicFolderBox.Text = Path.GetDirectoryName(dialog.FileName) ?? "";
            UpdateSongCount();
        }
    }

    private void ToggleApiKey_Click(object sender, RoutedEventArgs e)
    {
        _apiKeyVisible = !_apiKeyVisible;
        ToggleKeyBtn.Content = _apiKeyVisible ? "Hide" : "Show";
    }

    private void ToggleGeminiApiKey_Click(object sender, RoutedEventArgs e)
    {
        _geminiApiKeyVisible = !_geminiApiKeyVisible;
        ToggleGeminiKeyBtn.Content = _geminiApiKeyVisible ? "Hide" : "Show";
    }

    private void AiProviderCombo_SelectionChanged(object sender, SelectionChangedEventArgs e)
    {
        UpdateAiProviderPanels();
    }

    private void UpdateAiProviderPanels()
    {
        if (ClaudeKeyPanel == null || GeminiKeyPanel == null || ProxyPanel == null) return;

        var provider = GetComboTag(AiProviderCombo, "claude");

        ClaudeKeyPanel.Opacity = provider == "claude" ? 1.0 : 0.6;
        GeminiKeyPanel.Opacity = provider == "gemini" ? 1.0 : 0.6;
        ProxyPanel.Opacity = provider == "proxy" ? 1.0 : 0.6;
    }

    private void VoiceInputToggled(object sender, RoutedEventArgs e)
    {
        UpdateVoiceInputPanel();
    }

    private void UpdateVoiceInputPanel()
    {
        if (VoiceInputPanel == null) return;
        bool enabled = EnableVoiceInputCheck.IsChecked == true;
        VoiceInputPanel.IsEnabled = enabled;
        VoiceInputPanel.Opacity = enabled ? 1.0 : 0.5;
    }

    private void SttProviderCombo_SelectionChanged(object sender, SelectionChangedEventArgs e)
    {
        UpdateSttProviderPanels();
    }

    private void UpdateSttProviderPanels()
    {
        if (WhisperKeyPanel == null || GeminiSttNote == null) return;
        var provider = GetComboTag(SttProviderCombo, "whisper");
        bool isWhisper = provider == "whisper";
        WhisperKeyPanel.Visibility = isWhisper ? Visibility.Visible : Visibility.Collapsed;
        GeminiSttNote.Visibility = isWhisper ? Visibility.Collapsed : Visibility.Visible;
    }

    private void TtsToggled(object sender, RoutedEventArgs e)
    {
        UpdateTtsPanel();
    }

    private void UpdateTtsPanel()
    {
        if (TtsPanel == null) return;
        bool enabled = EnableTtsCheck.IsChecked == true;
        TtsPanel.IsEnabled = enabled;
        TtsPanel.Opacity = enabled ? 1.0 : 0.5;
    }

    private void TtsProviderCombo_SelectionChanged(object sender, SelectionChangedEventArgs e)
    {
        UpdateTtsProviderPanels();
    }

    private void UpdateTtsProviderPanels()
    {
        if (EdgeTtsPanel == null || SovitsPanel == null || ElevenLabsPanel == null
            || FishAudioPanel == null || OpenAiTtsPanel == null) return;

        var provider = GetComboTag(TtsProviderCombo, "edgetts");
        EdgeTtsPanel.Visibility = provider == "edgetts" ? Visibility.Visible : Visibility.Collapsed;
        SovitsPanel.Visibility = provider == "gptsovits" ? Visibility.Visible : Visibility.Collapsed;
        ElevenLabsPanel.Visibility = provider == "elevenlabs" ? Visibility.Visible : Visibility.Collapsed;
        FishAudioPanel.Visibility = provider == "fishaudio" ? Visibility.Visible : Visibility.Collapsed;
        OpenAiTtsPanel.Visibility = provider == "openaitts" ? Visibility.Visible : Visibility.Collapsed;
    }

    private void TtsVolumeSlider_ValueChanged(object sender, RoutedPropertyChangedEventArgs<double> e)
    {
        if (TtsVolumeLabel != null)
            TtsVolumeLabel.Text = $"{(int)e.NewValue}%";
    }

    private void HotkeyBox_PreviewKeyDown(object sender, System.Windows.Input.KeyEventArgs e)
    {
        e.Handled = true;

        var key = e.Key == System.Windows.Input.Key.System ? e.SystemKey : e.Key;

        // Skip modifier-only keys
        if (key is System.Windows.Input.Key.LeftCtrl or System.Windows.Input.Key.RightCtrl
            or System.Windows.Input.Key.LeftAlt or System.Windows.Input.Key.RightAlt
            or System.Windows.Input.Key.LeftShift or System.Windows.Input.Key.RightShift
            or System.Windows.Input.Key.LWin or System.Windows.Input.Key.RWin)
            return;

        var parts = new List<string>();
        if (System.Windows.Input.Keyboard.Modifiers.HasFlag(System.Windows.Input.ModifierKeys.Control))
            parts.Add("Ctrl");
        if (System.Windows.Input.Keyboard.Modifiers.HasFlag(System.Windows.Input.ModifierKeys.Alt))
            parts.Add("Alt");
        if (System.Windows.Input.Keyboard.Modifiers.HasFlag(System.Windows.Input.ModifierKeys.Shift))
            parts.Add("Shift");
        parts.Add(key.ToString());

        HotkeyBox.Text = string.Join("+", parts);
    }

    private void HotkeyBox_GotFocus(object sender, RoutedEventArgs e)
    {
        HotkeyBox.Text = "Press a key combo...";
    }

    private void HotkeyBox_LostFocus(object sender, RoutedEventArgs e)
    {
        if (HotkeyBox.Text == "Press a key combo...")
            HotkeyBox.Text = _config.Config.VoiceInput.Hotkey;
    }

    private void Save_Click(object sender, RoutedEventArgs e)
    {
        var c = _config.Config;

        // General
        c.StartWithWindows = StartWithWindowsCheck.IsChecked == true;
        c.CloseToTray = CloseToTrayCheck.IsChecked == true;
        c.BehaviorFrequency = GetComboTag(BehaviorFreqCombo, "normal");
        c.PomodoroIntegration.Enabled = EnablePomodoroIntegrationCheck.IsChecked == true;
        c.PomodoroIntegration.WorkStartedPrompt = PomoWorkStartedPromptBox.Text;
        c.PomodoroIntegration.WorkFinishedPrompt = PomoWorkFinishedPromptBox.Text;
        c.PomodoroIntegration.BreakStartedPrompt = PomoBreakStartedPromptBox.Text;
        c.PomodoroIntegration.BreakFinishedPrompt = PomoBreakFinishedPromptBox.Text;
        c.PomodoroIntegration.TaskAddedPrompt = PomoTaskAddedPromptBox.Text;

        // Companion Apps
        c.CompanionApps.LaunchMonitor = LaunchMonitorCheck.IsChecked == true;
        c.CompanionApps.MonitorPath = MonitorPathBox.Text;
        c.CompanionApps.LaunchTodoList = LaunchTodoCheck.IsChecked == true;
        c.CompanionApps.TodoListPath = TodoPathBox.Text;

        // Start with Windows — apply immediately on save
        StartupService.SetStartWithWindows(c.StartWithWindows);

        // Activity Monitor
        c.ActivityMonitor.Enabled = EnableActivityMonitorCheck.IsChecked == true;
        c.ActivityMonitor.DatabasePath = ActivityDbPathBox.Text;

        // Speech Frequency
        c.SpeechFrequency.PomodoroWork = GetComboTag(FreqPomodoroWorkCombo, "Silent");
        c.SpeechFrequency.PomodoroBreak = GetComboTag(FreqPomodoroBreakCombo, "Chatty");
        c.SpeechFrequency.Gaming = GetComboTag(FreqGamingCombo, "Rare");
        c.SpeechFrequency.WatchingVideos = GetComboTag(FreqWatchingVideosCombo, "Rare");
        c.SpeechFrequency.StudyingCoding = GetComboTag(FreqStudyCodingCombo, "Normal");
        c.SpeechFrequency.Default = GetComboTag(FreqDefaultCombo, "Normal");

        // Appearance
        if (SizeCombo.SelectedItem is ComboBoxItem sizeItem && sizeItem.Tag is string sizeTag
            && int.TryParse(sizeTag, out int size))
            c.PetSize = size;

        c.Opacity = OpacitySlider.Value / 100.0;
        c.EnableGlitchEffect = EnableGlitchCheck.IsChecked == true;
        c.EnableBlackCat = EnableCatCheck.IsChecked == true;
        c.CatName = CatNameBox.Text;
        c.EnableAmbientPaperPlanes = EnableAmbientPlanesCheck.IsChecked == true;

        if (PlaneFreqCombo.SelectedItem is ComboBoxItem freqItem && freqItem.Tag is string freqTag
            && int.TryParse(freqTag, out int freq))
            c.PaperPlaneFrequencyMinutes = freq;

        // Music
        c.MusicFolderPath = MusicFolderBox.Text;

        // AI
        c.AiProvider = GetComboTag(AiProviderCombo, "claude");
        c.ApiKey = ApiKeyBox.Password;
        c.GeminiApiKey = GeminiApiKeyBox.Password;
        c.ProxyBaseUrl = ProxyBaseUrlBox.Text;
        c.ProxyModel = GetComboTag(ProxyModelCombo, "claude-sonnet-4-5-20250929");
        c.EnableSinging = EnableSingingBubblesCheck.IsChecked == true;

        // Screen Awareness
        c.ScreenAwareness.Enabled = EnableScreenCheck.IsChecked == true;
        c.ScreenAwareness.ShowScreenWatchIndicator = ShowScreenIndicatorCheck.IsChecked == true;
        c.ScreenAwareness.EnableProtectedWindowCheck = EnableProtectedWindowCheck.IsChecked == true;
        c.ScreenAwareness.EnablePrivacyDownscale = EnablePrivacyDownscaleCheck.IsChecked == true;
        if (DownscaleResolutionCombo.SelectedItem is ComboBoxItem dsItem && dsItem.Tag is string dsTag
            && int.TryParse(dsTag, out int dsWidth))
            c.ScreenAwareness.PrivacyDownscaleMaxWidth = dsWidth;
        c.ScreenAwareness.EnableResponsePiiScan = EnableResponsePiiScanCheck.IsChecked == true;
        c.ScreenAwareness.VisionProvider = GetComboTag(VisionProviderCombo, "gemini");
        c.ScreenAwareness.VisionApiKey = VisionApiKeyBox.Password;
        c.ScreenAwareness.OllamaBaseUrl = OllamaBaseUrlBox.Text;
        c.ScreenAwareness.OllamaModelName = OllamaModelNameBox.Text;
        c.ScreenAwareness.HybridCloudProvider = GetComboTag(HybridCloudProviderCombo, "gemini");
        c.ScreenAwareness.HybridCloudApiKey = HybridCloudApiKeyBox.Password;
        if (ScreenIntervalCombo.SelectedItem is ComboBoxItem intervalItem && intervalItem.Tag is string intervalTag
            && int.TryParse(intervalTag, out int interval))
            c.ScreenAwareness.IntervalSeconds = interval;
        if (double.TryParse(ScreenBudgetBox.Text, out double budget))
            c.ScreenAwareness.MonthlyBudgetCap = budget;
        c.ScreenAwareness.AnalysisPrompt = ScreenPromptBox.Text;
        c.ScreenAwareness.BlacklistedApps = ScreenBlacklistBox.Text
            .Split('\n', StringSplitOptions.RemoveEmptyEntries | StringSplitOptions.TrimEntries)
            .ToList();

        // TTS
        c.Tts.Enabled = EnableTtsCheck.IsChecked == true;
        c.Tts.Provider = GetComboTag(TtsProviderCombo, "edgetts");
        c.Tts.EdgeTtsVoice = EdgeTtsVoiceBox.Text;
        c.Tts.GptsovitsUrl = SovitsUrlBox.Text;
        SaveCurrentProfileEdits();
        c.Tts.GptsovitsProfiles = _sovitsProfiles;
        c.Tts.GptsovitsActiveProfile = GetSelectedSovitsProfileName();
        c.Tts.ElevenLabsApiKey = ElevenLabsApiKeyBox.Password;
        c.Tts.ElevenLabsVoiceId = ElevenLabsVoiceIdBox.Text;
        c.Tts.FishAudioApiKey = FishAudioApiKeyBox.Password;
        c.Tts.FishAudioModelId = FishAudioModelIdBox.Text;
        c.Tts.FishAudioBaseUrl = FishAudioBaseUrlBox.Text;
        c.Tts.OpenAiTtsApiKey = OpenAiTtsApiKeyBox.Password;
        c.Tts.OpenAiTtsModel = GetComboTag(OpenAiTtsModelCombo, "tts-1");
        c.Tts.OpenAiTtsVoice = GetComboTag(OpenAiTtsVoiceCombo, "alloy");
        c.Tts.OpenAiTtsSpeed = OpenAiTtsSpeedSlider.Value / 100.0;
        c.Tts.Volume = TtsVolumeSlider.Value / 100.0;
        c.Tts.SpeakChatResponses = SpeakChatResponsesCheck.IsChecked == true;
        c.Tts.SpeakIdleChatter = SpeakIdleChatterCheck.IsChecked == true;
        c.Tts.AutoMuteFullscreen = AutoMuteFullscreenCheck.IsChecked == true;

        // Voice Input
        c.VoiceInput.Enabled = EnableVoiceInputCheck.IsChecked == true;
        c.VoiceInput.SttProvider = GetComboTag(SttProviderCombo, "whisper");
        c.VoiceInput.SttApiKey = WhisperApiKeyBox.Password;
        c.VoiceInput.Language = GetComboTag(SttLanguageCombo, "en");
        c.VoiceInput.IncludeScreenshot = VoiceIncludeScreenshotCheck.IsChecked == true;
        c.VoiceInput.Hotkey = HotkeyBox.Text;

        // Backend
        c.Backend.Enabled = EnableBackendCheck.IsChecked == true;
        c.Backend.Mode = GetComboTag(BackendModeCombo, "auto");
        if (int.TryParse(BackendPortBox.Text, out int backendPort))
            c.Backend.Port = backendPort;
        if (int.TryParse(InternalPortBox.Text, out int internalPort))
            c.Backend.InternalPort = internalPort;
        c.Backend.PythonPath = PythonPathBox.Text;
        c.Backend.TavilyApiKey = TavilyApiKeyBox.Password;
        c.Backend.OpenWeatherMapApiKey = WeatherApiKeyBox.Password;
        if (int.TryParse(MaxRetriesBox.Text, out int maxRetries))
            c.Backend.MaxRetries = maxRetries;

        // MCP
        c.Mcp.Enabled = EnableMcpClientCheck.IsChecked == true;
        c.Mcp.ExposeAsServer = EnableMcpServerCheck.IsChecked == true;
        SaveCurrentMcpServerEdits();
        c.Mcp.Servers = _mcpServers;

        _config.Save();
        _music.SetMusicFolder(c.MusicFolderPath);

        DialogResult = true;
        Close();
    }

    // --- GPT-SoVITS Profile Management ---

    private void PopulateSovitsProfileCombo(string activeProfileName)
    {
        _suppressProfileComboEvent = true;
        SovitsProfileCombo.Items.Clear();

        var noProfile = new ComboBoxItem { Content = "(No profile - legacy mode)", Tag = "" };
        SovitsProfileCombo.Items.Add(noProfile);

        int selectedIndex = 0;
        for (int i = 0; i < _sovitsProfiles.Count; i++)
        {
            var item = new ComboBoxItem { Content = _sovitsProfiles[i].Name, Tag = _sovitsProfiles[i].Name };
            SovitsProfileCombo.Items.Add(item);
            if (_sovitsProfiles[i].Name == activeProfileName)
                selectedIndex = i + 1;
        }

        SovitsProfileCombo.SelectedIndex = selectedIndex;
        _suppressProfileComboEvent = false;
        UpdateSovitsProfileEditor();
    }

    private void SovitsProfileCombo_SelectionChanged(object sender, SelectionChangedEventArgs e)
    {
        if (_suppressProfileComboEvent) return;
        SaveCurrentProfileEdits();
        UpdateSovitsProfileEditor();
    }

    private void UpdateSovitsProfileEditor()
    {
        if (SovitsProfileEditor == null) return;

        var profile = GetSelectedSovitsProfile();
        if (profile == null)
        {
            SovitsProfileEditor.Visibility = Visibility.Collapsed;
            return;
        }

        SovitsProfileEditor.Visibility = Visibility.Visible;
        SovitsProfileNameBox.Text = profile.Name;
        SovitsGptWeightsBox.Text = profile.GptWeightsPath;
        SovitsSovitsWeightsBox.Text = profile.SovitsWeightsPath;
        SovitsRefAudioBox.Text = profile.RefAudioPath;
        SovitsPromptTextBox.Text = profile.PromptText;
        SelectComboByTag(SovitsPromptLangCombo, profile.PromptLang);
        SelectComboByTag(SovitsTextLangCombo, profile.TextLang);

        _suppressProfileComboEvent = true;
        SovitsSpeedSlider.Value = profile.SpeedFactor * 100;
        SovitsSpeedLabel.Text = $"{profile.SpeedFactor:F1}x";
        _suppressProfileComboEvent = false;
    }

    private GptSovitsProfile? GetSelectedSovitsProfile()
    {
        var name = GetSelectedSovitsProfileName();
        if (string.IsNullOrEmpty(name)) return null;
        return _sovitsProfiles.FirstOrDefault(p => p.Name == name);
    }

    private string GetSelectedSovitsProfileName()
    {
        if (SovitsProfileCombo.SelectedItem is ComboBoxItem item && item.Tag is string tag)
            return tag;
        return "";
    }

    private void SaveCurrentProfileEdits()
    {
        var profile = GetSelectedSovitsProfile();
        if (profile == null) return;

        var newName = SovitsProfileNameBox.Text.Trim();
        if (!string.IsNullOrEmpty(newName) && newName != profile.Name)
        {
            profile.Name = newName;
            if (SovitsProfileCombo.SelectedItem is ComboBoxItem item)
            {
                item.Content = newName;
                item.Tag = newName;
            }
        }

        profile.GptWeightsPath = SovitsGptWeightsBox.Text;
        profile.SovitsWeightsPath = SovitsSovitsWeightsBox.Text;
        profile.RefAudioPath = SovitsRefAudioBox.Text;
        profile.PromptText = SovitsPromptTextBox.Text;
        profile.PromptLang = GetComboTag(SovitsPromptLangCombo, "auto");
        profile.TextLang = GetComboTag(SovitsTextLangCombo, "auto");
        profile.SpeedFactor = SovitsSpeedSlider.Value / 100.0;
    }

    private void SovitsAddProfile_Click(object sender, RoutedEventArgs e)
    {
        int n = 1;
        string name;
        do
        {
            name = $"Profile {n++}";
        } while (_sovitsProfiles.Any(p => p.Name == name));

        var profile = new GptSovitsProfile { Name = name };
        _sovitsProfiles.Add(profile);
        PopulateSovitsProfileCombo(name);
    }

    private void SovitsDeleteProfile_Click(object sender, RoutedEventArgs e)
    {
        var profile = GetSelectedSovitsProfile();
        if (profile == null) return;

        var result = MessageBox.Show(
            $"Delete profile \"{profile.Name}\"?",
            "Delete Profile",
            MessageBoxButton.YesNo,
            MessageBoxImage.Question);

        if (result != MessageBoxResult.Yes) return;

        _sovitsProfiles.Remove(profile);
        PopulateSovitsProfileCombo("");
    }

    private void SovitsSpeedSlider_ValueChanged(object sender, RoutedPropertyChangedEventArgs<double> e)
    {
        if (SovitsSpeedLabel != null && !_suppressProfileComboEvent)
            SovitsSpeedLabel.Text = $"{e.NewValue / 100.0:F1}x";
    }

    private void OpenAiTtsSpeedSlider_ValueChanged(object sender, RoutedPropertyChangedEventArgs<double> e)
    {
        if (OpenAiTtsSpeedLabel != null)
            OpenAiTtsSpeedLabel.Text = $"{e.NewValue / 100.0:F2}x";
    }

    private void BrowseGptWeights_Click(object sender, RoutedEventArgs e)
    {
        var path = BrowseForFile("GPT weights|*.ckpt|All files|*.*");
        if (path != null) SovitsGptWeightsBox.Text = path;
    }

    private void BrowseSovitsWeights_Click(object sender, RoutedEventArgs e)
    {
        var path = BrowseForFile("SoVITS weights|*.pth|All files|*.*");
        if (path != null) SovitsSovitsWeightsBox.Text = path;
    }

    private void BrowseRefAudio_Click(object sender, RoutedEventArgs e)
    {
        var path = BrowseForFile("Audio files|*.wav;*.mp3;*.flac;*.ogg|All files|*.*");
        if (path != null) SovitsRefAudioBox.Text = path;
    }

    private string? BrowseForFile(string filter)
    {
        var dialog = new Microsoft.Win32.OpenFileDialog
        {
            Filter = filter,
            CheckFileExists = false // Paths may be on the server machine
        };
        return dialog.ShowDialog(this) == true ? dialog.FileName : null;
    }

    // --- Pomodoro Prompt Panel ---

    private void PomodoroToggled(object sender, RoutedEventArgs e)
    {
        UpdatePomodoroPromptsPanel();
    }

    private void UpdatePomodoroPromptsPanel()
    {
        if (PomodoroPromptsPanel == null) return;
        bool enabled = EnablePomodoroIntegrationCheck.IsChecked == true;
        PomodoroPromptsPanel.Visibility = enabled ? Visibility.Visible : Visibility.Collapsed;
    }

    private void ResetPomoPrompts_Click(object sender, RoutedEventArgs e)
    {
        var defaults = new PomodoroIntegrationConfig();
        PomoWorkStartedPromptBox.Text = defaults.WorkStartedPrompt;
        PomoWorkFinishedPromptBox.Text = defaults.WorkFinishedPrompt;
        PomoBreakStartedPromptBox.Text = defaults.BreakStartedPrompt;
        PomoBreakFinishedPromptBox.Text = defaults.BreakFinishedPrompt;
        PomoTaskAddedPromptBox.Text = defaults.TaskAddedPrompt;
    }

    // --- Activity Monitor ---

    private void ActivityMonitorToggled(object sender, RoutedEventArgs e)
    {
        UpdateActivityMonitorPanel();
    }

    private void UpdateActivityMonitorPanel()
    {
        if (ActivityMonitorPanel == null) return;
        bool enabled = EnableActivityMonitorCheck.IsChecked == true;
        ActivityMonitorPanel.IsEnabled = enabled;
        ActivityMonitorPanel.Opacity = enabled ? 1.0 : 0.5;
    }

    private void BrowseActivityDb_Click(object sender, RoutedEventArgs e)
    {
        var dialog = new Microsoft.Win32.OpenFileDialog
        {
            Title = "Select monitor.db SQLite database",
            Filter = "SQLite database|*.db|All files|*.*",
            CheckFileExists = true
        };

        var currentPath = ActivityDbPathBox.Text;
        if (!string.IsNullOrEmpty(currentPath))
        {
            var dir = System.IO.Path.GetDirectoryName(currentPath);
            if (dir != null && System.IO.Directory.Exists(dir))
                dialog.InitialDirectory = dir;
        }

        if (dialog.ShowDialog(this) == true)
            ActivityDbPathBox.Text = dialog.FileName;
    }

    // --- Screen Awareness ---

    private bool _visionApiKeyVisible;

    private void ScreenAwarenessToggled(object sender, RoutedEventArgs e)
    {
        UpdateScreenAwarenessPanel();
    }

    private void UpdateScreenAwarenessPanel()
    {
        if (ScreenAwarenessPanel == null) return;
        bool enabled = EnableScreenCheck.IsChecked == true;
        ScreenAwarenessPanel.IsEnabled = enabled;
        ScreenAwarenessPanel.Opacity = enabled ? 1.0 : 0.5;
    }

    private void ToggleVisionApiKey_Click(object sender, RoutedEventArgs e)
    {
        _visionApiKeyVisible = !_visionApiKeyVisible;
        ToggleVisionKeyBtn.Content = _visionApiKeyVisible ? "Hide" : "Show";
    }

    private void VisionProviderCombo_SelectionChanged(object sender, SelectionChangedEventArgs e)
    {
        UpdateVisionProviderPanels();
    }

    private void UpdateVisionProviderPanels()
    {
        if (VisionApiKeyPanel == null || OllamaPanel == null || HybridCloudPanel == null) return;

        var provider = GetComboTag(VisionProviderCombo, "gemini");

        // Cloud key panel: visible for gemini/claude
        VisionApiKeyPanel.Visibility = provider is "gemini" or "claude"
            ? Visibility.Visible : Visibility.Collapsed;

        // Ollama panel: visible for ollama/local_hybrid
        OllamaPanel.Visibility = provider is "ollama" or "local_hybrid"
            ? Visibility.Visible : Visibility.Collapsed;

        // Hybrid cloud panel: visible for local_hybrid only
        HybridCloudPanel.Visibility = provider == "local_hybrid"
            ? Visibility.Visible : Visibility.Collapsed;
    }

    private void PrivacyDownscaleToggled(object sender, RoutedEventArgs e)
    {
        UpdateDownscalePanel();
    }

    private void UpdateDownscalePanel()
    {
        if (DownscaleResolutionPanel == null) return;
        bool enabled = EnablePrivacyDownscaleCheck.IsChecked == true;
        DownscaleResolutionPanel.IsEnabled = enabled;
        DownscaleResolutionPanel.Opacity = enabled ? 1.0 : 0.5;
    }

    private void ResetScreenPrompt_Click(object sender, RoutedEventArgs e)
    {
        var defaults = new ScreenAwarenessConfig();
        ScreenPromptBox.Text = defaults.AnalysisPrompt;
    }

    // --- Companion Apps ---

    private void BrowseMonitorPath_Click(object sender, RoutedEventArgs e)
    {
        var path = BrowseForFile("Executable or batch|*.exe;*.bat|All files|*.*");
        if (path != null) MonitorPathBox.Text = path;
    }

    private void BrowseTodoPath_Click(object sender, RoutedEventArgs e)
    {
        var path = BrowseForFile("Executable or batch|*.exe;*.bat|All files|*.*");
        if (path != null) TodoPathBox.Text = path;
    }

    // --- Backend ---

    private void BackendToggled(object sender, RoutedEventArgs e)
    {
        UpdateBackendPanel();
    }

    private void UpdateBackendPanel()
    {
        if (BackendPanel == null) return;
        bool enabled = EnableBackendCheck.IsChecked == true;
        BackendPanel.IsEnabled = enabled;
        BackendPanel.Opacity = enabled ? 1.0 : 0.5;
    }

    private void BrowsePythonPath_Click(object sender, RoutedEventArgs e)
    {
        var dialog = new Microsoft.Win32.OpenFileDialog
        {
            Title = "Select Python executable",
            Filter = "Python|python.exe;python3.exe|All files|*.*",
            CheckFileExists = false
        };
        if (dialog.ShowDialog(this) == true)
            PythonPathBox.Text = dialog.FileName;
    }

    // --- MCP ---

    private void PopulateMcpServerList()
    {
        _suppressMcpEvent = true;
        McpServerListBox.Items.Clear();

        foreach (var server in _mcpServers)
        {
            var prefix = server.Enabled ? "" : "[off] ";
            McpServerListBox.Items.Add($"{prefix}{server.Name}");
        }

        _suppressMcpEvent = false;
        UpdateMcpServerEditor();
    }

    private void McpServerList_SelectionChanged(object sender, SelectionChangedEventArgs e)
    {
        if (_suppressMcpEvent) return;
        SaveCurrentMcpServerEdits();
        UpdateMcpServerEditor();
    }

    private void UpdateMcpServerEditor()
    {
        if (McpServerEditor == null) return;

        var server = GetSelectedMcpServer();
        if (server == null)
        {
            McpServerEditor.Visibility = Visibility.Collapsed;
            return;
        }

        McpServerEditor.Visibility = Visibility.Visible;
        McpServerNameBox.Text = server.Name;
        McpServerCommandBox.Text = server.Command;
        McpServerArgsBox.Text = server.Arguments;
        SelectComboByTag(McpTransportCombo, server.TransportType);
        McpServerEnabledCheck.IsChecked = server.Enabled;
    }

    private McpServerDefinition? GetSelectedMcpServer()
    {
        int idx = McpServerListBox.SelectedIndex;
        if (idx < 0 || idx >= _mcpServers.Count) return null;
        return _mcpServers[idx];
    }

    private void SaveCurrentMcpServerEdits()
    {
        var server = GetSelectedMcpServer();
        if (server == null || McpServerNameBox == null) return;

        var newName = McpServerNameBox.Text.Trim();
        if (!string.IsNullOrEmpty(newName))
            server.Name = newName;

        server.Command = McpServerCommandBox.Text;
        server.Arguments = McpServerArgsBox.Text;
        server.TransportType = GetComboTag(McpTransportCombo, "stdio");
        server.Enabled = McpServerEnabledCheck.IsChecked == true;

        // Refresh display name
        int idx = McpServerListBox.SelectedIndex;
        if (idx >= 0 && idx < McpServerListBox.Items.Count)
        {
            var prefix = server.Enabled ? "" : "[off] ";
            McpServerListBox.Items[idx] = $"{prefix}{server.Name}";
        }
    }

    private void McpAddServer_Click(object sender, RoutedEventArgs e)
    {
        int n = 1;
        string name;
        do
        {
            name = $"Server {n++}";
        } while (_mcpServers.Any(s => s.Name == name));

        var server = new McpServerDefinition
        {
            Id = Guid.NewGuid().ToString("N")[..8],
            Name = name
        };
        _mcpServers.Add(server);
        PopulateMcpServerList();
        McpServerListBox.SelectedIndex = _mcpServers.Count - 1;
    }

    private void McpRemoveServer_Click(object sender, RoutedEventArgs e)
    {
        var server = GetSelectedMcpServer();
        if (server == null) return;

        var result = MessageBox.Show(
            $"Remove server \"{server.Name}\"?",
            "Remove MCP Server",
            MessageBoxButton.YesNo,
            MessageBoxImage.Question);

        if (result != MessageBoxResult.Yes) return;

        _mcpServers.Remove(server);
        PopulateMcpServerList();
    }

    private void Cancel_Click(object sender, RoutedEventArgs e)
    {
        DialogResult = false;
        Close();
    }
}
