# Paper Trade App - Setup Guide

## 🔧 Initial Setup for Contributors

This guide will help you set up the development environment and configure necessary credentials.

## Prerequisites

- Flutter SDK (3.0.0 or higher)
- Android Studio / Xcode (for mobile development)
- Firebase account
- OpenRouter API key (optional, for AI features)

## Step 1: Clone the Repository

```bash
git clone <your-repo-url>
cd paper_trade_app
flutter pub get
```

## Step 2: Firebase Configuration

### 2.1 Create Firebase Project
1. Go to [Firebase Console](https://console.firebase.google.com/)
2. Create a new project or use existing one
3. Enable **Authentication** → **Google Sign-In**
4. Enable **Cloud Firestore**

### 2.2 Configure Firebase for Flutter

#### For Android:
1. In Firebase Console → Project Settings → Your apps
2. Add an Android app (if not already added)
3. Download `google-services.json`
4. Copy the template and fill your credentials:
   ```bash
   cp android/app/google-services.json.example android/app/google-services.json
   # Edit the file with your Firebase credentials
   ```

#### For Web/Linux:
1. Copy the Firebase options template:
   ```bash
   cp lib/config/firebase_options.dart.example lib/config/firebase_options.dart
   ```
2. Fill in your Firebase credentials from Firebase Console
3. Replace all `YOUR_XXX` placeholders with actual values

### 2.3 Add SHA-1 Fingerprint (Required for Google Sign-In)

```bash
# Get your debug SHA-1
cd android
./gradlew signingReport | grep "SHA1"

# Copy the SHA1 fingerprint
# Go to Firebase Console → Project Settings → Your Android app
# Add the SHA-1 fingerprint under "SHA certificate fingerprints"
```

### 2.4 Update Firestore Security Rules

Go to Firebase Console → Firestore Database → Rules and paste:

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    match /users/{userId}/{document=**} {
      allow read, write: if request.auth != null && request.auth.uid == userId;
    }
  }
}
```

## Step 3: OpenRouter API Key (Optional)

For AI features, you'll need an OpenRouter API key:

1. Get your key from [OpenRouter](https://openrouter.ai/keys)
2. Create a `.env` file:
   ```bash
   cp .env.example .env
   ```
3. Add your key:
   ```
   OPENROUTER_API_KEY=sk-or-v1-your-actual-key-here
   ```
4. Update `lib/main.dart` to use the key from environment variables

## Step 4: Build & Run

```bash
# For Android
flutter build apk
# or
flutter run

# For Linux
flutter run -d linux

# For Web
flutter run -d chrome
```

## Platform-Specific Features

- **Android/Web**: Full Firebase support (Google Sign-In, Cloud Firestore)
- **Linux/Windows**: Local storage only (SharedPreferences)

## Troubleshooting

### Google Sign-In fails
- Ensure SHA-1 is added to Firebase Console
- Check that `google-services.json` is present in `android/app/`
- Verify Firestore security rules allow authenticated users

### Build fails
- Run `flutter clean`
- Delete `build/` folder
- Run `flutter pub get`

## File Structure

```
lib/
├── config/
│   ├── firebase_options.dart          # Your Firebase config (gitignored)
│   └── firebase_options.dart.example  # Template for contributors
├── core/
│   └── services/
│       ├── auth_service.dart          # Google Sign-In logic
│       └── firestore_service.dart     # Cloud/local storage logic
├── logic/
│   └── providers/                     # State management
└── presentation/
    └── screens/                       # UI screens

android/app/
├── google-services.json               # Firebase Android config (gitignored)
└── google-services.json.example       # Template for contributors
```

## Contributing

1. Copy all `.example` files and remove `.example` extension
2. Fill in your own credentials (never commit these!)
3. Make your changes
4. Test thoroughly
5. Submit a pull request

## Need Help?

- Check existing issues
- Create a new issue with details
- Join our community discussions

---

**Note**: Never commit actual credentials! The `.gitignore` is configured to protect sensitive files.
