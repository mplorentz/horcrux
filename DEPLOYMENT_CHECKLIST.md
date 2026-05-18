# App Store & Google Play Store Deployment Checklist

This checklist covers everything needed to distribute Horcrux via Apple App Store and Google Play Store, including beta testing through TestFlight and Google Play Internal Testing.

## 📋 Prerequisites

### Apple Developer Account

- [x] **Apple Developer Program membership** ($99/year)
  - Sign up at: https://developer.apple.com/programs/
  - Required for TestFlight and App Store distribution
  - Processing can take 24-48 hours

### Google Play Console Account

- [x] **Google Play Console account** ($25 one-time registration fee)
  - Sign up at: https://play.google.com/console/
  - Required for Play Store distribution
  - Processing is usually instant

### Legal & Policy Requirements

- [ ] **Privacy Policy URL** (Required for both stores)
  - Must be publicly accessible
  - Must cover data collection, usage, and user rights
  - Can be hosted on your website or GitHub Pages

---

## 🍎 iOS (Apple App Store) Setup

### 1. App Store Connect Configuration

- [x] Create app record in App Store Connect
  - Go to: https://appstoreconnect.apple.com/
  - Click "My Apps" → "+" → "New App"
  - Bundle ID: `com.singleoriginsoftware.horcrux`
  - App Name: "Horcrux"
  - Primary Language: English (or your preference)
  - SKU: `horcrux-001` (or your preferred SKU)

- [ ] Complete App Information
  - [ ] App Name
  - [ ] Subtitle (optional, 30 characters max)
  - [ ] Category: Select appropriate categories (e.g., Utilities, Productivity)
  - [ ] Privacy Policy URL (required)
  - [ ] Support URL
  - [ ] Marketing URL (optional)

- [ ] App Store Listing
  - [ ] App description (up to 4000 characters)
  - [ ] Keywords (100 characters max)
  - [ ] Promotional text (optional, 170 characters)
  - [ ] Screenshots (required):
    - [ ] iPhone 6.7" (1290 x 2796 pixels) - at least 1
    - [ ] iPhone 6.5" (1284 x 2778 pixels) - at least 1
    - [ ] iPad Pro 12.9" (2048 x 2732 pixels) - at least 1 (if supporting iPad)
  - [ ] App Preview videos (optional)
  - [ ] App Icon (1024 x 1024 pixels, PNG, no transparency)

### 2. iOS Code Signing & Certificates

- [ ] Generate App Store Distribution Certificate
  - In Xcode: Xcode → Settings → Accounts → Select your team → Manage Certificates
  - Or via Apple Developer Portal: Certificates, Identifiers & Profiles

- [ ] Create App ID (if not already created)
  - Bundle ID: `com.singleoriginsoftware.horcrux`
  - Enable required capabilities (e.g., Keychain Sharing if using FlutterSecureStorage)

- [ ] Create Provisioning Profile
  - Type: App Store Distribution
  - App ID: `com.singleoriginsoftware.horcrux`
  - Certificate: Your distribution certificate

- [ ] Configure Xcode project
  - Open `ios/Runner.xcworkspace` in Xcode
  - Select Runner target → Signing & Capabilities
  - Select your team
  - Ensure "Automatically manage signing" is enabled (recommended)
  - Or manually configure provisioning profile

### 3. iOS Build Configuration

- [x] Verify bundle identifier: `com.singleoriginsoftware.horcrux` ✅ (Already configured)
- [x] Verify app display name: "Horcrux" ✅ (Already configured)
- [x] Verify version number in `pubspec.yaml`: `1.0.0+1`
- [x] Ensure app icons are configured (1024x1024 required)
- [x] Configure launch screen (already configured)

### 4. iOS Build & Upload

- [x] Build iOS release archive

  ```bash
  flutter build ipa --release
  ```

  Or via Xcode:
  - Product → Archive
  - Wait for archive to complete

- [x] Upload to App Store Connect
  - In Xcode: Window → Organizer → Select archive → Distribute App
  - Or use: `xcrun altool --upload-app --file app.ipa --apiKey YOUR_API_KEY --apiIssuer YOUR_ISSUER_ID`
  - Or use Transporter app

### 5. TestFlight Beta Testing

- [x] Add internal testers (up to 100)
  - App Store Connect → TestFlight → Internal Testing
  - Add email addresses of testers

- [ ] Add external testers (up to 10,000)
  - App Store Connect → TestFlight → External Testing
  - Create a group and add testers
  - Note: First external build requires App Review (usually 24-48 hours)

- [x] Submit build for TestFlight review (external testing only)
  - Fill out required information
  - Answer export compliance questions

### 6. App Store Submission

