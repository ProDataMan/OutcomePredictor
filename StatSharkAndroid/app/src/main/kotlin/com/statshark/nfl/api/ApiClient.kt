package com.statshark.nfl.api

import com.google.gson.Gson
import com.google.gson.GsonBuilder
import com.statshark.nfl.BuildConfig
import okhttp3.OkHttpClient
import okhttp3.logging.HttpLoggingInterceptor
import retrofit2.Retrofit
import retrofit2.converter.gson.GsonConverterFactory
import java.util.Date
import java.util.concurrent.TimeUnit

/**
 * API Client Configuration
 * Provides configured Retrofit instance for API calls
 */
object ApiClient {

    private const val BASE_URL = BuildConfig.API_BASE_URL

    /**
     * Custom Gson instance with date formatting
     */
    private val gson: Gson = GsonBuilder()
        .setDateFormat("yyyy-MM-dd'T'HH:mm:ss")
        .create()

    /**
     * OkHttpClient with extended timeouts for Azure cold starts
     */
    private val okHttpClient: OkHttpClient by lazy {
        val loggingInterceptor = HttpLoggingInterceptor().apply {
            level = if (BuildConfig.DEBUG) {
                HttpLoggingInterceptor.Level.BODY
            } else {
                HttpLoggingInterceptor.Level.NONE
            }
        }

        OkHttpClient.Builder()
            .connectTimeout(90, TimeUnit.SECONDS)  // Azure cold start handling
            .readTimeout(90, TimeUnit.SECONDS)
            .writeTimeout(90, TimeUnit.SECONDS)
            .addInterceptor(loggingInterceptor)
            .build()
    }

    /**
     * Retrofit instance configured for StatShark API
     */
    private val retrofit: Retrofit by lazy {
        Retrofit.Builder()
            .baseUrl(BASE_URL)
            .client(okHttpClient)
            .addConverterFactory(GsonConverterFactory.create(gson))
            .build()
    }

    /**
     * API Service instance
     */
    val apiService: StatSharkApiService by lazy {
        retrofit.create(StatSharkApiService::class.java)
    }
}
