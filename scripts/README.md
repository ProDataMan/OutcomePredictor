Import team images into the iOS app asset catalog

Prereqs
- macOS with zsh
- ImageMagick (brew install imagemagick)
- Optional: rembg for better background removal (pip install rembg)

Usage

1. Run the import script with the source folder (your backend Teams dir) and the app Assets folder:

```bash
./scripts/import_team_images.sh \
  /Users/baysideuser/GitRepos/swift-vending-platform/backend/Sources/Teams \
  /Users/baysideuser/GitRepos/OutcomePredictor/NFLOutcomePredictor/NFLOutcomePredictor/Assets.xcassets
```

2. Open Xcode, refresh the asset catalog, and build. Assets are created with names like `team_KC` (imageset: `team_KC.imageset`).

Notes
- The script attempts to detect a 2-3 letter uppercase abbreviation from the folder name (e.g., `Chiefs_KC`). If it cannot, it falls back to a lowercase folder name.
- If `rembg` is available, it will be used to remove complex backgrounds; otherwise the script performs a simple white->transparent pass using ImageMagick.
- After import, the app will show the team icon in `TeamIconView` (used in team cards) and fall back to the existing helmet rendering when no asset is found.

If you'd like, I can add a small mapping file or interactive mode if your folder naming doesn't include abbreviations.
