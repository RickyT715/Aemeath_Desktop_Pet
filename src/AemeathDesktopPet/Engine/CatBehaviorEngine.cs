using System.Windows.Threading;
using AemeathDesktopPet.Models;

namespace AemeathDesktopPet.Engine;

/// <summary>
/// Independent FSM for the black cat companion.
/// Follows Aemeath with offset and delay, reacts to events.
/// </summary>
public class CatBehaviorEngine
{
    private static readonly Random _rng = new();

    private readonly DispatcherTimer _behaviorTimer;
    private CatState _currentState = CatState.CatIdle;
    private DateTime _stateEnteredAt = DateTime.UtcNow;
    private double _stateDuration = 5;

    // Cat position (independent from Aemeath)
    public double CatX { get; set; }
    public double CatY { get; set; }

    // Target position to follow Aemeath
    private double _targetX;
    private double _targetY;
    private double _followOffsetX;
    private double _followOffsetY;

    public CatState CurrentState => _currentState;

    public event Action<CatState>? StateChanged;
    public event Action? PositionChanged;

    /// <summary>
    /// Maps cat states to placeholder animation GIF names.
    /// </summary>
    private static readonly Dictionary<CatState, string> CatAnimations = new()
    {
        [CatState.CatIdle] = "cat_idle",
        [CatState.CatWalk] = "cat_walk",
        [CatState.CatNap] = "cat_nap",
        [CatState.CatGroom] = "cat_groom",
        [CatState.CatPounce] = "cat_pounce",
        [CatState.CatWatch] = "cat_watch",
        [CatState.CatRub] = "cat_rub",
        [CatState.CatStartled] = "cat_startled",
        [CatState.CatPurr] = "cat_purr",
        [CatState.CatPerch] = "cat_perch",
        [CatState.CatChase] = "cat_chase",
        [CatState.CatBat] = "cat_bat",
    };

    /// <summary>
    /// Weighted idle transitions for the cat.
    /// </summary>
    private static readonly (CatState state, int weight, double minDur, double maxDur)[] IdleTransitions =
    {
        (CatState.CatIdle,   15, 3.0, 8.0),
        (CatState.CatWalk,   12, 2.0, 5.0),
        (CatState.CatGroom,   8, 4.0, 8.0),
        (CatState.CatNap,     5, 8.0, 20.0),
    };

    public CatBehaviorEngine()
    {
        _followOffsetX = RandomRange(40, 80) * (_rng.NextDouble() < 0.5 ? -1 : 1);
        _followOffsetY = RandomRange(10, 30);

        _behaviorTimer = new DispatcherTimer(DispatcherPriority.Background)
        {
            Interval = TimeSpan.FromSeconds(1)
        };
        _behaviorTimer.Tick += OnBehaviorTick;
    }

    public void Start()
    {
        _stateEnteredAt = DateTime.UtcNow;
        TransitionTo(CatState.CatIdle);
        _behaviorTimer.Start();
    }

    public void Stop()
    {
        _behaviorTimer.Stop();
    }

    public static string GetAnimation(CatState state)
    {
        return CatAnimations.GetValueOrDefault(state, "cat_idle");
    }

    // --- Reactive methods ---

    public void OnAemeathMoved(double aemeathX, double aemeathY)
    {
        _targetX = aemeathX + _followOffsetX;
        _targetY = aemeathY + _followOffsetY;

        // Smooth follow (lerp toward target)
        if (_currentState is not CatState.CatNap and not CatState.CatPounce)
        {
            double lerp = 0.03; // slow follow (0.3-0.5s delay feel)
            CatX += (_targetX - CatX) * lerp;
            CatY += (_targetY - CatY) * lerp;
            PositionChanged?.Invoke();
        }
    }

    public void OnAemeathDragged()
    {
        if (_currentState == CatState.CatNap)
            return;
        TransitionTo(CatState.CatWatch, 3.0);
    }

    public void OnAemeathLanded()
    {
        TransitionTo(CatState.CatRub, 2.0);
    }

    public void OnAemeathGlitched()
    {
        TransitionTo(CatState.CatStartled, 1.5);
    }

    public void OnPaperPlaneLanded(double planeX)
    {
        _targetX = planeX;
        TransitionTo(CatState.CatChase, 3.0);
    }

    public void OnUserClickedCat()
    {
        TransitionTo(CatState.CatPurr, 3.0);
    }

    // --- Internal ---

    private void OnBehaviorTick(object? sender, EventArgs e)
    {
        var elapsed = (DateTime.UtcNow - _stateEnteredAt).TotalSeconds;

        // Don't auto-transition during reactive states
        if (_currentState is CatState.CatWatch or CatState.CatStartled
            or CatState.CatChase or CatState.CatRub or CatState.CatPurr)
        {
            if (elapsed >= _stateDuration)
                TransitionTo(CatState.CatIdle);
            return;
        }

        if (elapsed < _stateDuration)
            return;

        PickNextState();
    }

    private void PickNextState()
    {
        int totalWeight = 0;
        foreach (var (_, weight, _, _) in IdleTransitions)
            totalWeight += weight;

        int roll = _rng.Next(totalWeight);
        int cumulative = 0;

        foreach (var (state, weight, minDur, maxDur) in IdleTransitions)
        {
            cumulative += weight;
            if (roll < cumulative)
            {
                TransitionTo(state, RandomRange(minDur, maxDur));
                return;
            }
        }

        TransitionTo(CatState.CatIdle);
    }

    private void TransitionTo(CatState newState, double? duration = null)
    {
        _currentState = newState;
        _stateEnteredAt = DateTime.UtcNow;
        _stateDuration = duration ?? RandomRange(4, 10);
        StateChanged?.Invoke(newState);
    }

    private static double RandomRange(double min, double max)
    {
        return min + _rng.NextDouble() * (max - min);
    }
}
