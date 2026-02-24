using System.Text.Json;
using AemeathDesktopPet.Models;

namespace AemeathDesktopPet.Tests.Models;

public class GptSovitsProfileTests
{
    [Fact]
    public void DefaultValues_AreCorrect()
    {
        var profile = new GptSovitsProfile();

        Assert.Equal("Default", profile.Name);
        Assert.Equal("", profile.GptWeightsPath);
        Assert.Equal("", profile.SovitsWeightsPath);
        Assert.Equal("", profile.RefAudioPath);
        Assert.Equal("", profile.PromptText);
        Assert.Equal("auto", profile.PromptLang);
        Assert.Equal("auto", profile.TextLang);
        Assert.Equal(1.0, profile.SpeedFactor);
    }

    [Fact]
    public void TtsConfig_DefaultProfiles_Empty()
    {
        var tts = new TtsConfig();

        Assert.NotNull(tts.GptsovitsProfiles);
        Assert.Empty(tts.GptsovitsProfiles);
        Assert.Equal("", tts.GptsovitsActiveProfile);
    }

    [Fact]
    public void TtsConfig_ProfilesSerialization_RoundTrip()
    {
        var tts = new TtsConfig
        {
            GptsovitsActiveProfile = "MyModel",
            GptsovitsProfiles = new List<GptSovitsProfile>
            {
                new()
                {
                    Name = "MyModel",
                    GptWeightsPath = "/models/gpt.ckpt",
                    SovitsWeightsPath = "/models/sovits.pth",
                    RefAudioPath = "/audio/ref.wav",
                    PromptText = "Hello world",
                    PromptLang = "en",
                    TextLang = "zh",
                    SpeedFactor = 1.2
                }
            }
        };

        var json = JsonSerializer.Serialize(tts);
        var deserialized = JsonSerializer.Deserialize<TtsConfig>(json)!;

        Assert.Equal("MyModel", deserialized.GptsovitsActiveProfile);
        Assert.Single(deserialized.GptsovitsProfiles);

        var p = deserialized.GptsovitsProfiles[0];
        Assert.Equal("MyModel", p.Name);
        Assert.Equal("/models/gpt.ckpt", p.GptWeightsPath);
        Assert.Equal("/models/sovits.pth", p.SovitsWeightsPath);
        Assert.Equal("/audio/ref.wav", p.RefAudioPath);
        Assert.Equal("Hello world", p.PromptText);
        Assert.Equal("en", p.PromptLang);
        Assert.Equal("zh", p.TextLang);
        Assert.Equal(1.2, p.SpeedFactor);
    }

    [Fact]
    public void TtsConfig_BackwardCompatibility_NoProfilesInJson()
    {
        // Simulate old config JSON without profile fields
        var json = """{"Enabled":false,"Provider":"edgetts","GptsovitsUrl":"http://localhost:9880"}""";
        var tts = JsonSerializer.Deserialize<TtsConfig>(json)!;

        Assert.NotNull(tts.GptsovitsProfiles);
        Assert.Empty(tts.GptsovitsProfiles);
        Assert.Equal("", tts.GptsovitsActiveProfile);
        Assert.Equal("http://localhost:9880", tts.GptsovitsUrl);
    }
}
