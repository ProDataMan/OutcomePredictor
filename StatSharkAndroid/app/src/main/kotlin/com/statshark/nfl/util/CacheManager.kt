package com.statshark.nfl.util

import android.content.Context
import android.graphics.Bitmap
import android.graphics.BitmapFactory
import androidx.core.graphics.drawable.toBitmap
import coil.ImageLoader
import coil.disk.DiskCache
import coil.memory.MemoryCache
import coil.request.CachePolicy
import coil.util.DebugLogger
import okhttp3.OkHttpClient
import java.io.File

/**
 * Image Cache Utilities
 * Provides aggressive caching for team helmets and player images
 */
object ImageCacheManager {

    private const val CACHE_SIZE_MB = 100L
    private const val DISK_CACHE_DIR = "image_cache"
    private const val MEMORY_CACHE_PERCENT = 0.25

    /**
     * Creates an optimized ImageLoader with aggressive caching
     */
    fun createImageLoader(context: Context): ImageLoader {
        return ImageLoader.Builder(context)
            .memoryCache {
                MemoryCache.Builder(context)
                    .maxSizePercent(MEMORY_CACHE_PERCENT)
                    .build()
            }
            .diskCache {
                DiskCache.Builder()
                    .directory(File(context.cacheDir, DISK_CACHE_DIR))
                    .maxSizeBytes(CACHE_SIZE_MB * 1024 * 1024)
                    .build()
            }
            .respectCacheHeaders(false) // Cache aggressively
            .okHttpClient {
                OkHttpClient.Builder()
                    .cache(
                        okhttp3.Cache(
                            directory = File(context.cacheDir, "http_cache"),
                            maxSize = 50L * 1024 * 1024 // 50 MB
                        )
                    )
                    .build()
            }
            .logger(DebugLogger())
            .build()
    }

    /**
     * Pre-cache team helmet images
     */
    suspend fun precacheTeamHelmets(context: Context, imageLoader: ImageLoader) {
        val teamAbbreviations = listOf(
            "ARI", "ATL", "BAL", "BUF", "CAR", "CHI", "CIN", "CLE",
            "DAL", "DEN", "DET", "GB", "HOU", "IND", "JAX", "KC",
            "LAC", "LAR", "LV", "MIA", "MIN", "NE", "NO", "NYG",
            "NYJ", "PHI", "PIT", "SEA", "SF", "TB", "TEN", "WAS"
        )

        // Helmet images are already in drawable resources
        // They're automatically cached by the system
        // This is just a placeholder for future remote image caching if needed
    }

    /**
     * Get placeholder for player image based on team
     */
    fun getTeamHelmetPlaceholder(teamAbbreviation: String, context: Context): Int? {
        return when (teamAbbreviation.uppercase()) {
            "ARI" -> com.statshark.nfl.R.drawable.team_ari
            "ATL" -> com.statshark.nfl.R.drawable.team_atl
            "BAL" -> com.statshark.nfl.R.drawable.team_bal
            "BUF" -> com.statshark.nfl.R.drawable.team_buf
            "CAR" -> com.statshark.nfl.R.drawable.team_car
            "CHI" -> com.statshark.nfl.R.drawable.team_chi
            "CIN" -> com.statshark.nfl.R.drawable.team_cin
            "CLE" -> com.statshark.nfl.R.drawable.team_cle
            "DAL" -> com.statshark.nfl.R.drawable.team_dal
            "DEN" -> com.statshark.nfl.R.drawable.team_den
            "DET" -> com.statshark.nfl.R.drawable.team_det
            "GB" -> com.statshark.nfl.R.drawable.team_gb
            "HOU" -> com.statshark.nfl.R.drawable.team_hou
            "IND" -> com.statshark.nfl.R.drawable.team_ind
            "JAX" -> com.statshark.nfl.R.drawable.team_jax
            "KC" -> com.statshark.nfl.R.drawable.team_kc
            "LAC" -> com.statshark.nfl.R.drawable.team_lac
            "LAR" -> com.statshark.nfl.R.drawable.team_lar
            "LV" -> com.statshark.nfl.R.drawable.team_lv
            "MIA" -> com.statshark.nfl.R.drawable.team_mia
            "MIN" -> com.statshark.nfl.R.drawable.team_min
            "NE" -> com.statshark.nfl.R.drawable.team_ne
            "NO" -> com.statshark.nfl.R.drawable.team_no
            "NYG" -> com.statshark.nfl.R.drawable.team_nyg
            "NYJ" -> com.statshark.nfl.R.drawable.team_nyj
            "PHI" -> com.statshark.nfl.R.drawable.team_phi
            "PIT" -> com.statshark.nfl.R.drawable.team_pit
            "SEA" -> com.statshark.nfl.R.drawable.team_sea
            "SF" -> com.statshark.nfl.R.drawable.team_sf
            "TB" -> com.statshark.nfl.R.drawable.team_tb
            "TEN" -> com.statshark.nfl.R.drawable.team_ten
            "WAS" -> com.statshark.nfl.R.drawable.team_was
            else -> com.statshark.nfl.R.drawable.ic_helmet_placeholder
        }
    }
}

/**
 * Data Cache Manager
 * Caches team and player stats locally
 */
object DataCacheManager {

    private const val CACHE_VALIDITY_MS = 6 * 60 * 60 * 1000L // 6 hours

    data class CachedData<T>(
        val data: T,
        val timestamp: Long = System.currentTimeMillis()
    ) {
        fun isValid(): Boolean {
            return System.currentTimeMillis() - timestamp < CACHE_VALIDITY_MS
        }
    }

    private val teamsCache = mutableMapOf<String, CachedData<Any>>()
    private val playersCache = mutableMapOf<String, CachedData<Any>>()
    private val statsCache = mutableMapOf<String, CachedData<Any>>()

    fun <T> cacheTeamData(key: String, data: T) {
        teamsCache[key] = CachedData(data as Any)
    }

    @Suppress("UNCHECKED_CAST")
    fun <T> getTeamData(key: String): T? {
        val cached = teamsCache[key]
        return if (cached != null && cached.isValid()) {
            cached.data as? T
        } else {
            teamsCache.remove(key)
            null
        }
    }

    fun <T> cachePlayerData(playerId: String, data: T) {
        playersCache[playerId] = CachedData(data as Any)
    }

    @Suppress("UNCHECKED_CAST")
    fun <T> getPlayerData(playerId: String): T? {
        val cached = playersCache[playerId]
        return if (cached != null && cached.isValid()) {
            cached.data as? T
        } else {
            playersCache.remove(playerId)
            null
        }
    }

    fun <T> cacheStats(key: String, data: T) {
        statsCache[key] = CachedData(data as Any)
    }

    @Suppress("UNCHECKED_CAST")
    fun <T> getStats(key: String): T? {
        val cached = statsCache[key]
        return if (cached != null && cached.isValid()) {
            cached.data as? T
        } else {
            statsCache.remove(key)
            null
        }
    }

    fun clearExpiredCache() {
        teamsCache.entries.removeAll { !it.value.isValid() }
        playersCache.entries.removeAll { !it.value.isValid() }
        statsCache.entries.removeAll { !it.value.isValid() }
    }

    fun clearAllCache() {
        teamsCache.clear()
        playersCache.clear()
        statsCache.clear()
    }
}
