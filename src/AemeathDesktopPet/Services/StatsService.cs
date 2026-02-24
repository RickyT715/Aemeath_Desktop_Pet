using System.Windows.Threading;
using AemeathDesktopPet.Models;

namespace AemeathDesktopPet.Services;

/// <summary>
/// Manages Aemeath's stats: loading, saving, offline decay, interaction effects, periodic energy drain.
/// </summary>
public class StatsService
{
    private readonly JsonPersistenceService _persistence;
    private readonly DispatcherTimer _decayTimer;

    public AemeathStats Stats { get; private set; } = new();

    public event Action? StatsChanged;

    public StatsService(JsonPersistenceService persistence)
    {
        _persistence = persistence;

        _decayTimer = new DispatcherTimer(DispatcherPriority.Background)
        {
            Interval = TimeSpan.FromMinutes(5)
        };
        _decayTimer.Tick += OnDecayTick;
    }

    /// <summary>
    /// Loads stats from disk and applies offline decay.
    /// </summary>
    public void Load()
    {
        Stats = _persistence.LoadStats() ?? new AemeathStats();
        Stats.ApplyOfflineDecay(Stats.LastSeen);
        Stats.Clamp();
        StatsChanged?.Invoke();
    }

    public void Save()
    {
        Stats.LastSeen = DateTime.UtcNow;
        _persistence.SaveStats(Stats);
    }

    public void Start()
    {
        _decayTimer.Start();
    }

    public void Stop()
    {
        _decayTimer.Stop();
        Save();
    }

    // --- Interaction effects ---

    public void OnChatted()
    {
        Stats.Adjust(StatType.Mood, 3);
        Stats.Adjust(StatType.Affection, 2);
        Stats.TotalChats++;
        StatsChanged?.Invoke();
    }

    public void OnPetted()
    {
        Stats.Adjust(StatType.Mood, 5);
        Stats.Adjust(StatType.Affection, 3);
        Stats.TotalPets++;
        StatsChanged?.Invoke();
    }

    public void OnSang()
    {
        Stats.Adjust(StatType.Mood, 8);
        Stats.Adjust(StatType.Energy, -5);
        Stats.TotalSongs++;
        StatsChanged?.Invoke();
    }

    public void OnPaperPlaneThrown()
    {
        Stats.Adjust(StatType.Mood, 2);
        Stats.Adjust(StatType.Energy, -2);
        Stats.TotalPaperPlanes++;
        StatsChanged?.Invoke();
    }

    public void OnGamePlayed()
    {
        Stats.Adjust(StatType.Mood, 6);
        Stats.Adjust(StatType.Energy, -8);
        Stats.TotalGames++;
        StatsChanged?.Invoke();
    }

    // --- Periodic energy decay ---

    private void OnDecayTick(object? sender, EventArgs e)
    {
        // -1 energy every 5 minutes of active use
        Stats.Adjust(StatType.Energy, -1);
        // slight mood drift toward 50
        if (Stats.Mood > 55)
            Stats.Adjust(StatType.Mood, -0.5);
        else if (Stats.Mood < 45)
            Stats.Adjust(StatType.Mood, 0.5);

        StatsChanged?.Invoke();
    }
}
