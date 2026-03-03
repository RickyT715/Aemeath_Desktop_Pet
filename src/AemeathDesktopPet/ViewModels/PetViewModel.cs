using System.ComponentModel;
using System.Runtime.CompilerServices;
using System.Windows;
using System.Windows.Media.Imaging;
using AemeathDesktopPet.Engine;
using AemeathDesktopPet.Models;
using AemeathDesktopPet.Services;

namespace AemeathDesktopPet.ViewModels;

/// <summary>
/// Main ViewModel — orchestrates all engines, services, and user interactions.
/// </summary>
public class PetViewModel : INotifyPropertyChanged
{
    // Existing engines
    private readonly AnimationEngine _animation;
    private readonly BehaviorEngine _behavior;
    private readonly PhysicsEngine _physics;
    private readonly EnvironmentDetector _environment;
    private readonly ConfigService _config;
    private readonly MusicService _music;

    // New engines
    private readonly GlitchEffect _glitch;
    private readonly ParticleSystem _particles;
    private readonly PaperPlaneSystem _paperPlanes;
    private readonly CatBehaviorEngine _catBehavior;
    private readonly WindowEdgeManager _windowEdge;

    // New services
    private readonly JsonPersistenceService _persistence;
    private readonly StatsService _stats;
    private readonly MemoryService _memory;
    private IChatService _chat;
    private ITtsService _tts;
    private readonly IScreenAwarenessService _screenAwareness;

    // Voice input services
    private readonly VoiceInputService _voiceInput;
    private ISpeechToTextService? _stt;
    private readonly GlobalHotkeyService _globalHotkey;

    // Pomodoro integration
    private readonly PomodoroIntegrationService? _pomodoroIntegration;

    // Activity monitor
    private readonly ActivityMonitorService _activityMonitor;

    // Backend integration
    private BackendProcessManager? _backendManager;
    private InternalApiServer? _internalApi;

    // Bindable properties
    private BitmapSource? _currentFrame;
    private double _petX;
    private double _petY;
    private int _spriteSize = 200;
    private double _opacity = 1.0;
    private bool _isDragging;

    public BitmapSource? CurrentFrame
    {
        get => _currentFrame;
        set { _currentFrame = value; OnPropertyChanged(); }
    }

    public double PetX
    {
        get => _petX;
        set { _petX = value; OnPropertyChanged(); }
    }

    public double PetY
    {
        get => _petY;
        set { _petY = value; OnPropertyChanged(); }
    }

    public int SpriteSize
    {
        get => _spriteSize;
        set { _spriteSize = value; OnPropertyChanged(); }
    }

    public double PetOpacity
    {
        get => _opacity;
        set { _opacity = value; OnPropertyChanged(); }
    }

    // Public accessors for View layer
    public PetState CurrentState => _behavior.CurrentState;
    public ConfigService Config => _config;
    public MusicService Music => _music;
    public StatsService Stats => _stats;
    public MemoryService Memory => _memory;
    public IChatService Chat => _chat;
    public ITtsService Tts => _tts;
    public GlitchEffect Glitch => _glitch;
    public ParticleSystem Particles => _particles;
    public PaperPlaneSystem PaperPlanes => _paperPlanes;
    public CatBehaviorEngine CatBehavior => _catBehavior;
    public WindowEdgeManager WindowEdge => _windowEdge;
    public VoiceInputService VoiceInput => _voiceInput;
    public ISpeechToTextService? Stt => _stt;
    public GlobalHotkeyService GlobalHotkey => _globalHotkey;
    public PomodoroIntegrationService? PomodoroIntegration => _pomodoroIntegration;
    public ActivityMonitorService ActivityMonitor => _activityMonitor;
    public IScreenAwarenessService ScreenAwareness => _screenAwareness;
    public BehaviorEngine Behavior => _behavior;
    public AemeathStats CurrentStats => _stats.Stats;
    public BackendProcessManager? BackendManager => _backendManager;

