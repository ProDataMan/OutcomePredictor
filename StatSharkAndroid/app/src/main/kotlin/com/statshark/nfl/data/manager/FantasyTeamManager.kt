package com.statshark.nfl.data.manager

import android.content.Context
import android.content.SharedPreferences
import androidx.compose.runtime.mutableStateOf
import com.statshark.nfl.data.model.FantasyPlayer
import com.statshark.nfl.data.model.FantasyRoster
import com.statshark.nfl.data.model.PlayerDTO
import com.statshark.nfl.data.model.TeamDTO
import dagger.hilt.android.qualifiers.ApplicationContext
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import javax.inject.Inject
import javax.inject.Singleton

/**
 * Fantasy Team Manager
 * Manages fantasy roster with persistence
 * Mirrors iOS FantasyTeamManager functionality
 */
@Singleton
class FantasyTeamManager @Inject constructor(
    @ApplicationContext private val context: Context
) {
    private val prefs: SharedPreferences = context.getSharedPreferences("fantasy_prefs", Context.MODE_PRIVATE)

    private val _roster = MutableStateFlow(loadRoster())
    val roster: StateFlow<FantasyRoster> = _roster.asStateFlow()

    private val _teamName = MutableStateFlow(loadTeamName())
    val teamName: StateFlow<String> = _teamName.asStateFlow()

    private val _rosterChanges = MutableStateFlow(0)
    val rosterChanges: StateFlow<Int> = _rosterChanges.asStateFlow()

    companion object {
        private const val KEY_ROSTER = "fantasy_roster"
        private const val KEY_TEAM_NAME = "fantasy_team_name"
        private const val DEFAULT_TEAM_NAME = "My Team"
    }

    /**
     * Update team name
     */
    fun updateTeamName(name: String) {
        val trimmed = name.trim()
        if (trimmed.isEmpty()) return

        _teamName.value = trimmed
        prefs.edit().putString(KEY_TEAM_NAME, trimmed).apply()
    }

    /**
     * Add a player to the roster
     * Returns true if successful, false if position is full
     */
    fun addPlayer(player: PlayerDTO, team: TeamDTO): Boolean {
        val fantasyPlayer = FantasyPlayer.from(player, team)
        val currentRoster = _roster.value

        val success = when (player.position) {
            "QB" -> {
                if (currentRoster.quarterbacks.size < FantasyRoster.MAX_QBS) {
                    currentRoster.quarterbacks.add(fantasyPlayer)
                    true
                } else false
            }
            "RB" -> {
                if (currentRoster.runningBacks.size < FantasyRoster.MAX_RBS) {
                    currentRoster.runningBacks.add(fantasyPlayer)
                    true
                } else false
            }
            "WR" -> {
                if (currentRoster.wideReceivers.size < FantasyRoster.MAX_WRS) {
                    currentRoster.wideReceivers.add(fantasyPlayer)
                    true
                } else false
            }
            "TE" -> {
                if (currentRoster.tightEnds.size < FantasyRoster.MAX_TES) {
                    currentRoster.tightEnds.add(fantasyPlayer)
                    true
                } else false
            }
            "K" -> {
                if (currentRoster.kickers.size < FantasyRoster.MAX_KS) {
                    currentRoster.kickers.add(fantasyPlayer)
                    true
                } else false
            }
            "DEF" -> {
                if (currentRoster.defense.size < FantasyRoster.MAX_DEF) {
                    currentRoster.defense.add(fantasyPlayer)
                    true
                } else false
            }
            else -> false // Unknown position
        }

        if (success) {
            _rosterChanges.value += 1
            saveRoster()
        }

        return success
    }

    /**
     * Remove a player from the roster
     */
    fun removePlayer(player: FantasyPlayer) {
        val currentRoster = _roster.value

        currentRoster.quarterbacks.removeAll { it.id == player.id }
        currentRoster.runningBacks.removeAll { it.id == player.id }
        currentRoster.wideReceivers.removeAll { it.id == player.id }
        currentRoster.tightEnds.removeAll { it.id == player.id }
        currentRoster.kickers.removeAll { it.id == player.id }
        currentRoster.defense.removeAll { it.id == player.id }

        _rosterChanges.value += 1
        saveRoster()
    }

    /**
     * Check if player is on roster
     */
    fun isOnRoster(playerId: String): Boolean {
        return _roster.value.allPlayers.any { it.id == playerId }
    }

    /**
     * Check if position is full
     */
    fun isPositionFull(position: String): Boolean {
        val currentRoster = _roster.value
        return when (position) {
            "QB" -> currentRoster.quarterbacks.size >= FantasyRoster.MAX_QBS
            "RB" -> currentRoster.runningBacks.size >= FantasyRoster.MAX_RBS
            "WR" -> currentRoster.wideReceivers.size >= FantasyRoster.MAX_WRS
            "TE" -> currentRoster.tightEnds.size >= FantasyRoster.MAX_TES
            "K" -> currentRoster.kickers.size >= FantasyRoster.MAX_KS
            "DEF" -> currentRoster.defense.size >= FantasyRoster.MAX_DEF
            else -> true
        }
    }

    /**
     * Clear entire roster
     */
    fun clearRoster() {
        _roster.value = FantasyRoster()
        _rosterChanges.value += 1
        saveRoster()
    }

    private fun saveRoster() {
        val json = _roster.value.toJson()
        prefs.edit().putString(KEY_ROSTER, json).apply()
    }

    private fun loadRoster(): FantasyRoster {
        val json = prefs.getString(KEY_ROSTER, null)
        return if (json != null) {
            FantasyRoster.fromJson(json) ?: FantasyRoster()
        } else {
            FantasyRoster()
        }
    }

    private fun loadTeamName(): String {
        return prefs.getString(KEY_TEAM_NAME, DEFAULT_TEAM_NAME) ?: DEFAULT_TEAM_NAME
    }
}
