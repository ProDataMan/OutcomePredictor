import Vapor
import OutcomePredictorAPI

/// Vapor Content conformance for API DTOs.
/// This file adds Vapor-specific conformances without coupling OutcomePredictorAPI to Vapor.
/// Content protocol provides automatic encoding/decoding for Codable + Sendable types.

extension TeamDTO: Content {}
extension GameDTO: Content {}
extension ArticleDTO: Content {}
extension PredictionDTO: Content {}
extension VegasOddsDTO: Content {}
extension ErrorResponse: Content {}
extension GamesRequest: Content {}
extension NewsRequest: Content {}
extension PredictionRequest: Content {}
extension TeamRosterDTO: Content {}
extension PlayerDTO: Content {}
extension PlayerStatsDTO: Content {}
extension FeedbackDTO: Content {}
extension FeedbackSubmissionDTO: Content {}
extension MarkFeedbackReadDTO: Content {}
