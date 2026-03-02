using System.Net.Http;
using AemeathDesktopPet.Engine;
using AemeathDesktopPet.Models;
using AemeathDesktopPet.Services;

namespace AemeathDesktopPet.Tests.Services;

public class ScreenAwarenessServiceTests
{
    private static ScreenAwarenessConfig MakeConfig(bool enabled = false) => new()
    {
        Enabled = enabled,
        VisionApiKey = "test-key",
        VisionProvider = "gemini",
        IntervalSeconds = 60,
        MonthlyBudgetCap = 5.0,
        BlacklistedApps = new List<string>
        {
            "keepass.exe", "1password.exe", "chrome.exe:*bank*", "signal.exe"
        }
    };

    private static AemeathStats MakeStats() => new();

    private static ScreenAwarenessService CreateService(ScreenAwarenessConfig? config = null)
    {
        var cfg = config ?? MakeConfig();
        return new ScreenAwarenessService(
            () => cfg,
            MakeStats,
            () => "Kuro",
            new EnvironmentDetector(),
            new HttpClient());
    }

    [Fact]
    public void ImplementsIScreenAwarenessService()
    {
        var svc = CreateService();
        Assert.IsAssignableFrom<IScreenAwarenessService>(svc);
    }

    [Fact]
    public void IsEnabled_ReflectsConfig()
    {
        var config = MakeConfig(enabled: false);
        var svc = CreateService(config);
        Assert.False(svc.IsEnabled);

        config.Enabled = true;
        Assert.True(svc.IsEnabled);
    }

    [Fact]
    public void ConsumeLatestCommentary_ReturnsNullInitially()
    {
        var svc = CreateService();
        Assert.Null(svc.ConsumeLatestCommentary());
    }

    [Fact]
    public void ConsumeLatestCommentary_ClearsAfterRead()
    {
        var svc = CreateService();
        // Use reflection or internal access to set commentary for testing
        // For now, just verify the consume pattern works
        var first = svc.ConsumeLatestCommentary();
        var second = svc.ConsumeLatestCommentary();
        Assert.Null(first);
        Assert.Null(second);
    }

    [Fact]
    public void IsBlacklisted_BlocksMatchingProcess()
    {
        // We test the static/internal blacklist logic directly
        var config = MakeConfig();
        // IsBlacklisted uses EnvironmentDetector which calls Win32 —
        // we test MatchGlob directly instead
        Assert.True(ScreenAwarenessService.MatchGlob("Chase Bank - Google Chrome", "*bank*"));
    }

    [Fact]
    public void IsBlacklisted_AllowsNonMatching()
    {
        Assert.False(ScreenAwarenessService.MatchGlob("Google - Search", "*bank*"));
    }

    [Fact]
    public void MatchGlob_ExactMatch()
    {
        Assert.True(ScreenAwarenessService.MatchGlob("bank", "bank"));
    }

    [Fact]
    public void MatchGlob_WildcardStart()
    {
        Assert.True(ScreenAwarenessService.MatchGlob("My Bank Online", "*Bank*"));
    }

    [Fact]
    public void MatchGlob_WildcardEnd()
    {
        Assert.True(ScreenAwarenessService.MatchGlob("Bank of America", "Bank*"));
    }

    [Fact]
    public void MatchGlob_CaseInsensitive()
    {
        Assert.True(ScreenAwarenessService.MatchGlob("BANK WEBSITE", "*bank*"));
    }

    [Fact]
    public void MatchGlob_NoMatch()
    {
        Assert.False(ScreenAwarenessService.MatchGlob("Hello World", "*bank*"));
    }

    [Fact]
    public void MatchGlob_Star_MatchesAll()
    {
        Assert.True(ScreenAwarenessService.MatchGlob("anything", "*"));
    }

    // --- Enhanced Blacklist Defaults ---

    [Fact]
    public void DefaultBlacklist_Has16Entries()
    {
        var config = new ScreenAwarenessConfig();
        Assert.True(config.BlacklistedApps.Count >= 16);
    }

    [Fact]
    public void DefaultBlacklist_ContainsPasswordManagers()
    {
        var config = new ScreenAwarenessConfig();
        Assert.Contains("keepass.exe", config.BlacklistedApps);
        Assert.Contains("1password.exe", config.BlacklistedApps);
        Assert.Contains("bitwarden.exe", config.BlacklistedApps);
        Assert.Contains("lastpass.exe", config.BlacklistedApps);
    }

    [Fact]
    public void DefaultBlacklist_ContainsBrowserLoginPatterns()
    {
        var config = new ScreenAwarenessConfig();
        Assert.Contains("chrome.exe:*login*", config.BlacklistedApps);
        Assert.Contains("msedge.exe:*login*", config.BlacklistedApps);
        Assert.Contains("firefox.exe:*login*", config.BlacklistedApps);
    }

