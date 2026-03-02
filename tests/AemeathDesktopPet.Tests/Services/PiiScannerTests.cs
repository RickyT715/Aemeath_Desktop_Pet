using AemeathDesktopPet.Services;

namespace AemeathDesktopPet.Tests.Services;

public class PiiScannerTests
{
    // --- Credit Card (Luhn-valid) ---

    [Fact]
    public void ContainsPii_ValidVisaCard_ReturnsTrue()
    {
        Assert.True(PiiScanner.ContainsPii("Card: 4111 1111 1111 1111"));
    }

    [Fact]
    public void ContainsPii_ValidVisaCardNoDashes_ReturnsTrue()
    {
        Assert.True(PiiScanner.ContainsPii("4111111111111111"));
    }

    [Fact]
    public void ContainsPii_ValidMastercard_ReturnsTrue()
    {
        Assert.True(PiiScanner.ContainsPii("5500-0000-0000-0004"));
    }

    [Fact]
    public void ContainsPii_InvalidLuhnCard_ReturnsFalse()
    {
        // 4111 1111 1111 1112 fails Luhn
        Assert.False(PiiScanner.ContainsPii("4111 1111 1111 1112"));
    }

    [Fact]
    public void ContainsPii_ShortDigitSequence_ReturnsFalse()
    {
        Assert.False(PiiScanner.ContainsPii("Call 12345678"));
    }

    // --- SSN ---

    [Fact]
    public void ContainsPii_SsnWithDashes_ReturnsTrue()
    {
        Assert.True(PiiScanner.ContainsPii("SSN is 123-45-6789"));
    }

    [Fact]
    public void ContainsPii_SsnWithSpaces_ReturnsTrue()
    {
        Assert.True(PiiScanner.ContainsPii("Number: 123 45 6789"));
    }

    // --- Email ---

    [Fact]
    public void ContainsPii_Email_ReturnsTrue()
    {
        Assert.True(PiiScanner.ContainsPii("Contact user@example.com for help"));
    }

    [Fact]
    public void ContainsPii_EmailWithSubdomain_ReturnsTrue()
    {
        Assert.True(PiiScanner.ContainsPii("Send to admin@mail.corp.co.uk"));
    }

    // --- Phone ---

    [Fact]
    public void ContainsPii_UsPhoneWithParens_ReturnsTrue()
    {
        Assert.True(PiiScanner.ContainsPii("Call (555) 123-4567"));
    }

    [Fact]
    public void ContainsPii_UsPhoneWithDashes_ReturnsTrue()
    {
        Assert.True(PiiScanner.ContainsPii("Phone: 555-123-4567"));
    }

    [Fact]
    public void ContainsPii_PhoneWithCountryCode_ReturnsTrue()
    {
        Assert.True(PiiScanner.ContainsPii("Dial +1 555-123-4567"));
    }

    // --- Password keywords ---

    [Fact]
    public void ContainsPii_PasswordIs_ReturnsTrue()
    {
        Assert.True(PiiScanner.ContainsPii("The password is hunter2"));
    }

    [Fact]
    public void ContainsPii_PwdEquals_ReturnsTrue()
    {
        Assert.True(PiiScanner.ContainsPii("pwd=secret123"));
    }

    [Fact]
    public void ContainsPii_PasswdColon_ReturnsTrue()
    {
        Assert.True(PiiScanner.ContainsPii("passwd: myP@ss"));
    }

    // --- Clean text ---

    [Fact]
    public void ContainsPii_CleanText_ReturnsFalse()
    {
        Assert.False(PiiScanner.ContainsPii("Looks like you're coding in Visual Studio!"));
    }

    [Fact]
    public void ContainsPii_CleanTextWithNumbers_ReturnsFalse()
    {
        Assert.False(PiiScanner.ContainsPii("You have 3 tabs open and it's 2:30 PM."));
    }

    // --- Null / Empty ---

    [Fact]
    public void ContainsPii_Null_ReturnsFalse()
    {
        Assert.False(PiiScanner.ContainsPii(null));
    }

    [Fact]
    public void ContainsPii_Empty_ReturnsFalse()
    {
        Assert.False(PiiScanner.ContainsPii(""));
    }

    // --- Mixed / Embedded PII ---

    [Fact]
    public void ContainsPii_EmbeddedEmailInSentence_ReturnsTrue()
    {
        Assert.True(PiiScanner.ContainsPii("I can see you're emailing john.doe@company.org about the project"));
    }

    [Fact]
    public void ContainsPii_CreditCardInNaturalSpeech_ReturnsTrue()
    {
        Assert.True(PiiScanner.ContainsPii("Your card ending in 4111 1111 1111 1111 was charged."));
    }

    [Fact]
    public void ContainsPii_PasswordCaseInsensitive_ReturnsTrue()
    {
        Assert.True(PiiScanner.ContainsPii("PASSWORD is admin123"));
    }

    [Fact]
    public void ContainsPii_TypicalAiResponse_ReturnsFalse()
    {
        Assert.False(PiiScanner.ContainsPii("Looks like you're browsing the web! Having fun surfing?"));
    }

    [Fact]
    public void ContainsPii_AiResponseWithCodingContext_ReturnsFalse()
    {
        Assert.False(PiiScanner.ContainsPii("Oh, you're deep into some C# code! Looks like a WPF project with some tests running."));
    }

    [Fact]
    public void ContainsPii_AiResponseWithTimeReference_ReturnsFalse()
    {
        Assert.False(PiiScanner.ContainsPii("It's pretty late! You've been at this for a while. Maybe take a break?"));
    }

    [Fact]
    public void ContainsPii_WhitespaceOnly_ReturnsFalse()
    {
        Assert.False(PiiScanner.ContainsPii("   \t\n  "));
    }

    // --- Luhn algorithm ---

    [Fact]
    public void PassesLuhn_ValidNumber_ReturnsTrue()
    {
        // Visa test number
        Assert.True(PiiScanner.PassesLuhn("4111111111111111"));
    }

    [Fact]
    public void PassesLuhn_InvalidNumber_ReturnsFalse()
    {
        Assert.False(PiiScanner.PassesLuhn("4111111111111112"));
    }

    [Fact]
    public void PassesLuhn_Empty_ReturnsFalse()
    {
        Assert.False(PiiScanner.PassesLuhn(""));
    }

    [Fact]
    public void PassesLuhn_Null_ReturnsFalse()
    {
        Assert.False(PiiScanner.PassesLuhn(null!));
    }

    [Fact]
    public void PassesLuhn_AmexTestNumber_ReturnsTrue()
    {
        Assert.True(PiiScanner.PassesLuhn("378282246310005"));
    }
}
