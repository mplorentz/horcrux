# Firebase / FCM Setup

Horcrux uses Firebase Cloud Messaging (FCM) to delivier push notifications for vault events.

## One-time setup steps (do these once per environment)

### 1. Create the Firebase project

1. Go to [console.firebase.google.com](https://console.firebase.google.com) and create a new project named `horcrux` (or similar).
2. Disable Google Analytics unless you want it - it's not needed for FCM.

### 2. Register the Android app

1. In the Firebase Console, click "Add app" → Android.
2. Create your own package name like **`com.singleoriginsoftware.horcrux`** (must match `applicationId` in [android/app/build.gradle](../android/app/build.gradle)).
3. Download `google-services.json`.
4. Place it at `android/app/google-services.json`.
5. It is already gitignored - **do not commit** (verify with `git check-ignore android/app/google-services.json`).

### 3. Register the iOS app

1. In the Firebase Console, click "Add app" → iOS.
2. Create your custom bundle ID like **`com.singleoriginsoftware.horcrux`** (must match the iOS `PRODUCT_BUNDLE_IDENTIFIER` in `ios/Runner.xcodeproj/project.pbxproj`).
3. Download `GoogleService-Info.plist`.
4. Open `ios/Runner.xcworkspace` in Xcode, drag `GoogleService-Info.plist` into the `Runner` target (copy if needed, add to target `Runner`).
5. The file should end up at `ios/Runner/GoogleService-Info.plist` and be referenced from the Xcode project. **Do not commit.**

### 4. Generate `lib/firebase_options.dart`

Using the FlutterFire CLI is the recommended path. It stitches the two config files together and produces a platform-agnostic `DefaultFirebaseOptions` class used by `Firebase.initializeApp`.

```bash
# One-time: install the FlutterFire CLI
dart pub global activate flutterfire_cli

# Authenticate with Firebase (uses gcloud/Firebase CLI underneath)
firebase login

# Inside the horcrux_app repo:
flutterfire configure \
  --project=<your-firebase-project-id> \
  --platforms=android,ios,macos \
  --ios-bundle-id=<your-bundle-id> \
  --android-package-name=<your-package-name>
```

This will:

- Re-fetch `google-services.json` and `GoogleService-Info.plist` for iOS and macOS (overwriting any existing ones).
- Generate `lib/firebase_options.dart`.

### 5. APNs setup (iOS only)

For FCM to deliver to iOS, you need to upload an APNs key to Firebase:

1. Apple Developer portal → Keys → create a new key with "Apple Push Notifications service (APNs)" enabled. Download the `.p8`.
2. Firebase Console → Project settings → Cloud Messaging → iOS app → upload the APNs auth key, along with Key ID and Team ID.

You also need to enable the "Push Notifications" capability in Xcode (Runner target → Signing & Capabilities → +Capability → Push Notifications).

## Verification

Once all required artifacts are in place (including macOS `GoogleService-Info.plist` if you build for macOS):

```bash
fvm flutter pub get
fvm flutter run -d android   # or -d ios
```

- On Android, Gradle should apply `google-services` without error.
- On iOS, Xcode should build against `GoogleService-Info.plist` without complaint.
- `Firebase.initializeApp()` in `main.dart` (added in Phase 2) should succeed.
