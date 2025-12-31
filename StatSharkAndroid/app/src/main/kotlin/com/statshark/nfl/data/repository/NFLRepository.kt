package com.statshark.nfl.data.repository

import com.statshark.nfl.api.StatSharkApiService
import com.statshark.nfl.data.model.*
import com.statshark.nfl.ui.theme.TeamColors
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.async
import kotlinx.coroutines.awaitAll
import kotlinx.coroutines.coroutineScope
import kotlinx.coroutines.withContext
import java.text.SimpleDateFormat
import java.util.*
import javax.inject.Inject
import javax.inject.Singleton

/**
 * Repository for NFL data
 * Handles data operations and caching
 */
@Singleton
class NFLRepository @Inject constructor(private val apiService: StatSharkApiService) {

    // In-memory cache
    private var cachedTeams: List<TeamDTO>? = null
    private var cacheTimestamp: Long = 0
    private val CACHE_DURATION = 5 * 60 * 1000L // 5 minutes

    /**
     * Fetch all NFL teams with caching
     */
    suspend fun getTeams(forceRefresh: Boolean = false): Result<List<TeamDTO>> {
        return withContext(Dispatchers.IO) {
            try {
                // Check cache
                val now = System.currentTimeMillis()
                if (!forceRefresh && cachedTeams != null && (now - cacheTimestamp) < CACHE_DURATION) {
                    return@withContext Result.success(cachedTeams!!)
                }

                // Fetch from API
                val teams = apiService.getTeams()
                val teamsWithConference = teams.map {
                    it.copy(conference = TeamColors.getConference(it.abbreviation))
                }
                cachedTeams = teamsWithConference
                cacheTimestamp = now
                Result.success(teamsWithConference)
            } catch (e: Exception) {
                Result.failure(e)
            }
        }
    }

    /**
     * Fetch upcoming games
     */
    suspend fun getUpcomingGames(): Result<List<GameDTO>> {
        return withContext(Dispatchers.IO) {
            try {
                val games = apiService.getUpcomingGames()
                Result.success(games)
            } catch (e: Exception) {
                Result.failure(e)
            }
        }
    }

    /**
     * Fetch current week games
     */
    suspend fun getCurrentWeekGames(): Result<CurrentWeekResponse> {
        return withContext(Dispatchers.IO) {
            try {
                val response = apiService.getCurrentWeekGames()
                Result.success(response)
            } catch (e: Exception) {
                Result.failure(e)
            }
        }
    }

    /**
     * Fetch team roster
     */
    suspend fun getTeamRoster(teamId: String, season: Int): Result<TeamRosterDTO> {
        return withContext(Dispatchers.IO) {
            try {
                val roster = apiService.getTeamRoster(teamId, season)
                Result.success(roster)
            } catch (e: Exception) {
                Result.failure(e)
            }
        }
    }

    /**
     * Fetch team games
     */
    suspend fun getTeamGames(team: String, season: Int): Result<List<GameDTO>> {
        return withContext(Dispatchers.IO) {
            try {
                val games = apiService.getTeamGames(team, season)
                Result.success(games)
            } catch (e: Exception) {
                Result.failure(e)
            }
        }
    }

    /**
     * Fetch team news
     */
    suspend fun getTeamNews(team: String, limit: Int = 10): Result<List<ArticleDTO>> {
        return withContext(Dispatchers.IO) {
            try {
                val news = apiService.getNews(team, limit)
                Result.success(news)
            } catch (e: Exception) {
                Result.failure(e)
            }
        }
    }

    /**
     * Make a prediction
     */
    suspend fun makePrediction(
        homeTeam: String,
        awayTeam: String,
        season: Int,
        week: Int? = null
    ): Result<PredictionDTO> {
        return withContext(Dispatchers.IO) {
            try {
                val request = com.statshark.nfl.api.PredictionRequest(
                    homeTeamAbbreviation = homeTeam,
                    awayTeamAbbreviation = awayTeam,
                    season = season,
                    week = week
                )
                val prediction = apiService.makePrediction(request)
                Result.success(prediction)
            } catch (e: Exception) {
                Result.failure(e)
            }
        }
    }

    /**
     * Clear cache
     */
    fun clearCache() {
        cachedTeams = null
        cacheTimestamp = 0
    }

