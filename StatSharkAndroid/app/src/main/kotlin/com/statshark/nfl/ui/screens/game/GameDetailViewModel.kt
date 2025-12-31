package com.statshark.nfl.ui.screens.game

import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import com.statshark.nfl.data.model.GameDTO
import com.statshark.nfl.data.model.PredictionDTO
import com.statshark.nfl.data.repository.NFLRepository
import dagger.hilt.android.lifecycle.HiltViewModel
import kotlinx.coroutines.Job
import kotlinx.coroutines.delay
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.isActive
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

    private var liveScoreJob: Job? = null

    fun setGame(game: GameDTO) {
        _uiState.value = _uiState.value.copy(game = game)

        // Load prediction for future games
        if (!isGameCompleted(game)) {
            loadPrediction(game)
        }

        // Start live score updates for in-progress games
        if (isGameInProgress(game)) {
            startLiveScoreUpdates()
        }
    }

    override fun onCleared() {
        super.onCleared()
        stopLiveScoreUpdates()
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

    private fun isGameInProgress(game: GameDTO): Boolean {
        // Game is in progress if it has started but not completed
        // We can check if current time is past scheduled date but game not completed
        return !isGameCompleted(game) // For now, simplified check
    }

    private fun startLiveScoreUpdates() {
        // Cancel any existing job
        stopLiveScoreUpdates()

        // Start polling every 30 seconds
        liveScoreJob = viewModelScope.launch {
            while (isActive) {
                delay(30_000) // 30 seconds
                refreshGameData()
            }
        }
    }

    private fun stopLiveScoreUpdates() {
        liveScoreJob?.cancel()
        liveScoreJob = null
    }

    private suspend fun refreshGameData() {
        val currentGame = _uiState.value.game ?: return

        repository.getUpcomingGames().fold(
            onSuccess = { games ->
                // Find our game in the list
                val updatedGame = games.firstOrNull { game ->
                    game.homeTeam.abbreviation == currentGame.homeTeam.abbreviation &&
                    game.awayTeam.abbreviation == currentGame.awayTeam.abbreviation &&
                    game.week == currentGame.week &&
                    game.season == currentGame.season
                }

                if (updatedGame != null) {
                    _uiState.value = _uiState.value.copy(game = updatedGame)

                    // Stop polling if game is now completed
                    if (isGameCompleted(updatedGame)) {
                        stopLiveScoreUpdates()
                    }
                }
            },
            onFailure = {
                // Silently fail - we'll try again on next interval
            }
        )
    }
}
