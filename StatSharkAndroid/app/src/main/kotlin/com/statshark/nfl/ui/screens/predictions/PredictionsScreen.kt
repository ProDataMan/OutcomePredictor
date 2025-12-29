package com.statshark.nfl.ui.screens.predictions

import androidx.compose.foundation.layout.*
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.unit.dp
import androidx.navigation.NavController

/**
 * Predictions Screen
 * AI-powered game predictions
 */
@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun PredictionsScreen(navController: NavController) {
    Scaffold(
        topBar = {
            TopAppBar(
                title = { Text("Predictions") },
                colors = TopAppBarDefaults.topAppBarColors(
                    containerColor = MaterialTheme.colorScheme.primaryContainer,
                    titleContentColor = MaterialTheme.colorScheme.onPrimaryContainer
                )
            )
        }
    ) { paddingValues ->
        Box(
            modifier = Modifier
                .fillMaxSize()
                .padding(paddingValues),
            contentAlignment = Alignment.Center
        ) {
            Column(
                horizontalAlignment = Alignment.CenterHorizontally,
                verticalArrangement = Arrangement.spacedBy(16.dp)
            ) {
                Text(
                    text = "🎯 AI Predictions",
                    style = MaterialTheme.typography.headlineLarge
                )
                Text(
                    text = "Predictions Screen - Coming Soon!",
                    style = MaterialTheme.typography.bodyLarge
                )
            }
        }
    }
}
