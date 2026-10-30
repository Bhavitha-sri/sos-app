# SOS Guard App

A premium emergency SOS app built with Flutter and Firebase.

## Features
- Animated SOS emergency button
- Quick emergency call shortcuts
- Firebase Firestore SOS logging
- Live GPS location fetch
- Emergency contact messaging
- Premium dark UI design

## Tech Stack
- Flutter
- Firebase Authentication
- Cloud Firestore
- Geolocator
- URL launcher
- Permission Handler

## Setup
1. Install Flutter SDK
2. Open the project folder
3. Run:
   ```bash
   flutter pub get
   flutterfire configure
   flutter run
   ```
4. Firebase setup will generate `lib/firebase_options.dart` automatically.

## Firebase note
This repo includes placeholder Firebase options so the project can compile before you run `flutterfire configure`.

## Run locally
```bash
flutter pub get
flutter run
```

## Project structure
```text
lib/
  main.dart
  firebase_options.dart
  screens/
    sos_home_screen.dart
```

## Emergency actions included
- Police call: 112
- Hospital call: 108
- SOS message to emergency contacts
- Live location captured from device GPS

## Security note
Firestore rules should be restricted in production. Replace the sample rules with authenticated access rules before deployment.