- [ ] Complete App Store Review Information
  - [ ] Contact information
  - [ ] Demo account credentials (if app requires login)
  - [ ] Notes for reviewer

- [ ] Set pricing and availability
  - [ ] Price tier (Free or paid)
  - [ ] Countries/regions availability

- [ ] Submit for review
  - Build must be uploaded and processed
  - All required information must be complete
  - Review typically takes 24-48 hours

---

## 🤖 Android (Google Play Store) Setup

### 1. Google Play Console Configuration

- [ ] Create app in Google Play Console
  - Go to: https://play.google.com/console/
  - Click "Create app"
  - App name: "Horcrux"
  - Default language: English (or your preference)
  - App or game: App
  - Free or paid: Select appropriate option
  - Privacy Policy: Required (must be URL)

- [ ] Complete Store Listing
  - [ ] App name (50 characters max)
  - [ ] Short description (80 characters max)
  - [ ] Full description (4000 characters max)
  - [ ] App icon (512 x 512 pixels, PNG, no transparency)
  - [ ] Feature graphic (1024 x 500 pixels)
  - [ ] Screenshots (required):
    - [ ] Phone: At least 2 screenshots
    - [ ] Tablet: At least 2 screenshots (if supporting tablets)
  - [ ] Promotional video (optional, YouTube URL)

### 2. Android App Signing

- [x] Generate upload keystore

  ```bash
  keytool -genkey -v -keystore ~/horcrux-upload-key.jks -keyalg RSA -keysize 2048 -validity 10000 -alias horcrux
  ```

  - Store password: Choose a strong password
  - Key password: Choose a strong password
  - Key alias: `horcrux` (or your preference)
  - **IMPORTANT**: Save passwords securely! You'll need them for every release.

- [x] Configure signing in project
  - [ ] Copy `android/key.properties.example` to `android/key.properties`
  - [ ] Fill in your keystore details:
    ```
    storePassword=your_keystore_password
    keyPassword=your_key_password
    keyAlias=horcrux
    storeFile=/path/to/horcrux-upload-key.jks
    ```
  - [ ] Add `android/key.properties` to `.gitignore` (if not already)
  - ✅ Signing configuration already added to `build.gradle`

- [x] Upload keystore to Google Play App Signing (Recommended)
  - Google Play Console → Setup → App signing
  - Upload your keystore for Google to manage
  - Google will provide an upload certificate for future uploads

### 3. Android Build Configuration

- [ ] Verify application ID: `com.singleoriginsoftware.horcrux` ✅ (Just updated)
- [ ] Verify app label: "Horcrux" (in AndroidManifest.xml)
- [ ] Verify version code and version name in `pubspec.yaml`: `1.0.0+1`
- [ ] Ensure app icons are configured (multiple sizes)
- [ ] Verify minSdkVersion is appropriate (check `flutter.minSdkVersion`)

### 4. Android Build & Upload

- [ ] Build Android App Bundle (AAB) - Required for Play Store

  ```bash
  flutter build appbundle --release
  ```

  Output: `build/app/outputs/bundle/release/app-release.aab`

