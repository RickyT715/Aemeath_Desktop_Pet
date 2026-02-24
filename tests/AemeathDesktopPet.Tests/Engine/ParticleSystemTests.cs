using AemeathDesktopPet.Engine;

namespace AemeathDesktopPet.Tests.Engine;

public class ParticleSystemTests
{
    [Fact]
    public void Particles_EmptyByDefault()
    {
        var ps = new ParticleSystem();
        Assert.Empty(ps.Particles);
    }

    [Fact]
    public void Emit_AddsParticles()
    {
        var ps = new ParticleSystem();
        ps.Emit(ParticleType.Heart, 100, 100, 3);
        Assert.Equal(3, ps.Particles.Count);
    }

    [Fact]
    public void Emit_FiresParticlesChangedEvent()
    {
        var ps = new ParticleSystem();
        bool fired = false;
        ps.ParticlesChanged += () => fired = true;
        ps.Emit(ParticleType.Sparkle, 50, 50, 1);
        Assert.True(fired);
    }

    [Fact]
    public void Emit_RespectsMaxParticles()
    {
        var ps = new ParticleSystem();
        // Max is 12; emit 15
        ps.Emit(ParticleType.MusicNote, 0, 0, 15);
        Assert.True(ps.Particles.Count <= 12);
    }

    [Fact]
    public void Emit_SetsCorrectType()
    {
        var ps = new ParticleSystem();
        ps.Emit(ParticleType.SleepZ, 0, 0, 1);
        Assert.Equal(ParticleType.SleepZ, ps.Particles[0].Type);
    }

    [Fact]
    public void Emit_SetsGlyph()
    {
        var ps = new ParticleSystem();
        ps.Emit(ParticleType.Heart, 0, 0, 1);
        Assert.Equal("\u2665", ps.Particles[0].Glyph);
    }

    [Theory]
    [InlineData(ParticleType.MusicNote, "\u266A")]
    [InlineData(ParticleType.Heart, "\u2665")]
    [InlineData(ParticleType.Sparkle, "\u2726")]
    [InlineData(ParticleType.SleepZ, "Z")]
    [InlineData(ParticleType.FurPuff, "\u2022")]
    public void Emit_CorrectGlyphForType(ParticleType type, string expectedGlyph)
    {
        var ps = new ParticleSystem();
        ps.Emit(type, 0, 0, 1);
        Assert.Equal(expectedGlyph, ps.Particles[0].Glyph);
    }

    [Fact]
    public void Emit_PawPrint_HasGlyph()
    {
        var ps = new ParticleSystem();
        ps.Emit(ParticleType.PawPrint, 0, 0, 1);
        Assert.False(string.IsNullOrEmpty(ps.Particles[0].Glyph));
    }

    [Fact]
    public void Particle_DefaultLife_Is1()
    {
        var p = new Particle();
        Assert.Equal(1.0, p.Life);
    }

    [Fact]
    public void Particle_DefaultOpacity_Is1()
    {
        var p = new Particle();
        Assert.Equal(1.0, p.Opacity);
    }

    [Fact]
    public void Emit_ParticlesHaveNegativeVelocityY()
    {
        var ps = new ParticleSystem();
        ps.Emit(ParticleType.Heart, 100, 100, 1);
        // Particles float upward (negative Y)
        Assert.True(ps.Particles[0].VelocityY < 0);
    }

    [Fact]
    public void Start_Stop_DoesNotThrow()
    {
        var ps = new ParticleSystem();
        ps.Start();
        ps.Stop();
    }

    [Fact]
    public void ParticleType_Has6Values()
    {
        Assert.Equal(6, Enum.GetValues<ParticleType>().Length);
    }
}
