using System.Text.Json;
using AemeathDesktopPet.Models;
using AemeathDesktopPet.Services;

namespace AemeathDesktopPet.Tests.Services;

public class CoreMemoryServiceTests : IDisposable
{
    private readonly string _tempDir;
    private readonly CoreMemoryService _service;

    public CoreMemoryServiceTests()
    {
        _tempDir = Path.Combine(Path.GetTempPath(), $"AemeathTest_{Guid.NewGuid():N}");
        _service = new CoreMemoryService(_tempDir);
    }

    public void Dispose()
    {
        if (Directory.Exists(_tempDir))
            Directory.Delete(_tempDir, true);
    }

    // ---- Load ----

    [Fact]
    public void Load_ReturnsEmptyCoreMemory_WhenFileDoesNotExist()
    {
        var mem = _service.Load();

        Assert.NotNull(mem);
        Assert.Equal(1, mem.Version);
        Assert.Null(mem.UserProfile.Name);
        Assert.Empty(mem.UserProfile.KeyFacts);
        Assert.Equal("new", mem.Relationship.Stage);
    }

    [Fact]
    public void Load_HandlesCorruptJson_ReturnsDefault()
    {
        File.WriteAllText(Path.Combine(_tempDir, "core_memory.json"), "{ invalid json !!!");

        var mem = _service.Load();

        Assert.NotNull(mem);
        Assert.Equal(1, mem.Version);
    }

    [Fact]
    public void Load_HandlesEmptyFile_ReturnsDefault()
    {
        File.WriteAllText(Path.Combine(_tempDir, "core_memory.json"), "");

        var mem = _service.Load();

        Assert.NotNull(mem);
    }

    // ---- Save & Load Roundtrip ----

    [Fact]
    public void SaveAndLoad_RoundTrip()
    {
        var mem = new CoreMemory();
        mem.UserProfile.Name = "Ricky";
        mem.UserProfile.Occupation = "CS student";
        mem.UserProfile.KeyFacts.Add("Plays Wuthering Waves");
        mem.Personality.Interests.Add("Programming");
        mem.Personality.CommunicationStyle = "Casual";
        mem.Relationship.Stage = "familiar";
        mem.Relationship.DaysTogether = 45;

        _service.Save(mem);

        // Create new service instance pointing at same dir
        var service2 = new CoreMemoryService(_tempDir);
        var loaded = service2.Load();

        Assert.Equal("Ricky", loaded.UserProfile.Name);
        Assert.Equal("CS student", loaded.UserProfile.Occupation);
        Assert.Single(loaded.UserProfile.KeyFacts);
        Assert.Contains("Plays Wuthering Waves", loaded.UserProfile.KeyFacts);
        Assert.Single(loaded.Personality.Interests);
        Assert.Equal("Casual", loaded.Personality.CommunicationStyle);
        Assert.Equal("familiar", loaded.Relationship.Stage);
        Assert.Equal(45, loaded.Relationship.DaysTogether);
    }

    [Fact]
    public void Save_UpdatesLastUpdated()
    {
        var mem = new CoreMemory();
        var before = DateTime.UtcNow;
        _service.Save(mem);
        var after = DateTime.UtcNow;

        Assert.InRange(_service.Current.LastUpdated, before, after);
    }

    // ---- UpdateFact ----

    [Fact]
    public void UpdateFact_SetsUserName()
    {
        _service.Load();
        _service.UpdateFact("user_profile", "name", "Ricky");

        Assert.Equal("Ricky", _service.Current.UserProfile.Name);
    }

    [Fact]
    public void UpdateFact_SetsOccupation()
    {
        _service.Load();
        _service.UpdateFact("user_profile", "occupation", "CS student");

        Assert.Equal("CS student", _service.Current.UserProfile.Occupation);
    }

    [Fact]
    public void UpdateFact_AddsLanguage()
    {
        _service.Load();
        _service.UpdateFact("user_profile", "language", "English");
        _service.UpdateFact("user_profile", "language", "Chinese");

        Assert.Equal(2, _service.Current.UserProfile.Languages.Count);
        Assert.Contains("English", _service.Current.UserProfile.Languages);
        Assert.Contains("Chinese", _service.Current.UserProfile.Languages);
    }

    [Fact]
    public void UpdateFact_DoesNotDuplicateLanguage()
    {
        _service.Load();
        _service.UpdateFact("user_profile", "language", "English");
        _service.UpdateFact("user_profile", "language", "English");

        Assert.Single(_service.Current.UserProfile.Languages);
    }

