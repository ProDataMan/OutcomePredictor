# Adding Package Dependency - Visual Guide

## Current Status

✅ All source files copied to project
✅ Deployment target fixed (iOS 16.0)
❌ Missing: OutcomePredictorAPI package dependency

## Step-by-Step Visual Guide

### Step 1: Click Project
```
Project Navigator (left sidebar)
├── 📁 NFLOutcomePredictor (folder)
└── 📘 NFLOutcomePredictor (blue icon) ← CLICK THIS
```

### Step 2: Select Target
```
Top of the editor area shows:
PROJECT                 TARGETS
├── NFLOutcomePredictor ├── NFLOutcomePredictor ← SELECT THIS
                        ├── NFLOutcomePredictorTests
                        └── NFLOutcomePredictorUITests
```

### Step 3: General Tab
```
Tabs at top:
[General] [Signing & Capabilities] [Resource Tags] [Info] [Build Settings] [Build Phases] [Build Rules]
   ↑
CLICK HERE
```

### Step 4: Find Frameworks Section
```
Scroll down in General tab to:

Identity
App Category
Deployment Info
App Icons and Launch Screen
↓
Frameworks, Libraries, and Embedded Content  ← HERE
┌────────────────────────────────────────┐
│ Name                         Status    │
│                                        │
│                                  [+]   │ ← CLICK +
└────────────────────────────────────────┘
```

### Step 5: Add Package Dependency
```
When you click +, a dialog appears with options:
┌──────────────────────────────────────────┐
│ Add Files...                             │
│ Add Other...              [▼]            │ ← CLICK DROPDOWN
│   - Add Package Dependency... ← SELECT   │
│   - Add Files...                         │
└──────────────────────────────────────────┘
```

### Step 6: Add Local Package
```
New dialog opens:
┌──────────────────────────────────────────┐
│ Choose Package Repository                │
│                                          │
│ Search: [                           ]    │
│                                          │
│ [Add Local...]  [Cancel]  [Add Package] │
│      ↑                                   │
│   CLICK THIS                             │
└──────────────────────────────────────────┘
```

### Step 7: Navigate to Package
```
File picker opens:
Navigate to: /Users/baysideuser/GitRepos/OutcomePredictor
                                              ↑
                                         THIS FOLDER

Click [Add Package] button
```

### Step 8: Select Products
```
Dialog shows package products:
┌──────────────────────────────────────────┐
│ Package Product                          │
│ ☑ OutcomePredictorAPI  ← CHECK THIS     │
│                                          │
│ [Cancel]  [Add Package]                 │
│                ↑                         │
│           CLICK THIS                     │
└──────────────────────────────────────────┘
```

### Step 9: Verify
```
Back in Frameworks section, you should see:
┌────────────────────────────────────────┐
│ Name                         Status    │
│ OutcomePredictorAPI         Required  │ ← ADDED!
│                                  [+]   │
└────────────────────────────────────────┘

Also in Project Navigator:
├── 📁 NFLOutcomePredictor
├── 📘 NFLOutcomePredictor
└── 📦 Package Dependencies         ← NEW SECTION
    └── OutcomePredictorAPI         ← ADDED!
```

## Build and Run

Now press **Cmd+B** to build.

Build should succeed!

Then press **Cmd+R** to run the app.

## Troubleshooting

### "Add Package Dependency..." not showing
- Make sure you clicked the dropdown arrow next to "Add Other..."
- Try File > Add Package Dependencies from menu bar instead

### Package not found
- Make sure path is correct: `/Users/baysideuser/GitRepos/OutcomePredictor`
- Not the NFLOutcomePredictor folder - the parent OutcomePredictor folder

### Still getting module error
- Clean build: Product > Clean Build Folder (Cmd+Shift+K)
- Close and reopen Xcode
- Try again

## Success!

Once the package is added, the app will build and you'll see:
- 32 NFL teams with helmet designs
- Team details and games
- AI-powered predictions

All ready to go!
