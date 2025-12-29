package com.statshark.nfl.ui.screens.teams

import androidx.lifecycle.SavedStateHandle
import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import com.statshark.nfl.data.model.ArticleDTO
import com.statshark.nfl.data.model.GameDTO
import com.statshark.nfl.data.model.PlayerDTO
import com.statshark.nfl.data.model.TeamDTO
import com.statshark.nfl.data.repository.NFLRepository
import dagger.hilt.android.lifecycle.HiltViewModel
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.launch
import java.util.Calendar
import javax.inject.Inject

/**
 * UI State for Team Detail Screen
 */
data class TeamDetailUiState(
    val team: TeamDTO? = null,
    val players: List<PlayerDTO> = emptyList(),
    val games: List<GameDTO> = emptyList(),
    val news: List<ArticleDTO> = emptyList(),
    val selectedSeason: Int = Calendar.getInstance().get(Calendar.YEAR),
    val isLoadingRoster: Boolean = false,
    val isLoadingGames: Boolean = false,
    val isLoadingNews: Boolean = false,
    val rosterError: String? = null,
    val gamesError: String? = null,
    val newsError: String? = null
)

/**
 * Team Detail ViewModel
 * Manages state for the Team Detail screen
 */
@HiltViewModel
class TeamDetailViewModel @Inject constructor(
    private val repository: NFLRepository,
    savedStateHandle: SavedStateHandle
) : ViewModel() {

    private val teamId: String = checkNotNull(savedStateHandle["teamId"])

    private val _uiState = MutableStateFlow(TeamDetailUiState())
    val uiState: StateFlow<TeamDetailUiState> = _uiState.asStateFlow()

    init {
        loadTeamData()
    }

    /**
     * Load all team data
     */
    private fun loadTeamData() {
        // Find team from cached teams list
        viewModelScope.launch {
            repository.getTeams().fold(
                onSuccess = { teams ->
                    val team = teams.find { it.abbreviation == teamId }
                    _uiState.value = _uiState.value.copy(team = team)

                    if (team != null) {
                        loadRoster(team.abbreviation, _uiState.value.selectedSeason)
                        loadGames(team.abbreviation, _uiState.value.selectedSeason)
                        loadNews(team.abbreviation)
                    }
                },
                onFailure = {
                    // Team not found
                }
            )
        }
    }

    /**
     * Load team roster
     */
    fun loadRoster(teamId: String, season: Int) {
        viewModelScope.launch {
            _uiState.value = _uiState.value.copy(isLoadingRoster = true, rosterError = null)

            repository.getTeamRoster(teamId, season).fold(
                onSuccess = { rosterDTO ->
                    _uiState.value = _uiState.value.copy(
                        players = rosterDTO.players,
                        isLoadingRoster = false
                    )
                },
                onFailure = { error ->
                    _uiState.value = _uiState.value.copy(
                        isLoadingRoster = false,
                        rosterError = error.message ?: "Failed to load roster"
                    )
                }
            )
        }
    }

    /**
     * Load team games
     */
    fun loadGames(team: String, season: Int) {
        viewModelScope.launch {
            _uiState.value = _uiState.value.copy(isLoadingGames = true, gamesError = null)

            repository.getTeamGames(team, season).fold(
                onSuccess = { games ->
                    _uiState.value = _uiState.value.copy(
                        games = games.sortedByDescending { it.date },
                        isLoadingGames = false
                    )
                },
                onFailure = { error ->
                    _uiState.value = _uiState.value.copy(
                        isLoadingGames = false,
                        gamesError = error.message ?: "Failed to load games"
                    )
                }
            )
        }
    }

    /**
     * Load team news
     */
    fun loadNews(team: String) {
        viewModelScope.launch {
            _uiState.value = _uiState.value.copy(isLoadingNews = true, newsError = null)

            repository.getTeamNews(team, limit = 10).fold(
                onSuccess = { articles ->
                    _uiState.value = _uiState.value.copy(
                        news = articles,
                        isLoadingNews = false
                    )
                },
                onFailure = { error ->
                    _uiState.value = _uiState.value.copy(
                        isLoadingNews = false,
                        newsError = error.message ?: "Failed to load news"
                    )
                }
            )
        }
    }

    /**
     * Change season
     */
    fun changeSeason(season: Int) {
        _uiState.value = _uiState.value.copy(selectedSeason = season)
        _uiState.value.team?.let { team ->
            loadRoster(team.abbreviation, season)
            loadGames(team.abbreviation, season)
        }
    }

    /**
     * Retry loading data
     */
    fun retry() {
        _uiState.value.team?.let { team ->
            if (_uiState.value.rosterError != null) {
                loadRoster(team.abbreviation, _uiState.value.selectedSeason)
            }
            if (_uiState.value.gamesError != null) {
                loadGames(team.abbreviation, _uiState.value.selectedSeason)
            }
            if (_uiState.value.newsError != null) {
                loadNews(team.abbreviation)
            }
        }
    }
}
