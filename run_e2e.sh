
#!/bin/bash
echo "===================================================="
echo "RentaTool E2E Web Automated Testing"
echo "===================================================="

echo "[1/3] Starting Chromedriver..."
chromedriver --port=4444 &
CHROME_PID=$!
sleep 3

echo "[2/3] Running Flutter Drive for E2E Web Integration Tests..."
flutter drive --driver=test_driver/integration_test.dart --target=integration_test/app_test.dart -d web-server --browser-name=chrome

echo "[3/3] Shutting down Chromedriver..."
kill $CHROME_PID

echo "E2E Testing Complete. Screenshots are saved in the 'screenshots' folder."

