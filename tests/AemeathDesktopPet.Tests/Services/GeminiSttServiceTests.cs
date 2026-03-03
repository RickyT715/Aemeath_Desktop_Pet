using AemeathDesktopPet.Services;

namespace AemeathDesktopPet.Tests.Services;

public class GeminiSttServiceTests
{
    [Fact]
    public void IsAvailable_FalseWhenNoApiKey()
    {
        var service = new GeminiSttService(() => "");
        Assert.False(service.IsAvailable);
    }

    [Fact]
    public void IsAvailable_TrueWhenApiKeySet()
    {
        var service = new GeminiSttService(() => "test-gemini-key");
        Assert.True(service.IsAvailable);
    }

    [Fact]
    public void IsAvailable_FalseWhenApiKeyWhitespace()
    {
        var service = new GeminiSttService(() => "   ");
        Assert.False(service.IsAvailable);
    }

    [Fact]
    public async Task TranscribeAsync_ReturnsEmpty_WhenUnavailable()
    {
        var service = new GeminiSttService(() => "");
        var result = await service.TranscribeAsync(new byte[] { 1, 2, 3 }, "en");
        Assert.Empty(result);
    }

    [Fact]
    public async Task TranscribeAsync_ReturnsEmpty_WhenUnavailable_DifferentLanguage()
    {
        var service = new GeminiSttService(() => "");
        var result = await service.TranscribeAsync(new byte[] { 1, 2, 3 }, "zh");
        Assert.Empty(result);
    }

    [Fact]
    public void Constructor_DoesNotThrow()
    {
        var service = new GeminiSttService(() => "");
        Assert.NotNull(service);
    }
}
