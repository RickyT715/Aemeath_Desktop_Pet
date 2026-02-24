using AemeathDesktopPet.Services;

namespace AemeathDesktopPet.Tests.Services;

public class MusicServiceTests
{
    [Fact]
    public void MusicService_CanBeCreated()
    {
        var svc = new MusicService();
        Assert.NotNull(svc);
    }

    [Fact]
    public void Default_HasNoSongs()
    {
        var svc = new MusicService();
        Assert.False(svc.HasSongs);
        Assert.Equal(0, svc.SongCount);
    }

    [Fact]
    public void Default_IsNotPlaying()
    {
        var svc = new MusicService();
        Assert.False(svc.IsPlaying);
        Assert.Null(svc.CurrentSongName);
    }

    [Fact]
    public void Default_MusicFolder_IsEmpty()
    {
        var svc = new MusicService();
        Assert.Equal("", svc.MusicFolder);
    }

    [Fact]
    public void SetMusicFolder_EmptyPath_HasNoSongs()
    {
        var svc = new MusicService();
        svc.SetMusicFolder("");
        Assert.False(svc.HasSongs);
    }

    [Fact]
    public void SetMusicFolder_NonexistentPath_HasNoSongs()
    {
        var svc = new MusicService();
        svc.SetMusicFolder(@"C:\__nonexistent_aemeath_test_dir__");
        Assert.False(svc.HasSongs);
        Assert.Equal(@"C:\__nonexistent_aemeath_test_dir__", svc.MusicFolder);
    }

    [Fact]
    public void SetMusicFolder_WithAudioFiles_FindsSongs()
    {
        // Create a temp directory with some "audio" files
        var tempDir = Path.Combine(Path.GetTempPath(), "aemeath_music_test_" + Guid.NewGuid().ToString("N"));
        Directory.CreateDirectory(tempDir);
        try
        {
            File.WriteAllText(Path.Combine(tempDir, "song1.mp3"), "fake");
            File.WriteAllText(Path.Combine(tempDir, "song2.wav"), "fake");
            File.WriteAllText(Path.Combine(tempDir, "song3.flac"), "fake");
            File.WriteAllText(Path.Combine(tempDir, "readme.txt"), "not a song");
            File.WriteAllText(Path.Combine(tempDir, "image.png"), "not a song");

            var svc = new MusicService();
            svc.SetMusicFolder(tempDir);

            Assert.True(svc.HasSongs);
            Assert.Equal(3, svc.SongCount);
        }
        finally
        {
            Directory.Delete(tempDir, true);
        }
    }

    [Fact]
    public void SetMusicFolder_AllSupportedExtensions()
    {
        var tempDir = Path.Combine(Path.GetTempPath(), "aemeath_music_test_" + Guid.NewGuid().ToString("N"));
        Directory.CreateDirectory(tempDir);
        try
        {
            File.WriteAllText(Path.Combine(tempDir, "a.mp3"), "fake");
            File.WriteAllText(Path.Combine(tempDir, "b.wav"), "fake");
            File.WriteAllText(Path.Combine(tempDir, "c.wma"), "fake");
            File.WriteAllText(Path.Combine(tempDir, "d.m4a"), "fake");
            File.WriteAllText(Path.Combine(tempDir, "e.flac"), "fake");
            File.WriteAllText(Path.Combine(tempDir, "f.aac"), "fake");

            var svc = new MusicService();
            svc.SetMusicFolder(tempDir);

            Assert.Equal(6, svc.SongCount);
        }
        finally
        {
            Directory.Delete(tempDir, true);
        }
    }

    [Fact]
    public void ScanFolder_Rescan_UpdatesCount()
    {
        var tempDir = Path.Combine(Path.GetTempPath(), "aemeath_music_test_" + Guid.NewGuid().ToString("N"));
        Directory.CreateDirectory(tempDir);
        try
        {
            File.WriteAllText(Path.Combine(tempDir, "song1.mp3"), "fake");

            var svc = new MusicService();
            svc.SetMusicFolder(tempDir);
            Assert.Equal(1, svc.SongCount);

            // Add another file and rescan
            File.WriteAllText(Path.Combine(tempDir, "song2.mp3"), "fake");
            svc.ScanFolder();
            Assert.Equal(2, svc.SongCount);
        }
        finally
        {
            Directory.Delete(tempDir, true);
        }
    }

    [Fact]
    public void Stop_WhenNotPlaying_DoesNotThrow()
    {
        var svc = new MusicService();
        svc.Stop(); // Should not throw
        Assert.False(svc.IsPlaying);
    }

    [Fact]
    public void PlayRandom_WithNoSongs_DoesNotThrow()
    {
        var svc = new MusicService();
        svc.PlayRandom(); // No songs, should be no-op
        Assert.False(svc.IsPlaying);
    }

    [Fact]
    public void SetVolume_ClampsValues()
    {
        var svc = new MusicService();
        // Should not throw with extreme values
        svc.SetVolume(-1.0);
        svc.SetVolume(0.0);
        svc.SetVolume(0.5);
        svc.SetVolume(1.0);
        svc.SetVolume(2.0);
    }
}
