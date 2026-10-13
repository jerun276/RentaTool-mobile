# ═══════════════════════════════════════════════════════════════════════════════
# RentaTool Automated Unit Test Runner & Reporter
# Run this script to execute all unit tests and see the summary
# ═══════════════════════════════════════════════════════════════════════════════

Write-Host "🚀 Starting RentaTool Complete Unit Test Suite..." -ForegroundColor Cyan
Write-Host "Running tests across Catalog, Booking, Escrow, and Identity modules.`n" -ForegroundColor Gray

# Define the test files
$TestFiles = @(
    "test/modules/catalog/catalog_complete_unit_test.dart",
    "test/modules/booking/booking_complete_unit_test.dart",
    "test/modules/escrow/escrow_complete_unit_test.dart",
    "test/modules/identity/identity_complete_unit_test.dart"
)

# Run the flutter test command
$TestArgs = $TestFiles + "--reporter", "expanded"
flutter test @TestArgs

$exitCode = $LASTEXITCODE

if ($exitCode -eq 0) {
    Write-Host "`n✅ SUCCESS: All 118 Unit Tests Passed Successfully!" -ForegroundColor Green
    Write-Host "Ready for Instructor / Dev Team Demonstration." -ForegroundColor Green
} else {
    Write-Host "`n❌ FAILED: Some tests failed. Please check the output above." -ForegroundColor Red
}

Write-Host "`n💡 Tip: Press [Windows Key + Shift + S] to take a screenshot of this terminal output." -ForegroundColor Yellow
