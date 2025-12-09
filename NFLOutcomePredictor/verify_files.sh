#!/bin/bash

echo "🏈 NFL Outcome Predictor - File Check"
echo "======================================"
echo ""

APP_DIR="/Users/baysideuser/GitRepos/OutcomePredictor/NFLOutcomePredictor/NFLOutcomePredictor"

echo "Checking files in: $APP_DIR"
echo ""

FILES=(
    "NFLOutcomePredictorApp.swift"
    "ContentView.swift"
    "APIClient.swift"
    "TeamBranding.swift"
    "TeamDetailView.swift"
    "PredictionView.swift"
    "DTOExtensions.swift"
)

for file in "${FILES[@]}"; do
    if [ -f "$APP_DIR/$file" ]; then
        SIZE=$(ls -lh "$APP_DIR/$file" | awk '{print $5}')
        echo "✅ $file ($SIZE)"
    else
        echo "❌ $file (missing)"
    fi
done

if [ -d "$APP_DIR/Assets.xcassets" ]; then
    echo "✅ Assets.xcassets"
else
    echo "❌ Assets.xcassets (missing)"
fi

echo ""
echo "======================================"
echo "Next: Open Xcode and add files to project"
echo "See SETUP.md for detailed instructions"
echo ""
