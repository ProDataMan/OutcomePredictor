package com.statshark.nfl.data.repository

import com.statshark.nfl.api.StatSharkApiService
import com.statshark.nfl.data.model.*
import com.statshark.nfl.ui.theme.TeamColors
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.withContext
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
}