    public PetViewModel()
    {
        _config = new ConfigService();
        _config.Load();

        _animation = new AnimationEngine();
        _behavior = new BehaviorEngine();
        _physics = new PhysicsEngine();
        _environment = new EnvironmentDetector();
        _music = new MusicService();

        // New engines
        _glitch = new GlitchEffect { IsEnabled = _config.Config.EnableGlitchEffect };
        _particles = new ParticleSystem();
        _paperPlanes = new PaperPlaneSystem { EnableAmbient = _config.Config.EnableAmbientPaperPlanes };
        _catBehavior = new CatBehaviorEngine();
        _windowEdge = new WindowEdgeManager(_environment);

        // New services
        _persistence = new JsonPersistenceService();
        _stats = new StatsService(_persistence);
        _memory = new MemoryService(_persistence);
        _chat = CreateChatService();
        _tts = new TtsVoiceService(() => _config.Config.Tts, _environment);
        _screenAwareness = new ScreenAwarenessService(
            () => _config.Config.ScreenAwareness,
            () => _stats.Stats,
            () => _config.Config.CatName,
            _environment);

        // Voice input
        _voiceInput = new VoiceInputService();
        _stt = CreateSttService();
        _globalHotkey = new GlobalHotkeyService();

        // Pomodoro integration
        if (_config.Config.PomodoroIntegration.Enabled)
            _pomodoroIntegration = new PomodoroIntegrationService(
                _config.Config.PomodoroIntegration.PipeName,
                System.Windows.Threading.Dispatcher.CurrentDispatcher);

        // Activity monitor
        _activityMonitor = new ActivityMonitorService(() => _config.Config.ActivityMonitor);

        SpriteSize = _config.Config.PetSize;
        PetOpacity = _config.Config.Opacity;
        _physics.SpriteSize = SpriteSize;

        // Initialize music folder from config
        if (!string.IsNullOrEmpty(_config.Config.MusicFolderPath))
            _music.SetMusicFolder(_config.Config.MusicFolderPath);

        WireUpEvents();
    }

    public void Initialize()
    {
        // Pre-load all GIF frames
        _animation.PreloadAll();

        // Load stats
        _stats.Load();

        // Set up screen bounds
        var workArea = _environment.GetWorkArea();
        _physics.UpdateBounds(workArea);

        // Restore last position or center
        if (_config.Config.LastX >= 0 && _config.Config.LastY >= 0)
        {
            _physics.X = _config.Config.LastX;
            _physics.Y = _config.Config.LastY;
        }
        else
        {
            _physics.X = workArea.Width / 2 - SpriteSize / 2;
            _physics.Y = workArea.Height - SpriteSize - 50;
        }

        PetX = _physics.X;
        PetY = _physics.Y;

        // Initialize cat position near Aemeath
        _catBehavior.CatX = PetX + 60;
        _catBehavior.CatY = PetY + 30;

        // Feed stats context to behavior engine
        _behavior.SetStatsContext(_stats.Stats.Mood, _stats.Stats.Energy);

        // Start all engines
        _physics.Start();
        _behavior.Start();
        _glitch.Start();
        _particles.Start();
        _paperPlanes.Start();
        _stats.Start();

        if (_config.Config.EnableBlackCat)
            _catBehavior.Start();

        _windowEdge.Start();

        _pomodoroIntegration?.Start();

        if (_screenAwareness.IsEnabled)
            _screenAwareness.Start();

        // Start backend if enabled
        if (_config.Config.Backend.Enabled)
        {
            _internalApi = new InternalApiServer(
                _config.Config.Backend.InternalPort,
                _stats,
                _music,
                _behavior,
                _pomodoroIntegration);
            _internalApi.StartAsync();

            _backendManager = new BackendProcessManager(_config.Config.Backend);
            _backendManager.BackendReady += (_, _) =>
            {
                // Recreate chat service to use backend agent
                _chat = CreateChatService();
                _stt = CreateSttService();
            };
            _ = _backendManager.StartAsync();
        }
    }

