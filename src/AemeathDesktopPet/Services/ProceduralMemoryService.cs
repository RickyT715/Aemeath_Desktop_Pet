using System.Globalization;
using System.IO;
using System.Text;
using System.Text.Json;
using AemeathDesktopPet.Models;

namespace AemeathDesktopPet.Services;

/// <summary>
/// Manages procedural_memory.json — learned patterns, routines, and scheduled events.
/// Provides contextual retrieval for system prompt injection (~100 token budget).
/// </summary>
public class ProceduralMemoryService
{
    private static readonly JsonSerializerOptions JsonOpts = new()
    {
        WriteIndented = true,
        PropertyNamingPolicy = JsonNamingPolicy.CamelCase,
    };

    private readonly string _filePath;
    private ProceduralMemory _cache;

    public ProceduralMemoryService()
    {
        var dataDir = Path.Combine(
            Environment.GetFolderPath(Environment.SpecialFolder.LocalApplicationData),
            "AemeathDesktopPet");
        Directory.CreateDirectory(dataDir);
        _filePath = Path.Combine(dataDir, "procedural_memory.json");
        _cache = new ProceduralMemory();
    }

    /// <summary>
    /// Constructor for testing — accepts a custom data directory.
    /// </summary>
    internal ProceduralMemoryService(string dataDir)
    {
        Directory.CreateDirectory(dataDir);
        _filePath = Path.Combine(dataDir, "procedural_memory.json");
        _cache = new ProceduralMemory();
    }

    /// <summary>
    /// Loads procedural memory from disk. Returns a new empty instance if file doesn't exist.
    /// </summary>
    public ProceduralMemory Load()
    {
        if (!File.Exists(_filePath))
        {
            _cache = new ProceduralMemory();
            return _cache;
        }

        try
        {
            var json = File.ReadAllText(_filePath);
            _cache = JsonSerializer.Deserialize<ProceduralMemory>(json, JsonOpts) ?? new ProceduralMemory();
        }
        catch
        {
            _cache = new ProceduralMemory();
        }
        return _cache;
    }

    /// <summary>
    /// Saves procedural memory to disk.
    /// </summary>
    public void Save(ProceduralMemory memory)
    {
        _cache = memory;
        try
        {
            var json = JsonSerializer.Serialize(_cache, JsonOpts);
            File.WriteAllText(_filePath, json);
        }
        catch
        {
            // Non-critical — silently fail
        }
    }

    /// <summary>
    /// Returns scheduled events that are within the specified number of days ahead.
    /// </summary>
    public List<ScheduledEvent> GetUpcomingEvents(int daysAhead = 7)
    {
        var today = DateTime.UtcNow.Date;
        var cutoff = today.AddDays(daysAhead);

        return _cache.ScheduledEvents
            .Where(e =>
            {
                if (DateTime.TryParse(e.Date, CultureInfo.InvariantCulture, DateTimeStyles.None, out var eventDate))
                    return eventDate.Date >= today && eventDate.Date <= cutoff;
                return false;
            })
            .OrderBy(e => e.Date)
            .ToList();
    }

    /// <summary>
    /// Returns routines with confidence above the given threshold (default 0.5).
    /// </summary>
    public List<Routine> GetActiveRoutines(double minConfidence = 0.5)
    {
        return _cache.Routines
            .Where(r => r.Confidence >= minConfidence)
            .ToList();
    }

    /// <summary>
    /// Formats relevant procedural memory for system prompt injection (~100 tokens).
    /// Includes upcoming events and high-confidence routines.
    /// </summary>
    public string FormatForPrompt()
    {
        var sb = new StringBuilder();

        // Upcoming events
        var events = GetUpcomingEvents();
        if (events.Count > 0)
        {
            sb.AppendLine("### Upcoming Events");
            foreach (var ev in events.Take(3))
            {
                var daysUntil = "";
                if (DateTime.TryParse(ev.Date, CultureInfo.InvariantCulture, DateTimeStyles.None, out var eventDate))
                {
                    var diff = (eventDate.Date - DateTime.UtcNow.Date).Days;
                    daysUntil = diff switch
                    {
                        0 => " (today)",
                        1 => " (tomorrow)",
                        _ => $" (in {diff} days)"
                    };
                }
                sb.AppendLine($"- {ev.Event}: {ev.Date}{daysUntil}");
                if (!string.IsNullOrEmpty(ev.FollowUp))
                    sb.AppendLine($"  Reminder: {ev.FollowUp}");
            }
        }

        return sb.ToString().TrimEnd();
    }

    /// <summary>Returns the cached ProceduralMemory without re-reading from disk.</summary>
    public ProceduralMemory Current => _cache;
}
