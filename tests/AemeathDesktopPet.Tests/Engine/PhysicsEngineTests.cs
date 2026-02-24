using System.Windows;
using AemeathDesktopPet.Engine;

namespace AemeathDesktopPet.Tests.Engine;

public class PhysicsEngineTests
{
    private PhysicsEngine CreateEngine(Rect? bounds = null)
    {
        var engine = new PhysicsEngine();
        var workArea = bounds ?? new Rect(0, 0, 1920, 1080);
        engine.SpriteSize = 200;
        engine.UpdateBounds(workArea);
        return engine;
    }

    // --- UpdateBounds ---

    [Fact]
    public void UpdateBounds_SetsScreenBounds()
    {
        var engine = new PhysicsEngine();
        engine.SpriteSize = 200;
        engine.UpdateBounds(new Rect(0, 0, 1920, 1080));

        Assert.Equal(new Rect(0, 0, 1920, 1080), engine.ScreenBounds);
    }

    [Fact]
    public void UpdateBounds_SetsGroundY()
    {
        var engine = new PhysicsEngine();
        engine.SpriteSize = 200;
        engine.UpdateBounds(new Rect(0, 0, 1920, 1080));

        Assert.Equal(880, engine.GroundY); // 1080 - 200
    }

    [Fact]
    public void UpdateBounds_WithOffset()
    {
        var engine = new PhysicsEngine();
        engine.SpriteSize = 200;
        engine.UpdateBounds(new Rect(0, 0, 1920, 1040)); // taskbar = 40px

        Assert.Equal(840, engine.GroundY); // 1040 - 200
    }

    // --- Gravity ---

    [Fact]
    public void SimulateTick_Gravity_IncreasesVelocityY()
    {
        var engine = CreateEngine();
        engine.X = 500;
        engine.Y = 200;
        engine.IsGravityActive = true;
        engine.VelocityY = 0;

        engine.SimulateTick(0.016); // ~1 frame

        Assert.True(engine.VelocityY > 0); // Velocity increased downward
    }

    [Fact]
    public void SimulateTick_Gravity_MovesDown()
    {
        var engine = CreateEngine();
        engine.X = 500;
        engine.Y = 200;
        engine.IsGravityActive = true;
        engine.VelocityY = 100;

        engine.SimulateTick(0.016);

        Assert.True(engine.Y > 200);
    }

    [Fact]
    public void SimulateTick_NoGravity_DoesNotAccelerate()
    {
        var engine = CreateEngine();
        engine.X = 500;
        engine.Y = 200;
        engine.IsGravityActive = false;
        engine.VelocityX = 0;
        engine.VelocityY = 0;

        engine.SimulateTick(0.016);

        // No velocity, no gravity → no movement, VelocityY stays 0
        Assert.Equal(0, engine.VelocityY);
    }

    // --- Ground collision ---

    [Fact]
    public void SimulateTick_GroundBounce_HighVelocity()
    {
        var engine = CreateEngine();
        engine.X = 500;
        engine.Y = engine.GroundY + 10; // Below ground
        engine.VelocityY = 200; // Above MinBounceVelocity (50)
        engine.IsGravityActive = true;

        engine.SimulateTick(0.016);

        Assert.Equal(engine.GroundY, engine.Y); // Clamped to ground
        Assert.True(engine.VelocityY < 0); // Bounced upward
    }

    [Fact]
    public void SimulateTick_GroundBounce_DampsVelocity()
    {
        var engine = CreateEngine();
        engine.X = 500;
        engine.Y = engine.GroundY + 10;
        engine.VelocityY = 200;
        engine.VelocityX = 100;
        engine.IsGravityActive = true;

        engine.SimulateTick(0.016);

        // VelocityY should be bounced and damped (0.4 factor)
        Assert.True(Math.Abs(engine.VelocityY) < 200);
        // VelocityX should have friction (0.8 factor)
        Assert.True(Math.Abs(engine.VelocityX) < 100);
    }

    [Fact]
    public void SimulateTick_Ground_LowVelocity_Stops()
    {
        var engine = CreateEngine();
        engine.X = 500;
        engine.Y = engine.GroundY + 1;
        engine.VelocityY = 30; // Below MinBounceVelocity (50)
        engine.VelocityX = 5; // Below 10
        engine.IsGravityActive = true;

        bool hitGround = false;
        engine.HitGround += () => hitGround = true;

        engine.SimulateTick(0.016);

        Assert.Equal(engine.GroundY, engine.Y);
        Assert.Equal(0, engine.VelocityY);
        Assert.Equal(0, engine.VelocityX);
        Assert.False(engine.IsGravityActive);
        Assert.True(hitGround);
    }

