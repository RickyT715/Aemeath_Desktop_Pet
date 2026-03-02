using AemeathDesktopPet.Engine;
using AemeathDesktopPet.Models;

namespace AemeathDesktopPet.Tests.Engine;

public class BehaviorEngineTests
{
    private BehaviorEngine CreateEngine()
    {
        return new BehaviorEngine();
    }

    [Fact]
    public void InitialState_IsIdle()
    {
        var engine = CreateEngine();
        Assert.Equal(PetState.Idle, engine.CurrentState);
    }

    [Fact]
    public void Start_TransitionsToIdle_AndFiresEvent()
    {
        var engine = CreateEngine();
        PetState? receivedState = null;
        AnimationInfo? receivedAnim = null;

        engine.StateChanged += (state, anim) =>
        {
            receivedState = state;
            receivedAnim = anim;
        };

        engine.Start();

        Assert.Equal(PetState.Idle, engine.CurrentState);
        Assert.Equal(PetState.Idle, receivedState);
        Assert.NotNull(receivedAnim);
        Assert.Equal("normal", receivedAnim!.GifFileName);
    }

    [Fact]
    public void ForceState_ChangesCurrentState()
    {
        var engine = CreateEngine();
        engine.Start();

        engine.ForceState(PetState.Wave, 2.0);

        Assert.Equal(PetState.Wave, engine.CurrentState);
    }

    [Fact]
    public void ForceState_SetsPreviousState()
    {
        var engine = CreateEngine();
        engine.Start();

        engine.ForceState(PetState.Wave, 2.0);

        Assert.Equal(PetState.Idle, engine.PreviousState);
    }

    [Fact]
    public void ForceState_FiresStateChanged()
    {
        var engine = CreateEngine();
        engine.Start();

        PetState? receivedState = null;
        engine.StateChanged += (state, _) => receivedState = state;

        engine.ForceState(PetState.Laugh, 3.0);

        Assert.Equal(PetState.Laugh, receivedState);
    }

    [Fact]
    public void ForceState_SkipsSameState_NonIdle()
    {
        var engine = CreateEngine();
        engine.Start();

        engine.ForceState(PetState.Laugh, 3.0);

        // Trying to force same state should be skipped
        int eventCount = 0;
        engine.StateChanged += (_, _) => eventCount++;

        engine.ForceState(PetState.Laugh, 3.0);

        Assert.Equal(0, eventCount);
    }

    [Fact]
    public void ForceState_AllowsSameState_Idle()
    {
        var engine = CreateEngine();
        engine.Start();

        // Idle should be re-enterable (for "stay idle" transition)
        int eventCount = 0;
        engine.StateChanged += (_, _) => eventCount++;

        engine.ForceState(PetState.Idle, 5.0);

        Assert.Equal(1, eventCount);
    }

    [Fact]
    public void ReturnToPrevious_RestoresPreviousState()
    {
        var engine = CreateEngine();
        engine.Start();

        engine.ForceState(PetState.Wave, 2.0);
        Assert.Equal(PetState.Wave, engine.CurrentState);

        engine.ReturnToPrevious();
        Assert.Equal(PetState.Idle, engine.CurrentState);
    }

    [Fact]
    public void GetAnimation_ReturnsCorrectAnimation_ForKnownStates()
    {
        Assert.Equal("normal", BehaviorEngine.GetAnimation(PetState.Idle).GifFileName);
        Assert.Equal("normal_flying", BehaviorEngine.GetAnimation(PetState.FlyRight).GifFileName);
        Assert.Equal("normal_flying", BehaviorEngine.GetAnimation(PetState.FlyLeft).GifFileName);
        Assert.Equal("happy_hand_waving", BehaviorEngine.GetAnimation(PetState.Wave).GifFileName);
        Assert.Equal("laugh", BehaviorEngine.GetAnimation(PetState.Laugh).GifFileName);
        Assert.Equal("sign", BehaviorEngine.GetAnimation(PetState.Sigh).GifFileName);
        Assert.Equal("happy_jumping", BehaviorEngine.GetAnimation(PetState.PetHappy).GifFileName);
        Assert.Equal("happy_jumping", BehaviorEngine.GetAnimation(PetState.Landing).GifFileName);
        Assert.Equal("listening_music", BehaviorEngine.GetAnimation(PetState.Sing).GifFileName);
    }

    [Fact]
    public void GetAnimation_FlyLeft_IsMirrored()
    {
        var anim = BehaviorEngine.GetAnimation(PetState.FlyLeft);
        Assert.True(anim.Mirror);
    }

