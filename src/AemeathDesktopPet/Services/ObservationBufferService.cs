using System.IO;
using System.Text.Json;
using AemeathDesktopPet.Models;

namespace AemeathDesktopPet.Services;

/// <summary>
/// Manages the observation buffer — a short-lived accumulator for raw observations
/// from screen awareness, activity monitor, camera, and pomodoro sources.
/// Entries have a 24-hour TTL before being distilled into episodic memory or purged.
/// Persisted to observation_buffer.json.
/// </summary>
public class ObservationBufferService
{
    private static readonly JsonSerializerOptions JsonOpts = new()
    {
        WriteIndented = true,
        PropertyNamingPolicy = JsonNamingPolicy.CamelCase,
    };

    private readonly string _filePath;
    private ObservationBuffer _buffer;

    public ObservationBufferService()
    {
        var dataDir = Path.Combine(
            Environment.GetFolderPath(Environment.SpecialFolder.LocalApplicationData),
            "AemeathDesktopPet");
        Directory.CreateDirectory(dataDir);
        _filePath = Path.Combine(dataDir, "observation_buffer.json");
        _buffer = new ObservationBuffer();
    }

    /// <summary>
    /// Constructor for testing — accepts a custom data directory.
    /// </summary>
    internal ObservationBufferService(string dataDir)
    {
        Directory.CreateDirectory(dataDir);
        _filePath = Path.Combine(dataDir, "observation_buffer.json");
        _buffer = new ObservationBuffer();
    }

    /// <summary>
    /// Loads the observation buffer from disk and auto-purges expired entries.
    /// </summary>
    public void Load()
    {
        if (File.Exists(_filePath))
        {
            try
            {
                var json = File.ReadAllText(_filePath);
                _buffer = JsonSerializer.Deserialize<ObservationBuffer>(json, JsonOpts) ?? new ObservationBuffer();
            }
            catch
            {
                _buffer = new ObservationBuffer();
            }
        }
        else
        {
            _buffer = new ObservationBuffer();
        }

        PurgeExpired();
    }

    /// <summary>
    /// Adds a new observation to the buffer and persists to disk.
    /// </summary>
    public void AddObservation(string source, string content, string context)
    {
        var entry = new ObservationEntry
        {
            Source = source,
            Content = content,
            ActivityContext = context,
        };
        _buffer.Entries.Add(entry);
        Save();
    }

    /// <summary>
    /// Returns all non-expired entries in the buffer.
    /// </summary>
    public List<ObservationEntry> GetPending()
    {
        return _buffer.Entries.Where(e => !e.IsExpired).ToList();
    }

    /// <summary>
    /// Removes entries with the specified IDs (after they've been processed/distilled).
    /// </summary>
    public void ClearProcessed(List<string> ids)
    {
        var idSet = new HashSet<string>(ids);
        _buffer.Entries.RemoveAll(e => idSet.Contains(e.Id));
        Save();
    }

    /// <summary>
    /// Removes all entries that have exceeded their TTL.
    /// </summary>
    public void PurgeExpired()
    {
        var before = _buffer.Entries.Count;
        _buffer.Entries.RemoveAll(e => e.IsExpired);
        if (_buffer.Entries.Count != before)
            Save();
    }

    /// <summary>Returns the current number of entries in the buffer.</summary>
    public int Count => _buffer.Entries.Count;

    private void Save()
    {
        try
        {
            var json = JsonSerializer.Serialize(_buffer, JsonOpts);
            File.WriteAllText(_filePath, json);
        }
        catch
        {
            // Non-critical — silently fail
        }
    }
}
