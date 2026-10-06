# RentaTool-mobile: PR #1 Copilot Review Fix Guide
**PR #1: `feat(booking): implement booking engine and handover verification`**  
**Author:** Nirojan (@Nirojan02) – Student 3 (Component 3: Booking, QR Handover & Scheduling)  
**Target Branch:** `dev` ← **Source Branch:** `feature/booking-handover`

---

## 📌 Executive Summary

GitHub Copilot automated review flagged **16 issues** (🟡 *Changes recommended*) on PR #1.  
These issues fall into **4 main categories**:
1. **Critical Business Logic & Anti-Fraud Gaps**: Wear-lock bypass, fabricated GPS fallback, unverified success modals, and inverted timeline logic.
2. **Missing Native Platform Permissions**: Missing Android/iOS camera & location permissions and Google Maps keys (will crash on physical devices).
3. **Flutter Async Lifecycle / Memory Leaks**: Missing `if (!mounted) return;` guards before calling `setState(...)` after async HTTP calls.
4. **Windows Desktop Teardown**: Recursive `Destroy()` call in Windows runner.

Follow the actionable fixes below. Once resolved and pushed to `feature/booking-handover`, PR #1 will automatically update and Copilot review can be re-run to turn green.

---

## Part 1: Core Business Logic & Anti-Fraud Fixes (Critical)

### 1. Block Reservations on Wear-Locked Equipment
* **File:** `lib/modules/booking/screens/create_booking_screen.dart`
* **Issue:** The rubric and system specifications mandate that equipment with 60+ cumulative days or under maintenance cannot be booked. The booking screen allowed reservations even if `widget.equipment.isWearLocked` or `requiresMaintenanceCheck` was true.
* **Fix:** Check `isWearLocked` on init and block form submission:
```dart
// In _submitBooking():
if (widget.equipment != null && widget.equipment!.isWearLocked) {
  setState(() {
    _errorMessage = 'Equipment is currently locked out for mandatory 60-day maintenance overhaul. Bookings are disabled.';
  });
  return;
}
```
Also disable the submit button in `build()`:
```dart
AppButton(
  text: (widget.equipment?.isWearLocked ?? false)
      ? 'Locked: 60-Day Maintenance Required'
      : 'Confirm & Reserve Equipment',
  icon: (widget.equipment?.isWearLocked ?? false)
      ? Icons.lock_outline
      : Icons.check_circle_outline,
  isLoading: _isSubmitting,
  onPressed: (widget.equipment?.isWearLocked ?? false) ? null : _submitBooking,
)
```

---

### 2. Disallow Fabricated / Fallback Coordinates for QR Handover
* **Files:**  
  - `lib/modules/booking/services/location_service.dart`  
  - `lib/modules/booking/screens/qr_scanner_screen.dart`
* **Issue:** QR handover verification requires real physical GPS logging to prevent distance fraud. Falling back to default Colombo coordinates (`LocationService.defaultLatitude`, `6.9271`) when GPS is off/denied falsifies handover evidence.
* **Fix in `location_service.dart`:**
Make `getCurrentPosition()` return `null` or throw when GPS is disabled/denied instead of returning a dummy mock location.
* **Fix in `qr_scanner_screen.dart`:**
Require live GPS before submitting verification:
```dart
if (_currentGpsPosition == null) {
  ScaffoldMessenger.of(context).showSnackBar(
    const SnackBar(
      backgroundColor: AppColors.error,
      content: Text('GPS verification required. Please enable location services to verify equipment handover.'),
    ),
  );
  return;
}

final lat = _currentGpsPosition!.latitude;
final lng = _currentGpsPosition!.longitude;
```

---

### 3. Check Verification Response Status Before Showing Success Modal
* **File:** `lib/modules/booking/screens/qr_scanner_screen.dart`
* **Issue:** The scanner shows `_showVerificationSuccessModal` unconditionally after `service.verifyHandover(...)`, even if the API returned an unsuccessful response (`result.isSuccess == false`).
* **Fix:**
```dart
final result = await service.verifyHandover(
  bookingId: bkgId,
  request: request,
);

if (!mounted) return;

if (result.isSuccess) {
  ref.read(bookingProvider.notifier).fetchActiveBookings();
  _showVerificationSuccessModal(result, lat, lng);
} else {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      backgroundColor: AppColors.error,
      content: Text(result.message.isNotEmpty ? result.message : 'Handover verification failed.'),
    ),
  );
}
```

---

### 4. Remove Hardcoded Index-Based Equipment Map Coordinates
* **File:** `lib/modules/booking/screens/booking_map_screen.dart`
* **Issue:** The map loop fabricates coordinates using `((i % 5) - 2) * 0.035` on the list index.
* **Fix:** Use real equipment coordinates if present on the model (e.g., `eq.latitude`, `eq.longitude`), or use a geocoding lookup by `eq.location`. If neither exists, skip placing the pin on the map or display a warning banner rather than generating fake GPS positions.

---

### 5. Fix Inverted Return Verification Timeline Predicate
* **File:** `lib/modules/booking/widgets/booking_timeline_widget.dart`
* **Issue:** In Step 4 of the timeline (`Return Handover & Inspection`), `isCurrent` was set to `booking.isActive && booking.returnVerified`. When `returnVerified` is true, the step is completed (`step4Done`), not current.
* **Fix:**
```dart
_timelineStep(
  index: '4',
  title: 'Return Handover & Inspection',
  desc: booking.returnVerified
      ? 'Equipment returned. Post-rental condition verified.'
      : 'Renter generates return token; owner confirms receipt & physical condition.',
  isCompleted: step4Done,
  isCurrent: booking.isActive && !booking.returnVerified, // <-- Inverted predicate fixed
  isLast: true,
),
```

