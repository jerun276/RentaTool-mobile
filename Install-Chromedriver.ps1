$ProgressPreference = 'SilentlyContinue'
$version = "154.0.8037.97"
$url = "https://storage.googleapis.com/chrome-for-testing-public/154.0.8037.97/win64/chromedriver-win64.zip"
$zipFile = "$PWD\chromedriver.zip"
$extractPath = "$PWD\chromedriver_temp"

Write-Host "================================================" -ForegroundColor Cyan
Write-Host "Downloading Chromedriver v$version..." -ForegroundColor Yellow
Write-Host "================================================" -ForegroundColor Cyan

try {
    Invoke-WebRequest -Uri $url -OutFile $zipFile
    Write-Host "Download complete. Extracting..." -ForegroundColor Green
    
    Expand-Archive -Path $zipFile -DestinationPath $extractPath -Force
    
    # Move the exe to the root
    Move-Item -Path "$extractPath\chromedriver-win64\chromedriver.exe" -Destination "$PWD\chromedriver.exe" -Force
    
    # Cleanup
    Remove-Item -Path $zipFile -Force
    Remove-Item -Path $extractPath -Recurse -Force
    
    Write-Host "`n✅ SUCCESS! Chromedriver is now installed in your folder." -ForegroundColor Green
    Write-Host "You can now run: .\run_e2e.bat" -ForegroundColor Magenta
} catch {
    Write-Host "`n❌ FAILED to download or extract." -ForegroundColor Red
    Write-Host $_.Exception.Message
}