    [Fact]
    public void GetAnimation_FlyRight_IsNotMirrored()
    {
        var anim = BehaviorEngine.GetAnimation(PetState.FlyRight);
        Assert.False(anim.Mirror);
    }

    [Fact]
    public void GetAnimation_Sing_Has25Fps()
    {
        var anim = BehaviorEngine.GetAnimation(PetState.Sing);
        Assert.Equal(25.0, anim.Fps);
    }

    [Fact]
    public void GetAnimation_Sleep_MapsToSign()
    {
        // Sleep now has an explicit mapping to sign.gif (closest to drowsy)
        var anim = BehaviorEngine.GetAnimation(PetState.Sleep);
        Assert.Equal("sign", anim.GifFileName);
    }

    [Fact]
    public void GetAnimation_AllStatesHaveMappings()
    {
        // Every PetState enum value should have an explicit animation mapping
        foreach (PetState state in Enum.GetValues<PetState>())
        {
            var anim = BehaviorEngine.GetAnimation(state);
            Assert.NotNull(anim);
            Assert.False(string.IsNullOrEmpty(anim.GifFileName));
        }
    }

    [Fact]
    public void GetAnimation_Wave_IsOneShot()
    {
        var anim = BehaviorEngine.GetAnimation(PetState.Wave);
        Assert.False(anim.Loop);
    }

    [Fact]
    public void GetAnimation_Idle_Loops()
    {
        var anim = BehaviorEngine.GetAnimation(PetState.Idle);
        Assert.True(anim.Loop);
    }

    [Fact]
    public void SimulateBehaviorTick_SkipsDrag()
    {
        var engine = CreateEngine();
        engine.Start();
        engine.ForceState(PetState.Drag);

        // Force time expiry
        engine._stateEnteredAt = DateTime.UtcNow.AddSeconds(-100);
        engine._stateDuration = 1.0;

        int eventCount = 0;
        engine.StateChanged += (_, _) => eventCount++;

        engine.SimulateBehaviorTick();

        // Should not transition because Drag is user-driven
        Assert.Equal(PetState.Drag, engine.CurrentState);
        Assert.Equal(0, eventCount);
    }

    [Fact]
    public void SimulateBehaviorTick_SkipsThrown()
    {
        var engine = CreateEngine();
        engine.Start();
        engine.ForceState(PetState.Thrown);

        engine._stateEnteredAt = DateTime.UtcNow.AddSeconds(-100);
        engine._stateDuration = 1.0;

        engine.SimulateBehaviorTick();

        Assert.Equal(PetState.Thrown, engine.CurrentState);
    }

    [Fact]
    public void SimulateBehaviorTick_SkipsFall()
    {
        var engine = CreateEngine();
        engine.Start();
        engine.ForceState(PetState.Fall);

        engine._stateEnteredAt = DateTime.UtcNow.AddSeconds(-100);
        engine._stateDuration = 1.0;

        engine.SimulateBehaviorTick();

        Assert.Equal(PetState.Fall, engine.CurrentState);
    }

    [Fact]
    public void SimulateBehaviorTick_SkipsChat()
    {
        var engine = CreateEngine();
        engine.Start();
        engine.ForceState(PetState.Chat);

        engine._stateEnteredAt = DateTime.UtcNow.AddSeconds(-100);
        engine._stateDuration = 1.0;

        engine.SimulateBehaviorTick();

        Assert.Equal(PetState.Chat, engine.CurrentState);
    }

    [Fact]
    public void SimulateBehaviorTick_DoesNotTransition_WhenNotExpired()
    {
        var engine = CreateEngine();
        engine.Start();

        // Set a long duration, just entered
        engine._stateEnteredAt = DateTime.UtcNow;
        engine._stateDuration = 999.0;

        int eventCount = 0;
        engine.StateChanged += (_, _) => eventCount++;

        engine.SimulateBehaviorTick();

        Assert.Equal(0, eventCount);
    }

    [Fact]
    public void SimulateBehaviorTick_Transitions_WhenExpired()
    {
        var engine = CreateEngine();
        engine.Start();

        // Force expiry
        engine._stateEnteredAt = DateTime.UtcNow.AddSeconds(-100);
        engine._stateDuration = 1.0;

        PetState? newState = null;
        engine.StateChanged += (state, _) => newState = state;

        engine.SimulateBehaviorTick();

        // Should have transitioned to some state
        Assert.NotNull(newState);
    }

