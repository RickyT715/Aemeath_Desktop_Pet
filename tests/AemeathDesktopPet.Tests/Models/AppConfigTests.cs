using AemeathDesktopPet.Models;

namespace AemeathDesktopPet.Tests.Models;

public class AppConfigTests
{
    [Fact]
    public void AppConfig_DefaultValues()
    {
        var config = new AppConfig();

        Assert.Equal("", config.ApiKey);
        Assert.Equal(200, config.PetSize);
        Assert.Equal(1.0, config.Opacity);
        Assert.False(config.StartWithWindows);
        Assert.True(config.EnableGlitchEffect);
        Assert.True(config.EnableSinging);
        Assert.True(config.EnableBlackCat);
        Assert.Equal("Kuro", config.CatName);
        Assert.True(config.EnableAmbientPaperPlanes);
        Assert.Equal(5, config.PaperPlaneFrequencyMinutes);
        Assert.Equal("normal", config.BehaviorFrequency);
        Assert.True(config.CloseToTray);
        Assert.Equal("default", config.Theme);
    }

    [Fact]
    public void AppConfig_DefaultPosition_IsNegativeOne()
    {
        var config = new AppConfig();
        Assert.Equal(-1, config.LastX);
        Assert.Equal(-1, config.LastY);
    }

    [Fact]
    public void AppConfig_TtsConfig_NotNull()
    {
        var config = new AppConfig();
        Assert.NotNull(config.Tts);
    }

    [Fact]
    public void AppConfig_ScreenAwarenessConfig_NotNull()
    {
        var config = new AppConfig();
        Assert.NotNull(config.ScreenAwareness);
    }

    [Fact]
    public void AppConfig_PomodoroIntegrationConfig_NotNull()
    {
        var config = new AppConfig();
        Assert.NotNull(config.PomodoroIntegration);
        Assert.True(config.PomodoroIntegration.Enabled);
        Assert.Equal("AemeathDesktopPet", config.PomodoroIntegration.PipeName);
    }

    [Fact]
    public void TtsConfig_DefaultValues()
    {
        var tts = new TtsConfig();

        Assert.False(tts.Enabled);
        Assert.Equal("edgetts", tts.Provider);
        Assert.Equal("http://localhost:9880", tts.GptsovitsUrl);
        Assert.Equal("en-US-AvaMultilingualNeural", tts.EdgeTtsVoice);
        Assert.Equal("", tts.ElevenLabsApiKey);
        Assert.Equal("21m00Tcm4TlvDq8ikWAM", tts.ElevenLabsVoiceId);
        Assert.Equal("eleven_multilingual_v2", tts.ElevenLabsModelId);
        Assert.Equal(0.7, tts.Volume);
        Assert.True(tts.SpeakChatResponses);
        Assert.False(tts.SpeakIdleChatter);
        Assert.True(tts.AutoMuteFullscreen);
    }

    [Fact]
    public void ScreenAwarenessConfig_DefaultValues()
    {
        var sa = new ScreenAwarenessConfig();

        Assert.False(sa.Enabled);
        Assert.Equal(60, sa.IntervalSeconds);
        Assert.Equal(1, sa.PrivacyTier);
        Assert.Equal("gemini", sa.VisionProvider);
        Assert.Equal("", sa.VisionApiKey);
        Assert.False(sa.UseLocalPreFilter);
        Assert.Equal("phi3-vision", sa.LocalModelName);
        Assert.True(sa.BlurTaskbar);
        Assert.True(sa.BlurAddressBar);
        Assert.Equal(5.00, sa.MonthlyBudgetCap);
        Assert.True(sa.ShowScreenWatchIndicator);
    }

    [Fact]
    public void ScreenAwarenessConfig_AnalysisPrompt_HasNonEmptyDefault()
    {
        var sa = new ScreenAwarenessConfig();
        Assert.False(string.IsNullOrWhiteSpace(sa.AnalysisPrompt));
        Assert.Contains("Screen Awareness", sa.AnalysisPrompt);
    }

    [Fact]
    public void ScreenAwarenessConfig_DefaultBlacklist()
    {
        var sa = new ScreenAwarenessConfig();

        Assert.NotNull(sa.BlacklistedApps);
        Assert.Equal(4, sa.BlacklistedApps.Count);
        Assert.Contains("keepass.exe", sa.BlacklistedApps);
        Assert.Contains("1password.exe", sa.BlacklistedApps);
        Assert.Contains("signal.exe", sa.BlacklistedApps);
        Assert.Contains("chrome.exe:*bank*", sa.BlacklistedApps);
    }

    [Fact]
    public void AppConfig_SpeechFrequencyConfig_NotNull()
    {
        var config = new AppConfig();
        Assert.NotNull(config.SpeechFrequency);
    }

    [Fact]
    public void AppConfig_CompanionAppsConfig_NotNull_WithDefaults()
    {
        var config = new AppConfig();
        Assert.NotNull(config.CompanionApps);
        Assert.False(config.CompanionApps.LaunchMonitor);
        Assert.False(config.CompanionApps.LaunchTodoList);
        Assert.False(string.IsNullOrEmpty(config.CompanionApps.MonitorPath));
        Assert.False(string.IsNullOrEmpty(config.CompanionApps.TodoListPath));
    }

    [Fact]
    public void AppConfig_MutableProperties()
    {
        var config = new AppConfig();
        config.PetSize = 250;
        config.Opacity = 0.8;
        config.LastX = 100;
        config.LastY = 200;
        config.ApiKey = "test-key";

        Assert.Equal(250, config.PetSize);
        Assert.Equal(0.8, config.Opacity);
        Assert.Equal(100, config.LastX);
        Assert.Equal(200, config.LastY);
        Assert.Equal("test-key", config.ApiKey);
    }
}
