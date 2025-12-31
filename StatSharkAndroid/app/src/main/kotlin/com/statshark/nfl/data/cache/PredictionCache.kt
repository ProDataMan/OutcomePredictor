package com.statshark.nfl.data.cache

import com.statshark.nfl.data.model.GameDTO
import com.statshark.nfl.data.model.PredictionDTO

/**
 * Simple in-memory cache for PredictionDTO objects
 * Used to pass prediction data between screens
 */
object PredictionCache {
    private val cache = mutableMapOf<String, Pair<GameDTO, PredictionDTO>>()

    fun put(gameId: String, game: GameDTO, prediction: PredictionDTO) {
        cache[gameId] = game to prediction
    }

    fun get(gameId: String): Pair<GameDTO, PredictionDTO>? {
        return cache[gameId]
    }

    fun clear() {
        cache.clear()
    }
}
