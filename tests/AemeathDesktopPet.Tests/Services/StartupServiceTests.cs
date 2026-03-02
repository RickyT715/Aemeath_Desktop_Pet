using AemeathDesktopPet.Services;
using Microsoft.Win32;

namespace AemeathDesktopPet.Tests.Services;

public class StartupServiceTests
{
    private const string RegistryKeyPath = @"Software\Microsoft\Windows\CurrentVersion\Run";
    private const string AppName = "AemeathDesktopPet";

    /// <summary>
    /// Returns true if the current process can resolve its own exe path.
    /// On some CI runners (GitHub Actions), Environment.ProcessPath is null
    /// and Process.MainModule is also null, so SetStartWithWindows(true)
    /// silently skips writing the registry value.
    /// </summary>
    private static bool CanResolveProcessPath()
    {
        var exePath = Environment.ProcessPath
                      ?? System.Diagnostics.Process.GetCurrentProcess().MainModule?.FileName;
        return !string.IsNullOrEmpty(exePath);
    }

    private void CleanupRegistry()
    {
        using var key = Registry.CurrentUser.OpenSubKey(RegistryKeyPath, writable: true);
        key?.DeleteValue(AppName, throwOnMissingValue: false);
    }

    [Fact]
    public void SetStartWithWindows_True_CreatesRegistryKey()
    {
        if (!CanResolveProcessPath()) return; // CI: ProcessPath unavailable

        try
        {
            StartupService.SetStartWithWindows(true);

            using var key = Registry.CurrentUser.OpenSubKey(RegistryKeyPath, writable: false);
            var value = key?.GetValue(AppName);
            Assert.NotNull(value);
        }
        finally
        {
            CleanupRegistry();
        }
    }

    [Fact]
    public void SetStartWithWindows_False_RemovesRegistryKey()
    {
        try
        {
            StartupService.SetStartWithWindows(true);
            StartupService.SetStartWithWindows(false);

            using var key = Registry.CurrentUser.OpenSubKey(RegistryKeyPath, writable: false);
            var value = key?.GetValue(AppName);
            Assert.Null(value);
        }
        finally
        {
            CleanupRegistry();
        }
    }

    [Fact]
    public void IsStartWithWindows_ReflectsCurrentState()
    {
        if (!CanResolveProcessPath()) return; // CI: ProcessPath unavailable

        try
        {
            StartupService.SetStartWithWindows(true);
            Assert.True(StartupService.IsStartWithWindows());

            StartupService.SetStartWithWindows(false);
            Assert.False(StartupService.IsStartWithWindows());
        }
        finally
        {
            CleanupRegistry();
        }
    }

    [Fact]
    public void IsStartWithWindows_WhenNeverSet_ReturnsFalse()
    {
        CleanupRegistry();
        Assert.False(StartupService.IsStartWithWindows());
    }
}
