package com.statshark.nfl.ui.screens.player

import androidx.compose.foundation.background
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.lazy.grid.GridCells
import androidx.compose.foundation.lazy.grid.LazyVerticalGrid
import androidx.compose.foundation.lazy.grid.items
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.verticalScroll
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.ArrowBack
import androidx.compose.material.icons.filled.Person
import androidx.compose.material3.*
import androidx.compose.runtime.Composable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.Brush
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.layout.ContentScale
import androidx.compose.ui.res.painterResource
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.dp
import androidx.navigation.NavController
import coil.compose.AsyncImage
import com.statshark.nfl.R
import com.statshark.nfl.data.model.PlayerDTO
import com.statshark.nfl.data.model.PlayerStatsDTO
import com.statshark.nfl.ui.theme.TeamColors
import com.statshark.nfl.ui.components.FeedbackButton

/**
 * Player Detail Screen
 * Shows comprehensive player information and statistics
 */
@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun PlayerDetailScreen(
    player: PlayerDTO,
    teamAbbreviation: String,
    navController: NavController
) {
    val teamColors = TeamColors.getTeamColors(teamAbbreviation)
    val scrollState = rememberScrollState()

    Scaffold(
        topBar = {
            TopAppBar(
                title = { Text("Player Stats") },
                navigationIcon = {
                    IconButton(onClick = { navController.navigateUp() }) {
                        Icon(Icons.Filled.ArrowBack, contentDescription = "Back")
                    }
                },
                actions = {
                    FeedbackButton(pageName = "Player Detail")
                },
                colors = TopAppBarDefaults.topAppBarColors(
                    containerColor = teamColors.primary,
                    titleContentColor = Color.White,
                    navigationIconContentColor = Color.White
                )
            )
        }
    ) { paddingValues ->
        Column(
            modifier = Modifier
                .fillMaxSize()
                .padding(paddingValues)
                .verticalScroll(scrollState)
        ) {
            // Player Header
            PlayerHeader(
                player = player,
                teamAbbreviation = teamAbbreviation,
                teamColors = teamColors
            )

            Spacer(modifier = Modifier.height(24.dp))

            // Stats Section
            if (player.stats != null) {
                StatsSection(
                    player = player,
                    stats = player.stats
                )
            } else {
                NoStatsAvailable()
            }

            Spacer(modifier = Modifier.height(24.dp))
        }
    }
}

/**
 * Player Header with photo and basic info
 */
@Composable
fun PlayerHeader(
    player: PlayerDTO,
    teamAbbreviation: String,
    teamColors: TeamColors.TeamBranding
) {
    Column(
        modifier = Modifier
            .fillMaxWidth()
            .background(
                brush = Brush.verticalGradient(
                    colors = listOf(
                        teamColors.primary,
                        teamColors.primary.copy(alpha = 0.7f)
                    )
                )
            )
            .padding(24.dp),
        horizontalAlignment = Alignment.CenterHorizontally
    ) {
        // Player Photo
        Box(
            modifier = Modifier
                .size(150.dp)
                .clip(CircleShape)
                .background(Color.White.copy(alpha = 0.1f)),
            contentAlignment = Alignment.Center
        ) {
            if (player.photoURL != null) {
                AsyncImage(
                    model = player.photoURL,
                    contentDescription = player.name,
                    placeholder = painterResource(id = R.drawable.ic_helmet_placeholder),
                    error = painterResource(id = R.drawable.ic_helmet_placeholder),
                    modifier = Modifier
                        .fillMaxSize()
                        .clip(CircleShape),
                    contentScale = ContentScale.Crop
                )
            } else {
                Icon(
                    imageVector = Icons.Filled.Person,
                    contentDescription = null,
                    tint = Color.White,
                    modifier = Modifier.size(80.dp)
                )
            }
        }

        Spacer(modifier = Modifier.height(16.dp))

        // Player Name and Number
        Row(
            verticalAlignment = Alignment.CenterVertically,
            horizontalArrangement = Arrangement.spacedBy(8.dp)
        ) {
            Text(
                text = player.name,
                style = MaterialTheme.typography.headlineMedium,
                fontWeight = FontWeight.Bold,
                color = Color.White,
                textAlign = TextAlign.Center
            )
            if (player.jerseyNumber != null) {
                Text(
                    text = "#${player.jerseyNumber}",
                    style = MaterialTheme.typography.headlineSmall,
                    color = Color.White.copy(alpha = 0.9f)
                )
            }
        }

        Spacer(modifier = Modifier.height(8.dp))

        // Position
        Surface(
            shape = MaterialTheme.shapes.small,
            color = Color.White.copy(alpha = 0.2f)
        ) {
            Text(
                text = player.position,
                style = MaterialTheme.typography.titleLarge,
                fontWeight = FontWeight.Bold,
                color = Color.White,
                modifier = Modifier.padding(horizontal = 16.dp, vertical = 8.dp)
            )
        }

        Spacer(modifier = Modifier.height(16.dp))

        // Physical Stats Row
        Row(
            modifier = Modifier.fillMaxWidth(),
            horizontalArrangement = Arrangement.SpaceEvenly
        ) {
            if (player.height != null) {
                InfoPill(label = "Height", value = player.height)
            }
            if (player.weight != null) {
                InfoPill(label = "Weight", value = "${player.weight} lbs")
            }
            if (player.age != null) {
                InfoPill(label = "Age", value = "${player.age}")
            }
        }

        if (player.college != null) {
            Spacer(modifier = Modifier.height(8.dp))
            Text(
                text = player.college,
                style = MaterialTheme.typography.bodyLarge,
                color = Color.White.copy(alpha = 0.9f)
            )
        }
    }
}

