# BJBank - Deployment Guide

**Date**: 18/04/2026
**Version**: 1.0
**Document Type**: Deployment & Release Management

---

## Table of Contents

1. [Pre-Deployment Checklist](#1-pre-deployment-checklist)
2. [Environment Setup](#2-environment-setup)
3. [Android Deployment](#3-android-deployment)
4. [iOS Deployment](#4-ios-deployment)
5. [Firebase Setup](#5-firebase-setup)
6. [Testing Before Release](#6-testing-before-release)
7. [App Store Release](#7-app-store-release)
8. [Post-Deployment](#8-post-deployment)
9. [Rollback Procedures](#9-rollback-procedures)
10. [Troubleshooting](#10-troubleshooting)

---

## 1. Pre-Deployment Checklist

### 1.1 Code Quality

- [ ] All unit tests pass: `flutter test`
- [ ] No analysis warnings: `flutter analyze`
- [ ] Code coverage > 80%
- [ ] No TODO or FIXME comments in production code
- [ ] All strings localized (Portuguese)
- [ ] Null safety enabled
- [ ] No hardcoded secrets or API keys

### 1.2 Security

- [ ] PQC cryptography tested
- [ ] Firebase Security Rules reviewed
- [ ] No sensitive data logged
- [ ] SSL/TLS certificates valid
- [ ] Secure storage configured
- [ ] API authentication tested
- [ ] Data encryption enabled

### 1.3 Performance

- [ ] App startup time < 3 seconds
- [ ] List scrolling 60 FPS
- [ ] Firestore queries < 1 second
- [ ] PQC operations < 100ms
- [ ] Memory usage < 200MB
- [ ] Network requests optimized
- [ ] Images cached properly

### 1.4 Features

- [ ] All RF01-RF13 features tested
- [ ] Real-time updates working
- [ ] Offline mode functional
- [ ] Notifications working
- [ ] QR code scanning works
- [ ] File uploads working
- [ ] Push notifications configured

### 1.5 Documentation

- [ ] README updated
- [ ] ADRs completed
- [ ] API documentation done
- [ ] User guide prepared
- [ ] Release notes written
- [ ] CHANGELOG updated
- [ ] API keys documented

---

## 2. Environment Setup

### 2.1 Development Machine Setup

```bash
# Install Flutter (latest stable)
git clone https://github.com/flutter/flutter.git -b stable
export PATH="$PATH:`pwd`/flutter/bin"

# Verify installation
flutter doctor

# Install dependencies
cd bjbank/
flutter pub get

# Analyze code
flutter analyze

# Run tests
flutter test
```

### 2.2 Firebase Project Setup

**Create Firebase Project**:
1. Go to [Firebase Console](https://console.firebase.google.com)
2. Create new project: "BJBank Production"
3. Enable services:
   - Authentication (Email/Password)
   - Cloud Firestore (Production mode)
   - Cloud Storage
   - Cloud Messaging (FCM)
   - Cloud Functions
   - Crashlytics

**Configure Firebase for Flutter**:
```bash
# Install Firebase CLI
npm install -g firebase-tools

# Login to Firebase
firebase login

# Initialize Firebase
firebase init

# Configure for Flutter
flutterfire configure --platforms=android,ios
```

### 2.3 Version Management

```bash
# Update version in pubspec.yaml
# Format: major.minor.patch+build_number
version: 1.0.0+1

# Update build name and number
flutter build apk --release --build-name=1.0.0 --build-number=1
```

### 2.4 Environment Variables

```bash
# Create .env.production file
cat > .env.production << EOF
FIREBASE_PROJECT_ID=bjbank-production
FIREBASE_STORAGE_BUCKET=bjbank-prod.appspot.com
PRODUCTION=true
LOG_LEVEL=warning
EOF

# Use in build
flutter run -d <device> --dart-define-from-file=.env.production
```

---

## 3. Android Deployment

### 3.1 Generate Signing Key

**Create Keystore** (one-time):
```bash
keytool -genkey -v -keystore ~/bjbank-release.jks \
  -keyalg RSA -keysize 2048 -validity 10000 \
  -alias bjbank-key \
  -storepass <password> \
  -keypass <keypass>
```

**Store credentials securely**:
```bash
# Create key.properties (add to .gitignore)
cat > android/key.properties << EOF
storeFile=bjbank-release.jks
storePassword=<password>
keyPassword=<keypass>
keyAlias=bjbank-key
EOF

# Don't commit to git
echo "android/key.properties" >> .gitignore
```

### 3.2 Configure Gradle

**android/app/build.gradle**:
```gradle
android {
    signingConfigs {
        release {
            keyAlias keystoreProperties['keyAlias']
            keyPassword keystoreProperties['keyPassword']
            storeFile file(keystoreProperties['storeFile'])
            storePassword keystoreProperties['storePassword']
        }
    }

    buildTypes {
        release {
            signingConfig signingConfigs.release
            minifyEnabled true
            shrinkResources true
            proguardFiles getDefaultProguardFile(
                'proguard-android-optimize.txt'), 'proguard-rules.pro'
        }
    }
}
```

### 3.3 Build Release APK

```bash
# Clean build
flutter clean

# Build APK
flutter build apk --release

# Build App Bundle (recommended for Play Store)
flutter build appbundle --release

# Output locations
# APK: build/app/outputs/flutter-apk/app-release.apk
# AAB: build/app/outputs/bundle/release/app-release.aab

# Verify signature
jarsigner -verify -verbose -certs build/app/outputs/flutter-apk/app-release.apk
```

### 3.4 AndroidManifest.xml Configuration

**android/app/src/main/AndroidManifest.xml**:
```xml
<manifest xmlns:android="http://schemas.android.com/apk/res/android"
    package="com.bjbank.app">

    <!-- Required permissions -->
    <uses-permission android:name="android.permission.INTERNET" />
    <uses-permission android:name="android.permission.ACCESS_NETWORK_STATE" />
    <uses-permission android:name="android.permission.CAMERA" />
    <uses-permission android:name="android.permission.READ_EXTERNAL_STORAGE" />

    <!-- FCM permissions (Firebase handles most automatically) -->
    <uses-permission android:name="android.permission.RECEIVE_BOOT_COMPLETED" />

    <application
        android:label="BJBank"
        android:icon="@mipmap/ic_launcher"
        android:usesCleartextTraffic="false">

        <!-- Enable network security config -->
        <activity
            android:name=".MainActivity"
            android:theme="@style/LaunchTheme"
            android:configChanges="orientation|keyboardHidden|keyboard|screenSize|smallestScreenSize|locale|layoutDirection|fontScale|screenLayout|density|uiMode"
            android:hardwareAccelerated="true"
            android:windowSoftInputMode="adjustResize">
            <meta-data
                android:name="io.flutter.embedding.android.NormalTheme"
                android:resource="@style/NormalTheme" />
            <intent-filter>
                <action android:name="android.intent.action.MAIN" />
                <category android:name="android.intent.category.LAUNCHER" />
            </intent-filter>
        </activity>
    </application>
</manifest>
```

### 3.5 Network Security Configuration

**android/app/src/main/res/xml/network_security_config.xml**:
```xml
<?xml version="1.0" encoding="utf-8"?>
<network-security-config>
    <!-- Require HTTPS for all domains -->
    <domain-config cleartextTrafficPermitted="false">
        <domain includeSubdomains="true">*.firebase.com</domain>
        <domain includeSubdomains="true">*.firebaseio.com</domain>
        <!-- Certificate pinning (optional) -->
        <pin-set expiration="2027-04-18">
            <pin digest="SHA-256">base64-encoded-certificate-hash</pin>
        </pin-set>
    </domain-config>
</network-security-config>
```

---

## 4. iOS Deployment

### 4.1 Certificate Setup

**Create Production Certificate**:
1. Go to [Apple Developer](https://developer.apple.com/account)
2. Certificates, Identifiers & Profiles
3. Create App ID: `com.bjbank.app`
4. Create Production Certificate (for App Store distribution)
5. Create Provisioning Profile (Production)
6. Download and install (.p12 files)

**Update Xcode Settings**:
```bash
# Open Xcode
open ios/Runner.xcworkspace

# Configure in Xcode:
# - General tab: Bundle Identifier = com.bjbank.app
# - Signing & Capabilities: Select team and provisioning profile
# - Build Settings: Code Signing Identity = "Apple Distribution"
```

### 4.2 Build Release IPA

```bash
# Clean build
flutter clean

# Build iOS release
flutter build ios --release

# Build and archive
flutter build ios --release --no-codesign

# Open in Xcode for archiving
open ios/Runner.xcworkspace

# Or use command line
cd ios
xcodebuild -workspace Runner.xcworkspace \
  -scheme Runner \
  -configuration Release \
  -derivedDataPath build \
  -archivePath build/Runner.xcarchive \
  archive

# Export IPA
xcodebuild -exportArchive \
  -archivePath build/Runner.xcarchive \
  -exportOptionsPlist ExportOptions.plist \
  -exportPath build/ipa
```

### 4.3 ExportOptions.plist

**ios/ExportOptions.plist**:
```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>method</key>
    <string>app-store</string>
    <key>signingStyle</key>
    <string>automatic</string>
    <key>stripSwiftSymbols</key>
    <true/>
    <key>teamID</key>
    <string>YOUR_TEAM_ID</string>
    <key>uploadBitcode</key>
    <false/>
</dict>
</plist>
```

### 4.4 Info.plist Configuration

**ios/Runner/Info.plist**:
```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleName</key>
    <string>BJBank</string>
    <key>CFBundleVersion</key>
    <string>1.0.0</string>
    <key>CFBundleShortVersionString</key>
    <string>1.0</string>
    <key>NSCameraUsageDescription</key>
    <string>Para escanear códigos QR</string>
    <key>NSPhotoLibraryUsageDescription</key>
    <string>Para selecionar fotos</string>
    <!-- ATS: Force HTTPS -->
    <key>NSAppTransportSecurity</key>
    <dict>
        <key>NSAllowsArbitraryLoadsForMedia</key>
        <false/>
        <key>NSAllowsArbitraryLoadsInWebContent</key>
        <false/>
    </dict>
</dict>
</plist>
```

---

## 5. Firebase Setup

### 5.1 Firestore Configuration

**Create Collections** (via Firebase Console):
```
users/ (top-level)
├── {userId}
│   ├── accounts/ (subcollection)
│   ├── cards/ (subcollection)
│   ├── transactions/ (subcollection)
│   ├── transfers/ (subcollection)
│   ├── bills/ (subcollection)
│   ├── loans/ (subcollection)
│   ├── investments/ (subcollection)
│   ├── settings/ (subcollection)
│   └── notifications/ (subcollection)
```

### 5.2 Security Rules

**Production Firestore Rules**:
```
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    match /{document=**} {
      allow read, write: if false;
    }

    // User data
    match /users/{userId} {
      allow read, write: if request.auth.uid == userId;

      match /accounts/{accountId} {
        allow read, write: if request.auth.uid == userId;
      }

      match /transactions/{transactionId} {
        allow read: if request.auth.uid == userId;
        allow create: if request.auth.uid == userId &&
                         request.resource.data.accountId in get(/databases/$(database)/documents/users/$(userId)/accounts).data.keys();
      }

      // ... more subcollections
    }
  }
}
```

### 5.3 FCM Configuration

**Enable FCM**:
1. Firebase Console → Cloud Messaging
2. Generate Server Key (automatic)
3. Configure in app: `google-services.json` and `GoogleService-Info.plist`

**Test Sending Notification**:
```bash
# Get FCM token from app
# Send test message via Firebase Console or:
curl -X POST \
  https://fcm.googleapis.com/fcm/send \
  -H "Authorization: key=<FCM_SERVER_KEY>" \
  -H "Content-Type: application/json" \
  -d '{
    "to": "<FCM_TOKEN>",
    "notification": {
      "title": "Test",
      "body": "Test notification"
    }
  }'
```

### 5.4 Cloud Storage Setup

**Enable Cloud Storage**:
1. Firebase Console → Storage
2. Create bucket: `bjbank-prod.appspot.com`
3. Set security rules

**Storage Rules**:
```
rules_version = '2';
service firebase.storage {
  match /b/{bucket}/o {
    match /{allPaths=**} {
      allow read, write: if false;
    }

    // User profile pictures
    match /users/{userId}/profile.jpg {
      allow read, write: if request.auth.uid == userId;
    }

    // Document uploads
    match /users/{userId}/documents/{documentId} {
      allow read, write: if request.auth.uid == userId;
    }
  }
}
```

---

## 6. Testing Before Release

### 6.1 Automated Testing

```bash
# Run all tests
flutter test --coverage

# Generate coverage report
genhtml coverage/lcov.info -o coverage/html
open coverage/html/index.html
```

### 6.2 Manual Testing Checklist

**Authentication**:
- [ ] Sign up with new account
- [ ] Login with email/password
- [ ] PIN creation and validation
- [ ] Biometric authentication (if enabled)
- [ ] Logout functionality
- [ ] Session timeout
- [ ] Password reset

**Core Features**:
- [ ] View account balance (real-time)
- [ ] View transaction history
- [ ] Create transfer (validate IBAN)
- [ ] View cards (all types)
- [ ] View bills
- [ ] View loans
- [ ] View investments

**Advanced Features**:
- [ ] QR code generation
- [ ] QR code scanning
- [ ] MB WAY payment
- [ ] Push notifications
- [ ] Offline mode
- [ ] Dark theme
- [ ] Portuguese localization

**Security**:
- [ ] PQC key exchange works
- [ ] Data encrypted in transit
- [ ] Sensitive data not logged
- [ ] HMAC verification works
- [ ] No hardcoded secrets visible

**Performance**:
- [ ] App starts in < 3 seconds
- [ ] Scrolling is smooth (60 FPS)
- [ ] Firestore queries < 1 second
- [ ] Memory usage < 200MB
- [ ] No memory leaks (verify with DevTools)

### 6.3 Device Testing

```bash
# Test on multiple devices
flutter devices

# Test on physical device
flutter run -d <device_id>

# Test with performance overlay
flutter run --profile --show-performance-overlay
```

---

## 7. App Store Release

### 7.1 Google Play Store

**Prepare for Release**:
1. Update version in `pubspec.yaml`
2. Update `CHANGELOG.md` with version notes
3. Create release APK/AAB
4. Generate screenshots (1080×1920 for phones, 2560×1600 for tablets)
5. Prepare store listing (title, description, keywords)

**Create App on Play Console**:
1. Go to [Google Play Console](https://play.google.com/console)
2. Create Application: "BJBank"
3. Fill Store Listing
4. Add Screenshots
5. Add Pricing & Distribution
6. Accept Google Play Policies

**Upload Release**:
1. App bundles → Create new release
2. Upload `app-release.aab`
3. Set version number
4. Add release notes
5. Set rollout: 100%
6. Review and publish

**Play Store Review Checklist**:
- [ ] App description accurate
- [ ] Screenshots show features
- [ ] Privacy policy included
- [ ] Terms of service included
- [ ] Appropriate content rating
- [ ] Correct target audience
- [ ] Permissions justified

### 7.2 Apple App Store

**Prepare for Release**:
1. Update version in Xcode
2. Update app description
3. Generate screenshots (1024×1024 minimum)
4. Prepare app preview (30 seconds, optional)

**Create App on App Store Connect**:
1. Go to [App Store Connect](https://appstoreconnect.apple.com)
2. Create App: "BJBank"
3. Fill App Information
4. Add Screenshots
5. Add Promotional Image (optional)
6. Set Pricing & Distribution

**Build and Upload**:
```bash
# Build archive
flutter build ios --release

# In Xcode: Product → Archive

# In App Store Connect:
# 1. Manage Builds
# 2. Select your build
# 3. Submit for Review
```

**App Store Review Checklist**:
- [ ] App functionality clear
- [ ] Screenshots accurate
- [ ] Privacy policy detailed
- [ ] Contact information provided
- [ ] Version history accurate
- [ ] Category appropriate
- [ ] Age rating correct

### 7.3 Monitoring Release

**Monitor Metrics**:
- Downloads per day
- Crash rate
- Rating and reviews
- Retention (7-day, 30-day)
- Session length
- User demographics

**Tools**:
- Google Play Console Analytics
- App Store Connect Analytics
- Firebase Crashlytics
- Firebase Analytics

---

## 8. Post-Deployment

### 8.1 Monitoring

**Set up Alerts**:
```bash
# Firebase Crashlytics alerts
firebase functions:log

# Custom alerts
firebase functions:deploy monitorCrashes
```

**Check Metrics**:
- Crash-free users: > 99%
- Average session length: > 5 minutes
- Daily active users: monitor growth
- Retention rates: track trends

### 8.2 User Feedback

- Monitor App Store/Play Store reviews
- Respond to user feedback
- Track feature requests
- Monitor support tickets
- Collect bug reports

### 8.3 Release Notes

**Publish Release Notes**:
1. Update `CHANGELOG.md`
2. Create GitHub release
3. Post on social media
4. Notify users via email
5. Update website

**Template**:
```markdown
# BJBank v1.0.0 (Released: 18/04/2026)

## New Features
- Feature 1
- Feature 2

## Bug Fixes
- Fixed issue 1
- Fixed issue 2

## Improvements
- Performance improvement 1
- Security enhancement 1

## Breaking Changes
- None

## Known Issues
- None

## Download
- [Google Play](link)
- [App Store](link)
```

---

## 9. Rollback Procedures

### 9.1 When to Rollback

- Critical crashes (> 5% of users)
- Data loss or corruption
- Security vulnerability
- Major feature broken
- Performance degradation

### 9.2 Rollback Process

**Google Play Store**:
```
Google Play Console
  → App releases
  → Manage production release
  → Halt rollout
  → Create new version
  → Upload previous APK
  → Submit new release
```

**Apple App Store**:
```
App Store Connect
  → Version Release Information
  → Remove Current Version
  → Upload New Build with Previous Version
```

### 9.3 Post-Rollback

1. Investigate root cause
2. Fix in development
3. Extensive testing
4. Staged rollout (10% → 25% → 50% → 100%)
5. Monitor metrics
6. Communicate with users

---

## 10. Troubleshooting

### 10.1 Build Errors

**Gradle Build Fails**:
```bash
# Clean and rebuild
./gradlew clean
flutter clean
flutter pub get
flutter build apk --release
```

**iOS Build Fails**:
```bash
# Clean and rebuild
cd ios
rm -rf Pods Podfile.lock
cd ..
flutter clean
flutter pub get
flutter build ios --release
```

### 10.2 Signing Issues

**Android Signing Error**:
```bash
# Verify keystore
keytool -list -v -keystore ~/bjbank-release.jks -storepass <password>

# Re-sign APK
jarsigner -verbose -sigalg SHA1withRSA -digestalg SHA1 \
  -keystore ~/bjbank-release.jks app.apk bjbank-key
```

**iOS Signing Error**:
1. Verify certificate in Keychain Access
2. Verify provisioning profile in Xcode
3. Regenerate certificate/profile if needed
4. Update Xcode project settings

### 10.3 Firebase Connection Issues

**Test Firebase Connection**:
```dart
// In app
try {
  await FirebaseFirestore.instance.collection('test').doc('test').set({'test': true});
  print('Firebase connection successful');
} catch (e) {
  print('Firebase connection failed: $e');
}
```

**Check Firebase Security Rules**:
```bash
firebase deploy --only firestore:rules --project=bjbank-production
```

---

## References

- [Flutter Documentation](https://docs.flutter.dev/)
- [Flutter Build Documentation](https://docs.flutter.dev/deployment)
- [Google Play Console Help](https://support.google.com/googleplay/android-developer)
- [App Store Connect Help](https://help.apple.com/app-store-connect)
- [Firebase Documentation](https://firebase.google.com/docs)
- [Firebase Deployment Guide](https://firebase.google.com/docs/apps/manage-apps)

---

**Version**: 1.0
**Last Updated**: 18/04/2026
**Status**: Complete
**Maintained By**: DevOps Team
