# Navodayan Mobile (Flutter)

Flutter mobile application for the Navodayan community portal (Android & iOS).

## Package / Bundle IDs
- **Android Application ID**: `org.navodayan.app`
- **iOS Bundle ID**: `org.navodayan.app`

## Features
- **Authentication**: Login, Registration, Password Reset, Profile Management with persistent token storage.
- **Directory**: School and batch directory lookup with real-time search, filtering, and mentor badges.
- **Mentorship Hub**: Connect mentors and mentees with personalized request handling.
- **Firebase Integration**: Real-time Firebase Chat, Analytics, and Crashlytics.
- **Events & Community**: Community lounge and upcoming alumni events.
- **Modern UI**: Polished Material 3 design with full Dark Mode support and responsive navigation.

## Development

### 1. Install Dependencies
```bash
flutter pub get
```

### 2. Run the Application
```bash
# Run on default connected device / emulator
flutter run

# Run with custom API URL
flutter run --dart-define=API_BASE_URL=https://api.navodayan.org/api
```

### 3. Run Tests
```bash
flutter test
```

## CI/CD Pipeline (GitHub Actions)

The repository includes an automated workflow in `.github/workflows/build-and-distribute.yml` that:
1. Validates code through automated testing (`flutter test`).
2. Builds release APK (`build/app/outputs/flutter-apk/app-release.apk`).
3. Builds release App Bundle (`build/app/outputs/bundle/release/app-release.aab`).
4. Uploads both APK and AAB as downloadable GitHub Actions artifacts.
5. Distributes release APK to testers via **Firebase App Distribution**.

### Firebase Distribution Configuration
To enable Firebase App Distribution in GitHub Actions, add these repository secrets in GitHub (*Settings > Secrets and variables > Actions*):
- `FIREBASE_SERVICE_ACCOUNT_KEY`: Service account JSON key with Firebase App Distribution Admin role.
- `FIREBASE_APP_ID` (Optional): `1:302719874856:android:f09cbf8514adec44c7c21d` (defaults automatically from config).
