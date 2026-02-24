Add-Type -AssemblyName System.Drawing

$gifPath = Join-Path $PSScriptRoot "..\src\AemeathDesktopPet\Resources\Sprites\Aemeath\normal.gif"
$icoPath = Join-Path $PSScriptRoot "..\src\AemeathDesktopPet\Resources\Icons\tray_icon.ico"

# Load first frame of GIF
$gif = [System.Drawing.Image]::FromFile((Resolve-Path $gifPath).Path)

# Create resized PNG images for ICO sizes
$sizes = @(16, 32, 48, 256)
$pngDataList = @()

foreach ($size in $sizes) {
    $bmp = New-Object System.Drawing.Bitmap($size, $size)
    $g = [System.Drawing.Graphics]::FromImage($bmp)
    $g.InterpolationMode = [System.Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic
    $g.CompositingQuality = [System.Drawing.Drawing2D.CompositingQuality]::HighQuality
    $g.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::HighQuality
    $g.Clear([System.Drawing.Color]::Transparent)
    $g.DrawImage($gif, 0, 0, $size, $size)
    $g.Dispose()

    $ms = New-Object System.IO.MemoryStream
    $bmp.Save($ms, [System.Drawing.Imaging.ImageFormat]::Png)
    $pngDataList += ,($ms.ToArray())
    $ms.Dispose()
    $bmp.Dispose()
}
$gif.Dispose()

# Build ICO file
$fs = [System.IO.File]::Create($icoPath)
$bw = New-Object System.IO.BinaryWriter($fs)

# ICO Header
$bw.Write([uint16]0)
$bw.Write([uint16]1)
$bw.Write([uint16]$sizes.Count)

# Calculate data offset
$dataOffset = 6 + (16 * $sizes.Count)

# Write directory entries
for ($i = 0; $i -lt $sizes.Count; $i++) {
    $s = $sizes[$i]
    $data = $pngDataList[$i]
    if ($s -ge 256) {
        $bw.Write([byte]0)
        $bw.Write([byte]0)
    } else {
        $bw.Write([byte]$s)
        $bw.Write([byte]$s)
    }
    $bw.Write([byte]0)
    $bw.Write([byte]0)
    $bw.Write([uint16]1)
    $bw.Write([uint16]32)
    $bw.Write([uint32]$data.Length)
    $bw.Write([uint32]$dataOffset)
    $dataOffset += $data.Length
}

# Write PNG image data
for ($i = 0; $i -lt $sizes.Count; $i++) {
    $bw.Write($pngDataList[$i])
}

$bw.Close()
$fs.Close()

$fileInfo = Get-Item $icoPath
Write-Host "Icon created: $($fileInfo.FullName) ($($fileInfo.Length) bytes)"
