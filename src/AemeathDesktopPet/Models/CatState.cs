namespace AemeathDesktopPet.Models;

/// <summary>
/// All possible states for the black cat companion's FSM.
/// </summary>
public enum CatState
{
    CatIdle,
    CatWalk,
    CatNap,
    CatGroom,
    CatPounce,
    CatWatch,
    CatRub,
    CatStartled,
    CatPurr,
    CatPerch,
    CatChase,
    CatBat,
}
