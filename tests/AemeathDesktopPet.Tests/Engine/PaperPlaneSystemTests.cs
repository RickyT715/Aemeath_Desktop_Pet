using System.Windows;
using AemeathDesktopPet.Engine;

namespace AemeathDesktopPet.Tests.Engine;

public class PaperPlaneSystemTests
{
    private static readonly Rect TestBounds = new(0, 0, 1920, 1080);

    [Fact]
    public void Planes_EmptyByDefault()
    {
        var pps = new PaperPlaneSystem();
        Assert.Empty(pps.Planes);
    }

    [Fact]
    public void EnableAmbient_TrueByDefault()
    {
        var pps = new PaperPlaneSystem();
        Assert.True(pps.EnableAmbient);
    }

    [Fact]
    public void ThrowPlane_AddsPlane()
    {
        var pps = new PaperPlaneSystem();
        pps.ThrowPlane(500, 300, TestBounds);
        Assert.Single(pps.Planes);
    }

    [Fact]
    public void ThrowPlane_PlaneIsNotAmbient()
    {
        var pps = new PaperPlaneSystem();
        pps.ThrowPlane(500, 300, TestBounds);
        Assert.False(pps.Planes[0].IsAmbient);
    }

    [Fact]
    public void ThrowPlane_SetsStartPosition()
    {
        var pps = new PaperPlaneSystem();
        pps.ThrowPlane(500, 300, TestBounds);
        Assert.Equal(500, pps.Planes[0].X);
        Assert.Equal(300, pps.Planes[0].Y);
    }

    [Fact]
    public void ThrowPlane_FiresPlanesChangedEvent()
    {
        var pps = new PaperPlaneSystem();
        bool fired = false;
        pps.PlanesChanged += () => fired = true;
        pps.ThrowPlane(500, 300, TestBounds);
        Assert.True(fired);
    }

    [Fact]
    public void SpawnAmbient_AddsAmbientPlane()
    {
        var pps = new PaperPlaneSystem();
        pps.SpawnAmbient(TestBounds);
        Assert.Single(pps.Planes);
        Assert.True(pps.Planes[0].IsAmbient);
    }

    [Fact]
    public void SpawnAmbient_PlaneStartsOutsideBounds()
    {
        var pps = new PaperPlaneSystem();
        pps.SpawnAmbient(TestBounds);
        var plane = pps.Planes[0];
        // Ambient planes start outside screen edges
        Assert.True(plane.X < TestBounds.Left || plane.X > TestBounds.Right);
    }

    [Fact]
    public void ThrowPlane_MultiplePlanes()
    {
        var pps = new PaperPlaneSystem();
        pps.ThrowPlane(100, 100, TestBounds);
        pps.ThrowPlane(200, 200, TestBounds);
        pps.ThrowPlane(300, 300, TestBounds);
        Assert.Equal(3, pps.Planes.Count);
    }

    [Fact]
    public void TryClickPlane_ReturnsFalseWhenNoPlanesNearby()
    {
        var pps = new PaperPlaneSystem();
        pps.ThrowPlane(500, 300, TestBounds);
        Assert.False(pps.TryClickPlane(0, 0)); // far from the plane
    }

    [Fact]
    public void TryClickPlane_ReturnsTrueWhenPlaneNearby()
    {
        var pps = new PaperPlaneSystem();
        pps.ThrowPlane(500, 300, TestBounds);
        // Click within 25px of plane position
        Assert.True(pps.TryClickPlane(500, 300));
    }

    [Fact]
    public void TryClickPlane_ReturnsFalseWhenNoPlanes()
    {
        var pps = new PaperPlaneSystem();
        Assert.False(pps.TryClickPlane(500, 300));
    }

    [Fact]
    public void TryClickPlane_ReversesVelocity()
    {
        var pps = new PaperPlaneSystem();
        pps.ThrowPlane(500, 300, TestBounds);
        double originalVx = pps.Planes[0].VelocityX;

        pps.TryClickPlane(500, 300);

        // Velocity should be reversed (approximately)
        Assert.True(Math.Sign(pps.Planes[0].VelocityX) != Math.Sign(originalVx)
                    || originalVx == 0); // edge case if velocity was 0
    }

    [Fact]
    public void PaperPlane_DefaultTimeAlive_IsZero()
    {
        var plane = new PaperPlane();
        Assert.Equal(0, plane.TimeAlive);
    }

    [Fact]
    public void Start_Stop_DoesNotThrow()
    {
        var pps = new PaperPlaneSystem();
        pps.Start();
        pps.Stop();
    }

    [Fact]
    public void ThrowPlane_HasUpwardInitialVelocity()
    {
        var pps = new PaperPlaneSystem();
        pps.ThrowPlane(500, 500, TestBounds);
        Assert.True(pps.Planes[0].VelocityY < 0); // negative = upward
    }

    [Fact]
    public void ThrowPlane_SetsScreenBounds()
    {
        var pps = new PaperPlaneSystem();
        pps.ThrowPlane(500, 300, TestBounds);
        Assert.Equal(TestBounds, pps.Planes[0].ScreenBounds);
    }
}
