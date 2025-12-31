package com.statshark.nfl.data.manager

import android.content.Context
import com.statshark.nfl.data.model.*
import dagger.hilt.android.qualifiers.ApplicationContext
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.serialization.encodeToString
import kotlinx.serialization.json.Json
import javax.inject.Inject
import javax.inject.Singleton

/**
 * Fantasy League Manager
 * Handles league creation, joining, and management
 * Matches iOS FantasyLeagueManager implementation
 */
@Singleton
class FantasyLeagueManager @Inject constructor(
    @ApplicationContext private val context: Context
) {
    private val prefs = context.getSharedPreferences("fantasy_leagues", Context.MODE_PRIVATE)
    private val json = Json { ignoreUnknownKeys = true }

    private val _leagues = MutableStateFlow<List<FantasyLeague>>(emptyList())
    val leagues: StateFlow<List<FantasyLeague>> = _leagues.asStateFlow()

    private val _currentLeague = MutableStateFlow<FantasyLeague?>(null)
    val currentLeague: StateFlow<FantasyLeague?> = _currentLeague.asStateFlow()

    // Payment feature flag - disable until 1000 downloads
    companion object {
        const val PAYMENTS_ENABLED = false
        const val MINIMUM_DOWNLOADS_FOR_PAYMENTS = 1000
    }

    init {
        loadLeagues()
        loadCurrentLeague()
    }

    /**
     * Create a new league
     */
    fun createLeague(league: FantasyLeague) {
        val updated = _leagues.value + league
        _leagues.value = updated
        _currentLeague.value = league
        saveLeagues()
        saveCurrentLeague()
    }

    /**
     * Join an existing league via invite code
     */
    fun joinLeague(inviteCode: String, userName: String, roster: FantasyRoster): Boolean {
        val leagueIndex = _leagues.value.indexOfFirst { it.inviteCode == inviteCode }
        if (leagueIndex == -1) return false

        val league = _leagues.value[leagueIndex]
        val member = LeagueMember(
            name = userName,
            roster = roster,
            joinedAt = System.currentTimeMillis()
        )

        val updatedLeague = league.copy(
            members = league.members + member
        )

        val updatedLeagues = _leagues.value.toMutableList()
        updatedLeagues[leagueIndex] = updatedLeague

        _leagues.value = updatedLeagues
        _currentLeague.value = updatedLeague
        saveLeagues()
        saveCurrentLeague()

        return true
    }

    /**
     * Leave a league
     */
    fun leaveLeague(leagueId: String) {
        val updated = _leagues.value.filter { it.id != leagueId }
        _leagues.value = updated

        if (_currentLeague.value?.id == leagueId) {
            _currentLeague.value = updated.firstOrNull()
            saveCurrentLeague()
        }

        saveLeagues()
    }

    /**
     * Update league name
     */
    fun updateLeagueName(leagueId: String, name: String) {
        val trimmed = name.trim()
        if (trimmed.isEmpty()) return

        val leagueIndex = _leagues.value.indexOfFirst { it.id == leagueId }
        if (leagueIndex == -1) return

        val updatedLeagues = _leagues.value.toMutableList()
        updatedLeagues[leagueIndex] = updatedLeagues[leagueIndex].copy(name = trimmed)

        _leagues.value = updatedLeagues

        // Update current league if it's the one being edited
        if (_currentLeague.value?.id == leagueId) {
            _currentLeague.value = updatedLeagues[leagueIndex]
        }

        saveLeagues()
    }

    /**
     * Set current league
     */
    fun setCurrentLeague(league: FantasyLeague) {
        _currentLeague.value = league
        saveCurrentLeague()
    }

    /**
     * Update league standings based on weekly scores
     */
    fun updateStandings(league: FantasyLeague) {
        // Calculate standings based on fantasy points
        // This will be implemented when we have weekly scoring
    }

    private fun loadLeagues() {
        val jsonString = prefs.getString("leagues", null)
        if (jsonString != null) {
            try {
                val loaded = json.decodeFromString<List<FantasyLeague>>(jsonString)
                _leagues.value = loaded
            } catch (e: Exception) {
                _leagues.value = emptyList()
            }
        }
    }

    private fun loadCurrentLeague() {
        val leagueId = prefs.getString("current_league_id", null)
        if (leagueId != null) {
            _currentLeague.value = _leagues.value.firstOrNull { it.id == leagueId }
        }

        if (_currentLeague.value == null) {
            _currentLeague.value = _leagues.value.firstOrNull()
        }
    }

    private fun saveLeagues() {
        val jsonString = json.encodeToString(_leagues.value)
        prefs.edit().putString("leagues", jsonString).apply()
    }

    private fun saveCurrentLeague() {
        val leagueId = _currentLeague.value?.id
        if (leagueId != null) {
            prefs.edit().putString("current_league_id", leagueId).apply()
        }
    }
}