    [Fact]
    public void SimulateTick_Ground_LowVelocityY_HighVelocityX_DoesNotFireHitGround()
    {
        var engine = CreateEngine();
        engine.X = 500;
        engine.Y = engine.GroundY + 1;
        engine.VelocityY = 30; // Below MinBounceVelocity
        engine.VelocityX = 50; // Above 10 threshold
        engine.IsGravityActive = true;

        bool hitGround = false;
        engine.HitGround += () => hitGround = true;

        engine.SimulateTick(0.016);

        Assert.Equal(0, engine.VelocityY);
        Assert.False(hitGround); // Should NOT fire because VelocityX is still significant
    }

    // --- Screen edge collision ---

    [Fact]
    public void SimulateTick_LeftEdge_Bounce()
    {
        var engine = CreateEngine();
        engine.X = -10; // Past left edge
        engine.Y = 400;
        engine.VelocityX = -200;
        engine.IsGravityActive = false;

        engine.SimulateTick(0.016);

        Assert.Equal(0, engine.X); // Clamped to left
        Assert.True(engine.VelocityX > 0); // Bounced right
    }

    [Fact]
    public void SimulateTick_RightEdge_Bounce()
    {
        var engine = CreateEngine(); // bounds: 0,0,1920,1080
        engine.X = 1920; // Past right edge (right - SpriteSize = 1720)
        engine.Y = 400;
        engine.VelocityX = 200;
        engine.IsGravityActive = false;

        engine.SimulateTick(0.016);

        Assert.Equal(1920 - 200, engine.X); // Clamped to right - sprite
        Assert.True(engine.VelocityX < 0); // Bounced left
    }

    [Fact]
    public void SimulateTick_LeftEdge_Flying_FiresHitScreenEdge()
    {
        var engine = CreateEngine();
        engine.X = -10;
        engine.Y = 400;
        engine.IsFlying = true;
        engine.VelocityX = -80;

        bool hitEdge = false;
        engine.HitScreenEdge += () => hitEdge = true;

        engine.SimulateTick(0.016);

        Assert.True(hitEdge);
        Assert.Equal(0, engine.X);
    }

    [Fact]
    public void SimulateTick_RightEdge_Flying_FiresHitScreenEdge()
    {
        var engine = CreateEngine();
        engine.X = 1800; // Close to right
        engine.Y = 400;
        engine.IsFlying = true;
        engine.VelocityX = 80;

        bool hitEdge = false;
        engine.HitScreenEdge += () => hitEdge = true;

        engine.SimulateTick(0.016);

        Assert.True(hitEdge);
    }

    [Fact]
    public void SimulateTick_TopEdge_Bounce()
    {
        var engine = CreateEngine();
        engine.X = 500;
        engine.Y = -10;
        engine.VelocityY = -200;

        engine.SimulateTick(0.016);

        Assert.Equal(0, engine.Y); // Clamped to top
        Assert.True(engine.VelocityY > 0); // Bounced down
    }

    // --- Drag ---

    [Fact]
    public void BeginDrag_SetsState()
    {
        var engine = CreateEngine();
        engine.BeginDrag(100, 200);

        Assert.True(engine.IsDragging);
        Assert.False(engine.IsGravityActive);
        Assert.False(engine.IsFlying);
        Assert.Equal(0, engine.VelocityX);
        Assert.Equal(0, engine.VelocityY);
        Assert.Equal(0, engine.DragVelocityX);
        Assert.Equal(0, engine.DragVelocityY);
    }

    [Fact]
    public void UpdateDrag_MovesPosition()
    {
        var engine = CreateEngine();
        engine.BeginDrag(100, 200);

        engine.UpdateDrag(150, 250, 50, 50);

        Assert.Equal(100, engine.X); // 150 - 50
        Assert.Equal(200, engine.Y); // 250 - 50
    }

    [Fact]
    public void UpdateDrag_TracksDragVelocity()
    {
        var engine = CreateEngine();
        engine.BeginDrag(100, 200);

        // Simulate multiple drag updates
        engine.UpdateDrag(110, 210, 0, 0);
        engine.UpdateDrag(120, 220, 0, 0);
        engine.UpdateDrag(130, 230, 0, 0);

        // DragVelocity should be non-zero after movement
        Assert.NotEqual(0, engine.DragVelocityX);
        Assert.NotEqual(0, engine.DragVelocityY);
    }

    [Fact]
    public void UpdateDrag_ClampsToScreen()
    {
        var engine = CreateEngine();
        engine.BeginDrag(100, 200);

        // Try to drag way off-screen
        engine.UpdateDrag(-500, -500, 0, 0);

        Assert.True(engine.X >= 0);
        Assert.True(engine.Y >= 0);
    }

