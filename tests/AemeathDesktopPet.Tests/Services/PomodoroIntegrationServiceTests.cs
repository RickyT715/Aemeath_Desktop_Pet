using AemeathDesktopPet.Services;

namespace AemeathDesktopPet.Tests.Services;

public class PomodoroIntegrationServiceTests
{
    [Fact]
    public void IsWorkMode_DefaultFalse()
    {
        using var service = new PomodoroIntegrationService("TestPipe_Work", System.Windows.Threading.Dispatcher.CurrentDispatcher);
        Assert.False(service.IsWorkMode);
    }

    [Fact]
    public void IsBreakMode_DefaultFalse()
    {
        using var service = new PomodoroIntegrationService("TestPipe_Break", System.Windows.Threading.Dispatcher.CurrentDispatcher);
        Assert.False(service.IsBreakMode);
    }

    [Fact]
    public void IsConnected_DefaultFalse()
    {
        using var service = new PomodoroIntegrationService("TestPipe_Connected", System.Windows.Threading.Dispatcher.CurrentDispatcher);
        Assert.False(service.IsConnected);
    }

    [Fact]
    public void Start_DoesNotThrow()
    {
        using var service = new PomodoroIntegrationService("TestPipe_Start", System.Windows.Threading.Dispatcher.CurrentDispatcher);
        var ex = Record.Exception(() => service.Start());
        Assert.Null(ex);
    }

    [Fact]
    public void Dispose_DoesNotThrow()
    {
        var service = new PomodoroIntegrationService("TestPipe_Dispose", System.Windows.Threading.Dispatcher.CurrentDispatcher);
        service.Start();
        var ex = Record.Exception(() => service.Dispose());
        Assert.Null(ex);
    }

    [Fact]
    public void Dispose_CalledMultipleTimes_DoesNotThrow()
    {
        var service = new PomodoroIntegrationService("TestPipe_MultiDispose", System.Windows.Threading.Dispatcher.CurrentDispatcher);
        service.Dispose();
        var ex = Record.Exception(() => service.Dispose());
        Assert.Null(ex);
    }
}
