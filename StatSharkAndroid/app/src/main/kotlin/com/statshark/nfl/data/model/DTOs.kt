package com.statshark.nfl.data.model

import com.google.gson.annotations.SerializedName
import kotlinx.serialization.Serializable

/**
 * Team Data Transfer Object
 * Represents an NFL team with basic information
 */
@Serializable
data class TeamDTO(
    val name: String,
    val abbreviation: String,
    val conference: String?,
    val division: String,
    val city: String? = null,
    val primaryColor: String? = null,
    val secondaryColor: String? = null
)

/**
 * Game Data Transfer Object
 * Represents an NFL game with complete information
 */
@Serializable
data class GameDTO(
    val id: String,
    @SerializedName("home_team")
    val homeTeam: TeamDTO,
    @SerializedName("away_team")
    val awayTeam: TeamDTO,
    @SerializedName("home_score")
    val homeScore: Int? = null,
    @SerializedName("away_score")
    val awayScore: Int? = null,
    val date: String,
    @SerializedName("scheduled_date")
    val scheduledDate: String,
    val week: Int,
    val season: Int,
    val status: String? = null,
    val venue: String? = null
)

/**
 * Player Data Transfer Object
 * Represents a player with stats
 */
@Serializable
data class PlayerDTO(
    val id: String,
    val name: String,
    val position: String,
    @SerializedName("jersey_number")
    val jerseyNumber: Int? = null,
    val height: String? = null,
    val weight: Int? = null,
    val age: Int? = null,
    val college: String? = null,
    val experience: Int? = null,
    @SerializedName("photo_url")
    val photoURL: String? = null,
    val stats: PlayerStatsDTO? = null
)

/**
 * Player Stats Data Transfer Object
 */
@Serializable
data class PlayerStatsDTO(
    // Passing stats
    @SerializedName("passing_yards")
    val passingYards: Int? = null,
    @SerializedName("passing_touchdowns")
    val passingTouchdowns: Int? = null,
    val interceptions: Int? = null,
    val completions: Int? = null,
    val attempts: Int? = null,

    // Rushing stats
    @SerializedName("rushing_yards")
    val rushingYards: Int? = null,
    @SerializedName("rushing_touchdowns")
    val rushingTouchdowns: Int? = null,
    @SerializedName("rushing_attempts")
    val rushingAttempts: Int? = null,

    // Receiving stats
    @SerializedName("receiving_yards")
    val receivingYards: Int? = null,
    @SerializedName("receiving_touchdowns")
    val receivingTouchdowns: Int? = null,
    val receptions: Int? = null,
    val targets: Int? = null,

    // Defensive stats
    val tackles: Int? = null,
    val sacks: Double? = null,
    @SerializedName("defensive_interceptions")
    val defensiveInterceptions: Int? = null,
    @SerializedName("forced_fumbles")
    val forcedFumbles: Int? = null,

    // Kicking stats
    @SerializedName("field_goals_made")
    val fieldGoalsMade: Int? = null,
    @SerializedName("field_goals_attempted")
    val fieldGoalsAttempted: Int? = null,
    @SerializedName("extra_points_made")
    val extraPointsMade: Int? = null
) {
    val completionPercentage: Double?
        get() = if (attempts != null && attempts > 0 && completions != null) {
            (completions.toDouble() / attempts) * 100
        } else null

    val yardsPerCarry: Double?
        get() = if (rushingAttempts != null && rushingAttempts > 0 && rushingYards != null) {
            rushingYards.toDouble() / rushingAttempts
        } else null
}

/**
 * Team Roster Data Transfer Object
 */
@Serializable
data class TeamRosterDTO(
    val team: TeamDTO,
    val players: List<PlayerDTO>,
    val season: Int
)

/**
 * Prediction Data Transfer Object
 */
@Serializable
data class PredictionDTO(
    @SerializedName("game_id")
    val gameId: String,
    @SerializedName("home_team")
    val homeTeam: TeamDTO,
    @SerializedName("away_team")
    val awayTeam: TeamDTO,
    @SerializedName("scheduled_date")
    val scheduledDate: String,
    val location: String,
    val week: Int,
    val season: Int,
    @SerializedName("home_win_probability")
    val homeWinProbability: Double,
    @SerializedName("away_win_probability")
    val awayWinProbability: Double,
    val confidence: Double,
    @SerializedName("predicted_home_score")
    val predictedHomeScore: Int? = null,
    @SerializedName("predicted_away_score")
    val predictedAwayScore: Int? = null,
    val reasoning: String,
    @SerializedName("vegas_odds")
    val vegasOdds: VegasOddsDTO? = null
)