    public void Shutdown()
    {
        _screenAwareness.Stop();
        _tts.Stop();
        if (_tts is IDisposable disposableTts)
            disposableTts.Dispose();
        _music.Stop();
        _physics.Stop();
        _behavior.Stop();
        _animation.Stop();
        _glitch.Stop();
        _particles.Stop();
        _paperPlanes.Stop();
        _catBehavior.Stop();
        _windowEdge.Stop();
        _stats.Stop();
        _memory.Save();
        _config.SavePosition(_physics.X, _physics.Y);
        _globalHotkey.Dispose();
        _voiceInput.Dispose();
        _pomodoroIntegration?.Dispose();

        // Stop backend
        if (_backendManager != null)
        {
            _backendManager.StopAsync().GetAwaiter().GetResult();
            _backendManager.Dispose();
        }
        _internalApi?.Dispose();
    }

    /// <summary>
    /// Reloads settings from config after Settings window saves.
    /// </summary>
    public void ApplySettings()
    {
        SpriteSize = _config.Config.PetSize;
        PetOpacity = _config.Config.Opacity;
        _physics.SpriteSize = SpriteSize;
        _glitch.IsEnabled = _config.Config.EnableGlitchEffect;
        _paperPlanes.EnableAmbient = _config.Config.EnableAmbientPaperPlanes;

        // Recreate chat service if provider changed
        _chat = CreateChatService();

        // Recreate TTS provider if provider changed
        if (_tts is TtsVoiceService ttsVoice)
            ttsVoice.RecreateProvider();
        _tts.SetVolume(_config.Config.Tts.Volume);

        // Recreate STT service
        _stt = CreateSttService();

        // Restart screen awareness if settings changed
        _screenAwareness.Stop();
        if (_screenAwareness.IsEnabled)
            _screenAwareness.Start();

        // Reconfigure global hotkey
        if (_config.Config.VoiceInput.Enabled)
        {
            _globalHotkey.Configure(_config.Config.VoiceInput.Hotkey);
            _globalHotkey.Start();
        }
        else
        {
            _globalHotkey.Stop();
        }

        // Sync config to backend if running
        if (_backendManager is { IsReady: true })
        {
            _ = Task.Run(async () =>
            {
                try
                {
                    using var http = new System.Net.Http.HttpClient { Timeout = TimeSpan.FromSeconds(5) };
                    var json = System.Text.Json.JsonSerializer.Serialize(new { status = "sync" });
                    await http.PostAsync(
                        $"http://localhost:{_backendManager.Port}/config/sync",
                        new System.Net.Http.StringContent(json, System.Text.Encoding.UTF8, "application/json"));
                }
                catch { /* Backend may not be ready */ }
            });
        }
    }

    private IChatService CreateChatService()
    {
        // Three-tier fallback: Backend agent > Cloud API > Offline
        if (_backendManager is { IsReady: true })
            return new BackendAgentService(_backendManager, () => _stats.Stats);

        return _config.Config.AiProvider switch
        {
            "gemini" => new GeminiApiService(() => _config.Config, () => _stats.Stats),
            "proxy" => new ProxyApiService(() => _config.Config, () => _stats.Stats),
            _ => new ClaudeApiService(() => _config.Config, () => _stats.Stats),
        };
    }

    private ISpeechToTextService? CreateSttService()
    {
        var vi = _config.Config.VoiceInput;
        if (!vi.Enabled) return null;

        // If backend is ready, use its STT endpoint
        if (_backendManager is { IsReady: true })
            return new BackendSttService(_backendManager);

        return vi.SttProvider switch
        {
            "gemini" => new GeminiSttService(() => _config.Config.GeminiApiKey),
            _ => new WhisperSttService(() => vi.SttApiKey),
        };
    }

    // --- User Interactions ---