    /**
     * Fetch and calculate league standings
     */
    suspend fun getStandings(season: Int = Calendar.getInstance().get(Calendar.YEAR)): Result<LeagueStandings> {
        return withContext(Dispatchers.IO) {
            try {
                // Fetch all teams
                val teamsResult = getTeams()
                if (teamsResult.isFailure) {
                    return@withContext Result.failure(teamsResult.exceptionOrNull()!!)
                }
                val teams = teamsResult.getOrNull()!!

                // Fetch games for all teams in parallel
                val teamStandings = coroutineScope {
                    teams.map { team ->
                        async {
                            val gamesResult = getTeamGames(team.abbreviation, season)
                            val games = gamesResult.getOrNull() ?: emptyList()
                            calculateTeamStandings(team, games)
                        }
                    }.awaitAll()
                }

                // Group by conference and division
                val divisions = teamStandings
                    .groupBy { "${it.team.conference}-${it.team.division}" }
                    .map { (_, standings) ->
                        val sorted = standings.sortedWith(
                            compareByDescending<TeamStandings> { it.winPercentage }
                                .thenByDescending { it.wins }
                        )
                        DivisionStandings(
                            conference = sorted.first().team.conference ?: "Unknown",
                            division = sorted.first().team.division,
                            teams = sorted
                        )
                    }
                    .sortedWith(
                        compareBy<DivisionStandings> { it.conference }
                            .thenBy { it.division }
                    )

                val dateFormat = SimpleDateFormat("yyyy-MM-dd'T'HH:mm:ss'Z'", Locale.US)
                val lastUpdated = dateFormat.format(Date())

                Result.success(
                    LeagueStandings(
                        season = season,
                        week = null,
                        lastUpdated = lastUpdated,
                        divisions = divisions
                    )
                )
            } catch (e: Exception) {
                Result.failure(e)
            }
        }
    }

    /**
     * Calculate standings for a single team
     */
    private fun calculateTeamStandings(team: TeamDTO, games: List<GameDTO>): TeamStandings {
        var wins = 0
        var losses = 0
        var ties = 0
        var pointsFor = 0
        var pointsAgainst = 0
        var divisionWins = 0
        var divisionLosses = 0
        var conferenceWins = 0
        var conferenceLosses = 0
        val recentResults = mutableListOf<String>()

        // Only count completed games
        val completedGames = games.filter { it.homeScore != null && it.awayScore != null }

        for (game in completedGames) {
            val isHome = game.homeTeam.abbreviation == team.abbreviation
            val teamScore = if (isHome) game.homeScore!! else game.awayScore!!
            val opponentScore = if (isHome) game.awayScore!! else game.homeScore!!
            val opponent = if (isHome) game.awayTeam else game.homeTeam

            pointsFor += teamScore
            pointsAgainst += opponentScore

            // Determine result
            when {
                teamScore > opponentScore -> {
                    wins++
                    recentResults.add("W")

                    if (opponent.division == team.division) divisionWins++
                    if (opponent.conference == team.conference) conferenceWins++
                }
                teamScore < opponentScore -> {
                    losses++
                    recentResults.add("L")

                    if (opponent.division == team.division) divisionLosses++
                    if (opponent.conference == team.conference) conferenceLosses++
                }
                else -> {
                    ties++
                    recentResults.add("T")
                }
            }
        }

        // Calculate win percentage
        val totalGames = wins + losses + ties
        val winPercentage = if (totalGames > 0) {
            (wins + (ties * 0.5)) / totalGames
        } else {
            0.0
        }

        // Calculate streak
        val streak = calculateStreak(recentResults.takeLast(5))

        return TeamStandings(
            team = team,
            wins = wins,
            losses = losses,
            ties = ties,
            winPercentage = winPercentage,
            pointsFor = pointsFor,
            pointsAgainst = pointsAgainst,
            divisionWins = divisionWins,
            divisionLosses = divisionLosses,
            conferenceWins = conferenceWins,
            conferenceLosses = conferenceLosses,
            streak = streak
        )
    }

    /**
     * Calculate current win/loss streak
     */
    private fun calculateStreak(results: List<String>): String {
        if (results.isEmpty()) return "-"

        val mostRecent = results.last()
        var count = 0

        for (result in results.reversed()) {
            if (result == mostRecent) {
                count++
            } else {
                break
            }
        }

        return "$mostRecent$count"
    }
}
