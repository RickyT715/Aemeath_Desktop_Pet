using AemeathDesktopPet.Models;

namespace AemeathDesktopPet.Services;

/// <summary>
/// JSON-based conversation memory: stores recent messages and provides context windows.
/// </summary>
public class MemoryService
{
    private readonly JsonPersistenceService _persistence;
    private List<ChatMessage> _messages = new();

    public IReadOnlyList<ChatMessage> Messages => _messages;

    public MemoryService(JsonPersistenceService persistence)
    {
        _persistence = persistence;
    }

    public void Load()
    {
        _messages = _persistence.LoadMessages() ?? new List<ChatMessage>();
    }

    public void Save()
    {
        _persistence.SaveMessages(_messages);
    }

    public void AddMessage(ChatMessage message)
    {
        _messages.Add(message);

        // Keep last 200 messages in memory, trim oldest
        if (_messages.Count > 200)
            _messages.RemoveRange(0, _messages.Count - 200);
    }

    /// <summary>
    /// Returns the most recent N messages for use as AI context.
    /// </summary>
    public IReadOnlyList<ChatMessage> GetContextWindow(int maxMessages = 20)
    {
        int start = Math.Max(0, _messages.Count - maxMessages);
        return _messages.GetRange(start, _messages.Count - start);
    }

    public void Clear()
    {
        _messages.Clear();
    }
}
