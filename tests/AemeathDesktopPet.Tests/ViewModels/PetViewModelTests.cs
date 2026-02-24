using System.ComponentModel;
using AemeathDesktopPet.Models;
using AemeathDesktopPet.ViewModels;

namespace AemeathDesktopPet.Tests.ViewModels;

public class PetViewModelTests
{
    [Fact]
    public void PetViewModel_CanBeCreated()
    {
        // PetViewModel creates a ConfigService which does file I/O,
        // but should not throw on creation.
        var vm = new PetViewModel();
        Assert.NotNull(vm);
    }

    [Fact]
    public void PetViewModel_SpriteSize_IsPositive()
    {
        var vm = new PetViewModel();
        Assert.True(vm.SpriteSize > 0);
        Assert.True(vm.SpriteSize >= 100 && vm.SpriteSize <= 500);
    }

    [Fact]
    public void PetViewModel_DefaultOpacity_Is1()
    {
        var vm = new PetViewModel();
        Assert.Equal(1.0, vm.PetOpacity);
    }

    [Fact]
    public void PetViewModel_InitialState_IsIdle()
    {
        var vm = new PetViewModel();
        Assert.Equal(PetState.Idle, vm.CurrentState);
    }

    [Fact]
    public void PetViewModel_CurrentFrame_IsNullBeforeInitialize()
    {
        var vm = new PetViewModel();
        Assert.Null(vm.CurrentFrame);
    }

    [Fact]
    public void PetViewModel_ImplementsINotifyPropertyChanged()
    {
        var vm = new PetViewModel();
        Assert.IsAssignableFrom<INotifyPropertyChanged>(vm);
    }

    [Fact]
    public void PetViewModel_PropertyChanged_FiresForPetX()
    {
        var vm = new PetViewModel();
        string? changedProp = null;
        vm.PropertyChanged += (_, args) => changedProp = args.PropertyName;

        vm.PetX = 100;

        Assert.Equal("PetX", changedProp);
    }

    [Fact]
    public void PetViewModel_PropertyChanged_FiresForPetY()
    {
        var vm = new PetViewModel();
        string? changedProp = null;
        vm.PropertyChanged += (_, args) => changedProp = args.PropertyName;

        vm.PetY = 200;

        Assert.Equal("PetY", changedProp);
    }

    [Fact]
    public void PetViewModel_PropertyChanged_FiresForSpriteSize()
    {
        var vm = new PetViewModel();
        string? changedProp = null;
        vm.PropertyChanged += (_, args) => changedProp = args.PropertyName;

        vm.SpriteSize = 250;

        Assert.Equal("SpriteSize", changedProp);
    }

    [Fact]
    public void PetViewModel_PropertyChanged_FiresForPetOpacity()
    {
        var vm = new PetViewModel();
        string? changedProp = null;
        vm.PropertyChanged += (_, args) => changedProp = args.PropertyName;

        vm.PetOpacity = 0.5;

        Assert.Equal("PetOpacity", changedProp);
    }

    [Fact]
    public void PetViewModel_PropertyChanged_FiresForCurrentFrame()
    {
        var vm = new PetViewModel();
        string? changedProp = null;
        vm.PropertyChanged += (_, args) => changedProp = args.PropertyName;

        vm.CurrentFrame = null; // set to same value, but setter still fires

        Assert.Equal("CurrentFrame", changedProp);
    }

    [Fact]
    public void OnLeftClick_DoesNotThrow()
    {
        var vm = new PetViewModel();
        vm.OnLeftClick(); // Should not throw even before Initialize
    }

    [Fact]
    public void OnPetHappy_DoesNotThrow()
    {
        var vm = new PetViewModel();
        vm.OnPetHappy();
    }

    [Fact]
    public void Shutdown_DoesNotThrow_BeforeInitialize()
    {
        var vm = new PetViewModel();
        vm.Shutdown(); // Should not throw even if never initialized
    }

    [Fact]
    public void OnDragStart_OnDragEnd_Cycle()
    {
        var vm = new PetViewModel();

        // Should not throw
        vm.OnDragStart();
        vm.OnDragMove(150, 250);
        vm.OnDragEnd();
    }

    [Fact]
    public void OnDragEnd_WithoutDragStart_DoesNotThrow()
    {
        var vm = new PetViewModel();
        vm.OnDragEnd(); // Should be a no-op
    }

    [Fact]
    public void OnDragMove_WithoutDragStart_DoesNotThrow()
    {
        var vm = new PetViewModel();
        vm.OnDragMove(150, 250); // Should be a no-op
    }

    [Fact]
    public void OnSingRequested_DoesNotThrow()
    {
        var vm = new PetViewModel();
        vm.OnSingRequested();
    }

    [Fact]
    public void ApplySettings_DoesNotThrow()
    {
        var vm = new PetViewModel();
        vm.ApplySettings();
    }

    [Fact]
    public void Config_IsNotNull()
    {
        var vm = new PetViewModel();
        Assert.NotNull(vm.Config);
    }

    [Fact]
    public void Music_IsNotNull()
    {
        var vm = new PetViewModel();
        Assert.NotNull(vm.Music);
    }

    [Fact]
    public void Stats_IsNotNull()
    {
        var vm = new PetViewModel();
        Assert.NotNull(vm.Stats);
    }

    [Fact]
    public void Memory_IsNotNull()
    {
        var vm = new PetViewModel();
        Assert.NotNull(vm.Memory);
    }

    [Fact]
    public void Chat_IsNotNull()
    {
        var vm = new PetViewModel();
        Assert.NotNull(vm.Chat);
    }

    [Fact]
    public void Glitch_IsNotNull()
    {
        var vm = new PetViewModel();
        Assert.NotNull(vm.Glitch);
    }

    [Fact]
    public void Particles_IsNotNull()
    {
        var vm = new PetViewModel();
        Assert.NotNull(vm.Particles);
    }

    [Fact]
    public void PaperPlanes_IsNotNull()
    {
        var vm = new PetViewModel();
        Assert.NotNull(vm.PaperPlanes);
    }

    [Fact]
    public void CatBehavior_IsNotNull()
    {
        var vm = new PetViewModel();
        Assert.NotNull(vm.CatBehavior);
    }

    [Fact]
    public void OnChatRequested_SetsStateToChat()
    {
        var vm = new PetViewModel();
        vm.OnChatRequested();
        Assert.Equal(PetState.Chat, vm.CurrentState);
    }

    [Fact]
    public void OnChatClosed_SetsStateToIdle()
    {
        var vm = new PetViewModel();
        vm.OnChatRequested();
        vm.OnChatClosed();
        Assert.Equal(PetState.Idle, vm.CurrentState);
    }

    [Fact]
    public void OnPaperPlaneRequested_DoesNotThrow()
    {
        var vm = new PetViewModel();
        vm.OnPaperPlaneRequested();
    }

    [Fact]
    public void GetIdleBubbleText_ReturnsNonEmpty()
    {
        var vm = new PetViewModel();
        var text = vm.GetIdleBubbleText();
        Assert.False(string.IsNullOrEmpty(text));
    }

    [Fact]
    public void OnDragStart_SetsStateToDrag()
    {
        var vm = new PetViewModel();
        vm.OnDragStart();
        Assert.Equal(PetState.Drag, vm.CurrentState);
    }

    [Fact]
    public void OnDragEnd_SetsStateToIdle()
    {
        var vm = new PetViewModel();
        vm.OnDragStart();
        vm.OnDragEnd();
        Assert.Equal(PetState.Idle, vm.CurrentState);
    }
}
