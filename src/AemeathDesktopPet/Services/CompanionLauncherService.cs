using System.Diagnostics;
using System.IO;
using AemeathDesktopPet.Models;

namespace AemeathDesktopPet.Services;

public static class CompanionLauncherService
{
    public static void LaunchCompanions(CompanionAppsConfig config)
    {
        if (config.LaunchMonitor)
            LaunchIfNotRunning(config.MonitorPath);

        if (config.LaunchTodoList)
            LaunchProcess(config.TodoListPath);
    }

    internal static bool LaunchProcess(string path)
    {
        if (string.IsNullOrWhiteSpace(path))
            return false;

        if (!File.Exists(path))
            return false;

        try
        {
            var startInfo = new ProcessStartInfo
            {
                FileName = path,
                WorkingDirectory = Path.GetDirectoryName(path) ?? "",
                UseShellExecute = true
            };
            Process.Start(startInfo);
            return true;
        }
        catch
        {
            return false;
        }
    }

    private static void LaunchIfNotRunning(string path)
    {
        if (string.IsNullOrWhiteSpace(path) || !File.Exists(path))
            return;

        var ext = Path.GetExtension(path).ToLowerInvariant();
        if (ext == ".exe")
        {
            var processName = Path.GetFileNameWithoutExtension(path);
            try
            {
                if (Process.GetProcessesByName(processName).Length > 0)
                    return;
            }
            catch
            {
                // If we can't check, try launching anyway
            }
        }

        LaunchProcess(path);
    }
}
