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
    val jerseyNumber: String? = null,  // Changed from Int to String to match backend
    val height: String? = null,
    val weight: Int? = null,
    val age: Int? = null,
    val college: String? = null,
    val experience: Int? = null,
    val photoURL: String? = null,  // camelCase to match backend
    val stats: PlayerStatsDTO? = null
)

/**
 * Player Stats Data Transfer Object
 */
@Serializable
data class PlayerStatsDTO(
    // Passing stats
    val passingYards: Int? = null,
    val passingTouchdowns: Int? = null,
    val passingInterceptions: Int? = null,
    val passingCompletions: Int? = null,
    val passingAttempts: Int? = null,

    // Rushing stats
    val rushingYards: Int? = null,
    val rushingTouchdowns: Int? = null,
    val rushingAttempts: Int? = null,

    // Receiving stats
    val receivingYards: Int? = null,
    val receivingTouchdowns: Int? = null,
    val receptions: Int? = null,
    val targets: Int? = null,

    // Defensive stats
    val tackles: Int? = null,
    val sacks: Double? = null,
    val interceptions: Int? = null,  // Changed from defensiveInterceptions

    // Kicking stats
    val fieldGoalsMade: Int? = null,
    val fieldGoalsAttempted: Int? = null,
    val extraPointsMade: Int? = null,
    val extraPointsAttempted: Int? = null
) {
    // Computed properties
    val completionPercentage: Double?
        get() = if (passingAttempts != null && passingAttempts > 0 && passingCompletions != null) {
            (passingCompletions.toDouble() / passingAttempts.toDouble()) * 100.0
        } else null

    val yardsPerCarry: Double?
        get() = if (rushingAttempts != null && rushingAttempts > 0 && rushingYards != null) {
            rushingYards.toDouble() / rushingAttempts.toDouble()
        } else null

    val catchPercentage: Double?
        get() = if (targets != null && targets > 0 && receptions != null) {
            (receptions.toDouble() / targets.toDouble()) * 100.0
        } else null

    val yardsPerReception: Double?
        get() = if (receptions != null && receptions > 0 && receivingYards != null) {
            receivingYards.toDouble() / receptions.toDouble()
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
    val vegasOdds: VegasOddsDTO? = null,
    @SerializedName("confidence_breakdown")
    val confidenceBreakdown: PredictionConfidenceBreakdownDTO? = null
)

/**
 * Prediction Confidence Breakdown DTO
 */
@Serializable
data class PredictionConfidenceBreakdownDTO(
    val factors: List<ConfidenceFactorDTO>,
    @SerializedName("total_confidence")
    val totalConfidence: Double
)

/**
 * Individual Confidence Factor DTO
 */
@Serializable
data class ConfidenceFactorDTO(
    val id: String,
    val name: String,
    val impact: Double,  // -1.0 to 1.0 (positive favors predicted winner)
    val description: String,
    val category: String  // "historical", "injuries", "momentum", "weather", "travel"
) {
    val impactPercentage: Double
        get() = kotlin.math.abs(impact) * 100

    val favorsWinner: Boolean
        get() = impact > 0
}

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

// MARK: - Weather DTOs

/**
 * Game Weather Data Transfer Object
 * Weather forecast for a game
 */
@Serializable
data class GameWeatherDTO(
    val temperature: Double,
    val condition: String,
    @SerializedName("wind_speed")
    val windSpeed: Double,
    val precipitation: Double,
    val humidity: Double,
    val timestamp: String
)

/**
 * Team Weather Stats Data Transfer Object
 * Historical weather performance for a team
 */
@Serializable
data class TeamWeatherStatsDTO(
    @SerializedName("team_abbreviation")
    val teamAbbreviation: String,
    val season: Int,
    @SerializedName("home_stats")
    val homeStats: WeatherPerformanceDTO,
    @SerializedName("away_stats")
    val awayStats: WeatherPerformanceDTO
)

/**
 * Weather Performance Data Transfer Object
 * Performance statistics in different weather conditions
 */
@Serializable
data class WeatherPerformanceDTO(
    val clear: ConditionStatsDTO,
    val rain: ConditionStatsDTO,
    val snow: ConditionStatsDTO,
    val wind: ConditionStatsDTO,
    val cold: ConditionStatsDTO,
    val hot: ConditionStatsDTO
)

/**
 * Condition Stats Data Transfer Object
 * Statistics for a specific weather condition
 */
@Serializable
data class ConditionStatsDTO(
    val games: Int,
    val wins: Int,
    val losses: Int,
    @SerializedName("avg_points_scored")
    val avgPointsScored: Double,
    @SerializedName("avg_points_allowed")
    val avgPointsAllowed: Double
) {
    val winPercentage: Double
        get() = if (games > 0) (wins.toDouble() / games) * 100 else 0.0
}

// MARK: - Injury DTOs

/**
 * Injury Status enum
 */
enum class InjuryStatus(val displayName: String) {
    OUT("Out"),
    DOUBTFUL("Doubtful"),
    QUESTIONABLE("Questionable"),
    PROBABLE("Probable"),
    HEALTHY("Healthy")
}

/**
 * Player Position enum with impact weights
 */
enum class PlayerPosition(val abbr: String, val impactWeight: Double) {
    QUARTERBACK("QB", 1.0),
    RUNNING_BACK("RB", 0.6),
    WIDE_RECEIVER("WR", 0.5),
    TIGHT_END("TE", 0.3),
    DEFENSE("DEF", 0.4),
    OTHER("Other", 0.1)
}

/**
 * Injured Player Data Transfer Object
 */
@Serializable
data class InjuredPlayerDTO(
    val name: String,
    val position: String,
    val status: String,
    val description: String? = null
) {
    /**
     * Calculate impact on team performance (0.0 to 1.0)
     */
    fun calculateImpact(): Double {
        val statusMultiplier = when (status.uppercase()) {
            "OUT" -> 1.0
            "DOUBTFUL" -> 0.75
            "QUESTIONABLE" -> 0.4
            "PROBABLE" -> 0.15
            else -> 0.0
        }

        val positionWeight = when (position.uppercase()) {
            "QB" -> 1.0
            "RB" -> 0.6
            "WR" -> 0.5
            "TE" -> 0.3
            "DEF", "DEFENSE" -> 0.4
            else -> 0.1
        }

        return positionWeight * statusMultiplier
    }
}

/**
 * Team Injury Report Data Transfer Object
 */
@Serializable
data class TeamInjuryReportDTO(
    val team: TeamDTO,
    val injuries: List<InjuredPlayerDTO>,
    @SerializedName("fetched_at")
    val fetchedAt: String
) {
    /**
     * Total injury impact for the team (0.0 to 1.0)
     * Takes top 3 most impactful injuries with diminishing returns
     */
    val totalImpact: Double
        get() {
            val sortedImpacts = injuries.map { it.calculateImpact() }.sortedDescending()
            val weights = listOf(1.0, 0.5, 0.25)

            var total = 0.0
            sortedImpacts.take(3).forEachIndexed { index, impact ->
                total += impact * weights[index]
            }

            return minOf(1.0, total)
        }

    /**
     * Get key injuries (high impact players who are out or doubtful)
     */
    val keyInjuries: List<InjuredPlayerDTO>
        get() = injuries.filter { injury ->
            val impact = injury.calculateImpact()
            val status = injury.status.uppercase()
            impact > 0.3 && (status == "OUT" || status == "DOUBTFUL")
        }
}

/**
 * Game Injury Response
 * Injury report for both teams in a game
 */
@Serializable
data class GameInjuryResponseDTO(
    @SerializedName("home_team")
    val homeTeam: TeamInjuryReportDTO,
    @SerializedName("away_team")
    val awayTeam: TeamInjuryReportDTO,
    @SerializedName("game_id")
    val gameId: String
)

// MARK: - Player Comparison DTOs

/**
 * Player Comparison Request
 * Request to compare multiple players
 */
@Serializable
data class PlayerComparisonRequest(
    @SerializedName("player_ids")
    val playerIds: List<String>,
    val season: Int
)

/**
 * Player Comparison Response
 * Response containing compared players with analysis
 */
@Serializable
data class PlayerComparisonResponse(
    val players: List<PlayerDTO>,
    val comparisons: List<StatComparison>,
    val season: Int,
    @SerializedName("generated_at")
    val generatedAt: String
)

/**
 * Stat Comparison
 * Statistical comparison between players for a specific metric
 */
@Serializable
data class StatComparison(
    val id: String,
    @SerializedName("stat_name")
    val statName: String,
    val category: StatCategory,
    val values: List<PlayerStatValue>,
    @SerializedName("leader_player_id")
    val leaderPlayerId: String? = null
)

/**
 * Player Stat Value
 * Individual player's value for a statistic
 */
@Serializable
data class PlayerStatValue(
    @SerializedName("player_id")
    val playerId: String,
    @SerializedName("player_name")
    val playerName: String,
    val value: Double? = null,
    @SerializedName("formatted_value")
    val formattedValue: String,
    @SerializedName("percentile_rank")
    val percentileRank: Double? = null
)

/**
 * Stat Category
 * Category for player statistics
 */
@Serializable
enum class StatCategory(val value: String) {
    @SerializedName("passing")
    PASSING("passing"),

    @SerializedName("rushing")
    RUSHING("rushing"),

    @SerializedName("receiving")
    RECEIVING("receiving"),

    @SerializedName("defense")
    DEFENSE("defense"),

    @SerializedName("kicking")
    KICKING("kicking"),

    @SerializedName("general")
    GENERAL("general")
}

// MARK: - Team Stats DTOs

/**
 * Comprehensive team statistics for a season
 */
@Serializable
data class TeamStatsDTO(
    val team: TeamDTO,
    val season: Int,
    @SerializedName("offensive_stats")
    val offensiveStats: OffensiveStatsDTO,
    @SerializedName("defensive_stats")
    val defensiveStats: DefensiveStatsDTO,
    val rankings: TeamRankingsDTO? = null,
    @SerializedName("recent_games")
    val recentGames: List<GameDTO> = emptyList(),
    @SerializedName("key_players")
    val keyPlayers: List<PlayerDTO> = emptyList()
)

/**
 * Offensive statistics for a team
 */
@Serializable
data class OffensiveStatsDTO(
    @SerializedName("points_per_game")
    val pointsPerGame: Double,
    @SerializedName("yards_per_game")
    val yardsPerGame: Double,
    @SerializedName("passing_yards_per_game")
    val passingYardsPerGame: Double,
    @SerializedName("rushing_yards_per_game")
    val rushingYardsPerGame: Double,
    @SerializedName("third_down_conversion_rate")
    val thirdDownConversionRate: Double? = null,
    @SerializedName("red_zone_efficiency")
    val redZoneEfficiency: Double? = null,
    @SerializedName("turnovers_per_game")
    val turnoversPerGame: Double? = null
)

/**
 * Defensive statistics for a team
 */
@Serializable
data class DefensiveStatsDTO(
    @SerializedName("points_allowed_per_game")
    val pointsAllowedPerGame: Double,
    @SerializedName("yards_allowed_per_game")
    val yardsAllowedPerGame: Double,
    @SerializedName("passing_yards_allowed_per_game")
    val passingYardsAllowedPerGame: Double,
    @SerializedName("rushing_yards_allowed_per_game")
    val rushingYardsAllowedPerGame: Double,
    @SerializedName("sacks_per_game")
    val sacksPerGame: Double? = null,
    @SerializedName("interceptions_per_game")
    val interceptionsPerGame: Double? = null,
    @SerializedName("forced_fumbles_per_game")
    val forcedFumblesPerGame: Double? = null
)

/**
 * Team rankings in various statistical categories
 */
@Serializable
data class TeamRankingsDTO(
    @SerializedName("offensive_rank")
    val offensiveRank: Int? = null,
    @SerializedName("defensive_rank")
    val defensiveRank: Int? = null,
    @SerializedName("passing_offense_rank")
    val passingOffenseRank: Int? = null,
    @SerializedName("rushing_offense_rank")
    val rushingOffenseRank: Int? = null,
    @SerializedName("passing_defense_rank")
    val passingDefenseRank: Int? = null,
    @SerializedName("rushing_defense_rank")
    val rushingDefenseRank: Int? = null,
    @SerializedName("total_rank")
    val totalRank: Int? = null
)

// MARK: - Prediction Accuracy DTOs

/**
 * Historical prediction accuracy tracking
 */
@Serializable
data class PredictionAccuracyDTO(
    @SerializedName("overall_accuracy")
    val overallAccuracy: Double,
    @SerializedName("total_predictions")
    val totalPredictions: Int,
    @SerializedName("correct_predictions")
    val correctPredictions: Int,
    @SerializedName("weekly_accuracy")
    val weeklyAccuracy: List<WeeklyAccuracyDTO>,
    @SerializedName("confidence_breakdown")
    val confidenceBreakdown: List<ConfidenceAccuracyDTO>,
    @SerializedName("model_version")
    val modelVersion: String,
    @SerializedName("last_updated")
    val lastUpdated: String
)

/**
 * Accuracy statistics for a specific week
 */
@Serializable
data class WeeklyAccuracyDTO(
    val week: Int,
    val season: Int,
    val accuracy: Double,
    @SerializedName("total_games")
    val totalGames: Int,
    @SerializedName("correct_predictions")
    val correctPredictions: Int
) {
    val id: String
        get() = "$season-$week"
}

/**
 * Accuracy breakdown by confidence level
 */
@Serializable
data class ConfidenceAccuracyDTO(
    @SerializedName("confidence_range")
    val confidenceRange: String,
    val accuracy: Double,
    @SerializedName("total_predictions")
    val totalPredictions: Int,
    @SerializedName("correct_predictions")
    val correctPredictions: Int,
    @SerializedName("min_confidence")
    val minConfidence: Double,
    @SerializedName("max_confidence")
    val maxConfidence: Double
)

/**
 * Individual prediction result with actual outcome
 */
@Serializable
data class PredictionResultDTO(
    val id: String,
    @SerializedName("game_id")
    val gameId: String,
    @SerializedName("home_team")
    val homeTeam: TeamDTO,
    @SerializedName("away_team")
    val awayTeam: TeamDTO,
    @SerializedName("predicted_winner")
    val predictedWinner: String,
    @SerializedName("actual_winner")
    val actualWinner: String? = null,
    val confidence: Double,
    val week: Int,
    val season: Int,
    @SerializedName("game_date")
    val gameDate: String,
    val correct: Boolean? = null
)

// MARK: - Model Comparison DTOs

/**
 * Model Comparison Response
 * Comparison of multiple prediction models for a game
 */
@Serializable
data class ModelComparisonDTO(
    val game: GameDTO,
    val models: List<PredictionModelDTO>,
    val consensus: ConsensusDTO? = null,
    @SerializedName("generated_at")
    val generatedAt: String
)

/**
 * Prediction Model Result
 * Individual prediction model result
 */
@Serializable
data class PredictionModelDTO(
    val id: String,
    @SerializedName("model_name")
    val modelName: String,
    @SerializedName("model_version")
    val modelVersion: String,
    @SerializedName("predicted_winner")
    val predictedWinner: String,
    val confidence: Double,
    @SerializedName("home_win_probability")
    val homeWinProbability: Double,
    @SerializedName("away_win_probability")
    val awayWinProbability: Double,
    @SerializedName("predicted_home_score")
    val predictedHomeScore: Int? = null,
    @SerializedName("predicted_away_score")
    val predictedAwayScore: Int? = null,
    val reasoning: String? = null,
    val accuracy: ModelAccuracyDTO? = null
)

/**
 * Model Accuracy Stats
 * Model accuracy statistics
 */
@Serializable
data class ModelAccuracyDTO(
    @SerializedName("overall_accuracy")
    val overallAccuracy: Double,
    @SerializedName("recent_accuracy")
    val recentAccuracy: Double,
    @SerializedName("total_predictions")
    val totalPredictions: Int
)

/**
 * Consensus Prediction
 * Consensus prediction from all models
 */
@Serializable
data class ConsensusDTO(
    @SerializedName("predicted_winner")
    val predictedWinner: String,
    @SerializedName("agreement_percentage")
    val agreementPercentage: Double,
    @SerializedName("average_confidence")
    val averageConfidence: Double,
    @SerializedName("model_count")
    val modelCount: Int
)




