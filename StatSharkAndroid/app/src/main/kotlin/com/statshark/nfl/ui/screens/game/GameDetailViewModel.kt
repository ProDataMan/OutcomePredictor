package com.statshark.nfl.ui.screens.game

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
 * UI State for Game Detail Screen
 */
data class GameDetailUiState(
    val game: GameDTO? = null,
    val prediction: PredictionDTO? = null,
    val isLoadingPrediction: Boolean = false,
    val predictionError: String? = null
)

/**
 * Game Detail ViewModel
 */
@HiltViewModel
class GameDetailViewModel @Inject constructor(
    private val repository: NFLRepository
) : ViewModel() {

    private val _uiState = MutableStateFlow(GameDetailUiState())
    val uiState: StateFlow<GameDetailUiState> = _uiState.asStateFlow()

    fun setGame(game: GameDTO) {
        _uiState.value = _uiState.value.copy(game = game)

        // Load prediction for future games
        if (!isGameCompleted(game)) {
            loadPrediction(game)
        }
    }

    private fun loadPrediction(game: GameDTO) {
        viewModelScope.launch {
            _uiState.value = _uiState.value.copy(
                isLoadingPrediction = true,
                predictionError = null
            )

            repository.makePrediction(
                homeTeam = game.homeTeam.abbreviation,
                awayTeam = game.awayTeam.abbreviation,
                season = game.season,
                week = game.week
            ).fold(
                onSuccess = { prediction ->
                    _uiState.value = _uiState.value.copy(
                        prediction = prediction,
                        isLoadingPrediction = false
                    )
                },
                onFailure = { error ->
                    _uiState.value = _uiState.value.copy(
                        isLoadingPrediction = false,
                        predictionError = error.message ?: "Failed to load prediction"
                    )
                }
            )
        }
    }

    fun retryPrediction() {
        _uiState.value.game?.let { game ->
            loadPrediction(game)
        }
    }

    private fun isGameCompleted(game: GameDTO): Boolean {
        return game.homeScore != null && game.awayScore != null
    }
}
