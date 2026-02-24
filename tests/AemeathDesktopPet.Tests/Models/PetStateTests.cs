using AemeathDesktopPet.Models;

namespace AemeathDesktopPet.Tests.Models;

public class PetStateTests
{
    [Fact]
    public void PetState_HasAllCoreStates()
    {
        // Phase 1 core states
        Assert.True(Enum.IsDefined(typeof(PetState), PetState.Idle));
        Assert.True(Enum.IsDefined(typeof(PetState), PetState.FlyLeft));
        Assert.True(Enum.IsDefined(typeof(PetState), PetState.FlyRight));
        Assert.True(Enum.IsDefined(typeof(PetState), PetState.Fall));
        Assert.True(Enum.IsDefined(typeof(PetState), PetState.Drag));
        Assert.True(Enum.IsDefined(typeof(PetState), PetState.Thrown));
        Assert.True(Enum.IsDefined(typeof(PetState), PetState.Landing));
        Assert.True(Enum.IsDefined(typeof(PetState), PetState.Wave));
        Assert.True(Enum.IsDefined(typeof(PetState), PetState.Laugh));
        Assert.True(Enum.IsDefined(typeof(PetState), PetState.Sigh));
        Assert.True(Enum.IsDefined(typeof(PetState), PetState.PetHappy));
    }

    [Fact]
    public void PetState_HasPersonalityStates()
    {
        Assert.True(Enum.IsDefined(typeof(PetState), PetState.Sing));
        Assert.True(Enum.IsDefined(typeof(PetState), PetState.Sleep));
        Assert.True(Enum.IsDefined(typeof(PetState), PetState.Chat));
        Assert.True(Enum.IsDefined(typeof(PetState), PetState.Glitch));
        Assert.True(Enum.IsDefined(typeof(PetState), PetState.LookAtUser));
    }

    [Fact]
    public void PetState_HasWindowEdgeStates()
    {
        Assert.True(Enum.IsDefined(typeof(PetState), PetState.PeekEdge));
        Assert.True(Enum.IsDefined(typeof(PetState), PetState.LieOnWindow));
        Assert.True(Enum.IsDefined(typeof(PetState), PetState.HideTaskbar));
        Assert.True(Enum.IsDefined(typeof(PetState), PetState.ClingEdge));
    }

    [Fact]
    public void PetState_HasVoiceAndScreenStates()
    {
        Assert.True(Enum.IsDefined(typeof(PetState), PetState.Speaking));
        Assert.True(Enum.IsDefined(typeof(PetState), PetState.ScreenComment));
    }

    [Fact]
    public void PetState_TotalCount()
    {
        var values = Enum.GetValues<PetState>();
        Assert.Equal(26, values.Length);
    }
}
