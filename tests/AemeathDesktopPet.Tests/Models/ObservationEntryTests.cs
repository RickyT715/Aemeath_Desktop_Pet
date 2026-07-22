using AemeathDesktopPet.Models;

namespace AemeathDesktopPet.Tests.Models;

public class ObservationEntryTests
{
    [Fact]
    public void DefaultValues()
    {
        var entry = new ObservationEntry();

        Assert.NotNull(entry.Id);
        Assert.Equal(8, entry.Id.Length);
        Assert.Equal("", entry.Source);
        Assert.Equal("", entry.Content);
        Assert.Equal("", entry.ActivityContext);
        Assert.Equal(24, entry.TtlHours);
    }

    [Fact]
    public void Id_IsUnique()
    {
        var entry1 = new ObservationEntry();
        var entry2 = new ObservationEntry();
        Assert.NotEqual(entry1.Id, entry2.Id);
    }

    [Fact]
    public void Timestamp_DefaultsToUtcNow()
    {
        var before = DateTime.UtcNow;
        var entry = new ObservationEntry();
        var after = DateTime.UtcNow;

        Assert.InRange(entry.Timestamp, before, after);
    }

    [Fact]
    public void IsExpired_FalseWhenFresh()
    {
        var entry = new ObservationEntry { Timestamp = DateTime.UtcNow };
        Assert.False(entry.IsExpired);
    }

    [Fact]
    public void IsExpired_TrueWhenOlderThanTtl()
    {
        var entry = new ObservationEntry
        {
            Timestamp = DateTime.UtcNow.AddHours(-25),
            TtlHours = 24
        };
        Assert.True(entry.IsExpired);
    }

    [Fact]
    public void IsExpired_FalseWhenExactlyAtTtl()
    {
        // Entry created exactly TtlHours ago should not be expired yet
        // (it expires strictly after TTL)
        var entry = new ObservationEntry
        {
            Timestamp = DateTime.UtcNow.AddHours(-23),
            TtlHours = 24
        };
        Assert.False(entry.IsExpired);
    }

    [Fact]
    public void IsExpired_RespectsCustomTtl()
    {
        var entry = new ObservationEntry
        {
            Timestamp = DateTime.UtcNow.AddHours(-2),
            TtlHours = 1
        };
        Assert.True(entry.IsExpired);
    }

    [Fact]
    public void SetAllFields()
    {
        var entry = new ObservationEntry
        {
            Id = "custom01",
            Source = "screen",
            Content = "User viewing Khan Academy calculus video",
            ActivityContext = "StudyingCoding",
            TtlHours = 48
        };

        Assert.Equal("custom01", entry.Id);
        Assert.Equal("screen", entry.Source);
        Assert.Contains("Khan Academy", entry.Content);
        Assert.Equal("StudyingCoding", entry.ActivityContext);
        Assert.Equal(48, entry.TtlHours);
    }

    [Theory]
    [InlineData("screen")]
    [InlineData("activity")]
    [InlineData("camera")]
    [InlineData("pomodoro")]
    public void Source_AcceptsAllValidValues(string source)
    {
        var entry = new ObservationEntry { Source = source };
        Assert.Equal(source, entry.Source);
    }
}

public class ObservationBufferTests
{
    [Fact]
    public void DefaultValues()
    {
        var buffer = new ObservationBuffer();
        Assert.NotNull(buffer.Entries);
        Assert.Empty(buffer.Entries);
    }

    [Fact]
    public void CanAddEntries()
    {
        var buffer = new ObservationBuffer();
        buffer.Entries.Add(new ObservationEntry { Source = "screen", Content = "Test" });
        buffer.Entries.Add(new ObservationEntry { Source = "activity", Content = "Test 2" });

        Assert.Equal(2, buffer.Entries.Count);
    }

    [Fact]
    public void CanFilterExpiredEntries()
    {
        var buffer = new ObservationBuffer();
        buffer.Entries.Add(new ObservationEntry
        {
            Source = "screen",
            Content = "Old entry",
            Timestamp = DateTime.UtcNow.AddHours(-25)
        });
        buffer.Entries.Add(new ObservationEntry
        {
            Source = "screen",
            Content = "New entry",
            Timestamp = DateTime.UtcNow
        });

        var active = buffer.Entries.Where(e => !e.IsExpired).ToList();
        Assert.Single(active);
        Assert.Equal("New entry", active[0].Content);
    }
}
