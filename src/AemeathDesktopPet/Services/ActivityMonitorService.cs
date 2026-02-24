using System.IO;
using System.Text;
using AemeathDesktopPet.Models;
using Microsoft.Data.Sqlite;

namespace AemeathDesktopPet.Services;

public class ActivityMonitorService
{
    private readonly Func<ActivityMonitorConfig> _getConfig;

    // Cache for DetectActivityContext
    private ActivityContext _cachedContext;
    private DateTime _cacheExpiry = DateTime.MinValue;

    public ActivityMonitorService(Func<ActivityMonitorConfig> getConfig)
    {
        _getConfig = getConfig;
    }

    public bool IsAvailable
    {
        get
        {
            var cfg = _getConfig();
            return cfg.Enabled && File.Exists(cfg.DatabasePath);
        }
    }

    public string GetActivitySummary(DateTime from, DateTime to)
    {
        if (!IsAvailable) return "";

        try
        {
            var dbPath = _getConfig().DatabasePath;
            var connStr = new SqliteConnectionStringBuilder
            {
                DataSource = dbPath,
                Mode = SqliteOpenMode.ReadOnly
            }.ToString();

            using var conn = new SqliteConnection(connStr);
            conn.Open();

            var entries = new List<(string label, double seconds)>();

            // Query window_sessions
            QueryWindowSessions(conn, from, to, entries);

            // Query chrome_sessions
            QueryChromeSessions(conn, from, to, entries);

            if (entries.Count == 0) return "";

            // Group by label and sum duration
            var grouped = entries
                .GroupBy(e => e.label)
                .Select(g => (label: g.Key, totalSeconds: g.Sum(x => x.seconds)))
                .OrderByDescending(g => g.totalSeconds)
                .Take(5)
                .ToList();

            var sb = new StringBuilder("[Recent Activity] ");
            for (int i = 0; i < grouped.Count; i++)
            {
                var (label, totalSeconds) = grouped[i];
                int mins = (int)Math.Round(totalSeconds / 60.0);
                if (mins < 1) mins = 1;

                if (i > 0) sb.Append(", ");
                sb.Append($"{mins} min in {label}");
            }
            sb.Append('.');

            // Cap at ~250 chars to keep prompts lean
            var result = sb.ToString();
            if (result.Length > 250)
                result = result[..247] + "...";

            return result;
        }
        catch
        {
            return "";
        }
    }

    private static void QueryWindowSessions(SqliteConnection conn, DateTime from, DateTime to,
        List<(string label, double seconds)> entries)
    {
        try
        {
            var fromStr = from.ToString("yyyy-MM-dd HH:mm:ss");
            var toStr = to.ToString("yyyy-MM-dd HH:mm:ss");

            using var cmd = conn.CreateCommand();
            cmd.CommandText = @"
                SELECT process_name, window_title, duration_seconds
                FROM window_sessions
                WHERE start_time >= @from AND start_time <= @to
                  AND duration_seconds > 0
                ORDER BY duration_seconds DESC
                LIMIT 20";
            cmd.Parameters.AddWithValue("@from", fromStr);
            cmd.Parameters.AddWithValue("@to", toStr);

            using var reader = cmd.ExecuteReader();
            while (reader.Read())
            {
                var process = reader.GetString(0);
                var title = reader.IsDBNull(1) ? "" : reader.GetString(1);
                var duration = reader.GetDouble(2);

                // Build a readable label
                var label = FormatWindowLabel(process, title);
                entries.Add((label, duration));
            }
        }
        catch
        {
            // Table may not exist — skip silently
        }
    }

    private static void QueryChromeSessions(SqliteConnection conn, DateTime from, DateTime to,
        List<(string label, double seconds)> entries)
    {
        try
        {
            var fromStr = from.ToString("yyyy-MM-dd HH:mm:ss");
            var toStr = to.ToString("yyyy-MM-dd HH:mm:ss");

            using var cmd = conn.CreateCommand();
            cmd.CommandText = @"
                SELECT domain, page_title, duration_seconds
                FROM chrome_sessions
                WHERE start_time >= @from AND start_time <= @to
                  AND duration_seconds > 0
                ORDER BY duration_seconds DESC
                LIMIT 20";
            cmd.Parameters.AddWithValue("@from", fromStr);
            cmd.Parameters.AddWithValue("@to", toStr);

            using var reader = cmd.ExecuteReader();
            while (reader.Read())
            {
                var domain = reader.IsDBNull(0) ? "" : reader.GetString(0);
                var title = reader.IsDBNull(1) ? "" : reader.GetString(1);
                var duration = reader.GetDouble(2);

                var label = FormatChromeLabel(domain, title);
                entries.Add((label, duration));
            }
        }
        catch
        {
            // Table may not exist — skip silently
        }
    }

