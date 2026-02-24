using AemeathDesktopPet.Models;

namespace AemeathDesktopPet.Tests.Models;

public class AnimationInfoTests
{
    [Fact]
    public void AnimationInfo_DefaultFpsIs9()
    {
        var info = new AnimationInfo("test", Loop: true);
        Assert.Equal(9.0, info.Fps);
    }

    [Fact]
    public void AnimationInfo_DefaultMirrorIsFalse()
    {
        var info = new AnimationInfo("test", Loop: true);
        Assert.False(info.Mirror);
    }

    [Fact]
    public void AnimationInfo_CustomFps()
    {
        var info = new AnimationInfo("listening_music", Loop: true, Fps: 25);
        Assert.Equal(25.0, info.Fps);
    }

    [Fact]
    public void AnimationInfo_MirrorTrue()
    {
        var info = new AnimationInfo("normal_flying", Loop: true, Mirror: true);
        Assert.True(info.Mirror);
    }

    [Fact]
    public void AnimationInfo_RecordEquality()
    {
        var a = new AnimationInfo("normal", Loop: true, Fps: 9.0, Mirror: false);
        var b = new AnimationInfo("normal", Loop: true, Fps: 9.0, Mirror: false);
        Assert.Equal(a, b);
    }

    [Fact]
    public void AnimationInfo_RecordInequality_DifferentGif()
    {
        var a = new AnimationInfo("normal", Loop: true);
        var b = new AnimationInfo("laugh", Loop: true);
        Assert.NotEqual(a, b);
    }

    [Fact]
    public void AnimationInfo_RecordInequality_DifferentLoop()
    {
        var a = new AnimationInfo("normal", Loop: true);
        var b = new AnimationInfo("normal", Loop: false);
        Assert.NotEqual(a, b);
    }

    [Fact]
    public void AnimationInfo_GifFileName_Stored()
    {
        var info = new AnimationInfo("happy_jumping", Loop: false);
        Assert.Equal("happy_jumping", info.GifFileName);
    }
}
