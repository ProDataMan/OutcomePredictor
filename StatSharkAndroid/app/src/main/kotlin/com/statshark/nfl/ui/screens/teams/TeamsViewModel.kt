package com.statshark.nfl.ui.screens.teams

import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import com.statshark.nfl.data.model.TeamDTO
import com.statshark.nfl.data.repository.NFLRepository
import dagger.hilt.android.lifecycle.HiltViewModel
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.launch
import javax.inject.Inject

/**
 * UI State for Teams Screen
 */
data class TeamsUiState(
    val teams: List<TeamDTO> = emptyList(),
    val filteredTeams: List<TeamDTO> = emptyList(),
    val isLoading: Boolean = false,
    val error: String? = null,
    val selectedFilter: ConferenceFilter = ConferenceFilter.ALL,
    val searchQuery: String = ""
)

/**
 * Conference filter options
 */
enum class ConferenceFilter {
    ALL, NFC, AFC
}

/**
 * Teams ViewModel
 * Manages state for the Teams screen
 */
@HiltViewModel
class TeamsViewModel @Inject constructor(
    private val repository: NFLRepository
) : ViewModel() {

    private val _uiState = MutableStateFlow(TeamsUiState())
    val uiState: StateFlow<TeamsUiState> = _uiState.asStateFlow()

    init {
        loadTeams()
    }

    /**
     * Load teams from API
     */
    fun loadTeams(forceRefresh: Boolean = false) {
        viewModelScope.launch {
            _uiState.value = _uiState.value.copy(isLoading = true, error = null)

            repository.getTeams(forceRefresh).fold(
                onSuccess = { teams ->
                    _uiState.value = _uiState.value.copy(
                        teams = teams.sortedBy { it.name },
                        filteredTeams = applyFilters(teams, _uiState.value.selectedFilter, _uiState.value.searchQuery),
                        isLoading = false
                    )
                },
                onFailure = { error ->
                    _uiState.value = _uiState.value.copy(
                        isLoading = false,
                        error = error.message ?: "Failed to load teams"
                    )
                }
            )
        }
    }

    /**
     * Apply conference filter
     */
    fun setFilter(filter: ConferenceFilter) {
        _uiState.value = _uiState.value.copy(
            selectedFilter = filter,
            filteredTeams = applyFilters(_uiState.value.teams, filter, _uiState.value.searchQuery)
        )
    }

    /**
     * Update search query
     */
    fun setSearchQuery(query: String) {
        _uiState.value = _uiState.value.copy(
            searchQuery = query,
            filteredTeams = applyFilters(_uiState.value.teams, _uiState.value.selectedFilter, query)
        )
    }

    /**
     * Apply filters and search to teams
     */
    private fun applyFilters(teams: List<TeamDTO>?, filter: ConferenceFilter, searchQuery: String): List<TeamDTO> {
        if (teams == null) return emptyList()

        var filtered = when (filter) {
            ConferenceFilter.ALL -> teams
            ConferenceFilter.NFC -> teams.filter { it.conference == "NFC" }
            ConferenceFilter.AFC -> teams.filter { it.conference == "AFC" }
        }

        // Apply search
        if (searchQuery.isNotBlank()) {
            filtered = filtered.filter {
                it.name.contains(searchQuery, ignoreCase = true) ||
                it.abbreviation.contains(searchQuery, ignoreCase = true)
            }
        }

        return filtered.sortedBy { it.name }
    }

    /**
     * Retry loading teams
     */
    fun retry() {
        loadTeams(forceRefresh = true)
    }

    /**
     * Clear error
     */
    fun clearError() {
        _uiState.value = _uiState.value.copy(error = null)
    }
}
