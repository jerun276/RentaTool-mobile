# RentaTool-mobile – AI Agent Rules, File Access Tiers & Component Specifications

> **MANDATORY INSTRUCTION FOR AGENTS**:
> This Flutter workspace follows strict multi-developer isolation rules for SE3090 Assignment 1.
> Read `ACTIVE_COMPONENT_ID` below and observe the 4-Tier Access Control System.
> The full specifications for each component (endpoints, entities, UI, and AI agents) are detailed below.

```yaml
# ==============================================================================
# DEVELOPER CONFIGURATION (CHANGE THIS TO YOUR COMPONENT BEFORE PROMPTING)
# ==============================================================================
ACTIVE_STUDENT: "Student 2" # Options: "Student 1" | "Student 2" | "Student 3" | "Student 4" | "Tech Lead"
ACTIVE_COMPONENT_ID: "COMPONENT_2" # Options: "COMPONENT_1" | "COMPONENT_2" | "COMPONENT_3" | "COMPONENT_4" | "SHARED_CORE"
# ==============================================================================
```

---

## 1. 4-Tier Mobile Access Rules

### 🟢 TIER 1: Universal Shared Assets (Read & Use for ALL Members)

All members have unrestricted permission to import and use:

- **Auth Token & User State**: `lib/core/network/auth_interceptor.dart`, `lib/core/services/token_storage_service.dart`, JWT access tokens, current logged-in user profile provider.
- **Shared Theme & UI Tokens**: `lib/core/theme/**` (AppColors, typography, buttons), `lib/core/widgets/**` (app bars, buttons, loading indicators).
- **Network Client**: Pre-configured Dio client with automatic JWT token attachment.

### 🟡 TIER 2: Inter-Module Public Contracts (Read-Only Consumer Access)

- A screen in one module can navigate to another module's public route (e.g. Booking screen navigating to Equipment details).

### 🟠 TIER 3: Composition Points (Append-Only / Isolated Extension)

- `lib/core/routes/app_router.dart`: Only append your module's GoRouter routes.
- `lib/main.dart`: Shared entrypoint (only add module providers).

### 🔴 TIER 4: Exclusive Component Modules (Write Access Only to Active Owner)

- **COMPONENT_1 (Student 1)**: `lib/modules/identity/**`, `test/modules/identity/**`
- **COMPONENT_2 (Student 2)**: `lib/modules/catalog/**`, `test/modules/catalog/**`
- **COMPONENT_3 (Student 3)**: `lib/modules/booking/**`, `test/modules/booking/**`
- **COMPONENT_4 (Student 4)**: `lib/modules/escrow/**`, `test/modules/escrow/**`

> ⛔ If an agent attempts to edit screens or widgets belonging to another component's Tier 4 directory, it **must refuse and halt**.

---

## 2. Complete Component Specifications (Flutter & Shared Backend)

### 🔹 COMPONENT 1: User Identity, Verification & Trust Governance

- **Primary Owner**: Student 1
- **Branch**: `feature/comp1-auth-trust`
- **Flutter Mobile Scope (`lib/modules/identity/`)**:
  - Multi-step registration wizard (`Renter` / `Owner`).
  - Secure token storage with `flutter_secure_storage`.
  - Camera image capture & preview for NIC / driving license upload (`image_picker`).
  - Trust score indicator badge on user profile screen.
- **Backend API Endpoints**:
  - `POST /api/v1/auth/register`
  - `POST /api/v1/auth/login`
  - `POST /api/v1/users/kyc`
  - `GET /api/v1/users/{id}/trust-score`
  - `PATCH /api/v1/users/{id}/verification-status` _(Business-Specific)_

---

### 🔹 COMPONENT 2: Equipment Catalog & Asset Condition Inspection

- **Primary Owner**: Student 2
- **Branch**: `feature/comp2-catalog-inspection`
- **Flutter Mobile Scope (`lib/modules/catalog/`)**:
  - Tool listing creation wizard with photos, specs, daily rate, and replacement value.
  - Equipment feed with search bar, category chips, and pagination.
  - Multi-angle condition inspection camera screen (casing, cord, motor) with timestamp overlays.
- **Backend API Endpoints**:
  - `POST /api/v1/equipment`
  - `GET /api/v1/equipment`
  - `POST /api/v1/equipment/{id}/inspection-logs`
  - `GET /api/v1/equipment/{id}/history`
  - `POST /api/v1/equipment/batch-availability` _(Business-Specific)_

---

### 🔹 COMPONENT 3: Booking Engine & Handover Verification

- **Primary Owner**: Student 3
- **Branch**: `feature/comp3-booking-handover`
- **Flutter Mobile Scope (`lib/modules/booking/`)**:
  - Interactive Map radius search (`google_maps_flutter` & `geolocator`).
  - Single-use encrypted QR code generator for equipment owners (`qr_flutter`).
  - Camera-based QR code scanner for renters (`mobile_scanner`).
  - Rental booking date-picker and status timeline.
- **Backend API Endpoints**:
  - `POST /api/v1/bookings`
  - `GET /api/v1/bookings/active`
  - `POST /api/v1/bookings/{id}/generate-handover-token`
  - `POST /api/v1/bookings/{id}/verify-handover`
  - `POST /api/v1/bookings/{id}/extend-schedule` _(Business-Specific)_

---

### 🔹 COMPONENT 4: Escrow Ledger & Security Deposit Claims

- **Primary Owner**: Student 4
- **Branch**: `feature/comp4-escrow-claims`
- **Flutter Mobile Scope (`lib/modules/escrow/`)**:
  - Pre-authorization deposit hold sheet.
  - Damage dispute filing form with photo evidence upload.
  - Settlement summary screen showing repair deduction and renter balance refund.
- **Backend API Endpoints**:
  - `POST /api/v1/escrow/pre-authorize`
  - `POST /api/v1/claims`
  - `GET /api/v1/claims/{id}`
  - `POST /api/v1/claims/{id}/payout`
  - `POST /api/v1/claims/{id}/adjudicate` _(Business-Specific)_
