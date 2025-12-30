
# ⚡ PolisOne Setup Guide

This guide will help you get the PolisOne environment up and running quickly.

## 1. System Requirements
- **OS:** Windows / macOS / Linux
- **Flutter SDK:** Version 3.19.0 or higher
- **Node.js:** For Firebase CLI tools
- **Android Studio:** For Android emulation and build tools

## 2. Environment Setup

### Install Flutter
If you haven't installed Flutter yet:
1.  Download the SDK from [flutter.dev](https://flutter.dev/docs/get-started/install).
2.  Add `flutter/bin` to your PATH.
3.  Run `flutter doctor` to verify.

### Install Firebase Tools
Open your terminal and run:
```bash
npm install -g firebase-tools
firebase login
```

## 3. Project Configuration

### Google Maps API
You need a Google Cloud Project with **Maps SDK for Android** and **Maps JavaScript API** enabled.
1.  Get your API Key.
2.  **Android:** Open `android/app/src/main/AndroidManifest.xml` and replace `YOUR_API_KEY`.
3.  **Web:** Open `web/index.html` and replace `YOUR_API_KEY`.

### Firebase
The project relies on `lib/firebase_options.dart`. Do not delete this file. If you need to switch Firebase projects:
```bash
flutterfire configure
```

## 4. Running the Project

### VS Code (Recommended)
1.  Open the project folder.
2.  Go to **Run and Debug** tab.
3.  Select **"polisone_app"**.
4.  Choose your device (Chrome or Emulator) from the status bar.
5.  Press **F5**.

### Terminal
```bash
# Get packages
flutter pub get

# Run on Chrome
flutter run -d chrome

# Run on Android Emulator
flutter run -d emulator-5554
```

## 5. Troubleshooting Common Issues

### "Duplicate App" Error
If you see a red screen about "Duplicate App", simply **Hot Restart** (press `R` in terminal). This is a known development-only issue with Firebase on Web.

### "multidex" Errors (Android)
If the build fails with multidex errors, run:
```bash
flutter clean
flutter pub get
flutter run
```

### Map Not Loading
- Check if your API Key is valid and has billing enabled in Google Cloud Console.
- Ensure the relevant APIs (Android/JS) are enabled for the key.
