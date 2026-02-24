namespace AemeathDesktopPet.Models;

/// <summary>
/// Tracks Aemeath's mood, energy, and affection levels plus lifetime counters.
/// </summary>
public class AemeathStats
{
    // Core stats (0-100)
    public double Mood { get; set; } = 70;
    public double Energy { get; set; } = 80;
    public double Affection { get; set; } = 50;

    // Lifetime counters
    public DateTime FirstLaunch { get; set; } = DateTime.UtcNow;
    public DateTime LastSeen { get; set; } = DateTime.UtcNow;
    public int TotalChats { get; set; }
    public int TotalPets { get; set; }
    public int TotalSongs { get; set; }
    public int TotalPaperPlanes { get; set; }
    public int TotalGames { get; set; }

    /// <summary>
    /// Days the user has had Aemeath.
    /// </summary>
    public int DaysTogether => Math.Max(1, (int)(DateTime.UtcNow - FirstLaunch).TotalDays);

    /// <summary>
    /// Applies offline decay since the last session with diminishing returns and floor values.
    /// Decay rates per hour (from design doc Section 3.2.3):
    ///   Mood:      -5/hr first 4hrs, then -2/hr, floor 30
    ///   Energy:    -3/hr first 6hrs, then -1/hr, floor 20
    ///   Affection: -1/hr first 12hrs, then -0.5/hr, floor 40
    /// </summary>
    public void ApplyOfflineDecay(DateTime lastSeen)
    {
        double hoursAway = Math.Max(0, (DateTime.UtcNow - lastSeen).TotalHours);
        if (hoursAway < 0.1) return; // less than 6 minutes, skip

        Mood = ApplyDecay(Mood, hoursAway, fastRate: 5, slowRate: 2, fastHours: 4, floor: 30);
        Energy = ApplyDecay(Energy, hoursAway, fastRate: 3, slowRate: 1, fastHours: 6, floor: 20);
        Affection = ApplyDecay(Affection, hoursAway, fastRate: 1, slowRate: 0.5, fastHours: 12, floor: 40);
    }

    private static double ApplyDecay(double value, double hours, double fastRate, double slowRate, double fastHours, double floor)
    {
        double decay;
        if (hours <= fastHours)
        {
            decay = hours * fastRate;
        }
        else
        {
            decay = fastHours * fastRate + (hours - fastHours) * slowRate;
        }

        return Math.Max(floor, value - decay);
    }

    /// <summary>
    /// Clamps all stats to valid 0-100 range.
    /// </summary>
    public void Clamp()
    {
        Mood = Math.Clamp(Mood, 0, 100);
        Energy = Math.Clamp(Energy, 0, 100);
        Affection = Math.Clamp(Affection, 0, 100);
    }

    /// <summary>
    /// Adjusts a stat by the given delta, clamping to 0-100.
    /// </summary>
    public void Adjust(StatType stat, double delta)
    {
        switch (stat)
        {
            case StatType.Mood:
                Mood = Math.Clamp(Mood + delta, 0, 100);
                break;
            case StatType.Energy:
                Energy = Math.Clamp(Energy + delta, 0, 100);
                break;
            case StatType.Affection:
                Affection = Math.Clamp(Affection + delta, 0, 100);
                break;
        }
    }
}

public enum StatType
{
    Mood,
    Energy,
    Affection
}
