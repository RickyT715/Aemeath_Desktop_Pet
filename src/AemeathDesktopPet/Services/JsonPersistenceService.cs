using System.IO;
using System.Text.Json;
using AemeathDesktopPet.Models;

namespace AemeathDesktopPet.Services;

/// <summary>
/// Persists stats and conversation history as JSON files in %LOCALAPPDATA%\AemeathDesktopPet\.
/// </summary>
public class JsonPersistenceService
{
    private static readonly JsonSerializerOptions JsonOpts = new()
    {
        WriteIndented = true,
        PropertyNamingPolicy = JsonNamingPolicy.CamelCase,
    };

    private readonly string _dataDir;
    private readonly string _statsPath;
    private readonly string _messagesPath;

    public JsonPersistenceService()
    {
        _dataDir = Path.Combine(
            Environment.GetFolderPath(Environment.SpecialFolder.LocalApplicationData),
            "AemeathDesktopPet");
        Directory.CreateDirectory(_dataDir);

        _statsPath = Path.Combine(_dataDir, "stats.json");
        _messagesPath = Path.Combine(_dataDir, "messages.json");
    }

    /// <summary>
    /// Constructor for testing — accepts a custom data directory.
    /// </summary>
    internal JsonPersistenceService(string dataDir)
    {
        _dataDir = dataDir;
        Directory.CreateDirectory(_dataDir);
        _statsPath = Path.Combine(_dataDir, "stats.json");
        _messagesPath = Path.Combine(_dataDir, "messages.json");
    }

    public AemeathStats? LoadStats()
    {
        return LoadJson<AemeathStats>(_statsPath);
    }

    public void SaveStats(AemeathStats stats)
    {
        SaveJson(_statsPath, stats);
    }

    public List<ChatMessage>? LoadMessages()
    {
        return LoadJson<List<ChatMessage>>(_messagesPath);
    }

    public void SaveMessages(List<ChatMessage> messages)
    {
        SaveJson(_messagesPath, messages);
    }

    private T? LoadJson<T>(string path) where T : class
    {
        if (!File.Exists(path))
            return null;
        try
        {
            var json = File.ReadAllText(path);
            return JsonSerializer.Deserialize<T>(json, JsonOpts);
        }
        catch
        {
            return null;
        }
    }

    private void SaveJson<T>(string path, T data)
    {
        try
        {
            var json = JsonSerializer.Serialize(data, JsonOpts);
            File.WriteAllText(path, json);
        }
        catch
        {
            // Non-critical — silently fail
        }
    }
}
