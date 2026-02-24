using System.Drawing;
using System.Drawing.Imaging;
using System.IO;
using System.Runtime.InteropServices;

namespace AemeathDesktopPet.Services;

/// <summary>
/// Captures screenshots for sending to AI providers.
/// Uses System.Drawing.Common + P/Invoke for screen capture.
/// </summary>
public static class ScreenCaptureService
{
    [DllImport("user32.dll")]
    private static extern int GetSystemMetrics(int nIndex);

    private const int SM_CXSCREEN = 0;
    private const int SM_CYSCREEN = 1;

    /// <summary>
    /// Captures the primary screen as PNG bytes.
    /// </summary>
    public static byte[] CapturePrimaryScreen()
    {
        int width = GetSystemMetrics(SM_CXSCREEN);
        int height = GetSystemMetrics(SM_CYSCREEN);

        using var bmp = new Bitmap(width, height, PixelFormat.Format32bppArgb);
        using (var g = Graphics.FromImage(bmp))
        {
            g.CopyFromScreen(0, 0, 0, 0, new Size(width, height), CopyPixelOperation.SourceCopy);
        }

        using var ms = new MemoryStream();
        bmp.Save(ms, ImageFormat.Png);
        return ms.ToArray();
    }

    /// <summary>
    /// Captures the primary screen and downscales to fit within maxWidth,
    /// then encodes as JPEG at 70% quality (~200KB vs ~5MB PNG).
    /// </summary>
    public static byte[] CaptureAndDownscale(int maxWidth = 1280)
    {
        int screenW = GetSystemMetrics(SM_CXSCREEN);
        int screenH = GetSystemMetrics(SM_CYSCREEN);

        using var bmp = new Bitmap(screenW, screenH, PixelFormat.Format32bppArgb);
        using (var g = Graphics.FromImage(bmp))
        {
            g.CopyFromScreen(0, 0, 0, 0, new Size(screenW, screenH), CopyPixelOperation.SourceCopy);
        }

        // Downscale if wider than maxWidth
        Bitmap output;
        if (screenW > maxWidth)
        {
            double scale = (double)maxWidth / screenW;
            int newW = maxWidth;
            int newH = (int)(screenH * scale);
            output = new Bitmap(newW, newH, PixelFormat.Format24bppRgb);
            using (var g = Graphics.FromImage(output))
            {
                g.InterpolationMode = System.Drawing.Drawing2D.InterpolationMode.HighQualityBicubic;
                g.DrawImage(bmp, 0, 0, newW, newH);
            }
        }
        else
        {
            output = bmp;
        }

        try
        {
            // Encode as JPEG at 70% quality
            using var ms = new MemoryStream();
            var jpegCodec = ImageCodecInfo.GetImageEncoders()
                .First(c => c.FormatID == ImageFormat.Jpeg.Guid);
            var encoderParams = new EncoderParameters(1);
            encoderParams.Param[0] = new EncoderParameter(Encoder.Quality, 70L);
            output.Save(ms, jpegCodec, encoderParams);
            return ms.ToArray();
        }
        finally
        {
            if (output != bmp)
                output.Dispose();
        }
    }
}
