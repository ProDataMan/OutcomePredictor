package com.statshark.nfl.data.model

import kotlinx.serialization.Serializable
import kotlinx.serialization.encodeToString
import kotlinx.serialization.json.Json

/**
 * Fantasy Player representation
 * Mirrors iOS FantasyPlayer model
 */
@Serializable
data class FantasyPlayer(
    val id: String,
    val name: String,
    val position: String,
    val jerseyNumber: Int?,
    val photoURL: String?,
    val teamAbbreviation: String,
    val teamName: String,
    val stats: PlayerStatsDTO?
) {
    companion object {
        fun from(player: PlayerDTO, team: TeamDTO): FantasyPlayer {
            return FantasyPlayer(
                id = player.id,
                name = player.name,
                position = player.position,
                jerseyNumber = player.jerseyNumber,
                photoURL = player.photoURL,
                teamAbbreviation = team.abbreviation,
                teamName = team.name,
                stats = player.stats
            )
        }
    }

    /**
     * Calculate fantasy points based on standard scoring
     * Matches iOS implementation exactly
     */
    val projectedPoints: Double
        get() {
            val stats = this.stats ?: return 0.0
            var points = 0.0

            when (position) {
                "QB" -> {
                    // QB Scoring
                    points += (stats.passingYards ?: 0) * 0.04 // 1 point per 25 yards
                    points += (stats.passingTouchdowns ?: 0) * 4.0
                    points -= (stats.interceptions ?: 0) * 2.0
                    points += (stats.rushingYards ?: 0) * 0.1
                    points += (stats.rushingTouchdowns ?: 0) * 6.0
                }
                "RB" -> {
                    // RB Scoring
                    points += (stats.rushingYards ?: 0) * 0.1
                    points += (stats.rushingTouchdowns ?: 0) * 6.0
                    points += (stats.receivingYards ?: 0) * 0.1
                    points += (stats.receivingTouchdowns ?: 0) * 6.0
                    points += (stats.receptions ?: 0) * 0.5 // PPR
                }
                "WR", "TE" -> {
                    // WR/TE Scoring
                    points += (stats.receivingYards ?: 0) * 0.1
                    points += (stats.receivingTouchdowns ?: 0) * 6.0
                    points += (stats.receptions ?: 0) * 0.5 // PPR
                }
            }

            return points
        }
}

/**
 * Fantasy Team Roster
 * Mirrors iOS FantasyRoster model
 */
@Serializable
data class FantasyRoster(
    val quarterbacks: MutableList<FantasyPlayer> = mutableListOf(),
    val runningBacks: MutableList<FantasyPlayer> = mutableListOf(),
    val wideReceivers: MutableList<FantasyPlayer> = mutableListOf(),
    val tightEnds: MutableList<FantasyPlayer> = mutableListOf(),
    val kickers: MutableList<FantasyPlayer> = mutableListOf(),
    val defense: MutableList<FantasyPlayer> = mutableListOf()
) {
    companion object {
        const val MAX_QBS = 2
        const val MAX_RBS = 3
        const val MAX_WRS = 3
        const val MAX_TES = 2
        const val MAX_KS = 1
        const val MAX_DEF = 1

        fun fromJson(json: String): FantasyRoster? {
            return try {
                Json.decodeFromString<FantasyRoster>(json)
            } catch (e: Exception) {
                null
            }
        }
    }

    val allPlayers: List<FantasyPlayer>
        get() = quarterbacks + runningBacks + wideReceivers + tightEnds + kickers + defense

    val totalPlayers: Int
        get() = allPlayers.size

    val maxPlayers: Int
        get() = MAX_QBS + MAX_RBS + MAX_WRS + MAX_TES + MAX_KS + MAX_DEF

    val isFull: Boolean
        get() = totalPlayers >= maxPlayers

    val totalProjectedPoints: Double
        get() = allPlayers.sumOf { it.projectedPoints }

    fun toJson(): String {
        return Json.encodeToString(this)
    }
}
