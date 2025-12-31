package com.statshark.nfl.ui.screens.standings

import androidx.compose.foundation.layout.*
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.items
import androidx.compose.material.ExperimentalMaterialApi
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.Refresh
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.dp
import androidx.hilt.navigation.compose.hiltViewModel
import androidx.lifecycle.compose.collectAsStateWithLifecycle
import androidx.navigation.NavController
import com.google.accompanist.swiperefresh.SwipeRefresh
import com.google.accompanist.swiperefresh.rememberSwipeRefreshState
import com.statshark.nfl.data.model.DivisionStandings
import com.statshark.nfl.ui.components.FeedbackButton

/**
 * Standings Screen
 * Displays NFL standings by division and conference
 */
@OptIn(ExperimentalMaterial3Api::class, ExperimentalMaterialApi::class)
@Composable
fun StandingsScreen(
    navController: NavController,
    viewModel: StandingsViewModel = hiltViewModel()
) {
    val uiState by viewModel.uiState.collectAsStateWithLifecycle()
    val swipeRefreshState = rememberSwipeRefreshState(isRefreshing = uiState.isLoading)

    Scaffold(
        topBar = {
            TopAppBar(
                title = { Text("Standings") },
                colors = TopAppBarDefaults.topAppBarColors(
                    containerColor = MaterialTheme.colorScheme.primaryContainer,
                    titleContentColor = MaterialTheme.colorScheme.onPrimaryContainer
                ),
                actions = {
                    FeedbackButton(pageName = "Standings")
                    IconButton(onClick = { viewModel.retry() }) {
                        Icon(Icons.Filled.Refresh, contentDescription = "Refresh")
                    }
                }
            )
        }
    ) { paddingValues ->
        SwipeRefresh(
            state = swipeRefreshState,
            onRefresh = { viewModel.loadStandings() },
            modifier = Modifier.padding(paddingValues)
        ) {
            Column(modifier = Modifier.fillMaxSize()) {
                // Conference Selector
                TabRow(selectedTabIndex = if (uiState.selectedConference == "AFC") 0 else 1) {
                    Tab(
                        selected = uiState.selectedConference == "AFC",
                        onClick = { viewModel.selectConference("AFC") },
                        text = { Text("AFC") }
                    )
                    Tab(
                        selected = uiState.selectedConference == "NFC",
                        onClick = { viewModel.selectConference("NFC") },
                        text = { Text("NFC") }
                    )
                }

                // Content
                when {
                    uiState.isLoading && uiState.standings == null -> {
                        Box(
                            modifier = Modifier.fillMaxSize(),
                            contentAlignment = Alignment.Center
                        ) {
                            CircularProgressIndicator()
                        }
                    }
                    uiState.error != null && uiState.standings == null -> {
                        Box(
                            modifier = Modifier
                                .fillMaxSize()
                                .padding(16.dp),
                            contentAlignment = Alignment.Center
                        ) {
                            Column(
                                horizontalAlignment = Alignment.CenterHorizontally,
                                verticalArrangement = Arrangement.spacedBy(16.dp)
                            ) {
                                Text(
                                    text = "Failed to load standings",
                                    style = MaterialTheme.typography.titleMedium,
                                    fontWeight = FontWeight.Bold
                                )
                                Text(
                                    text = uiState.error!!,
                                    style = MaterialTheme.typography.bodyMedium,
                                    color = MaterialTheme.colorScheme.error,
                                    textAlign = TextAlign.Center
                                )
                                Button(onClick = { viewModel.retry() }) {
                                    Text("Retry")
                                }
                            }
                        }
                    }
                    uiState.standings != null -> {
                        LazyColumn(
                            contentPadding = PaddingValues(16.dp),
                            verticalArrangement = Arrangement.spacedBy(16.dp)
                        ) {
                            // Season header
                            item {
                                Column(
                                    modifier = Modifier.fillMaxWidth(),
                                    horizontalAlignment = Alignment.CenterHorizontally
                                ) {
                                    Text(
                                        text = "${uiState.standings!!.season} Season",
                                        style = MaterialTheme.typography.headlineMedium,
                                        fontWeight = FontWeight.Bold
                                    )
                                }
                            }

                            // Display divisions
                            items(uiState.displayedDivisions) { division ->
                                DivisionCard(division = division)
                            }
                        }
                    }
                }
            }
        }
    }
}

@Composable
fun DivisionCard(division: DivisionStandings) {
    Card(
        modifier = Modifier.fillMaxWidth(),
        elevation = CardDefaults.cardElevation(defaultElevation = 2.dp)
    ) {
        Column(modifier = Modifier.padding(16.dp)) {
            Text(
                text = "${division.conference} ${division.division}",
                style = MaterialTheme.typography.titleLarge,
                fontWeight = FontWeight.Bold
            )

            Spacer(modifier = Modifier.height(12.dp))

            // Header Row
            Row(modifier = Modifier.fillMaxWidth()) {
                Text("Team", Modifier.weight(2f), style = MaterialTheme.typography.labelSmall)
                Text("W", Modifier.weight(0.5f), style = MaterialTheme.typography.labelSmall)
                Text("L", Modifier.weight(0.5f), style = MaterialTheme.typography.labelSmall)
                Text("T", Modifier.weight(0.5f), style = MaterialTheme.typography.labelSmall)
                Text("PCT", Modifier.weight(0.8f), style = MaterialTheme.typography.labelSmall)
            }

            Divider(modifier = Modifier.padding(vertical = 8.dp))

            // Team rows
            division.teams.forEach { team ->
                Row(
                    modifier = Modifier.fillMaxWidth().padding(vertical = 4.dp),
                    verticalAlignment = Alignment.CenterVertically
                ) {
                    Text(team.team.abbreviation, Modifier.weight(2f), fontWeight = FontWeight.Medium)
                    Text("${team.wins}", Modifier.weight(0.5f))
                    Text("${team.losses}", Modifier.weight(0.5f))
                    Text("${team.ties}", Modifier.weight(0.5f))
                    Text(String.format("%.3f", team.winPercentage), Modifier.weight(0.8f))
                }
            }
        }
    }
}
