using AemeathDesktopPet.Services;
using Microsoft.Win32;

namespace AemeathDesktopPet.Tests.Services;

public class StartupServiceTests
{
    private const string RegistryKeyPath = @"Software\Microsoft\Windows\CurrentVersion\Run";
    private const string AppName = "AemeathDesktopPet";

    private void CleanupRegistry()
    {
        using var key = Registry.CurrentUser.OpenSubKey(RegistryKeyPath, writable: true);
        key?.DeleteValue(AppName, throwOnMissingValue: false);
    }

    [Fact]
    public void SetStartWithWindows_True_CreatesRegistryKey()
    {
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
