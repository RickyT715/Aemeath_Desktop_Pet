using System.IO;
using System.Text.Json;
using AemeathDesktopPet.Models;

namespace AemeathDesktopPet.Services;

/// <summary>
/// Loads, saves, and manages user configuration from config.json.
/// </summary>
public class ConfigService
{
    private static readonly JsonSerializerOptions JsonOptions = new()
    {
        WriteIndented = true,
        PropertyNamingPolicy = JsonNamingPolicy.CamelCase,
    };

    private readonly string _configPath;

    public AppConfig Config { get; private set; } = new();

    public ConfigService()
    {
        var dataDir = Path.Combine(
            Environment.GetFolderPath(Environment.SpecialFolder.LocalApplicationData),
            "AemeathDesktopPet");
        Directory.CreateDirectory(dataDir);
        _configPath = Path.Combine(dataDir, "config.json");
    }

    /// <summary>
    /// Constructor for testing — accepts a custom config directory.
    /// </summary>
    internal ConfigService(string configDir)
    {
        Directory.CreateDirectory(configDir);
        _configPath = Path.Combine(configDir, "config.json");
    }

    public void Load()
    {
        if (File.Exists(_configPath))
        {
            try
            {
                var json = File.ReadAllText(_configPath);
                Config = JsonSerializer.Deserialize<AppConfig>(json, JsonOptions) ?? new AppConfig();
            }
            catch
            {
                Config = new AppConfig();
            }
        }
        else
        {
            Config = new AppConfig();
            Save();
        }
    }

    public void Save()
    {
        try
        {
            var json = JsonSerializer.Serialize(Config, JsonOptions);
            File.WriteAllText(_configPath, json);
        }
        catch
        {
            // Silently fail — config save is non-critical
        }
    }

    /// <summary>
    /// Saves the pet's current position for restoration on next launch.
    /// </summary>
    public void SavePosition(double x, double y)
    {
        Config.LastX = x;
        Config.LastY = y;
        Save();
    }
}
