package com.statshark.nfl.ui.screens.player

import androidx.compose.foundation.layout.*
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.foundation.verticalScroll
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.ArrowBack
import androidx.compose.material3.*
import androidx.compose.runtime.Composable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
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
import com.statshark.nfl.data.model.TeamDTO
import com.statshark.nfl.ui.screens.teams.getTeamHelmetResource
import com.statshark.nfl.ui.theme.TeamColors
import kotlin.math.max

/**
 * Player Comparison Screen
 * Side-by-side player stats comparison
 */
@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun PlayerComparisonScreen(
    player1: PlayerDTO,
    player2: PlayerDTO,
    team1: TeamDTO,
    team2: TeamDTO,
    navController: NavController
) {
    Scaffold(
        topBar = {
            TopAppBar(
                title = { Text("Player Comparison") },
                navigationIcon = {
                    IconButton(onClick = { navController.navigateUp() }) {
                        Icon(Icons.Filled.ArrowBack, "Back")
                    }
                }
            )
        }
    ) { padding ->
        Column(
            modifier = Modifier
                .fillMaxSize()
                .padding(padding)
                .verticalScroll(rememberScrollState())
        ) {
            // Player Headers
            Row(
                modifier = Modifier
                    .fillMaxWidth()
                    .padding(16.dp),
                horizontalArrangement = Arrangement.spacedBy(16.dp)
            ) {
                PlayerComparisonHeader(player1, team1, Modifier.weight(1f))
                Divider(Modifier.width(1.dp).height(120.dp))
                PlayerComparisonHeader(player2, team2, Modifier.weight(1f))
            }

            // Stats Comparison
            if (player1.position == player2.position) {
                StatsComparisonSection(player1, player2)
            } else {
                Text(
                    "Players play different positions",
                    Modifier.fillMaxWidth().padding(32.dp),
                    textAlign = TextAlign.Center,
                    color = MaterialTheme.colorScheme.onSurfaceVariant
                )
            }

            // Recommendation
            RecommendationSection(player1, player2, team1, team2)

            Spacer(Modifier.height(16.dp))
        }
    }
}

@Composable
fun PlayerComparisonHeader(player: PlayerDTO, team: TeamDTO, modifier: Modifier = Modifier) {
    Column(
        modifier = modifier,
        horizontalAlignment = Alignment.CenterHorizontally,
        verticalArrangement = Arrangement.spacedBy(8.dp)
    ) {
        val helmetId = getTeamHelmetResource(team.abbreviation)
        AsyncImage(
            model = player.photoURL,
            contentDescription = player.name,
            placeholder = if (helmetId != null) painterResource(helmetId) else painterResource(R.drawable.ic_helmet_placeholder),
            error = if (helmetId != null) painterResource(helmetId) else painterResource(R.drawable.ic_helmet_placeholder),
            modifier = Modifier.size(60.dp).clip(CircleShape),
            contentScale = ContentScale.Crop
        )

        Text(player.name, style = MaterialTheme.typography.titleSmall, fontWeight = FontWeight.Bold, textAlign = TextAlign.Center)
        Text(player.position, style = MaterialTheme.typography.labelMedium, color = MaterialTheme.colorScheme.onSurfaceVariant)

        Surface(
            shape = RoundedCornerShape(8.dp),
            color = TeamColors.getPrimaryColor(team.abbreviation).copy(alpha = 0.2f)
        ) {
            Text(
                team.abbreviation,
                style = MaterialTheme.typography.labelSmall,
                color = TeamColors.getPrimaryColor(team.abbreviation),
                modifier = Modifier.padding(horizontal = 8.dp, vertical = 4.dp)
            )
        }
    }
}

@Composable
fun StatsComparisonSection(player1: PlayerDTO, player2: PlayerDTO) {
    Column(Modifier.padding(16.dp), verticalArrangement = Arrangement.spacedBy(16.dp)) {
        Text("Stats Comparison", style = MaterialTheme.typography.titleMedium, fontWeight = FontWeight.Bold)

        when (player1.position) {
            "QB" -> QuarterbackStatsComparison(player1, player2)
            "RB" -> RunningBackStatsComparison(player1, player2)
            "WR", "TE" -> ReceiverStatsComparison(player1, player2)
            else -> Text("Stats not available for this position", color = MaterialTheme.colorScheme.onSurfaceVariant)
        }
    }
}

@Composable
fun QuarterbackStatsComparison(p1: PlayerDTO, p2: PlayerDTO) {
    Column(verticalArrangement = Arrangement.spacedBy(12.dp)) {
        StatComparisonRow("Passing Yards", p1.stats?.passingYards, p2.stats?.passingYards)
        StatComparisonRow("Passing TDs", p1.stats?.passingTouchdowns, p2.stats?.passingTouchdowns)
        StatComparisonRow("Interceptions", p1.stats?.interceptions, p2.stats?.interceptions, lowerIsBetter = true)
        val comp1 = if (p1.stats?.attempts != null && p1.stats.attempts!! > 0) ((p1.stats.completions ?: 0) * 100) / p1.stats.attempts!! else null
        val comp2 = if (p2.stats?.attempts != null && p2.stats.attempts!! > 0) ((p2.stats.completions ?: 0) * 100) / p2.stats.attempts!! else null
        StatComparisonRow("Completion %", comp1, comp2)
    }
}

