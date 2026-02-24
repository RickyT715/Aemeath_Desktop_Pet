namespace AemeathDesktopPet.Models;

/// <summary>
/// A single chat message in the conversation history.
/// </summary>
public class ChatMessage
{
    public string Id { get; set; } = Guid.NewGuid().ToString("N")[..8];
    public string Role { get; set; } = "user"; // "user" or "assistant"
    public string Content { get; set; } = "";
    public DateTime Timestamp { get; set; } = DateTime.UtcNow;
    public bool IsStreaming { get; set; }

    public ChatMessage() { }

    public ChatMessage(string role, string content)
    {
        Role = role;
        Content = content;
    }

    public bool IsUser => Role == "user";
    public bool IsAssistant => Role == "assistant";
}
