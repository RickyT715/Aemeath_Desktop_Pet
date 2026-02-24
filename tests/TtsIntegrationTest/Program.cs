using System.IO;
using System.Diagnostics;
using AemeathDesktopPet.Engine;
using AemeathDesktopPet.Models;
using AemeathDesktopPet.Services;
using Edge_tts_sharp;
using Edge_tts_sharp.Model;
using NAudio.Wave;

Console.OutputEncoding = System.Text.Encoding.UTF8;

var text = "你好世界";
var env = new EnvironmentDetector();

Console.WriteLine("╔══════════════════════════════════════════════╗");
Console.WriteLine("║   Aemeath TTS - All 3 Providers Test        ║");
Console.WriteLine("╚══════════════════════════════════════════════╝");
Console.WriteLine();

// ═══════════════════════════════════════════
// Provider 1: Edge TTS (free, no API key)
// ═══════════════════════════════════════════
Console.WriteLine("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━");
Console.WriteLine("[1/3] EDGE TTS (free, no API key)");
Console.WriteLine("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━");
{
    var config = new TtsConfig
    {
        Enabled = true,
        Provider = "edgetts",
        EdgeTtsVoice = "zh-CN-XiaoxiaoNeural",
        Volume = 1.0,
        AutoMuteFullscreen = false,
    };

    Console.WriteLine($"  Voice: {config.EdgeTtsVoice}");

    try
    {
        using var tts = new TtsVoiceService(() => config, env);
        Console.WriteLine($"  Available: {tts.IsAvailable}");

        var sw = Stopwatch.StartNew();
        Console.WriteLine($"  Speaking: \"{text}\"");
        await tts.SpeakAsync(text);
        sw.Stop();
        Console.WriteLine($"  Result: SUCCESS ({sw.ElapsedMilliseconds}ms)");
    }
    catch (Exception ex)
    {
        Console.WriteLine($"  Result: FAILED - {ex.GetType().Name}: {ex.Message}");
    }
}
Console.WriteLine();

// ═══════════════════════════════════════════
// Provider 2: GPT-SoVITS (local server)
// ═══════════════════════════════════════════
Console.WriteLine("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━");
Console.WriteLine("[2/3] GPT-SoVITS (local server at localhost:9880)");
Console.WriteLine("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━");
{
    var config = new TtsConfig
    {
        Enabled = true,
        Provider = "gptsovits",
        GptsovitsUrl = "http://localhost:9880",
        Volume = 1.0,
        AutoMuteFullscreen = false,
    };

    Console.WriteLine($"  Server URL: {config.GptsovitsUrl}");

    try
    {
        using var tts = new TtsVoiceService(() => config, env);
        Console.WriteLine($"  Available: {tts.IsAvailable}");

        var sw = Stopwatch.StartNew();
        Console.WriteLine($"  Speaking: \"{text}\"");
        await tts.SpeakAsync(text);
        sw.Stop();
        Console.WriteLine($"  Result: SUCCESS ({sw.ElapsedMilliseconds}ms)");
    }
    catch (Exception ex)
    {
        Console.WriteLine($"  Result: FAILED - {ex.GetType().Name}: {ex.Message}");
    }
}
Console.WriteLine();

// ═══════════════════════════════════════════
// Provider 3: ElevenLabs (cloud API)
// ═══════════════════════════════════════════
Console.WriteLine("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━");
Console.WriteLine("[3/3] ELEVENLABS (cloud API)");
Console.WriteLine("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━");
{
    // Check for API key from environment variable or use empty
    var apiKey = Environment.GetEnvironmentVariable("ELEVENLABS_API_KEY") ?? "";

    var config = new TtsConfig
    {
        Enabled = true,
        Provider = "elevenlabs",
        ElevenLabsApiKey = apiKey,
        ElevenLabsVoiceId = "21m00Tcm4TlvDq8ikWAM", // Rachel
        ElevenLabsModelId = "eleven_multilingual_v2",
        Volume = 1.0,
        AutoMuteFullscreen = false,
    };

    Console.WriteLine($"  API Key: {(string.IsNullOrEmpty(apiKey) ? "(not set)" : apiKey[..8] + "...")}");
    Console.WriteLine($"  Voice ID: {config.ElevenLabsVoiceId} (Rachel)");
    Console.WriteLine($"  Model: {config.ElevenLabsModelId}");

    if (string.IsNullOrEmpty(apiKey))
    {
        Console.WriteLine("  Result: SKIPPED - No API key. Set ELEVENLABS_API_KEY env var to test.");
    }
    else
    {
        try
        {
            using var tts = new TtsVoiceService(() => config, env);
            Console.WriteLine($"  Available: {tts.IsAvailable}");

            var sw = Stopwatch.StartNew();
            Console.WriteLine($"  Speaking: \"{text}\"");
            await tts.SpeakAsync(text);
            sw.Stop();
            Console.WriteLine($"  Result: SUCCESS ({sw.ElapsedMilliseconds}ms)");
        }
        catch (Exception ex)
        {
            Console.WriteLine($"  Result: FAILED - {ex.GetType().Name}: {ex.Message}");
        }
    }
}
Console.WriteLine();

// ═══════════════════════════════════════════
// Bonus: Edge TTS voice showcase
// ═══════════════════════════════════════════
Console.WriteLine("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━");
Console.WriteLine("[Bonus] Edge TTS - Different voices");
Console.WriteLine("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━");

var voiceTests = new[]
{
    ("zh-CN-XiaoxiaoNeural",  "你好！我是晓晓。"),
    ("zh-CN-YunxiNeural",     "你好！我是云希。"),
    ("zh-CN-YunyangNeural",   "你好！我是云扬。"),
    ("en-US-AvaMultilingualNeural", "Hello! I am Ava."),
};

foreach (var (voiceName, phrase) in voiceTests)
{
    var config = new TtsConfig
    {
        Enabled = true,
        Provider = "edgetts",
        EdgeTtsVoice = voiceName,
        Volume = 1.0,
        AutoMuteFullscreen = false,
    };

    try
    {
        using var tts = new TtsVoiceService(() => config, env);
        Console.Write($"  {voiceName,-35} \"{phrase}\" ... ");
        var sw = Stopwatch.StartNew();
        await tts.SpeakAsync(phrase);
        sw.Stop();
        Console.WriteLine($"OK ({sw.ElapsedMilliseconds}ms)");
    }
    catch (Exception ex)
    {
        Console.WriteLine($"FAIL: {ex.Message}");
    }
}

Console.WriteLine();
Console.WriteLine("=== All tests complete ===");
