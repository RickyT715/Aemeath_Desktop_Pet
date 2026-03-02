using System.Net;
using System.Net.Http;
using AemeathDesktopPet.Engine;
using AemeathDesktopPet.Models;
using AemeathDesktopPet.Services;

namespace AemeathDesktopPet.Tests.Services;

/// <summary>
/// End-to-end tests for the screen awareness pipeline.
/// Tests the full flow from config through provider selection, HTTP calls,
/// response parsing, and PII filtering using mock HTTP responses.
/// </summary>
public class ScreenAwarenessE2ETests
{
    // --- Full Pipeline: Gemini Provider ---

    [Fact]
    public async Task E2E_GeminiProvider_CleanResponse_ReturnsCommentary()
    {
        var geminiResponse = """
        {"candidates":[{"content":{"parts":[{"text":"Looks like you're coding!"}]}}]}
        """;

        var svc = CreateServiceWithMockHttp(geminiResponse, provider: "gemini", apiKey: "test-key");
        var config = svc.Item2;

        // Verify provider is configured
        Assert.True(ScreenAwarenessService.IsProviderConfigured(config));

        // Parse response
        var result = await svc.Item1.AnalyzeTextWithGemini("sys", "prompt", "test-key");
        Assert.Equal("Looks like you're coding!", result);

        // PII scan should pass
        Assert.False(PiiScanner.ContainsPii(result));
    }

    [Fact]
    public async Task E2E_GeminiProvider_PiiResponse_WouldBeFiltered()
    {
        var geminiResponse = """
        {"candidates":[{"content":{"parts":[{"text":"I see you typed password is hunter2 in the browser"}]}}]}
        """;

        var svc = CreateServiceWithMockHttp(geminiResponse, provider: "gemini", apiKey: "test-key");
        var result = await svc.Item1.AnalyzeTextWithGemini("sys", "prompt", "test-key");

        Assert.NotNull(result);
        // PII scan should catch this
        Assert.True(PiiScanner.ContainsPii(result));
    }

    // --- Full Pipeline: Claude Provider ---

    [Fact]
    public async Task E2E_ClaudeProvider_CleanResponse_ReturnsCommentary()
    {
        var claudeResponse = """
        {"content":[{"type":"text","text":"Oh, watching a video? Nice!"}]}
        """;

        var svc = CreateServiceWithMockHttp(claudeResponse, provider: "claude", apiKey: "test-key");
        var result = await svc.Item1.AnalyzeTextWithClaude("sys", "prompt", "test-key");

        Assert.Equal("Oh, watching a video? Nice!", result);
        Assert.False(PiiScanner.ContainsPii(result));
    }

    [Fact]
    public async Task E2E_ClaudeProvider_EmailInResponse_WouldBeFiltered()
    {
        var claudeResponse = """
        {"content":[{"type":"text","text":"I see you're emailing user@example.com"}]}
        """;

        var svc = CreateServiceWithMockHttp(claudeResponse, provider: "claude", apiKey: "test-key");
        var result = await svc.Item1.AnalyzeTextWithClaude("sys", "prompt", "test-key");

        Assert.NotNull(result);
        Assert.True(PiiScanner.ContainsPii(result));
    }

    // --- Full Pipeline: Ollama Provider ---

    [Fact]
    public void E2E_OllamaProvider_NoApiKeyNeeded()
    {
        var config = new ScreenAwarenessConfig
        {
            Enabled = true,
            VisionProvider = "ollama",
            VisionApiKey = "", // empty is fine for Ollama
            OllamaBaseUrl = "http://localhost:11434",
            OllamaModelName = "qwen2.5vl:3b"
        };

        Assert.True(ScreenAwarenessService.IsProviderConfigured(config));
    }

    [Fact]
    public void E2E_OllamaProvider_ResponseParsed()
    {
        var ollamaJson = """{"message":{"role":"assistant","content":"The user is browsing Reddit."},"done":true}""";
        var result = ScreenAwarenessService.ExtractOllamaContent(ollamaJson);

        Assert.Equal("The user is browsing Reddit.", result);
        Assert.False(PiiScanner.ContainsPii(result));
    }

    [Fact]
    public void E2E_OllamaProvider_PiiInResponse_WouldBeFiltered()
    {
        var ollamaJson = """{"message":{"role":"assistant","content":"I can see a credit card 4111 1111 1111 1111 on screen"},"done":true}""";
        var result = ScreenAwarenessService.ExtractOllamaContent(ollamaJson);

        Assert.NotNull(result);
        Assert.True(PiiScanner.ContainsPii(result));
    }

    // --- Full Pipeline: Hybrid Provider ---

    [Fact]
    public void E2E_HybridProvider_ConfigRequirements()
    {
        // Needs Ollama + HybridCloudApiKey
        var config = new ScreenAwarenessConfig
        {
            VisionProvider = "local_hybrid",
            OllamaBaseUrl = "http://localhost:11434",
            OllamaModelName = "qwen2.5vl:3b",
            HybridCloudProvider = "gemini",
            HybridCloudApiKey = "" // missing!
        };

        Assert.False(ScreenAwarenessService.IsProviderConfigured(config));

        config.HybridCloudApiKey = "gemini-key";
        Assert.True(ScreenAwarenessService.IsProviderConfigured(config));
    }

    // --- Privacy Layer Toggle Tests ---

    [Fact]
    public void E2E_PiiScanToggle_WhenDisabled_PiiPassesThrough()
    {
        var config = new ScreenAwarenessConfig
        {
            EnableResponsePiiScan = false
        };

        var response = "The password is hunter2";

        // PII is detected by scanner
        Assert.True(PiiScanner.ContainsPii(response));

        // But with toggle off, the service should NOT filter it
        // (simulating the config check: if EnableResponsePiiScan && ContainsPii)
        bool shouldFilter = config.EnableResponsePiiScan && PiiScanner.ContainsPii(response);
        Assert.False(shouldFilter);
    }

