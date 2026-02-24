using AemeathDesktopPet.Interop;

namespace AemeathDesktopPet.Tests.Interop;

public class Win32ApiTests
{
    // --- Constant values (ensure no accidental changes) ---

    [Fact]
    public void WS_EX_TRANSPARENT_HasCorrectValue()
    {
        Assert.Equal(0x00000020, Win32Api.WS_EX_TRANSPARENT);
    }

    [Fact]
    public void WS_EX_TOOLWINDOW_HasCorrectValue()
    {
        Assert.Equal(0x00000080, Win32Api.WS_EX_TOOLWINDOW);
    }

    [Fact]
    public void WS_EX_LAYERED_HasCorrectValue()
    {
        Assert.Equal(0x00080000, Win32Api.WS_EX_LAYERED);
    }

    [Fact]
    public void GWL_EXSTYLE_HasCorrectValue()
    {
        Assert.Equal(-20, Win32Api.GWL_EXSTYLE);
    }

    // --- SetWindowPos flags ---

    [Fact]
    public void SWP_NOMOVE_HasCorrectValue()
    {
        Assert.Equal(0x0002u, Win32Api.SWP_NOMOVE);
    }

    [Fact]
    public void SWP_NOSIZE_HasCorrectValue()
    {
        Assert.Equal(0x0001u, Win32Api.SWP_NOSIZE);
    }

    [Fact]
    public void SWP_NOZORDER_HasCorrectValue()
    {
        Assert.Equal(0x0004u, Win32Api.SWP_NOZORDER);
    }

    [Fact]
    public void SWP_NOACTIVATE_HasCorrectValue()
    {
        Assert.Equal(0x0010u, Win32Api.SWP_NOACTIVATE);
    }

    [Fact]
    public void SWP_FRAMECHANGED_HasCorrectValue()
    {
        Assert.Equal(0x0020u, Win32Api.SWP_FRAMECHANGED);
    }

    // --- Bitmask logic ---

    [Fact]
    public void BitwiseOr_AddsTransparentFlag()
    {
        int baseStyle = 0x00080080; // LAYERED | TOOLWINDOW
        int result = baseStyle | Win32Api.WS_EX_TRANSPARENT;
        Assert.Equal(0x000800A0, result);
        Assert.True((result & Win32Api.WS_EX_TRANSPARENT) != 0);
    }

    [Fact]
    public void BitwiseAndNot_RemovesTransparentFlag()
    {
        int withTransparent = 0x000800A0; // LAYERED | TOOLWINDOW | TRANSPARENT
        int result = withTransparent & ~Win32Api.WS_EX_TRANSPARENT;
        Assert.Equal(0x00080080, result);
        Assert.True((result & Win32Api.WS_EX_TRANSPARENT) == 0);
    }

    [Fact]
    public void RemoveTransparent_WhenNotPresent_IsNoOp()
    {
        int withoutTransparent = 0x00080080; // LAYERED | TOOLWINDOW
        int result = withoutTransparent & ~Win32Api.WS_EX_TRANSPARENT;
        Assert.Equal(withoutTransparent, result);
    }

    [Fact]
    public void AddTransparent_WhenAlreadyPresent_IsNoOp()
    {
        int withTransparent = 0x000800A0;
        int result = withTransparent | Win32Api.WS_EX_TRANSPARENT;
        Assert.Equal(withTransparent, result);
    }

    // --- SetClickThrough with null handle (graceful fail) ---

    [Fact]
    public void SetClickThrough_ZeroHandle_DoesNotThrow()
    {
        // Win32 calls with IntPtr.Zero are no-ops (GetWindowLong returns 0)
        Win32Api.SetClickThrough(IntPtr.Zero, true);
        Win32Api.SetClickThrough(IntPtr.Zero, false);
    }

    [Fact]
    public void IsClickThrough_ZeroHandle_ReturnsFalse()
    {
        // GetWindowLong with IntPtr.Zero returns 0
        Assert.False(Win32Api.IsClickThrough(IntPtr.Zero));
    }

    // --- RECT struct ---

    [Fact]
    public void RECT_Width_CalculatesCorrectly()
    {
        var rect = new Win32Api.RECT { Left = 10, Top = 20, Right = 110, Bottom = 120 };
        Assert.Equal(100, rect.Width);
        Assert.Equal(100, rect.Height);
    }

    [Fact]
    public void RECT_ZeroSize()
    {
        var rect = new Win32Api.RECT { Left = 50, Top = 50, Right = 50, Bottom = 50 };
        Assert.Equal(0, rect.Width);
        Assert.Equal(0, rect.Height);
    }

    // --- GetWindowTitle with zero handle ---

    [Fact]
    public void GetWindowTitle_ZeroHandle_ReturnsEmpty()
    {
        var title = Win32Api.GetWindowTitle(IntPtr.Zero);
        Assert.Equal(string.Empty, title);
    }
}