/**
 * Info Pill for player attributes
 */
@Composable
fun InfoPill(label: String, value: String) {
    Column(
        horizontalAlignment = Alignment.CenterHorizontally
    ) {
        Text(
            text = value,
            style = MaterialTheme.typography.titleMedium,
            fontWeight = FontWeight.Bold,
            color = Color.White
        )
        Text(
            text = label,
            style = MaterialTheme.typography.bodySmall,
            color = Color.White.copy(alpha = 0.7f)
        )
    }
}

/**
 * Stats Section - displays position-specific stats
 */
@Composable
fun StatsSection(
    player: PlayerDTO,
    stats: PlayerStatsDTO
) {
    Column(
        modifier = Modifier
            .fillMaxWidth()
            .padding(horizontal = 16.dp)
    ) {
        Text(
            text = "Season Stats",
            style = MaterialTheme.typography.titleLarge,
            fontWeight = FontWeight.Bold
        )

        Spacer(modifier = Modifier.height(16.dp))

        when {
            player.position == "QB" && hasPassingStats(stats) -> {
                QuarterbackStats(stats)
            }
            player.position == "RB" && hasRushingStats(stats) -> {
                RunningBackStats(stats)
            }
            (player.position == "WR" || player.position == "TE") && hasReceivingStats(stats) -> {
                ReceiverStats(stats)
            }
            hasDefensiveStats(stats) -> {
                DefensiveStats(stats)
            }
            else -> {
                NoStatsAvailable()
            }
        }
    }
}

/**
 * Quarterback Stats
 */
@Composable
fun QuarterbackStats(stats: PlayerStatsDTO) {
    Column(verticalArrangement = Arrangement.spacedBy(16.dp)) {
        if (hasPassingStats(stats)) {
            StatCategory(title = "Passing") {
                LazyVerticalGrid(
                    columns = GridCells.Fixed(2),
                    horizontalArrangement = Arrangement.spacedBy(12.dp),
                    verticalArrangement = Arrangement.spacedBy(12.dp),
                    modifier = Modifier.height(300.dp)
                ) {
                    stats.passingYards?.let {
                        item { StatCard(label = "Passing Yards", value = it.toString()) }
                    }
                    stats.passingTouchdowns?.let {
                        item { StatCard(label = "Touchdowns", value = it.toString()) }
                    }
                    stats.interceptions?.let {
                        item { StatCard(label = "Interceptions", value = it.toString()) }
                    }
                    stats.completionPercentage?.let {
                        item { StatCard(label = "Completion %", value = String.format("%.1f%%", it)) }
                    }
                    stats.completions?.let {
                        item { StatCard(label = "Completions", value = it.toString()) }
                    }
                    stats.attempts?.let {
                        item { StatCard(label = "Attempts", value = it.toString()) }
                    }
                }
            }
        }

        if (hasRushingStats(stats)) {
            StatCategory(title = "Rushing") {
                LazyVerticalGrid(
                    columns = GridCells.Fixed(2),
                    horizontalArrangement = Arrangement.spacedBy(12.dp),
                    verticalArrangement = Arrangement.spacedBy(12.dp),
                    modifier = Modifier.height(150.dp)
                ) {
                    stats.rushingYards?.let {
                        item { StatCard(label = "Rushing Yards", value = it.toString()) }
                    }
                    stats.rushingTouchdowns?.let {
                        item { StatCard(label = "Touchdowns", value = it.toString()) }
                    }
                    stats.rushingAttempts?.let {
                        item { StatCard(label = "Attempts", value = it.toString()) }
                    }
                }
            }
        }
    }
}

