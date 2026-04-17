# Firebase / FCM Setup

Horcrux uses Firebase Cloud Messaging (FCM) for silent push wake-up notifications as part of the NIP-9a relay push flow. The push payload is content-free - it just wakes the app, which then connects to its relays and shows local notifications based on what it finds.

## Status

The Flutter/Gradle/iOS wiring for Firebase is already in place:

- `firebase_core` and `firebase_messaging` are declared in [pubspec.yaml](../pubspec.yaml).
- Android has the `com.google.gms.google-services` plugin applied in [android/settings.gradle](../android/settings.gradle) and [android/app/build.gradle](../android/app/build.gradle), with `minSdk = 23`.
- iOS has `remote-notification` + `fetch` background modes and `FirebaseAppDelegateProxyEnabled=true` in [ios/Runner/Info.plist](../ios/Runner/Info.plist), and the Podfile pins `platform :ios, '13.0'`.

What's still required before the app can build and talk to FCM:

1. **A Firebase project** on the Google Firebase Console.
2. **`android/app/google-services.json`** downloaded from that project's Android app registration.
3. **`ios/Runner/GoogleService-Info.plist`** downloaded from that project's iOS app registration, added to the Xcode project.
4. **`macos/Runner/GoogleService-Info.plist`** for macOS FCM (same Firebase iOS app as iOS; FlutterFire writes it here). **Do not commit** — it is listed in `.gitignore`. Use `macos/Runner/GoogleService-Info.plist.example` as a shape reference only.
5. **`lib/firebase_options.dart`** generated via `flutterfire configure` (optional but recommended — required for `Firebase.initializeApp(options: ...)`).

These files contain project identifiers and API keys that are tied to a specific Firebase account, so they can't be committed by the AI agent. See the instructions below.

## One-time setup steps (do these once per environment)

### 1. Create the Firebase project

1. Go to [console.firebase.google.com](https://console.firebase.google.com) and create a new project named `horcrux` (or similar).
2. Disable Google Analytics unless you want it - it's not needed for FCM.

### 2. Register the Android app

1. In the Firebase Console, click "Add app" → Android.
2. Use package name **`com.singleoriginsoftware.horcrux`** (must match `applicationId` in [android/app/build.gradle](../android/app/build.gradle)).
3. Download `google-services.json`.
4. Place it at `android/app/google-services.json`.
5. It is already gitignored - **do not commit** (verify with `git check-ignore android/app/google-services.json`).

### 3. Register the iOS app

1. In the Firebase Console, click "Add app" → iOS.
2. Use bundle ID **`com.singleoriginsoftware.horcrux`** (must match the iOS `PRODUCT_BUNDLE_IDENTIFIER` in `ios/Runner.xcodeproj/project.pbxproj`).
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
  --ios-bundle-id=com.singleoriginsoftware.horcrux \
  --android-package-name=com.singleoriginsoftware.horcrux
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

## Privacy note

The FCM payload Horcrux sends is intentionally content-free:

```json
{ "data": { "type": "relay_event" } }
```

No event IDs, relay URLs, pubkeys, or secrets are sent through Google's infrastructure. The app wakes up, connects to its own configured relays, and decides locally whether to display a notification.
