package com.statshark.nfl.ui.screens.fantasy

import androidx.compose.foundation.horizontalScroll
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.items
import androidx.compose.foundation.rememberScrollState
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.Delete
import androidx.compose.material.icons.filled.Person3
import androidx.compose.material.icons.filled.PersonAdd
import androidx.compose.material.icons.filled.Settings
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.dp
import androidx.hilt.navigation.compose.hiltViewModel
import androidx.navigation.NavController
import com.statshark.nfl.data.model.PlayerDTO
import com.statshark.nfl.data.model.TeamDTO
import com.statshark.nfl.ui.components.FeedbackButton
import com.statshark.nfl.data.model.FantasyPlayer
import com.statshark.nfl.data.model.FantasyRoster
import androidx.compose.material.icons.filled.CheckCircle

/**
 * Fantasy Screen
 * Full fantasy football features with player search and roster management
 */
@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun FantasyScreen(
    viewModel: FantasyViewModel = hiltViewModel(),
    navController: NavController? = null
) {
    var selectedTab by remember { mutableStateOf(0) }
    val uiState by viewModel.uiState.collectAsState()
    val teams by viewModel.teams.collectAsState()
    var showClearDialog by remember { mutableStateOf(false) }

    Scaffold(
        topBar = {
            TopAppBar(
                title = { Text("Fantasy Football") },
                navigationIcon = {
                    IconButton(onClick = { /* Settings */ }) {
                        Icon(Icons.Default.Settings, "Settings")
                    }
                },
                actions = {
                    if (selectedTab == 1 && uiState.roster.allPlayers.isNotEmpty()) {
                        IconButton(onClick = { showClearDialog = true }) {
                            Icon(Icons.Default.Delete, "Clear Roster", tint = MaterialTheme.colorScheme.error)
                        }
                    }
                    FeedbackButton(pageName = "Fantasy")
                }
            )
        }
    ) { padding ->
        Column(
            modifier = Modifier
                .fillMaxSize()
                .padding(padding)
        ) {
            // Tab Selector
            TabRow(selectedTabIndex = selectedTab) {
                Tab(
                    selected = selectedTab == 0,
                    onClick = { selectedTab = 0 },
                    text = { Text("Find Players") }
                )
                Tab(
                    selected = selectedTab == 1,
                    onClick = { selectedTab = 1 },
                    text = { Text("My Team (${uiState.roster.totalPlayers})") }
                )
            }

            // Tab Content
            when (selectedTab) {
                0 -> PlayerSearchView(viewModel = viewModel, teams = teams)
                1 -> RosterView(viewModel = viewModel, roster = uiState.roster)
            }
        }
    }

    // Clear roster confirmation dialog
    if (showClearDialog) {
        AlertDialog(
            onDismissRequest = { showClearDialog = false },
            title = { Text("Clear Roster?") },
            text = { Text("This will remove all players from your fantasy team.") },
            confirmButton = {
                TextButton(
                    onClick = {
                        viewModel.clearRoster()
                        showClearDialog = false
                    }
                ) {
                    Text("Clear", color = MaterialTheme.colorScheme.error)
                }
            },
            dismissButton = {
                TextButton(onClick = { showClearDialog = false }) {
                    Text("Cancel")
                }
            }
        )
    }
}

