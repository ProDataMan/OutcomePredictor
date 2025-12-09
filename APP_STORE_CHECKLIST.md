# App Store Submission Checklist

This checklist covers all remaining steps to submit the NFL Outcome Predictor app to the App Store.

## ✅ Completed

- [x] Error handling with Bull Shark dialog
- [x] Score predictions
- [x] UI improvements
- [x] Dockerfile created
- [x] Azure deployment steps documented (AZURE_DEPLOYMENT_STEPS.md)
- [x] Production URL configured in APIClient.swift

## 🔴 Blocking: Deploy Server to Azure

**Required before app submission**

1. Unblock Azure network access in Apple Claude Code dashboard
2. Follow steps in `AZURE_DEPLOYMENT_STEPS.md`
3. Verify API is accessible at: `https://nfl-predictor-api.azurewebsites.net/api/v1/teams`

Once server is deployed, the app automatically uses production URL when built in Release mode.

## 📱 App Icon Assets

### Option 1: Create in Figma/Design Tool

Design Requirements:
- 1024x1024 PNG (no transparency)
- NFL themed (football, teams, predictions)
- Readable at small sizes
- Professional appearance

Suggested Design:
- Football icon
- Chart/graph overlay
- Team colors (red/gold or neutral)
- Bold, simple design

### Option 2: Use SF Symbols

Quick icon using SF Symbols + background:
1. Open Xcode project: `/Users/baysideuser/GitRepos/OutcomePredictor/NFLOutcomePredictor/NFLOutcomePredictor.xcodeproj`
2. Select Assets.xcassets > AppIcon
3. Create placeholder with code:

```swift
import SwiftUI

struct AppIconGenerator: View {
    var body: some View {
        ZStack {
            // Background gradient
            LinearGradient(
                colors: [Color.blue, Color.purple],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )

            VStack(spacing: 8) {
                Image(systemName: "chart.bar.fill")
                    .font(.system(size: 400))
                    .foregroundColor(.white)
                    .shadow(radius: 10)

                Image(systemName: "football.fill")
                    .font(.system(size: 200))
                    .foregroundColor(.white)
                    .offset(y: -50)
            }
        }
        .frame(width: 1024, height: 1024)
    }
}
```

Take screenshot at 1024x1024 and use as app icon.

### Icon Sizes Needed

Add to Assets.xcasset > AppIcon:
- 1024x1024 - App Store
- 180x180 - iPhone @3x
- 120x120 - iPhone @2x
- 167x167 - iPad Pro
- 152x152 - iPad @2x
- 76x76 - iPad

### Quick Icon Tool

Use https://icon.kitchen to generate all sizes from 1024x1024 PNG.

## 🎯 Xcode Configuration

### 1. Open Project in Xcode

```bash
open /Users/baysideuser/GitRepos/OutcomePredictor/NFLOutcomePredictor/NFLOutcomePredictor.xcodeproj
```

### 2. Update Project Settings

Select project root > TARGETS > NFLOutcomePredictor:

**General Tab:**
- Display Name: `NFL Predictor`
- Bundle Identifier: Choose unique ID (example: `com.yourname.nflpredictor`)
- Version: `1.0`
- Build: `1`
- Deployment Target: iOS 16.0 or later

**Signing & Capabilities:**
- Team: Select your Apple Developer team
- Signing Certificate: Apple Development
- Enable "Automatically manage signing"

**Info Tab:**
- Add Privacy - Internet Usage Description: "This app requires internet access to fetch NFL game data and predictions."

### 3. Add App Icons

1. Select Assets.xcassets
2. Click AppIcon
3. Drag icon images to correct size slots
4. Verify all required sizes filled

### 4. Build Settings

Set Release configuration:
- Product > Scheme > Edit Scheme
- Run > Build Configuration > Release
- Archive > Build Configuration > Release

## 📸 Screenshots

Required device screenshots:

### iPhone 6.7" (1290 x 2796)

Take screenshots of:
1. **Teams List** - Grid view of all NFL teams
2. **Team Detail** - Single team with schedule
3. **Prediction Screen** - Game prediction with scores
4. **Prediction Result** - Showing predicted winner and scores

### How to Take Screenshots

