package com.statshark.nfl.ui.screens.fantasy

import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.padding
import androidx.compose.material3.*
import androidx.compose.runtime.Composable
import androidx.compose.ui.Modifier
import androidx.hilt.navigation.compose.hiltViewModel
import com.statshark.nfl.ui.components.FeedbackButton

/**
 * Fantasy Screen
 * Entry point for all fantasy football features
 */
@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun FantasyScreen(
    viewModel: FantasyViewModel = hiltViewModel()
) {
    Scaffold(
        topBar = {
            TopAppBar(
                title = { Text("Fantasy Football") },
                actions = {
                    FeedbackButton(pageName = "Fantasy")
                },
                colors = TopAppBarDefaults.topAppBarColors(
                    containerColor = MaterialTheme.colorScheme.primaryContainer,
                    titleContentColor = MaterialTheme.colorScheme.onPrimaryContainer
                )
            )
        }
    ) { paddingValues ->
        // This screen will act as a hub for fantasy features
        // For now, it's a placeholder
        Column(
            modifier = Modifier
                .fillMaxSize()
                .padding(paddingValues)
        ) {
            Text("Fantasy Screen - Coming Soon")
        }
    }
}
