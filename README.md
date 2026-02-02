# Private Two-User Chat (Flutter + Firebase RTDB)

This project implements a minimal real-time chat between two predetermined users
(`atharva` and `Sonal`) backed by **Firebase Realtime Database**. Authentication
is fully custom (no Firebase Auth) and sessions persist locally via
`shared_preferences`.

## Project Structure

```
lib/
├── main.dart
├── models/
│   └── message_model.dart
├── screens/
│   ├── chat_screen.dart
│   └── login_screen.dart
├── services/
│   └── firebase_service.dart
└── widgets/
    └── message_bubble.dart
```

## Firebase Setup

1. Create a Firebase project (already provisioned as `cutiepie-7c441`).
2. Enable **Realtime Database** and set the rules to:
   ```json
   {
     "rules": {
       ".read": true,
       ".write": true
     }
   }
   ```
3. Seed the database with the required structure:
   ```json
   {
     "users": {
       "atharva": {
         "password": "Badboy",
         "name": "Atharva"
       },
       "sonal": {
         "password": "Goodgirl",
         "name": "Sonal"
       }
     }
   }
   ```
4. Download `google-services.json` from the Firebase console and place it in
   `android/app/`. The file is git-ignored to keep credentials private.

## Running the App

1. Ensure Flutter SDK 3.5+ is installed and `flutter doctor` is clean.
2. From the repo root run:
   ```bash
   flutter pub get
   flutter run
   ```
3. Use the following credentials:
   - `atharva / Badboy`
   - `gf / Goodgirl` (maps to `sonal`)

## Feature Notes

- Real-time listener on `chat/` keeps conversations live for both users.
- Message bubbles differentiate sender/receiver with pastel styling.
- Empty messages are blocked with inline validation.
- Logout clears the cached session and returns to the login screen.

## Troubleshooting

- If authentication fails, confirm the user IDs/passwords exist under the exact
  database paths shown above.
- For connectivity issues, verify the `databaseURL` in `google-services.json`
  points to the correct RTDB instance (`asia-southeast1`).
