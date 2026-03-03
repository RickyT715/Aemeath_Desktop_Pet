using AemeathDesktopPet.Services;

namespace AemeathDesktopPet.Tests.Services;

public class WhisperSttServiceTests
{
    [Fact]
    public void IsAvailable_FalseWhenNoApiKey()
    {
        var service = new WhisperSttService(() => "");
        Assert.False(service.IsAvailable);
    }

    [Fact]
    public void IsAvailable_TrueWhenApiKeySet()
    {
        var service = new WhisperSttService(() => "sk-test-key");
        Assert.True(service.IsAvailable);
    }

    [Fact]
    public void IsAvailable_FalseWhenApiKeyWhitespace()
    {
        var service = new WhisperSttService(() => "   ");
        Assert.False(service.IsAvailable);
    }

    [Fact]
    public async Task TranscribeAsync_ReturnsEmpty_WhenUnavailable()
    {
        var service = new WhisperSttService(() => "");
        var result = await service.TranscribeAsync(new byte[] { 1, 2, 3 }, "en");
        Assert.Empty(result);
    }

    [Fact]
    public async Task TranscribeAsync_ReturnsEmpty_WhenUnavailable_DifferentLanguage()
    {
        var service = new WhisperSttService(() => "");
        var result = await service.TranscribeAsync(new byte[] { 1, 2, 3 }, "ja");
        Assert.Empty(result);
    }

    [Fact]
    public void Constructor_DoesNotThrow()
    {
        var service = new WhisperSttService(() => "");
        Assert.NotNull(service);
    }
}
