using AemeathDesktopPet.Engine;

namespace AemeathDesktopPet.Tests.Engine;

public class GlitchEffectTests
{
    [Fact]
    public void IsGlitching_FalseByDefault()
    {
        var glitch = new GlitchEffect();
        Assert.False(glitch.IsGlitching);
    }

    [Fact]
    public void IsEnabled_TrueByDefault()
    {
        var glitch = new GlitchEffect();
        Assert.True(glitch.IsEnabled);
    }

    [Fact]
    public void IsEnabled_CanBeDisabled()
    {
        var glitch = new GlitchEffect();
        glitch.IsEnabled = false;
        Assert.False(glitch.IsEnabled);
    }

    [Fact]
    public void TriggerGlitch_WhenDisabled_DoesNotGlitch()
    {
        var glitch = new GlitchEffect();
        glitch.IsEnabled = false;
        glitch.TriggerGlitch();
        Assert.False(glitch.IsGlitching);
    }

    [Fact]
    public void TriggerGlitch_WhenEnabled_SetsIsGlitching()
    {
        var glitch = new GlitchEffect();
        glitch.TriggerGlitch();
        Assert.True(glitch.IsGlitching);
    }

    [Fact]
    public void TriggerGlitch_FiresGlitchStartedEvent()
    {
        var glitch = new GlitchEffect();
        bool fired = false;
        glitch.GlitchStarted += () => fired = true;
        glitch.TriggerGlitch();
        Assert.True(fired);
    }

    [Fact]
    public void TriggerGlitch_WhenAlreadyGlitching_DoesNotRestart()
    {
        var glitch = new GlitchEffect();
        int startCount = 0;
        glitch.GlitchStarted += () => startCount++;

        glitch.TriggerGlitch();
        glitch.TriggerGlitch(); // should be ignored

        Assert.Equal(1, startCount);
    }

    [Fact]
    public void Stop_ResetsGlitchState()
    {
        var glitch = new GlitchEffect();
        glitch.TriggerGlitch();
        glitch.Stop();
        Assert.False(glitch.IsGlitching);
    }

    [Fact]
    public void Start_DoesNotThrow()
    {
        var glitch = new GlitchEffect();
        glitch.Start();
        glitch.Stop(); // cleanup
    }
}
