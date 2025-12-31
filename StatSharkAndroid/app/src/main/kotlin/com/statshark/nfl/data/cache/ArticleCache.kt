package com.statshark.nfl.data.cache

import com.statshark.nfl.data.model.ArticleDTO

/**
 * Simple in-memory cache for ArticleDTO objects
 * Used to pass article data between screens
 */
object ArticleCache {
    private val cache = mutableMapOf<String, ArticleDTO>()

    fun put(article: ArticleDTO) {
        cache[article.id] = article
    }

    fun get(id: String): ArticleDTO? {
        return cache[id]
    }

    fun clear() {
        cache.clear()
    }
}
