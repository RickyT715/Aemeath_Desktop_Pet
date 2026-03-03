using System.Text.Json;
using AemeathDesktopPet.Engine;
using AemeathDesktopPet.Models;

namespace AemeathDesktopPet.Services.McpServer;

/// <summary>
/// MCP server tools that expose Aemeath's pet data and actions.
/// Static references are set during initialization from the main app.
/// Provides tool definitions and execution via the MCP JSON-RPC protocol.
/// </summary>
public static class AemeathPetTools
{
    private static StatsService? _stats;
    private static BehaviorEngine? _behavior;
    private static Action<string>? _sendChat;

    /// <summary>
    /// Initializes tool dependencies. Must be called before any tool invocations.
    /// </summary>
    public static void Initialize(StatsService stats, BehaviorEngine behavior, Action<string>? sendChat = null)
    {
        _stats = stats;
        _behavior = behavior;
        _sendChat = sendChat;
    }

    /// <summary>
    /// Returns the MCP tool definitions for the tools/list response.
    /// </summary>
    public static List<object> GetToolDefinitions() => new()
    {
        new
        {
            name = "get_pet_status",
            description = "Get the pet's current mood, energy, and affection levels",
            inputSchema = new { type = "object", properties = new { } }
        },
        new
        {
            name = "feed_pet",
            description = "Boost the pet's mood by the specified amount (1-100)",
            inputSchema = new
            {
                type = "object",
                properties = new
                {
                    amount = new { type = "integer", description = "Amount to boost mood (1-100)", @default = 10 }
                }
            }
        },
        new
        {
            name = "play_animation",
            description = "Make the pet perform a specific animation: wave, laugh, sing, fly, sleep, happy",
            inputSchema = new
            {
                type = "object",
                properties = new
                {
                    animation = new { type = "string", description = "Animation name" }
                },
                required = new[] { "animation" }
            }
        },
        new
        {
            name = "send_message",
            description = "Send a message to the pet's chat",
            inputSchema = new
            {
                type = "object",
                properties = new
                {
                    message = new { type = "string", description = "Message to send" }
                },
                required = new[] { "message" }
            }
        }
    };

    /// <summary>
    /// Executes a tool by name and returns the result as a JSON string.
    /// </summary>
    public static string ExecuteTool(string toolName, JsonElement? arguments)
    {
        return toolName switch
        {
            "get_pet_status" => GetPetStatus(),
            "feed_pet" => FeedPet(arguments),
            "play_animation" => PlayAnimation(arguments),
            "send_message" => SendMessage(arguments),
            _ => JsonSerializer.Serialize(new { error = $"Unknown tool: {toolName}" })
        };
    }

    private static string GetPetStatus()
    {
        if (_stats == null)
            return JsonSerializer.Serialize(new { error = "Not initialized" });

        var s = _stats.Stats;
        return JsonSerializer.Serialize(new
        {
            mood = s.Mood,
            energy = s.Energy,
            affection = s.Affection,
            days_together = s.DaysTogether,
            total_chats = s.TotalChats,
            total_pets = s.TotalPets,
            total_songs = s.TotalSongs
        });
    }

    private static string FeedPet(JsonElement? arguments)
    {
        if (_stats == null)
            return JsonSerializer.Serialize(new { error = "Not initialized" });

        int amount = 10;
        if (arguments?.TryGetProperty("amount", out var amountProp) == true)
            amount = amountProp.GetInt32();

        amount = Math.Clamp(amount, 1, 100);
        _stats.Stats.Adjust(StatType.Mood, amount);
        _stats.Stats.Adjust(StatType.Affection, amount / 3.0);

        return JsonSerializer.Serialize(new
        {
            status = "ok",
            mood = _stats.Stats.Mood,
            affection = _stats.Stats.Affection,
            boosted_by = amount
        });
    }

    private static string PlayAnimation(JsonElement? arguments)
    {
        if (_behavior == null)
            return JsonSerializer.Serialize(new { error = "Not initialized" });

        var animation = arguments?.GetProperty("animation").GetString() ?? "";

        var state = animation.ToLowerInvariant() switch
        {
            "wave" => PetState.Wave,
            "laugh" => PetState.Laugh,
            "sing" => PetState.Sing,
            "fly" or "flyright" => PetState.FlyRight,
            "flyleft" => PetState.FlyLeft,
            "sleep" => PetState.Sleep,
            "happy" => PetState.PetHappy,
            "sigh" => PetState.Sigh,
            _ => (PetState?)null
        };

        if (state == null)
            return JsonSerializer.Serialize(new { error = $"Unknown animation: {animation}" });

        _behavior.ForceState(state.Value, 3.0);
        return JsonSerializer.Serialize(new { status = "ok", animation, state = state.Value.ToString() });
    }

    private static string SendMessage(JsonElement? arguments)
    {
        if (_sendChat == null)
            return JsonSerializer.Serialize(new { error = "Chat not available" });

        var message = arguments?.GetProperty("message").GetString() ?? "";
        _sendChat(message);
        return JsonSerializer.Serialize(new { status = "ok", message_sent = message });
    }
}
