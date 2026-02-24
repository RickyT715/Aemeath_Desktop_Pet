using AemeathDesktopPet.Models;
using AemeathDesktopPet.Services;
using Microsoft.Data.Sqlite;

namespace AemeathDesktopPet.Tests.Services;

public class ActivityMonitorServiceTests : IDisposable
{
    private readonly string _tempDir;
    private readonly string _dbPath;

    public ActivityMonitorServiceTests()
    {
        _tempDir = Path.Combine(Path.GetTempPath(), "AemeathTests_AM_" + Guid.NewGuid().ToString("N")[..8]);
        Directory.CreateDirectory(_tempDir);
        _dbPath = Path.Combine(_tempDir, "monitor.db");
    }

    public void Dispose()
    {
        SqliteConnection.ClearAllPools();
        if (Directory.Exists(_tempDir))
            Directory.Delete(_tempDir, recursive: true);
    }

    private ActivityMonitorService CreateService(bool enabled = true, string? dbPath = null)
    {
        var config = new ActivityMonitorConfig
        {
            Enabled = enabled,
            DatabasePath = dbPath ?? _dbPath
        };
        return new ActivityMonitorService(() => config);
    }

    private void CreateDatabase(bool withWindowSessions = true, bool withChromeSessions = true)
    {
        using var conn = new SqliteConnection($"Data Source={_dbPath}");
        conn.Open();

        if (withWindowSessions)
        {
            using var cmd = conn.CreateCommand();
            cmd.CommandText = @"
                CREATE TABLE window_sessions (
                    id INTEGER PRIMARY KEY,
                    process_name TEXT NOT NULL,
                    window_title TEXT,
                    start_time TEXT NOT NULL,
                    end_time TEXT,
                    duration_seconds REAL NOT NULL
                )";
            cmd.ExecuteNonQuery();
        }

        if (withChromeSessions)
        {
            using var cmd = conn.CreateCommand();
            cmd.CommandText = @"
                CREATE TABLE chrome_sessions (
                    id INTEGER PRIMARY KEY,
                    page_title TEXT,
                    url TEXT,
                    domain TEXT,
                    start_time TEXT NOT NULL,
                    end_time TEXT,
                    duration_seconds REAL NOT NULL
                )";
            cmd.ExecuteNonQuery();
        }
    }

    private void InsertWindowSession(string process, string? title, string startTime, double duration)
    {
        using var conn = new SqliteConnection($"Data Source={_dbPath}");
        conn.Open();
        using var cmd = conn.CreateCommand();
        cmd.CommandText = @"
            INSERT INTO window_sessions (process_name, window_title, start_time, duration_seconds)
            VALUES (@process, @title, @start, @duration)";
        cmd.Parameters.AddWithValue("@process", process);
        cmd.Parameters.AddWithValue("@title", (object?)title ?? DBNull.Value);
        cmd.Parameters.AddWithValue("@start", startTime);
        cmd.Parameters.AddWithValue("@duration", duration);
        cmd.ExecuteNonQuery();
    }

    private void InsertChromeSession(string? domain, string? title, string startTime, double duration)
    {
        using var conn = new SqliteConnection($"Data Source={_dbPath}");
        conn.Open();
        using var cmd = conn.CreateCommand();
        cmd.CommandText = @"
            INSERT INTO chrome_sessions (domain, page_title, start_time, duration_seconds)
            VALUES (@domain, @title, @start, @duration)";
        cmd.Parameters.AddWithValue("@domain", (object?)domain ?? DBNull.Value);
        cmd.Parameters.AddWithValue("@title", (object?)title ?? DBNull.Value);
        cmd.Parameters.AddWithValue("@start", startTime);
        cmd.Parameters.AddWithValue("@duration", duration);
        cmd.ExecuteNonQuery();
    }

    // --- IsAvailable ---

    [Fact]
    public void IsAvailable_ReturnsFalse_WhenDisabled()
    {
        CreateDatabase();
        var service = CreateService(enabled: false);
        Assert.False(service.IsAvailable);
    }

    [Fact]
    public void IsAvailable_ReturnsFalse_WhenDbDoesNotExist()
    {
        var service = CreateService(enabled: true, dbPath: Path.Combine(_tempDir, "nonexistent.db"));
        Assert.False(service.IsAvailable);
    }

    [Fact]
    public void IsAvailable_ReturnsTrue_WhenEnabledAndDbExists()
    {
        CreateDatabase();
        var service = CreateService(enabled: true);
        Assert.True(service.IsAvailable);
    }