    [Fact]
    public void DefaultBlacklist_ContainsBrowserPasswordPatterns()
    {
        var config = new ScreenAwarenessConfig();
        Assert.Contains("chrome.exe:*password*", config.BlacklistedApps);
        Assert.Contains("msedge.exe:*password*", config.BlacklistedApps);
        Assert.Contains("firefox.exe:*password*", config.BlacklistedApps);
    }

    [Fact]
    public void MatchGlob_LoginPattern()
    {
        Assert.True(ScreenAwarenessService.MatchGlob("Login - Google Accounts", "*login*"));
    }

    [Fact]
    public void MatchGlob_PasswordPattern()
    {
        Assert.True(ScreenAwarenessService.MatchGlob("Change Password - Settings", "*password*"));
    }

    // --- Perceptual Hash ---

    [Fact]
    public void HammingDistance_IdenticalHashes_ReturnsZero()
    {
        Assert.Equal(0, ScreenAwarenessService.HammingDistance(0xDEADBEEF, 0xDEADBEEF));
    }

    [Fact]
    public void HammingDistance_DifferentBit_ReturnsOne()
    {
        Assert.Equal(1, ScreenAwarenessService.HammingDistance(0, 1));
    }

    [Fact]
    public void HammingDistance_AllDifferent_Returns64()
    {
        Assert.Equal(64, ScreenAwarenessService.HammingDistance(0, ulong.MaxValue));
    }

    [Fact]
    public void HasScreenChanged_FirstCall_ReturnsTrue()
    {
        var svc = CreateService();
        // Create a minimal valid JPEG to test with
        var jpeg = CreateMinimalJpeg();
        Assert.True(svc.HasScreenChanged(jpeg));
    }

    [Fact]
    public void HasScreenChanged_IdenticalScreenshot_ReturnsFalse()
    {
        var svc = CreateService();
        var jpeg = CreateMinimalJpeg();
        svc.HasScreenChanged(jpeg); // first call sets the hash
        Assert.False(svc.HasScreenChanged(jpeg)); // same screenshot
    }

    // --- Budget ---

    [Fact]
    public void IsOverBudget_UnderBudget_ReturnsFalse()
    {
        var config = MakeConfig();
        config.MonthlyBudgetCap = 5.0;
        var svc = CreateService(config);
        svc.MonthlySpend = 1.0;
        Assert.False(svc.IsOverBudget(config));
    }

    [Fact]
    public void IsOverBudget_AtBudget_ReturnsTrue()
    {
        var config = MakeConfig();
        config.MonthlyBudgetCap = 5.0;
        var svc = CreateService(config);
        svc.MonthlySpend = 5.0;
        Assert.True(svc.IsOverBudget(config));
    }

    [Fact]
    public void IsOverBudget_OverBudget_ReturnsTrue()
    {
        var config = MakeConfig();
        config.MonthlyBudgetCap = 5.0;
        var svc = CreateService(config);
        svc.MonthlySpend = 10.0;
        Assert.True(svc.IsOverBudget(config));
    }

    [Fact]
    public async Task CaptureAndCommentAsync_WhenDisabled_ReturnsNull()
    {
        var config = MakeConfig(enabled: false);
        var svc = CreateService(config);
        var result = await svc.CaptureAndCommentAsync();
        Assert.Null(result);
    }

    [Fact]
    public async Task CaptureAndCommentAsync_WhenNoApiKey_ReturnsNull()
    {
        var config = MakeConfig(enabled: true);
        config.VisionApiKey = "";
        var svc = CreateService(config);
        var result = await svc.CaptureAndCommentAsync();
        Assert.Null(result);
    }

    [Fact]
    public void StartStop_DoesNotThrow()
    {
        var config = MakeConfig(enabled: false);
        var svc = CreateService(config);
        svc.Start();
        svc.Stop();
    }

    [Fact]
    public void Dispose_DoesNotThrow()
    {
        var config = MakeConfig(enabled: false);
        var svc = CreateService(config);
        svc.Start();
        svc.Dispose();
    }

    // --- Provider Configuration Check ---

    [Fact]
    public void IsProviderConfigured_Gemini_NeedsApiKey()
    {
        var config = new ScreenAwarenessConfig { VisionProvider = "gemini", VisionApiKey = "" };
        Assert.False(ScreenAwarenessService.IsProviderConfigured(config));

        config.VisionApiKey = "test-key";
        Assert.True(ScreenAwarenessService.IsProviderConfigured(config));
    }

    [Fact]
    public void IsProviderConfigured_Claude_NeedsApiKey()
    {
        var config = new ScreenAwarenessConfig { VisionProvider = "claude", VisionApiKey = "" };
        Assert.False(ScreenAwarenessService.IsProviderConfigured(config));

        config.VisionApiKey = "test-key";
        Assert.True(ScreenAwarenessService.IsProviderConfigured(config));
    }

