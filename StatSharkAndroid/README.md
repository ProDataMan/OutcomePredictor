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

### Implemented
- ✅ Project structure
- ✅ API client with Retrofit
- ✅ Data models (DTOs)
- ✅ Navigation setup
- ✅ Bottom navigation bar
- ✅ Material 3 theming

### In Progress
- 🚧 Teams screen with grid layout
- 🚧 API integration
- 🚧 Team detail view

### Planned
- ⏳ Predictions screen
- ⏳ Fantasy screen
- ⏳ Player details
- ⏳ Game details
- ⏳ News integration

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

**Current Phase:** Phase 1 - Foundation ✅

**Next Steps:**
1. Implement Teams list with API
2. Add team branding system
3. Build team detail screen
4. Create player roster view

## 📂 Project Structure

```
app/src/main/kotlin/com/statshark/nfl/
├── api/                    # API client and services
│   ├── ApiClient.kt
│   └── StatSharkApiService.kt
├── data/                   # Data layer
│   └── model/
│       └── DTOs.kt
├── ui/                     # UI layer
│   ├── navigation/
│   ├── screens/
│   │   ├── teams/
│   │   ├── predictions/
│   │   └── fantasy/
│   └── theme/
├── MainActivity.kt
└── StatSharkApplication.kt
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

- **Week 1:** Foundation (API, DTOs, Navigation) ✅
- **Week 2:** Teams Feature (In Progress)
- **Week 3:** Predictions Feature
- **Weeks 4-5:** Fantasy Feature
- **Week 6:** Polish & Launch

---

Built with ❤️ using Jetpack Compose and Claude Code
