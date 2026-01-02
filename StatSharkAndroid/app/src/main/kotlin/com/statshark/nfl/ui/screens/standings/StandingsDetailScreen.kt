package com.statshark.nfl.ui.screens.standings

import androidx.compose.foundation.layout.*
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.verticalScroll
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.ArrowBack
import androidx.compose.material3.*
import androidx.compose.runtime.Composable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.res.painterResource
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.dp
import androidx.navigation.NavController
import coil.compose.AsyncImage
import com.statshark.nfl.R
import com.statshark.nfl.data.model.DivisionStandings
import com.statshark.nfl.data.model.TeamStandings
import com.statshark.nfl.ui.components.FeedbackButton
import com.statshark.nfl.ui.screens.teams.getTeamHelmetResource

/**
 * Standings Detail Screen
 * Shows detailed standings for a specific division
 */
@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun StandingsDetailScreen(
    division: DivisionStandings,
    season: Int,
    navController: NavController
) {
    Scaffold(
        topBar = {
            TopAppBar(
                title = { Text("${division.conference} ${division.division}") },
                navigationIcon = {
                    IconButton(onClick = { navController.navigateUp() }) {
                        Icon(Icons.Filled.ArrowBack, "Back")
                    }
                },
                actions = {
                    FeedbackButton(pageName = "Standings Detail")
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
            // Division Header
            DivisionHeader(division, season)

            Spacer(Modifier.height(16.dp))

            // Standings Table
            StandingsTable(division.teams)

            Spacer(Modifier.height(24.dp))

            // Division Stats Summary
            DivisionStatsSummary(division)

            Spacer(Modifier.height(16.dp))
        }
    }
}

@Composable
fun DivisionHeader(division: DivisionStandings, season: Int) {
    Column(
        modifier = Modifier
            .fillMaxWidth()
            .padding(16.dp),
        horizontalAlignment = Alignment.CenterHorizontally
    ) {
        Text(
            "${division.conference} ${division.division}",
            style = MaterialTheme.typography.titleLarge,
            fontWeight = FontWeight.Bold
        )

        Text(
            "$season Season",
            style = MaterialTheme.typography.bodyMedium,
            color = MaterialTheme.colorScheme.onSurfaceVariant
        )
    }
}

@Composable
fun StandingsTable(teams: List<TeamStandings>) {
    Column(
        modifier = Modifier
            .fillMaxWidth()
            .padding(horizontal = 16.dp)
    ) {
        // Header Row
        Card(
            colors = CardDefaults.cardColors(
                containerColor = MaterialTheme.colorScheme.surfaceVariant
            )
        ) {
            Row(
                modifier = Modifier
                    .fillMaxWidth()
                    .padding(horizontal = 12.dp, vertical = 8.dp),
                horizontalArrangement = Arrangement.SpaceBetween
            ) {
                Text(
                    "RK",
                    style = MaterialTheme.typography.labelSmall,
                    fontWeight = FontWeight.SemiBold,
                    modifier = Modifier.width(30.dp)
                )

                Text(
                    "Team",
                    style = MaterialTheme.typography.labelSmall,
                    fontWeight = FontWeight.SemiBold,
                    modifier = Modifier.weight(1f)
                )

                Text(
                    "W-L",
                    style = MaterialTheme.typography.labelSmall,
                    fontWeight = FontWeight.SemiBold,
                    modifier = Modifier.width(60.dp),
                    textAlign = TextAlign.Center
                )

                Text(
                    "PCT",
                    style = MaterialTheme.typography.labelSmall,
                    fontWeight = FontWeight.SemiBold,
                    modifier = Modifier.width(50.dp),
                    textAlign = TextAlign.Center
                )

                Text(
                    "PF",
                    style = MaterialTheme.typography.labelSmall,
                    fontWeight = FontWeight.SemiBold,
                    modifier = Modifier.width(40.dp),
                    textAlign = TextAlign.Center
                )

                Text(
                    "PA",
                    style = MaterialTheme.typography.labelSmall,
                    fontWeight = FontWeight.SemiBold,
                    modifier = Modifier.width(40.dp),
                    textAlign = TextAlign.Center
                )
            }
        }

        Spacer(Modifier.height(8.dp))

        // Team Rows
        teams.forEachIndexed { index, standing ->
            StandingRowCard(rank = index + 1, standing = standing)

            if (index < teams.size - 1) {
                Spacer(Modifier.height(4.dp))
            }
        }
    }
}

@Composable
fun StandingRowCard(rank: Int, standing: TeamStandings) {
    Card(
        colors = CardDefaults.cardColors(
            containerColor = MaterialTheme.colorScheme.surface
        )
    ) {
        Row(
            modifier = Modifier
                .fillMaxWidth()
                .padding(horizontal = 12.dp, vertical = 12.dp),
            horizontalArrangement = Arrangement.SpaceBetween,
            verticalAlignment = Alignment.CenterVertically
        ) {
            // Rank
            Text(
                "$rank",
                style = MaterialTheme.typography.bodyMedium,
                fontWeight = FontWeight.SemiBold,
                color = getRankColor(rank),
                modifier = Modifier.width(30.dp)
            )

            // Team
            Row(
                modifier = Modifier.weight(1f),
                horizontalArrangement = Arrangement.spacedBy(8.dp),
                verticalAlignment = Alignment.CenterVertically
            ) {
                val helmetId = getTeamHelmetResource(standing.team.abbreviation)
                if (helmetId != null) {
                    AsyncImage(
                        model = helmetId,
                        contentDescription = standing.team.name,
                        placeholder = painterResource(R.drawable.ic_helmet_placeholder),
                        modifier = Modifier.size(30.dp).clip(CircleShape)
                    )
                }

                Column {
                    Text(
                        standing.team.abbreviation,
                        style = MaterialTheme.typography.bodyMedium,
                        fontWeight = FontWeight.SemiBold
                    )

                    Text(
                        standing.streak,
                        style = MaterialTheme.typography.labelSmall,
                        color = getStreakColor(standing.streak)
                    )
                }
            }

            // W-L
            Text(
                standing.record,
                style = MaterialTheme.typography.bodyMedium,
                modifier = Modifier.width(60.dp),
                textAlign = TextAlign.Center
            )

            // PCT
            Text(
                String.format(".%03d", (standing.winPercentage * 1000).toInt()),
                style = MaterialTheme.typography.bodyMedium,
                modifier = Modifier.width(50.dp),
                textAlign = TextAlign.Center
            )

            // PF
            Text(
                "${standing.pointsFor}",
                style = MaterialTheme.typography.bodyMedium,
                modifier = Modifier.width(40.dp),
                textAlign = TextAlign.Center
            )

            // PA
            Text(
                "${standing.pointsAgainst}",
                style = MaterialTheme.typography.bodyMedium,
                modifier = Modifier.width(40.dp),
                textAlign = TextAlign.Center
            )
        }
    }
}

@Composable
fun DivisionStatsSummary(division: DivisionStandings) {
    Column(
        modifier = Modifier
            .fillMaxWidth()
            .padding(horizontal = 16.dp)
    ) {
        Text(
            "Division Statistics",
            style = MaterialTheme.typography.titleMedium,
            fontWeight = FontWeight.Bold
        )

        Spacer(Modifier.height(12.dp))

        Row(
            modifier = Modifier.fillMaxWidth(),
            horizontalArrangement = Arrangement.spacedBy(12.dp)
        ) {
            DivisionStatCard(
                title = "Avg Points For",
                value = String.format("%.1f", calculateAveragePointsFor(division)),
                modifier = Modifier.weight(1f)
            )

            DivisionStatCard(
                title = "Avg Points Against",
                value = String.format("%.1f", calculateAveragePointsAgainst(division)),
                modifier = Modifier.weight(1f)
            )
        }

        Spacer(Modifier.height(8.dp))

        Row(
            modifier = Modifier.fillMaxWidth(),
            horizontalArrangement = Arrangement.spacedBy(12.dp)
        ) {
            DivisionStatCard(
                title = "Division Leader",
                value = division.teams.firstOrNull()?.team?.abbreviation ?: "-",
                modifier = Modifier.weight(1f)
            )

            DivisionStatCard(
                title = "Best Record",
                value = division.teams.firstOrNull()?.record ?: "-",
                modifier = Modifier.weight(1f)
            )
        }
    }
}

@Composable
fun DivisionStatCard(title: String, value: String, modifier: Modifier = Modifier) {
    Card(
        modifier = modifier,
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
                title,
                style = MaterialTheme.typography.labelSmall,
                color = MaterialTheme.colorScheme.onSurfaceVariant,
                textAlign = TextAlign.Center
            )

            Spacer(Modifier.height(8.dp))

            Text(
                value,
                style = MaterialTheme.typography.titleMedium,
                fontWeight = FontWeight.Bold
            )
        }
    }
}

fun getRankColor(rank: Int): Color {
    return when (rank) {
        1 -> Color(0xFF4CAF50) // Green
        2 -> Color(0xFF2196F3) // Blue
        else -> Color.Gray
    }
}

fun getStreakColor(streak: String): Color {
    return when {
        streak.startsWith("W") -> Color(0xFF4CAF50) // Green
        streak.startsWith("L") -> Color(0xFFF44336) // Red
        else -> Color.Gray
    }
}

fun calculateAveragePointsFor(division: DivisionStandings): Double {
    val total = division.teams.sumOf { it.pointsFor }
    return total.toDouble() / division.teams.size
}

fun calculateAveragePointsAgainst(division: DivisionStandings): Double {
    val total = division.teams.sumOf { it.pointsAgainst }
    return total.toDouble() / division.teams.size
}