    // --- GetActivitySummary: disabled/unavailable ---

    [Fact]
    public void GetActivitySummary_ReturnsEmpty_WhenDisabled()
    {
        CreateDatabase();
        var service = CreateService(enabled: false);
        var result = service.GetActivitySummary(DateTime.Now.AddHours(-1), DateTime.Now);
        Assert.Equal("", result);
    }

    [Fact]
    public void GetActivitySummary_ReturnsEmpty_WhenDbMissing()
    {
        var service = CreateService(enabled: true, dbPath: Path.Combine(_tempDir, "missing.db"));
        var result = service.GetActivitySummary(DateTime.Now.AddHours(-1), DateTime.Now);
        Assert.Equal("", result);
    }

    // --- GetActivitySummary: empty tables ---

    [Fact]
    public void GetActivitySummary_ReturnsEmpty_WhenNoData()
    {
        CreateDatabase();
        var service = CreateService();
        var result = service.GetActivitySummary(DateTime.Now.AddHours(-1), DateTime.Now);
        Assert.Equal("", result);
    }

    // --- GetActivitySummary: window sessions ---

    [Fact]
    public void GetActivitySummary_ReturnsWindowActivity()
    {
        CreateDatabase();
        InsertWindowSession("Code.exe", "PetWindow.xaml.cs", "2026-02-15 10:00:00", 720);

        var service = CreateService();
        var from = new DateTime(2026, 2, 15, 9, 0, 0);
        var to = new DateTime(2026, 2, 15, 11, 0, 0);

        var result = service.GetActivitySummary(from, to);

        Assert.StartsWith("[Recent Activity]", result);
        Assert.Contains("Code", result);
        Assert.Contains("PetWindow.xaml.cs", result);
        Assert.Contains("12 min", result);
    }

    [Fact]
    public void GetActivitySummary_StripsExeExtension()
    {
        CreateDatabase();
        InsertWindowSession("devenv.exe", "Solution Explorer", "2026-02-15 10:00:00", 300);

        var service = CreateService();
        var from = new DateTime(2026, 2, 15, 9, 0, 0);
        var to = new DateTime(2026, 2, 15, 11, 0, 0);

        var result = service.GetActivitySummary(from, to);

        Assert.Contains("devenv", result);
        Assert.DoesNotContain(".exe", result);
    }

    // --- GetActivitySummary: chrome sessions ---

    [Fact]
    public void GetActivitySummary_ReturnsChromeActivity()
    {
        CreateDatabase();
        InsertChromeSession("github.com", "Pull request #42", "2026-02-15 10:00:00", 480);

        var service = CreateService();
        var from = new DateTime(2026, 2, 15, 9, 0, 0);
        var to = new DateTime(2026, 2, 15, 11, 0, 0);

        var result = service.GetActivitySummary(from, to);

        Assert.StartsWith("[Recent Activity]", result);
        Assert.Contains("github.com", result);
        Assert.Contains("Pull request #42", result);
    }

    // --- GetActivitySummary: mixed data ---

    [Fact]
    public void GetActivitySummary_CombinesWindowAndChrome()
    {
        CreateDatabase();
        InsertWindowSession("Code.exe", "main.ts", "2026-02-15 10:00:00", 600);
        InsertChromeSession("stackoverflow.com", "How to unit test", "2026-02-15 10:05:00", 300);

        var service = CreateService();
        var from = new DateTime(2026, 2, 15, 9, 0, 0);
        var to = new DateTime(2026, 2, 15, 11, 0, 0);

        var result = service.GetActivitySummary(from, to);

        Assert.Contains("Code", result);
        Assert.Contains("stackoverflow.com", result);
    }

    // --- GetActivitySummary: ordering and grouping ---

    [Fact]
    public void GetActivitySummary_SortsByDurationDescending()
    {
        CreateDatabase();
        InsertWindowSession("notepad.exe", "notes.txt", "2026-02-15 10:00:00", 60);
        InsertWindowSession("Code.exe", "app.ts", "2026-02-15 10:02:00", 900);
        InsertWindowSession("explorer.exe", "Downloads", "2026-02-15 10:20:00", 120);

        var service = CreateService();
        var from = new DateTime(2026, 2, 15, 9, 0, 0);
        var to = new DateTime(2026, 2, 15, 11, 0, 0);

        var result = service.GetActivitySummary(from, to);

        // Code (900s = 15 min) should appear before explorer (120s) and notepad (60s)
        int codePos = result.IndexOf("Code");
        int explorerPos = result.IndexOf("explorer");
        int notepadPos = result.IndexOf("notepad");

        Assert.True(codePos < explorerPos, "Code should appear before explorer");
        Assert.True(explorerPos < notepadPos, "explorer should appear before notepad");
    }

