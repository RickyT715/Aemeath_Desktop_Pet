using System.IO;
using System.Text;
using System.Text.Json;
using AemeathDesktopPet.Models;

namespace AemeathDesktopPet.Services;

/// <summary>
/// Manages core_memory.json — the always-loaded user profile and relationship data.
/// This is injected into every system prompt (~500 token budget).
/// </summary>
public class CoreMemoryService
{
    private static readonly JsonSerializerOptions JsonOpts = new()
    {
        WriteIndented = true,
        PropertyNamingPolicy = JsonNamingPolicy.CamelCase,
    };

    private readonly string _filePath;
    private CoreMemory _cache;

    public CoreMemoryService()
    {
        var dataDir = Path.Combine(
            Environment.GetFolderPath(Environment.SpecialFolder.LocalApplicationData),
            "AemeathDesktopPet");
        Directory.CreateDirectory(dataDir);
        _filePath = Path.Combine(dataDir, "core_memory.json");
        _cache = new CoreMemory();
    }

    /// <summary>
    /// Constructor for testing — accepts a custom data directory.
    /// </summary>
    internal CoreMemoryService(string dataDir)
    {
        Directory.CreateDirectory(dataDir);
        _filePath = Path.Combine(dataDir, "core_memory.json");
        _cache = new CoreMemory();
    }

    /// <summary>
    /// Loads core memory from disk. Returns a new empty CoreMemory if file doesn't exist.
    /// </summary>
    public CoreMemory Load()
    {
        if (!File.Exists(_filePath))
        {
            _cache = new CoreMemory();
            return _cache;
        }

        try
        {
            var json = File.ReadAllText(_filePath);
            _cache = JsonSerializer.Deserialize<CoreMemory>(json, JsonOpts) ?? new CoreMemory();
        }
        catch
        {
            _cache = new CoreMemory();
        }
        return _cache;
    }

