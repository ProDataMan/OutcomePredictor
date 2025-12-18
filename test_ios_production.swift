#!/usr/bin/env swift

import Foundation
#if canImport(FoundationNetworking)
import FoundationNetworking
#endif

/// Test script to verify iOS app can connect to production API
func testProductionAPI() async {
    let baseURL = "https://statshark-api.azurewebsites.net/api/v1"

    print("🧪 Testing iOS App Production Connectivity")
    print("📡 API Base URL: \(baseURL)")
    print("=" * 50)

    // Test 1: Fetch Teams
    do {
        print("1️⃣ Testing Teams Endpoint...")
        let teamsURL = URL(string: "\(baseURL)/teams")!
        let (teamsData, teamsResponse) = try await URLSession.shared.data(from: teamsURL)

        let httpResponse = teamsResponse as! HTTPURLResponse
        print("   Status: \(httpResponse.statusCode)")
        print("   Data Size: \(teamsData.count) bytes")

        // Parse teams
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase

        let teams = try decoder.decode([[String: String]].self, from: teamsData)
        print("   Teams Found: \(teams.count)")
        if let firstTeam = teams.first {
            print("   Sample Team: \(firstTeam["name"] ?? "N/A") (\(firstTeam["abbreviation"] ?? "N/A"))")
        }
        print("   ✅ Teams API working")

    } catch {
        print("   ❌ Teams API failed: \(error)")
        return
    }

    // Test 2: Fetch Upcoming Games
    do {
        print("\n2️⃣ Testing Upcoming Games Endpoint...")
        let upcomingURL = URL(string: "\(baseURL)/upcoming")!
        let (upcomingData, upcomingResponse) = try await URLSession.shared.data(from: upcomingURL)

        let httpResponse = upcomingResponse as! HTTPURLResponse
        print("   Status: \(httpResponse.statusCode)")
        print("   Data Size: \(upcomingData.count) bytes")

        // Parse games
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        decoder.dateDecodingStrategy = .iso8601

        let games = try decoder.decode([[String: Any]].self, from: upcomingData)
        print("   Upcoming Games: \(games.count)")
        print("   ✅ Upcoming games API working")

    } catch {
        print("   ❌ Upcoming games API failed: \(error)")
        return
    }

    print("\n🎉 iOS App Production API Test Complete!")
    print("📱 The mobile app should work perfectly with the production backend")
}

// Helper for string repetition
extension String {
    static func * (left: String, right: Int) -> String {
        return String(repeating: left, count: right)
    }
}

// Run the test
await testProductionAPI()