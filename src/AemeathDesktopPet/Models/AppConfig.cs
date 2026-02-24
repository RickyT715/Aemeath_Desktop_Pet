using System.Text.Json.Serialization;

namespace AemeathDesktopPet.Models;

public class AppConfig
{
    public string ApiKey { get; set; } = "";
    public int PetSize { get; set; } = 200;
    public double Opacity { get; set; } = 1.0;
    public bool StartWithWindows { get; set; } = false;
    public bool EnableGlitchEffect { get; set; } = true;
    public bool EnableSinging { get; set; } = true;
    public bool EnableBlackCat { get; set; } = true;
    public string CatName { get; set; } = "Kuro";
    public bool EnableAmbientPaperPlanes { get; set; } = true;
    public int PaperPlaneFrequencyMinutes { get; set; } = 5;
    public string BehaviorFrequency { get; set; } = "normal";
    public bool CloseToTray { get; set; } = true;
    public string Theme { get; set; } = "default";

    // AI Provider: "claude" or "gemini"
    public string AiProvider { get; set; } = "claude";
    public string GeminiApiKey { get; set; } = "";

    // Music
    public string MusicFolderPath { get; set; } = "";

    // Last known position
    public double LastX { get; set; } = -1;
    public double LastY { get; set; } = -1;

    public TtsConfig Tts { get; set; } = new();
    public ScreenAwarenessConfig ScreenAwareness { get; set; } = new();
    public VoiceInputConfig VoiceInput { get; set; } = new();
    public PomodoroIntegrationConfig PomodoroIntegration { get; set; } = new();
    public ActivityMonitorConfig ActivityMonitor { get; set; } = new();
    public SpeechFrequencyConfig SpeechFrequency { get; set; } = new();
    public CompanionAppsConfig CompanionApps { get; set; } = new();
}

public class TtsConfig
{
    public bool Enabled { get; set; } = false;
    public string Provider { get; set; } = "edgetts";
    public string GptsovitsUrl { get; set; } = "http://localhost:9880";
    public List<GptSovitsProfile> GptsovitsProfiles { get; set; } = new();
    public string GptsovitsActiveProfile { get; set; } = "";
    public string EdgeTtsVoice { get; set; } = "en-US-AvaMultilingualNeural";
    public string ElevenLabsApiKey { get; set; } = "";
    public string ElevenLabsVoiceId { get; set; } = "21m00Tcm4TlvDq8ikWAM";
    public string ElevenLabsModelId { get; set; } = "eleven_multilingual_v2";
    public string FishAudioApiKey { get; set; } = "";
    public string FishAudioModelId { get; set; } = "";
    public string FishAudioBaseUrl { get; set; } = "https://api.fish.audio";
    public string OpenAiTtsApiKey { get; set; } = "";
    public string OpenAiTtsModel { get; set; } = "tts-1";
    public string OpenAiTtsVoice { get; set; } = "alloy";
    public double OpenAiTtsSpeed { get; set; } = 1.0;
    public double Volume { get; set; } = 0.7;
    public bool SpeakChatResponses { get; set; } = true;
    public bool SpeakIdleChatter { get; set; } = false;
    public bool AutoMuteFullscreen { get; set; } = true;
}

public class GptSovitsProfile
{
    public string Name { get; set; } = "Default";
    public string GptWeightsPath { get; set; } = "";
    public string SovitsWeightsPath { get; set; } = "";
    public string RefAudioPath { get; set; } = "";
    public string PromptText { get; set; } = "";
    public string PromptLang { get; set; } = "auto";
    public string TextLang { get; set; } = "auto";
    public double SpeedFactor { get; set; } = 1.0;
}

public class VoiceInputConfig
{
    public bool Enabled { get; set; } = false;
    public string SttProvider { get; set; } = "whisper"; // "whisper" or "gemini"
    public string SttApiKey { get; set; } = ""; // Whisper (OpenAI) API key; Gemini reuses GeminiApiKey
    public string Language { get; set; } = "en";
    public bool IncludeScreenshot { get; set; } = false;
    public string Hotkey { get; set; } = "Ctrl+F2";
}

public class PomodoroIntegrationConfig
{
    public bool Enabled { get; set; } = true;
    public string PipeName { get; set; } = "AemeathDesktopPet";

