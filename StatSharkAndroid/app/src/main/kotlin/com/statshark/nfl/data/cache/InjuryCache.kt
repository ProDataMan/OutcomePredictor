package com.statshark.nfl.data.cache

import com.statshark.nfl.data.model.TeamInjuryReportDTO

/**
 * Simple in-memory cache for injury reports
 * Used to pass injury data between screens
 */
object InjuryCache {
    // Injury reports by game ID (stores both home and away team reports)
    private val cache = mutableMapOf<String, Pair<TeamInjuryReportDTO, TeamInjuryReportDTO>>()

    fun put(gameId: String, homeReport: TeamInjuryReportDTO, awayReport: TeamInjuryReportDTO) {
        cache[gameId] = Pair(homeReport, awayReport)
    }

    fun get(gameId: String): Pair<TeamInjuryReportDTO, TeamInjuryReportDTO>? {
        return cache[gameId]
    }

    fun clear() {
        cache.clear()
    }
}
