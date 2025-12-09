# App Store Submission Guide

This guide prepares the NFL Outcome Predictor iOS app for App Store submission.

## Prerequisites

- Apple Developer Account ($99/year) - [developer.apple.com](https://developer.apple.com)
- Xcode 15.0 or later
- macOS Sonoma or later
- Production API deployed to Azure

## Phase 1: App Store Connect Setup

### 1. Create App ID

1. Login to [Apple Developer Portal](https://developer.apple.com/account)
2. Navigate to Certificates, Identifiers & Profiles
3. Create new App ID:
   - Description: `NFL Outcome Predictor`
   - Bundle ID: `com.yourcompany.nfloutcomepredictor` (must be unique)
   - Capabilities needed: None (using public APIs only)

### 2. Create App Store Connect Record

1. Login to [App Store Connect](https://appstoreconnect.apple.com)
2. Click "My Apps" > "+" > "New App"
3. Fill in details:
   - Platform: iOS
   - Name: `NFL Outcome Predictor`
   - Primary Language: English (U.S.)
   - Bundle ID: Select the one created above
   - SKU: `nfl-predictor-001` (internal reference)
   - User Access: Full Access

## Phase 2: Required Assets

### App Icons

Create app icons in these sizes (use [Figma](https://figma.com) or [IconKitchen](https://icon.kitchen)):

- **1024x1024** - App Store icon (PNG, no alpha channel)
- **180x180** - iPhone @3x
- **120x120** - iPhone @2x
- **167x167** - iPad Pro @2x
- **152x152** - iPad @2x
- **76x76** - iPad

Icon guidelines:
- No transparency
- Use team colors (red, gold for Chiefs or team-neutral)
- Include football or NFL theme
- Readable at small sizes

### Screenshots

Required for each device size:
- **iPhone 6.7" (Pro Max)**: 1290 x 2796 px
- **iPhone 6.5"**: 1284 x 2778 px
- **iPad Pro 12.9"**: 2048 x 2732 px

Take screenshots of:
1. Team selection/browse screen
2. Game prediction screen with results
3. Team detail with schedule
4. Prediction with Vegas odds comparison

### Privacy Policy

Create a privacy policy covering:
- Data collected: None (all data from public APIs)
- Third-party services: ESPN (public), The Odds API (betting odds)
- Analytics: None
- User accounts: None

Host on GitHub Pages or your website. Example template in `PRIVACY_POLICY_TEMPLATE.md`.

## Phase 3: App Configuration

### Update Bundle Identifier

1. Open `/Users/baysideuser/GitRepos/OutcomePredictor/NFLOutcomePredictor/NFLOutcomePredictor.xcodeproj`
2. Select project > Signing & Capabilities
3. Update Bundle Identifier to match App Store Connect
4. Select your team
5. Enable "Automatically manage signing"

### Update Display Name

In `Info.plist`:
```xml
<key>CFBundleDisplayName</key>
<string>NFL Predictor</string>
```

### Update Version and Build

In project settings:
- Version: `1.0`
- Build: `1`

### Configure Production URL

Update APIClient to use production URL:

```swift
init(baseURL: String? = nil) {
    #if DEBUG
    // Development
    if let configuredURL = ProcessInfo.processInfo.environment["SERVER_BASE_URL"] {
        self.baseURL = configuredURL
    } else {
        self.baseURL = baseURL ?? "http://localhost:8080/api/v1"
    }
    #else
    // Production
    self.baseURL = baseURL ?? "https://nfl-predictor-api.azurewebsites.net/api/v1"
    #endif
}
```

## Phase 4: App Store Metadata

Fill in App Store Connect:

### App Information

- **Name**: NFL Outcome Predictor
- **Subtitle**: AI-Powered NFL Game Predictions
- **Category**: Sports
- **Secondary Category**: Entertainment

### Description

```
Predict NFL game outcomes with AI-powered analysis!

NFL Outcome Predictor uses artificial intelligence to analyze team performance, player statistics, and betting odds to predict game outcomes. Get detailed predictions for every NFL game with confidence ratings and expert analysis.

FEATURES:
• AI-powered game predictions
• Real-time scores and schedules
• Team statistics and analysis
• Vegas odds comparison
• Detailed prediction reasoning
• Support for all 32 NFL teams

DATA SOURCES:
• ESPN public API for schedules and scores
• The Odds API for betting lines
• Historical team performance data

Perfect for football fans, fantasy players, and sports enthusiasts who want data-driven insights into upcoming games.

Note: This app provides predictions for entertainment purposes only. Not affiliated with the NFL.
```

### Keywords

```
NFL, football, predictions, sports, betting, odds, fantasy, schedule, scores, teams
```

### Support URL

Create a simple support page or use GitHub repo URL.

### Marketing URL (Optional)

Your website or landing page.

### Privacy Policy URL (Required)

URL to hosted privacy policy.

## Phase 5: Content Rights

### Age Rating

- No objectionable content
- No gambling (we show odds but don't facilitate betting)
- Rating: 4+ (Safe for all ages)

### Export Compliance

- Does not use encryption beyond what iOS provides
- Select "No" for export compliance

## Phase 6: TestFlight Beta Testing

Before submitting to App Store, test with TestFlight:

### 1. Archive for TestFlight

1. Select "Any iOS Device" in Xcode
2. Product > Archive
3. When complete, Organizer opens automatically
4. Click "Distribute App"
5. Select "TestFlight & App Store"
6. Follow prompts

### 2. Add Beta Testers

1. In App Store Connect > TestFlight
2. Add internal testers (up to 100, instant access)
3. Add external testers (unlimited, requires review)

### 3. Beta Test Checklist

Test these flows:
- [ ] Browse all teams
- [ ] View team details and schedule
- [ ] Make game predictions
- [ ] View prediction results
- [ ] Check Vegas odds display
- [ ] Verify season selector works (2024-2025)
- [ ] Test on iPhone and iPad
- [ ] Test on iOS 16, 17, and 18

## Phase 7: Final Submission

### Pre-submission Checklist

- [ ] All screenshots uploaded
- [ ] App icon (1024x1024) uploaded
- [ ] Privacy policy URL added
- [ ] App description complete
- [ ] Keywords optimized
- [ ] Support URL configured
- [ ] Age rating completed
- [ ] TestFlight testing complete
- [ ] Production API deployed and tested
- [ ] Build version incremented

### Submit for Review

1. App Store Connect > "Prepare for Submission"
2. Fill in version information
3. Add build from TestFlight
4. Submit for review

### Review Notes

Add note for App Review team:

```
This app provides AI-powered predictions for NFL games using publicly available data from ESPN and betting odds from The Odds API. The app does not facilitate gambling or betting - it only displays odds for informational purposes.

Test credentials: Not required (no login system)

Important: The app requires an active internet connection to fetch live game data and predictions.
```

## Phase 8: Post-Submission

### Review Timeline

- Typically 1-3 days
- Can be faster for simple apps
- Monitor email for questions from App Review

### If Rejected

Common rejection reasons:
- Missing privacy policy
- Unclear app purpose
- Crash on launch
- Performance issues

Fix issues and resubmit.

### After Approval

1. App appears in App Store within 24 hours
2. Monitor crash reports in Xcode Organizer
3. Respond to user reviews
4. Plan v1.1 with user feedback

## Future Updates

For version 1.1+:
- Add injury tracking to predictions
- Implement home/away performance splits
- Add team statistics integration
- Create fantasy football features
- Add push notifications for game predictions
- Implement user favorites/saved predictions