    public string WorkStartedPrompt { get; set; } =
        "[Pomodoro Timer] I just started a {duration}-minute work session on \"{taskTitle}\". Say something short (1-2 sentences) to encourage me and remind me to focus.";
    public string WorkFinishedPrompt { get; set; } =
        "[Pomodoro Timer] I just finished my pomodoro work session on \"{taskTitle}\"! Say something short (1-2 sentences) to celebrate and congratulate me.";
    public string BreakStartedPrompt { get; set; } =
        "[Pomodoro Timer] I'm starting a {breakType} break ({duration} minutes). Say something short (1-2 sentences) to help me relax or chat with me.";
    public string BreakFinishedPrompt { get; set; } =
        "[Pomodoro Timer] My break is over, time to get back to work. Say something short (1-2 sentences) to motivate me.";
    public string TaskAddedPrompt { get; set; } =
        "[Pomodoro Timer] I just added a new task to my to-do list: \"{taskTitle}\". React briefly (1 sentence).";
}

public class ScreenAwarenessConfig
{
    public bool Enabled { get; set; } = false;
    public int IntervalSeconds { get; set; } = 60;
    public int PrivacyTier { get; set; } = 1;
    public string VisionProvider { get; set; } = "gemini";
    public string VisionApiKey { get; set; } = "";
    public bool UseLocalPreFilter { get; set; } = false;
    public string LocalModelName { get; set; } = "phi3-vision";
    public List<string> BlacklistedApps { get; set; } = new()
    {
        "chrome.exe:*bank*", "keepass.exe", "1password.exe", "signal.exe"
    };
    public bool BlurTaskbar { get; set; } = true;
    public bool BlurAddressBar { get; set; } = true;
    public double MonthlyBudgetCap { get; set; } = 5.00;
    public bool ShowScreenWatchIndicator { get; set; } = true;
    public string AnalysisPrompt { get; set; } =
        "[Screen Awareness] Look at this screenshot and make a brief, natural observation (1-2 sentences) about what the user seems to be doing. Be casual and in-character. NEVER read or repeat specific text, numbers, names, passwords, or identifiable information visible on screen. Just comment on the general activity.";
}

public class ActivityMonitorConfig
{
    public bool Enabled { get; set; } = false;
    public string DatabasePath { get; set; } = @"D:\Study\Project\Computer_and_Chrome_Monitor_with_AI_Analysis\data\monitor.db";
}

public enum ActivityContext
{
    Default,
    PomodoroWork,
    PomodoroBreak,
    Gaming,
    WatchingVideos,
    StudyingCoding
}

public enum SpeechFrequencyLevel
{
    Silent,
    Rare,
    Normal,
    Chatty
}

public class SpeechFrequencyConfig
{
    public string PomodoroWork { get; set; } = "Silent";
    public string PomodoroBreak { get; set; } = "Chatty";
    public string Gaming { get; set; } = "Rare";
    public string WatchingVideos { get; set; } = "Rare";
    public string StudyingCoding { get; set; } = "Normal";
    public string Default { get; set; } = "Normal";

    public SpeechFrequencyLevel GetLevel(ActivityContext context)
    {
        var raw = context switch
        {
            ActivityContext.PomodoroWork => PomodoroWork,
            ActivityContext.PomodoroBreak => PomodoroBreak,
            ActivityContext.Gaming => Gaming,
            ActivityContext.WatchingVideos => WatchingVideos,
            ActivityContext.StudyingCoding => StudyingCoding,
            _ => Default
        };

        if (Enum.TryParse<SpeechFrequencyLevel>(raw, ignoreCase: true, out var level))
            return level;
        return SpeechFrequencyLevel.Normal;
    }

    public static (double min, double max)? GetInterval(SpeechFrequencyLevel level) => level switch
    {
        SpeechFrequencyLevel.Silent => null,
        SpeechFrequencyLevel.Rare => (120, 240),
        SpeechFrequencyLevel.Normal => (45, 90),
        SpeechFrequencyLevel.Chatty => (15, 30),
        _ => (45, 90)
    };
}

public class CompanionAppsConfig
{
    public bool LaunchMonitor { get; set; } = false;
    public string MonitorPath { get; set; } = @"D:\Study\Project\Computer_and_Chrome_Monitor_with_AI_Analysis\run.bat";
    public bool LaunchTodoList { get; set; } = false;
    public string TodoListPath { get; set; } = @"D:\Study\Project\To_Do_List\run.bat";
}