1. Run app in Simulator (iPhone 15 Pro Max for 6.7")
2. Navigate to each screen
3. Capture: Device > Trigger Screenshot (Cmd+S)
4. Screenshots saved to Desktop

### iPad Pro 12.9" (2048 x 2732)

Same 4 screenshots on iPad simulator.

## 🔒 Privacy Policy

Create simple privacy policy page. Example content:

```markdown
# Privacy Policy for NFL Outcome Predictor

## Data Collection
NFL Outcome Predictor does not collect, store, or share any personal information.

## Third-Party Services
- ESPN API: Public NFL game data
- The Odds API: Public betting odds
- Azure: Server hosting (no user data stored)

## Analytics
We do not use analytics or tracking.

## Contact
[Your email]

Last updated: [Date]
```

Host on:
- GitHub Pages (free)
- Personal website
- Or use https://www.privacypolicies.com to generate

## 🍎 App Store Connect Setup

### 1. Create App ID

1. Go to https://developer.apple.com/account
2. Certificates, Identifiers & Profiles > Identifiers
3. Click + to create App ID
4. Select App IDs > Continue
5. Description: `NFL Outcome Predictor`
6. Bundle ID: Match Xcode (example: `com.yourname.nflpredictor`)
7. Capabilities: None needed
8. Register

### 2. Create App Store Connect Record

1. Go to https://appstoreconnect.apple.com
2. My Apps > + > New App
3. Fill form:
   - Platforms: iOS
   - Name: `NFL Outcome Predictor`
   - Primary Language: English (U.S.)
   - Bundle ID: Select the one created above
   - SKU: `nfl-predictor-001`
   - User Access: Full Access
4. Create

### 3. Fill App Information

**App Information:**
- Subtitle: `AI-Powered NFL Game Predictions`
- Primary Category: Sports
- Secondary Category: Entertainment
- Content Rights: Check "Yes" (you own rights)

**Pricing and Availability:**
- Price: Free
- Availability: All countries

**App Privacy:**
- Privacy Policy URL: [Your hosted privacy policy URL]
- Data Types: None (no data collected)

### 4. Version Information

**Description:**
```
Predict NFL game outcomes with AI-powered analysis!

NFL Outcome Predictor uses artificial intelligence to analyze team performance, player statistics, and betting odds to predict game outcomes. Get detailed predictions for every NFL game with confidence ratings and expert analysis.

FEATURES:
• AI-powered game predictions with predicted scores
• Real-time schedules and upcoming games
• Team statistics and analysis
• Vegas odds comparison
• Detailed prediction reasoning
• Support for all 32 NFL teams

DATA SOURCES:
• ESPN API for schedules and scores
• The Odds API for betting lines
• Historical team performance data

Perfect for football fans, fantasy players, and sports enthusiasts who want data-driven insights into upcoming games.

Note: This app provides predictions for entertainment purposes only. Not affiliated with the NFL.
```

**Keywords:**
```
NFL,football,predictions,sports,betting,odds,fantasy,schedule,scores,teams
```

**Support URL:** Your website or GitHub repo
**Marketing URL:** Optional

### 5. Add Screenshots

Upload screenshots for:
- iPhone 6.7" (4-10 screenshots)
- iPad Pro 12.9" (4-10 screenshots)

### 6. Build Information

**What to Test:**
```
This app provides AI-powered predictions for NFL games using publicly available data from ESPN and betting odds from The Odds API.

Test Flow:
1. Browse teams list
2. Select a team to view details
3. Tap "Predict" tab
4. Select two teams or tap an upcoming game
5. View prediction with scores and analysis

Note: Requires active internet connection to fetch live data.
```

**Review Notes:**
```
This app provides AI-powered predictions for NFL games using publicly available data. The app does not facilitate gambling or betting - it only displays odds for informational purposes.

No test credentials needed - no login system.
Requires internet connection for all features.
```

**Version Release:** Manual release

**Copyright:** Your name or company, [Year]

**Age Rating:**
- Questionnaire responses: All "None" except:
  - Unrestricted Web Access: No
  - Gambling and Contests: No (informational only)
- Result: 4+ (Safe for all ages)

## 📦 Archive and Upload

### 1. Create Archive

1. In Xcode, select "Any iOS Device" as destination
2. Product > Clean Build Folder (Cmd+Shift+K)
3. Product > Archive (Cmd+B then wait)
4. When complete, Xcode Organizer opens automatically

### 2. Validate Archive

1. In Organizer, select the archive
2. Click "Validate App"
3. Select distribution method: App Store Connect
4. Select distribution certificate
5. Review signing options
6. Validate
7. Fix any issues that appear

### 3. Upload to App Store Connect

1. After successful validation, click "Distribute App"
2. Select App Store Connect
3. Select Upload
4. Review options:
   - Include bitcode: No (not needed for Swift)
   - Upload symbols: Yes (for crash reports)
   - Manage version and build number: Yes
5. Upload
6. Wait for processing (10-30 minutes)

### 4. Select Build in App Store Connect

1. Go to appstoreconnect.apple.com
2. My Apps > NFL Outcome Predictor
3. Version 1.0 > Build section
4. Click + next to Build
5. Select uploaded build
6. Save

## 🚀 Submit for Review

### Pre-Submission Checklist

- [ ] Server deployed to Azure and accessible
- [ ] App icon uploaded (all sizes)
- [ ] Screenshots uploaded (iPhone and iPad)
- [ ] Privacy policy URL added
- [ ] App description complete
- [ ] Keywords added
- [ ] Support URL added
- [ ] Age rating completed
- [ ] Build uploaded and selected
- [ ] Test notes added
- [ ] Version set to "Manual release"

### Submit

1. Click "Add for Review" button
2. Answer export compliance questions:
   - Uses encryption: No (only standard iOS encryption)
3. Submit for Review
4. Wait for confirmation email

## ⏰ Review Timeline

- **In Review**: 1-3 business days typically
- **Status Updates**: Check App Store Connect or email
- **Questions**: Apple Review team may ask questions

## 🎉 After Approval

1. App status changes to "Pending Developer Release"
2. Click "Release This Version" to publish
3. App appears in App Store within 24 hours
4. Monitor crash reports in Xcode Organizer
5. Respond to user reviews

## 🔄 Future Updates

Version 1.1 ideas:
- Injury report integration
- Push notifications for predictions
- User favorites and saved predictions
- Historical prediction accuracy tracking
- Fantasy football integration
- Home/away performance analysis
- Weather impact on predictions

## 📞 Support

- App Review Issues: https://developer.apple.com/contact/app-store/
- Technical Support: https://developer.apple.com/support/
- App Store Connect Help: In-app help button

## 🔗 Quick Links

- **Developer Portal**: https://developer.apple.com/account
- **App Store Connect**: https://appstoreconnect.apple.com
- **TestFlight**: https://appstoreconnect.apple.com (TestFlight tab)
- **Review Guidelines**: https://developer.apple.com/app-store/review/guidelines/
- **Human Interface Guidelines**: https://developer.apple.com/design/human-interface-guidelines/
