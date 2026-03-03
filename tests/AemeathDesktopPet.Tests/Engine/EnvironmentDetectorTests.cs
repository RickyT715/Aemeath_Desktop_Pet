using AemeathDesktopPet.Engine;

namespace AemeathDesktopPet.Tests.Engine;

/// <summary>
/// Smoke tests for EnvironmentDetector. These rely on Win32 APIs and WPF SystemParameters,
/// which may not be fully available in headless CI. Tests are wrapped with Record.Exception
/// to handle environments where SystemParameters throws.
/// </summary>
public class EnvironmentDetectorTests
{
    private readonly EnvironmentDetector _detector = new();

    [Fact]
    public void GetWorkArea_DoesNotThrow()
    {
        var ex = Record.Exception(() => _detector.GetWorkArea());
        Assert.Null(ex);
    }

    [Fact]
    public void GetWorkArea_ReturnsNonZeroRect()
    {
        var area = _detector.GetWorkArea();
        Assert.True(area.Width > 0, "WorkArea Width should be > 0");
        Assert.True(area.Height > 0, "WorkArea Height should be > 0");
    }

    [Fact]
    public void GetScreenBounds_DoesNotThrow()
    {
        var ex = Record.Exception(() => _detector.GetScreenBounds());
        Assert.Null(ex);
    }

    [Fact]
    public void GetScreenBounds_ReturnsNonZero_GreaterOrEqualToWorkArea()
    {
        var screen = _detector.GetScreenBounds();
        var work = _detector.GetWorkArea();
        Assert.True(screen.Width > 0, "ScreenBounds Width should be > 0");
        Assert.True(screen.Height > 0, "ScreenBounds Height should be > 0");
        Assert.True(screen.Width >= work.Width, "ScreenBounds Width should be >= WorkArea Width");
        Assert.True(screen.Height >= work.Height, "ScreenBounds Height should be >= WorkArea Height");
    }

    [Fact]
    public void IsFullscreenAppActive_DoesNotThrow()
    {
        var ex = Record.Exception(() => _detector.IsFullscreenAppActive());
        Assert.Null(ex);
    }

    [Fact]
    public void GetForegroundAppInfo_DoesNotThrow()
    {
        var ex = Record.Exception(() => _detector.GetForegroundAppInfo());
        Assert.Null(ex);
    }

    [Fact]
    public void HasProtectedWindowVisible_DoesNotThrow()
    {
        var ex = Record.Exception(() => _detector.HasProtectedWindowVisible());
        Assert.Null(ex);
    }

    [Fact]
    public void GetVisibleWindows_DoesNotThrow_ReturnsListType()
    {
        var ex = Record.Exception(() =>
        {
            var windows = _detector.GetVisibleWindows();
            Assert.NotNull(windows);
        });
        Assert.Null(ex);
    }
}
