package com.statshark.nfl.ui.screens.standings

import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import com.statshark.nfl.data.model.DivisionStandings
import com.statshark.nfl.data.model.LeagueStandings
import com.statshark.nfl.data.model.TeamStandings
import com.statshark.nfl.data.repository.NFLRepository
import dagger.hilt.android.lifecycle.HiltViewModel
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.launch
import java.util.*
import javax.inject.Inject

/**
 * Sort options for standings
 */
enum class StandingsSortOption(val displayName: String) {
    WIN_PERCENTAGE("Win %"),
    POINTS_FOR("Points For"),
    POINTS_AGAINST("Points Against"),
    STREAK("Streak")
}

/**
 * UI State for Standings Screen
 */
data class StandingsUiState(
    val standings: LeagueStandings? = null,
    val isLoading: Boolean = false,
    val error: String? = null,
    val selectedConference: String = "AFC",
    val sortOption: StandingsSortOption = StandingsSortOption.WIN_PERCENTAGE
) {
    val displayedDivisions: List<DivisionStandings>
        get() {
            val divisions = when (selectedConference) {
                "AFC" -> standings?.afcStandings ?: emptyList()
                "NFC" -> standings?.nfcStandings ?: emptyList()
                else -> emptyList()
            }

            return divisions.map { division ->
                val sortedTeams = when (sortOption) {
                    StandingsSortOption.WIN_PERCENTAGE ->
                        division.teams.sortedWith(
                            compareByDescending<TeamStandings> { it.winPercentage }
                                .thenByDescending { it.wins }
                        )
                    StandingsSortOption.POINTS_FOR ->
                        division.teams.sortedByDescending { it.pointsFor }
                    StandingsSortOption.POINTS_AGAINST ->
                        division.teams.sortedBy { it.pointsAgainst }
                    StandingsSortOption.STREAK ->
                        division.teams.sortedWith { t1, t2 -> compareStreak(t1.streak, t2.streak) }
                }
                DivisionStandings(
                    conference = division.conference,
                    division = division.division,
                    teams = sortedTeams
                )
            }
        }

    private fun compareStreak(s1: String, s2: String): Int {
        if (s1 == "-" || s2 == "-") return s1.compareTo(s2)

        val num1 = s1.drop(1).toIntOrNull() ?: 0
        val num2 = s2.drop(1).toIntOrNull() ?: 0
        val isWin1 = s1.startsWith("W")
        val isWin2 = s2.startsWith("W")

        return when {
            isWin1 && !isWin2 -> -1
            !isWin1 && isWin2 -> 1
            else -> num2.compareTo(num1)
        }
    }
}

/**
 * Standings ViewModel
 * Loads and manages standings data
 */
@HiltViewModel
class StandingsViewModel @Inject constructor(
    private val repository: NFLRepository
) : ViewModel() {

    private val _uiState = MutableStateFlow(StandingsUiState())
    val uiState: StateFlow<StandingsUiState> = _uiState.asStateFlow()

    init {
        loadStandings()
    }

    fun selectConference(conference: String) {
        _uiState.value = _uiState.value.copy(selectedConference = conference)
    }

    fun setSortOption(option: StandingsSortOption) {
        _uiState.value = _uiState.value.copy(sortOption = option)
    }

    fun loadStandings() {
        viewModelScope.launch {
            _uiState.value = _uiState.value.copy(isLoading = true, error = null)

            val currentSeason = Calendar.getInstance().get(Calendar.YEAR)
            repository.getStandings(currentSeason).fold(
                onSuccess = { standings ->
                    _uiState.value = _uiState.value.copy(
                        standings = standings,
                        isLoading = false,
                        error = null
                    )
                },
                onFailure = { exception ->
                    _uiState.value = _uiState.value.copy(
                        isLoading = false,
                        error = exception.message ?: "Failed to load standings"
                    )
                }
            )
        }
    }

    fun retry() {
        loadStandings()
    }
}