    [Fact]
    public void GetActivitySummary_GroupsDuplicateLabels()
    {
        CreateDatabase();
        // Two sessions for the same app+title should be grouped
        InsertWindowSession("Code.exe", "index.ts", "2026-02-15 10:00:00", 300);
        InsertWindowSession("Code.exe", "index.ts", "2026-02-15 10:10:00", 300);

        var service = CreateService();
        var from = new DateTime(2026, 2, 15, 9, 0, 0);
        var to = new DateTime(2026, 2, 15, 11, 0, 0);

        var result = service.GetActivitySummary(from, to);

        // Should show 10 min (300 + 300 = 600s), not two separate entries
        Assert.Contains("10 min", result);
        // Should only appear once
        int firstIdx = result.IndexOf("Code - index.ts");
        int lastIdx = result.LastIndexOf("Code - index.ts");
        Assert.Equal(firstIdx, lastIdx);
    }

    [Fact]
    public void GetActivitySummary_LimitsToTop5Entries()
    {
        CreateDatabase();
        for (int i = 1; i <= 8; i++)
        {
            InsertWindowSession($"app{i}.exe", $"Window {i}", "2026-02-15 10:00:00", i * 60);
        }

        var service = CreateService();
        var from = new DateTime(2026, 2, 15, 9, 0, 0);
        var to = new DateTime(2026, 2, 15, 11, 0, 0);

        var result = service.GetActivitySummary(from, to);

        // Top 5 by duration: app8 (480s), app7 (420s), app6 (360s), app5 (300s), app4 (240s)
        Assert.Contains("app8", result);
        Assert.Contains("app5", result);
        // app1 (60s) should NOT appear — it's outside top 5
        Assert.DoesNotContain("app1", result);
        Assert.DoesNotContain("app2", result);
        Assert.DoesNotContain("app3", result);
    }

    // --- GetActivitySummary: time range filtering ---

    [Fact]
    public void GetActivitySummary_FiltersOutOfRange()
    {
        CreateDatabase();
        InsertWindowSession("Code.exe", "in-range.ts", "2026-02-15 10:30:00", 300);
        InsertWindowSession("notepad.exe", "out-of-range.txt", "2026-02-15 08:00:00", 600);

        var service = CreateService();
        var from = new DateTime(2026, 2, 15, 10, 0, 0);
        var to = new DateTime(2026, 2, 15, 11, 0, 0);

        var result = service.GetActivitySummary(from, to);

        Assert.Contains("Code", result);
        Assert.DoesNotContain("notepad", result);
    }

    // --- GetActivitySummary: formatting edge cases ---

    [Fact]
    public void GetActivitySummary_MinDurationIsOneMinute()
    {
        CreateDatabase();
        // 10 seconds should round to 1 min minimum
        InsertWindowSession("Code.exe", "tiny.ts", "2026-02-15 10:00:00", 10);

        var service = CreateService();
        var from = new DateTime(2026, 2, 15, 9, 0, 0);
        var to = new DateTime(2026, 2, 15, 11, 0, 0);

        var result = service.GetActivitySummary(from, to);

        Assert.Contains("1 min", result);
    }

    [Fact]
    public void GetActivitySummary_TruncatesLongWindowTitles()
    {
        CreateDatabase();
        var longTitle = new string('A', 60); // 60 chars, exceeds 40 char limit
        InsertWindowSession("Code.exe", longTitle, "2026-02-15 10:00:00", 300);

        var service = CreateService();
        var from = new DateTime(2026, 2, 15, 9, 0, 0);
        var to = new DateTime(2026, 2, 15, 11, 0, 0);

        var result = service.GetActivitySummary(from, to);

        Assert.Contains("...", result);
        // Should not contain the full 60-char title
        Assert.DoesNotContain(longTitle, result);
    }

    [Fact]
    public void GetActivitySummary_TruncatesLongChromeTitles()
    {
        CreateDatabase();
        var longTitle = new string('B', 50); // 50 chars, exceeds 35 char limit
        InsertChromeSession("example.com", longTitle, "2026-02-15 10:00:00", 300);

        var service = CreateService();
        var from = new DateTime(2026, 2, 15, 9, 0, 0);
        var to = new DateTime(2026, 2, 15, 11, 0, 0);

        var result = service.GetActivitySummary(from, to);

        Assert.Contains("...", result);
        Assert.DoesNotContain(longTitle, result);
    }

