package com.statshark.nfl.api

import com.statshark.nfl.data.model.*
import retrofit2.Response
import retrofit2.http.*

/**
 * StatShark API Service
 * Retrofit interface for NFL prediction API
 */
interface StatSharkApiService {

    @GET("teams")
    suspend fun getTeams(): List<TeamDTO>

    @GET("upcoming")
    suspend fun getUpcomingGames(): List<GameDTO>

    @GET("current-week")
    suspend fun getCurrentWeekGames(): CurrentWeekResponse

    @GET("teams/{teamId}")
    suspend fun getTeamDetails(@Path("teamId") teamId: String): TeamDTO

    @GET("teams/{teamId}/roster")
    suspend fun getTeamRoster(
        @Path("teamId") teamId: String,
        @Query("season") season: Int
    ): TeamRosterDTO

    @GET("games")
    suspend fun getTeamGames(
        @Query("team") team: String,
        @Query("season") season: Int
    ): List<GameDTO>

    @GET("news")
    suspend fun getNews(
        @Query("team") team: String,
        @Query("limit") limit: Int = 10
    ): List<ArticleDTO>

    @POST("predictions")
    suspend fun makePrediction(
        @Body request: PredictionRequest
    ): PredictionDTO

    // Feedback endpoints
    @POST("feedback")
    suspend fun submitFeedback(
        @Body submission: FeedbackSubmissionDTO
    ): Response<FeedbackDTO>

    @GET("feedback")
    suspend fun getFeedback(
        @Query("userId") userId: String
    ): Response<List<FeedbackDTO>>

    @GET("feedback/unread")
    suspend fun getUnreadCount(
        @Query("userId") userId: String
    ): Response<UnreadCountResponse>

    @POST("feedback/mark-read")
    suspend fun markFeedbackAsRead(
        @Body request: MarkFeedbackReadDTO
    ): Response<Unit>
}

/**
 * Prediction Request Body
 */
data class PredictionRequest(
    val homeTeamAbbreviation: String,
    val awayTeamAbbreviation: String,
    val season: Int,
    val week: Int? = null,
    val scheduledDate: String? = null
)
