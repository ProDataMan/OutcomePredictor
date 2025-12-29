package com.statshark.nfl.ui.screens.predictions

import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import com.statshark.nfl.data.model.GameDTO
import com.statshark.nfl.data.model.PredictionDTO
import com.statshark.nfl.data.repository.NFLRepository
import dagger.hilt.android.lifecycle.HiltViewModel
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.launch
import javax.inject.Inject

/**
 * UI State for Predictions Screen
 */
data class PredictionsUiState(
    val upcomingGames: List<GameDTO> = emptyList(),
    val predictions: Map<String, PredictionDTO> = emptyMap(),
    val isLoadingGames: Boolean = false,
    val gamesError: String? = null,
    val loadingPredictions: Set<String> = emptySet(),
    val predictionErrors: Map<String, String> = emptyMap()
)

/**
 * Predictions ViewModel
 * Manages state for AI predictions screen
 */
@HiltViewModel
class PredictionsViewModel @Inject constructor(
    private val repository: NFLRepository
) : ViewModel() {

    private val _uiState = MutableStateFlow(PredictionsUiState())
    val uiState: StateFlow<PredictionsUiState> = _uiState.asStateFlow()

    init {
        loadUpcomingGames()
    }

    /**
     * Load upcoming games
     */
    fun loadUpcomingGames() {
        viewModelScope.launch {
            _uiState.value = _uiState.value.copy(isLoadingGames = true, gamesError = null)

            repository.getUpcomingGames().fold(
                onSuccess = { games ->
                    _uiState.value = _uiState.value.copy(
                        upcomingGames = games,
                        isLoadingGames = false
                    )
                },
                onFailure = { error ->
                    _uiState.value = _uiState.value.copy(
                        isLoadingGames = false,
                        gamesError = error.message ?: "Failed to load upcoming games"
                    )
                }
            )
        }
    }

    /**
     * Make prediction for a game
     */
    fun makePrediction(game: GameDTO) {
        viewModelScope.launch {
            val gameId = game.id
            _uiState.value = _uiState.value.copy(
                loadingPredictions = _uiState.value.loadingPredictions + gameId,
                predictionErrors = _uiState.value.predictionErrors - gameId
            )

            repository.makePrediction(
                homeTeam = game.homeTeam.abbreviation,
                awayTeam = game.awayTeam.abbreviation,
                season = game.season,
                week = game.week
            ).fold(
                onSuccess = { prediction ->
                    _uiState.value = _uiState.value.copy(
                        predictions = _uiState.value.predictions + (gameId to prediction),
                        loadingPredictions = _uiState.value.loadingPredictions - gameId
                    )
                },
                onFailure = { error ->
                    _uiState.value = _uiState.value.copy(
                        loadingPredictions = _uiState.value.loadingPredictions - gameId,
                        predictionErrors = _uiState.value.predictionErrors + (gameId to (error.message ?: "Prediction failed"))
                    )
                }
            )
        }
    }

    /**
     * Retry loading games
     */
    fun retry() {
        loadUpcomingGames()
    }
}