    public void OnLeftClick()
    {
        if (_isDragging) return;
        _behavior.ForceState(PetState.Wave, 1.5);
        _stats.OnPetted();
        _particles.Emit(ParticleType.Heart, PetX + SpriteSize / 2, PetY, 2);
    }

    public void OnPetHappy()
    {
        if (_isDragging) return;
        _behavior.ForceState(PetState.PetHappy, 1.5);
        _stats.OnPetted();
        _particles.Emit(ParticleType.Sparkle, PetX + SpriteSize / 2, PetY, 3);
    }

    public void OnDragStart()
    {
        _isDragging = true;
        _behavior.ForceState(PetState.Drag);
        _physics.IsDragging = true;
        _physics.IsGravityActive = false;
        _physics.IsFlying = false;
        _physics.VelocityX = 0;
        _physics.VelocityY = 0;
        _catBehavior.OnAemeathDragged();
    }

    public void OnDragMove(double newX, double newY)
    {
        if (!_isDragging) return;

        double minX = _physics.ScreenBounds.Left;
        double maxX = _physics.ScreenBounds.Right - SpriteSize;
        double minY = _physics.ScreenBounds.Top;
        double maxY = _physics.ScreenBounds.Bottom - SpriteSize;

        if (maxX >= minX) newX = Math.Clamp(newX, minX, maxX);
        if (maxY >= minY) newY = Math.Clamp(newY, minY, maxY);

        _physics.X = newX;
        _physics.Y = newY;
        PetX = newX;
        PetY = newY;
    }

    public void OnDragEnd()
    {
        if (!_isDragging) return;
        _isDragging = false;
        _physics.EndDrag();
        _behavior.ForceState(PetState.Idle);
    }

    // --- Music ---

    public void OnSingRequested()
    {
        _behavior.ForceState(PetState.Sing, 15.0);
        _stats.OnSang();
        _particles.Emit(ParticleType.MusicNote, PetX + SpriteSize / 2, PetY, 3);
    }

    // --- New interactions ---

    public void OnChatRequested()
    {
        _behavior.ForceState(PetState.Chat, 60.0); // long duration, user-driven
    }

    public void OnChatClosed()
    {
        if (_behavior.CurrentState == PetState.Chat)
            _behavior.ForceState(PetState.Idle);
    }

    public void OnPaperPlaneRequested()
    {
        _behavior.ForceState(PetState.PaperPlane, 2.0);
        var bounds = _environment.GetWorkArea();
        _paperPlanes.ThrowPlane(PetX + SpriteSize / 2, PetY, bounds);
        _stats.OnPaperPlaneThrown();
    }

    public void OnCallCat()
    {
        if (!_config.Config.EnableBlackCat) return;
        _catBehavior.OnAemeathMoved(PetX, PetY);
    }

    public void OnStatsRequested()
    {
        // Handled by View layer — opens StatsPopup
    }

    /// <summary>
    /// Gets a speech bubble text for idle chatter or AI response.
    /// </summary>
    public string GetIdleBubbleText()
    {
        return OfflineResponses.GetContextual(_stats.Stats, DateTime.Now);
    }

    // --- Internal event wiring ---