    [Fact]
    public void GetActivitySummary_HandlesNullWindowTitle()
    {
        CreateDatabase();
        InsertWindowSession("explorer.exe", null, "2026-02-15 10:00:00", 300);

        var service = CreateService();
        var from = new DateTime(2026, 2, 15, 9, 0, 0);
        var to = new DateTime(2026, 2, 15, 11, 0, 0);

        var result = service.GetActivitySummary(from, to);

        // Should show just the process name without a title
        Assert.Contains("\"explorer\"", result);
    }

    [Fact]
    public void GetActivitySummary_HandlesNullChromeDomain()
    {
        CreateDatabase();
        InsertChromeSession(null, "Some Page", "2026-02-15 10:00:00", 300);

        var service = CreateService();
        var from = new DateTime(2026, 2, 15, 9, 0, 0);
        var to = new DateTime(2026, 2, 15, 11, 0, 0);

        var result = service.GetActivitySummary(from, to);

        Assert.Contains("Chrome", result);
    }

    [Fact]
    public void GetActivitySummary_HandlesShortWindowTitle()
    {
        CreateDatabase();
        InsertWindowSession("app.exe", "ab", "2026-02-15 10:00:00", 300);

        var service = CreateService();
        var from = new DateTime(2026, 2, 15, 9, 0, 0);
        var to = new DateTime(2026, 2, 15, 11, 0, 0);

        var result = service.GetActivitySummary(from, to);

        // Title < 3 chars should show just process name
        Assert.Contains("\"app\"", result);
        Assert.DoesNotContain("ab", result);
    }

    [Fact]
    public void GetActivitySummary_HandlesShortChromeTitle()
    {
        CreateDatabase();
        InsertChromeSession("example.com", "hi", "2026-02-15 10:00:00", 300);

        var service = CreateService();
        var from = new DateTime(2026, 2, 15, 9, 0, 0);
        var to = new DateTime(2026, 2, 15, 11, 0, 0);

        var result = service.GetActivitySummary(from, to);

        // Short title should fall back to domain-only label
        Assert.Contains("Chrome on example.com", result);
    }

    // --- GetActivitySummary: result capping ---

    [Fact]
    public void GetActivitySummary_CapsAt250Chars()
    {
        CreateDatabase();
        // Insert many entries with long titles to produce a very long summary
        for (int i = 0; i < 20; i++)
        {
            InsertWindowSession($"very_long_process_name_{i}.exe",
                $"A very long window title for session number {i} that fills space",
                "2026-02-15 10:00:00", (20 - i) * 120);
        }

        var service = CreateService();
        var from = new DateTime(2026, 2, 15, 9, 0, 0);
        var to = new DateTime(2026, 2, 15, 11, 0, 0);

        var result = service.GetActivitySummary(from, to);

        Assert.True(result.Length <= 250, $"Result was {result.Length} chars, expected <= 250");
    }

    [Fact]
    public void GetActivitySummary_EndsWith_Period_Or_Ellipsis()
    {
        CreateDatabase();
        InsertWindowSession("Code.exe", "test.ts", "2026-02-15 10:00:00", 300);

        var service = CreateService();
        var from = new DateTime(2026, 2, 15, 9, 0, 0);
        var to = new DateTime(2026, 2, 15, 11, 0, 0);

        var result = service.GetActivitySummary(from, to);

        Assert.True(result.EndsWith('.') || result.EndsWith("..."),
            $"Result should end with '.' or '...' but was: {result}");
    }

    // --- GetActivitySummary: missing tables ---

    [Fact]
    public void GetActivitySummary_HandlesNoWindowSessionsTable()
    {
        CreateDatabase(withWindowSessions: false, withChromeSessions: true);
        InsertChromeSession("github.com", "Issues", "2026-02-15 10:00:00", 300);

        var service = CreateService();
        var from = new DateTime(2026, 2, 15, 9, 0, 0);
        var to = new DateTime(2026, 2, 15, 11, 0, 0);

        var result = service.GetActivitySummary(from, to);

        // Should still return chrome data even without window_sessions table
        Assert.Contains("github.com", result);
    }

    [Fact]
    public void GetActivitySummary_HandlesNoChromeSessions()
    {
        CreateDatabase(withWindowSessions: true, withChromeSessions: false);
        InsertWindowSession("Code.exe", "main.ts", "2026-02-15 10:00:00", 300);

        var service = CreateService();
        var from = new DateTime(2026, 2, 15, 9, 0, 0);
        var to = new DateTime(2026, 2, 15, 11, 0, 0);

        var result = service.GetActivitySummary(from, to);

        // Should still return window data even without chrome_sessions table
        Assert.Contains("Code", result);
    }

