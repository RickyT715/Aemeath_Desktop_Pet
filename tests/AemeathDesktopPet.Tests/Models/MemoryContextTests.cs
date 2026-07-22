using AemeathDesktopPet.Models;

namespace AemeathDesktopPet.Tests.Models;

public class MemoryContextTests
{
    [Fact]
    public void DefaultValues_AllNullOrEmpty()
    {
        var ctx = new MemoryContext();

        Assert.Null(ctx.UserName);
        Assert.Empty(ctx.UserFacts);
        Assert.Empty(ctx.Preferences);
        Assert.Empty(ctx.RecentTopics);
        Assert.Null(ctx.SessionSummary);
        Assert.Empty(ctx.Observations);
        Assert.Empty(ctx.UpcomingEvents);
        Assert.Null(ctx.RelationshipStage);
        Assert.Equal(0, ctx.DaysTogether);
        Assert.Null(ctx.CommunicationStyle);
    }

    [Fact]
    public void SetUserName_Persists()
    {
        var ctx = new MemoryContext { UserName = "Ricky" };
        Assert.Equal("Ricky", ctx.UserName);
    }

    [Fact]
    public void UserFacts_CanAddItems()
    {
        var ctx = new MemoryContext();
        ctx.UserFacts.Add("Likes programming");
        ctx.UserFacts.Add("Studies CS");

        Assert.Equal(2, ctx.UserFacts.Count);
        Assert.Contains("Likes programming", ctx.UserFacts);
    }

    [Fact]
    public void Preferences_CanAddItems()
    {
        var ctx = new MemoryContext();
        ctx.Preferences.Add("Dark mode");
        Assert.Single(ctx.Preferences);
    }

    [Fact]
    public void RecentTopics_CanAddItems()
    {
        var ctx = new MemoryContext();
        ctx.RecentTopics.Add("[3 days ago] Talked about exam");
        Assert.Single(ctx.RecentTopics);
    }

    [Fact]
    public void Observations_CanAddItems()
    {
        var ctx = new MemoryContext();
        ctx.Observations.Add("VS Code open for 45 min");
        Assert.Single(ctx.Observations);
    }

    [Fact]
    public void UpcomingEvents_CanAddItems()
    {
        var ctx = new MemoryContext();
        ctx.UpcomingEvents.Add("Calculus exam: March 10");
        Assert.Single(ctx.UpcomingEvents);
    }

    [Fact]
    public void RelationshipStage_CanBeSet()
    {
        var ctx = new MemoryContext { RelationshipStage = "familiar" };
        Assert.Equal("familiar", ctx.RelationshipStage);
    }

    [Fact]
    public void DaysTogether_CanBeSet()
    {
        var ctx = new MemoryContext { DaysTogether = 45 };
        Assert.Equal(45, ctx.DaysTogether);
    }

    [Fact]
    public void CommunicationStyle_CanBeSet()
    {
        var ctx = new MemoryContext { CommunicationStyle = "Casual, appreciates humor" };
        Assert.Equal("Casual, appreciates humor", ctx.CommunicationStyle);
    }

    [Fact]
    public void SessionSummary_CanBeSet()
    {
        var ctx = new MemoryContext { SessionSummary = "User discussed exam prep" };
        Assert.Equal("User discussed exam prep", ctx.SessionSummary);
    }

    [Fact]
    public void FullyPopulatedContext_AllFieldsAccessible()
    {
        var ctx = new MemoryContext
        {
            UserName = "Ricky",
            UserFacts = new List<string> { "CS student", "Likes WuWa" },
            Preferences = new List<string> { "Dark mode" },
            RecentTopics = new List<string> { "Exam stress" },
            SessionSummary = "Talked about study plans",
            Observations = new List<string> { "Coding in VS Code" },
            UpcomingEvents = new List<string> { "Exam March 10" },
            RelationshipStage = "close_friend",
            DaysTogether = 90,
            CommunicationStyle = "Casual"
        };

        Assert.Equal("Ricky", ctx.UserName);
        Assert.Equal(2, ctx.UserFacts.Count);
        Assert.Single(ctx.Preferences);
        Assert.Single(ctx.RecentTopics);
        Assert.Equal("Talked about study plans", ctx.SessionSummary);
        Assert.Single(ctx.Observations);
        Assert.Single(ctx.UpcomingEvents);
        Assert.Equal("close_friend", ctx.RelationshipStage);
        Assert.Equal(90, ctx.DaysTogether);
        Assert.Equal("Casual", ctx.CommunicationStyle);
    }
}
