# Bhitte Patro

Bhitte Patro is a modern, feature-rich Nepali calendar, scheduling, and news aggregator application built with Flutter. It provides a traditional Bikram Sambat (BS) calendar, a task scheduler that syncs with Google Calendar, real-time weather and astronomical tracking, an interactive globe simulation, and a daily news feed aggregated from scraped Nepalese online portals.

---

## Key Features

- **Nepali Calendar (Bikram Sambat)**
  - View months and days in the Bikram Sambat system.
  - Convert dates between Bikram Sambat (BS) and Gregorian (AD) calendars using a custom conversion algorithm.
  - Access details for holidays, festivals, and events cached locally.

- **Schedule and Reminders**
  - Add, edit, and delete personal reminders.
  - Sync reminders in real time with Google Calendar using the Google Calendar API.
  - Schedule local push notifications for upcoming reminders using timezone-aware notifications.

- **Interactive Earth Globe**
  - View an interactive 3D/2D Earth globe visualization representing the Earth.
  - Render orbital paths, angles, and relative positions of the Sun and Moon based on astronomical parameters.

- **Weather and Sun Times**
  - Access real-time temperature data based on the user's location via the Open-Meteo API.
  - Calculate precise sunrise and sunset times on-device using a custom implementation of the NOAA Solar Calculator.
  - Fall back to Kathmandu coordinates (27.7172 N, 85.3240 E) if location permissions are denied.

- **Aggregated News Feed**
  - Read curated daily news headlines, summaries, and source metadata.
  - Open news articles in an integrated in-app webview.

- **Authentication**
  - Secure login using Firebase Authentication integrated with Google Sign-In.

- **Over-The-Air (OTA) Updates**
  - Fully configured with Shorebird Code Push to deploy patches directly to users without requiring App Store or Google Play Store updates.

---

## Data Integrations and Scraped Resources

Bhitte Patro combines local computations, external APIs, and scraped content to deliver a rich experience:

1. **News Aggregator Scraper**
   - News articles are fetched from a JSON endpoint updated by an external scraper.
   - Endpoint: `https://raw.githubusercontent.com/gaurovgiri/newsapi/refs/heads/master/data/today.json`
   - Data points include: scraped date and time, list of active sources, article title, summary snippet, source portal name, original article URL, and thumbnail image URL.

2. **Weather API**
   - Real-time weather parameters are requested dynamically using the Open-Meteo API.
   - Endpoint: `https://api.open-meteo.com/v1/forecast` (queries latitude, longitude, and current weather flags).

3. **Sunrise and Sunset Calculations**
   - Calculated locally in Dart using custom astronomical equations derived from the NOAA Solar Calculator.
   - Inputs user geolocation coordinates (latitude/longitude) or falls back to Kathmandu coordinates.

4. **Static Calendar Database**
   - Calendar structures, monthly days, and holiday listings are loaded from the local asset database at `assets/calendar.json`.

---

## Project Architecture

The application is structured using a feature-first approach to decouple independent modules and ensure clean separation of concerns.

### Directory Layout

```
lib/
├── core/                       - Shared system-wide configurations, models, and services
│   ├── consts/                 - Design system styling (colors, typography, spacing)
│   ├── models/                 - Data structures and Hive schemas (calendar, news, reminders)
│   ├── providers/              - Riverpod state management and dependency injection providers
│   ├── repositories/           - Local cache database wrappers
│   ├── router/                 - App navigation configuration using GoRouter
│   ├── services/               - Platform integrations (Firebase Auth, Google Calendar, Notifications)
│   ├── strings/                - App translation strings and literals
│   └── utils/                  - Utilities (logger, Nepali date converter, solar calculator)
│
├── features/                   - Feature modules containing UI and business logic
│   ├── auth/                   - Authentication flow screens (Login page)
│   ├── calendar/               - Bikram Sambat grid views, events lists, and date detail sheets
│   ├── globe/                  - Interactive space simulation, painters, and orbit tracking
│   ├── home/                   - Dashboards, greeting headers, and main entry structures
│   ├── news/                   - News feed UI, listings, and detailed in-app webviews
│   ├── profile/                - User profile management and log out actions
│   └── schedule/               - Reminder additions, detail sheets, and sync settings
│
└── shared/                     - Shared widgets and global structural layouts
    └── layout/                 - Layout configurations (bottom navigation ShellRoute shell)
```

### Key Libraries and SDKs Used

- **Framework**: Flutter SDK (supported SDK version ^3.11.0)
- **State Management**: Flutter Riverpod (`flutter_riverpod`)
- **Routing**: GoRouter (`go_router`)
- **Local Persistence**: Hive (`hive_flutter`) for local key-value databases
- **Authentication**: Firebase Core (`firebase_core`), Firebase Auth (`firebase_auth`), and Google Sign-In (`google_sign_in`)
- **APIs and Clients**: HTTP (`http`), HTTP client (`dio`), and Google APIs client (`googleapis`, `googleapis_auth`)
- **Notifications**: Flutter Local Notifications (`flutter_local_notifications`), Timezone (`timezone`)
- **Visualization**: Flutter Earth Globe (`flutter_earth_globe`), CustomPainter
- **Over-The-Air Engine**: Shorebird (`shorebird.yaml`)

---

## Download and Installation Steps

### Prerequisites

Before starting, ensure you have the following installed on your machine:
- Flutter SDK (version 3.11.0 or higher)
- Dart SDK
- Android SDK (for Android builds) or Xcode (for iOS builds, macOS only)
- Firebase CLI (configured with your Firebase account credentials)
- Shorebird CLI (optional, if deploying over-the-air patches)

### Step 1: Clone the Repository

Download the project source files to your local workstation:

```bash
git clone https://github.com/your-username/bhitte_patro.git
cd bhitte_patro
```

### Step 2: Install Flutter Dependencies

Fetch all external packages listed in the configuration file:

```bash
flutter pub get
```

### Step 3: Configure Firebase and Google Console Credentials

The app uses Firebase for authentication and the Google Calendar API for scheduling sync. Ensure you perform the following configurations:

1. **Firebase Setup**:
   - Register the app in your Firebase console.
   - Download the configuration files (`google-services.json` for Android, `GoogleService-Info.plist` for iOS) and place them in their respective platform directories.
   - Configure Firebase details inside `firebase.json` at the root of the project.

2. **Google Sign-In & Google Calendar API Scopes**:
   - In the Google Cloud Console, enable the **Google Calendar API**.
   - Set up the OAuth consent screen and add the `https://www.googleapis.com/auth/calendar` scope.
   - Add your development SHA-1 certificate fingerprint to the Firebase Android app configuration.

### Step 4: Run the Application

Execute the run command to deploy the app to an active emulator, simulator, or connected physical device:

```bash
flutter run
```

### Step 5: Build Production Binaries

Generate optimized release builds for distribution:

- **Android APK**:
  ```bash
  flutter build apk --release
  ```

- **iOS App Bundle**:
  ```bash
  flutter build ipa --release
  ```

---

## Shorebird Over-The-Air Patches

To apply code updates dynamically without uploading a new version to the Google Play Store or Apple App Store:

1. Install the Shorebird command-line tool if you have not done so already:
   ```bash
   curl --proto '=https' --tlsv1.2 -sSf https://install.shorebird.dev | bash
   ```

2. Authenticate the CLI with your Shorebird account:
   ```bash
   shorebird login
   ```

3. Deploy an OTA patch release:
   - For Android:
     ```bash
     shorebird patch android
     ```
   - For iOS:
     ```bash
     shorebird patch ios
     ```
