using System.Windows.Threading;
using AemeathDesktopPet.Models;

namespace AemeathDesktopPet.Engine;

/// <summary>
/// FSM with weighted-random behavior selection for Aemeath.
/// Drives state transitions and animation changes.
/// Stats-aware conditional weights for dynamic behavior.
/// </summary>
public class BehaviorEngine
{
    private static readonly Random _rng = new();

    private readonly DispatcherTimer _behaviorTimer;
    internal PetState _currentState = PetState.Idle;
    private PetState _previousState = PetState.Idle;
    internal DateTime _stateEnteredAt = DateTime.UtcNow;
    internal double _stateDuration; // seconds before auto-transition

    // Stats context for conditional weights
    private double _mood = 60;
    private double _energy = 70;

    public event Action<PetState, AnimationInfo>? StateChanged;

    public PetState CurrentState => _currentState;
    public PetState PreviousState => _previousState;

    /// <summary>
    /// When true, Sing weight is forced to 0 in idle transitions.
    /// Set by PetWindow based on pomodoro work mode or missing music folder.
    /// </summary>
    public bool SuppressSinging { get; set; }

    /// <summary>
    /// Maps every state to its animation. States without custom art use best-fit placeholders.
    /// </summary>
    private static readonly Dictionary<PetState, AnimationInfo> StateAnimations = new()
    {
        // Core states (Phase 1)
        [PetState.Idle]          = new("normal", Loop: true),
        [PetState.FlyRight]      = new("normal_flying", Loop: true),
        [PetState.FlyLeft]       = new("normal_flying", Loop: true, Mirror: true),
        [PetState.Fall]          = new("normal", Loop: true),
        [PetState.Drag]          = new("normal", Loop: true),
        [PetState.Thrown]        = new("normal", Loop: true),
        [PetState.Landing]       = new("happy_jumping", Loop: false),
        [PetState.Wave]          = new("happy_hand_waving", Loop: false),
        [PetState.Laugh]         = new("laugh", Loop: true),
        [PetState.Sigh]          = new("sign", Loop: true),
        [PetState.PetHappy]      = new("happy_jumping", Loop: false),

        // Personality states (Phase 4)
        [PetState.Sing]          = new("listening_music", Loop: true, Fps: 25),
        [PetState.PlayGame]      = new("normal", Loop: true),          // placeholder
        [PetState.PaperPlane]    = new("happy_hand_waving", Loop: false), // one-shot throw
        [PetState.Glitch]        = new("normal", Loop: true),          // glitch overlay handles visuals
        [PetState.Sleep]         = new("sign", Loop: true),            // closest to drowsy
        [PetState.LookAtUser]    = new("normal", Loop: true),          // placeholder
        [PetState.Chat]          = new("laugh", Loop: true),           // mouth movement
        [PetState.CatLap]        = new("normal", Loop: true),          // placeholder
        [PetState.PetCat]        = new("happy_jumping", Loop: false),  // one-shot

        // Window edge states (Phase 2b)
        [PetState.PeekEdge]      = new("normal", Loop: true),          // position-based
        [PetState.LieOnWindow]   = new("normal", Loop: true),          // position-based
        [PetState.HideTaskbar]   = new("normal", Loop: true),          // position-based
        [PetState.ClingEdge]     = new("normal", Loop: true),          // position-based

        // Voice & screen states (Phase 5b/5c)
        [PetState.Speaking]      = new("laugh", Loop: true),           // mouth movement
        [PetState.ScreenComment] = new("laugh", Loop: true),           // mouth movement
    };

    /// <summary>
    /// Base idle transition table with weights from design doc.
    /// Weights are dynamically adjusted by SetStatsContext().
    /// </summary>
    private readonly List<(PetState state, int baseWeight, double minDuration, double maxDuration)> _idleTransitions = new()
    {
        (PetState.FlyRight,   15, 3.0,  8.0),
        (PetState.FlyLeft,    15, 3.0,  8.0),
        (PetState.Sing,        5, 5.0, 15.0),
        (PetState.Laugh,       5, 2.0,  4.0),
        (PetState.Sigh,        3, 3.0,  6.0),
        (PetState.PlayGame,    4, 5.0, 12.0),
        (PetState.PaperPlane,  3, 1.5,  2.0),
        (PetState.LookAtUser,  2, 3.0,  6.0),
        (PetState.PetCat,      2, 1.5,  2.0),
        (PetState.Sleep,       1, 8.0, 20.0),
        (PetState.Idle,       10, 4.0, 10.0),
    };

    /// <summary>
    /// States that should NOT auto-transition (user-driven or long-duration).
    /// </summary>
    private static readonly HashSet<PetState> NoAutoTransition = new()
    {
        PetState.Drag,
        PetState.Thrown,
        PetState.Fall,
        PetState.Chat,
        PetState.Sleep,
        PetState.PlayGame,
        PetState.Speaking,
        PetState.ScreenComment,
    };

