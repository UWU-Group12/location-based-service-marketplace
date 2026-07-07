# Implementation Plan - Onboarding and Auth Flow

Implement a comprehensive onboarding, role selection, and authentication flow using Firebase Auth and Flutter.

## User Review Required

- **Onboarding Content**: I will use placeholder images and text for the onboarding screens. You may want to provide specific assets later.
- **Role Selection**: I will implement a screen to select between "Service Provider" and "Client". This choice will be passed to the registration screen.
- **Firebase Setup**: Ensure Email/Password and Google Sign-in are enabled in the Firebase Console.
- **Google Sign-in**: Implementation of Google Sign-in requires platform-specific configuration (SHA-1 for Android, URL scheme for iOS). I will provide the code structure, but you might need to finalize the setup.

## Proposed Changes

### Dependencies

#### [pubspec.yaml](file:///D:/Programming/location-based-service-marketplace/service_finder_app/pubspec.yaml)
- Add `shared_preferences` for tracking first-time launch.
- Add `google_sign_in` for Google Authentication.
- Add `smooth_page_indicator` for the onboarding dots.
- Add `font_awesome_flutter` for social icons if needed (or use Material icons).

---

### Core Logic & Services

#### [NEW] [auth_service.dart](file:///D:/Programming/location-based-service-marketplace/service_finder_app/lib/services/auth_service.dart)
- Handle Email/Password registration and login.
- Handle Google Sign-in.
- Handle Password Reset.

#### [NEW] [pref_service.dart](file:///D:/Programming/location-based-service-marketplace/service_finder_app/lib/services/pref_service.dart)
- Handle checking and setting "first time launch" flag using `shared_preferences`.

---

### Screens

#### [main.dart](file:///D:/Programming/location-based-service-marketplace/service_finder_app/lib/main.dart)
- Initialize Firebase.
- Determine initial route (Onboarding vs RoleSelection/Auth).
- Listen to Auth state.

#### [NEW] [onboarding_screen.dart](file:///D:/Programming/location-based-service-marketplace/service_finder_app/lib/screens/onboarding_screen.dart)
- 3-page introduction using `PageView`.
- Includes "Skip" and "Next/Get Started" buttons.
- Navigates to `RoleSelectionScreen` upon completion.

#### [NEW] [role_selection_screen.dart](file:///D:/Programming/location-based-service-marketplace/service_finder_app/lib/screens/role_selection_screen.dart)
- UI to select "Service Provider" or "Client".

#### [NEW] [login_screen.dart](file:///D:/Programming/location-based-service-marketplace/service_finder_app/lib/screens/login_screen.dart)
- Unified login for both roles.
- Email, Password, Forgot Password, Google Login, Link to Signup.

#### [NEW] [register_screen.dart](file:///D:/Programming/location-based-service-marketplace/service_finder_app/lib/screens/register_screen.dart)
- Unified registration form: First Name, Last Name, Mobile, Email, Password.
- Register Now, Google Login.
- Handles role logic (e.g., tags user in Firestore).

---

## Verification Plan

### Automated Tests
- N/A for this phase (UI and Auth heavy).

### Manual Verification
1. **First Launch**: Verify Onboarding appears only on the first run.
2. **Role Selection**: Verify clicking a role leads to the registration page with the correct context.
3. **Login Flow**:
   - Test login with valid/invalid credentials.
   - Test "Forgot Password" triggers email.
4. **Registration Flow**:
   - Test account creation for both roles.
   - Verify Google Sign-in UI (and logic if configured).
5. **Persistence**: Verify the app opens to the Home screen if already logged in.
