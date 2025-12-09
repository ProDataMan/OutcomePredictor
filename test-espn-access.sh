#!/bin/bash

# Simple script to test ESPN API access
# Run this directly in your terminal outside Claude Code

echo "Testing ESPN API Access..."
echo ""

# Test 1: Can we reach ESPN?
echo "1. Testing network connectivity to ESPN..."
if ping -c 1 site.api.espn.com > /dev/null 2>&1; then
    echo "   ✓ ESPN domain is reachable"
else
    echo "   ✗ Cannot reach ESPN domain"
fi

echo ""

# Test 2: Try to fetch data with curl
echo "2. Testing ESPN API with curl..."
response=$(curl -s -w "\n%{http_code}" "https://site.api.espn.com/apis/site/v2/sports/football/nfl/scoreboard" 2>&1)
http_code=$(echo "$response" | tail -n1)

if [ "$http_code" = "200" ]; then
    echo "   ✓ ESPN API returned 200 OK"
    echo "   Sample response:"
    echo "$response" | head -n -1 | head -c 200
    echo "..."
else
    echo "   ✗ ESPN API returned code: $http_code"
fi

echo ""
echo ""

# Test 3: Run our Swift program
echo "3. Running Swift data fetcher..."
echo ""
cd "$(dirname "$0")"
swift run fetch-data
