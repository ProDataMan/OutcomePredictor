package com.statshark.nfl.ui.screens.teams

import androidx.compose.foundation.Image
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.lazy.grid.GridCells
import androidx.compose.foundation.lazy.grid.LazyVerticalGrid
import androidx.compose.foundation.lazy.grid.items
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.Clear
import androidx.compose.material.icons.filled.Search
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.res.painterResource
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.text.style.TextOverflow
import androidx.compose.ui.unit.dp
import androidx.hilt.navigation.compose.hiltViewModel
import androidx.lifecycle.compose.collectAsStateWithLifecycle
import androidx.navigation.NavController
import com.statshark.nfl.data.model.TeamDTO
import com.statshark.nfl.ui.navigation.Screen

/**
 * Teams Screen
 * Displays all NFL teams in a grid layout with conference filtering
 */
@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun TeamsScreen(
    navController: NavController,
    viewModel: TeamsViewModel = hiltViewModel()
) {
    val uiState by viewModel.uiState.collectAsStateWithLifecycle()

    Scaffold(
        topBar = {
            TopAppBar(
                title = { Text("NFL Teams") },
                colors = TopAppBarDefaults.topAppBarColors(
                    containerColor = MaterialTheme.colorScheme.primaryContainer,
                    titleContentColor = MaterialTheme.colorScheme.onPrimaryContainer
                )
            )
        }
    ) { paddingValues ->
        Column(
            modifier = Modifier
                .fillMaxSize()
                .padding(paddingValues)
        ) {
            // Search Bar
            OutlinedTextField(
                value = uiState.searchQuery,
                onValueChange = { viewModel.setSearchQuery(it) },
                modifier = Modifier
                    .fillMaxWidth()
                    .padding(horizontal = 16.dp, vertical = 8.dp),
                placeholder = { Text("Search teams") },
                leadingIcon = {
                    Icon(Icons.Filled.Search, contentDescription = "Search")
                },
                trailingIcon = {
                    if (uiState.searchQuery.isNotEmpty()) {
                        IconButton(onClick = { viewModel.setSearchQuery("") }) {
                            Icon(Icons.Filled.Clear, contentDescription = "Clear")
                        }
                    }
                },
                singleLine = true,
                shape = RoundedCornerShape(24.dp)
            )

            // Conference Filter (Segmented Control style - matching iOS)
            ConferenceFilterRow(
                selectedFilter = uiState.selectedFilter,
                onFilterSelected = { viewModel.setFilter(it) },
                modifier = Modifier.padding(horizontal = 16.dp, vertical = 8.dp)
            )

            // Content
            when {
                uiState.isLoading -> {
                    LoadingContent()
                }
                uiState.error != null -> {
                    ErrorContent(
                        error = uiState.error!!,
                        onRetry = { viewModel.retry() }
                    )
                }
                uiState.filteredTeams.isEmpty() -> {
                    EmptyContent()
                }
                else -> {
                    TeamsGrid(
                        teams = uiState.filteredTeams,
                        onTeamClick = { team ->
                            navController.navigate(Screen.TeamDetail.createRoute(team.abbreviation))
                        }
                    )
                }
            }
        }
    }
}

/**
 * Conference Filter Row
 * Matches iOS segmented picker style
 */
@Composable
fun ConferenceFilterRow(
    selectedFilter: ConferenceFilter,
    onFilterSelected: (ConferenceFilter) -> Unit,
    modifier: Modifier = Modifier
) {
    val filters = ConferenceFilter.values()
    val selectedIndex = filters.indexOf(selectedFilter)

    TabRow(
        selectedTabIndex = selectedIndex,
        modifier = modifier.fillMaxWidth(),
        containerColor = MaterialTheme.colorScheme.surfaceVariant,
        contentColor = MaterialTheme.colorScheme.primary
    ) {
        filters.forEachIndexed { index, filter ->
            Tab(
                selected = selectedIndex == index,
                onClick = { onFilterSelected(filter) },
                text = {
                    Text(
                        text = filter.name,
                        style = MaterialTheme.typography.labelLarge,
                        fontWeight = if (selectedIndex == index) FontWeight.SemiBold else FontWeight.Normal
                    )
                }
            )
        }
    }
}

/**
 * Teams Grid
 * Matches iOS LazyVGrid with adaptive sizing
 */
@Composable
fun TeamsGrid(
    teams: List<TeamDTO>,
    onTeamClick: (TeamDTO) -> Unit,
    modifier: Modifier = Modifier
) {
    LazyVerticalGrid(
        columns = GridCells.Adaptive(minSize = 160.dp),
        contentPadding = PaddingValues(16.dp),
        horizontalArrangement = Arrangement.spacedBy(16.dp),
        verticalArrangement = Arrangement.spacedBy(16.dp),
        modifier = modifier.fillMaxSize()
    ) {
        items(teams, key = { it.abbreviation }) { team ->
            TeamCard(
                team = team,
                onClick = { onTeamClick(team) }
            )
        }
    }
}

/**
 * Team Card Component
 * Matches iOS TeamCardView layout
 */
