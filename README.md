# 🩸 Shadow Hunt — Multiplayer Horror Game
### PUSL2023 Mobile Application Development

---

## 📱 App Overview
Shadow Hunt is a real-time multiplayer horror game built with Flutter and Firebase.
One player is assigned as the **Hunter**, the rest are **Survivors**.
- Survivors must complete mini-tasks (tap challenges, phone shaking) to escape
- The Hunter must catch all survivors before they finish
- All gameplay is synced in real-time via Firebase Realtime Database

---

## 🛠️ Setup Instructions

### Step 1 — Install Tools
- Flutter SDK: https://flutter.dev/docs/get-started/install/windows
- VS Code: https://code.visualstudio.com
- Android Studio (for emulator): https://developer.android.com/studio
- Git: https://git-scm.com

### Step 2 — Clone & Install Dependencies
```bash
git clone <your-github-repo-url>
cd shadow_hunt
flutter pub get
```

### Step 3 — Firebase Setup
1. Go to https://console.firebase.google.com
2. Click "Add Project" → name it `shadow-hunt`
3. Enable **Authentication** → Email/Password
4. Enable **Cloud Firestore** → Start in test mode
5. Enable **Realtime Database** → Start in test mode → pick a region
6. Click "Add App" → Android → enter package name: `com.example.shadow_hunt`
7. Download `google-services.json` → place it in `android/app/`

### Step 4 — Configure Firebase in Flutter
```bash
dart pub global activate flutterfire_cli
flutterfire configure
```
This auto-generates `lib/firebase_options.dart`

### Step 5 — Run the App
```bash
flutter run
```

---

## 📂 Project Structure
```
lib/
├── main.dart                  # App entry point
├── firebase_options.dart      # Firebase config (auto-generated)
├── models/
│   ├── player_model.dart      # Player data model
│   ├── room_model.dart        # Game room data model
│   └── task_model.dart        # Task data model + default tasks
├── services/
│   ├── auth_service.dart      # Firebase Auth (login/register/logout)
│   ├── game_service.dart      # Game logic (rooms, tasks, win conditions)
│   └── leaderboard_service.dart # Firestore leaderboard
└── screens/
    ├── splash_screen.dart     # App intro screen
    ├── home_screen.dart       # Main menu
    ├── lobby_screen.dart      # Create/join room + waiting lobby
    ├── role_screen.dart       # Role reveal animation
    ├── gameover_screen.dart   # Win/loss result screen
    ├── leaderboard_screen.dart# Global rankings
    └── game/
        ├── hunter_screen.dart # Hunter gameplay
        └── survivor_screen.dart # Survivor gameplay + tasks
```

---

## 🎮 Pages (7 total — exceeds requirement of 5)
| Screen | Description |
|--------|-------------|
| Splash Screen | Animated intro with horror theme |
| Login / Register | Firebase Auth screens |
| Home Screen | Main menu with navigation |
| Lobby Screen | Create/join room with live player list |
| Role Screen | Animated role reveal (Hunter or Survivor) |
| Hunter Screen | Real-time survivor tracking + catch button |
| Survivor Screen | Task list + interactive mini-games |
| Game Over Screen | Win/loss result + stats update |
| Leaderboard Screen | Global rankings from Firestore |

---

## 🔥 Firebase Usage
| Service | Usage |
|---------|-------|
| Firebase Auth | User login, registration |
| Firestore | User profiles, leaderboard, win/loss stats |
| Realtime Database | Live game state, room data, tasks, player status |

---

## 📱 Device Features Used
- **Accelerometer (sensors_plus)** — Shake tasks for survivors
- **Haptic feedback** — Vibration on events
- **Torch/Flashlight (torch_light)** — Optional hunter power
