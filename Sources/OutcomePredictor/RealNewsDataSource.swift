import Foundation
#if canImport(FoundationNetworking)
import FoundationNetworking
#endif

/// News data source using the DataLoader - implements NewsDataSource protocol.
public struct RealNewsDataSource: NewsDataSource {
    private let dataLoader: DataLoader

    public init(dataLoader: DataLoader) {
        self.dataLoader = dataLoader
    }

    public func fetchArticles(for team: Team, before date: Date) async throws -> [Article] {
        let sevenDaysAgo = Calendar.current.date(byAdding: .day, value: -7, to: date) ?? date
        let articles = try await dataLoader.loadArticles(for: team, before: date, after: sevenDaysAgo)
        return articles
    }
}
