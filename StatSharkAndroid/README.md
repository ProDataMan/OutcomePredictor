# StatShark NFL Predictor - Android App

Android version of the StatShark NFL prediction and fantasy football app.

## 🏗️ Architecture

- **Language:** Kotlin 100%
- **UI:** Jetpack Compose (Material 3)
- **Architecture:** MVVM
- **Dependency Injection:** Hilt
- **Networking:** Retrofit + OkHttp
- **Image Loading:** Coil
- **Navigation:** Jetpack Navigation Compose

## 📱 Features

### Implemented ✅
- ✅ Project structure with Jetpack Compose
- ✅ API client with Retrofit and Hilt DI
- ✅ Complete data models (DTOs) matching backend API
- ✅ Navigation with bottom bar and deep linking
- ✅ Material 3 theming with team colors
- ✅ **Teams Screen** - Grid view of all 32 NFL teams with conference filtering
- ✅ **Team Detail Screen** - 3-tab interface with:
  - Player roster with photos, stats, and position grouping
  - Game history with scores and win/loss tracking
  - Team news feed with articles
  - Season selector (2020-present)
- ✅ **Predictions Screen** - AI-powered game predictions with:
  - Upcoming games display
  - On-demand prediction generation
  - Win probabilities and confidence scores
  - Detailed analysis and reasoning
  - Vegas odds comparison
- ✅ Team color system for all 32 NFL teams
- ✅ Error handling with retry functionality
- ✅ Loading states and empty states
- ✅ Network timeout configuration for Azure cold starts

### In Progress 🚧
- 🚧 Player detail screen
- 🚧 Game detail screen

### Planned ⏳
- ⏳ Fantasy screen with roster management
- ⏳ Push notifications for game updates
- ⏳ Offline caching with Room database
- ⏳ Widget for upcoming predictions

## 🚀 Getting Started

### Prerequisites
- Android Studio Hedgehog (2023.1.1) or newer
- JDK 17
- Android SDK 34
- Minimum SDK: 26 (Android 8.0)

### Setup
1. Open project in Android Studio
2. Sync Gradle files
3. Run on emulator or device

### API Configuration
The app connects to the StatShark API:
- Production: `https://statshark-api.azurewebsites.net/api/v1`
- Configured in `app/build.gradle.kts`

## 📦 Dependencies

### Core
- AndroidX Core KTX
- Lifecycle Runtime
- Activity Compose

### UI
- Jetpack Compose (Material 3)
- Compose Navigation
- Material Icons Extended

### Networking
- Retrofit 2.9.0
- OkHttp 4.12.0
- Gson Converter

### DI
- Hilt 2.48

### Image Loading
- Coil Compose 2.5.0

## 🎨 Design System

### Colors
- Primary: Shark Blue `#1E3A8A`
- Secondary: Shark Teal `#14B8A6`
- Tertiary: Shark Gray `#64748B`

### Typography
- Material 3 default typography with system fonts

## 🔧 Development Status

**Current Phase:** Phase 3 - Core Features Complete ✅

**Completed:**
1. ✅ Phase 1: Foundation (API, Navigation, Architecture)
2. ✅ Phase 2: Teams Screen with API Integration
3. ✅ Phase 3: Team Detail and Predictions Screens

**Next Steps:**
1. Player detail screen with comprehensive stats visualization
2. Game detail screen with play-by-play and box score
3. Fantasy screen for roster management
4. Build and test on Android device/emulator
5. Performance optimization and polish

## 📂 Project Structure

```
app/src/main/kotlin/com/statshark/nfl/
├── api/                    # API client and services
│   ├── ApiClient.kt        # Retrofit configuration with timeouts
│   └── StatSharkApiService.kt  # API endpoints
├── data/                   # Data layer
│   ├── model/
│   │   └── DTOs.kt         # Data transfer objects
│   └── repository/
│       └── NFLRepository.kt  # Repository with caching
├── di/                     # Dependency injection
│   └── AppModule.kt        # Hilt modules
├── ui/                     # UI layer
│   ├── navigation/
│   │   └── Navigation.kt   # Routes and navigation
│   ├── screens/
│   │   ├── teams/
│   │   │   ├── TeamsScreen.kt       # Teams grid
│   │   │   ├── TeamsViewModel.kt    # Teams state
│   │   │   ├── TeamDetailScreen.kt  # Team detail UI
│   │   │   └── TeamDetailViewModel.kt  # Team detail state
│   │   ├── predictions/
│   │   │   ├── PredictionsScreen.kt    # Predictions UI
│   │   │   └── PredictionsViewModel.kt # Predictions state
│   │   └── fantasy/
│   │       └── FantasyScreen.kt     # Fantasy placeholder
│   ├── theme/
│   │   ├── Theme.kt         # Material 3 theme
│   │   └── TeamColors.kt    # NFL team colors
│   └── StatSharkApp.kt      # Main app composable
├── MainActivity.kt          # App entry point
└── StatSharkApplication.kt  # Application class with Hilt
```

## 🧪 Testing
- Unit tests: `app/src/test/`
- Instrumented tests: `app/src/androidTest/`

## 📝 Notes

- Extends iOS app timeout (90s) for Azure cold starts
- Uses same API as iOS app
- Feature parity goal with iOS version
- Material 3 design language

## 👨‍💻 Development Timeline

- **Phase 1:** Foundation (API, DTOs, Navigation, DI) ✅
- **Phase 2:** Teams Feature with API Integration ✅
- **Phase 3:** Team Detail and Predictions Features ✅
- **Phase 4:** Player and Game Details (In Progress)
- **Phase 5:** Fantasy Feature (Planned)
- **Phase 6:** Polish, Testing & Launch (Planned)

## 🎯 Current Implementation Status

The Android app now has feature parity with the iOS app for core functionality:

| Feature | iOS | Android | Notes |
|---------|-----|---------|-------|
| Teams List | ✅ | ✅ | Grid view with filtering |
| Team Detail | ✅ | ✅ | Roster, games, news tabs |
| Predictions | ✅ | ✅ | AI predictions with analysis |
| Player Detail | ✅ | 🚧 | Next to implement |
| Game Detail | ✅ | 🚧 | Next to implement |
| Fantasy | 🚧 | 🚧 | Placeholder only |
| Team Colors | ✅ | ✅ | All 32 teams |
| Real Player Stats | ✅ | ✅ | API-Sports integration |
| News Feed | ✅ | ✅ | Team-specific articles |

## 🔨 Building and Running

### Using Android Studio (Recommended)
1. Open the `StatSharkAndroid` directory in Android Studio
2. Let Gradle sync complete
3. Select a device or emulator (API 26+)
4. Click Run or press Shift+F10

### Using Gradle Command Line
```bash
cd StatSharkAndroid
./gradlew assembleDebug          # Build debug APK
./gradlew installDebug           # Install on connected device
./gradlew assembleRelease        # Build release APK (requires signing)
```

Note: The Gradle wrapper needs to be generated on first setup. Android Studio handles this automatically.

---

Built with ❤️ using Jetpack Compose and Claude Code
