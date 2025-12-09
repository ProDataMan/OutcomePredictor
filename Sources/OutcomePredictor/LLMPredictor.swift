import Foundation
#if canImport(FoundationNetworking)
import FoundationNetworking
#endif

/// LLM-based predictor using foundation models for game outcome prediction.
public struct LLMPredictor: GamePredictor {
    private let llmClient: LLMClient
    private let promptBuilder: PromptBuilder

    /// Creates an LLM-based predictor.
    ///
    /// - Parameters:
    ///   - llmClient: Client for LLM API calls.
    ///   - promptBuilder: Builds prompts from game context.
    public init(llmClient: LLMClient, promptBuilder: PromptBuilder = DefaultPromptBuilder()) {
        self.llmClient = llmClient
        self.promptBuilder = promptBuilder
    }

    public func predict(game: Game, features: [String: Double]) async throws -> Prediction {
        // Build context - in real use, this would come from DataAggregator
        let context = PredictionContext(
            game: game,
            homeTeamGames: [],
            awayTeamGames: [],
            homeTeamArticles: [],
            awayTeamArticles: []
        )

        return try await predict(context: context)
    }

    /// Makes a prediction using full context from multiple data sources.
    ///
    /// - Parameter context: Complete prediction context with historical and text data.
    /// - Returns: Prediction with LLM-generated reasoning.
    /// - Throws: `PredictionError` if prediction fails.
    public func predict(context: PredictionContext) async throws -> Prediction {
        // Build prompt from context
        let prompt = promptBuilder.buildPrompt(from: context)

        // Call LLM
        let response = try await llmClient.generatePrediction(prompt: prompt)

        // Parse response
        return try parseLLMResponse(response, for: context.game)
    }

    private func parseLLMResponse(_ response: LLMResponse, for game: Game) throws -> Prediction {
        // Extract probability from response
        let probability = response.homeWinProbability

        return try Prediction(
            game: game,
            homeWinProbability: probability,
            confidence: response.confidence,
            reasoning: response.reasoning
        )
    }
}

/// Client for interacting with LLM APIs.
public protocol LLMClient: Sendable {
    /// Generates a game prediction from a prompt.
    ///
    /// - Parameter prompt: Prompt describing the game and context.
    /// - Returns: LLM response with prediction.
    /// - Throws: Network or API errors.
    func generatePrediction(prompt: String) async throws -> LLMResponse
}

/// Response from LLM containing prediction.
public struct LLMResponse: Codable, Sendable {
    /// Home team win probability (0.0-1.0).
    public let homeWinProbability: Double

    /// Confidence in prediction (0.0-1.0).
    public let confidence: Double

    /// Reasoning for the prediction.
    public let reasoning: String

    /// Key factors identified by LLM.
    public let keyFactors: [String]

    /// Creates an LLM response.
    public init(homeWinProbability: Double, confidence: Double, reasoning: String, keyFactors: [String] = []) {
        self.homeWinProbability = homeWinProbability
        self.confidence = confidence
        self.reasoning = reasoning
        self.keyFactors = keyFactors
    }
}

/// Builds prompts for LLM from game context.
public protocol PromptBuilder: Sendable {
    /// Builds a prompt from prediction context.
    ///
    /// - Parameter context: Complete game context.
    /// - Returns: Formatted prompt for LLM.
    func buildPrompt(from context: PredictionContext) -> String
}

/// Default prompt builder for NFL predictions.
public struct DefaultPromptBuilder: PromptBuilder {
    /// Creates a default prompt builder.
    public init() {}

