using AemeathDesktopPet.Models;

namespace AemeathDesktopPet.Tests.Models;

public class SpeechFrequencyConfigTests
{
    [Fact]
    public void DefaultValues_MatchExpected()
    {
        var cfg = new SpeechFrequencyConfig();

        Assert.Equal("Silent", cfg.PomodoroWork);
        Assert.Equal("Chatty", cfg.PomodoroBreak);
        Assert.Equal("Rare", cfg.Gaming);
        Assert.Equal("Rare", cfg.WatchingVideos);
        Assert.Equal("Normal", cfg.StudyingCoding);
        Assert.Equal("Normal", cfg.Default);
    }

    [Theory]
    [InlineData(ActivityContext.PomodoroWork, SpeechFrequencyLevel.Silent)]
    [InlineData(ActivityContext.PomodoroBreak, SpeechFrequencyLevel.Chatty)]
    [InlineData(ActivityContext.Gaming, SpeechFrequencyLevel.Rare)]
    [InlineData(ActivityContext.WatchingVideos, SpeechFrequencyLevel.Rare)]
    [InlineData(ActivityContext.StudyingCoding, SpeechFrequencyLevel.Normal)]
    [InlineData(ActivityContext.Default, SpeechFrequencyLevel.Normal)]
    public void GetLevel_ReturnsDefaultLevelForEachContext(ActivityContext context, SpeechFrequencyLevel expected)
    {
        var cfg = new SpeechFrequencyConfig();
        Assert.Equal(expected, cfg.GetLevel(context));
    }

    [Fact]
    public void GetLevel_InvalidString_FallsBackToNormal()
    {
        var cfg = new SpeechFrequencyConfig { Gaming = "nonsense" };
        Assert.Equal(SpeechFrequencyLevel.Normal, cfg.GetLevel(ActivityContext.Gaming));
    }

    [Fact]
    public void GetLevel_CaseInsensitive()
    {
        var cfg = new SpeechFrequencyConfig { Gaming = "sIlEnT" };
        Assert.Equal(SpeechFrequencyLevel.Silent, cfg.GetLevel(ActivityContext.Gaming));
    }

    [Fact]
    public void GetLevel_CustomValue_Works()
    {
        var cfg = new SpeechFrequencyConfig { Default = "Chatty" };
        Assert.Equal(SpeechFrequencyLevel.Chatty, cfg.GetLevel(ActivityContext.Default));
    }

    [Fact]
    public void GetLevel_EmptyString_FallsBackToNormal()
    {
        var cfg = new SpeechFrequencyConfig { PomodoroWork = "" };
        Assert.Equal(SpeechFrequencyLevel.Normal, cfg.GetLevel(ActivityContext.PomodoroWork));
    }

    [Fact]
    public void GetInterval_Silent_ReturnsNull()
    {
        Assert.Null(SpeechFrequencyConfig.GetInterval(SpeechFrequencyLevel.Silent));
    }

    [Fact]
    public void GetInterval_Rare_Returns120To240()
    {
        var interval = SpeechFrequencyConfig.GetInterval(SpeechFrequencyLevel.Rare);
        Assert.NotNull(interval);
        Assert.Equal(120, interval.Value.min);
        Assert.Equal(240, interval.Value.max);
    }

    [Fact]
    public void GetInterval_Normal_Returns45To90()
    {
        var interval = SpeechFrequencyConfig.GetInterval(SpeechFrequencyLevel.Normal);
        Assert.NotNull(interval);
        Assert.Equal(45, interval.Value.min);
        Assert.Equal(90, interval.Value.max);
    }

    [Fact]
    public void GetInterval_Chatty_Returns15To30()
    {
        var interval = SpeechFrequencyConfig.GetInterval(SpeechFrequencyLevel.Chatty);
        Assert.NotNull(interval);
        Assert.Equal(15, interval.Value.min);
        Assert.Equal(30, interval.Value.max);
    }
}
