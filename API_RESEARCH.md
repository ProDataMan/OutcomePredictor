# Sports Data API Comparison & Pricing

## Executive Summary

**Current Status**:
- ✅ Player images: REAL (ESPN CDN)
- ⚠️ Player stats: MOCK (randomly generated)
- ✅ Game scores: REAL (ESPN API)

**Why Stats Are Mock**: ESPN's free public API does NOT provide player statistics. You need a paid stats API.

**ESPN Premium API**: Does NOT exist as a public offering. ESPN only provides custom partnerships to major companies (FanDuel, DraftKings, etc.).

---

## API-Sports (Currently Configured But Not Working)

- **Website**: https://api-sports.io
- **Status**: ❌ Not working from Azure (falling back to ESPN)
- **Your API Key**: `aa2dc9d028789dfba7784af56a8735d6` (already in Azure config)
- **Code**: Already fully implemented in `APISportsDataSource.swift`

### Pricing
- **FREE**: 100 requests/day
- **BASIC**: $15/month - 3,000 requests/day
- **PRO**: $50/month - 10,000 requests/day
- **ULTRA**: $150/month - 30,000 requests/day

### Features
- Real NFL player statistics (2022+)
- Player headshots included
- Team stats, game stats
- Historical data

### Why It's Not Working
Tested with 2022 season data (where API-Sports should have real stats), but still getting mock data. This means:
1. Azure may have outbound firewall rules
2. API-Sports may block Azure's IP ranges (anti-bot)
3. May need to whitelist Azure's outbound IPs with API-Sports
4. Could be API configuration issue

### To Fix API-Sports
- Check Azure logs for API-Sports connection errors
- Contact API-Sports support to whitelist Azure IPs
- Verify API key is valid and active
- Check Azure App Service outbound IP addresses

---

## ESPN API (Currently Working)

- **Website**: https://www.espn.com
- **Status**: ✅ Working (limited data)
- **Cost**: FREE

### What ESPN Free API Provides
- ✅ Team rosters (names, positions, jersey numbers)
- ✅ Player headshots (via CDN)
- ✅ Game scores and schedules
- ✅ Team information
- ❌ Player statistics (NOT available)

### ESPN Premium/Partner API
**Does NOT exist** as a public offering. ESPN does not sell a premium API to developers. Major partners get custom data deals through ESPN's business development team.

---

## Alternative Stats Providers

### Option 1: SportsData.io (Recommended)
- **Website**: https://sportsdata.io
- **Quality**: Excellent (used by many fantasy apps)
- **Ease of Use**: Self-service API, good documentation

#### Pricing
- **Trial**: $0 - 1,000 API calls (for testing)
- **Starter**: $29/month - 10,000 calls/day
- **Pro**: $149/month - 100,000 calls/day
- **Enterprise**: Custom pricing

#### Data Included
- Complete NFL player statistics
- Real-time game data
- Player projections
- Injury reports
- Play-by-play data

#### Implementation Effort
- Would need to create new `SportsDataIODataSource.swift`
- Similar structure to existing `APISportsDataSource.swift`
- Estimated: 4-6 hours to implement and test

---

### Option 2: Sportradar (Enterprise)
- **Website**: https://sportradar.com
- **Quality**: Highest (official NFL data partner)
- **Pricing**: Custom enterprise pricing (likely $500+/month minimum)

#### Features
- Official NFL data
- Real-time stats
- Fastest updates
- Most comprehensive

#### Drawbacks
- Expensive
- Requires sales contact
- Not self-service
- Overkill for most apps

---

### Option 3: RapidAPI Sports Providers
- **Website**: https://rapidapi.com/category/Sports
- **Pricing**: $5-50/month (varies by provider)
- **Quality**: Mixed (depends on specific provider)

#### Providers Available
- Tank01 NFL API
- API-Football (American Football)
- NFL API by API-SPORTS (same as api-sports.io)

