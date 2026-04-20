# Golden Hour

Golden Hour is a free major project idea for highway accident response. It helps alert nearby drivers and trained first-aiders, shares GPS context, and speeds up emergency response during the critical golden hour.

## Features

- Drivers within a 500 meter range can see nearby accident alerts
- The system can auto-assign the nearest trained first-aider
- Manual SOS support through a Big Red Button
- Accelerometer-based crash detection heuristic
- Optional TensorFlow Lite severity scoring
- Supabase authentication and realtime-friendly database schema
- OpenStreetMap-based maps, so paid Google Maps is not required
- Profile onboarding for driver, first-aider, and dispatcher roles

## Free Tech Stack

- Flutter
- Supabase Free Tier
- OpenStreetMap via `flutter_map`
- WebSocket support for future live dispatcher feeds
- Optional TensorFlow Lite support
- Supabase Realtime

## Folder Structure

```text
golden_hour/
├── lib/
│   ├── main.dart
│   ├── screens/
│   │   ├── home_screen.dart
│   │   ├── login_screen.dart
│   │   └── accident_alert_screen.dart
│   └── services/
│       ├── accident_detector.dart
│       └── alert_service.dart
├── assets/models/
├── pubspec.yaml
├── supabase_schema.sql
└── README.md
```

## Installation

### 1. Install Flutter

For a free Windows setup:

1. Download the Flutter SDK zip: https://docs.flutter.dev/get-started/install/windows
2. Extract it to `C:\src\flutter`
3. Add `C:\src\flutter\bin` to your system `Path`
4. Open a new terminal and run:

```powershell
flutter doctor
```

### 2. Install Android Studio or use VS Code

- Install Android Studio and complete the Android SDK and emulator setup
- Or use a real Android device with USB debugging enabled

### 3. Install project dependencies

In the project folder:

```powershell
cd d:\accident\golden_hour
flutter pub get
```

### 4. Create a free Supabase project

1. Create a free account at https://supabase.com
2. Create a new project
3. Open SQL Editor and run `supabase_schema.sql`
4. Copy the Project URL and anon key

Run the app with:

```powershell
flutter run --dart-define=SUPABASE_URL=https://YOUR-PROJECT.supabase.co --dart-define=SUPABASE_ANON_KEY=YOUR-ANON-KEY
```

### 5. Merge Android permissions

After `flutter create .`, check [AndroidManifest.xml](D:/accident/golden_hour/android/app/src/main/AndroidManifest.xml). If Flutter overwrites it, merge the required permissions back into the generated file.

## Demo Flow

1. Open the app and create an account
2. Complete profile setup and choose a role
3. View the home screen with map and current location
4. Turn on `Start Watch` for accelerometer-based crash monitoring
5. Press the `Big Red Button` to send a manual accident alert
6. The app stores the report in Supabase, assigns the nearest first-aider, and attempts the 108 call flow
7. Nearby alerts refresh in realtime

## TensorFlow Lite Note

- `assets/models/accident_severity.tflite` is optional
- If the file is missing, the app uses a heuristic severity score
- For a production version, you can add camera-based severity estimation plus sensor fusion

## Important Notes

- Direct automated 108 integration is not officially available, so the app launches `tel:108` and stores a GPS log
- Driver push notifications through FCM are a future enhancement
- Camera severity estimation requires a separately trained custom TFLite model
- Without `flutter create .`, Android and iOS runner files are not fully generated

## Next Steps

After installing Flutter, run:

```powershell
cd d:\accident\golden_hour
flutter create .
flutter pub get
flutter run
```

The purpose of `flutter create .` is only to generate Android, web, and native runner folders. If it asks to overwrite `lib/main.dart`, `pubspec.yaml`, or other existing project files, choose `n`. Then run `flutter pub get` and `flutter run`.

## Project Documents

- [PROJECT_EXPLANATION.md](D:/accident/golden_hour/PROJECT_EXPLANATION.md)
- [NEXT_PHASE_CHECKLIST.md](D:/accident/golden_hour/NEXT_PHASE_CHECKLIST.md)
- [FINAL_STATUS.md](D:/accident/golden_hour/FINAL_STATUS.md)
- [RELEASE_CHECKLIST.md](D:/accident/golden_hour/RELEASE_CHECKLIST.md)
- [ANDROID_RELEASE_GUIDE.md](D:/accident/golden_hour/ANDROID_RELEASE_GUIDE.md)
- [PUBLIC_RELEASE_ROADMAP.md](D:/accident/golden_hour/PUBLIC_RELEASE_ROADMAP.md)
- [PRIVACY_POLICY.md](D:/accident/golden_hour/PRIVACY_POLICY.md)
- [TERMS_OF_USE.md](D:/accident/golden_hour/TERMS_OF_USE.md)

