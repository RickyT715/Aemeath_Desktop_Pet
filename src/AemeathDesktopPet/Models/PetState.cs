namespace AemeathDesktopPet.Models;

/// <summary>
/// All possible states for Aemeath's behavior FSM.
/// </summary>
public enum PetState
{
    // Core states (Phase 1)
    Idle,
    FlyLeft,
    FlyRight,
    Fall,
    Drag,
    Thrown,
    Landing,
    Wave,
    Laugh,
    Sigh,
    PetHappy,

    // Personality states (Phase 4)
    Sing,
    PlayGame,
    PaperPlane,
    Glitch,
    Sleep,
    LookAtUser,
    Chat,
    CatLap,
    PetCat,

    // Window edge states (Phase 2b)
    PeekEdge,
    LieOnWindow,
    HideTaskbar,
    ClingEdge,

    // Voice & screen states (Phase 5b/5c)
    Speaking,
    ScreenComment,
}

/// <summary>
/// Metadata for an animation: which GIF file, frame count, FPS, and loop mode.
/// </summary>
public record AnimationInfo(
    string GifFileName,
    bool Loop,
    double Fps = 9.0,
    bool Mirror = false);