/**
 * Running Back Stats
 */
@Composable
fun RunningBackStats(stats: PlayerStatsDTO) {
    Column(verticalArrangement = Arrangement.spacedBy(16.dp)) {
        if (hasRushingStats(stats)) {
            StatCategory(title = "Rushing") {
                LazyVerticalGrid(
                    columns = GridCells.Fixed(2),
                    horizontalArrangement = Arrangement.spacedBy(12.dp),
                    verticalArrangement = Arrangement.spacedBy(12.dp),
                    modifier = Modifier.height(200.dp)
                ) {
                    stats.rushingYards?.let {
                        item { StatCard(label = "Rushing Yards", value = it.toString()) }
                    }
                    stats.rushingTouchdowns?.let {
                        item { StatCard(label = "Touchdowns", value = it.toString()) }
                    }
                    stats.rushingAttempts?.let {
                        item { StatCard(label = "Attempts", value = it.toString()) }
                    }
                    stats.yardsPerCarry?.let {
                        item { StatCard(label = "Yards/Carry", value = String.format("%.1f", it)) }
                    }
                }
            }
        }

        if (hasReceivingStats(stats)) {
            StatCategory(title = "Receiving") {
                LazyVerticalGrid(
                    columns = GridCells.Fixed(2),
                    horizontalArrangement = Arrangement.spacedBy(12.dp),
                    verticalArrangement = Arrangement.spacedBy(12.dp),
                    modifier = Modifier.height(200.dp)
                ) {
                    stats.receivingYards?.let {
                        item { StatCard(label = "Receiving Yards", value = it.toString()) }
                    }
                    stats.receivingTouchdowns?.let {
                        item { StatCard(label = "Touchdowns", value = it.toString()) }
                    }
                    stats.receptions?.let {
                        item { StatCard(label = "Receptions", value = it.toString()) }
                    }
                    stats.targets?.let {
                        item { StatCard(label = "Targets", value = it.toString()) }
                    }
                }
            }
        }
    }
}

/**
 * Receiver Stats (WR/TE)
 */
@Composable
fun ReceiverStats(stats: PlayerStatsDTO) {
    StatCategory(title = "Receiving") {
        LazyVerticalGrid(
            columns = GridCells.Fixed(2),
            horizontalArrangement = Arrangement.spacedBy(12.dp),
            verticalArrangement = Arrangement.spacedBy(12.dp),
            modifier = Modifier.height(250.dp)
        ) {
            stats.receivingYards?.let {
                item { StatCard(label = "Receiving Yards", value = it.toString()) }
            }
            stats.receivingTouchdowns?.let {
                item { StatCard(label = "Touchdowns", value = it.toString()) }
            }
            stats.receptions?.let {
                item { StatCard(label = "Receptions", value = it.toString()) }
            }
            stats.targets?.let {
                item { StatCard(label = "Targets", value = it.toString()) }
            }
            if (stats.receptions != null && stats.targets != null && stats.targets > 0) {
                val catchRate = (stats.receptions.toDouble() / stats.targets) * 100
                item { StatCard(label = "Catch %", value = String.format("%.1f%%", catchRate)) }
            }
            if (stats.receivingYards != null && stats.receptions != null && stats.receptions > 0) {
                val ypc = stats.receivingYards.toDouble() / stats.receptions
                item { StatCard(label = "Yards/Catch", value = String.format("%.1f", ypc)) }
            }
        }
    }
}

