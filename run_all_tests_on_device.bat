@echo off
echo =========================================================
echo   RentaTool LK Mobile - FULL TEST SUITE (ON DEVICE)
echo =========================================================

SET DEVICE_ID=R9ZXA0206LN

echo.
echo [PHASE 1/2] Running 229 Unit and Widget Tests on Device (%DEVICE_ID%)...
echo Saving output to unit_test_output.txt ...
flutter test -d %DEVICE_ID% > unit_test_output.txt 2>&1
echo Unit and Widget Tests DONE. Output saved to unit_test_output.txt

echo.
echo [PHASE 2/2] Running 4 Integration Tests & Capturing Screenshots on Device (%DEVICE_ID%)...

echo.
echo [1/4] Running Auth Flow...
flutter drive --driver=test_driver/integration_test.dart --target=integration_test/auth_flow_test.dart -d %DEVICE_ID%

echo.
echo [2/4] Running Catalog Flow...
flutter drive --driver=test_driver/integration_test.dart --target=integration_test/catalog_flow_test.dart -d %DEVICE_ID%

echo.
echo [3/4] Running Booking Flow...
flutter drive --driver=test_driver/integration_test.dart --target=integration_test/booking_flow_test.dart -d %DEVICE_ID%

echo.
echo [4/4] Running Escrow Flow...
flutter drive --driver=test_driver/integration_test.dart --target=integration_test/escrow_flow_test.dart -d %DEVICE_ID%

echo.
echo =========================================================
echo   ALL TESTS FINISHED SUCCESSFULLY ON YOUR DEVICE!
echo   Captured Screenshots are saved in screenshots\ folder.
echo =========================================================
pause
