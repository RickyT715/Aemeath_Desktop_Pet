using System.Net.Http;
using System.Text;
using System.Text.Json;
using AemeathDesktopPet.Models;

namespace AemeathDesktopPet.Services;

/// <summary>
/// Bridge between C# frontend and Python memory backend.
/// Assembles MemoryContext for AI calls, submits data for extraction and distillation.
/// Falls back to local-only mode when Python backend is unavailable.
/// </summary>
public class MemoryBridgeService
{
    private static readonly JsonSerializerOptions JsonOpts = new()
    {
        PropertyNamingPolicy = JsonNamingPolicy.SnakeCaseLower,
    };

    private readonly CoreMemoryService _coreMemory;
    private readonly ProceduralMemoryService _proceduralMemory;
    private readonly ObservationBufferService _observationBuffer;
    private readonly BackendProcessManager? _backend;
    private readonly HttpMessageHandler? _httpHandler;
    private readonly HttpClient _http;

    // Cached episodic memories from last Python retrieval
    private List<string> _cachedEpisodicMemories = new();

    public MemoryBridgeService(
        CoreMemoryService coreMemory,
        ProceduralMemoryService proceduralMemory,
        ObservationBufferService observationBuffer,
        BackendProcessManager? backend,
        HttpMessageHandler? httpHandler = null)
    {
        _coreMemory = coreMemory;
        _proceduralMemory = proceduralMemory;
        _observationBuffer = observationBuffer;
        _backend = backend;
        _httpHandler = httpHandler;
        _http = CreateHttpClient(TimeSpan.FromMilliseconds(500));
    }

    private HttpClient CreateHttpClient(TimeSpan timeout)
    {
        var client = _httpHandler != null
            ? new HttpClient(_httpHandler, disposeHandler: false)
            : new HttpClient();
        client.Timeout = timeout;
        return client;
    }

    /// <summary>
    /// Assembles a complete MemoryContext for injection into the system prompt.
    /// Local reads are instant; Python episodic retrieval has a 500ms timeout.
    /// Target: &lt;200ms total.
    /// </summary>
    public async Task<MemoryContext> GetMemoryContextAsync(string userMessage)
    {
        var context = new MemoryContext();

        // 1. Always: load core memory (local, instant)
        var core = _coreMemory.Current;
        context.UserName = core.UserProfile.Name;
        context.CommunicationStyle = core.Personality.CommunicationStyle;
        context.RelationshipStage = core.Relationship.Stage;
        context.DaysTogether = core.Relationship.DaysTogether;

        // Collect user facts from profile
        var facts = new List<string>();
        if (!string.IsNullOrEmpty(core.UserProfile.Occupation))
            facts.Add($"Occupation: {core.UserProfile.Occupation}");
        if (!string.IsNullOrEmpty(core.UserProfile.AgeRange))
            facts.Add($"Age range: {core.UserProfile.AgeRange}");
        if (core.UserProfile.Languages.Count > 0)
            facts.Add($"Languages: {string.Join(", ", core.UserProfile.Languages)}");
        facts.AddRange(core.UserProfile.KeyFacts);
        context.UserFacts = facts;

        // Collect preferences from personality
        context.Preferences = core.Personality.Interests.ToList();

        // 2. Always: check procedural memory for upcoming events (local, instant)
        var upcoming = _proceduralMemory.GetUpcomingEvents();
        context.UpcomingEvents = upcoming
            .Select(FormatEvent)
            .ToList();

        // 3. Get recent observations from buffer (local, instant)
        var pendingObs = _observationBuffer.GetPending();
        if (pendingObs.Count > 0)
        {
            context.Observations = pendingObs
                .OrderByDescending(o => o.Timestamp)
                .Take(5)
                .Select(o => $"[{o.Source}] {o.Content}")
                .ToList();
        }

        // 4. If Python available: semantic retrieval of relevant episodic memories
        if (_backend is { IsReady: true } && !string.IsNullOrWhiteSpace(userMessage))
        {
            try
            {
                var url = $"http://localhost:{_backend.Port}/memory/retrieve?q={Uri.EscapeDataString(userMessage)}&top_k=3";
                var response = await _http.GetAsync(url);
                if (response.IsSuccessStatusCode)
                {
                    var json = await response.Content.ReadAsStringAsync();
                    var doc = JsonDocument.Parse(json);
                    if (doc.RootElement.TryGetProperty("memories", out var memories))
                    {
                        var retrieved = new List<string>();
                        foreach (var mem in memories.EnumerateArray())
                        {
                            var content = mem.GetProperty("content").GetString() ?? "";
                            if (!string.IsNullOrEmpty(content))
                                retrieved.Add(content);
                        }
                        _cachedEpisodicMemories = retrieved;
                    }
                }
            }
            catch
            {
                // Timeout or error — use cached episodic memories
            }
        }

        context.RecentTopics = _cachedEpisodicMemories.Take(5).ToList();

        return context;
    }