    [Fact]
    public void GetActivitySummary_HandlesEmptyDatabase()
    {
        // Create DB with no tables at all
        using (var conn = new SqliteConnection($"Data Source={_dbPath}"))
        {
            conn.Open();
        }

        var service = CreateService();
        var from = new DateTime(2026, 2, 15, 9, 0, 0);
        var to = new DateTime(2026, 2, 15, 11, 0, 0);

        var result = service.GetActivitySummary(from, to);

        Assert.Equal("", result);
    }

    // --- GetActivitySummary: corrupt/invalid DB ---

    [Fact]
    public void GetActivitySummary_HandlesCorruptDb()
    {
        File.WriteAllText(_dbPath, "this is not a valid sqlite database");

        var service = CreateService();
        var from = new DateTime(2026, 2, 15, 9, 0, 0);
        var to = new DateTime(2026, 2, 15, 11, 0, 0);

        var result = service.GetActivitySummary(from, to);

        Assert.Equal("", result);
    }

    // --- GetActivitySummary: zero duration filtered ---

    [Fact]
    public void GetActivitySummary_SkipsZeroDuration()
    {
        CreateDatabase();
        InsertWindowSession("Code.exe", "active.ts", "2026-02-15 10:00:00", 300);
        InsertWindowSession("notepad.exe", "zero.txt", "2026-02-15 10:00:00", 0);

        var service = CreateService();
        var from = new DateTime(2026, 2, 15, 9, 0, 0);
        var to = new DateTime(2026, 2, 15, 11, 0, 0);

        var result = service.GetActivitySummary(from, to);

        Assert.Contains("Code", result);
        Assert.DoesNotContain("notepad", result);
    }

    // --- Config accessor is called fresh each time ---

    [Fact]
    public void IsAvailable_ReflectsConfigChanges()
    {
        CreateDatabase();
        var config = new ActivityMonitorConfig
        {
            Enabled = false,
            DatabasePath = _dbPath
        };
        var service = new ActivityMonitorService(() => config);

        Assert.False(service.IsAvailable);

        config.Enabled = true;
        Assert.True(service.IsAvailable);
    }

    // --- Comma separator between entries ---

    [Fact]
    public void GetActivitySummary_SeparatesEntriesWithCommas()
    {
        CreateDatabase();
        InsertWindowSession("Code.exe", "file1.ts", "2026-02-15 10:00:00", 600);
        InsertWindowSession("Discord.exe", "General", "2026-02-15 10:10:00", 300);

        var service = CreateService();
        var from = new DateTime(2026, 2, 15, 9, 0, 0);
        var to = new DateTime(2026, 2, 15, 11, 0, 0);

        var result = service.GetActivitySummary(from, to);

        // Should have a comma between the two entries
        Assert.Contains(", ", result);
    }

    // --- Prefix format ---

    [Fact]
    public void GetActivitySummary_StartsWithRecentActivityPrefix()
    {
        CreateDatabase();
        InsertWindowSession("Code.exe", "test.cs", "2026-02-15 10:00:00", 300);

        var service = CreateService();
        var from = new DateTime(2026, 2, 15, 9, 0, 0);
        var to = new DateTime(2026, 2, 15, 11, 0, 0);

        var result = service.GetActivitySummary(from, to);

        Assert.StartsWith("[Recent Activity] ", result);
    }

    // --- GetCameraSummary: disabled/unavailable ---

    [Fact]
    public void GetCameraSummary_ReturnsEmpty_WhenDisabled()
    {
        CreateDatabase();
        var service = CreateService(enabled: false);
        var result = service.GetCameraSummary(DateTime.Now.AddHours(-1), DateTime.Now);
        Assert.Equal("", result);
    }

    [Fact]
    public void GetCameraSummary_ReturnsEmpty_WhenDbMissing()
    {
        var service = CreateService(enabled: true, dbPath: Path.Combine(_tempDir, "missing.db"));
        var result = service.GetCameraSummary(DateTime.Now.AddHours(-1), DateTime.Now);
        Assert.Equal("", result);
    }

    // --- GetCameraSummary: no data ---

    [Fact]
    public void GetCameraSummary_ReturnsEmpty_WhenNoAttentionData()
    {
        CreateDatabaseWithAttentionSessions();
        var service = CreateService();
        var result = service.GetCameraSummary(DateTime.Now.AddHours(-1), DateTime.Now);
        Assert.Equal("", result);
    }