/**
 * Vegas Odds Data Transfer Object
 */
@Serializable
data class VegasOddsDTO(
    @SerializedName("home_moneyline")
    val homeMoneyline: Int? = null,
    @SerializedName("away_moneyline")
    val awayMoneyline: Int? = null,
    val spread: Double? = null,
    val total: Double? = null,
    @SerializedName("home_implied_probability")
    val homeImpliedProbability: Double? = null,
    @SerializedName("away_implied_probability")
    val awayImpliedProbability: Double? = null,
    val bookmaker: String
)

/**
 * Article Data Transfer Object
 * Represents a news article
 */
@Serializable
data class ArticleDTO(
    val id: String,
    val title: String,
    val content: String,
    val source: String,
    val url: String,
    val date: String,
    @SerializedName("related_teams")
    val relatedTeams: List<String>
)

/**
 * Current Week Response
 */
@Serializable
data class CurrentWeekResponse(
    @SerializedName("current_week")
    val currentWeek: Int,
    @SerializedName("current_season")
    val currentSeason: Int,
    val games: List<GameDTO>,
    @SerializedName("as_of_date")
    val asOfDate: String
)

/**
 * Prediction Result
 * Simplified prediction model for UI display
 */
@Serializable
data class PredictionResult(
    val predictedWinner: String,
    val confidence: Double,
    val reasoning: String,
    val vegasOdds: VegasOddsDTO?
)

/**
 * Team Standings
 * Team standings information calculated from game results
 */
@Serializable
data class TeamStandings(
    val team: TeamDTO,
    val wins: Int,
    val losses: Int,
    val ties: Int,
    @SerializedName("win_percentage")
    val winPercentage: Double,
    @SerializedName("points_for")
    val pointsFor: Int,
    @SerializedName("points_against")
    val pointsAgainst: Int,
    @SerializedName("division_wins")
    val divisionWins: Int,
    @SerializedName("division_losses")
    val divisionLosses: Int,
    @SerializedName("conference_wins")
    val conferenceWins: Int,
    @SerializedName("conference_losses")
    val conferenceLosses: Int,
    val streak: String
) {
    val record: String
        get() = if (ties > 0) "$wins-$losses-$ties" else "$wins-$losses"
}

/**
 * Division Standings
 * Standings grouping for a division
 */
@Serializable
data class DivisionStandings(
    val conference: String,
    val division: String,
    val teams: List<TeamStandings>
)

/**
 * League Standings
 * Complete league standings organized by division
 */
@Serializable
data class LeagueStandings(
    val season: Int,
    val week: Int? = null,
    @SerializedName("last_updated")
    val lastUpdated: String,
    val divisions: List<DivisionStandings>
) {
    val afcStandings: List<DivisionStandings>
        get() = divisions.filter { it.conference == "AFC" }

    val nfcStandings: List<DivisionStandings>
        get() = divisions.filter { it.conference == "NFC" }
}

// MARK: - Feedback DTOs

/**
 * Feedback submission request
 */
@Serializable
data class FeedbackSubmissionDTO(
    @SerializedName("user_id")
    val userId: String,
    val page: String,
    val platform: String,
    @SerializedName("feedback_text")
    val feedbackText: String,
    @SerializedName("app_version")
    val appVersion: String? = null,
    @SerializedName("device_model")
    val deviceModel: String? = null
)

/**
 * Feedback response DTO
 */
@Serializable
data class FeedbackDTO(
    val id: String,
    @SerializedName("user_id")
    val userId: String,
    val page: String,
    val platform: String,
    @SerializedName("feedback_text")
    val feedbackText: String,
    @SerializedName("app_version")
    val appVersion: String? = null,
    @SerializedName("device_model")
    val deviceModel: String? = null,
    @SerializedName("created_at")
    val createdAt: String,
    @SerializedName("is_read")
    val isRead: Boolean
)

/**
 * Mark feedback as read request
 */
@Serializable
data class MarkFeedbackReadDTO(
    @SerializedName("feedback_ids")
    val feedbackIds: List<String>
)

/**
 * Unread count response
 */
@Serializable
data class UnreadCountResponse(
    @SerializedName("unread_count")
    val unreadCount: Int
)
