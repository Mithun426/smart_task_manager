# Smart Task Manager

A Flutter task management app with Firebase backend, offline support, and a clean Material Design UI.

## Features

- **Authentication** — Email/password login & registration via Firebase Auth
- **Task Management** — Create, edit, delete, and mark tasks as complete
- **Search & Filter** — Search tasks by title, filter by status, sort by date/priority
- **Offline Support** — Local caching with Hive, auto-sync when back online
- **Dark Mode** — Toggle between light and dark themes (persisted locally)
- **Profile** — View and update your display name
- **Shimmer Loading** — Skeleton placeholders while data loads

## Tech Stack

| Layer | Tool |
|-------|------|
| Framework | Flutter |
| State Management | Riverpod |
| Backend | Firebase (Auth + Firestore) |
| Networking | Dio |
| Local Storage | Hive |
| Routing | GoRouter |
| Code Generation | Freezed + JSON Serializable |

## Project Structure

```
lib/
├── core/
│   ├── errors/          # Custom exception classes
│   ├── local_storage/   # Hive setup & helpers
│   ├── network/         # Dio client & API constants
│   ├── router/          # GoRouter configuration
│   ├── theme/           # App theme & theme provider
│   └── widgets/         # Shared UI components
├── features/
│   ├── auth/            # Login, registration, auth state
│   ├── profile/         # User profile & settings
│   └── tasks/           # Task CRUD, list, filters
├── firebase_options.dart
└── main.dart
```

## Setup

### Prerequisites

- Flutter SDK (3.11+)
- A Firebase project with Auth and Firestore enabled

### Steps

1. **Clone the repo**
   ```bash
   git clone https://github.com/your-username/smart_task_manager.git
   cd smart_task_manager
   ```

2. **Install dependencies**
   ```bash
   flutter pub get
   ```

3. **Firebase config**
   - Set up a Firebase project and add your Android/iOS app
   - Place `google-services.json` in `android/app/`
   - Update `firebase_options.dart` if using FlutterFire CLI

4. **Run code generation**
   ```bash
   dart run build_runner build --delete-conflicting-outputs
   ```

5. **Run the app**
   ```bash
   flutter run
   ```

## Screenshots

_Coming soon_

## License

This project is for personal/educational use.
