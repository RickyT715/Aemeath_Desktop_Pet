using System.IO;
using System.Windows;
using AemeathDesktopPet.Services;

namespace AemeathDesktopPet;

public partial class App : Application
{
    protected override void OnStartup(StartupEventArgs e)
    {
        base.OnStartup(e);

        // Ensure data directory exists
        var dataDir = Path.Combine(
            Environment.GetFolderPath(Environment.SpecialFolder.LocalApplicationData),
            "AemeathDesktopPet");
        Directory.CreateDirectory(dataDir);

        // Launch companion apps before the main window shows
        var config = new ConfigService();
        config.Load();
        CompanionLauncherService.LaunchCompanions(config.Config.CompanionApps);
    }
}