#### Notes
- Multiple options to choose from
- Easy to test different providers
- Quality varies significantly

---

### Option 4: The Odds API (Already Using)
- **Website**: https://the-odds-api.com
- **Status**: ✅ Already working in your app for betting odds
- **Data**: Betting odds only (NO player stats)

---

## Cost Comparison

| Provider | Monthly Cost | Requests/Day | Player Stats | Real-Time | Best For |
|----------|-------------|--------------|--------------|-----------|----------|
| ESPN Free | $0 | Unlimited* | ❌ | Partial | Rosters, scores, images |
| API-Sports FREE | $0 | 100 | ✅ | Yes | Testing only |
| API-Sports BASIC | $15 | 3,000 | ✅ | Yes | Small apps |
| SportsData.io Trial | $0 | 1,000 total | ✅ | Yes | Testing |
| SportsData.io Starter | $29 | 10,000 | ✅ | Yes | Production apps |
| API-Sports PRO | $50 | 10,000 | ✅ | Yes | Growing apps |
| SportsData.io Pro | $149 | 100,000 | ✅ | Yes | High traffic |
| Sportradar | $500+ | Custom | ✅ | Yes | Enterprise |

*Subject to rate limiting

---

## Recommendation

### Best Path Forward

**Option A: Fix API-Sports (Best ROI)**
- ✅ Already implemented in code
- ✅ API key already configured
- ✅ Most cost-effective ($15/month)
- ❌ Currently not working from Azure
- **Action**: Debug Azure → API-Sports connectivity

**Option B: SportsData.io Trial (Quickest Win)**
- ✅ Free trial with 1,000 calls
- ✅ Good documentation
- ✅ Self-service signup
- ❌ Requires new code implementation (~4-6 hours)
- **Action**: Sign up, implement data source, test

**Option C: Keep Mock Data (Zero Cost)**
- ✅ Free
- ✅ Works for demos
- ❌ Stats are random/unrealistic
- ❌ Not suitable for production
- **Action**: Nothing (current state)

---

## Why API-Sports Might Be Failing

Based on testing, even 2022 data (where API-Sports should work) returns mock stats. Possible causes:

### 1. Azure Firewall
Azure App Service may block outbound HTTPS to api-sports.io domain.

**Check**: Azure Portal → App Service → Networking → Outbound Rules

### 2. IP Blocking
API-Sports may block Azure's IP ranges as bot traffic.

**Solution**: Contact API-Sports support with your Azure outbound IPs

**Get Azure IPs**:
```bash
az webapp show --name statshark-api --resource-group ProDataMan \
  --query outboundIpAddresses -o tsv
```

### 3. API Key Configuration
The API key might not be active or has wrong permissions.

**Check**: Test API key directly from another server:
```bash
curl "https://v1.american-football.api-sports.io/players?team=1&season=2024" \
  -H "x-apisports-key: aa2dc9d028789dfba7784af56a8735d6"
```

### 4. Code Issue
The fallback to ESPN might be triggering incorrectly.

**Check**: Azure application logs for "API-Sports failed" messages

---

## Next Steps

1. **Test API Key** from a different network to verify it works
2. **Check Azure logs** for API-Sports connection errors
3. **Get Azure outbound IPs** and whitelist with API-Sports
4. **If blocked**, try SportsData.io trial as alternative
5. **Long term**: Choose between fixing API-Sports ($15/mo) or SportsData.io ($29/mo)

---

## Summary

| Question | Answer |
|----------|--------|
| Can I get ESPN premium API? | No - not publicly available |
| What's the cheapest real stats? | API-Sports BASIC at $15/month |
| What's the best quality stats? | Sportradar (expensive) or SportsData.io (reasonable) |
| Why aren't stats working now? | ESPN free API doesn't provide stats |
| Is API-Sports working? | No - Azure can't reach it or it's blocking Azure |
| Are images real? | Yes - ESPN CDN working fine |
| Are game scores real? | Yes - ESPN API working fine |

