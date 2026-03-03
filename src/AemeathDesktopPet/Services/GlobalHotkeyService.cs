using System.Diagnostics;
using System.Runtime.InteropServices;
using System.Windows.Input;
using AemeathDesktopPet.Interop;

namespace AemeathDesktopPet.Services;

/// <summary>
/// Low-level keyboard hook for push-to-talk.
/// Detects both key-down and key-up for hold-to-record behavior.
/// </summary>
public class GlobalHotkeyService : IDisposable
{
    private IntPtr _hookId = IntPtr.Zero;
    private Win32Api.LowLevelKeyboardProc? _proc;

    // Configured hotkey
    private Key _targetKey = Key.F2;
    private ModifierKeys _targetModifiers = ModifierKeys.Control;
    private bool _isKeyDown;

    public event Action? HotkeyPressed;
    public event Action? HotkeyReleased;

    /// <summary>
    /// Parses a hotkey string like "Ctrl+F2", "Shift+Alt+F5", etc.
    /// </summary>
    public void Configure(string hotkeyString)
    {
        _targetModifiers = ModifierKeys.None;
        _targetKey = Key.F2;

        if (string.IsNullOrWhiteSpace(hotkeyString))
            return;

        var parts = hotkeyString.Split('+', StringSplitOptions.RemoveEmptyEntries | StringSplitOptions.TrimEntries);
        foreach (var part in parts)
        {
            var lower = part.ToLowerInvariant();
            switch (lower)
            {
                case "ctrl" or "control":
                    _targetModifiers |= ModifierKeys.Control;
                    break;
                case "alt":
                    _targetModifiers |= ModifierKeys.Alt;
                    break;
                case "shift":
                    _targetModifiers |= ModifierKeys.Shift;
                    break;
                case "win" or "windows":
                    _targetModifiers |= ModifierKeys.Windows;
                    break;
                default:
                    if (Enum.TryParse<Key>(part, ignoreCase: true, out var key))
                        _targetKey = key;
                    break;
            }
        }
    }

    public void Start()
    {
        if (_hookId != IntPtr.Zero)
            return;

        _proc = HookCallback;
        using var process = Process.GetCurrentProcess();
        using var module = process.MainModule!;
        _hookId = Win32Api.SetWindowsHookEx(
            Win32Api.WH_KEYBOARD_LL,
            _proc,
            Win32Api.GetModuleHandle(module.ModuleName),
            0);
    }

    public void Stop()
    {
        if (_hookId != IntPtr.Zero)
        {
            Win32Api.UnhookWindowsHookEx(_hookId);
            _hookId = IntPtr.Zero;
        }
        _proc = null;
    }

    private IntPtr HookCallback(int nCode, IntPtr wParam, IntPtr lParam)
    {
        if (nCode >= 0)
        {
            var hookStruct = Marshal.PtrToStructure<Win32Api.KBDLLHOOKSTRUCT>(lParam);
            var vk = (int)hookStruct.vkCode;
            var key = KeyInterop.KeyFromVirtualKey(vk);

            if (key == _targetKey && AreModifiersPressed())
            {
                int msg = wParam.ToInt32();
                if (msg is Win32Api.WM_KEYDOWN or Win32Api.WM_SYSKEYDOWN)
                {
                    if (!_isKeyDown)
                    {
                        _isKeyDown = true;
                        HotkeyPressed?.Invoke();
                    }
                }
                else if (msg is Win32Api.WM_KEYUP or Win32Api.WM_SYSKEYUP)
                {
                    if (_isKeyDown)
                    {
                        _isKeyDown = false;
                        HotkeyReleased?.Invoke();
                    }
                }
            }
        }

        return Win32Api.CallNextHookEx(_hookId, nCode, wParam, lParam);
    }

    private bool AreModifiersPressed()
    {
        if (_targetModifiers == ModifierKeys.None)
            return true;

        bool ctrl = (_targetModifiers & ModifierKeys.Control) == 0 ||
                    (Keyboard.Modifiers & ModifierKeys.Control) != 0;
        bool alt = (_targetModifiers & ModifierKeys.Alt) == 0 ||
                   (Keyboard.Modifiers & ModifierKeys.Alt) != 0;
        bool shift = (_targetModifiers & ModifierKeys.Shift) == 0 ||
                     (Keyboard.Modifiers & ModifierKeys.Shift) != 0;
        bool win = (_targetModifiers & ModifierKeys.Windows) == 0 ||
                   (Keyboard.Modifiers & ModifierKeys.Windows) != 0;

        return ctrl && alt && shift && win;
    }

    public void Dispose()
    {
        Stop();
    }
}
