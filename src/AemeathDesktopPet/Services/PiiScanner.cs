using System.Text.RegularExpressions;

namespace AemeathDesktopPet.Services;

/// <summary>
/// Scans AI response text for personally identifiable information (PII).
/// Used as a post-response privacy layer to discard responses that accidentally
/// contain credit card numbers, SSNs, emails, phone numbers, or password keywords.
/// </summary>
internal static class PiiScanner
{
    // Credit card: 13-19 digit sequences (with optional spaces/dashes), validated by Luhn
    private static readonly Regex CreditCardRegex = new(
        @"\b(?:\d[ \-]*?){13,19}\b", RegexOptions.Compiled);

    // US Social Security Number: XXX-XX-XXXX
    private static readonly Regex SsnRegex = new(
        @"\b\d{3}[ \-]\d{2}[ \-]\d{4}\b", RegexOptions.Compiled);

    // Email address
    private static readonly Regex EmailRegex = new(
        @"\b[A-Za-z0-9._%+\-]+@[A-Za-z0-9.\-]+\.[A-Za-z]{2,}\b", RegexOptions.Compiled);

    // US phone number: (XXX) XXX-XXXX or XXX-XXX-XXXX or +1XXXXXXXXXX
    private static readonly Regex PhoneRegex = new(
        @"(?:\+?1[ \-]?)?\(?\d{3}\)?[ \-.]?\d{3}[ \-.]?\d{4}\b", RegexOptions.Compiled);

    // Password-related keywords in the response
    private static readonly Regex PasswordKeywordRegex = new(
        @"\b(?:password|passwd|pwd)\s*(?:is|:|=)\s*\S+", RegexOptions.Compiled | RegexOptions.IgnoreCase);

    /// <summary>
    /// Returns true if the text contains any detected PII patterns.
    /// </summary>
    public static bool ContainsPii(string? text)
    {
        if (string.IsNullOrEmpty(text))
            return false;

        // Check password keywords first (cheapest)
        if (PasswordKeywordRegex.IsMatch(text))
            return true;

        // Check email
        if (EmailRegex.IsMatch(text))
            return true;

        // Check SSN
        if (SsnRegex.IsMatch(text))
            return true;

        // Check phone
        if (PhoneRegex.IsMatch(text))
            return true;

        // Check credit card (with Luhn validation to reduce false positives)
        foreach (Match match in CreditCardRegex.Matches(text))
        {
            var digits = new string(match.Value.Where(char.IsDigit).ToArray());
            if (digits.Length >= 13 && digits.Length <= 19 && PassesLuhn(digits))
                return true;
        }

        return false;
    }

    /// <summary>
    /// Validates a digit string using the Luhn algorithm.
    /// Returns true if the checksum is valid (mod 10 == 0).
    /// </summary>
    internal static bool PassesLuhn(string digits)
    {
        if (string.IsNullOrEmpty(digits))
            return false;

        int sum = 0;
        bool alternate = false;
        for (int i = digits.Length - 1; i >= 0; i--)
        {
            int n = digits[i] - '0';
            if (n < 0 || n > 9)
                return false;

            if (alternate)
            {
                n *= 2;
                if (n > 9)
                    n -= 9;
            }
            sum += n;
            alternate = !alternate;
        }
        return sum % 10 == 0;
    }
}
