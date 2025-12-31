package com.statshark.nfl.ui.screens.standings

import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import com.statshark.nfl.data.model.DivisionStandings
import com.statshark.nfl.data.model.LeagueStandings
import com.statshark.nfl.data.repository.NFLRepository
import dagger.hilt.android.lifecycle.HiltViewModel
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.launch
import java.util.*
import javax.inject.Inject

/**
 * UI State for Standings Screen
 */
data class StandingsUiState(
    val standings: LeagueStandings? = null,
    val isLoading: Boolean = false,
    val error: String? = null,
    val selectedConference: String = "AFC"
) {
    val displayedDivisions: List<DivisionStandings>
        get() = when (selectedConference) {
            "AFC" -> standings?.afcStandings ?: emptyList()
            "NFC" -> standings?.nfcStandings ?: emptyList()
            else -> emptyList()
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