@Composable
fun TeamCard(
    team: TeamDTO,
    onClick: () -> Unit,
    modifier: Modifier = Modifier
) {
    Card(
        modifier = modifier
            .fillMaxWidth()
            .height(160.dp)
            .clickable(onClick = onClick),
        shape = RoundedCornerShape(12.dp),
        elevation = CardDefaults.cardElevation(defaultElevation = 2.dp),
        colors = CardDefaults.cardColors(
            containerColor = MaterialTheme.colorScheme.surface
        )
    ) {
        Column(
            modifier = Modifier
                .fillMaxSize()
                .padding(16.dp),
            horizontalAlignment = Alignment.CenterHorizontally,
            verticalArrangement = Arrangement.Center
        ) {
            // Team Helmet Icon
            val helmetResourceId = getTeamHelmetResource(team.abbreviation)
            if (helmetResourceId != null) {
                Image(
                    painter = painterResource(id = helmetResourceId),
                    contentDescription = "${team.name} helmet",
                    modifier = Modifier.size(80.dp)
                )
            }

            Spacer(modifier = Modifier.height(12.dp))

            // Team Name
            Text(
                text = team.name,
                style = MaterialTheme.typography.titleMedium,
                fontWeight = FontWeight.Bold,
                textAlign = TextAlign.Center,
                maxLines = 2,
                overflow = TextOverflow.Ellipsis
            )

            Spacer(modifier = Modifier.height(4.dp))

            // Conference and Division
            Text(
                text = "${team.conference} ${team.division}",
                style = MaterialTheme.typography.bodySmall,
                color = MaterialTheme.colorScheme.onSurfaceVariant,
                textAlign = TextAlign.Center
            )
        }
    }
}

/**
 * Loading Content
 */
@Composable
fun LoadingContent() {
    Box(
        modifier = Modifier.fillMaxSize(),
        contentAlignment = Alignment.Center
    ) {
        Column(
            horizontalAlignment = Alignment.CenterHorizontally,
            verticalArrangement = Arrangement.spacedBy(16.dp)
        ) {
            CircularProgressIndicator()
            Text(
                text = "Loading NFL Teams...",
                style = MaterialTheme.typography.bodyLarge,
                color = MaterialTheme.colorScheme.onSurfaceVariant
            )
        }
    }
}

/**
 * Error Content
 */
@Composable
fun ErrorContent(
    error: String,
    onRetry: () -> Unit
) {
    Box(
        modifier = Modifier.fillMaxSize(),
        contentAlignment = Alignment.Center
    ) {
        Column(
            horizontalAlignment = Alignment.CenterHorizontally,
            verticalArrangement = Arrangement.spacedBy(16.dp),
            modifier = Modifier.padding(32.dp)
        ) {
            Text(
                text = "🦈",
                style = MaterialTheme.typography.displayLarge
            )
            Text(
                text = "Awe Snap!",
                style = MaterialTheme.typography.headlineMedium,
                fontWeight = FontWeight.Bold
            )
            Text(
                text = error,
                style = MaterialTheme.typography.bodyMedium,
                color = MaterialTheme.colorScheme.error,
                textAlign = TextAlign.Center
            )
            Button(
                onClick = onRetry,
                modifier = Modifier.padding(top = 8.dp)
            ) {
                Text("Retry")
            }
        }
    }
}

/**
 * Empty Content
 */
@Composable
fun EmptyContent() {
    Box(
        modifier = Modifier.fillMaxSize(),
        contentAlignment = Alignment.Center
    ) {
        Text(
            text = "No teams found",
            style = MaterialTheme.typography.bodyLarge,
            color = MaterialTheme.colorScheme.onSurfaceVariant
        )
    }
}

/**
 * Get drawable resource ID for team helmet
 */
fun getTeamHelmetResource(abbreviation: String): Int? {
    return when (abbreviation.uppercase()) {
        "ARI" -> com.statshark.nfl.R.drawable.team_ari
        "ATL" -> com.statshark.nfl.R.drawable.team_atl
        "BAL" -> com.statshark.nfl.R.drawable.team_bal
        "BUF" -> com.statshark.nfl.R.drawable.team_buf
        "CAR" -> com.statshark.nfl.R.drawable.team_car
        "CHI" -> com.statshark.nfl.R.drawable.team_chi
        "CIN" -> com.statshark.nfl.R.drawable.team_cin
        "CLE" -> com.statshark.nfl.R.drawable.team_cle
        "DAL" -> com.statshark.nfl.R.drawable.team_dal
        "DEN" -> com.statshark.nfl.R.drawable.team_den
        "DET" -> com.statshark.nfl.R.drawable.team_det
        "GB" -> com.statshark.nfl.R.drawable.team_gb
        "HOU" -> com.statshark.nfl.R.drawable.team_hou
        "IND" -> com.statshark.nfl.R.drawable.team_ind
        "JAX" -> com.statshark.nfl.R.drawable.team_jax
        "KC" -> com.statshark.nfl.R.drawable.team_kc
        "LAC" -> com.statshark.nfl.R.drawable.team_lac
        "LAR" -> com.statshark.nfl.R.drawable.team_lar
        "LV" -> com.statshark.nfl.R.drawable.team_lv
        "MIA" -> com.statshark.nfl.R.drawable.team_mia
        "MIN" -> com.statshark.nfl.R.drawable.team_min
        "NE" -> com.statshark.nfl.R.drawable.team_ne
        "NO" -> com.statshark.nfl.R.drawable.team_no
        "NYG" -> com.statshark.nfl.R.drawable.team_nyg
        "NYJ" -> com.statshark.nfl.R.drawable.team_nyj
        "PHI" -> com.statshark.nfl.R.drawable.team_phi
        "PIT" -> com.statshark.nfl.R.drawable.team_pit
        "SEA" -> com.statshark.nfl.R.drawable.team_sea
        "SF" -> com.statshark.nfl.R.drawable.team_sf
        "TB" -> com.statshark.nfl.R.drawable.team_tb
        "TEN" -> com.statshark.nfl.R.drawable.team_ten
        "WAS" -> com.statshark.nfl.R.drawable.team_was
        else -> null
    }
}