    // --- GetCameraSummary: valid data ---

    [Fact]
    public void GetCameraSummary_ReturnsFormattedSummary()
    {
        CreateDatabaseWithAttentionSessions();
        InsertAttentionSession("2026-02-15 10:00:00", "2026-02-15 10:01:00",
            avgAttention: 0.75, faceRatio: 0.95, screenRatio: 0.85,
            emotion: "happy", blinkRate: 18.5, mindWandering: 2);

        var service = CreateService();
        var from = new DateTime(2026, 2, 15, 9, 0, 0);
        var to = new DateTime(2026, 2, 15, 11, 0, 0);

        var result = service.GetCameraSummary(from, to);

        Assert.StartsWith("[User State] ", result);
        Assert.Contains("happy", result);
        Assert.Contains("0.75", result);
        Assert.Contains("85%", result);
        Assert.Contains("2 mind-wandering", result);
        Assert.Contains("18/min", result); // 18.5 banker's rounds to 18
    }

    [Fact]
    public void GetCameraSummary_AggregatesMultipleSessions()
    {
        CreateDatabaseWithAttentionSessions();
        InsertAttentionSession("2026-02-15 10:00:00", "2026-02-15 10:01:00",
            avgAttention: 0.80, faceRatio: 0.9, screenRatio: 0.90,
            emotion: "happy", blinkRate: 16, mindWandering: 1);
        InsertAttentionSession("2026-02-15 10:01:00", "2026-02-15 10:02:00",
            avgAttention: 0.60, faceRatio: 0.8, screenRatio: 0.70,
            emotion: "neutral", blinkRate: 20, mindWandering: 3);

        var service = CreateService();
        var from = new DateTime(2026, 2, 15, 9, 0, 0);
        var to = new DateTime(2026, 2, 15, 11, 0, 0);

        var result = service.GetCameraSummary(from, to);

        // Average attention: (0.80 + 0.60) / 2 = 0.70
        Assert.Contains("0.70", result);
        // Average screen ratio: (0.90 + 0.70) / 2 = 0.80 = 80%
        Assert.Contains("80%", result);
        // Total mind wandering: 1 + 3 = 4
        Assert.Contains("4 mind-wandering", result);
    }

    [Fact]
    public void GetCameraSummary_FindsDominantEmotion()
    {
        CreateDatabaseWithAttentionSessions();
        InsertAttentionSession("2026-02-15 10:00:00", "2026-02-15 10:01:00",
            emotion: "sad");
        InsertAttentionSession("2026-02-15 10:01:00", "2026-02-15 10:02:00",
            emotion: "happy");
        InsertAttentionSession("2026-02-15 10:02:00", "2026-02-15 10:03:00",
            emotion: "happy");

        var service = CreateService();
        var from = new DateTime(2026, 2, 15, 9, 0, 0);
        var to = new DateTime(2026, 2, 15, 11, 0, 0);

        var result = service.GetCameraSummary(from, to);

        Assert.Contains("Dominant emotion: happy", result);
    }

    // --- GetCameraSummary: time filtering ---

    [Fact]
    public void GetCameraSummary_FiltersOutOfRange()
    {
        CreateDatabaseWithAttentionSessions();
        InsertAttentionSession("2026-02-15 10:30:00", "2026-02-15 10:31:00",
            emotion: "happy", avgAttention: 0.9);
        InsertAttentionSession("2026-02-15 08:00:00", "2026-02-15 08:01:00",
            emotion: "angry", avgAttention: 0.3);

        var service = CreateService();
        var from = new DateTime(2026, 2, 15, 10, 0, 0);
        var to = new DateTime(2026, 2, 15, 11, 0, 0);

        var result = service.GetCameraSummary(from, to);

        Assert.Contains("happy", result);
        Assert.DoesNotContain("angry", result);
    }

    // --- GetCameraSummary: missing table ---

    [Fact]
    public void GetCameraSummary_ReturnsEmpty_WhenNoAttentionTable()
    {
        // Create DB with only window_sessions, no attention_sessions
        CreateDatabase(withWindowSessions: true, withChromeSessions: false);

        var service = CreateService();
        var from = new DateTime(2026, 2, 15, 9, 0, 0);
        var to = new DateTime(2026, 2, 15, 11, 0, 0);

        var result = service.GetCameraSummary(from, to);

        Assert.Equal("", result);
    }

    // --- GetCameraSummary: no mind wandering ---