- [ ] Upload to Google Play Console
  - Google Play Console → Production (or Internal Testing) → Create new release
  - Upload the `.aab` file
  - Add release notes
  - Save (don't publish yet for testing)

### 5. Google Play Internal Testing

- [ ] Create internal testing track
  - Google Play Console → Testing → Internal testing
  - Create release and upload AAB
  - Add testers:
    - [ ] Create tester list with email addresses
    - [ ] Or use Google Groups
    - [ ] Share opt-in URL with testers

- [ ] Publish internal testing release
  - Review and publish
  - Testers can opt-in via the provided URL

### 6. Google Play Store Submission

- [ ] Complete Content Rating
  - [ ] Complete questionnaire
  - [ ] Get rating certificate (usually instant)

- [ ] Complete Data Safety section
  - [ ] Declare data collection practices
  - [ ] Privacy policy URL (required)

- [ ] Set up pricing and distribution
  - [ ] Price (Free or set price)
  - [ ] Countries/regions
  - [ ] Device compatibility

- [ ] Submit for review
  - All required sections must be complete
  - Review typically takes 1-3 days for new apps

---

## 🔄 Version Management Strategy

### Version Format

- Format: `MAJOR.MINOR.PATCH+BUILD_NUMBER`
- Example: `1.0.0+1`
- Defined in: `pubspec.yaml`

### Version Guidelines

- **MAJOR**: Breaking changes
- **MINOR**: New features, backward compatible
- **PATCH**: Bug fixes
- **BUILD_NUMBER**: Increment for each build (required for both stores)

### Incrementing Versions

- iOS: Both version name and build number must increment
- Android: versionCode (build number) must always increase
- Update in `pubspec.yaml` before each release

---

## 📱 App Assets Checklist

### iOS Assets

- [ ] App Icon: 1024 x 1024 pixels (PNG, no transparency)
- [ ] Launch Screen: Already configured ✅
- [ ] Screenshots for App Store:
  - [ ] iPhone 6.7" (1290 x 2796)
  - [ ] iPhone 6.5" (1284 x 2778)
  - [ ] iPad Pro 12.9" (2048 x 2732) - if supporting iPad

### Android Assets

- [ ] App Icon: 512 x 512 pixels (PNG, no transparency)
- [ ] Feature Graphic: 1024 x 500 pixels
- [ ] Screenshots:
  - [ ] Phone: At least 2 (recommended: 4-8)
  - [ ] Tablet: At least 2 (if supporting tablets)

---

## 🔐 Security & Best Practices

### Android Keystore Security

- [ ] Store keystore file securely (not in repository)
- [ ] Backup keystore file to secure location
- [ ] Document keystore passwords securely
- [ ] Consider using Google Play App Signing (recommended)

### iOS Certificate Security

- [ ] Use Xcode's automatic signing (recommended)
- [ ] Or securely store certificates and provisioning profiles
- [ ] Keep Apple Developer account credentials secure

### Environment Variables

- [ ] Never commit `android/key.properties` to git
- [ ] Use CI/CD secrets for automated builds
- [ ] Document required environment variables

---

## 🚀 CI/CD Setup (Optional but Recommended)

### GitHub Actions for Automated Builds

- [ ] Create workflow for iOS builds
  - Archive and upload to TestFlight
  - Requires Apple API key or App Store Connect API

- [ ] Create workflow for Android builds
  - Build AAB and upload to Play Console
  - Requires Google Play service account

- [ ] Set up secrets in GitHub:
  - [ ] `APPLE_API_KEY_ID`
  - [ ] `APPLE_API_ISSUER_ID`
  - [ ] `APPLE_API_KEY` (base64 encoded .p8 file)
  - [ ] `GOOGLE_PLAY_SERVICE_ACCOUNT_JSON`
  - [ ] `KEYSTORE_PASSWORD`
  - [ ] `KEY_PASSWORD`
  - [ ] `KEYSTORE_BASE64` (base64 encoded keystore)

---

## 📝 Pre-Launch Checklist

### Before First Beta Release

- [ ] Test app thoroughly on physical devices
- [ ] Test on both iOS and Android
- [ ] Verify all features work correctly
- [ ] Check app performance and memory usage
- [ ] Test app with different network conditions
- [ ] Verify privacy policy is accessible
- [ ] Test deep links (if applicable)
- [ ] Verify app icons display correctly

### Before Production Release

- [ ] All beta feedback addressed
- [ ] App Store listing complete
- [ ] Play Store listing complete
- [ ] Screenshots and descriptions finalized
- [ ] Privacy policy finalized
- [ ] Support contact information verified
- [ ] Pricing set correctly
- [ ] App tested on multiple devices
- [ ] Crash reporting set up (if using)
- [ ] Analytics set up (if using)

---

## 🐛 Troubleshooting

### iOS Common Issues

- **"No signing certificate found"**: Generate certificate in Xcode or Apple Developer Portal
- **"Provisioning profile doesn't match"**: Update provisioning profile or use automatic signing
- **"Invalid bundle identifier"**: Ensure bundle ID matches App Store Connect exactly

### Android Common Issues

- **"Keystore file not found"**: Check path in `key.properties`
- **"Keystore password incorrect"**: Verify passwords in `key.properties`
- **"Version code already used"**: Increment version code in `pubspec.yaml`

---

## 📚 Useful Resources

- [Flutter iOS Deployment](https://docs.flutter.dev/deployment/ios)
- [Flutter Android Deployment](https://docs.flutter.dev/deployment/android)
- [Apple App Store Connect](https://appstoreconnect.apple.com/)
- [Google Play Console](https://play.google.com/console/)
- [TestFlight Documentation](https://developer.apple.com/testflight/)
- [Google Play Internal Testing](https://support.google.com/googleplay/android-developer/answer/9845334)

---

## ✅ Quick Start Commands

### iOS

```bash
# Build for release
flutter build ipa --release

# Or build and open in Xcode for manual upload
flutter build ios --release
open ios/Runner.xcworkspace
```

### Android

```bash
# Build App Bundle for Play Store
flutter build appbundle --release

# Or build APK for testing (not for Play Store)
flutter build apk --release
```

---

**Last Updated**: 2024
**App Bundle ID**: `com.singleoriginsoftware.horcrux`
**Current Version**: `1.0.0+1`
