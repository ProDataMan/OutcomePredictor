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
    val predictionErrors: Map<String, String> = emptyMap(),
    val selectedWeek: Int? = null,
    val minConfidence: Double = 0.0,
    val isLoadingBatch: Boolean = false,
    val batchProgress: Float = 0f,
    val preSelectedHomeTeam: String? = null,
    val preSelectedAwayTeam: String? = null
) {
    // Available weeks from games
    val availableWeeks: List<Int>
        get() = upcomingGames.mapNotNull { it.week }.distinct().sorted()

    // Current week (first week with games)
    val currentWeek: Int?
        get() = upcomingGames.firstOrNull()?.week

    // Filtered games by week, confidence, and pre-selection
    val filteredGames: List<GameDTO>
        get() {
            // If teams are pre-selected, show only that game
            if (preSelectedHomeTeam != null && preSelectedAwayTeam != null) {
                return upcomingGames.filter { game ->
                    (game.homeTeam.abbreviation == preSelectedHomeTeam && game.awayTeam.abbreviation == preSelectedAwayTeam) ||
                    (game.homeTeam.abbreviation == preSelectedAwayTeam && game.awayTeam.abbreviation == preSelectedHomeTeam)
                }
            }

            var games = if (selectedWeek == null) {
                upcomingGames
            } else {
                upcomingGames.filter { it.week == selectedWeek }
            }

            // Apply confidence filter
            if (minConfidence > 0) {
                games = games.filter { game ->
                    val prediction = predictions[game.id]
                    prediction != null && prediction.confidence >= minConfidence
                }
            }

            return games
        }
}

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
                    val errorMessage = when {
                        error.message?.contains("HTTP") == true -> {
                            "Server error: ${error.message}"
                        }
                        error.message?.contains("Unable to resolve host") == true -> {
                            "Network error: Cannot reach server. Check your connection."
                        }
                        error.message?.contains("timeout") == true -> {
                            "Request timed out. Server may be slow or unavailable."
                        }
                        error.message?.contains("JSON") == true -> {
                            "Data format error: ${error.message}"
                        }
                        else -> {
                            error.message ?: "Prediction failed: Unknown error"
                        }
                    }
                    _uiState.value = _uiState.value.copy(
                        loadingPredictions = _uiState.value.loadingPredictions - gameId,
                        predictionErrors = _uiState.value.predictionErrors + (gameId to errorMessage)
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

    /**
     * Update selected week filter
     */
    fun setSelectedWeek(week: Int?) {
        _uiState.value = _uiState.value.copy(selectedWeek = week)
    }

    /**
     * Update minimum confidence filter
     */
    fun setMinConfidence(confidence: Double) {
        _uiState.value = _uiState.value.copy(minConfidence = confidence)
    }

    /**
     * Predict all games in current filter
     */
    fun predictAllGames() {
        viewModelScope.launch {
            val games = if (_uiState.value.selectedWeek == null) {
                _uiState.value.upcomingGames
            } else {
                _uiState.value.upcomingGames.filter { it.week == _uiState.value.selectedWeek }
            }

            if (games.isEmpty()) return@launch

            _uiState.value = _uiState.value.copy(
                isLoadingBatch = true,
                batchProgress = 0f
            )

            val total = games.size.toFloat()

            games.forEachIndexed { index, game ->
                val gameId = game.id

                // Skip if already predicted
                if (_uiState.value.predictions.containsKey(gameId)) {
                    _uiState.value = _uiState.value.copy(
                        batchProgress = (index + 1) / total
                    )
                    return@forEachIndexed
                }

                repository.makePrediction(
                    homeTeam = game.homeTeam.abbreviation,
                    awayTeam = game.awayTeam.abbreviation,
                    season = game.season,
                    week = game.week
                ).fold(
                    onSuccess = { prediction ->
                        _uiState.value = _uiState.value.copy(
                            predictions = _uiState.value.predictions + (gameId to prediction),
                            batchProgress = (index + 1) / total
                        )
                    },
                    onFailure = { error ->
                        // Continue with other predictions even if one fails
                        val errorMessage = when {
                            error.message?.contains("HTTP") == true -> {
                                "Server error: ${error.message}"
                            }
                            error.message?.contains("Unable to resolve host") == true -> {
                                "Network error: Cannot reach server"
                            }
                            error.message?.contains("timeout") == true -> {
                                "Request timed out"
                            }
                            else -> {
                                error.message ?: "Prediction failed"
                            }
                        }
                        _uiState.value = _uiState.value.copy(
                            predictionErrors = _uiState.value.predictionErrors + (gameId to errorMessage),
                            batchProgress = (index + 1) / total
                        )
                    }
                )

                // Small delay to avoid overwhelming the server
                kotlinx.coroutines.delay(100)
            }

            _uiState.value = _uiState.value.copy(
                isLoadingBatch = false,
                batchProgress = 1f
            )
        }
    }

    /**
     * Pre-select teams and automatically make prediction
     * Called when navigating from team detail "Next Game" card
     */
    fun preSelectTeams(homeTeam: String, awayTeam: String) {
        viewModelScope.launch {
            // Set pre-selected teams in state to filter the games list
            _uiState.value = _uiState.value.copy(
                preSelectedHomeTeam = homeTeam,
                preSelectedAwayTeam = awayTeam
            )

            // Find the game matching these teams
            val game = _uiState.value.upcomingGames.firstOrNull {
                (it.homeTeam.abbreviation == homeTeam && it.awayTeam.abbreviation == awayTeam) ||
                (it.homeTeam.abbreviation == awayTeam && it.awayTeam.abbreviation == homeTeam)
            }

            // Automatically make prediction for this game if found
            game?.let { makePrediction(it) }
        }
    }
}