    [Fact]
    public void UpdateFact_AddsKeyFact()
    {
        _service.Load();
        _service.UpdateFact("user_profile", "key_fact", "Likes WuWa");

        Assert.Single(_service.Current.UserProfile.KeyFacts);
        Assert.Contains("Likes WuWa", _service.Current.UserProfile.KeyFacts);
    }

    [Fact]
    public void UpdateFact_SetsPersonalityFields()
    {
        _service.Load();
        _service.UpdateFact("personality", "communication_style", "Casual");
        _service.UpdateFact("personality", "mood_patterns", "Upbeat");
        _service.UpdateFact("personality", "interest", "Gaming");
        _service.UpdateFact("personality", "dislike", "Bugs");

        Assert.Equal("Casual", _service.Current.Personality.CommunicationStyle);
        Assert.Equal("Upbeat", _service.Current.Personality.MoodPatterns);
        Assert.Contains("Gaming", _service.Current.Personality.Interests);
        Assert.Contains("Bugs", _service.Current.Personality.Dislikes);
    }

    [Fact]
    public void UpdateFact_SetsRelationshipFields()
    {
        _service.Load();
        _service.UpdateFact("relationship", "stage", "close_friend");
        _service.UpdateFact("relationship", "trust_level", "high");
        _service.UpdateFact("relationship", "inside_joke", "Paper plane incident");
        _service.UpdateFact("relationship", "milestone", "First song together");
        _service.UpdateFact("relationship", "days_together", "90");

        Assert.Equal("close_friend", _service.Current.Relationship.Stage);
        Assert.Equal("high", _service.Current.Relationship.TrustLevel);
        Assert.Contains("Paper plane incident", _service.Current.Relationship.InsideJokes);
        Assert.Contains("First song together", _service.Current.Relationship.Milestones);
        Assert.Equal(90, _service.Current.Relationship.DaysTogether);
    }

    [Fact]
    public void UpdateFact_UnknownCategory_DoesNotThrow()
    {
        _service.Load();
        _service.UpdateFact("unknown_category", "key", "value");
        // Should not throw, just silently ignore
    }

    [Fact]
    public void UpdateFact_PersistsToDisk()
    {
        _service.Load();
        _service.UpdateFact("user_profile", "name", "Ricky");

        // Verify it persisted
        var service2 = new CoreMemoryService(_tempDir);
        var loaded = service2.Load();
        Assert.Equal("Ricky", loaded.UserProfile.Name);
    }

    [Fact]
    public void UpdateFact_OverwritesExistingValue()
    {
        _service.Load();
        _service.UpdateFact("user_profile", "name", "Alice");
        _service.UpdateFact("user_profile", "name", "Ricky");

        Assert.Equal("Ricky", _service.Current.UserProfile.Name);
    }

    // ---- RemoveFact ----

    [Fact]
    public void RemoveFact_ClearsUserName()
    {
        _service.Load();
        _service.UpdateFact("user_profile", "name", "Ricky");
        _service.RemoveFact("user_profile", "name");

        Assert.Null(_service.Current.UserProfile.Name);
    }

    [Fact]
    public void RemoveFact_ClearsOccupation()
    {
        _service.Load();
        _service.UpdateFact("user_profile", "occupation", "Student");
        _service.RemoveFact("user_profile", "occupation");

        Assert.Null(_service.Current.UserProfile.Occupation);
    }

    [Fact]
    public void RemoveFact_ClearsPersonality()
    {
        _service.Load();
        _service.UpdateFact("personality", "communication_style", "Casual");
        _service.RemoveFact("personality", "communication_style");

        Assert.Null(_service.Current.Personality.CommunicationStyle);
    }

    [Fact]
    public void RemoveFact_ResetsRelationshipStage()
    {
        _service.Load();
        _service.UpdateFact("relationship", "stage", "best_friend");
        _service.RemoveFact("relationship", "stage");

        Assert.Equal("new", _service.Current.Relationship.Stage);
    }

    [Fact]
    public void RemoveFact_ResetsTrustLevel()
    {
        _service.Load();
        _service.UpdateFact("relationship", "trust_level", "high");
        _service.RemoveFact("relationship", "trust_level");

        Assert.Equal("initial", _service.Current.Relationship.TrustLevel);
    }

    [Fact]
    public void RemoveFact_UnknownCategory_DoesNotThrow()
    {
        _service.Load();
        _service.RemoveFact("unknown", "key");
    }

    // ---- FormatForPrompt ----

    [Fact]
    public void FormatForPrompt_EmptyMemory_ContainsRelationship()
    {
        _service.Load();
        var text = _service.FormatForPrompt();

        // Even with empty memory, relationship line is always present
        Assert.Contains("Relationship: new (0 days together)", text);
    }

