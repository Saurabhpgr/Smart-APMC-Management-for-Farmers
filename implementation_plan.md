# Goal Description

Build a fully functional, production-ready mobile application called "Smart APMC Management System for Farmers". The application will use Flutter for the mobile app and Firebase as the primary backend for authentication and database storage (Firestore). A supplementary Node.js backend will be configured for specific admin operations.

> [!IMPORTANT]
> **User Review Required: Firebase Configuration Files**
> The system requires your existing Firebase configuration files. Please ensure you place `google-services.json` inside the `smart_apmc/android/app` directory (once created) and `serviceAccountKey.json` inside the `backend` directory.

## Open Questions

> [!WARNING]
> - Are you okay with using **Provider** for state management and **GoRouter** for routing in the Flutter app?
> - For Google Sign-in, have you enabled Google Auth in your Firebase Console and added the SHA-1 key of your local machine?

## Proposed Changes

### 1. Project Initialization
- Create a new Flutter project named `smart_apmc`.
- Initialize a Node.js project named `backend`.

### 2. Dependencies
- **Flutter**: `firebase_core`, `firebase_auth`, `cloud_firestore`, `google_sign_in`, `provider`, `go_router`, `intl` (for dates).
- **Node.js**: `express`, `firebase-admin`, `cors`, `dotenv`.

### 3. Database Schema (Firestore)
- **farmers**: `{ uid, name, email, phone, aadhaar, village, district, state, role: 'farmer', createdAt }`
- **traders**: `{ uid, name, email, phone, business_name, license_number, role: 'trader', createdAt }`
- **admins**: `{ uid, name, email, phone, role: 'admin', createdAt }`
- **products**: `{ id, name, category }`
- **slots**: `{ id, date, time, max_capacity, current_capacity }`
- **bookings**: `{ id, farmer_id, product_id, quantity, slot_id, status }`
- **bids**: `{ id, trader_id, product_id, bid_price, timestamp }`
- **sales**: `{ id, farmer_id, trader_id, final_price, date }`
- **payments**: `{ id, sale_id, amount, payment_status, payment_date }`
- **marketPrices**: `{ product_id, min_price, max_price, avg_price, date }`

### 4. Authentication Flow
- **Registration**: Email/Password + Role Selection (Farmer, Trader, Admin). Automatically provisions the user in the respective Firestore collection.
- **Google Auth**: Attempts sign in. If no document exists in `farmers`, `traders`, or `admins`, navigates to an onboarding screen to select a role.
- **Role-Based Navigation**: Redirects to `FarmerDashboard`, `TraderDashboard`, or `AdminDashboard` based on the fetched Firestore document.

### 5. Application Modules
#### [NEW] Farmer Module
- Dashboard with quick actions.
- Slot Booking interface.
- Market price viewing (with offline caching capability using Firestore offline persistence).
- Payments and Bidding results tracking.

#### [NEW] Trader Module
- Dashboard with available market products.
- Real-time bidding interface on active products.
- Pending payments processing.

#### [NEW] Admin Module
- Overall control panel for user approvals.
- Market price entry form.
- Slot creation tool.

#### [NEW] Backend (Node.js)
- Server setup with `firebase-admin` to securely process complex admin logic (e.g., aggregating reports, resolving auctions automatically).

## Verification Plan

### Automated/Unit Tests
- Basic widget testing for the core UI components.
- Mocked database operations to verify state management behavior.

### Manual Verification
- Compile and run the Flutter app (Android/Windows).
- Test the full registration and login flow with a dummy user.
- Verify in the Firebase Console that documents are created correctly with the Auth UID.
- Perform an end-to-end flow: Admin creates a slot -> Farmer books a slot -> Trader bids -> Sale created -> Payment tracked.
