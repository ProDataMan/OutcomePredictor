#!/bin/bash

# Production Testing Suite for StatShark API
# Usage: ./test_production.sh

BASE_URL="https://statshark-api.azurewebsites.net/api/v1"

echo "🚀 Testing StatShark Production API at $BASE_URL"
echo "================================================"

# Test 1: Health Check
echo "1️⃣ Health Check - Teams Endpoint"
curl -s -w "Status: %{http_code}\nTime: %{time_total}s\n" -o /tmp/teams_response.json "$BASE_URL/teams"
if [ $? -eq 0 ]; then
    echo "✅ Teams endpoint accessible"
    # Show first team
    echo "Sample response:"
    head -3 /tmp/teams_response.json
else
    echo "❌ Teams endpoint failed"
fi
echo ""

# Test 2: Specific Team Details
echo "2️⃣ Team Details - Kansas City Chiefs"
curl -s -w "Status: %{http_code}\nTime: %{time_total}s\n" -o /tmp/team_kc.json "$BASE_URL/teams/KC"
if [ $? -eq 0 ]; then
    echo "✅ Team details accessible"
else
    echo "❌ Team details failed"
fi
echo ""

# Test 3: Upcoming Games
echo "3️⃣ Upcoming Games"
curl -s -w "Status: %{http_code}\nTime: %{time_total}s\n" -o /tmp/upcoming.json "$BASE_URL/upcoming"
if [ $? -eq 0 ]; then
    echo "✅ Upcoming games accessible"
    echo "Sample games:"
    head -5 /tmp/upcoming.json
else
    echo "❌ Upcoming games failed"
fi
echo ""

# Test 4: Predictions
echo "4️⃣ Prediction Endpoint"
curl -s -w "Status: %{http_code}\nTime: %{time_total}s\n" -o /tmp/prediction.json "$BASE_URL/predict" \
    -H "Content-Type: application/json" \
    -d '{"homeTeam":"KC","awayTeam":"BUF","season":2024,"week":15}'
if [ $? -eq 0 ]; then
    echo "✅ Prediction endpoint accessible"
else
    echo "❌ Prediction endpoint failed"
fi
echo ""

# Test 5: Performance Test
echo "5️⃣ Performance Test (5 concurrent requests)"
for i in {1..5}; do
    curl -s -w "Request $i: %{time_total}s\n" -o /dev/null "$BASE_URL/teams" &
done
wait
echo ""

# Test 6: Mobile App Simulation
echo "6️⃣ Mobile App User Journey Simulation"
echo "Simulating typical iOS app usage..."

# Step 1: Load teams list
curl -s -w "Load Teams: %{http_code} (%{time_total}s)\n" -o /tmp/mobile_teams.json "$BASE_URL/teams"

# Step 2: Get team details
curl -s -w "Team Details: %{http_code} (%{time_total}s)\n" -o /tmp/mobile_team.json "$BASE_URL/teams/SF"

# Step 3: Load upcoming games
curl -s -w "Upcoming Games: %{http_code} (%{time_total}s)\n" -o /tmp/mobile_upcoming.json "$BASE_URL/upcoming"

# Step 4: Make prediction
curl -s -w "Make Prediction: %{http_code} (%{time_total}s)\n" -o /tmp/mobile_prediction.json "$BASE_URL/predict" \
    -H "Content-Type: application/json" \
    -d '{"homeTeam":"SF","awayTeam":"LA","season":2024,"week":15}'

echo ""
echo "📱 Production API Test Complete!"
echo "Check /tmp/ files for detailed responses if needed"

# Cleanup flag
if [ "$1" == "--cleanup" ]; then
    rm -f /tmp/teams_response.json /tmp/team_kc.json /tmp/upcoming.json /tmp/prediction.json /tmp/mobile_*.json
    echo "🧹 Cleaned up temp files"
fi