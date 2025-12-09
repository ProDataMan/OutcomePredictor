import Foundation
#if canImport(FoundationNetworking)
import FoundationNetworking
#endif

/// News API client for fetching articles about NFL teams.
///
/// Uses NewsAPI.org for article aggregation. Free tier: 100 requests/day.
/// Get API key at: https://newsapi.org/
public struct NewsAPIDataSource: NewsDataSource {
    private let apiKey: String
    private let baseURL: String
    private let session: URLSession

    /// Creates a News API data source.
    ///
    /// - Parameters:
    ///   - apiKey: NewsAPI.org API key.
    ///   - baseURL: News API base URL.
    ///   - session: URL session for requests.
    public init(
        apiKey: String,
        baseURL: String = "https://newsapi.org/v2",
        session: URLSession = .shared
    ) {
        self.apiKey = apiKey
        self.baseURL = baseURL
        self.session = session
    }

    public func fetchArticles(for team: Team, before date: Date) async throws -> [Article] {
        let query = "\(team.name) OR \(team.abbreviation) NFL"
        let dateFormatter = ISO8601DateFormatter()
        let toDate = dateFormatter.string(from: date)

        // Calculate from date (7 days before)
        let fromDate = Calendar.current.date(byAdding: .day, value: -7, to: date) ?? date
        let fromDateString = dateFormatter.string(from: fromDate)

        let urlString = "\(baseURL)/everything?q=\(query.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? query)&from=\(fromDateString)&to=\(toDate)&language=en&sortBy=publishedAt&apiKey=\(apiKey)"

        guard let url = URL(string: urlString) else {
            throw DataSourceError.invalidURL(urlString)
        }

        var request = URLRequest(url: url)
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let (data, response) = try await session.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw DataSourceError.invalidResponse
        }

        guard httpResponse.statusCode == 200 else {
            throw DataSourceError.httpError(httpResponse.statusCode)
        }

        let newsResponse = try JSONDecoder().decode(NewsAPIResponse.self, from: data)
        return parseArticles(from: newsResponse, team: team)
    }

    private func parseArticles(from response: NewsAPIResponse, team: Team) -> [Article] {
        response.articles.compactMap { newsArticle in
            guard let publishedAt = ISO8601DateFormatter().date(from: newsArticle.publishedAt ?? "") else {
                return nil
            }

            return Article(
                title: newsArticle.title,
                content: newsArticle.description ?? newsArticle.content ?? "",
                publishedDate: publishedAt,
                source: newsArticle.source.name,
                teams: [team]
            )
        }
    }
}

private struct NewsAPIResponse: Codable {
    let status: String
    let totalResults: Int
    let articles: [NewsAPIArticle]
}

private struct NewsAPIArticle: Codable {
    let source: NewsAPISource
    let title: String
    let description: String?
    let content: String?
    let publishedAt: String?
}

private struct NewsAPISource: Codable {
    let name: String
}

/// Reddit API client for fetching posts about NFL teams.
///
/// Register app at: https://www.reddit.com/prefs/apps
/// Free tier with rate limiting.
public struct RedditAPIDataSource: RedditDataSource {
    private let clientId: String
    private let clientSecret: String
    private let userAgent: String
    private let baseURL: String
    private let session: URLSession
    private var accessToken: String?

    /// Creates a Reddit API data source.
    ///
    /// - Parameters:
    ///   - clientId: Reddit app client ID.
    ///   - clientSecret: Reddit app secret.
    ///   - userAgent: User agent string.
    ///   - baseURL: Reddit API base URL.
    ///   - session: URL session for requests.
    public init(
        clientId: String,
        clientSecret: String,
        userAgent: String = "OutcomePredictor/1.0",
        baseURL: String = "https://oauth.reddit.com",
        session: URLSession = .shared
    ) {
        self.clientId = clientId
        self.clientSecret = clientSecret
        self.userAgent = userAgent
        self.baseURL = baseURL
        self.session = session
    }

    public func fetchPosts(about team: Team, limit: Int, before date: Date) async throws -> [Article] {
        // Get team subreddit name (e.g., "49ers", "eagles")
        let subreddit = getSubredditName(for: team)
        return try await fetchPosts(from: [subreddit, "nfl"], limit: limit)
    }

    public func fetchPosts(from subreddits: [String], limit: Int) async throws -> [Article] {
        var allArticles: [Article] = []

        for subreddit in subreddits {
            let urlString = "\(baseURL)/r/\(subreddit)/hot?limit=\(min(limit, 100))"
            guard let url = URL(string: urlString) else { continue }

            var request = URLRequest(url: url)
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            request.setValue(userAgent, forHTTPHeaderField: "User-Agent")

            // Note: Full implementation requires OAuth token management
            // For now, using read-only public access

            do {
                let (data, response) = try await session.data(for: request)

                guard let httpResponse = response as? HTTPURLResponse,
                      httpResponse.statusCode == 200 else {
                    continue
                }

                let redditResponse = try JSONDecoder().decode(RedditResponse.self, from: data)
                let articles = parseRedditPosts(from: redditResponse, subreddit: subreddit)
                allArticles.append(contentsOf: articles)
            } catch {
                // Continue with other subreddits on error
                continue
            }
        }

        return Array(allArticles.prefix(limit))
    }

