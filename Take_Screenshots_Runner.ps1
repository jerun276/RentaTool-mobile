$modules = @(
    @{ Name="Identity"; File="test/modules/identity/identity_complete_unit_test.dart" },
    @{ Name="Catalog"; File="test/modules/catalog/catalog_complete_unit_test.dart" },
    @{ Name="Booking"; File="test/modules/booking/booking_complete_unit_test.dart" },
    @{ Name="Escrow"; File="test/modules/escrow/escrow_complete_unit_test.dart" }
)

$reportFile = "$PWD\Comprehensive_Test_Output.txt"
Clear-Content $reportFile -ErrorAction SilentlyContinue

Clear-Host
Write-Host "[START] Starting Interactive Test Runner for Screenshots" -ForegroundColor Cyan
Write-Host "This will run one module at a time, allowing you to take screenshots.`n" -ForegroundColor Gray
Start-Sleep -Seconds 2

foreach ($mod in $modules) {
    Clear-Host
    Write-Host "========================================" -ForegroundColor Yellow
    Write-Host "[TEST] Running tests for: $($mod.Name) Component" -ForegroundColor Yellow
    Write-Host "========================================" -ForegroundColor Yellow
    
    $logHeader = "`n`n========================================`n=== $($mod.Name) COMPONENT TEST OUTPUT ===`n========================================`n"
    Add-Content -Path $reportFile -Value $logHeader

    # Run test and capture output to screen and temp file
    flutter test $mod.File --reporter expanded 2>&1 | Tee-Object -FilePath "temp_out.txt"
    
    # Append to main report
    Get-Content "temp_out.txt" | Add-Content -Path $reportFile

    Write-Host "`n----------------------------------------" -ForegroundColor Cyan
    Write-Host "[SUCCESS] $($mod.Name) tests finished!" -ForegroundColor Green
    Write-Host "[SCREENSHOT] PLEASE TAKE YOUR SCREENSHOT NOW (Windows Key + Shift + S)!" -ForegroundColor Magenta
    Read-Host "Press [Enter] when you are ready to proceed to the next test"
}

# Cleanup temp file
Remove-Item "temp_out.txt" -ErrorAction SilentlyContinue

Clear-Host
Write-Host "[DONE] All tests completed!" -ForegroundColor Green
Write-Host "[FILE] Full raw output report saved to: $reportFile" -ForegroundColor Cyan
Write-Host "Opening report file now..." -ForegroundColor Gray

# Open the compiled txt report
Invoke-Item $reportFile
