# Security Setup Guide

## ⚠️ IMPORTANT: Firebase Configuration Security

This project uses Firebase for backend services. **NEVER commit sensitive Firebase configuration files to Git.**

## Files That Must NEVER Be Committed

The following files contain sensitive API keys and credentials:

- ✋ `polisone_app/lib/firebase_options.dart`
- ✋ `polisone_app/android/app/google-services.json`
- ✋ `polisone_app/ios/Runner/GoogleService-Info.plist`
- ✋ `firebase.json`
- ✋ `.firebaserc`

These files are already listed in `.gitignore` to prevent accidental commits.

## Initial Setup for New Developers

### 1. Get Firebase Configuration Files

You need to download the Firebase configuration files from the Firebase Console:

1. Go to [Firebase Console](https://console.firebase.google.com/)
2. Select the project: `polisone-b1179`
3. Go to **Project Settings** → **General**
4. Scroll down to **Your apps**

### 2. Setup for Each Platform

#### Web & Desktop (Windows/macOS/Linux)

1. In Firebase Console, find your Web app
2. Copy the configuration
3. Use the template file as a guide:
   ```bash
   cp polisone_app/lib/firebase_options.template.dart polisone_app/lib/firebase_options.dart
   ```
4. Fill in the actual values from Firebase Console

#### Android

1. In Firebase Console, find your Android app
2. Click **Download google-services.json**
3. Place it at: `polisone_app/android/app/google-services.json`

#### iOS (if applicable)

1. In Firebase Console, find your iOS app
2. Click **Download GoogleService-Info.plist**
3. Place it at: `polisone_app/ios/Runner/GoogleService-Info.plist`

### 3. Verify Setup

After placing the configuration files:

```bash
# Check that sensitive files are NOT tracked by Git
git status

# The files should NOT appear as untracked or modified
# If they do, check your .gitignore file
```

## If You Accidentally Commit Sensitive Data

If you accidentally commit Firebase credentials:

1. **DO NOT** just delete the files and commit again - they remain in Git history
2. **Immediately rotate all API keys** in Firebase Console:
   - Go to Project Settings → General
   - Regenerate API keys for affected platforms
3. **Contact the project maintainer** for help cleaning Git history
4. **Follow the cleanup procedure** in the project documentation

## Security Best Practices

1. ✅ Always check `git status` before committing
2. ✅ Never share Firebase configuration files via email, chat, or public channels
3. ✅ Use environment variables for additional secrets
4. ✅ Regularly review Firebase Console for unauthorized access
5. ✅ Enable Firebase App Check for production apps
6. ✅ Set up proper Firestore security rules

## Getting Help

If you need access to Firebase configuration files:

1. Ask the project maintainer for Firebase Console access
2. Or request the configuration files through a secure channel (not email/chat)
3. Never commit these files to version control

## Firebase Console Access

Project: `polisone-b1179`
Console URL: https://console.firebase.google.com/project/polisone-b1179

Contact the project admin for access permissions.
