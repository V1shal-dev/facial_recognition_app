# Face Verification App

✨ What is Face Verify?
Face Verify is a Flutter app that proves your identity using just your phone's camera — no internet, no server, no data leaving your device. Register once with a selfie, then verify yourself anytime by taking a new photo. The app computes a match score using Google ML Kit and tells you if it's really you.
Perfect for: mobile security demos, learning Flutter + ML Kit, or lightweight "prove it's me" flows in real apps.

🎯 Key Highlights
🔐Privacy FirstAll processing on-device. Photos never leave your phone.🤖Smart MatchingMulti-signal algorithm: landmarks + appearance + geometry + pose📊Match ScoreClear percentage result — know exactly how confident the match is📜History TrackingEvery verification attempt is saved locally with date, time, and score⚡No SetupNo backend, no API keys, no accounts — clone and run

🧠 How the Matching Works
The app combines 4 signals for accurate verification:
┌─────────────────────────────────────────────────────────┐
│                   MATCH SCORE ENGINE                    │
├──────────────────┬──────────────────────────────────────┤
│ 🎯 Landmarks     │ Eye/nose/mouth positions (main signal)│
│ 🎨 Appearance    │ Pixel-level face region similarity    │
│ 📐 Geometry      │ Face size & proportion check          │
│ 📷 Head Pose     │ Light angle weight for fairness       │
└──────────────────┴──────────────────────────────────────┘

✅ Same person → typically 65–95% match
❌ Different person → score capped (e.g. ≤42–55%) — appearance alone can't fake a pass

📱 App Screens
Splash ──► Registration ──► Capture Profile Photo
                                      │
                              Home Dashboard
                                      │
              ┌───────────────────────┼───────────────┐
           Verify Now             History           Profile
              │
         Camera Capture
              │
         Result Screen (Match % + Status)

ScreenDescriptionSplashIntro → routes to Registration or HomeRegistrationName, email, mobile, gender → capture profile selfieHomeHow it works, Verify Now CTA, verification statsCaptureLive camera with face guide, review before savingResultMatch %, verified/try again, retry or go homeHistoryAll past attempts with timestamp and scoreProfileView info, logout (clears local data)

🛠️ Tech Stack
dartdependencies:
  flutter                       // UI framework
  google_mlkit_face_detection   // On-device face detection & landmarks
  camera                        // Profile & verification photo capture
  provider                      // State management
  shared_preferences            // Persist user data & settings
  path_provider                 // Store images on disk
  flutter_animate               // UI animations
  image                         // Face region crop & resize
  intl                          // Date/time formatting in history

🚀 Getting Started
Prerequisites

Flutter SDK 3.x
Dart 3.x
Android or iOS device/emulator with camera

Run the app
bash# 1. Clone the repo
git clone https://github.com/YOUR_USERNAME/facial_recognition_app.git
cd facial_recognition_app

# 2. Install dependencies
flutter pub get

# 3. Run
flutter run
Build Release APK
bashflutter build apk --release
Output: build/app/outputs/flutter-apk/app-release.apk

📦 Download the latest APK from Releases →


📁 Project Structure
lib/
├── main.dart                          # Entry point, theme, routing
├── models/
│   ├── user_model.dart                # User data shape
│   └── verification_history.dart     # History entry model
├── providers/
│   └── user_provider.dart            # Global state (user, images, match %)
├── services/
│   ├── storage_service.dart          # Local persistence
│   └── face_matching_service.dart    # Core matching algorithm
├── screens/
│   ├── splash_screen.dart
│   ├── registration_screen.dart
│   ├── home_screen.dart
│   ├── capture_screen.dart
│   ├── result_screen.dart
│   ├── history_screen.dart
│   ├── profile_screen.dart
│   └── main_navigation.dart
└── widgets/                          # Reusable UI components

🔒 Privacy & Security

✅ Zero network calls — no analytics, no telemetry, no uploads
✅ Local storage only — profile photo and history on your device
✅ No API keys — ML Kit face detection runs fully on-device
✅ Logout = full wipe — clears all local data

Built with ❤️ using Flutter & Google ML Kit
⭐ Star this repo if you found it useful!