    [Fact]
    public void SimulateBehaviorTick_AutoTransition_ProducesValidState()
    {
        var engine = CreateEngine();
        engine.Start();

        // Force expiry many times to exercise weighted random
        var seenStates = new HashSet<PetState>();
        engine.StateChanged += (state, _) => seenStates.Add(state);

        for (int i = 0; i < 100; i++)
        {
            engine._stateEnteredAt = DateTime.UtcNow.AddSeconds(-100);
            engine._stateDuration = 0;
            engine.SimulateBehaviorTick();
        }

        // Should see at least some of the idle transition states (expanded table)
        var validStates = new HashSet<PetState>
        {
            PetState.Idle, PetState.FlyRight, PetState.FlyLeft,
            PetState.Sing, PetState.Laugh, PetState.Sigh,
            PetState.PlayGame, PetState.PaperPlane, PetState.LookAtUser,
            PetState.PetCat, PetState.Sleep,
        };

        foreach (var state in seenStates)
        {
            Assert.Contains(state, validStates);
        }
    }

    [Fact]
    public void SimulateBehaviorTick_SkipsSleep()
    {
        var engine = CreateEngine();
        engine.Start();
        engine.ForceState(PetState.Sleep);

        engine._stateEnteredAt = DateTime.UtcNow.AddSeconds(-100);
        engine._stateDuration = 1.0;

        engine.SimulateBehaviorTick();

        Assert.Equal(PetState.Sleep, engine.CurrentState);
    }

    [Fact]
    public void SimulateBehaviorTick_SkipsSpeaking()
    {
        var engine = CreateEngine();
        engine.Start();
        engine.ForceState(PetState.Speaking);

        engine._stateEnteredAt = DateTime.UtcNow.AddSeconds(-100);
        engine._stateDuration = 1.0;

        engine.SimulateBehaviorTick();

        Assert.Equal(PetState.Speaking, engine.CurrentState);
    }

    [Fact]
    public void SetStatsContext_DoesNotThrow()
    {
        var engine = CreateEngine();
        engine.SetStatsContext(80, 60);
    }

    [Fact]
    public void MultipleTransitions_TrackPreviousCorrectly()
    {
        var engine = CreateEngine();
        engine.Start();

        engine.ForceState(PetState.FlyRight, 5.0);
        Assert.Equal(PetState.Idle, engine.PreviousState);

        engine.ForceState(PetState.Wave, 1.5);
        Assert.Equal(PetState.FlyRight, engine.PreviousState);

        engine.ForceState(PetState.Laugh, 2.0);
        Assert.Equal(PetState.Wave, engine.PreviousState);
    }

    [Fact]
    public void SuppressSinging_DefaultIsFalse()
    {
        var engine = CreateEngine();
        Assert.False(engine.SuppressSinging);
    }

    [Fact]
    public void SuppressSinging_WhenTrue_PreventsSingSelection()
    {
        var engine = CreateEngine();
        engine.Start();
        engine.SuppressSinging = true;
        // High mood and energy so Sing would normally be possible
        engine.SetStatsContext(80, 80);

        var seenStates = new HashSet<PetState>();
        engine.StateChanged += (state, _) => seenStates.Add(state);

        // Run many transitions. Reset to Idle to avoid NoAutoTransition deadlock.
        for (int i = 0; i < 200; i++)
        {
            engine._currentState = PetState.Idle;
            engine._stateEnteredAt = DateTime.UtcNow.AddSeconds(-100);
            engine._stateDuration = 0;
            engine.SimulateBehaviorTick();
        }

        Assert.DoesNotContain(PetState.Sing, seenStates);
    }

    [Fact]
    public void SuppressSinging_WhenFalse_AllowsSingSelection()
    {
        var engine = CreateEngine();
        engine.Start();
        engine.SuppressSinging = false;
        engine.SetStatsContext(80, 80);

        var seenStates = new HashSet<PetState>();
        engine.StateChanged += (state, _) => seenStates.Add(state);

        // Run many transitions — Sing has weight 5 so should appear in 500 tries.
        // Reset state to Idle before each tick to avoid getting stuck in
        // NoAutoTransition states (e.g., PlayGame) which block further transitions.
        for (int i = 0; i < 500; i++)
        {
            engine._currentState = PetState.Idle;
            engine._stateEnteredAt = DateTime.UtcNow.AddSeconds(-100);
            engine._stateDuration = 0;
            engine.SimulateBehaviorTick();
        }

        Assert.Contains(PetState.Sing, seenStates);
    }

    [Fact]
    public void SuppressSinging_CanBeToggled()
    {
        var engine = CreateEngine();
        engine.SuppressSinging = true;
        Assert.True(engine.SuppressSinging);
        engine.SuppressSinging = false;
        Assert.False(engine.SuppressSinging);
    }
}