@Composable
fun RunningBackStatsComparison(p1: PlayerDTO, p2: PlayerDTO) {
    Column(verticalArrangement = Arrangement.spacedBy(12.dp)) {
        StatComparisonRow("Rushing Yards", p1.stats?.rushingYards, p2.stats?.rushingYards)
        StatComparisonRow("Rushing TDs", p1.stats?.rushingTouchdowns, p2.stats?.rushingTouchdowns)
        StatComparisonRow("Receptions", p1.stats?.receptions, p2.stats?.receptions)
        StatComparisonRow("Receiving Yards", p1.stats?.receivingYards, p2.stats?.receivingYards)
    }
}

@Composable
fun ReceiverStatsComparison(p1: PlayerDTO, p2: PlayerDTO) {
    Column(verticalArrangement = Arrangement.spacedBy(12.dp)) {
        StatComparisonRow("Receptions", p1.stats?.receptions, p2.stats?.receptions)
        StatComparisonRow("Receiving Yards", p1.stats?.receivingYards, p2.stats?.receivingYards)
        StatComparisonRow("Receiving TDs", p1.stats?.receivingTouchdowns, p2.stats?.receivingTouchdowns)
        StatComparisonRow("Targets", p1.stats?.targets, p2.stats?.targets)
    }
}

@Composable
fun StatComparisonRow(label: String, value1: Int?, value2: Int?, lowerIsBetter: Boolean = false) {
    Column(verticalArrangement = Arrangement.spacedBy(4.dp)) {
        Text(label, style = MaterialTheme.typography.labelMedium, fontWeight = FontWeight.Medium)

        Row(horizontalArrangement = Arrangement.spacedBy(12.dp)) {
            StatBar(value1, max(value1 ?: 0, value2 ?: 0), determineWinner(value1, value2, lowerIsBetter) == 1, Modifier.weight(1f), Alignment.End)
            StatBar(value2, max(value1 ?: 0, value2 ?: 0), determineWinner(value1, value2, lowerIsBetter) == 2, Modifier.weight(1f), Alignment.Start)
        }
    }
}

fun determineWinner(v1: Int?, v2: Int?, lowerIsBetter: Boolean): Int? {
    if (v1 == null || v2 == null || v1 == v2) return null
    return if (lowerIsBetter) if (v1 < v2) 1 else 2 else if (v1 > v2) 1 else 2
}

@Composable
fun StatBar(value: Int?, maxValue: Int, isWinner: Boolean, modifier: Modifier, alignment: Alignment.Horizontal) {
    Column(modifier = modifier, horizontalAlignment = alignment) {
        Text(
            value?.toString() ?: "-",
            style = MaterialTheme.typography.labelSmall,
            fontWeight = if (isWinner) FontWeight.Bold else FontWeight.Normal,
            color = if (isWinner) MaterialTheme.colorScheme.tertiary else MaterialTheme.colorScheme.onSurface
        )

        val width = if (maxValue > 0 && value != null) (value.toFloat() / maxValue.toFloat()) else 0f
        Box(Modifier.fillMaxWidth().height(8.dp)) {
            LinearProgressIndicator(
                progress = { width },
                modifier = Modifier.fillMaxWidth().clip(RoundedCornerShape(4.dp)),
                color = if (isWinner) MaterialTheme.colorScheme.tertiary else MaterialTheme.colorScheme.primary,
                trackColor = MaterialTheme.colorScheme.surfaceVariant
            )
        }
    }
}

@Composable
fun RecommendationSection(p1: PlayerDTO, p2: PlayerDTO, t1: TeamDTO, t2: TeamDTO) {
    Card(
        modifier = Modifier.fillMaxWidth().padding(16.dp),
        colors = CardDefaults.cardColors(containerColor = MaterialTheme.colorScheme.surfaceVariant)
    ) {
        Column(Modifier.padding(16.dp), verticalArrangement = Arrangement.spacedBy(8.dp)) {
            Text("Recommendation", style = MaterialTheme.typography.titleSmall, fontWeight = FontWeight.Bold)

            val message = if (p1.position != p2.position) {
                "Cannot compare players at different positions"
            } else if (p1.stats == null || p2.stats == null) {
                "Insufficient stats for comparison"
            } else {
                val score1 = calculateFantasyScore(p1)
                val score2 = calculateFantasyScore(p2)
                when {
                    kotlin.math.abs(score1 - score2) < 10.0 -> "Both players have similar production. Either is a good choice."
                    score1 > score2 -> "${p1.name} has the statistical edge with better overall production."
                    else -> "${p2.name} has the statistical edge with better overall production."
                }
            }

            Text(message, style = MaterialTheme.typography.bodyMedium)
        }
    }
}

fun calculateFantasyScore(player: PlayerDTO): Double {
    val stats = player.stats ?: return 0.0
    return when (player.position) {
        "QB" -> (stats.passingYards ?: 0) * 0.04 + (stats.passingTouchdowns ?: 0) * 4.0 - (stats.interceptions ?: 0) * 2.0
        "RB" -> (stats.rushingYards ?: 0) * 0.1 + (stats.rushingTouchdowns ?: 0) * 6.0 + (stats.receivingYards ?: 0) * 0.1 + (stats.receivingTouchdowns ?: 0) * 6.0
        "WR", "TE" -> (stats.receivingYards ?: 0) * 0.1 + (stats.receivingTouchdowns ?: 0) * 6.0 + (stats.receptions ?: 0) * 0.5
        else -> 0.0
    }
}
