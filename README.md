# RentaTool Mobile Application 🛠️📱

Cross-platform Flutter application for the **RentaTool** P2P & Commercial Equipment Rental Platform, built with **Flutter (Material 3 Dark Theme)**, **Riverpod 2.x**, **GoRouter**, and **Dio**.

---

## 🏛️ 4-Tier Architecture & Modular Boundaries

To maintain strict isolation and prevent cross-boundary Git merge conflicts, the codebase strictly enforces the **4-Tier Mobile Access Rules**:

```
lib/
├── core/                         # [Tier 1: Universal Shared Assets]
│   ├── constants/api_constants.dart
│   ├── network/api_client.dart & auth_interceptor.dart
│   ├── routes/app_router.dart    # [Tier 3: Composition Point]
│   ├── services/token_storage_service.dart
│   ├── theme/app_colors.dart & app_theme.dart
│   └── widgets/                  # Shared atomic UI components
└── modules/                      # [Tier 4: Component Modules]
    ├── identity/                 # Student 1: Auth, KYC Verification & Trust Scores
    ├── catalog/                  # Student 2: Equipment Catalog, Wear Tracking & Inspections
    ├── booking/                  # Student 3: Reservation Lifecycle, Handover Tokens & QR Scan
    └── escrow/                   # Student 4: Security Deposits, Payouts & Damage Claims
```

### Component Ownership & Branch Assignment

| Student | Module Scope | Feature Branch | Key Deliverables |
|---|---|---|---|
| **Student 1** | `lib/modules/identity/` | `feature/identity-trust` | Login, Register, KYC submission, Trust badge & Profile |
| **Student 2** | `lib/modules/catalog/` | `feature/catalog-wear` | Equipment list/detail, Equipment creation, Condition inspection, Wear progress |
| **Student 3** | `lib/modules/booking/` | `feature/booking-handover` | Active/past bookings, booking details, QR code generation, Handover scanner |
| **Student 4** | `lib/modules/escrow/` | `feature/escrow-claims` | Escrow hold list, Security deposit breakdown, Damage claims, Evidence submission |

---

## 🚀 Getting Started

### 1. Prerequisites
- **Flutter SDK**: `>= 3.19.0`
- **Dart SDK**: `>= 3.3.0`
- **RentaTool Backend**: Running on `http://localhost:5000` (or `http://10.0.2.2:5000` inside Android Emulator)

### 2. Dependency Setup
```bash
flutter pub get
```

### 3. Backend URL Configuration
The app automatically detects the runtime platform:
- **Android Emulator**: Resolves to `http://10.0.2.2:5000/api`
- **iOS Simulator / Desktop / Web**: Resolves to `http://localhost:5000/api`
- Custom IP: Override `API_BASE_URL` in `lib/core/constants/api_constants.dart` if testing on a physical mobile device via WiFi.

### 4. Running the App
```bash
# Run on connected device / emulator
flutter run

# Run specifically on Chrome (for quick UI testing)
flutter run -d chrome
```

---

## 🧪 Testing & Code Quality

Execute static analysis and the automated test suite before committing:

```bash
# 1. Analyze code for lints or compilation warnings
dart analyze

# 2. Run unit and widget test suite
flutter test
```

### Test Coverage
- `test/widget_test.dart`: Verifies app bootstrap, theme application, and GoRouter initialization.
- `test/modules/identity/identity_test.dart`: Verifies User, KYC, and TrustScore data models and JSON serialization.
- `test/modules/catalog/catalog_test.dart`: Verifies Equipment, wear calculation, and inspection models.
- `test/modules/booking/booking_test.dart`: Verifies Booking lifecycle, handover token models, and status helpers.
- `test/modules/escrow/escrow_test.dart`: Verifies Escrow hold amounts, damage claim models, and status flags.

---

## 🌿 Contribution Workflow for Teammates

1. **Pull latest `main`**:
   ```bash
   git checkout main
   git pull origin main
   ```
2. **Checkout your assigned branch**:
   ```bash
   # Student 1
   git checkout -b feature/identity-trust
   # Student 2
   git checkout -b feature/catalog-wear
   # Student 3
   git checkout -b feature/booking-handover
   # Student 4
   git checkout -b feature/escrow-claims
   ```
3. **Develop within your module**:
   - Only edit files inside your designated `lib/modules/<your_module>/` directory.
   - Use `ApiClient` and shared widgets from `lib/core/` without modifying core infrastructure.
   - If a new route or core dependency is strictly required, consult the Tech Lead.
4. **Test & Push**:
   ```bash
   dart analyze
   flutter test
   git add .
   git commit -m "feat(module): implement feature xyz"
   git push origin feature/<your-branch>
   ```