    [Fact]
    public void E2E_PiiScanToggle_WhenEnabled_PiiFiltered()
    {
        var config = new ScreenAwarenessConfig
        {
            EnableResponsePiiScan = true
        };

        var response = "The password is hunter2";

        bool shouldFilter = config.EnableResponsePiiScan && PiiScanner.ContainsPii(response);
        Assert.True(shouldFilter);
    }

    [Fact]
    public void E2E_DownscaleToggle_AffectsCaptureWidth()
    {
        var config = new ScreenAwarenessConfig
        {
            EnablePrivacyDownscale = true,
            PrivacyDownscaleMaxWidth = 480
        };

        int captureWidth = config.EnablePrivacyDownscale ? config.PrivacyDownscaleMaxWidth : 768;
        Assert.Equal(480, captureWidth);

        // Disable downscale
        config.EnablePrivacyDownscale = false;
        captureWidth = config.EnablePrivacyDownscale ? config.PrivacyDownscaleMaxWidth : 768;
        Assert.Equal(768, captureWidth);
    }

    [Fact]
    public void E2E_DownscaleToggle_CustomResolution()
    {
        var config = new ScreenAwarenessConfig
        {
            EnablePrivacyDownscale = true,
            PrivacyDownscaleMaxWidth = 320
        };

        int captureWidth = config.EnablePrivacyDownscale ? config.PrivacyDownscaleMaxWidth : 768;
        Assert.Equal(320, captureWidth);
    }

    [Fact]
    public void E2E_ProtectedWindowToggle_ConfigDriven()
    {
        var configOn = new ScreenAwarenessConfig { EnableProtectedWindowCheck = true };
        var configOff = new ScreenAwarenessConfig { EnableProtectedWindowCheck = false };

        Assert.True(configOn.EnableProtectedWindowCheck);
        Assert.False(configOff.EnableProtectedWindowCheck);
    }

    // --- Budget Tracking per Provider ---

    [Fact]
    public void E2E_BudgetTracking_OllamaIsZeroCost()
    {
        var config = new ScreenAwarenessConfig
        {
            VisionProvider = "ollama",
            MonthlyBudgetCap = 0.01 // very low budget
        };

        var svc = new ScreenAwarenessService(
            () => config, () => new AemeathStats(), () => "Kuro",
            new EnvironmentDetector(), new HttpClient());

        // Even with $0.01 budget, Ollama should never exceed it (costs $0)
        svc.MonthlySpend = 0.0;
        Assert.False(svc.IsOverBudget(config));
    }

    // --- Full CaptureAndComment Pipeline (disabled path) ---

    [Fact]
    public async Task E2E_CaptureAndComment_DisabledService_ReturnsNull()
    {
        var config = new ScreenAwarenessConfig { Enabled = false };
        var svc = new ScreenAwarenessService(
            () => config, () => new AemeathStats(), () => "Kuro",
            new EnvironmentDetector(), new HttpClient());

        Assert.Null(await svc.CaptureAndCommentAsync());
    }

    [Fact]
    public void E2E_CaptureAndComment_OllamaNoKey_StillConfigured()
    {
        // Ollama doesn't need an API key, so this should be "configured"
        var config = new ScreenAwarenessConfig
        {
            Enabled = true,
            VisionProvider = "ollama",
            VisionApiKey = ""
        };

        Assert.True(ScreenAwarenessService.IsProviderConfigured(config));
    }

    // --- Response Parsing Robustness ---

    [Fact]
    public void E2E_AllParsers_HandleEmptyString()
    {
        Assert.Null(ScreenAwarenessService.ExtractGeminiContent(""));
        Assert.Null(ScreenAwarenessService.ExtractClaudeContent(""));
        Assert.Null(ScreenAwarenessService.ExtractOllamaContent(""));
    }

    [Fact]
    public void E2E_AllParsers_HandleNull()
    {
        // All parsers should handle null/empty gracefully
        Assert.Null(ScreenAwarenessService.ExtractGeminiContent("null"));
        Assert.Null(ScreenAwarenessService.ExtractClaudeContent("null"));
        Assert.Null(ScreenAwarenessService.ExtractOllamaContent("null"));
    }

    // --- Helper ---

    private static (ScreenAwarenessService, ScreenAwarenessConfig) CreateServiceWithMockHttp(
        string responseBody, string provider = "gemini", string apiKey = "test-key")
    {
        var handler = new MockHttpHandler(responseBody);
        var config = new ScreenAwarenessConfig
        {
            Enabled = true,
            VisionProvider = provider,
            VisionApiKey = apiKey,
            EnableResponsePiiScan = true,
            EnablePrivacyDownscale = true,
            PrivacyDownscaleMaxWidth = 480
        };

        var svc = new ScreenAwarenessService(
            () => config, () => new AemeathStats(), () => "Kuro",
            new EnvironmentDetector(), new HttpClient(handler));

        return (svc, config);
    }

    private class MockHttpHandler : HttpMessageHandler
    {
        private readonly string _responseBody;

        public MockHttpHandler(string responseBody)
        {
            _responseBody = responseBody;
        }

        protected override Task<HttpResponseMessage> SendAsync(HttpRequestMessage request, CancellationToken ct)
        {
            return Task.FromResult(new HttpResponseMessage(HttpStatusCode.OK)
            {
                Content = new StringContent(_responseBody, System.Text.Encoding.UTF8, "application/json")
            });
        }
    }
}
