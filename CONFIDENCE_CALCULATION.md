# Confidence Calculation Improvement

## Problem

The original confidence calculation was too simplistic:

```swift
let confidence = min(1.0, Double(totalGames) / 20.0)
```

This resulted in **100% confidence** whenever there were 20+ total games between both teams. In Week 13 of the season:
- Each team has ~13 games played
- Total = 13 + 13 = 26 games
- Confidence = 26/20 = 1.3 → capped at 1.0 (100%)

This doesn't make sense because:
1. **Close matchups** (50/50 predictions) should have lower confidence
2. **Evenly matched teams** create more uncertainty
3. **Sample size alone** doesn't capture prediction difficulty

## New Multi-Factor Confidence Model

The improved calculation uses **three factors** that combine to create a more realistic confidence score:

### Factor 1: Sample Size (0.0 to 0.4)

```swift
let sampleSizeFactor = min(0.4, Double(totalGames) / 50.0)
```

**Purpose**: Ensure sufficient game data exists for both teams

**Scoring**:
- 0 games: 0% contribution
- 25 games: 20% contribution
- 50+ games: 40% contribution (max)

**Rationale**: Need more games (50) to reach max confidence, not just 20

### Factor 2: Data Balance (0.0 to 0.2)

```swift
let minGames = min(homeGamesCount, awayGamesCount)
let maxGames = max(homeGamesCount, awayGamesCount)
let balanceFactor = 0.2 * (Double(minGames) / Double(maxGames))
```

**Purpose**: Prefer balanced sample sizes between teams

**Scoring**:
- Equal games (13 vs 13): 20% contribution
- Imbalanced (5 vs 13): ~8% contribution
- Very imbalanced (2 vs 13): ~3% contribution

**Rationale**: If one team has much more data than the other, we're less confident in the comparison

### Factor 3: Prediction Certainty (0.0 to 0.4)

```swift
let distanceFrom50 = abs(homeWinProbability - 0.5)
let certaintyFactor = min(0.4, distanceFrom50 * 0.8)
```

**Purpose**: Reflect how decisive the prediction is

**Scoring**:
- 50% win probability (toss-up): 0% contribution
- 60% win probability: 8% contribution
- 75% win probability: 20% contribution
- 90%+ win probability: 32%+ contribution (up to 40% max)

**Rationale**: When teams are evenly matched (near 50/50), we should be less confident, even with good sample sizes

## Combined Confidence Score

```swift
confidence = sampleSizeFactor + balanceFactor + certaintyFactor
```

**Maximum possible**: 0.4 + 0.2 + 0.4 = **1.0 (100%)**

**Typical ranges**:
- **Blowout prediction** (90% win prob, 26 games, balanced): ~82% confidence
- **Strong favorite** (75% win prob, 26 games, balanced): ~60% confidence
- **Close game** (55% win prob, 26 games, balanced): ~28% confidence
- **Toss-up** (50% win prob, 26 games, balanced): ~24% confidence
- **Early season** (60% win prob, 8 games, balanced): ~16% confidence

## Examples

### Example 1: Close Matchup (SF vs BUF)
- SF win rate: 52%, BUF win rate: 48%
- Home win probability: 57% (close game)
- Total games: 26 (13 each)

**Calculation**:
- Sample size: 26/50 = 52% → 0.26 (capped at 0.4)
- Balance: 13/13 = 100% → 0.20
- Certainty: |0.57 - 0.5| × 0.8 = 0.07 × 0.8 = 0.056

**Final confidence**: 0.26 + 0.20 + 0.056 = **52%**

### Example 2: Strong Favorite (KC vs CLE)
- KC win rate: 85%, CLE win rate: 25%
- Home win probability: 88% (decisive)
- Total games: 26 (13 each)

**Calculation**:
- Sample size: 26/50 = 0.26
- Balance: 13/13 = 0.20
- Certainty: |0.88 - 0.5| × 0.8 = 0.38 × 0.8 = 0.304

**Final confidence**: 0.26 + 0.20 + 0.304 = **76%**

### Example 3: Early Season
- Win probability: 60%
- Total games: 8 (4 each)

**Calculation**:
- Sample size: 8/50 = 0.064
- Balance: 4/4 = 0.20
- Certainty: |0.60 - 0.5| × 0.8 = 0.08

**Final confidence**: 0.064 + 0.20 + 0.08 = **34%**

## Benefits

1. **More realistic**: No more automatic 100% confidence
2. **Reflects uncertainty**: Close games show appropriately lower confidence
3. **Considers context**: Multiple factors create nuanced confidence scores
4. **Interpretable**: Each factor has clear meaning
5. **Capped properly**: Still can't exceed 100%

## Impact on UI

Users will now see varied confidence scores:
- **High confidence (70-90%)**: Clear favorite with good data
- **Medium confidence (40-70%)**: Solid prediction but some uncertainty
- **Low confidence (20-40%)**: Toss-up or limited data
- **Very low confidence (<20%)**: Early season or extremely close matchup

This gives users better insight into how reliable each prediction is.
