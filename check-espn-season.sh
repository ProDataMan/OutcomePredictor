#!/bin/bash

echo "Checking ESPN API for current season..."
echo ""

# Check current scoreboard (no season specified)
echo "1. Current scoreboard (default):"
curl -s "https://site.api.espn.com/apis/site/v2/sports/football/nfl/scoreboard" | grep -o '"year":[0-9]*' | head -1

echo ""
echo "2. Week 13, 2024:"
curl -s "https://site.api.espn.com/apis/site/v2/sports/football/nfl/scoreboard?seasontype=2&week=13&dates=2024" | grep -o '"year":[0-9]*' | head -1

echo ""
echo "3. Week 13, 2025:"
curl -s "https://site.api.espn.com/apis/site/v2/sports/football/nfl/scoreboard?seasontype=2&week=13&dates=2025" | grep -o '"year":[0-9]*' | head -1

echo ""
echo "4. Checking event count for each:"
echo "   2024 Week 13: $(curl -s "https://site.api.espn.com/apis/site/v2/sports/football/nfl/scoreboard?seasontype=2&week=13&dates=2024" | grep -o '"id":"[0-9]*"' | wc -l) events"
echo "   2025 Week 13: $(curl -s "https://site.api.espn.com/apis/site/v2/sports/football/nfl/scoreboard?seasontype=2&week=13&dates=2025" | grep -o '"id":"[0-9]*"' | wc -l) events"
