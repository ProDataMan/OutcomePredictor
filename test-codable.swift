#!/usr/bin/env swift

import Foundation

// Copy the exact structs from ESPNDataSource.swift
private struct ESPNScoreboard: Codable {
    let events: [ESPNEvent]
}

private struct ESPNEvent: Codable {
    let date: String
    let competitions: [ESPNCompetition]
}

private struct ESPNCompetition: Codable {
    let competitors: [ESPNCompetitor]
    let status: ESPNStatus
}

private struct ESPNCompetitor: Codable {
    let homeAway: String
    let score: String
    let team: ESPNTeam
}

private struct ESPNTeam: Codable {
    let abbreviation: String
    let displayName: String
}

private struct ESPNStatus: Codable {
    let type: ESPNStatusType
}

private struct ESPNStatusType: Codable {
    let completed: Bool
}

// Read and decode the file
let fileURL = URL(fileURLWithPath: "Week_13.json")
let data = try Data(contentsOf: fileURL)

do {
    let scoreboard = try JSONDecoder().decode(ESPNScoreboard.self, from: data)
    print("✅ Successfully decoded with JSONDecoder")
    print("   Found \(scoreboard.events.count) events")

    var gameCount = 0
    for event in scoreboard.events {
        guard let competition = event.competitions.first else {
            print("   ⚠️  Event has no competitions")
            continue
        }

        let homeComp = competition.competitors.first { $0.homeAway == "home" }
        let awayComp = competition.competitors.first { $0.homeAway == "away" }

        if let home = homeComp, let away = awayComp {
            gameCount += 1
            print("   \(gameCount). \(away.team.abbreviation) @ \(home.team.abbreviation)")
        } else {
            print("   ⚠️  Could not find home/away")
        }
    }

    print("\nTotal games found: \(gameCount)")

} catch {
    print("❌ JSONDecoder failed: \(error)")
    if let decodingError = error as? DecodingError {
        switch decodingError {
        case .keyNotFound(let key, let context):
            print("   Missing key: \(key.stringValue)")
            print("   Context: \(context.debugDescription)")
        case .typeMismatch(let type, let context):
            print("   Type mismatch: \(type)")
            print("   Context: \(context.debugDescription)")
        case .valueNotFound(let type, let context):
            print("   Value not found: \(type)")
            print("   Context: \(context.debugDescription)")
        case .dataCorrupted(let context):
            print("   Data corrupted: \(context.debugDescription)")
        @unknown default:
            print("   Unknown decoding error")
        }
    }
}
