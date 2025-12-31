import Vapor
import Fluent

/// Feedback model for storing user feedback in the database
final class Feedback: Model, Content, @unchecked Sendable {
    static let schema = "feedback"

    @ID(key: .id)
    var id: UUID?

    @Field(key: "user_id")
    var userId: String

    @Field(key: "page")
    var page: String

    @Field(key: "platform")
    var platform: String // "iOS" or "Android"

    @Field(key: "feedback_text")
    var feedbackText: String

    @Field(key: "app_version")
    var appVersion: String?

    @Field(key: "device_model")
    var deviceModel: String?

    @Timestamp(key: "created_at", on: .create)
    var createdAt: Date?

    @Field(key: "is_read")
    var isRead: Bool

    init() {}

    init(
        id: UUID? = nil,
        userId: String,
        page: String,
        platform: String,
        feedbackText: String,
        appVersion: String? = nil,
        deviceModel: String? = nil,
        isRead: Bool = false
    ) {
        self.id = id
        self.userId = userId
        self.page = page
        self.platform = platform
        self.feedbackText = feedbackText
        self.appVersion = appVersion
        self.deviceModel = deviceModel
        self.isRead = isRead
    }
}

/// Migration for creating the feedback table
struct CreateFeedback: AsyncMigration {
    func prepare(on database: Database) async throws {
        try await database.schema(Feedback.schema)
            .id()
            .field("user_id", .string, .required)
            .field("page", .string, .required)
            .field("platform", .string, .required)
            .field("feedback_text", .string, .required)
            .field("app_version", .string)
            .field("device_model", .string)
            .field("created_at", .datetime)
            .field("is_read", .bool, .required)
            .create()
    }

    func revert(on database: Database) async throws {
        try await database.schema(Feedback.schema).delete()
    }
}
