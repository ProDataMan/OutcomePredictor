package com.statshark.nfl.data.cache

import com.statshark.nfl.data.model.PlayerDTO

/**
 * Simple in-memory cache for passing player data through navigation
 * This avoids having to serialize/deserialize complex objects in navigation args
 */
object PlayerCache {
    private val cache = mutableMapOf<String, PlayerDTO>()

    fun put(player: PlayerDTO) {
        cache[player.id] = player
    }

    fun get(playerId: String): PlayerDTO? {
        return cache[playerId]
    }

    fun clear() {
        cache.clear()
    }
}
