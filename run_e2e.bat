@echo off
echo ====================================================
echo RentaTool E2E Web Automated Testing
echo ====================================================

echo [1/3] Starting Chromedriver (v154) on port 4444...
start "Chromedriver" /min cmd /c "%~dp0chromedriver.exe --port=4444"
timeout /t 4 /nobreak >nul

echo [2/3] Running Flutter Drive E2E Tests (screenshots auto-saved)...
flutter drive --driver=test_driver/integration_test.dart --target=integration_test/app_test.dart -d web-server --browser-name=chrome

echo.
echo [3/3] E2E Testing Complete!
echo Screenshots saved in: screenshots\
echo.
pause