    public func buildPrompt(from context: PredictionContext) -> String {
        var prompt = """
        You are an expert NFL analyst. Analyze this upcoming game and provide a prediction.

        GAME DETAILS:
        Home Team: \(context.game.homeTeam.name) (\(context.game.homeTeam.abbreviation))
        Away Team: \(context.game.awayTeam.name) (\(context.game.awayTeam.abbreviation))
        Date: \(formatDate(context.game.scheduledDate))
        Week: \(context.game.week), Season: \(context.game.season)

        """

        // Add historical performance
        if !context.homeTeamGames.isEmpty {
            let homeRecord = calculateRecord(for: context.game.homeTeam, in: context.homeTeamGames)
            prompt += """

            HOME TEAM RECORD: \(homeRecord.wins)-\(homeRecord.losses)\(homeRecord.ties > 0 ? "-\(homeRecord.ties)" : "")
            Recent games:
            \(formatRecentGames(for: context.game.homeTeam, games: context.homeTeamGames))

            """
        }

        if !context.awayTeamGames.isEmpty {
            let awayRecord = calculateRecord(for: context.game.awayTeam, in: context.awayTeamGames)
            prompt += """

            AWAY TEAM RECORD: \(awayRecord.wins)-\(awayRecord.losses)\(awayRecord.ties > 0 ? "-\(awayRecord.ties)" : "")
            Recent games:
            \(formatRecentGames(for: context.game.awayTeam, games: context.awayTeamGames))

            """
        }

        // Add news and social media context
        if !context.homeTeamArticles.isEmpty {
            prompt += """

            HOME TEAM NEWS & SOCIAL MEDIA:
            \(formatArticles(context.homeTeamArticles.prefix(5)))

            """
        }

        if !context.awayTeamArticles.isEmpty {
            prompt += """

            AWAY TEAM NEWS & SOCIAL MEDIA:
            \(formatArticles(context.awayTeamArticles.prefix(5)))

            """
        }

        prompt += """

        ANALYSIS REQUIRED:
        1. Analyze team performance trends
        2. Consider injury reports and roster changes from news
        3. Evaluate momentum and narrative factors from social media
        4. Account for home field advantage
        5. Consider division rivalry dynamics if applicable

        Provide your response in this JSON format:
        {
            "homeWinProbability": <number between 0.0 and 1.0>,
            "confidence": <number between 0.0 and 1.0>,
            "reasoning": "<detailed explanation>",
            "keyFactors": ["factor1", "factor2", "factor3"]
        }
        """

        return prompt
    }

    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }

    private func calculateRecord(for team: Team, in games: [Game]) -> (wins: Int, losses: Int, ties: Int) {
        var wins = 0
        var losses = 0
        var ties = 0

        for game in games where game.outcome != nil {
            let isHome = game.homeTeam.id == team.id
            switch game.outcome!.winner {
            case .home where isHome, .away where !isHome:
                wins += 1
            case .home where !isHome, .away where isHome:
                losses += 1
            case .tie:
                ties += 1
            default:
                break
            }
        }

        return (wins, losses, ties)
    }

    private func formatRecentGames(for team: Team, games: [Game]) -> String {
        let recentGames = games
            .filter { $0.outcome != nil }
            .sorted { $0.scheduledDate > $1.scheduledDate }
            .prefix(3)

        return recentGames.map { game in
            let isHome = game.homeTeam.id == team.id
            let opponent = isHome ? game.awayTeam : game.homeTeam
            let location = isHome ? "vs" : "@"
            let outcome = game.outcome!
            let teamScore = isHome ? outcome.homeScore : outcome.awayScore
            let oppScore = isHome ? outcome.awayScore : outcome.homeScore
            let result = teamScore > oppScore ? "W" : (teamScore < oppScore ? "L" : "T")

            return "  \(result) \(location) \(opponent.abbreviation) \(teamScore)-\(oppScore)"
        }.joined(separator: "\n")
    }

    private func formatArticles(_ articles: any Sequence<Article>) -> String {
        return articles.map { article in
            let source = article.source.uppercased()
            return "  [\(source)] \(article.title)"
        }.joined(separator: "\n")
    }
}

/// Claude API client implementation.
public struct ClaudeAPIClient: LLMClient {
    private let apiKey: String
    private let model: String
    private let baseURL: String

    /// Creates a Claude API client.
    ///
    /// - Parameters:
    ///   - apiKey: Anthropic API key.
    ///   - model: Model to use (default: claude-sonnet-4-5-20250929).
    ///   - baseURL: API base URL.
    public init(
        apiKey: String,
        model: String = "claude-sonnet-4-5-20250929",
        baseURL: String = "https://api.anthropic.com/v1/messages"
    ) {
        self.apiKey = apiKey
        self.model = model
        self.baseURL = baseURL
    }

    public func generatePrediction(prompt: String) async throws -> LLMResponse {
        guard let url = URL(string: baseURL) else {
            throw URLError(.badURL)
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(apiKey, forHTTPHeaderField: "x-api-key")
        request.setValue("2023-06-01", forHTTPHeaderField: "anthropic-version")

        let body: [String: Any] = [
            "model": model,
            "max_tokens": 2048,
            "messages": [
                ["role": "user", "content": prompt]
            ]
        ]

        request.httpBody = try JSONSerialization.data(withJSONObject: body)

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw URLError(.badServerResponse)
        }

        guard httpResponse.statusCode == 200 else {
            throw URLError(.badServerResponse)
        }

        // Parse Claude response
        let claudeResponse = try JSONDecoder().decode(ClaudeResponse.self, from: data)

        // Extract JSON from response text
        guard let content = claudeResponse.content.first?.text else {
            throw PredictionError.insufficientData
        }

        // Parse the JSON response from the model
        return try parsePredictionJSON(content)
    }

    private func parsePredictionJSON(_ text: String) throws -> LLMResponse {
        // Extract JSON from markdown code block if present
        var jsonString = text
        if let jsonStart = text.range(of: "```json"),
           let jsonEnd = text.range(of: "```", range: jsonStart.upperBound..<text.endIndex) {
            jsonString = String(text[jsonStart.upperBound..<jsonEnd.lowerBound]).trimmingCharacters(in: .whitespacesAndNewlines)
        } else if let jsonStart = text.range(of: "{"),
                  let jsonEnd = text.range(of: "}", options: .backwards) {
            jsonString = String(text[jsonStart.lowerBound...jsonEnd.upperBound])
        }

        let data = jsonString.data(using: .utf8) ?? Data()
        return try JSONDecoder().decode(LLMResponse.self, from: data)
    }
}

/// Claude API response structure.
private struct ClaudeResponse: Codable {
    let content: [Content]

    struct Content: Codable {
        let text: String
    }
}
