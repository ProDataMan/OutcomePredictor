package com.statshark.nfl.ui.screens.fantasy

import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import com.statshark.nfl.data.manager.FantasyTeamManager
import com.statshark.nfl.data.model.FantasyPlayer
import com.statshark.nfl.data.model.FantasyRoster
import com.statshark.nfl.data.model.PlayerDTO
import com.statshark.nfl.data.model.TeamDTO
import com.statshark.nfl.data.model.TeamRosterDTO
import com.statshark.nfl.data.repository.NFLRepository
import dagger.hilt.android.lifecycle.HiltViewModel
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.SharingStarted
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.flow.combine
import kotlinx.coroutines.flow.stateIn
import kotlinx.coroutines.launch
import java.util.Calendar
import javax.inject.Inject

/**
 * Fantasy Screen ViewModel
 * Manages fantasy team state and player search
 */
@HiltViewModel
class FantasyViewModel @Inject constructor(
    private val repository: NFLRepository,
    private val fantasyManager: FantasyTeamManager
) : ViewModel() {

    private val _uiState = MutableStateFlow(FantasyUiState())
    val uiState: StateFlow<FantasyUiState> = combine(
        _uiState,
        fantasyManager.roster,
        fantasyManager.rosterChanges
    ) { state, roster, _ ->
        state.copy(roster = roster)
    }.stateIn(
        viewModelScope,
        SharingStarted.WhileSubscribed(5000),
        FantasyUiState()
    )

    private val _teams = MutableStateFlow<List<TeamDTO>>(emptyList())
    val teams: StateFlow<List<TeamDTO>> = _teams.asStateFlow()

    private val _teamRoster = MutableStateFlow<TeamRosterDTO?>(null)
    val teamRoster: StateFlow<TeamRosterDTO?> = _teamRoster.asStateFlow()

    private val _allPositionPlayers = MutableStateFlow<List<Pair<PlayerDTO, TeamDTO>>>(emptyList())
    val allPositionPlayers: StateFlow<List<Pair<PlayerDTO, TeamDTO>>> = _allPositionPlayers.asStateFlow()

    init {
        loadTeams()
    }

    private fun loadTeams() {
        viewModelScope.launch {
            _uiState.value = _uiState.value.copy(isLoadingTeams = true)
            repository.getTeams().fold(
                onSuccess = {
                    _teams.value = it
                    _uiState.value = _uiState.value.copy(isLoadingTeams = false)
                },
                onFailure = {
                    _uiState.value = _uiState.value.copy(
                        isLoadingTeams = false,
                        error = "Failed to load teams: ${it.message}"
                    )
                }
            )
        }
    }

    fun loadTeamRoster(teamAbbreviation: String) {
        viewModelScope.launch {
            _uiState.value = _uiState.value.copy(isLoadingRoster = true, rosterError = null)
            val season = Calendar.getInstance().get(Calendar.YEAR)
            repository.getTeamRoster(teamAbbreviation, season).fold(
                onSuccess = {
                    _teamRoster.value = it
                    _uiState.value = _uiState.value.copy(isLoadingRoster = false)
                },
                onFailure = {
                    _uiState.value = _uiState.value.copy(
                        isLoadingRoster = false,
                        rosterError = "Failed to load roster: ${it.message}"
                    )
                }
            )
        }
    }

    fun loadAllPositionPlayers(position: String) {
        viewModelScope.launch {
            _uiState.value = _uiState.value.copy(isLoadingAllPlayers = true)
            _allPositionPlayers.value = emptyList()

            val allPlayers = mutableListOf<Pair<PlayerDTO, TeamDTO>>()
            val season = Calendar.getInstance().get(Calendar.YEAR)

            for (team in _teams.value) {
                repository.getTeamRoster(team.abbreviation, season).fold(
                    onSuccess = { roster ->
                        val positionPlayers = roster.players.filter { it.position == position }
                        positionPlayers.forEach { player ->
                            allPlayers.add(Pair(player, team))
                        }
                    },
                    onFailure = { /* Continue with other teams if one fails */ }
                )
            }

            // Sort by stats
            val sorted = when (position) {
                "QB" -> allPlayers.sortedByDescending { it.first.stats?.passingYards ?: 0 }
                "RB" -> allPlayers.sortedByDescending { it.first.stats?.rushingYards ?: 0 }
                "WR", "TE" -> allPlayers.sortedByDescending { it.first.stats?.receivingYards ?: 0 }
                else -> allPlayers
            }

            _allPositionPlayers.value = sorted
            _uiState.value = _uiState.value.copy(isLoadingAllPlayers = false)
        }
    }

    fun addPlayer(player: PlayerDTO, team: TeamDTO): Boolean {
        return fantasyManager.addPlayer(player, team)
    }

    fun removePlayer(player: FantasyPlayer) {
        fantasyManager.removePlayer(player)
    }

    fun isOnRoster(playerId: String): Boolean {
        return fantasyManager.isOnRoster(playerId)
    }

    fun isPositionFull(position: String): Boolean {
        return fantasyManager.isPositionFull(position)
    }

    fun clearRoster() {
        fantasyManager.clearRoster()
    }

    fun clearTeamRoster() {
        _teamRoster.value = null
    }

    fun clearAllPositionPlayers() {
        _allPositionPlayers.value = emptyList()
    }
}

data class FantasyUiState(
    val roster: FantasyRoster = FantasyRoster(),
    val isLoadingTeams: Boolean = false,
    val isLoadingRoster: Boolean = false,
    val isLoadingAllPlayers: Boolean = false,
    val error: String? = null,
    val rosterError: String? = null
)
