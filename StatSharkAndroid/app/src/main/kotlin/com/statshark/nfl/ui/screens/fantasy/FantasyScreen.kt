package com.statshark.nfl.ui.screens.fantasy

import androidx.compose.foundation.layout.*
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.unit.dp
import androidx.navigation.NavController

/**
 * Fantasy Screen
 * Fantasy football roster management
 */
@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun FantasyScreen(navController: NavController) {
    Scaffold(
        topBar = {
            TopAppBar(
                title = { Text("Fantasy") },
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
                    text = "🏈 Fantasy Football",
                    style = MaterialTheme.typography.headlineLarge
                )
                Text(
                    text = "Fantasy Screen - Coming Soon!",
                    style = MaterialTheme.typography.bodyLarge
                )
            }
        }
    }
}
