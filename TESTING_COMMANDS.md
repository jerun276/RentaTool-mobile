# RentaTool Mobile & UI Automation — Test Execution Guide

This document lists all commands to run Flutter mobile unit/widget tests, Flutter device integration tests, and Playwright automated visual UI tests for **SE3110 Quality Management in Software Engineering**.

---

## 1. Flutter Unit & Widget Tests

Run all commands from the repository root: `c:\Users\jerun\OneDrive\Desktop\SEF\SEF_Project\RentaTool-mobile`.

### Run All Mobile Unit & Widget Tests
Executes all 33 Flutter tests verifying state management, models, Riverpod providers, and UI widgets:
```powershell
flutter test
```

### Run Widget Tests Specifically
Runs the UI widget test suite (`widget_test.dart`):
```powershell
flutter test test/widget_test.dart
```

---

## 2. Playwright Automated UI & E2E Testing Suite

Playwright automates end-to-end browser user journeys against the running RentaTool Web client. It tests:
- **TC-01**: App Boot & Canvas Initialization
- **TC-02**: Form Interaction & Validation Error Triggers
- **TC-03**: Responsive Layouts across Mobile ($375\text{px}$), Tablet ($768\text{px}$), and Desktop ($1280\text{px}$)
- **TC-04**: Route Transition to Registration Screen
- **TC-05**: Web Load Performance & Render Timing Budget
- **TC-06**: Interactive Visual Smoke & Keyboard Input Flow

### Step 1: Start the Web Server
In **Terminal 1**, start Flutter web server:
```powershell
cd c:\Users\jerun\OneDrive\Desktop\SEF\SEF_Project\RentaTool-mobile
flutter run -d web-server --web-port 8080
```
*(Leave this running at `http://localhost:8080`)*

### Step 2: Run Playwright Tests
In **Terminal 2**, navigate to the Playwright directory:
```powershell
cd c:\Users\jerun\OneDrive\Desktop\SEF\SEF_Project\RentaTool-mobile\playwright_tests
```

Run any of the following modes:

- **Headed Mode** *(Watch Google Chrome execute live on your screen)*:
  ```powershell
  npx playwright test --headed
  ```

- **Silent / Headless Background Run**:
  ```powershell
  npx playwright test
  ```

- **Interactive UI Dashboard**:
  ```powershell
  npx playwright test --ui
  ```

- **Open the Interactive HTML Test Report**:
  ```powershell
  npx playwright show-report
  ```

---

## 3. Flutter Integration Tests (On Device / Emulator)

To run integration tests directly against a connected physical Android device or emulator:

### Check Connected Devices
```powershell
flutter devices
```

### Run All Integration Tests
```powershell
flutter test integration_test/app_test.dart -d <device_id>
```

### Run Specific Flow Integration Tests
- **Authentication Flow**:
  ```powershell
  flutter test integration_test/auth_flow_test.dart -d <device_id>
  ```

- **Catalog Flow**:
  ```powershell
  flutter test integration_test/catalog_flow_test.dart -d <device_id>
  ```

- **Booking Flow**:
  ```powershell
  flutter test integration_test/booking_flow_test.dart -d <device_id>
  ```

- **Escrow Flow**:
  ```powershell
  flutter test integration_test/escrow_flow_test.dart -d <device_id>
  ```
