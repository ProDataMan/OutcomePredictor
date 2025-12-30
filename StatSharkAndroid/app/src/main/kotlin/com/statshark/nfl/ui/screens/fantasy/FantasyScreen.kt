package com.statshark.nfl.ui.screens.fantasy

import android.app.AlertDialog
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.LazyRow
import androidx.compose.foundation.lazy.items
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.Add
import androidx.compose.material.icons.filled.Delete
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.dp
import androidx.hilt.navigation.compose.hiltViewModel
import androidx.lifecycle.compose.collectAsStateWithLifecycle
import com.statshark.nfl.data.model.FantasyRoster
import com.statshark.nfl.data.model.PlayerDTO
import com.statshark.nfl.data.model.TeamDTO

/**
 * Fantasy Screen - Main fantasy football interface
 * Matches iOS FantasyView functionality
 */
@Composable
fun FantasyScreen(
    navController: androidx.navigation.NavController? = null,
    viewModel: FantasyViewModel = hiltViewModel()
) {
    var selectedTab by remember { mutableIntStateOf(0) }
    val uiState by viewModel.uiState.collectAsStateWithLifecycle()
    val context = LocalContext.current

    Column(modifier = Modifier.fillMaxSize()) {
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

        when (selectedTab) {
            0 -> PlayerSearchView(viewModel = viewModel)
            1 -> RosterView(
                viewModel = viewModel,
                onClearRoster = {
                    AlertDialog.Builder(context)
                        .setTitle("Clear Roster?")
                        .setMessage("This will remove all players from your fantasy team.")
                        .setPositiveButton("Clear") { _, _ -> viewModel.clearRoster() }
                        .setNegativeButton("Cancel", null)
                        .show()
                }
            )
        }
    }
}

@Composable
fun PlayerSearchView(viewModel: FantasyViewModel) {
    var selectedPosition by remember { mutableStateOf("All") }
    var selectedTeam by remember { mutableStateOf<TeamDTO?>(null) }

    val teams by viewModel.teams.collectAsStateWithLifecycle()
    val teamRoster by viewModel.teamRoster.collectAsStateWithLifecycle()
    val allPositionPlayers by viewModel.allPositionPlayers.collectAsStateWithLifecycle()
    val uiState by viewModel.uiState.collectAsStateWithLifecycle()

    val positions = listOf("All", "QB", "RB", "WR", "TE", "K", "DEF")

    Column(modifier = Modifier.fillMaxSize()) {
        // Position filter
        LazyRow(
            modifier = Modifier.fillMaxWidth().padding(vertical = 8.dp),
            contentPadding = PaddingValues(horizontal = 16.dp),
            horizontalArrangement = Arrangement.spacedBy(8.dp)
        ) {
            items(positions) { position ->
                PositionFilterChip(
                    position = position,
                    isSelected = selectedPosition == position,
                    isFull = position != "All" && viewModel.isPositionFull(position),
                    onClick = { selectedPosition = position }
                )
            }
        }

        // Team selector
        LazyRow(
            modifier = Modifier.fillMaxWidth().padding(vertical = 8.dp),
            contentPadding = PaddingValues(horizontal = 16.dp),
            horizontalArrangement = Arrangement.spacedBy(8.dp)
        ) {
            items(teams) { team ->
                TeamFilterChip(
                    team = team,
                    isSelected = selectedTeam?.abbreviation == team.abbreviation,
                    onClick = {
                        if (selectedTeam?.abbreviation == team.abbreviation) {
                            selectedTeam = null
                            viewModel.clearTeamRoster()
                        } else {
                            selectedTeam = team
                            viewModel.clearAllPositionPlayers()
                            viewModel.loadTeamRoster(team.abbreviation)
                        }
                    }
                )
            }
        }

        Divider()

        when {
            selectedTeam != null -> TeamPlayersView(selectedTeam!!, teamRoster, selectedPosition, uiState.isLoadingRoster, uiState.rosterError, viewModel)
            selectedPosition != "All" -> {
                LaunchedEffect(selectedPosition) { viewModel.loadAllPositionPlayers(selectedPosition) }
                AllPositionPlayersView(allPositionPlayers, uiState.isLoadingAllPlayers, viewModel)
            }
            else -> EmptySearchState()
        }
    }
}