    [Fact]
    public void GetCameraSummary_OmitsMindWandering_WhenZero()
    {
        CreateDatabaseWithAttentionSessions();
        InsertAttentionSession("2026-02-15 10:00:00", "2026-02-15 10:01:00",
            avgAttention: 0.9, emotion: "neutral", mindWandering: 0);

        var service = CreateService();
        var from = new DateTime(2026, 2, 15, 9, 0, 0);
        var to = new DateTime(2026, 2, 15, 11, 0, 0);

        var result = service.GetCameraSummary(from, to);

        Assert.DoesNotContain("mind-wandering", result);
    }

    // --- GetCameraSummary: corrupt DB ---

    [Fact]
    public void GetCameraSummary_HandlesCorruptDb()
    {
        File.WriteAllText(_dbPath, "not a valid database");

        var service = CreateService();
        var from = new DateTime(2026, 2, 15, 9, 0, 0);
        var to = new DateTime(2026, 2, 15, 11, 0, 0);

        var result = service.GetCameraSummary(from, to);

        Assert.Equal("", result);
    }

    // --- GetCameraSummary: caps length ---

    [Fact]
    public void GetCameraSummary_CapsAt200Chars()
    {
        CreateDatabaseWithAttentionSessions();
        // Insert sessions with long emotion strings won't happen since we format,
        // but insert many to try to produce a longer result
        InsertAttentionSession("2026-02-15 10:00:00", "2026-02-15 10:01:00",
            avgAttention: 0.123456789, emotion: "verylongemotionname",
            blinkRate: 99.9, mindWandering: 999);

        var service = CreateService();
        var from = new DateTime(2026, 2, 15, 9, 0, 0);
        var to = new DateTime(2026, 2, 15, 11, 0, 0);

        var result = service.GetCameraSummary(from, to);

        Assert.True(result.Length <= 200, $"Result was {result.Length} chars, expected <= 200");
    }

    // --- ClassifyActivity: static method tests ---

    [Fact]
    public void ClassifyActivity_EmptyLists_ReturnsDefault()
    {
        var result = ActivityMonitorService.ClassifyActivity(
            new List<(string, double)>(), new List<(string, double)>());
        Assert.Equal(ActivityContext.Default, result);
    }

    [Fact]
    public void ClassifyActivity_GamingProcess_ReturnsGaming()
    {
        var processes = new List<(string, double)> { ("steam.exe", 60) };
        var domains = new List<(string, double)>();
        Assert.Equal(ActivityContext.Gaming,
            ActivityMonitorService.ClassifyActivity(processes, domains));
    }

    [Fact]
    public void ClassifyActivity_GamingDomain_ReturnsGaming()
    {
        var processes = new List<(string, double)>();
        var domains = new List<(string, double)> { ("store.steampowered.com", 45) };
        Assert.Equal(ActivityContext.Gaming,
            ActivityMonitorService.ClassifyActivity(processes, domains));
    }

    [Fact]
    public void ClassifyActivity_VideoDomain_ReturnsWatchingVideos()
    {
        var processes = new List<(string, double)>();
        var domains = new List<(string, double)> { ("youtube.com", 60) };
        Assert.Equal(ActivityContext.WatchingVideos,
            ActivityMonitorService.ClassifyActivity(processes, domains));
    }

    [Fact]
    public void ClassifyActivity_BilibiliDomain_ReturnsWatchingVideos()
    {
        var processes = new List<(string, double)>();
        var domains = new List<(string, double)> { ("bilibili.com", 60) };
        Assert.Equal(ActivityContext.WatchingVideos,
            ActivityMonitorService.ClassifyActivity(processes, domains));
    }

    [Fact]
    public void ClassifyActivity_StudyProcess_ReturnsStudyingCoding()
    {
        var processes = new List<(string, double)> { ("code.exe", 45) };
        var domains = new List<(string, double)>();
        Assert.Equal(ActivityContext.StudyingCoding,
            ActivityMonitorService.ClassifyActivity(processes, domains));
    }

    [Fact]
    public void ClassifyActivity_StudyDomain_ReturnsStudyingCoding()
    {
        var processes = new List<(string, double)>();
        var domains = new List<(string, double)> { ("github.com", 60) };
        Assert.Equal(ActivityContext.StudyingCoding,
            ActivityMonitorService.ClassifyActivity(processes, domains));
    }