@Composable
fun PlayerSearchView(viewModel: FantasyViewModel, teams: List<TeamDTO>) {
    var selectedPosition by remember { mutableStateOf("All") }
    var selectedTeam by remember { mutableStateOf<TeamDTO?>(null) }

    val teamRoster by viewModel.teamRoster.collectAsState()
    val allPositionPlayers by viewModel.allPositionPlayers.collectAsState()
    val uiState by viewModel.uiState.collectAsState()

    val positions = listOf("All", "QB", "RB", "WR", "TE", "K", "DEF")

    Column(modifier = Modifier.fillMaxSize()) {
        // Position Filter
        Row(
            modifier = Modifier
                .fillMaxWidth()
                .horizontalScroll(rememberScrollState())
                .padding(horizontal = 16.dp, vertical = 8.dp),
            horizontalArrangement = Arrangement.spacedBy(8.dp)
        ) {
            positions.forEach { position ->
                val isFull = position != "All" && viewModel.isPositionFull(position)
                FilterChip(
                    selected = selectedPosition == position,
                    onClick = {
                        selectedPosition = position
                        if (position != "All" && selectedTeam == null) {
                            viewModel.loadAllPositionPlayers(position)
                        }
                    },
                    label = { Text(position) },
                    leadingIcon = if (isFull) {
                        {
                            Icon(
                                imageVector = Icons.Default.CheckCircle,
                                contentDescription = "Full",
                                modifier = Modifier.size(16.dp)
                            )
                        }
                    } else null
                )
            }
        }

        // Team Selector
        Row(
            modifier = Modifier
                .fillMaxWidth()
                .horizontalScroll(rememberScrollState())
                .padding(horizontal = 16.dp, vertical = 8.dp),
            horizontalArrangement = Arrangement.spacedBy(8.dp)
        ) {
            teams.forEach { team ->
                FilterChip(
                    selected = selectedTeam?.abbreviation == team.abbreviation,
                    onClick = {
                        if (selectedTeam?.abbreviation == team.abbreviation) {
                            selectedTeam = null
                            viewModel.clearTeamRoster()
                        } else {
                            selectedTeam = team
                            viewModel.loadTeamRoster(team.abbreviation)
                        }
                    },
                    label = { Text(team.abbreviation) }
                )
            }
        }

        HorizontalDivider()

        // Players List
        when {
            selectedTeam != null -> {
                // Show team players
                TeamPlayersView(
                    teamRoster = teamRoster,
                    positionFilter = selectedPosition,
                    isLoading = uiState.isLoadingRoster,
                    error = uiState.rosterError,
                    viewModel = viewModel,
                    team = selectedTeam!!
                )
            }
            selectedPosition != "All" -> {
                // Show all players for position
                AllPositionPlayersView(
                    players = allPositionPlayers,
                    isLoading = uiState.isLoadingAllPlayers,
                    viewModel = viewModel
                )
            }
            else -> {
                // Empty state
                Column(
                    modifier = Modifier
                        .fillMaxSize()
                        .padding(32.dp),
                    horizontalAlignment = Alignment.CenterHorizontally,
                    verticalArrangement = Arrangement.Center
                ) {
                    Icon(
                        imageVector = Icons.Default.Person3,
                        contentDescription = null,
                        modifier = Modifier.size(64.dp),
                        tint = MaterialTheme.colorScheme.onSurfaceVariant
                    )
                    Spacer(Modifier.height(16.dp))
                    Text(
                        "Select a team or position",
                        style = MaterialTheme.typography.titleMedium,
                        color = MaterialTheme.colorScheme.onSurfaceVariant
                    )
                    Spacer(Modifier.height(8.dp))
                    Text(
                        "Choose a team to view all players, or select a position to see the best players across all teams",
                        style = MaterialTheme.typography.bodySmall,
                        color = MaterialTheme.colorScheme.onSurfaceVariant,
                        textAlign = TextAlign.Center
                    )
                }
            }
        }
    }
}

@Composable
fun TeamPlayersView(
    teamRoster: com.statshark.nfl.data.model.TeamRosterDTO?,
    positionFilter: String,
    isLoading: Boolean,
    error: String?,
    viewModel: FantasyViewModel,
    team: TeamDTO
) {
    Box(modifier = Modifier.fillMaxSize()) {
        when {
            isLoading -> {
                CircularProgressIndicator(modifier = Modifier.align(Alignment.Center))
            }
            error != null -> {
                Text(
                    text = error,
                    modifier = Modifier.align(Alignment.Center).padding(16.dp),
                    color = MaterialTheme.colorScheme.error
                )
            }
            teamRoster != null -> {
                val filteredPlayers = if (positionFilter == "All") {
                    teamRoster.players
                } else {
                    teamRoster.players.filter { it.position == positionFilter }
                }

                if (filteredPlayers.isEmpty()) {
                    Text(
                        "No ${if (positionFilter == "All") "" else positionFilter} players found",
                        modifier = Modifier.align(Alignment.Center),
                        color = MaterialTheme.colorScheme.onSurfaceVariant
                    )
                } else {
                    LazyColumn(
                        contentPadding = PaddingValues(16.dp),
                        verticalArrangement = Arrangement.spacedBy(12.dp)
                    ) {
                        items(filteredPlayers) { player ->
                            FantasyPlayerCard(
                                player = player,
                                team = team,
                                viewModel = viewModel
                            )
                        }
                    }
                }
            }
        }
    }
}

