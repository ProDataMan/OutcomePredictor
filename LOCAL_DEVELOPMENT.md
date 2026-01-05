# StatShark Local Development Guide

Develop and test StatShark without waiting for Azure deployments. This guide shows you how to run the backend API
locally using Docker and automatically configure iOS and Android apps to use local services.

## Quick Start

### 1. Setup Environment Variables

Copy the example environment file and add your API keys:

```bash
cp .env.example .env
```

Edit `.env` and add your API keys:
- `ODDS_API_KEY` - Get free key at https://the-odds-api.com/
- `NEWS_API_KEY` - Get free key at https://newsapi.org/
- `API_SPORTS_KEY` - Get key at https://api-sports.io/

### 2. Start Local Backend

```bash
docker-compose up -d
```

The API server runs at `http://localhost:8080/api/v1`

Check health:
```bash
curl http://localhost:8080/api/v1/teams
```

View logs:
```bash
docker-compose logs -f api
```

Stop server:
```bash
docker-compose down
```

### 3. Run iOS App

iOS automatically uses the correct backend based on build configuration:

**Debug Build** (Xcode default):
- Uses `http://localhost:8080/api/v1`
- Fast local development
- No Azure deployment needed

**Release Build** (Archive for App Store):
- Uses `https://statshark-api.azurewebsites.net/api/v1`
- Production Azure backend

Simply run the app in Xcode with Run (⌘R) for debug mode.

### 4. Run Android App

Android automatically uses the correct backend based on build variant:

**Debug Variant** (Android Studio default):
- Uses `http://10.0.2.2:8080/api/v1` (Android emulator localhost)
- Fast local development
- No Azure deployment needed

**Release Variant** (Build APK/Bundle):
- Uses `https://statshark-api.azurewebsites.net/api/v1`
- Production Azure backend

Simply run the app in Android Studio for debug mode.

**Note:** Android emulator uses `10.0.2.2` to access host machine's `localhost`.

## Development Workflow

### Rapid Feature Development

1. Make code changes to backend (`Sources/`)
2. Rebuild Docker container:
   ```bash
   docker-compose up -d --build
   ```
3. Run iOS or Android app in debug mode
4. Test changes immediately

No Azure deployment required during feature development.

### Testing with Real Devices

#### iOS Physical Device
Update `AppConfiguration.swift` temporarily for your Mac's IP:
```swift
case .debug:
    return "http://192.168.1.XXX:8080/api/v1"  // Replace with your Mac's IP
```

#### Android Physical Device
Update `build.gradle.kts` temporarily for your computer's IP:
```kotlin
debug {
    buildConfigField("String", "API_BASE_URL", "\"http://192.168.1.XXX:8080/api/v1/\"")
}
```

Find your IP:
```bash
ifconfig | grep "inet " | grep -v 127.0.0.1
```

## Deployment to Azure

Deployments now only happen on GitHub releases, not on every push.

### Creating a Release

1. Commit and push your changes:
   ```bash
   git add .
   git commit -m "feat: your feature description"
   git push origin main
   ```

2. Create a release tag:
   ```bash
   git tag v1.0.0
   git push origin v1.0.0
   ```

3. Create GitHub release:
   - Go to GitHub repository
   - Click "Releases" → "Create a new release"
   - Select your tag
   - Add release notes
   - Click "Publish release"

This triggers the deployment workflow automatically.

### Manual Deployment

Trigger deployment manually from GitHub Actions:
- Go to Actions tab
- Select "Deploy StatShark to Azure" workflow
- Click "Run workflow"

## Troubleshooting

### Docker Container Not Starting

Check logs:
```bash
docker-compose logs api
```

Common issues:
- Port 8080 already in use: Change port in `docker-compose.yml`
- Missing API keys: Check `.env` file

### iOS App Cannot Connect

Check:
1. Docker container is running: `docker-compose ps`
2. API responds: `curl http://localhost:8080/api/v1/teams`
3. Using Debug build configuration in Xcode

### Android App Cannot Connect

Check:
1. Docker container is running: `docker-compose ps`
2. API responds: `curl http://localhost:8080/api/v1/teams`
3. Using Debug build variant in Android Studio
4. Emulator can access host: `adb shell ping 10.0.2.2`

### Rebuild Everything

```bash
docker-compose down
docker-compose build --no-cache
docker-compose up -d
```

## Configuration Summary

| Component | Debug/Development | Release/Production |
|-----------|------------------|-------------------|
| Backend (Docker) | `http://localhost:8080` | Azure Web App |
| iOS App | `http://localhost:8080/api/v1` | `https://statshark-api.azurewebsites.net/api/v1` |
| Android App | `http://10.0.2.2:8080/api/v1` | `https://statshark-api.azurewebsites.net/api/v1` |
| GitHub Actions | Runs tests only | Full deployment on release |

## Benefits

- **No waiting**: Test changes in seconds, not minutes
- **Cost efficient**: Azure only runs for production
- **Seamless**: Apps automatically use correct backend
- **Safe**: Production deploys only on releases
- **Painless**: One command to start developing
