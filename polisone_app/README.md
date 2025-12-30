# 🛡️ PolisOne - Integrated Smart Policing Ecosystem

PolisOne is a next-generation policing platform designed to modernize law enforcement operations through real-time data, smart analytics, and seamless communication.

## 🚀 Key Features

### 🏢 Admin Command Center
- **Real-Time Operations Map:** Live GPS tracking of all patrol units and incident locations.
- **Incident Reports Dashboard:** View and manage field reports (Suspicious Activity, Traffic Violations, etc.).
- **Smart Roster System:** Automated shift scheduling and management.
- **Communication Hub:** Broadcast messages to officers and manage department channels.
- **Digital FIR:** Manage First Information Reports digitally.
- **Crime Analytics:** Visual insights into crime trends and hotspots.
- **Emergency Response Center:** Monitor SOS alerts from officers in the field.

### 👮 Officer Field App
- **Smart Beat Patrol:** GPS-tracked patrols with checkpoint check-ins.
- **Emergency SOS:** One-tap emergency alerts (Officer Down, Backup Needed).
- **Digital Malkhana:** QR-code based evidence management and chain of custody.
- **Secure Communication:** Encrypted voice and text messaging with HQ.
- **Incident Reporting:** Quick field reporting with location tagging.

---

## 🛠️ Technology Stack
- **Framework:** [Flutter](https://flutter.dev/) (Cross-platform: Android, iOS, Web)
- **Backend:** [Firebase](https://firebase.google.com/)
  - **Authentication:** User management
  - **Firestore:** Real-time NoSQL database
  - **Storage:** Evidence and voice message storage
  - **Hosting:** Web dashboard deployment
- **Maps:** Google Maps Flutter

---

## ⚙️ Setup Instructions

### Prerequisites
1.  **Flutter SDK** (3.x or later)
2.  **Firebase CLI** (`npm install -g firebase-tools`)
3.  **Google Maps API Key** (configured in `android/app/src/main/AndroidManifest.xml` and `web/index.html`)

### Installation
1.  **Clone the repository:**
    ```bash
    git clone https://github.com/your-org/polisone_app.git
    cd polisone_app
    ```

2.  **Install Dependencies:**
    ```bash
    flutter pub get
    ```

3.  **Configure Firebase:**
    Ensure you have the `firebase_options.dart` file in `lib/`. If not, run:
    ```bash
    flutterfire configure
    ```

### Running the App

#### 🌍 Web (Admin Dashboard)
```bash
flutter run -d chrome
```

#### 📱 Android (Officer App)
```bash
flutter run -d android
```

---

## 💾 Scripts & Utilities
Located in `scripts/`:
- **`populate_firebase.js` / `.ps1`**: Utility scripts to seed the Firestore database with initial dummy data (officers, shifts, etc.) for testing.

---

## 🚢 Deployment

### Web Deployment (Firebase Hosting)
1.  **Build the Release Version:**
    ```bash
    flutter build web --release
    ```
2.  **Deploy to Firebase:**
    ```bash
    firebase deploy --only hosting
    ```

### Android Release
Refer to [deployment_guide.md](deployment_guide.md) for detailed steps on generating a signed APK/App Bundle.

---

## 📂 Project Structure
```
lib/
├── features/           # Feature-specific modules
│   ├── admin/          # Admin Dashboard screens
│   ├── communication/  # Chat & Voice features
│   ├── malkhana/       # Evidence management
│   ├── patrol/         # Smart Beat Patrol
│   └── ...
├── widgets/            # Reusable UI components
├── services/           # Backend services (Roster, etc.)
├── main.dart           # Application Entry Point
└── firebase_options.dart # Firebase Configuration
```