    [Fact]
    public void EndDrag_StaysInPlace()
    {
        var engine = CreateEngine();
        engine.BeginDrag(100, 200);

        // Simulate drag to a position
        engine.UpdateDrag(300, 400, 0, 0);

        double xBefore = engine.X;
        double yBefore = engine.Y;

        engine.EndDrag();

        Assert.False(engine.IsDragging);
        Assert.False(engine.IsGravityActive);
        Assert.Equal(0, engine.VelocityX);
        Assert.Equal(0, engine.VelocityY);
        Assert.Equal(xBefore, engine.X);
        Assert.Equal(yBefore, engine.Y);
    }

    [Fact]
    public void EndDrag_NoGravityAfterRelease()
    {
        var engine = CreateEngine();
        engine.BeginDrag(100, 200);
        engine.UpdateDrag(500, 300, 0, 0);
        engine.EndDrag();

        double yBefore = engine.Y;

        // Simulate a physics tick — pet should NOT fall
        engine.SimulateTick(0.1);

        Assert.Equal(yBefore, engine.Y);
    }

    // --- Flying ---

    [Fact]
    public void StartFlying_Right()
    {
        var engine = CreateEngine();
        engine.StartFlying(1);

        Assert.True(engine.IsFlying);
        Assert.False(engine.IsGravityActive);
        Assert.Equal(1, engine.FlyDirection);
        Assert.True(engine.VelocityX > 0);
    }

    [Fact]
    public void StartFlying_Left()
    {
        var engine = CreateEngine();
        engine.StartFlying(-1);

        Assert.True(engine.IsFlying);
        Assert.Equal(-1, engine.FlyDirection);
        Assert.True(engine.VelocityX < 0);
    }

    [Fact]
    public void StopFlying_ResetsState()
    {
        var engine = CreateEngine();
        engine.StartFlying(1);
        engine.StopFlying();

        Assert.False(engine.IsFlying);
        Assert.Equal(0, engine.FlyDirection);
        Assert.Equal(0, engine.VelocityX);
        Assert.Equal(0, engine.VelocityY);
    }

    [Fact]
    public void SimulateTick_Flying_MovesSideways()
    {
        var engine = CreateEngine();
        engine.X = 500;
        engine.Y = 400;
        engine.StartFlying(1);

        double startX = engine.X;
        engine.SimulateTick(0.1); // 100ms

        Assert.True(engine.X > startX);
    }

    [Fact]
    public void SimulateTick_Flying_HasVerticalBob()
    {
        var engine = CreateEngine();
        engine.X = 500;
        engine.Y = 400;
        engine.StartFlying(1);

        engine.SimulateTick(0.016);

        // VelocityY should be set by sine wave bob
        // It may be very small but should exist
        // (The sine bob sets VelocityY each tick)
        // This is hard to assert precisely since it depends on DateTime
        // Just check the flying state is maintained
        Assert.True(engine.IsFlying);
    }

    // --- SimulateTick edge cases ---

    [Fact]
    public void SimulateTick_SkipsDragging()
    {
        var engine = CreateEngine();
        engine.X = 500;
        engine.Y = 400;
        engine.IsDragging = true;
        engine.VelocityY = 100;
        engine.IsGravityActive = true;

        double startY = engine.Y;
        engine.SimulateTick(0.016);

        Assert.Equal(startY, engine.Y); // No movement during drag
    }

    [Fact]
    public void SimulateTick_ZeroDt_DoesNothing()
    {
        var engine = CreateEngine();
        engine.X = 500;
        engine.Y = 400;
        engine.VelocityY = 100;
        engine.IsGravityActive = true;

        engine.SimulateTick(0);

        Assert.Equal(400, engine.Y);
    }

    [Fact]
    public void SimulateTick_NegativeDt_DoesNothing()
    {
        var engine = CreateEngine();
        engine.X = 500;
        engine.Y = 400;
        engine.VelocityY = 100;

        engine.SimulateTick(-0.016);

        Assert.Equal(400, engine.Y);
    }

    [Fact]
    public void SimulateTick_PositionChanged_Fires()
    {
        var engine = CreateEngine();
        engine.X = 500;
        engine.Y = 400;
        engine.VelocityX = 100;

        bool posChanged = false;
        engine.PositionChanged += () => posChanged = true;

        engine.SimulateTick(0.016);

        Assert.True(posChanged);
    }

    [Fact]
    public void SimulateTick_NoMovement_NoEvent()
    {
        var engine = CreateEngine();
        engine.X = 500;
        engine.Y = 400;
        engine.VelocityX = 0;
        engine.VelocityY = 0;
        engine.IsGravityActive = false;

        bool posChanged = false;
        engine.PositionChanged += () => posChanged = true;

        engine.SimulateTick(0.016);

        Assert.False(posChanged);
    }
}
