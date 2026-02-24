using System.Text.Json;
using AemeathDesktopPet.Models;
using AemeathDesktopPet.Services;

namespace AemeathDesktopPet.Tests.Services;

public class ConfigServiceTests : IDisposable
{
    private readonly string _tempDir;

    public ConfigServiceTests()
    {
        _tempDir = Path.Combine(Path.GetTempPath(), "AemeathTests_" + Guid.NewGuid().ToString("N")[..8]);
    }

    public void Dispose()
    {
        if (Directory.Exists(_tempDir))
            Directory.Delete(_tempDir, recursive: true);
    }

    [Fact]
    public void Load_CreatesDefaultConfig_WhenNoFileExists()
    {
        var svc = new ConfigService(_tempDir);
        svc.Load();

        Assert.NotNull(svc.Config);
        Assert.Equal(200, svc.Config.PetSize);
        Assert.Equal(1.0, svc.Config.Opacity);

        // Should also create the file on disk
        var configPath = Path.Combine(_tempDir, "config.json");
        Assert.True(File.Exists(configPath));
    }

    [Fact]
    public void SaveAndLoad_RoundTrip()
    {
        var svc = new ConfigService(_tempDir);
        svc.Load();

        // Modify config
        svc.Config.PetSize = 250;
        svc.Config.Opacity = 0.75;
        svc.Config.ApiKey = "test-api-key";
        svc.Config.LastX = 400;
        svc.Config.LastY = 300;
        svc.Save();

        // Load into a new service instance
        var svc2 = new ConfigService(_tempDir);
        svc2.Load();

        Assert.Equal(250, svc2.Config.PetSize);
        Assert.Equal(0.75, svc2.Config.Opacity);
        Assert.Equal("test-api-key", svc2.Config.ApiKey);
        Assert.Equal(400, svc2.Config.LastX);
        Assert.Equal(300, svc2.Config.LastY);
    }

    [Fact]
    public void SavePosition_UpdatesConfig()
    {
        var svc = new ConfigService(_tempDir);
        svc.Load();

        svc.SavePosition(123.4, 567.8);

        Assert.Equal(123.4, svc.Config.LastX);
        Assert.Equal(567.8, svc.Config.LastY);

        // Verify persisted to disk
        var svc2 = new ConfigService(_tempDir);
        svc2.Load();
        Assert.Equal(123.4, svc2.Config.LastX);
        Assert.Equal(567.8, svc2.Config.LastY);
    }

    [Fact]
    public void Load_HandlesCorruptJson_GracefullyFallsBack()
    {
        Directory.CreateDirectory(_tempDir);
        File.WriteAllText(Path.Combine(_tempDir, "config.json"), "{ invalid json !!!");

        var svc = new ConfigService(_tempDir);
        svc.Load();

        // Should fall back to default config
        Assert.NotNull(svc.Config);
        Assert.Equal(200, svc.Config.PetSize);
    }

    [Fact]
    public void Load_HandlesEmptyFile_GracefullyFallsBack()
    {
        Directory.CreateDirectory(_tempDir);
        File.WriteAllText(Path.Combine(_tempDir, "config.json"), "");

        var svc = new ConfigService(_tempDir);
        svc.Load();

        Assert.NotNull(svc.Config);
        Assert.Equal(200, svc.Config.PetSize);
    }

    [Fact]
    public void Load_HandlesPartialJson_UsesDefaults()
    {
        Directory.CreateDirectory(_tempDir);
        File.WriteAllText(Path.Combine(_tempDir, "config.json"), "{\"petSize\":150}");

        var svc = new ConfigService(_tempDir);
        svc.Load();

        Assert.Equal(150, svc.Config.PetSize);
        Assert.Equal(1.0, svc.Config.Opacity); // default for unspecified field
    }

    [Fact]
    public void Save_TtsConfig_RoundTrip()
    {
        var svc = new ConfigService(_tempDir);
        svc.Load();

        svc.Config.Tts.Enabled = true;
        svc.Config.Tts.Volume = 0.5;
        svc.Config.Tts.Provider = "elevenlabs";
        svc.Save();

        var svc2 = new ConfigService(_tempDir);
        svc2.Load();

        Assert.True(svc2.Config.Tts.Enabled);
        Assert.Equal(0.5, svc2.Config.Tts.Volume);
        Assert.Equal("elevenlabs", svc2.Config.Tts.Provider);
    }

    [Fact]
    public void Save_ScreenAwarenessConfig_RoundTrip()
    {
        var svc = new ConfigService(_tempDir);
        svc.Load();

        svc.Config.ScreenAwareness.Enabled = true;
        svc.Config.ScreenAwareness.IntervalSeconds = 30;
        svc.Config.ScreenAwareness.BlacklistedApps.Add("custom.exe");
        svc.Save();

        var svc2 = new ConfigService(_tempDir);
        svc2.Load();

        Assert.True(svc2.Config.ScreenAwareness.Enabled);
        Assert.Equal(30, svc2.Config.ScreenAwareness.IntervalSeconds);
        Assert.Contains("custom.exe", svc2.Config.ScreenAwareness.BlacklistedApps);
    }

    [Fact]
    public void Constructor_CreatesDirectory()
    {
        var nested = Path.Combine(_tempDir, "sub", "dir");
        var svc = new ConfigService(nested);

        Assert.True(Directory.Exists(nested));
    }

    [Fact]
    public void Save_WritesPrettyJson()
    {
        var svc = new ConfigService(_tempDir);
        svc.Load();
        svc.Save();

        var json = File.ReadAllText(Path.Combine(_tempDir, "config.json"));
        // Pretty-printed JSON should contain newlines and indentation
        Assert.Contains("\n", json);
        Assert.Contains("  ", json);
    }

    [Fact]
    public void Save_UsesCamelCaseNaming()
    {
        var svc = new ConfigService(_tempDir);
        svc.Load();
        svc.Save();

        var json = File.ReadAllText(Path.Combine(_tempDir, "config.json"));
        // Should use camelCase (petSize, not PetSize)
        Assert.Contains("\"petSize\"", json);
        Assert.Contains("\"opacity\"", json);
        Assert.DoesNotContain("\"PetSize\"", json);
    }
}