    public string GetCameraSummary(DateTime from, DateTime to)
    {
        if (!IsAvailable) return "";

        try
        {
            var dbPath = _getConfig().DatabasePath;
            var connStr = new SqliteConnectionStringBuilder
            {
                DataSource = dbPath,
                Mode = SqliteOpenMode.ReadOnly
            }.ToString();

            using var conn = new SqliteConnection(connStr);
            conn.Open();

            return QueryAttentionSessions(conn, from, to);
        }
        catch
        {
            return "";
        }
    }

    private static string QueryAttentionSessions(SqliteConnection conn, DateTime from, DateTime to)
    {
        try
        {
            var fromStr = from.ToString("yyyy-MM-dd HH:mm:ss");
            var toStr = to.ToString("yyyy-MM-dd HH:mm:ss");

            using var cmd = conn.CreateCommand();
            cmd.CommandText = @"
                SELECT avg_attention_score, face_present_ratio, looking_at_screen_ratio,
                       dominant_emotion, blink_rate_per_minute, mind_wandering_events
                FROM attention_sessions
                WHERE start_time >= @from AND start_time <= @to
                ORDER BY start_time DESC
                LIMIT 10";
            cmd.Parameters.AddWithValue("@from", fromStr);
            cmd.Parameters.AddWithValue("@to", toStr);

            using var reader = cmd.ExecuteReader();

            var emotions = new Dictionary<string, int>(StringComparer.OrdinalIgnoreCase);
            double totalAttention = 0;
            double totalScreenRatio = 0;
            double totalBlinkRate = 0;
            int totalMindWandering = 0;
            int count = 0;

            while (reader.Read())
            {
                count++;
                totalAttention += reader.IsDBNull(0) ? 0 : reader.GetDouble(0);
                totalScreenRatio += reader.IsDBNull(2) ? 0 : reader.GetDouble(2);

                var emotion = reader.IsDBNull(3) ? "unknown" : reader.GetString(3);
                if (!string.IsNullOrWhiteSpace(emotion))
                {
                    emotions.TryGetValue(emotion, out int eCnt);
                    emotions[emotion] = eCnt + 1;
                }

                totalBlinkRate += reader.IsDBNull(4) ? 0 : reader.GetDouble(4);
                totalMindWandering += reader.IsDBNull(5) ? 0 : (int)reader.GetDouble(5);
            }

            if (count == 0) return "";

            var avgAttention = totalAttention / count;
            var avgScreenRatio = totalScreenRatio / count;
            var avgBlinkRate = totalBlinkRate / count;

            // Find dominant emotion
            var dominantEmotion = "unknown";
            int maxEmotionCount = 0;
            foreach (var kvp in emotions)
            {
                if (kvp.Value > maxEmotionCount)
                {
                    maxEmotionCount = kvp.Value;
                    dominantEmotion = kvp.Key;
                }
            }

            var sb = new StringBuilder("[User State] ");
            sb.Append($"Dominant emotion: {dominantEmotion}. ");
            sb.Append($"Attention: {avgAttention:F2}. ");
            sb.Append($"Looking at screen: {avgScreenRatio * 100:F0}%. ");
            if (totalMindWandering > 0)
                sb.Append($"{totalMindWandering} mind-wandering events. ");
            sb.Append($"Blink rate: {avgBlinkRate:F0}/min.");

            var result = sb.ToString();
            if (result.Length > 200)
                result = result[..197] + "...";

            return result;
        }
        catch
        {
            // Table may not exist — skip silently
            return "";
        }
    }

    // --- Activity Context Detection ---

    private static readonly HashSet<string> GamingProcesses = new(StringComparer.OrdinalIgnoreCase)
    {
        "steam.exe", "steamwebhelper.exe", "epicgameslauncher.exe",
        "genshinimpact.exe", "yuanshen.exe", "wuthering waves.exe",
        "client-win64-shipping.exe", "valorant.exe", "cs2.exe",
        "league of legends.exe", "overwatch.exe", "minecraft.exe",
        "riotclientservices.exe", "gog galaxy.exe"
    };

    private static readonly HashSet<string> GamingDomains = new(StringComparer.OrdinalIgnoreCase)
    {
        "store.steampowered.com", "epicgames.com"
    };

    private static readonly HashSet<string> VideoDomains = new(StringComparer.OrdinalIgnoreCase)
    {
        "youtube.com", "www.youtube.com", "twitch.tv", "www.twitch.tv",
        "bilibili.com", "www.bilibili.com", "netflix.com", "www.netflix.com",
        "iqiyi.com", "www.iqiyi.com", "v.qq.com",
        "disneyplus.com", "www.disneyplus.com",
        "crunchyroll.com", "www.crunchyroll.com"
    };

    private static readonly HashSet<string> StudyProcesses = new(StringComparer.OrdinalIgnoreCase)
    {
        "code.exe", "devenv.exe", "idea64.exe", "pycharm64.exe",
        "webstorm64.exe", "rider64.exe", "obsidian.exe", "anki.exe",
        "notion.exe", "onenote.exe"
    };

    private static readonly HashSet<string> StudyDomains = new(StringComparer.OrdinalIgnoreCase)
    {
        "github.com", "stackoverflow.com", "leetcode.com",
        "coursera.org", "www.coursera.org",
        "learn.microsoft.com", "docs.google.com",
        "kaggle.com", "www.kaggle.com",
        "developer.mozilla.org"
    };

