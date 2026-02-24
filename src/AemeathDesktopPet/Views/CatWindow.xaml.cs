using System.Windows;
using System.Windows.Input;
using System.Windows.Interop;
using AemeathDesktopPet.Engine;
using AemeathDesktopPet.Interop;
using AemeathDesktopPet.Models;

namespace AemeathDesktopPet.Views;

public partial class CatWindow : Window
{
    private readonly CatBehaviorEngine _catEngine;

    public CatWindow(CatBehaviorEngine catEngine)
    {
        InitializeComponent();
        _catEngine = catEngine;

        _catEngine.PositionChanged += () =>
        {
            Left = _catEngine.CatX;
            Top = _catEngine.CatY;
        };

        _catEngine.StateChanged += OnCatStateChanged;

        Loaded += OnLoaded;
    }

    private void OnLoaded(object sender, RoutedEventArgs e)
    {
        // Make tool window (hidden from Alt+Tab)
        var hwnd = new WindowInteropHelper(this).Handle;
        Win32Api.SetToolWindow(hwnd);

        Left = _catEngine.CatX;
        Top = _catEngine.CatY;
    }

    private void OnCatStateChanged(CatState state)
    {
        // Update cat visual based on state
        // When real cat sprites are available, swap the Image source here.
        // For now, change the emoji to reflect state:
        CatGlyph.Text = state switch
        {
            CatState.CatNap => "\uD83D\uDE3A",    // 😺 sleeping
            CatState.CatPounce => "\uD83D\uDE3C",  // 😼 pounce
            CatState.CatStartled => "\uD83D\uDE40", // 🙀 startled
            CatState.CatPurr => "\uD83D\uDE3B",    // 😻 happy
            CatState.CatChase => "\uD83D\uDC08",   // 🐈 running
            _ => "\uD83D\uDC08",                    // 🐈 default cat
        };
    }

    protected override void OnMouseLeftButtonDown(MouseButtonEventArgs e)
    {
        base.OnMouseLeftButtonDown(e);
        _catEngine.OnUserClickedCat();
    }
}