@Composable
fun TeamPlayersView(
    team: TeamDTO,
    roster: com.statshark.nfl.data.model.TeamRosterDTO?,
    positionFilter: String,
    isLoading: Boolean,
    error: String?,
    viewModel: FantasyViewModel
) {
    val filteredPlayers = remember(roster, positionFilter) {
        roster?.players?.let { if (positionFilter == "All") it else it.filter { p -> p.position == positionFilter } } ?: emptyList()
    }

    when {
        isLoading -> Box(Modifier.fillMaxSize(), contentAlignment = Alignment.Center) { CircularProgressIndicator() }
        error != null -> Box(Modifier.fillMaxSize(), contentAlignment = Alignment.Center) {
            Text(error, color = MaterialTheme.colorScheme.error, textAlign = TextAlign.Center, modifier = Modifier.padding(16.dp))
        }
        filteredPlayers.isEmpty() -> Box(Modifier.fillMaxSize(), contentAlignment = Alignment.Center) {
            Text("No ${if (positionFilter == "All") "" else positionFilter} players found", color = MaterialTheme.colorScheme.onSurfaceVariant)
        }
        else -> LazyColumn(Modifier.fillMaxSize(), contentPadding = PaddingValues(16.dp), verticalArrangement = Arrangement.spacedBy(12.dp)) {
            items(filteredPlayers, key = { it.id }) { player -> FantasyPlayerCard(player, team, viewModel) }
        }
    }
}

@Composable
fun AllPositionPlayersView(
    players: List<Pair<PlayerDTO, TeamDTO>>,
    isLoading: Boolean,
    viewModel: FantasyViewModel
) {
    when {
        isLoading -> Box(Modifier.fillMaxSize(), contentAlignment = Alignment.Center) {
            Column(horizontalAlignment = Alignment.CenterHorizontally, verticalArrangement = Arrangement.spacedBy(16.dp)) {
                CircularProgressIndicator()
                Text("Loading players from all teams...")
            }
        }
        players.isEmpty() -> Box(Modifier.fillMaxSize(), contentAlignment = Alignment.Center) {
            Text("No players found", color = MaterialTheme.colorScheme.onSurfaceVariant)
        }
        else -> LazyColumn(Modifier.fillMaxSize(), contentPadding = PaddingValues(16.dp), verticalArrangement = Arrangement.spacedBy(12.dp)) {
            items(players, key = { it.first.id }) { (player, team) -> FantasyPlayerCard(player, team, viewModel) }
        }
    }
}

@Composable
fun EmptySearchState() {
    Box(Modifier.fillMaxSize(), contentAlignment = Alignment.Center) {
        Column(horizontalAlignment = Alignment.CenterHorizontally, verticalArrangement = Arrangement.spacedBy(16.dp), modifier = Modifier.padding(32.dp)) {
            Icon(Icons.Default.Add, null, Modifier.size(64.dp), tint = MaterialTheme.colorScheme.onSurfaceVariant)
            Text("Select a team or position", style = MaterialTheme.typography.titleMedium, fontWeight = FontWeight.Bold)
            Text(
                "Choose a team to view all players, or select a position to see the best players across all teams",
                style = MaterialTheme.typography.bodyMedium,
                color = MaterialTheme.colorScheme.onSurfaceVariant,
                textAlign = TextAlign.Center
            )
        }
    }
}

@Composable
fun RosterView(viewModel: FantasyViewModel, onClearRoster: () -> Unit) {
    val uiState by viewModel.uiState.collectAsStateWithLifecycle()
    val roster = uiState.roster

    if (roster.allPlayers.isEmpty()) {
        Box(Modifier.fillMaxSize(), contentAlignment = Alignment.Center) {
            Column(horizontalAlignment = Alignment.CenterHorizontally, verticalArrangement = Arrangement.spacedBy(16.dp), modifier = Modifier.padding(32.dp)) {
                Icon(Icons.Default.Add, null, Modifier.size(64.dp), tint = MaterialTheme.colorScheme.onSurfaceVariant)
                Text("Your roster is empty", style = MaterialTheme.typography.titleMedium, fontWeight = FontWeight.Bold)
                Text("Add players from the Find Players tab", style = MaterialTheme.typography.bodyMedium, color = MaterialTheme.colorScheme.onSurfaceVariant)
            }
        }
    } else {
        LazyColumn(Modifier.fillMaxSize(), contentPadding = PaddingValues(16.dp), verticalArrangement = Arrangement.spacedBy(16.dp)) {
            item { RosterSummaryCard(roster) }
            if (roster.quarterbacks.isNotEmpty()) item { PositionSection("Quarterbacks", roster.quarterbacks, FantasyRoster.MAX_QBS, viewModel) }
            if (roster.runningBacks.isNotEmpty()) item { PositionSection("Running Backs", roster.runningBacks, FantasyRoster.MAX_RBS, viewModel) }
            if (roster.wideReceivers.isNotEmpty()) item { PositionSection("Wide Receivers", roster.wideReceivers, FantasyRoster.MAX_WRS, viewModel) }
            if (roster.tightEnds.isNotEmpty()) item { PositionSection("Tight Ends", roster.tightEnds, FantasyRoster.MAX_TES, viewModel) }
            item {
                OutlinedButton(
                    onClick = onClearRoster,
                    modifier = Modifier.fillMaxWidth(),
                    colors = ButtonDefaults.outlinedButtonColors(contentColor = MaterialTheme.colorScheme.error)
                ) {
                    Icon(Icons.Default.Delete, null)
                    Spacer(Modifier.width(8.dp))
                    Text("Clear Roster")
                }
            }
        }
    }
}
