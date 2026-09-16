using System.Runtime.ExceptionServices;
using System.Windows;
using System.Windows.Controls;
using System.Windows.Threading;
using AemeathDesktopPet.Models;
using AemeathDesktopPet.Services;
using AemeathDesktopPet.ViewModels;
using AemeathDesktopPet.Views;

namespace AemeathDesktopPet.Tests.Views;

public class ChatWindowTests
{
    [Fact]
    public void ImmediateReply_AfterSeededHistory_RendersOrderedMessagesAndRemainsReady()
    {
        RunInSta(async () =>
        {
            var tempDirectory = Path.Combine(
                Path.GetTempPath(), $"AemeathChatWindowTest_{Guid.NewGuid():N}");
            ChatWindow? window = null;
            Application? application = null;
            Exception? dispatcherException = null;

            try
            {
                application = CreateTestApplication();
                var dispatcher = Dispatcher.CurrentDispatcher;
                dispatcher.UnhandledException += CaptureDispatcherException;

                var persistence = new JsonPersistenceService(tempDirectory);
                var memory = new MemoryService(persistence);
                memory.Load();
                memory.AddMessage(new ChatMessage("user", "Seeded question"));
                memory.AddMessage(new ChatMessage("assistant", "Seeded answer"));
                memory.Save();

                var stats = new StatsService(persistence);
                stats.Load();
                var viewModel = new ChatViewModel(
                    new ImmediateChatService("Immediate offline reply"), memory, stats);
                window = new ChatWindow(viewModel);
                window.Show();
                await DrainDispatcherAsync(DispatcherPriority.Loaded);

                var messageList = Assert.IsType<ListBox>(window.FindName("MessageList"));
                var sendButton = Assert.IsType<Button>(window.FindName("SendButton"));
                viewModel.InputText = "New offline prompt";
                await DrainDispatcherAsync(DispatcherPriority.DataBind);
                Assert.True(sendButton.IsEnabled);

                sendButton.RaiseEvent(new RoutedEventArgs(Button.ClickEvent));
                await WaitUntilAsync(
                    () => dispatcherException != null ||
                        (viewModel.Messages.Count == 4 && !viewModel.IsSending),
                    TimeSpan.FromSeconds(10));
                await DrainDispatcherAsync(DispatcherPriority.Loaded);
                window.UpdateLayout();

                Assert.Null(dispatcherException);
                Assert.False(viewModel.IsSending);
                Assert.Collection(
                    RenderedMessages(messageList, 4),
                    message => AssertMessage(message, "user", "Seeded question"),
                    message => AssertMessage(message, "assistant", "Seeded answer"),
                    message => AssertMessage(message, "user", "New offline prompt"),
                    message => AssertMessage(message, "assistant", "Immediate offline reply"));

                viewModel.InputText = "Ready for another prompt";
                await DrainDispatcherAsync(DispatcherPriority.DataBind);
                Assert.True(sendButton.IsEnabled);

                void CaptureDispatcherException(object sender, DispatcherUnhandledExceptionEventArgs args)
                {
                    dispatcherException = args.Exception;
                    args.Handled = true;
                }
            }
            finally
            {
                window?.Close();
                application?.Shutdown();
                if (Directory.Exists(tempDirectory))
                    Directory.Delete(tempDirectory, true);
            }
        });
    }

    private static Application CreateTestApplication()
    {
        Assert.Null(Application.Current);
        var application = new Application
        {
            ShutdownMode = ShutdownMode.OnExplicitShutdown,
        };
        application.Resources.MergedDictionaries.Add(new ResourceDictionary
        {
            Source = new Uri(
                "pack://application:,,,/AemeathDesktopPet;component/Themes/AemeathTheme.xaml",
                UriKind.Absolute),
        });
        return application;
    }

    private static IReadOnlyList<ChatMessage> RenderedMessages(ListBox messageList, int count)
    {
        var rendered = new List<ChatMessage>(count);
        for (var index = 0; index < count; index++)
        {
            var container = Assert.IsType<ListBoxItem>(
                messageList.ItemContainerGenerator.ContainerFromIndex(index));
            rendered.Add(Assert.IsType<ChatMessage>(container.DataContext));
        }
        return rendered;
    }

    private static void AssertMessage(ChatMessage message, string role, string content)
    {
        Assert.Equal(role, message.Role);
        Assert.Equal(content, message.Content);
    }

    private static async Task DrainDispatcherAsync(DispatcherPriority priority)
    {
        await Dispatcher.CurrentDispatcher.InvokeAsync(() => { }, priority);
    }

    private static async Task WaitUntilAsync(Func<bool> condition, TimeSpan timeout)
    {
        var deadline = DateTime.UtcNow + timeout;
        while (!condition())
        {
            if (DateTime.UtcNow >= deadline)
                throw new TimeoutException("Chat view did not reach the expected rendered state.");
            await Task.Delay(20);
        }
    }

    private static void RunInSta(Func<Task> testBody)
    {
        Exception? failure = null;
        Dispatcher? dispatcher = null;
        var thread = new Thread(() =>
        {
            try
            {
                dispatcher = Dispatcher.CurrentDispatcher;
                SynchronizationContext.SetSynchronizationContext(
                    new DispatcherSynchronizationContext(dispatcher));
                dispatcher.BeginInvoke(new Action(async () =>
                {
                    try
                    {
                        await testBody();
                    }
                    catch (Exception exception)
                    {
                        failure = exception;
                    }
                    finally
                    {
                        dispatcher.BeginInvokeShutdown(DispatcherPriority.Send);
                    }
                }));
                Dispatcher.Run();
            }
            catch (Exception exception)
            {
                failure = exception;
            }
        })
        {
            IsBackground = true,
        };
        thread.SetApartmentState(ApartmentState.STA);
        thread.Start();

        if (!thread.Join(TimeSpan.FromSeconds(30)))
        {
            dispatcher?.BeginInvokeShutdown(DispatcherPriority.Send);
            throw new TimeoutException("STA dispatcher did not complete the ChatWindow regression test.");
        }

        if (failure != null)
            ExceptionDispatchInfo.Capture(failure).Throw();
    }

    private sealed class ImmediateChatService(string response) : IChatService
    {
        public bool IsAvailable => true;

        public Task<string> SendMessageAsync(
            string userMessage, IReadOnlyList<ChatMessage> history)
            => Task.FromResult(response);

        public async IAsyncEnumerable<string> StreamMessageAsync(
            string userMessage, IReadOnlyList<ChatMessage> history)
        {
            yield return response;
            await Task.CompletedTask;
        }
    }
}
