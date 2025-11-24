# Admin Panel Guide

## Overview

The VOGUE AI project has **two separate applications**:

1. **User App (Android)** - `lib/main.dart` - For end users
2. **Admin Panel (Web)** - `lib/admin_main.dart` - For administrators

Both connect to the same Firebase backend but serve different purposes.

## Building the Applications

### User App (Android)

```bash
# Build Android APK
flutter build apk --target=lib/main.dart

# Build Android App Bundle (for Play Store)
flutter build appbundle --target=lib/main.dart
```

### Admin Panel (Web)

```bash
# Build web dashboard
flutter build web --target=lib/admin_main.dart

# Run admin panel locally
flutter run -d chrome --target=lib/admin_main.dart
```

## Admin Panel Features

### 1. **User Management**
- View all registered users
- Search users by email or UID
- View user details (onboarding data, analysis)
- Block/unblock users

### 2. **Clothing Management**
- Add, edit, delete clothing items
- Manage clothing database
- View all clothing items with images

### 3. **Analytics Dashboard**
- Total users count
- Users with completed onboarding
- Users with skin analysis
- Completion rates

### 4. **Questionnaire Management**
- Edit body types options
- Edit size ranges
- Edit fit preferences
- Edit style goals

### 5. **Chatbot Review**
- View all chatbot conversations
- Review user interactions
- Monitor chatbot performance

### 6. **Color Recommendations**
- Manage color recommendations by skin tone
- Update color palettes
- Configure seasonal color types

### 7. **Jewelry Management**
- Add/edit jewelry recommendations
- Manage jewelry items by skin tone
- Configure jewelry suggestions

### 8. **Scraper Configuration**
- Enable/disable web scraping
- Configure max items per brand
- Set timeout values
- Manage retry attempts
- Configure brands to scrape

### 9. **Export Data**
- Export all users data (JSON)
- Export analytics data
- Generate reports

## Setting Up Admin Access

### Step 1: Create Admin User in Firebase

1. Go to Firebase Console → Authentication
2. Create a user account with email/password
3. Note the User UID

### Step 2: Add Admin Role in Firestore

1. Go to Firebase Console → Firestore Database
2. Create a collection named `admins`
3. Add a document with the User UID as document ID
4. Add field: `role` = `"admin"`

Example:
```
Collection: admins
Document ID: [USER_UID]
Fields:
  - role: "admin"
  - createdAt: [timestamp]
  - email: "admin@example.com"
```

### Step 3: Access Admin Panel

1. Build web: `flutter build web --target=lib/admin_main.dart`
2. Deploy to Firebase Hosting or your web server
3. Navigate to the admin panel URL
4. Sign in with the admin account credentials

## Security Notes

- Admin authentication checks for `role: "admin"` in Firestore `admins` collection
- Regular users cannot access admin panel (role check fails)
- Admin code is completely separate from user app code
- Admin panel is web-only (not available in Android app)

## File Structure

```
lib/
├── main.dart                    # User app entry point (Android)
├── admin_main.dart              # Admin panel entry point (Web)
├── screens/
│   ├── admin/                   # Admin screens (web only)
│   │   ├── admin_login_screen.dart
│   │   ├── admin_dashboard_screen.dart
│   │   ├── user_management_screen.dart
│   │   ├── clothing_management_screen.dart
│   │   ├── analytics_screen.dart
│   │   ├── questionnaire_management_screen.dart
│   │   ├── chatbot_review_screen.dart
│   │   ├── color_recommendations_screen.dart
│   │   ├── jewelry_management_screen.dart
│   │   ├── scraper_config_screen.dart
│   │   └── export_screen.dart
│   └── [user screens]           # User app screens (Android)
└── services/
    └── admin_service.dart       # Admin Firebase operations
```

## Firestore Collections

### Admin Collections:
- `admins/{uid}` - Admin users with role
- `clothing_items/{itemId}` - Admin-managed clothing
- `jewelry_items/{itemId}` - Jewelry recommendations
- `chatbot_conversations/{convId}` - Chat logs
- `scraper_config/settings` - Scraper configuration
- `config/color_recommendations` - Color rules

### User Collections (read-only for admin):
- `users/{uid}` - User accounts
- `users/{uid}/onboarding/` - Questionnaire data
- `users/{uid}/analysis/` - Skin tone analysis
- `config/questionnaire_v1` - Questionnaire config

## Troubleshooting

### Admin login fails
- Check if user exists in `admins` collection
- Verify `role` field is set to `"admin"`
- Check Firebase Authentication is enabled

### Admin panel not loading
- Ensure you're building with `--target=lib/admin_main.dart`
- Check Firebase configuration in `firebase_options.dart`
- Verify web build completed successfully

### Cannot access admin features
- Verify you're signed in with an admin account
- Check Firestore security rules allow admin access
- Ensure `admins` collection exists and has your UID

## Deployment

### Deploy Admin Panel to Firebase Hosting

```bash
# Build web
flutter build web --target=lib/admin_main.dart

# Deploy to Firebase Hosting
firebase deploy --only hosting
```

### Deploy User App to Play Store

```bash
# Build app bundle
flutter build appbundle --target=lib/main.dart

# Upload to Play Console
# Follow Google Play Console instructions
```

## Support

For issues or questions about the admin panel, check:
- Firebase Console for data issues
- Flutter build logs for compilation errors
- Browser console for web-specific errors

