package com.statshark.nfl.data.cache

import com.statshark.nfl.data.model.GameDTO

/**
 * Simple in-memory cache for GameDTO objects
 * Used to pass game data between screens without re-fetching
 */
object GameCache {
    private val cache = mutableMapOf<String, GameDTO>()

    fun put(game: GameDTO) {
        cache[game.id] = game
    }

    fun get(id: String): GameDTO? {
        return cache[id]
    }

    fun clear() {
        cache.clear()
    }
}
