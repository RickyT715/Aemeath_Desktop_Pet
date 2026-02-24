using AemeathDesktopPet.Models;

namespace AemeathDesktopPet.Tests.Models;

public class CatStateTests
{
    [Fact]
    public void CatState_Has12Values()
    {
        var values = Enum.GetValues<CatState>();
        Assert.Equal(12, values.Length);
    }

    [Fact]
    public void CatState_ContainsAllExpectedStates()
    {
        Assert.True(Enum.IsDefined(CatState.CatIdle));
        Assert.True(Enum.IsDefined(CatState.CatWalk));
        Assert.True(Enum.IsDefined(CatState.CatNap));
        Assert.True(Enum.IsDefined(CatState.CatGroom));
        Assert.True(Enum.IsDefined(CatState.CatPounce));
        Assert.True(Enum.IsDefined(CatState.CatWatch));
        Assert.True(Enum.IsDefined(CatState.CatRub));
        Assert.True(Enum.IsDefined(CatState.CatStartled));
        Assert.True(Enum.IsDefined(CatState.CatPurr));
        Assert.True(Enum.IsDefined(CatState.CatPerch));
        Assert.True(Enum.IsDefined(CatState.CatChase));
        Assert.True(Enum.IsDefined(CatState.CatBat));
    }
}