    /// <summary>
    /// Saves core memory to disk.
    /// </summary>
    public void Save(CoreMemory memory)
    {
        _cache = memory;
        _cache.LastUpdated = DateTime.UtcNow;
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
    /// Updates a specific fact in core memory by category and key.
    /// Categories: "user_profile", "personality", "relationship".
    /// </summary>
    public void UpdateFact(string category, string key, string value)
    {
        switch (category.ToLowerInvariant())
        {
            case "user_profile":
                UpdateUserProfileFact(key, value);
                break;
            case "personality":
                UpdatePersonalityFact(key, value);
                break;
            case "relationship":
                UpdateRelationshipFact(key, value);
                break;
        }
        Save(_cache);
    }

    /// <summary>
    /// Removes a specific fact from core memory.
    /// </summary>
    public void RemoveFact(string category, string key)
    {
        switch (category.ToLowerInvariant())
        {
            case "user_profile":
                RemoveUserProfileFact(key);
                break;
            case "personality":
                RemovePersonalityFact(key);
                break;
            case "relationship":
                RemoveRelationshipFact(key);
                break;
        }
        Save(_cache);
    }

    /// <summary>
    /// Formats core memory as a text block suitable for system prompt injection.
    /// Budget: ~500 tokens max.
    /// </summary>
    public string FormatForPrompt()
    {
        var sb = new StringBuilder();
        var p = _cache.UserProfile;
        var pers = _cache.Personality;
        var r = _cache.Relationship;

        // User profile section
        if (!string.IsNullOrEmpty(p.Name))
            sb.AppendLine($"- Name: {p.Name}");
        if (!string.IsNullOrEmpty(p.Nickname))
            sb.AppendLine($"- Nickname: {p.Nickname}");
        if (!string.IsNullOrEmpty(p.Occupation))
            sb.AppendLine($"- Occupation: {p.Occupation}");
        if (!string.IsNullOrEmpty(p.AgeRange))
            sb.AppendLine($"- Age range: {p.AgeRange}");
        if (p.Languages.Count > 0)
            sb.AppendLine($"- Languages: {string.Join(", ", p.Languages)}");
        if (p.KeyFacts.Count > 0)
        {
            foreach (var fact in p.KeyFacts)
                sb.AppendLine($"- {fact}");
        }

        // Personality section
        if (pers.Interests.Count > 0)
            sb.AppendLine($"- Key interests: {string.Join(", ", pers.Interests)}");
        if (pers.Dislikes.Count > 0)
            sb.AppendLine($"- Dislikes: {string.Join(", ", pers.Dislikes)}");
        if (!string.IsNullOrEmpty(pers.CommunicationStyle))
            sb.AppendLine($"- Communication style: {pers.CommunicationStyle}");
        if (!string.IsNullOrEmpty(pers.MoodPatterns))
            sb.AppendLine($"- Mood patterns: {pers.MoodPatterns}");

        // Relationship section
        sb.AppendLine($"- Relationship: {r.Stage} ({r.DaysTogether} days together)");
        if (r.InsideJokes.Count > 0)
            sb.AppendLine($"- Inside jokes: {string.Join("; ", r.InsideJokes)}");

        return sb.ToString().TrimEnd();
    }

    /// <summary>Returns the cached CoreMemory without re-reading from disk.</summary>
    public CoreMemory Current => _cache;

    private void UpdateUserProfileFact(string key, string value)
    {
        var p = _cache.UserProfile;
        switch (key.ToLowerInvariant())
        {
            case "name": p.Name = value; break;
            case "nickname": p.Nickname = value; break;
            case "age_range": p.AgeRange = value; break;
            case "occupation": p.Occupation = value; break;
            case "language":
                if (!p.Languages.Contains(value))
                    p.Languages.Add(value);
                break;
            case "key_fact":
                if (!p.KeyFacts.Contains(value))
                    p.KeyFacts.Add(value);
                break;
        }
    }

    private void UpdatePersonalityFact(string key, string value)
    {
        var pers = _cache.Personality;
        switch (key.ToLowerInvariant())
        {
            case "communication_style": pers.CommunicationStyle = value; break;
            case "mood_patterns": pers.MoodPatterns = value; break;
            case "interest":
                if (!pers.Interests.Contains(value))
                    pers.Interests.Add(value);
                break;
            case "dislike":
                if (!pers.Dislikes.Contains(value))
                    pers.Dislikes.Add(value);
                break;
        }
    }

    private void UpdateRelationshipFact(string key, string value)
    {
        var r = _cache.Relationship;
        switch (key.ToLowerInvariant())
        {
            case "stage": r.Stage = value; break;
            case "trust_level": r.TrustLevel = value; break;
            case "inside_joke":
                if (!r.InsideJokes.Contains(value))
                    r.InsideJokes.Add(value);
                break;
            case "milestone":
                if (!r.Milestones.Contains(value))
                    r.Milestones.Add(value);
                break;
            case "days_together":
                if (int.TryParse(value, out var days))
                    r.DaysTogether = days;
                break;
        }
    }

    private void RemoveUserProfileFact(string key)
    {
        var p = _cache.UserProfile;
        switch (key.ToLowerInvariant())
        {
            case "name": p.Name = null; break;
            case "nickname": p.Nickname = null; break;
            case "age_range": p.AgeRange = null; break;
            case "occupation": p.Occupation = null; break;
        }
    }

    private void RemovePersonalityFact(string key)
    {
        var pers = _cache.Personality;
        switch (key.ToLowerInvariant())
        {
            case "communication_style": pers.CommunicationStyle = null; break;
            case "mood_patterns": pers.MoodPatterns = null; break;
        }
    }

    private void RemoveRelationshipFact(string key)
    {
        var r = _cache.Relationship;
        switch (key.ToLowerInvariant())
        {
            case "stage": r.Stage = "new"; break;
            case "trust_level": r.TrustLevel = "initial"; break;
        }
    }
}
