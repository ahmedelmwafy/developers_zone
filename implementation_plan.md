# Developers Zone — Project Guide 🚀

The **Developers Zone** application is a production-level social platform built with Flutter using **MVC Architecture**, **Provider** state management, and **Firebase** backend.

## 📁 Architecture Overview (MVC)
- **Models**: `lib/models/` — Data definitions and factory methods (User, Post, Chat, etc.).
- **Views**: `lib/views/` — Responsive and modern UI with dark theme.
- **Controllers**: `lib/controllers/` — Business logic and state handling using Providers.
- **Services**: `lib/services/` — External interactions (Firebase, ImgBB, AdMob).

## 🛠 Required Setup Steps

### 1. Firebase Configuration
Since the codebase assumes Firebase is initialized, you must:
1. Go to the [Firebase Console](https://console.firebase.google.com/).
2. Create a new project called `Developers Zone`.
3. Add **Android** and **iOS** apps to your Firebase project.
4. Download `google-services.json` (Android) and `GoogleService-Info.plist` (iOS).
5. Place them in:
   - `android/app/google-services.json`
   - `ios/Runner/GoogleService-Info.plist`
6. Enable **Authentication** (Email/Password, Google, Apple).
7. Enable **Cloud Firestore** and set the security rules to allow read/write for authenticated users.

### 2. ImgBB API Key
Image uploads are handled via ImgBB.
1. Get a free API key from [ImgBB API](https://api.imgbb.com/).
2. Replace the placeholder in `lib/services/imgbb_service.dart`:
   ```dart
   static const String apiKey = 'YOUR_IMGBB_API_KEY';
   ```

### 3. Google AdMob
AdMob is initialized. Use the test IDs provided in `AndroidManifest.xml` and `Info.plist` for development. Replace with production IDs during release.

### 4. Running the App
Since `flutter create` was not executed due to local environment restrictions, follow these steps in your terminal:
```bash
# 1. Generate missing native files if needed (or let the IDE handle it)
flutter create --org com.valiidate --project-name developers_zone .

# 2. Get dependencies
flutter pub get

# 3. Run the app
flutter run
```

## ✨ Features Included
- ✅ **Authentication**: Email/Pass, Google, Apple.
- ✅ **Localization**: Arabic and English fully supported with dynamic switching.
- ✅ **Profile**: CRUD with ImgBB upload, social links, and bio.
- ✅ **Posts**: Real-time global feed with filtering by job position.
- ✅ **Chat**: Real-time one-to-one private messaging.
- ✅ **Admin**: User ban/unban system and real-time Ad Management.
- ✅ **Monetization**: Splash Ads and Home Banner Carousel.

---
**Enjoy building the Developer Community!**