    public BehaviorEngine()
    {
        _behaviorTimer = new DispatcherTimer(DispatcherPriority.Background)
        {
            Interval = TimeSpan.FromSeconds(1)
        };
        _behaviorTimer.Tick += OnBehaviorTick;
    }

    public void Start()
    {
        _stateDuration = RandomRange(3.0, 6.0);
        _stateEnteredAt = DateTime.UtcNow;
        TransitionTo(PetState.Idle);
        _behaviorTimer.Start();
    }

    public void Stop()
    {
        _behaviorTimer.Stop();
    }

    /// <summary>
    /// Update stats context for dynamic weight adjustment.
    /// </summary>
    public void SetStatsContext(double mood, double energy)
    {
        _mood = mood;
        _energy = energy;
    }

    /// <summary>
    /// Force a state transition (e.g., from user input like click or drag).
    /// </summary>
    public void ForceState(PetState newState, double? duration = null)
    {
        TransitionTo(newState, duration);
    }

    /// <summary>
    /// Returns to the previous state (used after one-shot reactions like Wave).
    /// </summary>
    public void ReturnToPrevious()
    {
        TransitionTo(_previousState);
    }

    /// <summary>
    /// Gets the animation info for a given state. Returns idle animation as fallback.
    /// </summary>
    public static AnimationInfo GetAnimation(PetState state)
    {
        return StateAnimations.GetValueOrDefault(state, StateAnimations[PetState.Idle]);
    }

    private void OnBehaviorTick(object? sender, EventArgs e)
    {
        SimulateBehaviorTick();
    }

    /// <summary>
    /// Runs one behavior tick. Exposed for testing.
    /// </summary>
    internal void SimulateBehaviorTick()
    {
        var elapsed = (DateTime.UtcNow - _stateEnteredAt).TotalSeconds;

        // Don't auto-transition during user-driven states
        if (NoAutoTransition.Contains(_currentState))
            return;

        // Check if current state has expired
        if (elapsed < _stateDuration)
            return;

        // Pick a new random state based on weights
        PickNextIdleState();
    }

    private void PickNextIdleState()
    {
        // Build adjusted weights based on stats
        var adjustedTransitions = new List<(PetState state, int weight, double minDur, double maxDur)>();

        foreach (var (state, baseWeight, minDur, maxDur) in _idleTransitions)
        {
            int weight = baseWeight;

            // Conditional adjustments
            switch (state)
            {
                case PetState.Sleep:
                    // Only sleep at night or when very low energy
                    if (!TimeAwareness.ShouldSleep(_energy))
                        weight = 0;
                    else
                        weight = _energy < 30 ? 5 : 2;
                    break;

                case PetState.Sigh:
                    // Higher when mood is low
                    if (_mood < 50) weight = (int)(baseWeight * 2);
                    if (_mood > 70) weight = 1;
                    break;

                case PetState.Laugh:
                    // Higher when mood is high
                    if (_mood > 70) weight = (int)(baseWeight * 1.5);
                    if (_mood < 30) weight = 1;
                    break;

                case PetState.PlayGame:
                    // Needs energy
                    if (_energy < 20) weight = 0;
                    break;

                case PetState.Sing:
                    // Needs some energy and decent mood
                    if (_energy < 15 || _mood < 20) weight = 0;
                    // Suppress during pomodoro work or when no music folder
                    if (SuppressSinging) weight = 0;
                    break;
            }

            if (weight > 0)
                adjustedTransitions.Add((state, weight, minDur, maxDur));
        }

        // Weighted random selection
        int totalWeight = 0;
        foreach (var (_, weight, _, _) in adjustedTransitions)
            totalWeight += weight;

        if (totalWeight == 0)
        {
            TransitionTo(PetState.Idle);
            return;
        }

        int roll = _rng.Next(totalWeight);
        int cumulative = 0;

        foreach (var (state, weight, minDur, maxDur) in adjustedTransitions)
        {
            cumulative += weight;
            if (roll < cumulative)
            {
                TransitionTo(state, RandomRange(minDur, maxDur));
                return;
            }
        }

        // Fallback
        TransitionTo(PetState.Idle);
    }

    private void TransitionTo(PetState newState, double? duration = null)
    {
        if (newState == _currentState && _currentState != PetState.Idle)
            return;

        _previousState = _currentState;
        _currentState = newState;
        _stateEnteredAt = DateTime.UtcNow;
        _stateDuration = duration ?? RandomRange(4.0, 10.0);

        var anim = GetAnimation(newState);
        StateChanged?.Invoke(newState, anim);
    }

    private static double RandomRange(double min, double max)
    {
        return min + _rng.NextDouble() * (max - min);
    }
}
