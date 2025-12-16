import Foundation
import OutcomePredictor

/// Debug tool to inspect ESPN API responses
@main
struct DebugESPN {
    static func main() async {
        print("=== ESPN API Response Inspector ===\n")

        do {
            // Test 1: Current scoreboard
            print("📡 Fetching current scoreboard...\n")
            let scoreboardURL = "https://site.api.espn.com/apis/site/v2/sports/football/nfl/scoreboard"
            try await inspectURL(scoreboardURL, name: "Current Scoreboard")

            print("\n" + String(repeating: "=", count: 60) + "\n")

            // Test 2: Specific week
            print("📡 Fetching Week 13, 2024...\n")
            let weekURL = "https://site.api.espn.com/apis/site/v2/sports/football/nfl/scoreboard?seasontype=2&week=13&dates=2024"
            try await inspectURL(weekURL, name: "Week 13")

            print("\n" + String(repeating: "=", count: 60) + "\n")

            // Test 3: Team schedule endpoint (Chiefs)
            print("📡 Fetching Kansas City Chiefs 2024 schedule...\n")
            let chiefsURL = "https://site.api.espn.com/apis/site/v2/sports/football/nfl/teams/kc/schedule?season=2024"
            try await inspectURL(chiefsURL, name: "Chiefs_Schedule_2024")

            print("\n" + String(repeating: "=", count: 60) + "\n")

            // Test 4: Current scoreboard (no season specified)
            print("📡 Fetching current scoreboard (default season)...\n")
            let currentURL = "https://site.api.espn.com/apis/site/v2/sports/football/nfl/scoreboard"
            try await inspectURL(currentURL, name: "Current_Scoreboard")

        } catch {
            print("❌ Error: \(error)")
        }
    }

    static func inspectURL(_ urlString: String, name: String) async throws {
        print("URL: \(urlString)")

        // Use HTTPClient from OutcomePredictor module which works on Linux
        let httpClient = HTTPClient()

        let (data, statusCode) = try await httpClient.get(url: urlString)

        print("Status: \(statusCode)")
        print("Size: \(data.count) bytes")
        print("")

        // Try to parse as JSON
        if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] {
            print("JSON Structure:")
            printJSON(json, indent: 0, maxDepth: 3)
        } else {
            print("Not valid JSON")
            // Show raw response
            if let text = String(data: data, encoding: .utf8) {
                print("Raw response (first 500 chars):")
                print(String(text.prefix(500)))
            }
        }

        // Save to file for inspection
        let filename = "\(name.replacingOccurrences(of: " ", with: "_")).json"
        let fileURL = URL(fileURLWithPath: filename)
        try data.write(to: fileURL)
        print("\n💾 Saved response to: \(fileURL.path)")
    }

    static func printJSON(_ json: Any, indent: Int, maxDepth: Int) {
        let indentStr = String(repeating: "  ", count: indent)

        if indent > maxDepth {
            print("\(indentStr)...")
            return
        }

        switch json {
        case let dict as [String: Any]:
            for (key, value) in dict.prefix(10) {
                if let nestedDict = value as? [String: Any] {
                    print("\(indentStr)\(key): {")
                    printJSON(nestedDict, indent: indent + 1, maxDepth: maxDepth)
                    print("\(indentStr)}")
                } else if let array = value as? [Any] {
                    print("\(indentStr)\(key): [\(array.count) items]")
                    if let first = array.first, indent < maxDepth {
                        print("\(indentStr)  First item:")
                        printJSON(first, indent: indent + 2, maxDepth: maxDepth)
                    }
                } else {
                    let valueStr = String(describing: value)
                    let truncated = valueStr.count > 100 ? String(valueStr.prefix(100)) + "..." : valueStr
                    print("\(indentStr)\(key): \(truncated)")
                }
            }
            if dict.count > 10 {
                print("\(indentStr)... and \(dict.count - 10) more keys")
            }

        case let array as [Any]:
            print("\(indentStr)[\(array.count) items]")
            if let first = array.first {
                print("\(indentStr)First item:")
                printJSON(first, indent: indent + 1, maxDepth: maxDepth)
            }

        default:
            let valueStr = String(describing: json)
            let truncated = valueStr.count > 100 ? String(valueStr.prefix(100)) + "..." : valueStr
            print("\(indentStr)\(truncated)")
        }
    }
}