/**
 * Defensive Stats
 */
@Composable
fun DefensiveStats(stats: PlayerStatsDTO) {
    StatCategory(title = "Defense") {
        LazyVerticalGrid(
            columns = GridCells.Fixed(2),
            horizontalArrangement = Arrangement.spacedBy(12.dp),
            verticalArrangement = Arrangement.spacedBy(12.dp),
            modifier = Modifier.height(150.dp)
        ) {
            stats.tackles?.let {
                item { StatCard(label = "Tackles", value = it.toString()) }
            }
            stats.sacks?.let {
                item { StatCard(label = "Sacks", value = String.format("%.1f", it)) }
            }
            stats.interceptions?.let {
                item { StatCard(label = "Interceptions", value = it.toString()) }
            }
        }
    }
}

/**
 * Stat Category Section
 */
@Composable
fun StatCategory(
    title: String,
    content: @Composable () -> Unit
) {
    Column {
        Text(
            text = title,
            style = MaterialTheme. typography.titleMedium,
            fontWeight = FontWeight.Bold,
            color = MaterialTheme.colorScheme.primary
        )
        Spacer(modifier = Modifier.height(12.dp))
        Card(
            modifier = Modifier.fillMaxWidth(),
            elevation = CardDefaults.cardElevation(defaultElevation = 2.dp)
        ) {
            Box(modifier = Modifier.padding(16.dp)) {
                content()
            }
        }
    }
}

/**
 * Individual Stat Card
 */
@Composable
fun StatCard(label: String, value: String) {
    Card(
        modifier = Modifier.fillMaxWidth(),
        colors = CardDefaults.cardColors(
            containerColor = MaterialTheme.colorScheme.surfaceVariant
        )
    ) {
        Column(
            modifier = Modifier
                .fillMaxWidth()
                .padding(16.dp),
            horizontalAlignment = Alignment.CenterHorizontally
        ) {
            Text(
                text = value,
                style = MaterialTheme.typography.headlineMedium,
                fontWeight = FontWeight.Bold,
                color = MaterialTheme.colorScheme.primary
            )
            Spacer(modifier = Modifier.height(4.dp))
            Text(
                text = label,
                style = MaterialTheme.typography.bodySmall,
                color = MaterialTheme.colorScheme.onSurfaceVariant,
                textAlign = TextAlign.Center
            )
        }
    }
}

/**
 * No Stats Available Message
 */
@Composable
fun NoStatsAvailable() {
    Box(
        modifier = Modifier
            .fillMaxWidth()
            .padding(48.dp),
        contentAlignment = Alignment.Center
    ) {
        Column(
            horizontalAlignment = Alignment.CenterHorizontally,
            verticalArrangement = Arrangement.spacedBy(8.dp)
        ) {
            Icon(
                imageVector = Icons.Filled.Person,
                contentDescription = null,
                modifier = Modifier.size(64.dp),
                tint = MaterialTheme.colorScheme.onSurfaceVariant.copy(alpha = 0.5f)
            )
            Text(
                text = "No stats available",
                style = MaterialTheme.typography.bodyLarge,
                color = MaterialTheme.colorScheme.onSurfaceVariant
            )
        }
    }
}

// Helper functions
private fun hasPassingStats(stats: PlayerStatsDTO): Boolean =
    stats.passingYards != null || stats.passingTouchdowns != null || stats.interceptions != null

private fun hasRushingStats(stats: PlayerStatsDTO): Boolean =
    stats.rushingYards != null || stats.rushingTouchdowns != null || stats.rushingAttempts != null

private fun hasReceivingStats(stats: PlayerStatsDTO): Boolean =
    stats.receivingYards != null || stats.receivingTouchdowns != null || stats.receptions != null

private fun hasDefensiveStats(stats: PlayerStatsDTO): Boolean =
    stats.tackles != null || stats.sacks != null || stats.interceptions != null