---

### 6. Fix Date-Only Rental Extension Calculation
* **File:** `lib/modules/booking/widgets/surge_extension_sheet.dart`
* **Issue:** `_newEndDate.difference(widget.booking.endDate).inDays` truncates to integer days if times differ (e.g. 23 hours = 0 days).
* **Fix:** Normalize both to calendar dates:
```dart
int get _extendedDays {
  final d1 = DateTime(widget.booking.endDate.year, widget.booking.endDate.month, widget.booking.endDate.day);
  final d2 = DateTime(_newEndDate.year, _newEndDate.month, _newEndDate.day);
  final diff = d2.difference(d1).inDays;
  return diff <= 0 ? 1 : diff;
}
```

---

## Part 2: Native Mobile Permissions & API Keys (Platform Crashes)

### 7. Android Manifest Permissions & Maps Key
* **File:** `android/app/src/main/AndroidManifest.xml`
* **Issue:** Missing `<uses-permission>` tags for camera, GPS, and internet, causing security exceptions on Android 10+.
* **Fix:** Add before `<application>`:
```xml
    <!-- Hardware & Security Permissions -->
    <uses-permission android:name="android.permission.INTERNET"/>
    <uses-permission android:name="android.permission.CAMERA"/>
    <uses-permission android:name="android.permission.ACCESS_FINE_LOCATION"/>
    <uses-permission android:name="android.permission.ACCESS_COARSE_LOCATION"/>

    <uses-feature android:name="android.hardware.camera" android:required="false"/>
```
And inside `<application>`:
```xml
    <!-- Google Maps API Key -->
    <meta-data
        android:name="com.google.android.geo.API_KEY"
        android:value="${MAPS_API_KEY}"/>
```

---

### 8. iOS Info.plist Usage Descriptions & Maps Key
* **File:** `ios/Runner/Info.plist`
* **Issue:** iOS immediately terminates apps that access Camera or Location without descriptions in `Info.plist`.
* **Fix:** Add inside `<dict>`:
```xml
    <key>NSCameraUsageDescription</key>
    <string>Camera access is required to scan QR handover tokens and capture equipment condition evidence.</string>
    <key>NSLocationWhenInUseUsageDescription</key>
    <string>Location access is required to verify real-time GPS coordinates during tool pickup and return handover.</string>
```
* **File:** `ios/Runner/AppDelegate.swift`
* **Fix:** Add Google Maps initialization:
```swift
import GoogleMaps

@main
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    GMSServices.provideAPIKey("YOUR_IOS_MAPS_API_KEY")
    GeneratedPluginRegistrant.register(with: self)
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
}
```

---

## Part 3: Flutter Async Lifecycle (`mounted` Guards)

When calling `await` in asynchronous methods, navigating away unmounts the widget. Calling `setState()` without an `if (!mounted) return;` guard causes `setState() called after dispose()` exceptions.

### 9. Fix `create_booking_screen.dart` Catch Block
```dart
    } catch (e) {
      if (!mounted) return; // <-- Add guard here
      setState(() {
        _errorMessage = e.toString().replaceFirst('Exception: ', '');
      });
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
```

### 10. Fix `surge_extension_sheet.dart` Error & Update Handlers
```dart
    } catch (e) {
      if (!mounted) return; // <-- Add guard
      setState(() {
        _errorMessage = e.toString().replaceFirst('Exception: ', '');
      });
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
```

### 11. Fix `booking_map_screen.dart` Overlay & Position Updates
In `_initLocationAndData()`, ensure:
```dart
    final pos = await locService.getCurrentPosition();
    if (!mounted) return; // <-- Add guard before updating state
    setState(() {
      _currentPosition = pos;
      _isLoading = false;
    });
    _updateMapOverlays();
```

---

## Part 4: Windows Desktop Teardown Fix

### 12. Fix Recursive Window Destruction in `win32_window.cpp`
* **File:** `windows/runner/win32_window.cpp`
* **Issue:** Under `case WM_DESTROY:`, calling `Destroy()` calls `DestroyWindow(window_handle_)` again while already inside the destruction message handler.
* **Fix:**
```cpp
    case WM_DESTROY:
      window_handle_ = nullptr;
      // Do not call Destroy(); the window is already being destroyed by Windows
      if (quit_on_close_) {
        PostQuitMessage(0);
      }
      return 0;
```

---

## 🚀 How Nirojan Can Apply & Push the Fixes

1. Checkout the feature branch:
   ```bash
   cd RentaTool-mobile
   git checkout feature/booking-handover
   git pull origin feature/booking-handover
   ```
2. Apply the code and configuration fixes listed above.
3. Verify static analysis passes with zero warnings:
   ```bash
   flutter analyze
   ```
4. Commit with conventional commit message:
   ```bash
   git add .
   git commit -m "fix(booking): resolve copilot code review findings for permissions, wear lock, and lifecycle"
   git push origin feature/booking-handover
   ```
5. On GitHub, PR #1 will automatically update with the new commit. Click **"Re-request review"** from Copilot to get a green review, then merge into `dev`!