    /// <summary>
    /// Fire-and-forget: submits a conversation turn to Python for memory extraction.
    /// Does not block the chat response.
    /// </summary>
    public async Task SubmitForExtraction(string userMessage, string assistantResponse)
    {
        if (_backend is not { IsReady: true })
            return;

        try
        {
            var payload = new
            {
                user_message = userMessage,
                assistant_response = assistantResponse
            };
            var content = new StringContent(
                JsonSerializer.Serialize(payload, JsonOpts),
                Encoding.UTF8,
                "application/json");

            // Use a longer timeout for extraction (background work)
            using var extractHttp = CreateHttpClient(TimeSpan.FromSeconds(10));
            await extractHttp.PostAsync(
                $"http://localhost:{_backend.Port}/memory/extract", content);
        }
        catch
        {
            // Non-critical — extraction failure is silent
        }
    }

    /// <summary>
    /// Submits pending observations to Python for distillation into episodic memories.
    /// Called periodically (every 30 minutes) by a timer.
    /// </summary>
    public async Task SubmitObservationsAsync()
    {
        if (_backend is not { IsReady: true })
            return;

        var pending = _observationBuffer.GetPending();
        if (pending.Count == 0)
            return;

        try
        {
            var payload = new
            {
                observations = pending.Select(o => new
                {
                    id = o.Id,
                    timestamp = o.Timestamp,
                    source = o.Source,
                    content = o.Content,
                    activity_context = o.ActivityContext
                }).ToList()
            };

            var content = new StringContent(
                JsonSerializer.Serialize(payload, JsonOpts),
                Encoding.UTF8,
                "application/json");

            using var distillHttp = CreateHttpClient(TimeSpan.FromSeconds(15));
            var response = await distillHttp.PostAsync(
                $"http://localhost:{_backend.Port}/memory/distill", content);

            if (response.IsSuccessStatusCode)
            {
                // Clear the processed observations
                var processedIds = pending.Select(o => o.Id).ToList();
                _observationBuffer.ClearProcessed(processedIds);
            }
        }
        catch
        {
            // Non-critical — will retry next cycle
        }
    }

    /// <summary>
    /// Reloads core and procedural memory from disk.
    /// Call after Python backend updates local files.
    /// </summary>
    public void ReloadLocalMemory()
    {
        _coreMemory.Load();
        _proceduralMemory.Load();
    }

    private static string FormatEvent(ScheduledEvent ev)
    {
        if (DateTime.TryParse(ev.Date, System.Globalization.CultureInfo.InvariantCulture,
                System.Globalization.DateTimeStyles.None, out var eventDate))
        {
            var diff = (eventDate.Date - DateTime.UtcNow.Date).Days;
            var daysUntil = diff switch
            {
                0 => "(today)",
                1 => "(tomorrow)",
                _ => $"(in {diff} days)"
            };
            return $"{ev.Event}: {ev.Date} {daysUntil}";
        }
        return $"{ev.Event}: {ev.Date}";
    }
}
