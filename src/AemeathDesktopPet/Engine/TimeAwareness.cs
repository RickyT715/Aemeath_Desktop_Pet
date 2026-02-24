namespace AemeathDesktopPet.Engine;

/// <summary>
/// Utility for time-of-day awareness. Used by BehaviorEngine for conditional transitions.
/// </summary>
public static class TimeAwareness
{
    public enum TimePeriod
    {
        Morning,    // 6:00 - 11:59
        Day,        // 12:00 - 16:59
        Evening,    // 17:00 - 20:59
        Night,      // 21:00 - 23:59
        LateNight,  // 0:00 - 5:59
    }

    public static TimePeriod GetCurrentPeriod()
    {
        return GetPeriod(DateTime.Now.Hour);
    }

    public static TimePeriod GetPeriod(int hour)
    {
        return hour switch
        {
            >= 6 and < 12 => TimePeriod.Morning,
            >= 12 and < 17 => TimePeriod.Day,
            >= 17 and < 21 => TimePeriod.Evening,
            >= 21 and < 24 => TimePeriod.Night,
            _ => TimePeriod.LateNight,
        };
    }

    /// <summary>
    /// Whether Aemeath should consider sleeping based on time + energy.
    /// </summary>
    public static bool ShouldSleep(double energy)
    {
        var period = GetCurrentPeriod();
        return period is TimePeriod.LateNight || (period is TimePeriod.Night && energy < 30);
    }

    /// <summary>
    /// Whether it's a good time for a greeting (morning or return after absence).
    /// </summary>
    public static bool ShouldGreet()
    {
        return GetCurrentPeriod() == TimePeriod.Morning;
    }
}
