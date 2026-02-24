using AemeathDesktopPet.Models;
using AemeathDesktopPet.Services;

namespace AemeathDesktopPet.Tests.Services;

public class CompanionLauncherServiceTests
{
    [Fact]
    public void LaunchProcess_NullPath_ReturnsFalse()
    {
        Assert.False(CompanionLauncherService.LaunchProcess(null!));
    }

    [Fact]
    public void LaunchProcess_EmptyPath_ReturnsFalse()
    {
        Assert.False(CompanionLauncherService.LaunchProcess(""));
    }

    [Fact]
    public void LaunchProcess_WhitespacePath_ReturnsFalse()
    {
        Assert.False(CompanionLauncherService.LaunchProcess("   "));
    }

    [Fact]
    public void LaunchProcess_NonexistentFile_ReturnsFalse()
    {
        Assert.False(CompanionLauncherService.LaunchProcess(@"C:\nonexistent\fake_app.exe"));
    }

    [Fact]
    public void LaunchCompanions_BothDisabled_NoException()
    {
        var config = new CompanionAppsConfig
        {
            LaunchMonitor = false,
            LaunchTodoList = false
        };

        var ex = Record.Exception(() => CompanionLauncherService.LaunchCompanions(config));
        Assert.Null(ex);
    }

    [Fact]
    public void LaunchCompanions_EnabledButInvalidPaths_NoException()
    {
        var config = new CompanionAppsConfig
        {
            LaunchMonitor = true,
            MonitorPath = @"C:\nonexistent\fake.exe",
            LaunchTodoList = true,
            TodoListPath = @"C:\nonexistent\fake.bat"
        };

        var ex = Record.Exception(() => CompanionLauncherService.LaunchCompanions(config));
        Assert.Null(ex);
    }
}