    public ActivityContext DetectActivityContext()
    {
        if (!IsAvailable) return ActivityContext.Default;

        var now = DateTime.Now;
        if (now < _cacheExpiry) return _cachedContext;

        try
        {
            var dbPath = _getConfig().DatabasePath;
            var connStr = new SqliteConnectionStringBuilder
            {
                DataSource = dbPath,
                Mode = SqliteOpenMode.ReadOnly
            }.ToString();

            using var conn = new SqliteConnection(connStr);
            conn.Open();

            var from = now.AddMinutes(-3);
            var processes = new List<(string name, double seconds)>();
            var domains = new List<(string name, double seconds)>();

            QueryProcessSummary(conn, from, now, processes);
            QueryDomainSummary(conn, from, now, domains);

            _cachedContext = ClassifyActivity(processes, domains);
        }
        catch
        {
            _cachedContext = ActivityContext.Default;
        }

        _cacheExpiry = now.AddSeconds(30);
        return _cachedContext;
    }

    private static void QueryProcessSummary(SqliteConnection conn, DateTime from, DateTime to,
        List<(string name, double seconds)> results)
    {
        try
        {
            using var cmd = conn.CreateCommand();
            cmd.CommandText = @"
                SELECT process_name, SUM(duration_seconds)
                FROM window_sessions
                WHERE start_time >= @from AND start_time <= @to
                  AND duration_seconds > 0
                GROUP BY process_name
                ORDER BY SUM(duration_seconds) DESC
                LIMIT 10";
            cmd.Parameters.AddWithValue("@from", from.ToString("yyyy-MM-dd HH:mm:ss"));
            cmd.Parameters.AddWithValue("@to", to.ToString("yyyy-MM-dd HH:mm:ss"));

            using var reader = cmd.ExecuteReader();
            while (reader.Read())
            {
                var name = reader.GetString(0);
                var secs = reader.GetDouble(1);
                results.Add((name, secs));
            }
        }
        catch { }
    }

    private static void QueryDomainSummary(SqliteConnection conn, DateTime from, DateTime to,
        List<(string name, double seconds)> results)
    {
        try
        {
            using var cmd = conn.CreateCommand();
            cmd.CommandText = @"
                SELECT domain, SUM(duration_seconds)
                FROM chrome_sessions
                WHERE start_time >= @from AND start_time <= @to
                  AND duration_seconds > 0
                  AND domain IS NOT NULL AND domain != ''
                GROUP BY domain
                ORDER BY SUM(duration_seconds) DESC
                LIMIT 10";
            cmd.Parameters.AddWithValue("@from", from.ToString("yyyy-MM-dd HH:mm:ss"));
            cmd.Parameters.AddWithValue("@to", to.ToString("yyyy-MM-dd HH:mm:ss"));

            using var reader = cmd.ExecuteReader();
            while (reader.Read())
            {
                var name = reader.GetString(0);
                var secs = reader.GetDouble(1);
                results.Add((name, secs));
            }
        }
        catch { }
    }

    internal static ActivityContext ClassifyActivity(
        List<(string name, double seconds)> processes,
        List<(string name, double seconds)> domains)
    {
        double gamingScore = 0, videoScore = 0, studyScore = 0;

        foreach (var (name, secs) in processes)
        {
            if (GamingProcesses.Contains(name)) gamingScore += secs;
            if (StudyProcesses.Contains(name)) studyScore += secs;
        }

        foreach (var (name, secs) in domains)
        {
            if (GamingDomains.Contains(name)) gamingScore += secs;
            if (VideoDomains.Contains(name)) videoScore += secs;
            if (StudyDomains.Contains(name)) studyScore += secs;
        }

        const double threshold = 30;

        // Pick highest above threshold
        double maxScore = Math.Max(gamingScore, Math.Max(videoScore, studyScore));
        if (maxScore < threshold) return ActivityContext.Default;

        if (gamingScore == maxScore) return ActivityContext.Gaming;
        if (videoScore == maxScore) return ActivityContext.WatchingVideos;
        return ActivityContext.StudyingCoding;
    }

    private static string FormatWindowLabel(string process, string title)
    {
        // Strip .exe extension
        var app = process.Replace(".exe", "", StringComparison.OrdinalIgnoreCase).Trim();

        if (string.IsNullOrWhiteSpace(title) || title.Length < 3)
            return $"\"{app}\"";

        // Truncate long titles
        if (title.Length > 40)
            title = title[..37] + "...";

        return $"\"{app} - {title}\"";
    }

    private static string FormatChromeLabel(string domain, string title)
    {
        if (string.IsNullOrWhiteSpace(domain))
            return "Chrome";

        if (string.IsNullOrWhiteSpace(title) || title.Length < 3)
            return $"Chrome on {domain}";

        if (title.Length > 35)
            title = title[..32] + "...";

        return $"{domain} (\"{title}\")";
    }
}
