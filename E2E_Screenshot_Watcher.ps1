Add-Type -AssemblyName System.Drawing
Add-Type -AssemblyName System.Windows.Forms

# Use ABSOLUTE path to avoid GDI+ save error
$projectRoot = "C:\Users\ASUS\Desktop\Rental\RentaTool-mobile"
$screenshotDir = "$projectRoot\test_screenshots"
New-Item -ItemType Directory -Force -Path $screenshotDir | Out-Null

$steps = @(
    @{ WaitSeconds=20;  Label="Step1_Identity_Login" },
    @{ WaitSeconds=55;  Label="Step2_Catalog_Browse" },
    @{ WaitSeconds=90;  Label="Step3_Booking_List" },
    @{ WaitSeconds=130; Label="Step4_Escrow_Dashboard" },
    @{ WaitSeconds=170; Label="Step5_Profile_View" }
)

function Take-Screenshot {
    param([string]$filepath)
    try {
        $bounds = [System.Windows.Forms.Screen]::PrimaryScreen.Bounds
        $bmp = New-Object System.Drawing.Bitmap($bounds.Width, $bounds.Height, [System.Drawing.Imaging.PixelFormat]::Format32bppArgb)
        $gfx = [System.Drawing.Graphics]::FromImage($bmp)
        $gfx.CopyFromScreen($bounds.Location, [System.Drawing.Point]::Empty, $bounds.Size, [System.Drawing.CopyPixelOperation]::SourceCopy)
        $gfx.Flush()
        $gfx.Dispose()
        # Save using full absolute path, no format argument
        $bmp.Save($filepath)
        $bmp.Dispose()
        Write-Host "[SAVED] $filepath" -ForegroundColor Green
    } catch {
        Write-Host "[ERROR] $_" -ForegroundColor Red
    }
}

Write-Host "==========================================================" -ForegroundColor Cyan
Write-Host "[AUTO SCREENSHOT WATCHER] Starting in 3 seconds..." -ForegroundColor Yellow
Write-Host "IMPORTANT: Make sure Chrome is visible on your screen!" -ForegroundColor Magenta
Write-Host "Saving to: $screenshotDir" -ForegroundColor Gray
Write-Host "==========================================================" -ForegroundColor Cyan
Start-Sleep -Seconds 3

$startTime = Get-Date
Write-Host "[START] Timer started at $startTime" -ForegroundColor Gray

foreach ($step in $steps) {
    $elapsed = 0
    while ($elapsed -lt $step.WaitSeconds) {
        $now = (Get-Date) - $startTime
        $elapsed = $now.TotalSeconds
        $remaining = [math]::Round($step.WaitSeconds - $elapsed)
        Write-Host "`r[WAITING] $($step.Label) in ${remaining}s...   " -NoNewline -ForegroundColor DarkYellow
        Start-Sleep -Milliseconds 500
    }
    Write-Host ""
    # Build full absolute path with .png extension
    $timestamp = Get-Date -Format "HHmmss"
    $filename = "$screenshotDir\$($step.Label)_$timestamp.png"
    Write-Host "[SNAP] Capturing: $($step.Label)" -ForegroundColor Cyan
    Take-Screenshot -filepath $filename
}

Write-Host ""
Write-Host "==========================================================" -ForegroundColor Cyan
Write-Host "[DONE] All 5 E2E screenshots captured!" -ForegroundColor Green
Write-Host "Folder: $screenshotDir" -ForegroundColor Cyan
Write-Host "==========================================================" -ForegroundColor Cyan
Invoke-Item $screenshotDir

