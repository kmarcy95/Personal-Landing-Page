# Generates a 1200x630 branded OG share card.
# Output: images/og.png

Add-Type -AssemblyName System.Drawing

$root = Split-Path -Parent $PSScriptRoot
$outPath = Join-Path $root 'images\og.png'

$width = 1200
$height = 630
$bmp = New-Object System.Drawing.Bitmap $width, $height
$g = [System.Drawing.Graphics]::FromImage($bmp)
$g.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::AntiAlias
$g.TextRenderingHint = [System.Drawing.Text.TextRenderingHint]::AntiAliasGridFit

# Background: dark base
$g.Clear([System.Drawing.Color]::FromArgb(255, 6, 6, 8))

# Violet glow orb (top-right)
$orbPoints = [System.Drawing.PointF[]]@(
  [System.Drawing.PointF]::new(900, 0),
  [System.Drawing.PointF]::new(1200, 0),
  [System.Drawing.PointF]::new(1200, 400),
  [System.Drawing.PointF]::new(900, 400)
)
$orbBrush = New-Object System.Drawing.Drawing2D.PathGradientBrush -ArgumentList (,$orbPoints)
$orbBrush.CenterColor = [System.Drawing.Color]::FromArgb(180, 122, 77, 255)
$orbBrush.SurroundColors = @([System.Drawing.Color]::FromArgb(0, 122, 77, 255))
$g.FillEllipse($orbBrush, 700, -200, 700, 700)

# Secondary glow (bottom-left)
$orbPoints2 = [System.Drawing.PointF[]]@(
  [System.Drawing.PointF]::new(0, 400),
  [System.Drawing.PointF]::new(400, 400),
  [System.Drawing.PointF]::new(400, 700),
  [System.Drawing.PointF]::new(0, 700)
)
$orbBrush2 = New-Object System.Drawing.Drawing2D.PathGradientBrush -ArgumentList (,$orbPoints2)
$orbBrush2.CenterColor = [System.Drawing.Color]::FromArgb(120, 160, 107, 255)
$orbBrush2.SurroundColors = @([System.Drawing.Color]::FromArgb(0, 160, 107, 255))
$g.FillEllipse($orbBrush2, -150, 350, 500, 500)

# KEITH wordmark
$wordmarkFont = New-Object System.Drawing.Font 'Arial Black', 140, ([System.Drawing.FontStyle]::Bold)
$wordmarkBrush = New-Object System.Drawing.SolidBrush ([System.Drawing.Color]::FromArgb(255, 244, 241, 255))
$g.DrawString('KEITH', $wordmarkFont, $wordmarkBrush, 80, 200)

# Tagline
$taglineFont = New-Object System.Drawing.Font 'Segoe UI', 26, ([System.Drawing.FontStyle]::Regular)
$taglineBrush = New-Object System.Drawing.SolidBrush ([System.Drawing.Color]::FromArgb(255, 155, 150, 180))
$g.DrawString('Watch live * Unlock the library * Real moments', $taglineFont, $taglineBrush, 92, 380)

# Domain footer
$domainFont = New-Object System.Drawing.Font 'Segoe UI', 22, ([System.Drawing.FontStyle]::Bold)
$domainBrush = New-Object System.Drawing.SolidBrush ([System.Drawing.Color]::FromArgb(255, 160, 107, 255))
$g.DrawString('keith-links-995.pages.dev', $domainFont, $domainBrush, 92, 520)

# Save
$bmp.Save($outPath, [System.Drawing.Imaging.ImageFormat]::Png)
$g.Dispose()
$bmp.Dispose()
Write-Host "Wrote $outPath"