    private func getSubredditName(for team: Team) -> String {
        // Map team names to subreddit names
        let mapping: [String: String] = [
            "SF": "49ers",
            "KC": "KansasCityChiefs",
            "BUF": "buffalobills",
            "PHI": "eagles",
            "DAL": "cowboys",
            "GB": "GreenBayPackers",
            "NE": "Patriots",
            "DEN": "DenverBroncos",
            // Add more mappings as needed
        ]

        return mapping[team.abbreviation] ?? team.abbreviation.lowercased()
    }

    private func parseRedditPosts(from response: RedditResponse, subreddit: String) -> [Article] {
        response.data.children.compactMap { child in
            let post = child.data
            let date = Date(timeIntervalSince1970: post.created)

            // Try to identify mentioned teams from post
            let teams = NFLTeams.allTeams.filter { team in
                post.title.localizedCaseInsensitiveContains(team.name) ||
                post.title.localizedCaseInsensitiveContains(team.abbreviation)
            }

            return Article(
                title: post.title,
                content: post.selftext ?? "",
                publishedDate: date,
                source: "Reddit r/\(subreddit)",
                teams: teams.isEmpty ? [] : Array(teams.prefix(2))
            )
        }
    }
}

private struct RedditResponse: Codable {
    let data: RedditData
}

private struct RedditData: Codable {
    let children: [RedditChild]
}

private struct RedditChild: Codable {
    let data: RedditPost
}

private struct RedditPost: Codable {
    let title: String
    let selftext: String?
    let created: Double
    let author: String
    let score: Int
}

/// X (Twitter) API client for fetching tweets about NFL teams.
///
/// Requires X API v2 access. Get keys at: https://developer.x.com/
/// Note: X API is now paid ($100/month minimum for basic access).
public struct XAPIDataSource: XDataSource {
    private let bearerToken: String
    private let baseURL: String
    private let session: URLSession

    /// Creates an X API data source.
    ///
    /// - Parameters:
    ///   - bearerToken: X API v2 bearer token.
    ///   - baseURL: X API base URL.
    ///   - session: URL session for requests.
    public init(
        bearerToken: String,
        baseURL: String = "https://api.twitter.com/2",
        session: URLSession = .shared
    ) {
        self.bearerToken = bearerToken
        self.baseURL = baseURL
        self.session = session
    }

    public func fetchTweets(about team: Team, limit: Int, before date: Date) async throws -> [Article] {
        let query = "\(team.name) OR #\(team.abbreviation) (injury OR game OR news)"
        return try await searchTweets(query: query, limit: limit, before: date, team: team)
    }

    public func fetchTweets(from usernames: [String], limit: Int) async throws -> [Article] {
        var allArticles: [Article] = []

        for username in usernames {
            let tweets = try await fetchUserTimeline(username: username, limit: limit)
            allArticles.append(contentsOf: tweets)
        }

        return Array(allArticles.prefix(limit))
    }

    private func searchTweets(query: String, limit: Int, before: Date, team: Team) async throws -> [Article] {
        let dateFormatter = ISO8601DateFormatter()
        let endTime = dateFormatter.string(from: before)

        let encodedQuery = query.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? query
        let urlString = "\(baseURL)/tweets/search/recent?query=\(encodedQuery)&max_results=\(min(limit, 100))&end_time=\(endTime)&tweet.fields=created_at,author_id"

        guard let url = URL(string: urlString) else {
            throw DataSourceError.invalidURL(urlString)
        }

        var request = URLRequest(url: url)
        request.setValue("Bearer \(bearerToken)", forHTTPHeaderField: "Authorization")

        let (data, response) = try await session.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw DataSourceError.invalidResponse
        }

        guard httpResponse.statusCode == 200 else {
            if httpResponse.statusCode == 429 {
                throw DataSourceError.rateLimitExceeded
            }
            throw DataSourceError.httpError(httpResponse.statusCode)
        }

        let twitterResponse = try JSONDecoder().decode(TwitterResponse.self, from: data)
        return parseTweets(from: twitterResponse, team: team)
    }

    private func fetchUserTimeline(username: String, limit: Int) async throws -> [Article] {
        // Implementation for user timeline
        return []
    }

    private func parseTweets(from response: TwitterResponse, team: Team) -> [Article] {
        response.data?.compactMap { tweet in
            guard let createdAt = ISO8601DateFormatter().date(from: tweet.createdAt ?? "") else {
                return nil
            }

            return Article(
                title: tweet.text.prefix(100).appending("..."),
                content: tweet.text,
                publishedDate: createdAt,
                source: "X (Twitter)",
                teams: [team]
            )
        } ?? []
    }
}

private struct TwitterResponse: Codable {
    let data: [TwitterTweet]?
}

private struct TwitterTweet: Codable {
    let id: String
    let text: String
    let createdAt: String?

    enum CodingKeys: String, CodingKey {
        case id, text
        case createdAt = "created_at"
    }
}