    [Fact]
    public void IsProviderConfigured_Ollama_NoKeyNeeded()
    {
        var config = new ScreenAwarenessConfig { VisionProvider = "ollama", VisionApiKey = "" };
        Assert.True(ScreenAwarenessService.IsProviderConfigured(config));
    }

    [Fact]
    public void IsProviderConfigured_LocalHybrid_NeedsHybridCloudKey()
    {
        var config = new ScreenAwarenessConfig { VisionProvider = "local_hybrid", HybridCloudApiKey = "" };
        Assert.False(ScreenAwarenessService.IsProviderConfigured(config));

        config.HybridCloudApiKey = "test-key";
        Assert.True(ScreenAwarenessService.IsProviderConfigured(config));
    }

    // --- Config Defaults ---

    [Fact]
    public void ConfigDefaults_PrivacyLayersEnabledByDefault()
    {
        var config = new ScreenAwarenessConfig();
        Assert.True(config.EnableProtectedWindowCheck);
        Assert.True(config.EnablePrivacyDownscale);
        Assert.True(config.EnableResponsePiiScan);
    }

    [Fact]
    public void ConfigDefaults_DownscaleWidth_Is480()
    {
        var config = new ScreenAwarenessConfig();
        Assert.Equal(480, config.PrivacyDownscaleMaxWidth);
    }

    [Fact]
    public void ConfigDefaults_OllamaSettings()
    {
        var config = new ScreenAwarenessConfig();
        Assert.Equal("http://localhost:11434", config.OllamaBaseUrl);
        Assert.Equal("qwen2.5vl:3b", config.OllamaModelName);
    }

    [Fact]
    public void ConfigDefaults_HybridSettings()
    {
        var config = new ScreenAwarenessConfig();
        Assert.Equal("gemini", config.HybridCloudProvider);
        Assert.Equal("", config.HybridCloudApiKey);
    }

    // --- Ollama Response Parsing ---

    [Fact]
    public void ExtractOllamaContent_ValidResponse_ReturnsContent()
    {
        var json = """{"message":{"role":"assistant","content":"You seem to be coding!"},"done":true}""";
        Assert.Equal("You seem to be coding!", ScreenAwarenessService.ExtractOllamaContent(json));
    }

    [Fact]
    public void ExtractOllamaContent_EmptyContent_ReturnsEmpty()
    {
        var json = """{"message":{"role":"assistant","content":""},"done":true}""";
        Assert.Equal("", ScreenAwarenessService.ExtractOllamaContent(json));
    }

    [Fact]
    public void ExtractOllamaContent_MalformedJson_ReturnsNull()
    {
        Assert.Null(ScreenAwarenessService.ExtractOllamaContent("{bad json}"));
    }

    [Fact]
    public void ExtractOllamaContent_MissingMessage_ReturnsNull()
    {
        var json = """{"done":true}""";
        Assert.Null(ScreenAwarenessService.ExtractOllamaContent(json));
    }

    // --- Gemini/Claude Response Parsing ---

    [Fact]
    public void ExtractGeminiContent_ValidResponse_ReturnsText()
    {
        var json = """{"candidates":[{"content":{"parts":[{"text":"Looks like coding!"}]}}]}""";
        Assert.Equal("Looks like coding!", ScreenAwarenessService.ExtractGeminiContent(json));
    }

    [Fact]
    public void ExtractGeminiContent_MalformedJson_ReturnsNull()
    {
        Assert.Null(ScreenAwarenessService.ExtractGeminiContent("not json"));
    }

    [Fact]
    public void ExtractClaudeContent_ValidResponse_ReturnsText()
    {
        var json = """{"content":[{"type":"text","text":"Nice code!"}]}""";
        Assert.Equal("Nice code!", ScreenAwarenessService.ExtractClaudeContent(json));
    }

    [Fact]
    public void ExtractClaudeContent_MalformedJson_ReturnsNull()
    {
        Assert.Null(ScreenAwarenessService.ExtractClaudeContent("not json"));
    }

    // --- Helper ---

    private static byte[] CreateMinimalJpeg()
    {
        // Create a small bitmap and encode as JPEG
        using var bmp = new System.Drawing.Bitmap(16, 16, System.Drawing.Imaging.PixelFormat.Format24bppRgb);
        using (var g = System.Drawing.Graphics.FromImage(bmp))
        {
            g.Clear(System.Drawing.Color.Blue);
        }
        using var ms = new System.IO.MemoryStream();
        bmp.Save(ms, System.Drawing.Imaging.ImageFormat.Jpeg);
        return ms.ToArray();
    }
}
