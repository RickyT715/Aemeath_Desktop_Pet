using System.Net;
using System.Net.Http;
using System.Text;
using System.Text.Json;
using AemeathDesktopPet.Models;
using AemeathDesktopPet.Services;

namespace AemeathDesktopPet.Tests.Contract;

/// <summary>
/// Contract tests verifying C#-Python JSON serialization compatibility.
/// Ensures field names match Pydantic model expectations (snake_case).
/// </summary>
public class MemoryContractTests
{
    private static readonly JsonSerializerOptions JsonOpts = new()
    {
        PropertyNamingPolicy = JsonNamingPolicy.SnakeCaseLower,
    };

    [Fact]
    public void ExtractionPayload_SerializesTo_SnakeCaseFields()
    {
        var payload = new { user_message = "Hello", assistant_response = "Hi there" };
        var json = JsonSerializer.Serialize(payload, JsonOpts);

        Assert.Contains("\"user_message\"", json);
        Assert.Contains("\"assistant_response\"", json);
    }

    [Fact]
    public void ExtractionPayload_DoesNotContain_CamelCaseFields()
    {
        var payload = new { user_message = "Hello", assistant_response = "Hi there" };
        var json = JsonSerializer.Serialize(payload, JsonOpts);

        Assert.DoesNotContain("\"userMessage\"", json);
        Assert.DoesNotContain("\"assistantResponse\"", json);
    }

    [Fact]
    public void DistillPayload_ObservationFields_MatchPydantic()
    {
        // Simulating what MemoryBridgeService.SubmitObservationsAsync serializes
        var payload = new
        {
            observations = new[]
            {
                new
                {
                    id = "obs-1",
                    timestamp = "2026-03-03T10:00:00Z",
                    source = "screen",
                    content = "VS Code open",
                    activity_context = "StudyingCoding"
                }
            }
        };
        var json = JsonSerializer.Serialize(payload, JsonOpts);

        Assert.Contains("\"activity_context\"", json);
        Assert.Contains("\"observations\"", json);
    }

    [Fact]
    public void DistillPayload_DoesNotContain_CamelCaseActivityContext()
    {
        var payload = new
        {
            observations = new[]
            {
                new { id = "1", timestamp = "t", source = "s", content = "c", activity_context = "Default" }
            }
        };
        var json = JsonSerializer.Serialize(payload, JsonOpts);

        Assert.DoesNotContain("\"activityContext\"", json);
    }

    [Fact]
    public void RetrievalResponse_ParsesFromPythonFormat()
    {
        // Python returns: {"memories": [{"content": "...", "type": "fact", "created_at": "...", "importance": 0.8}]}
        var pythonJson = """{"memories": [{"content": "User likes gaming", "type": "fact", "created_at": "2026-03-01T00:00:00Z", "importance": 0.8}]}""";

        var doc = JsonDocument.Parse(pythonJson);
        Assert.True(doc.RootElement.TryGetProperty("memories", out var memories));
        Assert.Equal(1, memories.GetArrayLength());

        var first = memories[0];
        Assert.Equal("User likes gaming", first.GetProperty("content").GetString());
        Assert.Equal("fact", first.GetProperty("type").GetString());
    }

    [Fact]
    public void RetrievalResponse_EmptyMemoriesList_ParsesCorrectly()
    {
        var pythonJson = """{"memories": []}""";
        var doc = JsonDocument.Parse(pythonJson);

        Assert.True(doc.RootElement.TryGetProperty("memories", out var memories));
        Assert.Equal(0, memories.GetArrayLength());
    }

    [Fact]
    public void MemoryBridgeService_JsonOpts_UsesSnakeCaseLower()
    {
        // Verify via reflection that the service's static JsonOpts uses SnakeCaseLower
        var field = typeof(MemoryBridgeService).GetField("JsonOpts",
            System.Reflection.BindingFlags.NonPublic | System.Reflection.BindingFlags.Static);
        Assert.NotNull(field);

        var opts = field!.GetValue(null) as JsonSerializerOptions;
        Assert.NotNull(opts);
        Assert.Equal(JsonNamingPolicy.SnakeCaseLower, opts!.PropertyNamingPolicy);
    }
}
