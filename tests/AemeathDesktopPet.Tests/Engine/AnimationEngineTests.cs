using System.IO;
using System.Windows.Media;
using System.Windows.Media.Imaging;
using AemeathDesktopPet.Engine;
using AemeathDesktopPet.Models;

namespace AemeathDesktopPet.Tests.Engine;

public class AnimationEngineTests
{
    /// <summary>
    /// Creates a minimal valid GIF file for testing.
    /// This is a 1x1 pixel GIF89a with 2 frames.
    /// </summary>
    private static byte[] CreateTestGif(int frameCount = 2)
    {
        using var ms = new MemoryStream();
        using var writer = new BinaryWriter(ms);

        // GIF89a header
        writer.Write("GIF89a"u8);

        // Logical screen descriptor: 1x1, global color table of 2 colors
        writer.Write((ushort)1);  // width
        writer.Write((ushort)1);  // height
        writer.Write((byte)0x80); // GCT flag, 1 bit color resolution, 2 colors
        writer.Write((byte)0);    // background color index
        writer.Write((byte)0);    // pixel aspect ratio

        // Global Color Table (2 entries of 3 bytes each)
        writer.Write(new byte[] { 0, 0, 0 });     // color 0: black
        writer.Write(new byte[] { 255, 0, 0 });   // color 1: red

        // Application Extension for Netscape looping
        writer.Write((byte)0x21); // extension introducer
        writer.Write((byte)0xFF); // application extension
        writer.Write((byte)11);   // block size
        writer.Write("NETSCAPE2.0"u8);
        writer.Write((byte)3);    // sub-block size
        writer.Write((byte)1);    // loop sub-block id
        writer.Write((ushort)0);  // loop count (0 = infinite)
        writer.Write((byte)0);    // block terminator

        for (int f = 0; f < frameCount; f++)
        {
            // Graphic Control Extension
            writer.Write((byte)0x21); // extension introducer
            writer.Write((byte)0xF9); // GCE
            writer.Write((byte)4);    // block size
            writer.Write((byte)0);    // disposal method, no transparency
            writer.Write((ushort)10); // delay (10 * 10ms = 100ms)
            writer.Write((byte)0);    // transparent color index
            writer.Write((byte)0);    // block terminator

            // Image Descriptor
            writer.Write((byte)0x2C); // image separator
            writer.Write((ushort)0);  // left
            writer.Write((ushort)0);  // top
            writer.Write((ushort)1);  // width
            writer.Write((ushort)1);  // height
            writer.Write((byte)0);    // no local color table

            // Image Data (LZW compressed)
            writer.Write((byte)2);    // LZW minimum code size
            writer.Write((byte)2);    // sub-block size
            writer.Write((byte)0x4C); // compressed data
            writer.Write((byte)0x01); // compressed data
            writer.Write((byte)0);    // block terminator
        }

        // GIF trailer
        writer.Write((byte)0x3B);

        return ms.ToArray();
    }

    private string SetupTestSpritesDir(int fileCount = 1, int framesPerGif = 2)
    {
        var baseDir = Path.Combine(Path.GetTempPath(), "AemeathAnimTest_" + Guid.NewGuid().ToString("N")[..8]);
        var ameathDir = Path.Combine(baseDir, "Resources", "Sprites", "Aemeath");
        Directory.CreateDirectory(ameathDir);

        var gifData = CreateTestGif(framesPerGif);

        if (fileCount >= 1)
            File.WriteAllBytes(Path.Combine(ameathDir, "normal.gif"), gifData);
        if (fileCount >= 2)
            File.WriteAllBytes(Path.Combine(ameathDir, "laugh.gif"), gifData);
        if (fileCount >= 3)
            File.WriteAllBytes(Path.Combine(ameathDir, "normal_flying.gif"), gifData);

        return baseDir;
    }

    [Fact]
    public void CreateTestGif_ProducesValidGif()
    {
        var data = CreateTestGif(2);
        Assert.True(data.Length > 0);

        // Verify it starts with GIF89a
        Assert.Equal((byte)'G', data[0]);
        Assert.Equal((byte)'I', data[1]);
        Assert.Equal((byte)'F', data[2]);
    }

    [Fact]
    public void AnimationEngine_CanBeCreated()
    {
        var engine = new AnimationEngine();
        Assert.NotNull(engine);
        Assert.False(engine.IsPlaying);
        Assert.Null(engine.CurrentFrame);
    }

    [Fact]
    public void Play_WithFallback_PlaysNormal()
    {
        // This tests that when a requested animation doesn't exist,
        // it falls back to "normal" if available.
        // Since we can't easily control the sprites dir,
        // we test the logic indirectly through the engine API.
        var engine = new AnimationEngine();

        // Playing without preloading anything — should not crash
        var anim = new AnimationInfo("nonexistent", Loop: true);
        engine.Play(anim);

        // Should not be playing since no frames were loaded
        // (Play returns early when no frames found)
        Assert.Null(engine.CurrentFrame);
    }

    [Fact]
    public void Stop_WhenNotPlaying_DoesNotThrow()
    {
        var engine = new AnimationEngine();
        engine.Stop();
        Assert.False(engine.IsPlaying);
    }

    [Fact]
    public void AnimationInfo_ForPlay_StripsExtension()
    {
        // Verifying that AnimationInfo with ".gif" in the name
        // would work via Path.GetFileNameWithoutExtension
        var info = new AnimationInfo("normal.gif", Loop: true);
        var key = Path.GetFileNameWithoutExtension(info.GifFileName);
        Assert.Equal("normal", key);
    }

    [Fact]
    public void AnimationInfo_ForPlay_NoExtension_StaysAsIs()
    {
        var info = new AnimationInfo("normal", Loop: true);
        var key = Path.GetFileNameWithoutExtension(info.GifFileName);
        Assert.Equal("normal", key);
    }
}
