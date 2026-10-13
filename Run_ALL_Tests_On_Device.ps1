Param(
    [string]$DeviceId = "R9ZXA0206LN"
)

$ErrorActionPreference = "Continue"

Write-Host "=========================================================" -ForegroundColor Cyan
Write-Host "   RentaTool LK Mobile - FULL TEST SUITE (ON DEVICE)" -ForegroundColor Cyan
Write-Host "   Target Device ID: $DeviceId" -ForegroundColor Yellow
Write-Host "=========================================================" -ForegroundColor Cyan

Write-Host "`n[PHASE 1/2] Running 229 Unit & Widget Tests on Device..." -ForegroundColor Green
flutter test -d $DeviceId 2>&1 | Tee-Object -FilePath "unit_and_widget_test_device_output.txt"

Write-Host "`n[PHASE 2/2] Running 4 E2E Integration Tests & Capturing Screenshots..." -ForegroundColor Green

$integrationTests = @(
    @{ Name = "1. Auth Flow"; Target = "integration_test/auth_flow_test.dart" },
    @{ Name = "2. Catalog Flow"; Target = "integration_test/catalog_flow_test.dart" },
    @{ Name = "3. Booking Flow"; Target = "integration_test/booking_flow_test.dart" },
    @{ Name = "4. Escrow Flow"; Target = "integration_test/escrow_flow_test.dart" }
)

foreach ($t in $integrationTests) {
    Write-Host "`n---> Executing $($t.Name)..." -ForegroundColor Yellow
    flutter drive --driver=test_driver/integration_test.dart --target=$($t.Target) -d $DeviceId
}

Write-Host "`n=========================================================" -ForegroundColor Cyan
Write-Host "   ALL TESTS COMPLETED ON DEVICE $DeviceId!" -ForegroundColor Green
Write-Host "   - Terminal Output Log: unit_and_widget_test_device_output.txt" -ForegroundColor White
Write-Host "   - Captured Screenshots: screenshots/ folder" -ForegroundColor White
Write-Host "=========================================================" -ForegroundColor Cyan
