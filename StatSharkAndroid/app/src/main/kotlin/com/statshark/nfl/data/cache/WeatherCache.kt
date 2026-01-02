package com.statshark.nfl.data.cache

import com.statshark.nfl.data.model.GameWeatherDTO
import com.statshark.nfl.data.model.TeamWeatherStatsDTO

/**
 * Simple in-memory cache for weather data
 * Used to pass weather data between screens
 */
object WeatherCache {
    // Game weather forecasts by game ID
    private val gameWeatherCache = mutableMapOf<String, GameWeatherDTO>()

    // Team weather stats by team abbreviation
    private val teamStatsCache = mutableMapOf<String, TeamWeatherStatsDTO>()

    fun putGameWeather(gameId: String, weather: GameWeatherDTO) {
        gameWeatherCache[gameId] = weather
    }

    fun getGameWeather(gameId: String): GameWeatherDTO? {
        return gameWeatherCache[gameId]
    }

    fun putTeamStats(teamAbbr: String, stats: TeamWeatherStatsDTO) {
        teamStatsCache[teamAbbr] = stats
    }

    fun getTeamStats(teamAbbr: String): TeamWeatherStatsDTO? {
        return teamStatsCache[teamAbbr]
    }

    fun clear() {
        gameWeatherCache.clear()
        teamStatsCache.clear()
    }
}
