# Bhitte Patro

<p align="center">
  <img width="100" height="100" alt="logo" src="https://github.com/user-attachments/assets/f0970223-6f0b-4709-bdc9-ad6856b323f2" />
</p>

Bhitte Patro is a modern, feature-rich Nepali calendar, scheduling, and news aggregator application built with Flutter. It provides a traditional Bikram Sambat (BS) calendar, a task scheduler that syncs with Google Calendar, real-time weather and astronomical tracking, an interactive globe simulation, and a daily news feed aggregated from scraped Nepalese online portals.


<div style="width: 100%; overflow-x: auto; margin: 20px 0; font-family: sans-serif;">
  <table style="width: 100%; border-collapse: collapse; text-align: center;">
    <thead>
      <tr>
        <th style="padding: 15px; border: 1px solid #ccc; background-color: #f4f4f4; font-weight: bold;">Screenshot 1</th>
        <th style="padding: 15px; border: 1px solid #ccc; background-color: #f4f4f4; font-weight: bold;">Screenshot 2</th>
        <th style="padding: 15px; border: 1px solid #ccc; background-color: #f4f4f4; font-weight: bold;">Screenshot 3</th>
      </tr>
    </thead>
    <tbody>
      <tr>
        <td style="padding: 15px; border: 1px solid #ccc; vertical-align: top;">
          <img width="400" height="900" alt="simulator_screenshot_328A473F-2466-4690-8C58-AC1AC403F3F6" src="https://github.com/user-attachments/assets/efdb6c3d-90d0-419b-8333-5dfc27cad79a" style="max-width: 100%; height: auto;" />
        </td>
        <td style="padding: 15px; border: 1px solid #ccc; vertical-align: top;">
          <img width="400" height="900" alt="simulator_screenshot_9EF0CB89-20B5-480D-BFD5-58BE4F5F9948" src="https://github.com/user-attachments/assets/0e1732a1-3195-4620-a2eb-b084dc3906b2" style="max-width: 100%; height: auto;" />
        </td>
          <td style="padding: 15px; border: 1px solid #ccc; vertical-align: top;">
          <img width="400" height="900" alt="simulator_screenshot_9EF0CB89-20B5-480D-BFD5-58BE4F5F9948" src="https://github.com/user-attachments/assets/a4f4e8e9-3cbc-4eff-bac9-295e262fe089" style="max-width: 100%; height: auto;" />
        </td>
      </tr>
    </tbody>
  </table>
</div>

<div style="width: 100%; overflow-x: auto; margin: 20px 0; font-family: sans-serif;">
  <table style="width: 100%; border-collapse: collapse; text-align: center;">
    <thead>
      <tr>
        <th style="padding: 15px; border: 1px solid #ccc; background-color: #f4f4f4; font-weight: bold;">Home Widget Small</th>
        <th style="padding: 15px; border: 1px solid #ccc; background-color: #f4f4f4; font-weight: bold;">Home Widget Medium</th>
        <th style="padding: 15px; border: 1px solid #ccc; background-color: #f4f4f4; font-weight: bold;">Home Widget Large</th>
      </tr>
    </thead>
    <tbody>
      <tr>
        <td style="padding: 15px; border: 1px solid #ccc; vertical-align: top;">
          <img width="400" height="900" alt="simulator_screenshot_328A473F-2466-4690-8C58-AC1AC403F3F6" src="https://github.com/user-attachments/assets/a944315c-cce9-47b5-bdb7-2bf49aeaa741" style="max-width: 100%; height: auto;" />
        </td>
        <td style="padding: 15px; border: 1px solid #ccc; vertical-align: top;">
          <img width="400" height="900" alt="simulator_screenshot_9EF0CB89-20B5-480D-BFD5-58BE4F5F9948" src="https://github.com/user-attachments/assets/b941f9a2-00bc-4e71-b436-086e56c053ea" style="max-width: 100%; height: auto;" />
        </td>
    <td style="padding: 15px; border: 1px solid #ccc; vertical-align: top;">
          <img width="400" height="900" alt="simulator_screenshot_9EF0CB89-20B5-480D-BFD5-58BE4F5F9948" src="https://github.com/user-attachments/assets/4d5d05ed-1de0-40dd-b73f-995c89253ede" style="max-width: 100%; height: auto;" />
        </td>
      </tr>
    </tbody>
  </table>
</div>



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