    private void WireUpEvents()
    {
        _animation.FrameChanged += frame =>
        {
            CurrentFrame = frame;
        };

        _animation.AnimationCompleted += () =>
        {
            var state = _behavior.CurrentState;
            if (state is PetState.Wave or PetState.PetHappy or PetState.Landing
                or PetState.PaperPlane or PetState.PetCat)
            {
                _behavior.ForceState(PetState.Idle);
            }
        };

        _behavior.StateChanged += (state, anim) =>
        {
            _animation.Play(anim);
            HandleStatePhysics(state);
            HandleStateMusic(state);
            HandleStateParticles(state);
        };

        _physics.PositionChanged += () =>
        {
            PetX = _physics.X;
            PetY = _physics.Y;
            _catBehavior.OnAemeathMoved(PetX, PetY);
            _windowEdge.Update(PetX, PetY, SpriteSize);
        };

        _physics.HitGround += () =>
        {
            _behavior.ForceState(PetState.Landing, 1.0);
            _catBehavior.OnAemeathLanded();
        };

        _physics.HitScreenEdge += () =>
        {
            if (_behavior.CurrentState == PetState.FlyRight)
                _behavior.ForceState(PetState.FlyLeft, 4.0);
            else if (_behavior.CurrentState == PetState.FlyLeft)
                _behavior.ForceState(PetState.FlyRight, 4.0);
        };

        _music.PlaybackEnded += () =>
        {
            if (_behavior.CurrentState == PetState.Sing)
                _behavior.ForceState(PetState.Idle);
        };

        // Glitch triggers cat startled
        _glitch.GlitchStarted += () =>
        {
            _catBehavior.OnAemeathGlitched();
        };

        // Paper plane landing triggers cat chase
        _paperPlanes.PlaneLanded += landingX =>
        {
            _catBehavior.OnPaperPlaneLanded(landingX);
        };

        // Stats changes update behavior weights
        _stats.StatsChanged += () =>
        {
            _behavior.SetStatsContext(_stats.Stats.Mood, _stats.Stats.Energy);
        };

        // Window edge: perched window closed -> fall
        _windowEdge.PerchedWindowClosed += () =>
        {
            _behavior.ForceState(PetState.Fall);
            _physics.IsGravityActive = true;
            _physics.IsFlying = false;
        };
    }

    private void HandleStatePhysics(PetState state)
    {
        switch (state)
        {
            case PetState.FlyRight:
                _physics.StartFlying(1);
                break;
            case PetState.FlyLeft:
                _physics.StartFlying(-1);
                break;
            case PetState.Fall:
            case PetState.Thrown:
                _physics.IsGravityActive = true;
                _physics.IsFlying = false;
                break;
            case PetState.Idle:
            case PetState.Wave:
            case PetState.Laugh:
            case PetState.Sigh:
            case PetState.Sing:
            case PetState.Landing:
            case PetState.PetHappy:
            case PetState.PlayGame:
            case PetState.PaperPlane:
            case PetState.Sleep:
            case PetState.LookAtUser:
            case PetState.Chat:
            case PetState.CatLap:
            case PetState.PetCat:
            case PetState.Speaking:
            case PetState.ScreenComment:
            case PetState.Glitch:
                _physics.StopFlying();
                break;
            // Window edge states: keep current physics (position-driven)
            case PetState.PeekEdge:
            case PetState.LieOnWindow:
            case PetState.HideTaskbar:
            case PetState.ClingEdge:
                _physics.StopFlying();
                break;
        }
    }

    private void HandleStateMusic(PetState state)
    {
        if (state == PetState.Sing && _music.HasSongs)
        {
            _music.PlayRandom();
        }
        else if (state != PetState.Sing && _music.IsPlaying)
        {
            _music.Stop();
        }
    }

    private void HandleStateParticles(PetState state)
    {
        double cx = PetX + SpriteSize / 2;
        double cy = PetY;

        switch (state)
        {
            case PetState.Sing:
                _particles.Emit(ParticleType.MusicNote, cx, cy, 2);
                break;
            case PetState.Sleep:
                _particles.Emit(ParticleType.SleepZ, cx, cy, 1);
                break;
            case PetState.PetHappy:
            case PetState.Laugh:
                _particles.Emit(ParticleType.Sparkle, cx, cy, 2);
                break;
            case PetState.PetCat:
                _particles.Emit(ParticleType.PawPrint, cx, cy + SpriteSize, 2);
                break;
        }
    }

    // --- INotifyPropertyChanged ---

    public event PropertyChangedEventHandler? PropertyChanged;

    protected void OnPropertyChanged([CallerMemberName] string? name = null)
    {
        PropertyChanged?.Invoke(this, new PropertyChangedEventArgs(name));
    }
}
