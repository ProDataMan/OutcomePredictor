# Features Implementation Plan - Session Notes

## 🎯 Goals for Today's Session
1. Game Predictions Enhancement
2. Player Comparison Tool
3. Team Statistics & Standings
4. Live Scores & Real-Time Updates

## Token Budget: ~44K remaining
**Strategy:** Implement highest-impact improvements, document remainder for next session

---

## 1. Game Predictions Enhancement ⭐ PRIORITY

### Current State:
- iOS: GameDetailView.swift shows basic prediction
- Android: GameDetailScreen.kt exists
- Backend: PredictionDTO with confidence, probabilities, reasoning

### Enhancements Needed:
**HIGH IMPACT (Do Now):**
- ✅ Add visual confidence meter/gauge
- ✅ Show key player matchups
- ✅ Add betting line comparison (if available from VegasOddsDTO)
- ✅ Improve reasoning display with better formatting

**MEDIUM IMPACT (If time):**
- Head-to-head team stat comparison
- Historical matchup record

### Files to Modify:
- iOS: `GameDetailView.swift` (prediction card section)
- Android: `StatSharkAndroid/app/src/main/kotlin/com/statshark/nfl/ui/screens/game/GameDetailScreen.kt`

---

## 2. Player Comparison Tool ⭐ PRIORITY

### Current State:
- NOT IMPLEMENTED - New feature

### Implementation Plan:
**Core Functionality:**
- Select 2 players (same position preferred)
- Side-by-side stats comparison
- Visual bars/charts for key stats
- "Who should I start?" recommendation

### Approach:
1. Create comparison screen/view
2. Add "Compare" button to player detail screens
3. Use existing PlayerDTO stats
4. Visual comparison with progress bars

### Files to Create:
- iOS: `PlayerComparisonView.swift`
- Android: `PlayerComparisonScreen.kt`
- May need comparison state management

---

## 3. Team Statistics & Standings ⭐ PRIORITY

### Current State:
- Backend likely has standings endpoint
- NOT displayed in either app

### Implementation Plan:
**Core Display:**
- League standings table (AFC/NFC)
- Division standings
- Team W-L record with win percentage
- Points for/against

**Enhancement:**
- Team rankings (offense/defense)
- Season trends

### Approach:
1. Check if backend `/api/v1/standings` endpoint exists
2. Create StandingsDTO if needed
3. Add Standings tab or screen
4. Table/list view with sortable columns

### Files to Create/Modify:
- iOS: `StandingsView.swift`
- Android: `StandingsScreen.kt`
- Backend: Verify standings endpoint exists

---

## 4. Live Scores & Real-Time Updates

### Current State:
- Games have status field ("in progress", "final")
- No real-time polling/updates

### Implementation Plan:
**Basic (Do if time):**
- Poll for score updates every 30-60 seconds when game is live
- Update game cards with latest scores
- Show quarter/time remaining

**Advanced (Next session):**
- WebSocket/SSE for real-time updates
- Push notifications
- Live game events

### Approach:
1. Add polling timer to game screens
2. Refresh scores when status="in progress"
3. Visual indicator for live games
4. Auto-refresh game lists

### Files to Modify:
- iOS: `GameDetailView.swift`, `PredictionView.swift`
- Android: `GameDetailScreen.kt`, `PredictionsScreen.kt`

---

## Implementation Priority (Given Token Constraints):

### PHASE 1: Visual Enhancements (Highest ROI)
1. **Game Predictions Enhancement** - Improve existing screens ⏱️ ~8K tokens
   - Add confidence meter
   - Better prediction display
   - Key matchup highlights

2. **Player Comparison** - New comparative view ⏱️ ~12K tokens
   - Create comparison screen
   - Side-by-side stats
   - Visual bars

### PHASE 2: Data Features (If Tokens Remain)
3. **Team Standings** - New data display ⏱️ ~10K tokens
   - Standings table
   - Division/conference views

4. **Live Scores** - Polling updates ⏱️ ~8K tokens
   - Add refresh logic
   - Live status indicators

### PHASE 3: Next Session (If needed)
- Advanced live score features
- More detailed standings
- Additional comparison features
- Performance optimizations

---

## Success Criteria:
- ✅ Game predictions look professional with visual confidence indicators
- ✅ Users can compare any 2 players side-by-side
- ✅ Standings table shows current league standings
- ✅ Live games update scores automatically
- ✅ All changes work on both iOS and Android
- ✅ Committed and pushed (auto-deploys to Azure)

---

## Next Steps:
1. Start with Game Predictions Enhancement (both platforms)
2. Add Player Comparison screens
3. Implement Standings if tokens allow
4. Add live score polling if tokens allow
5. Commit and push for auto-deployment

**Status: Ready to implement**
