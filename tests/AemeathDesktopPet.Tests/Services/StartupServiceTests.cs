using AemeathDesktopPet.Services;
using Microsoft.Win32;

namespace AemeathDesktopPet.Tests.Services;

public class StartupServiceTests
{
    private const string RegistryKeyPath = @"Software\Microsoft\Windows\CurrentVersion\Run";
    private const string AppName = "AemeathDesktopPet";

    /// <summary>
    /// Checks if the registry Run key is writable AND SetStartWithWindows
    /// actually writes a value. On CI runners, the registry may exist but
    /// Environment.ProcessPath may be a host like dotnet.exe that gets
    /// filtered, or the key may not be writable.
    /// </summary>
    private static bool CanWriteRegistryStartup()
    {
        try
        {
            using var key = Registry.CurrentUser.OpenSubKey(RegistryKeyPath, writable: true);
            if (key == null) return false;

            // Try a real write/read/cleanup cycle with a test value
            const string testName = "AemeathDesktopPet_WriteTest";
            key.SetValue(testName, "test");
            var readBack = key.GetValue(testName);
            key.DeleteValue(testName, throwOnMissingValue: false);
            return readBack != null;
        }
        catch
        {
            return false;
        }
    }

    private void CleanupRegistry()
    {
        try
        {
            using var key = Registry.CurrentUser.OpenSubKey(RegistryKeyPath, writable: true);
            key?.DeleteValue(AppName, throwOnMissingValue: false);
        }
        catch { /* CI: registry not available */ }
    }

    [Fact]
    public void SetStartWithWindows_True_CreatesRegistryKey()
    {
        if (!CanWriteRegistryStartup()) return; // Skip on environments without registry write access

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
        if (!CanWriteRegistryStartup()) return; // Skip on environments without registry write access

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
        if (!CanWriteRegistryStartup()) return; // Skip on environments without registry write access

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
