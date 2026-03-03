using System.Diagnostics;
using System.IO;
using System.Text;
using System.Text.Json;
using AemeathDesktopPet.Models;

namespace AemeathDesktopPet.Services;

/// <summary>
/// Manages connections to external MCP servers via JSON-RPC over stdio.
/// Uses the MCP wire protocol directly for tool discovery and invocation.
/// </summary>
public class McpClientService : IDisposable
{
    private readonly Dictionary<string, McpConnection> _connections = new();
    private int _requestId;
    private bool _disposed;

    /// <summary>
    /// Connects to an MCP server by launching its process.
    /// </summary>
    public async Task ConnectAsync(McpServerDefinition server)
    {
        if (_connections.ContainsKey(server.Id))
            await DisconnectAsync(server.Id);

        var psi = new ProcessStartInfo
        {
            FileName = server.Command,
            Arguments = server.Arguments,
            UseShellExecute = false,
            RedirectStandardInput = true,
            RedirectStandardOutput = true,
            RedirectStandardError = true,
            CreateNoWindow = true
        };

        var process = Process.Start(psi);
        if (process == null)
            throw new InvalidOperationException($"Failed to start MCP server: {server.Name}");

        var conn = new McpConnection(server.Id, server.Name, process);
        _connections[server.Id] = conn;

        // Send initialize request
        await SendRequestAsync(conn, "initialize", new
        {
            protocolVersion = "2024-11-05",
            capabilities = new { },
            clientInfo = new { name = "AemeathDesktopPet", version = "1.0.0" }
        });

        // Send initialized notification
        await SendNotificationAsync(conn, "notifications/initialized", null);
    }

    /// <summary>
    /// Disconnects from a specific MCP server.
    /// </summary>
    public async Task DisconnectAsync(string serverId)
    {
        if (_connections.TryGetValue(serverId, out var conn))
        {
            _connections.Remove(serverId);
            conn.Dispose();
            await Task.CompletedTask;
        }
    }

    /// <summary>
    /// Lists all tools available on the specified MCP server.
    /// </summary>
    public async Task<List<McpToolInfo>> ListToolsAsync(string serverId)
    {
        if (!_connections.TryGetValue(serverId, out var conn))
            return new List<McpToolInfo>();

        var response = await SendRequestAsync(conn, "tools/list", new { });
        var tools = new List<McpToolInfo>();

        if (response.TryGetProperty("result", out var result) &&
            result.TryGetProperty("tools", out var toolsArray))
        {
            foreach (var tool in toolsArray.EnumerateArray())
            {
                tools.Add(new McpToolInfo
                {
                    Name = tool.GetProperty("name").GetString() ?? "",
                    Description = tool.TryGetProperty("description", out var desc)
                        ? desc.GetString() ?? ""
                        : ""
                });
            }
        }

        return tools;
    }

    /// <summary>
    /// Calls a tool on the specified MCP server.
    /// </summary>
    public async Task<string> CallToolAsync(
        string serverId,
        string toolName,
        Dictionary<string, object?> parameters)
    {
        if (!_connections.TryGetValue(serverId, out var conn))
            return JsonSerializer.Serialize(new { error = "Server not connected" });

        var response = await SendRequestAsync(conn, "tools/call", new
        {
            name = toolName,
            arguments = parameters
        });

        if (response.TryGetProperty("result", out var result) &&
            result.TryGetProperty("content", out var content))
        {
            var texts = new List<string>();
            foreach (var item in content.EnumerateArray())
            {
                if (item.TryGetProperty("type", out var type) &&
                    type.GetString() == "text" &&
                    item.TryGetProperty("text", out var text))
                {
                    texts.Add(text.GetString() ?? "");
                }
            }
            return texts.Count > 0 ? string.Join("\n", texts) : "No result";
        }

        return "No result";
    }

    public bool IsConnected(string serverId) => _connections.ContainsKey(serverId);
    public IReadOnlyCollection<string> ConnectedServerIds => _connections.Keys;

    private async Task<JsonElement> SendRequestAsync(McpConnection conn, string method, object? parameters)
    {
        var id = Interlocked.Increment(ref _requestId);
        var request = new
        {
            jsonrpc = "2.0",
            id,
            method,
            @params = parameters
        };

        var json = JsonSerializer.Serialize(request);
        await conn.Process.StandardInput.WriteLineAsync(json);
        await conn.Process.StandardInput.FlushAsync();

        // Read response line
        var responseLine = await conn.Process.StandardOutput.ReadLineAsync();
        if (string.IsNullOrEmpty(responseLine))
            return default;

        return JsonSerializer.Deserialize<JsonElement>(responseLine);
    }

    private async Task SendNotificationAsync(McpConnection conn, string method, object? parameters)
    {
        var notification = new
        {
            jsonrpc = "2.0",
            method,
            @params = parameters
        };

        var json = JsonSerializer.Serialize(notification);
        await conn.Process.StandardInput.WriteLineAsync(json);
        await conn.Process.StandardInput.FlushAsync();
    }

    public void Dispose()
    {
        if (_disposed) return;
        _disposed = true;

        foreach (var conn in _connections.Values)
            conn.Dispose();
        _connections.Clear();
    }

    private class McpConnection : IDisposable
    {
        public string Id { get; }
        public string Name { get; }
        public Process Process { get; }

        public McpConnection(string id, string name, Process process)
        {
            Id = id;
            Name = name;
            Process = process;
        }

        public void Dispose()
        {
            if (!Process.HasExited)
            {
                try { Process.Kill(entireProcessTree: true); } catch { }
            }
            Process.Dispose();
        }
    }
}

/// <summary>
/// Basic information about an MCP tool.
/// </summary>
public class McpToolInfo
{
    public string Name { get; set; } = "";
    public string Description { get; set; } = "";
}