    [Fact]
    public void FormatForPrompt_ContainsUserName()
    {
        _service.Load();
        _service.UpdateFact("user_profile", "name", "Ricky");

        var text = _service.FormatForPrompt();

        Assert.Contains("Name: Ricky", text);
    }

    [Fact]
    public void FormatForPrompt_ContainsAllProfileFields()
    {
        _service.Load();
        _service.UpdateFact("user_profile", "name", "Ricky");
        _service.UpdateFact("user_profile", "nickname", "Rick");
        _service.UpdateFact("user_profile", "occupation", "CS student");
        _service.UpdateFact("user_profile", "age_range", "20-25");
        _service.UpdateFact("user_profile", "language", "English");
        _service.UpdateFact("user_profile", "key_fact", "Plays piano");

        var text = _service.FormatForPrompt();

        Assert.Contains("Name: Ricky", text);
        Assert.Contains("Nickname: Rick", text);
        Assert.Contains("Occupation: CS student", text);
        Assert.Contains("Age range: 20-25", text);
        Assert.Contains("Languages: English", text);
        Assert.Contains("Plays piano", text);
    }

    [Fact]
    public void FormatForPrompt_ContainsPersonalityFields()
    {
        _service.Load();
        _service.UpdateFact("personality", "interest", "Programming");
        _service.UpdateFact("personality", "interest", "Gaming");
        _service.UpdateFact("personality", "communication_style", "Casual");

        var text = _service.FormatForPrompt();

        Assert.Contains("Key interests: Programming, Gaming", text);
        Assert.Contains("Communication style: Casual", text);
    }

    [Fact]
    public void FormatForPrompt_HandlesEmptyFields_Gracefully()
    {
        _service.Load();
        // Don't set any fields except what's always shown
        var text = _service.FormatForPrompt();

        Assert.NotNull(text);
        Assert.DoesNotContain("Name:", text);
        Assert.DoesNotContain("Occupation:", text);
        Assert.DoesNotContain("Key interests:", text);
        Assert.Contains("Relationship:", text);
    }

    [Fact]
    public void FormatForPrompt_IncludesInsideJokes()
    {
        _service.Load();
        _service.UpdateFact("relationship", "inside_joke", "The paper plane incident");

        var text = _service.FormatForPrompt();

        Assert.Contains("Inside jokes: The paper plane incident", text);
    }

    // ---- Current ----

    [Fact]
    public void Current_ReturnsCache()
    {
        var loaded = _service.Load();
        Assert.Same(loaded, _service.Current);
    }

    // ---- Constructor ----

    [Fact]
    public void Constructor_CreatesDirectory()
    {
        var nested = Path.Combine(_tempDir, "sub", "dir");
        var svc = new CoreMemoryService(nested);
        Assert.True(Directory.Exists(nested));
    }

    [Fact]
    public void UpdateFact_RelationshipDaysTogether_InvalidString_DoesNotChange()
    {
        _service.Load();
        _service.UpdateFact("relationship", "days_together", "90");
        _service.UpdateFact("relationship", "days_together", "not_a_number");
        Assert.Equal(90, _service.Current.Relationship.DaysTogether);
    }

    [Fact]
    public void UpdateFact_CaseInsensitiveCategory()
    {
        _service.Load();
        _service.UpdateFact("USER_PROFILE", "name", "Test");
        Assert.Equal("Test", _service.Current.UserProfile.Name);
    }

    [Fact]
    public void UpdateFact_CaseInsensitiveKey()
    {
        _service.Load();
        _service.UpdateFact("user_profile", "NAME", "Test");
        Assert.Equal("Test", _service.Current.UserProfile.Name);
    }

    [Fact]
    public void UpdateFact_UnknownKey_DoesNotThrow()
    {
        _service.Load();
        _service.UpdateFact("user_profile", "unknown_key", "value");
        // Should not throw — silently ignored
    }

    [Fact]
    public void RemoveFact_UnknownKey_DoesNotThrow()
    {
        _service.Load();
        _service.RemoveFact("user_profile", "unknown_key");
        // Should not throw
    }

    [Fact]
    public void FormatForPrompt_ContainsDislikes()
    {
        _service.Load();
        _service.UpdateFact("personality", "dislike", "Bugs");
        var text = _service.FormatForPrompt();
        Assert.Contains("Dislikes: Bugs", text);
    }

    [Fact]
    public void FormatForPrompt_ContainsMoodPatterns()
    {
        _service.Load();
        _service.UpdateFact("personality", "mood_patterns", "Usually upbeat in mornings");
        var text = _service.FormatForPrompt();
        Assert.Contains("Mood patterns: Usually upbeat in mornings", text);
    }
}
