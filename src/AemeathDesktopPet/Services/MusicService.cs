using System.IO;
using System.Windows.Media;

namespace AemeathDesktopPet.Services;

/// <summary>
/// Scans a folder for audio files and plays a random song when the pet sings.
/// </summary>
public class MusicService
{
    private static readonly string[] SupportedExtensions =
        { ".mp3", ".wav", ".wma", ".m4a", ".flac", ".aac" };

    private readonly MediaPlayer _player = new();
    private readonly Random _rng = new();
    private string[] _songFiles = Array.Empty<string>();

    public string MusicFolder { get; private set; } = "";
    public bool IsPlaying { get; private set; }
    public string? CurrentSongName { get; private set; }
    public bool HasSongs => _songFiles.Length > 0;
    public int SongCount => _songFiles.Length;

    public event Action? PlaybackEnded;

    public MusicService()
    {
        _player.MediaEnded += (_, _) =>
        {
            IsPlaying = false;
            CurrentSongName = null;
            PlaybackEnded?.Invoke();
        };
    }

    /// <summary>
    /// Sets the music folder and scans for audio files.
    /// </summary>
    public void SetMusicFolder(string path)
    {
        MusicFolder = path;
        ScanFolder();
    }

    /// <summary>
    /// Re-scans the configured music folder for audio files.
    /// </summary>
    public void ScanFolder()
    {
        if (string.IsNullOrEmpty(MusicFolder) || !Directory.Exists(MusicFolder))
        {
            _songFiles = Array.Empty<string>();
            return;
        }

        _songFiles = Directory.GetFiles(MusicFolder)
            .Where(f => SupportedExtensions.Contains(Path.GetExtension(f).ToLowerInvariant()))
            .ToArray();
    }

    /// <summary>
    /// Plays a random song from the music folder.
    /// </summary>
    public void PlayRandom()
    {
        if (_songFiles.Length == 0) return;
        var song = _songFiles[_rng.Next(_songFiles.Length)];
        Play(song);
    }

    /// <summary>
    /// Plays a specific audio file.
    /// </summary>
    public void Play(string filePath)
    {
        Stop();
        try
        {
            _player.Open(new Uri(filePath));
            _player.Play();
            IsPlaying = true;
            CurrentSongName = Path.GetFileNameWithoutExtension(filePath);
        }
        catch
        {
            IsPlaying = false;
            CurrentSongName = null;
        }
    }

    /// <summary>
    /// Stops the currently playing song.
    /// </summary>
    public void Stop()
    {
        if (IsPlaying)
        {
            _player.Stop();
        }
        _player.Close();
        IsPlaying = false;
        CurrentSongName = null;
    }

    public void SetVolume(double volume)
    {
        _player.Volume = Math.Clamp(volume, 0, 1);
    }
}
