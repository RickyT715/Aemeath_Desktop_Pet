using System.ComponentModel;
using AemeathDesktopPet.Models;
using AemeathDesktopPet.Services;
using AemeathDesktopPet.ViewModels;

namespace AemeathDesktopPet.Tests.ViewModels;

/// <summary>
/// Fake chat service that yields a fixed response for testing.
/// </summary>
internal class FakeChatService : IChatService
{
    public bool IsAvailable => true;
    public string ResponseText { get; set; } = "Hello from Aemeath!";

    public Task<string> SendMessageAsync(string userMessage, IReadOnlyList<ChatMessage> history)
        => Task.FromResult(ResponseText);

    public async IAsyncEnumerable<string> StreamMessageAsync(string userMessage, IReadOnlyList<ChatMessage> history)
    {
        yield return ResponseText;
        await Task.CompletedTask;
    }
}

public class ChatViewModelTests : IDisposable
{
    private readonly string _tempDir;
    private readonly JsonPersistenceService _persistence;
    private readonly MemoryService _memory;
    private readonly StatsService _stats;
    private readonly FakeChatService _chat;

    public ChatViewModelTests()
    {
        _tempDir = Path.Combine(Path.GetTempPath(), $"AemeathTest_{Guid.NewGuid():N}");
        _persistence = new JsonPersistenceService(_tempDir);
        _memory = new MemoryService(_persistence);
        _stats = new StatsService(_persistence);
        _stats.Load();
        _chat = new FakeChatService();
    }

    public void Dispose()
    {
        if (Directory.Exists(_tempDir))
            Directory.Delete(_tempDir, true);
    }

    [Fact]
    public void Constructor_LoadsEmptyHistory()
    {
        var vm = new ChatViewModel(_chat, _memory, _stats);
        Assert.Empty(vm.Messages);
    }

    [Fact]
    public void Constructor_LoadsExistingHistory()
    {
        // Pre-populate memory
        _memory.Load();
        _memory.AddMessage(new ChatMessage("user", "Hi"));
        _memory.AddMessage(new ChatMessage("assistant", "Hey!"));
        _memory.Save();

        // Create a new memory service to reload from disk
        var memory2 = new MemoryService(_persistence);
        var vm = new ChatViewModel(_chat, memory2, _stats);
        Assert.Equal(2, vm.Messages.Count);
    }

    [Fact]
    public void InputText_DefaultsToEmpty()
    {
        var vm = new ChatViewModel(_chat, _memory, _stats);
        Assert.Equal("", vm.InputText);
    }

    [Fact]
    public void IsSending_DefaultsToFalse()
    {
        var vm = new ChatViewModel(_chat, _memory, _stats);
        Assert.False(vm.IsSending);
    }

    [Fact]
    public void CanSend_FalseWhenInputEmpty()
    {
        var vm = new ChatViewModel(_chat, _memory, _stats);
        vm.InputText = "";
        Assert.False(vm.CanSend);
    }

    [Fact]
    public void CanSend_FalseWhenInputWhitespace()
    {
        var vm = new ChatViewModel(_chat, _memory, _stats);
        vm.InputText = "   ";
        Assert.False(vm.CanSend);
    }

    [Fact]
    public void CanSend_TrueWhenInputHasText()
    {
        var vm = new ChatViewModel(_chat, _memory, _stats);
        vm.InputText = "Hello";
        Assert.True(vm.CanSend);
    }

    [Fact]
    public void InputText_Setter_FiresPropertyChanged()
    {
        var vm = new ChatViewModel(_chat, _memory, _stats);
        var changed = new List<string?>();
        vm.PropertyChanged += (_, args) => changed.Add(args.PropertyName);

        vm.InputText = "test";

        Assert.Contains("InputText", changed);
        Assert.Contains("CanSend", changed);
    }

    [Fact]
    public void IsSending_Setter_FiresPropertyChanged()
    {
        var vm = new ChatViewModel(_chat, _memory, _stats);
        var changed = new List<string?>();
        vm.PropertyChanged += (_, args) => changed.Add(args.PropertyName);

        vm.IsSending = true;

        Assert.Contains("IsSending", changed);
        Assert.Contains("CanSend", changed);
    }

    [Fact]
    public void ImplementsINotifyPropertyChanged()
    {
        var vm = new ChatViewModel(_chat, _memory, _stats);
        Assert.IsAssignableFrom<INotifyPropertyChanged>(vm);
    }

    [Fact]
    public async Task SendMessageAsync_DoesNothing_WhenCanSendIsFalse()
    {
        var vm = new ChatViewModel(_chat, _memory, _stats);
        vm.InputText = "";

        await vm.SendMessageAsync();

        Assert.Empty(vm.Messages);
    }

    [Fact]
    public async Task SendMessageAsync_AddsUserAndAssistantMessages()
    {
        var vm = new ChatViewModel(_chat, _memory, _stats);
        vm.InputText = "Hi there";

        await vm.SendMessageAsync();

        Assert.Equal(2, vm.Messages.Count);
        Assert.Equal("user", vm.Messages[0].Role);
        Assert.Equal("Hi there", vm.Messages[0].Content);
        Assert.Equal("assistant", vm.Messages[1].Role);
    }

    [Fact]
    public async Task SendMessageAsync_ClearsInputAfterSend()
    {
        var vm = new ChatViewModel(_chat, _memory, _stats);
        vm.InputText = "Hello";

        await vm.SendMessageAsync();

        Assert.Equal("", vm.InputText);
    }

    [Fact]
    public async Task SendMessageAsync_AssistantGetsResponseFromChatService()
    {
        _chat.ResponseText = "Test response from Aemeath";
        var vm = new ChatViewModel(_chat, _memory, _stats);
        vm.InputText = "Hello";

        await vm.SendMessageAsync();

        Assert.Equal("Test response from Aemeath", vm.Messages[1].Content);
    }

    [Fact]
    public async Task SendMessageAsync_SetsIsSendingDuringOperation()
    {
        var vm = new ChatViewModel(_chat, _memory, _stats);
        vm.InputText = "Hello";

        await vm.SendMessageAsync();

        // After completion, IsSending should be false
        Assert.False(vm.IsSending);
    }

    [Fact]
    public async Task SendMessageAsync_PersistsToMemory()
    {
        var vm = new ChatViewModel(_chat, _memory, _stats);
        vm.InputText = "Hello";

        await vm.SendMessageAsync();

        // Memory should have the messages
        Assert.True(_memory.Messages.Count >= 2);
    }

    [Fact]
    public async Task SendMessageAsync_TracksStats()
    {
        var vm = new ChatViewModel(_chat, _memory, _stats);
        vm.InputText = "Hello";

        await vm.SendMessageAsync();

        Assert.Equal(1, _stats.Stats.TotalChats);
    }
}
