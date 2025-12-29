package com.statshark.nfl.di

import com.statshark.nfl.data.repository.NFLRepository
import dagger.Module
import dagger.Provides
import dagger.hilt.InstallIn
import dagger.hilt.components.SingletonComponent
import javax.inject.Singleton

/**
 * Hilt Module for Dependency Injection
 * Provides app-level dependencies
 */
@Module
@InstallIn(SingletonComponent::class)
object AppModule {

    @Provides
    @Singleton
    fun provideNFLRepository(): NFLRepository {
        return NFLRepository()
    }
}
