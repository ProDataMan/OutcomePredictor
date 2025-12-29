package com.statshark.nfl

import android.app.Application
import dagger.hilt.android.HiltAndroidApp

/**
 * StatShark Application Class
 * Entry point for the Android application
 */
@HiltAndroidApp
class StatSharkApplication : Application() {

    override fun onCreate() {
        super.onCreate()
        // Application-level initialization
    }
}
