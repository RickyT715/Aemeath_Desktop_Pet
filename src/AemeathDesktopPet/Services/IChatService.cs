using AemeathDesktopPet.Models;

namespace AemeathDesktopPet.Services;

/// <summary>
/// Interface for AI chat service (Claude/Gemini API or offline fallback).
/// </summary>
public interface IChatService
{
    bool IsAvailable { get; }

    Task<string> SendMessageAsync(string userMessage, IReadOnlyList<ChatMessage> history);

    IAsyncEnumerable<string> StreamMessageAsync(string userMessage, IReadOnlyList<ChatMessage> history);

    /// <summary>
    /// Sends a message with an optional screenshot attachment.
    /// Default implementation ignores the screenshot.
    /// </summary>
    Task<string> SendMessageAsync(string userMessage, IReadOnlyList<ChatMessage> history, byte[]? screenshot)
        => SendMessageAsync(userMessage, history);

    /// <summary>
    /// Streams a message with an optional screenshot attachment.
    /// Default implementation ignores the screenshot.
    /// </summary>
    IAsyncEnumerable<string> StreamMessageAsync(string userMessage, IReadOnlyList<ChatMessage> history, byte[]? screenshot)
        => StreamMessageAsync(userMessage, history);
}
