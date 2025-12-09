#!/usr/bin/env swift

import Foundation

// Read the Week_13.json file
let fileURL = URL(fileURLWithPath: "Week_13.json")
let data = try Data(contentsOf: fileURL)

// Parse as generic JSON to see structure
if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
   let events = json["events"] as? [[String: Any]] {

    print("Found \(events.count) events in JSON")

    for (index, event) in events.enumerated() {
        if let competitions = event["competitions"] as? [[String: Any]],
           let competition = competitions.first,
           let competitors = competition["competitors"] as? [[String: Any]] {

            let homeComp = competitors.first { ($0["homeAway"] as? String) == "home" }
            let awayComp = competitors.first { ($0["homeAway"] as? String) == "away" }

            if let homeTeam = homeComp?["team"] as? [String: Any],
               let awayTeam = awayComp?["team"] as? [String: Any],
               let homeAbbr = homeTeam["abbreviation"] as? String,
               let awayAbbr = awayTeam["abbreviation"] as? String {

                print("\(index + 1). \(awayAbbr) @ \(homeAbbr)")

                // Check normalization
                let normalizedhome = homeAbbr == "WSH" ? "WAS" : (homeAbbr == "LA" ? "LAR" : homeAbbr)
                let normalizedAway = awayAbbr == "WSH" ? "WAS" : (awayAbbr == "LA" ? "LAR" : awayAbbr)

                if normalizedhome != homeAbbr || normalizedAway != awayAbbr {
                    print("   Normalized: \(normalizedAway) @ \(normalizedhome)")
                }
            } else {
                print("\(index + 1). ERROR: Could not extract team info")
            }
        } else {
            print("\(index + 1). ERROR: No competitors found")
        }
    }
} else {
    print("ERROR: Could not parse JSON structure")
}