@Composable
fun AllPositionPlayersView(
    players: List<Pair<PlayerDTO, TeamDTO>>,
    isLoading: Boolean,
    viewModel: FantasyViewModel
) {
    Box(modifier = Modifier.fillMaxSize()) {
        when {
            isLoading -> {
                CircularProgressIndicator(modifier = Modifier.align(Alignment.Center))
            }
            players.isEmpty() && !isLoading -> {
                Text(
                    "No players found",
                    modifier = Modifier.align(Alignment.Center),
                    color = MaterialTheme.colorScheme.onSurfaceVariant
                )
            }
            else -> {
                LazyColumn(
                    contentPadding = PaddingValues(16.dp),
                    verticalArrangement = Arrangement.spacedBy(12.dp)
                ) {
                    items(players) { (player, team) ->
                        FantasyPlayerCard(
                            player = player,
                            team = team,
                            viewModel = viewModel
                        )
                    }
                }
            }
        }
    }
}

@Composable
fun RosterView(viewModel: FantasyViewModel, roster: FantasyRoster) {
    if (roster.allPlayers.isEmpty()) {
        Column(
            modifier = Modifier
                .fillMaxSize()
                .padding(32.dp),
            horizontalAlignment = Alignment.CenterHorizontally,
            verticalArrangement = Arrangement.Center
        ) {
            Icon(
                imageVector = Icons.Default.PersonAdd,
                contentDescription = null,
                modifier = Modifier.size(64.dp),
                tint = MaterialTheme.colorScheme.onSurfaceVariant
            )
            Spacer(Modifier.height(16.dp))
            Text(
                "Your roster is empty",
                style = MaterialTheme.typography.titleMedium,
                color = MaterialTheme.colorScheme.onSurfaceVariant
            )
            Spacer(Modifier.height(8.dp))
            Text(
                "Add players from the Find Players tab",
                style = MaterialTheme.typography.bodySmall,
                color = MaterialTheme.colorScheme.onSurfaceVariant
            )
        }
    } else {
        LazyColumn(
            contentPadding = PaddingValues(16.dp),
            verticalArrangement = Arrangement.spacedBy(16.dp)
        ) {
            // Roster Summary
            item {
                RosterSummaryCard(roster = roster)
            }

            // QB Section
            if (roster.quarterbacks.isNotEmpty()) {
                item {
                    PositionSection(
                        title = "Quarterbacks",
                        players = roster.quarterbacks,
                        maxPlayers = FantasyRoster.MAX_QBS,
                        viewModel = viewModel
                    )
                }
            }

            // RB Section
            if (roster.runningBacks.isNotEmpty()) {
                item {
                    PositionSection(
                        title = "Running Backs",
                        players = roster.runningBacks,
                        maxPlayers = FantasyRoster.MAX_RBS,
                        viewModel = viewModel
                    )
                }
            }

            // WR Section
            if (roster.wideReceivers.isNotEmpty()) {
                item {
                    PositionSection(
                        title = "Wide Receivers",
                        players = roster.wideReceivers,
                        maxPlayers = FantasyRoster.MAX_WRS,
                        viewModel = viewModel
                    )
                }
            }

            // TE Section
            if (roster.tightEnds.isNotEmpty()) {
                item {
                    PositionSection(
                        title = "Tight Ends",
                        players = roster.tightEnds,
                        maxPlayers = FantasyRoster.MAX_TES,
                        viewModel = viewModel
                    )
                }
            }
        }
    }
}
