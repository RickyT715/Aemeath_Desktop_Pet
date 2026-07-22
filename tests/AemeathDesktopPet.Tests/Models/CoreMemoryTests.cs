using AemeathDesktopPet.Models;

namespace AemeathDesktopPet.Tests.Models;

public class CoreMemoryTests
{
    [Fact]
    public void DefaultValues()
    {
        var mem = new CoreMemory();

        Assert.Equal(1, mem.Version);
        Assert.NotNull(mem.UserProfile);
        Assert.NotNull(mem.Personality);
        Assert.NotNull(mem.Relationship);
    }

    [Fact]
    public void LastUpdated_DefaultsToUtcNow()
    {
        var before = DateTime.UtcNow;
        var mem = new CoreMemory();
        var after = DateTime.UtcNow;

        Assert.InRange(mem.LastUpdated, before, after);
    }

    [Fact]
    public void Version_CanBeUpdated()
    {
        var mem = new CoreMemory { Version = 2 };
        Assert.Equal(2, mem.Version);
    }
}

public class UserProfileTests
{
    [Fact]
    public void DefaultValues()
    {
        var profile = new UserProfile();

        Assert.Null(profile.Name);
        Assert.Null(profile.Nickname);
        Assert.Null(profile.AgeRange);
        Assert.Null(profile.Occupation);
        Assert.Empty(profile.KeyFacts);
        Assert.Empty(profile.Languages);
    }

    [Fact]
    public void SetAllFields()
    {
        var profile = new UserProfile
        {
            Name = "Ricky",
            Nickname = "Rick",
            AgeRange = "20-25",
            Occupation = "CS student",
            KeyFacts = new List<string> { "Likes Wuthering Waves", "Plays piano" },
            Languages = new List<string> { "English", "Chinese" }
        };

        Assert.Equal("Ricky", profile.Name);
        Assert.Equal("Rick", profile.Nickname);
        Assert.Equal("20-25", profile.AgeRange);
        Assert.Equal("CS student", profile.Occupation);
        Assert.Equal(2, profile.KeyFacts.Count);
        Assert.Equal(2, profile.Languages.Count);
    }

    [Fact]
    public void KeyFacts_CanAddAndRemove()
    {
        var profile = new UserProfile();
        profile.KeyFacts.Add("Fact A");
        profile.KeyFacts.Add("Fact B");
        Assert.Equal(2, profile.KeyFacts.Count);

        profile.KeyFacts.Remove("Fact A");
        Assert.Single(profile.KeyFacts);
        Assert.Contains("Fact B", profile.KeyFacts);
    }
}

public class UserPersonalityTests
{
    [Fact]
    public void DefaultValues()
    {
        var personality = new UserPersonality();

        Assert.Null(personality.CommunicationStyle);
        Assert.Null(personality.MoodPatterns);
        Assert.Empty(personality.Interests);
        Assert.Empty(personality.Dislikes);
    }

    [Fact]
    public void SetAllFields()
    {
        var personality = new UserPersonality
        {
            CommunicationStyle = "Casual",
            MoodPatterns = "Generally upbeat",
            Interests = new List<string> { "Programming", "Gaming" },
            Dislikes = new List<string> { "Bugs" }
        };

        Assert.Equal("Casual", personality.CommunicationStyle);
        Assert.Equal("Generally upbeat", personality.MoodPatterns);
        Assert.Equal(2, personality.Interests.Count);
        Assert.Single(personality.Dislikes);
    }
}

public class RelationshipStateTests
{
    [Fact]
    public void DefaultValues()
    {
        var rel = new RelationshipState();

        Assert.Equal("new", rel.Stage);
        Assert.Equal(0, rel.DaysTogether);
        Assert.Equal("initial", rel.TrustLevel);
        Assert.Empty(rel.InsideJokes);
        Assert.Empty(rel.Milestones);
    }

    [Theory]
    [InlineData("new")]
    [InlineData("acquaintance")]
    [InlineData("familiar")]
    [InlineData("close_friend")]
    [InlineData("best_friend")]
    public void Stage_AcceptsAllValidValues(string stage)
    {
        var rel = new RelationshipState { Stage = stage };
        Assert.Equal(stage, rel.Stage);
    }

    [Fact]
    public void InsideJokes_CanAddItems()
    {
        var rel = new RelationshipState();
        rel.InsideJokes.Add("The paper plane incident");
        Assert.Single(rel.InsideJokes);
    }

    [Fact]
    public void Milestones_CanAddItems()
    {
        var rel = new RelationshipState();
        rel.Milestones.Add("First conversation");
        rel.Milestones.Add("Shared a song together");
        Assert.Equal(2, rel.Milestones.Count);
    }

    [Fact]
    public void DaysTogether_CanBeSet()
    {
        var rel = new RelationshipState { DaysTogether = 365 };
        Assert.Equal(365, rel.DaysTogether);
    }
}
