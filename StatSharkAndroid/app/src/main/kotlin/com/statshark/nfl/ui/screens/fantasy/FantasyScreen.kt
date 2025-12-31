package com.statshark.nfl.ui.screens.fantasy

import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.ui.Modifier
import androidx.hilt.navigation.compose.hiltViewModel

/**
 * Fantasy Screen
 * Entry point for all fantasy football features
 */
@Composable
fun FantasyScreen(
    viewModel: FantasyViewModel = hiltViewModel()
) {
    // This screen will act as a hub for fantasy features
    // For now, it's a placeholder
    Column(modifier = Modifier.fillMaxSize()) {
        Text("Fantasy Screen")
    }
}