    [Fact]
    public void ClassifyActivity_HighestScoreWins()
    {
        var processes = new List<(string, double)>
        {
            ("code.exe", 40),   // study: 40
            ("steam.exe", 100)  // gaming: 100
        };
        var domains = new List<(string, double)>
        {
            ("github.com", 20)  // study: +20 = 60 total
        };
        // gaming=100 > study=60 → Gaming
        Assert.Equal(ActivityContext.Gaming,
            ActivityMonitorService.ClassifyActivity(processes, domains));
    }

    [Fact]
    public void ClassifyActivity_BelowThreshold_ReturnsDefault()
    {
        var processes = new List<(string, double)> { ("steam.exe", 20) }; // < 30s threshold
        var domains = new List<(string, double)>();
        Assert.Equal(ActivityContext.Default,
            ActivityMonitorService.ClassifyActivity(processes, domains));
    }

    [Fact]
    public void ClassifyActivity_CombinedScores_AddUp()
    {
        // Study from both process and domain
        var processes = new List<(string, double)> { ("code.exe", 20) };
        var domains = new List<(string, double)> { ("github.com", 25) };
        // study = 20 + 25 = 45, above threshold
        Assert.Equal(ActivityContext.StudyingCoding,
            ActivityMonitorService.ClassifyActivity(processes, domains));
    }

    [Fact]
    public void ClassifyActivity_WutheringWaves_ReturnsGaming()
    {
        var processes = new List<(string, double)> { ("client-win64-shipping.exe", 60) };
        var domains = new List<(string, double)>();
        Assert.Equal(ActivityContext.Gaming,
            ActivityMonitorService.ClassifyActivity(processes, domains));
    }

    // --- DetectActivityContext: integration tests ---

    [Fact]
    public void DetectActivityContext_WhenDisabled_ReturnsDefault()
    {
        var service = CreateService(enabled: false);
        Assert.Equal(ActivityContext.Default, service.DetectActivityContext());
    }

    [Fact]
    public void DetectActivityContext_NoData_ReturnsDefault()
    {
        CreateDatabase();
        var service = CreateService();
        Assert.Equal(ActivityContext.Default, service.DetectActivityContext());
    }

    [Fact]
    public void DetectActivityContext_CachesResult()
    {
        CreateDatabase();
        var now = DateTime.Now;
        InsertWindowSession("steam.exe", "Game", now.ToString("yyyy-MM-dd HH:mm:ss"), 120);

        var service = CreateService();
        var first = service.DetectActivityContext();
        // Second call should use cache (same result, no error even if DB changes)
        var second = service.DetectActivityContext();
        Assert.Equal(first, second);
    }

    // --- Helper methods for attention_sessions ---

    private void CreateDatabaseWithAttentionSessions()
    {
        using var conn = new SqliteConnection($"Data Source={_dbPath}");
        conn.Open();
        using var cmd = conn.CreateCommand();
        cmd.CommandText = @"
            CREATE TABLE attention_sessions (
                id INTEGER PRIMARY KEY,
                start_time TEXT NOT NULL,
                end_time TEXT,
                avg_attention_score REAL,
                face_present_ratio REAL,
                looking_at_screen_ratio REAL,
                gaze_on_screen_ratio REAL,
                dominant_emotion TEXT,
                blink_rate_per_minute REAL,
                mind_wandering_events INTEGER
            )";
        cmd.ExecuteNonQuery();
    }

    private void InsertAttentionSession(string startTime, string endTime,
        double avgAttention = 0.5, double faceRatio = 0.9, double screenRatio = 0.8,
        string emotion = "neutral", double blinkRate = 15.0, int mindWandering = 0)
    {
        using var conn = new SqliteConnection($"Data Source={_dbPath}");
        conn.Open();
        using var cmd = conn.CreateCommand();
        cmd.CommandText = @"
            INSERT INTO attention_sessions
                (start_time, end_time, avg_attention_score, face_present_ratio,
                 looking_at_screen_ratio, dominant_emotion, blink_rate_per_minute,
                 mind_wandering_events)
            VALUES (@start, @end, @attention, @face, @screen, @emotion, @blink, @wander)";
        cmd.Parameters.AddWithValue("@start", startTime);
        cmd.Parameters.AddWithValue("@end", endTime);
        cmd.Parameters.AddWithValue("@attention", avgAttention);
        cmd.Parameters.AddWithValue("@face", faceRatio);
        cmd.Parameters.AddWithValue("@screen", screenRatio);
        cmd.Parameters.AddWithValue("@emotion", emotion);
        cmd.Parameters.AddWithValue("@blink", blinkRate);
        cmd.Parameters.AddWithValue("@wander", mindWandering);
        cmd.ExecuteNonQuery();
    }
}
