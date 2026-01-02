package com.statshark.nfl.ui.screens.teams

import androidx.compose.foundation.horizontalScroll
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
import com.statshark.nfl.data.model.*
import com.statshark.nfl.ui.components.FeedbackButton
import com.statshark.nfl.ui.theme.TeamColors
import java.text.SimpleDateFormat
import java.util.*

/**
 * Team Stats Detail Screen
 * Shows comprehensive team statistics including offensive, defensive stats, rankings, and more
 */
@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun TeamStatsDetailScreen(
    teamStats: TeamStatsDTO,
    navController: NavController
) {
    Scaffold(
        topBar = {
            TopAppBar(
                title = { Text("${teamStats.team.abbreviation} Stats") },
                navigationIcon = {
                    IconButton(onClick = { navController.navigateUp() }) {
                        Icon(Icons.Filled.ArrowBack, "Back")
                    }
                },
                actions = {
                    FeedbackButton(pageName = "Team Stats Detail")
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
            // Team Header
            TeamStatsHeader(teamStats.team, teamStats.season)

            Spacer(Modifier.height(16.dp))

            // Rankings
            teamStats.rankings?.let { rankings ->
                RankingsSection(rankings)
                Spacer(Modifier.height(16.dp))
            }

            // Offensive Stats
            OffensiveStatsSection(teamStats.offensiveStats)
            Spacer(Modifier.height(16.dp))

            // Defensive Stats
            DefensiveStatsSection(teamStats.defensiveStats)
            Spacer(Modifier.height(16.dp))

            // Key Players
            if (teamStats.keyPlayers.isNotEmpty()) {
                KeyPlayersSection(teamStats.keyPlayers)
                Spacer(Modifier.height(16.dp))
            }

            // Recent Games
            if (teamStats.recentGames.isNotEmpty()) {
                RecentGamesSection(teamStats.recentGames, teamStats.team.abbreviation)
                Spacer(Modifier.height(16.dp))
            }
        }
    }
}

@Composable
fun TeamStatsHeader(team: TeamDTO, season: Int) {
    Column(
        modifier = Modifier
            .fillMaxWidth()
            .padding(16.dp),
        horizontalAlignment = Alignment.CenterHorizontally
    ) {
        val helmetId = getTeamHelmetResource(team.abbreviation)
        if (helmetId != null) {
            AsyncImage(
                model = helmetId,
                contentDescription = team.name,
                placeholder = painterResource(R.drawable.ic_helmet_placeholder),
                modifier = Modifier.size(100.dp)
            )
        }

        Spacer(Modifier.height(12.dp))

        Text(
            team.name,
            style = MaterialTheme.typography.titleLarge,
            fontWeight = FontWeight.Bold,
            textAlign = TextAlign.Center
        )

        Text(
            "$season Season",
            style = MaterialTheme.typography.bodyMedium,
            color = MaterialTheme.colorScheme.onSurfaceVariant
        )

        Spacer(Modifier.height(12.dp))

        Row(
            horizontalArrangement = Arrangement.spacedBy(16.dp)
        ) {
            Column(horizontalAlignment = Alignment.CenterHorizontally) {
                Text(
                    team.conference ?: "",
                    style = MaterialTheme.typography.labelMedium,
                    color = MaterialTheme.colorScheme.onSurfaceVariant
                )
                Text(
                    "Conference",
                    style = MaterialTheme.typography.labelSmall,
                    color = MaterialTheme.colorScheme.onSurfaceVariant
                )
            }

            Divider(Modifier.width(1.dp).height(30.dp))

            Column(horizontalAlignment = Alignment.CenterHorizontally) {
                Text(
                    team.division,
                    style = MaterialTheme.typography.labelMedium,
                    color = MaterialTheme.colorScheme.onSurfaceVariant
                )
                Text(
                    "Division",
                    style = MaterialTheme.typography.labelSmall,
                    color = MaterialTheme.colorScheme.onSurfaceVariant
                )
            }
        }
    }
}

@Composable
fun RankingsSection(rankings: TeamRankingsDTO) {
    Column(
        modifier = Modifier
            .fillMaxWidth()
            .padding(horizontal = 16.dp)
    ) {
        Text(
            "Rankings",
            style = MaterialTheme.typography.titleMedium,
            fontWeight = FontWeight.Bold
        )

        Spacer(Modifier.height(12.dp))

        Row(
            modifier = Modifier.fillMaxWidth(),
            horizontalArrangement = Arrangement.spacedBy(12.dp)
        ) {
            rankings.offensiveRank?.let { rank ->
                RankCard("Offense", rank, Modifier.weight(1f))
            }
            rankings.defensiveRank?.let { rank ->
                RankCard("Defense", rank, Modifier.weight(1f))
            }
        }

        Spacer(Modifier.height(8.dp))

        Row(
            modifier = Modifier.horizontalScroll(rememberScrollState()),
            horizontalArrangement = Arrangement.spacedBy(12.dp)
        ) {
            rankings.passingOffenseRank?.let { rank ->
                RankCard("Pass Offense", rank, Modifier.width(120.dp))
            }
            rankings.rushingOffenseRank?.let { rank ->
                RankCard("Rush Offense", rank, Modifier.width(120.dp))
            }
            rankings.passingDefenseRank?.let { rank ->
                RankCard("Pass Defense", rank, Modifier.width(120.dp))
            }
            rankings.rushingDefenseRank?.let { rank ->
                RankCard("Rush Defense", rank, Modifier.width(120.dp))
            }
        }
    }
}

@Composable
fun RankCard(title: String, rank: Int, modifier: Modifier = Modifier) {
    Card(
        modifier = modifier,
        colors = CardDefaults.cardColors(
            containerColor = MaterialTheme.colorScheme.surfaceVariant
        )
    ) {
        Column(
            modifier = Modifier
                .fillMaxWidth()
                .padding(12.dp),
            horizontalAlignment = Alignment.CenterHorizontally
        ) {
            Text(
                title,
                style = MaterialTheme.typography.labelSmall,
                color = MaterialTheme.colorScheme.onSurfaceVariant
            )

            Text(
                "#$rank",
                style = MaterialTheme.typography.titleMedium,
                fontWeight = FontWeight.Bold,
                color = getRankColor(rank)
            )
        }
    }
}

fun getRankColor(rank: Int): Color {
    return when (rank) {
        in 1..5 -> Color(0xFF4CAF50) // Green
        in 6..16 -> Color(0xFF2196F3) // Blue
        in 17..26 -> Color(0xFFFF9800) // Orange
        else -> Color(0xFFF44336) // Red
    }
}

@Composable
fun OffensiveStatsSection(offensiveStats: OffensiveStatsDTO) {
    Column(
        modifier = Modifier
            .fillMaxWidth()
            .padding(horizontal = 16.dp)
    ) {
        Text(
            "Offensive Stats",
            style = MaterialTheme.typography.titleMedium,
            fontWeight = FontWeight.Bold
        )

        Spacer(Modifier.height(12.dp))

        Column(verticalArrangement = Arrangement.spacedBy(8.dp)) {
            StatsRow("Points Per Game", String.format("%.1f", offensiveStats.pointsPerGame))
            StatsRow("Yards Per Game", String.format("%.1f", offensiveStats.yardsPerGame))
            StatsRow("Passing Yards/Game", String.format("%.1f", offensiveStats.passingYardsPerGame))
            StatsRow("Rushing Yards/Game", String.format("%.1f", offensiveStats.rushingYardsPerGame))

            offensiveStats.thirdDownConversionRate?.let { rate ->
                StatsRow("3rd Down Conversion", String.format("%.1f%%", rate * 100))
            }

            offensiveStats.redZoneEfficiency?.let { eff ->
                StatsRow("Red Zone Efficiency", String.format("%.1f%%", eff * 100))
            }

            offensiveStats.turnoversPerGame?.let { to ->
                StatsRow("Turnovers Per Game", String.format("%.1f", to))
            }
        }
    }
}

@Composable
fun DefensiveStatsSection(defensiveStats: DefensiveStatsDTO) {
    Column(
        modifier = Modifier
            .fillMaxWidth()
            .padding(horizontal = 16.dp)
    ) {
        Text(
            "Defensive Stats",
            style = MaterialTheme.typography.titleMedium,
            fontWeight = FontWeight.Bold
        )

        Spacer(Modifier.height(12.dp))

        Column(verticalArrangement = Arrangement.spacedBy(8.dp)) {
            StatsRow("Points Allowed/Game", String.format("%.1f", defensiveStats.pointsAllowedPerGame))
            StatsRow("Yards Allowed/Game", String.format("%.1f", defensiveStats.yardsAllowedPerGame))
            StatsRow("Pass Yards Allowed/Game", String.format("%.1f", defensiveStats.passingYardsAllowedPerGame))
            StatsRow("Rush Yards Allowed/Game", String.format("%.1f", defensiveStats.rushingYardsAllowedPerGame))

            defensiveStats.sacksPerGame?.let { sacks ->
                StatsRow("Sacks Per Game", String.format("%.1f", sacks))
            }

            defensiveStats.interceptionsPerGame?.let { ints ->
                StatsRow("Interceptions Per Game", String.format("%.1f", ints))
            }

            defensiveStats.forcedFumblesPerGame?.let { fumbles ->
                StatsRow("Forced Fumbles/Game", String.format("%.1f", fumbles))
            }
        }
    }
}

@Composable
fun StatsRow(label: String, value: String) {
    Card(
        colors = CardDefaults.cardColors(
            containerColor = MaterialTheme.colorScheme.surfaceVariant
        )
    ) {
        Row(
            modifier = Modifier
                .fillMaxWidth()
                .padding(horizontal = 16.dp, vertical = 12.dp),
            horizontalArrangement = Arrangement.SpaceBetween
        ) {
            Text(
                label,
                style = MaterialTheme.typography.bodyMedium,
                color = MaterialTheme.colorScheme.onSurfaceVariant
            )

            Text(
                value,
                style = MaterialTheme.typography.bodyMedium,
                fontWeight = FontWeight.SemiBold
            )
        }
    }
}

@Composable
fun KeyPlayersSection(players: List<PlayerDTO>) {
    Column(
        modifier = Modifier
            .fillMaxWidth()
            .padding(horizontal = 16.dp)
    ) {
        Text(
            "Key Players",
            style = MaterialTheme.typography.titleMedium,
            fontWeight = FontWeight.Bold
        )

        Spacer(Modifier.height(12.dp))

        Row(
            modifier = Modifier.horizontalScroll(rememberScrollState()),
            horizontalArrangement = Arrangement.spacedBy(12.dp)
        ) {
            players.forEach { player ->
                KeyPlayerCard(player)
            }
        }
    }
}

@Composable
fun KeyPlayerCard(player: PlayerDTO) {
    Card(
        modifier = Modifier.width(100.dp),
        colors = CardDefaults.cardColors(
            containerColor = MaterialTheme.colorScheme.surfaceVariant
        )
    ) {
        Column(
            modifier = Modifier
                .fillMaxWidth()
                .padding(12.dp),
            horizontalAlignment = Alignment.CenterHorizontally,
            verticalArrangement = Arrangement.spacedBy(8.dp)
        ) {
            AsyncImage(
                model = player.photoURL,
                contentDescription = player.name,
                placeholder = painterResource(R.drawable.ic_helmet_placeholder),
                error = painterResource(R.drawable.ic_helmet_placeholder),
                modifier = Modifier
                    .size(60.dp)
                    .clip(CircleShape),
                contentScale = ContentScale.Crop
            )

            Text(
                player.name,
                style = MaterialTheme.typography.labelSmall,
                fontWeight = FontWeight.Medium,
                textAlign = TextAlign.Center,
                maxLines = 2
            )

            Text(
                player.position,
                style = MaterialTheme.typography.labelSmall,
                color = MaterialTheme.colorScheme.onSurfaceVariant
            )
        }
    }
}

@Composable
fun RecentGamesSection(games: List<GameDTO>, teamAbbr: String) {
    Column(
        modifier = Modifier
            .fillMaxWidth()
            .padding(horizontal = 16.dp)
    ) {
        Text(
            "Recent Games",
            style = MaterialTheme.typography.titleMedium,
            fontWeight = FontWeight.Bold
        )

        Spacer(Modifier.height(12.dp))

        Column(verticalArrangement = Arrangement.spacedBy(8.dp)) {
            games.take(5).forEach { game ->
                RecentGameCard(game, teamAbbr)
            }
        }
    }
}

@Composable
fun RecentGameCard(game: GameDTO, teamAbbr: String) {
    val isHome = game.homeTeam.abbreviation == teamAbbr
    val opponent = if (isHome) game.awayTeam.abbreviation else game.homeTeam.abbreviation

    Card(
        colors = CardDefaults.cardColors(
            containerColor = MaterialTheme.colorScheme.surfaceVariant
        )
    ) {
        Row(
            modifier = Modifier
                .fillMaxWidth()
                .padding(16.dp),
            horizontalArrangement = Arrangement.SpaceBetween,
            verticalAlignment = Alignment.CenterVertically
        ) {
            Column {
                Text(
                    "${if (isHome) "vs" else "@"} $opponent",
                    style = MaterialTheme.typography.bodyMedium,
                    fontWeight = FontWeight.Medium
                )

                Text(
                    formatGameDate(game.scheduledDate),
                    style = MaterialTheme.typography.labelSmall,
                    color = MaterialTheme.colorScheme.onSurfaceVariant
                )
            }

            if (game.homeScore != null && game.awayScore != null) {
                val teamScore = if (isHome) game.homeScore else game.awayScore
                val oppScore = if (isHome) game.awayScore else game.homeScore
                val won = teamScore!! > oppScore!!

                Text(
                    "$teamScore - $oppScore",
                    style = MaterialTheme.typography.bodyMedium,
                    fontWeight = FontWeight.Bold,
                    color = if (won) Color(0xFF4CAF50) else Color(0xFFF44336)
                )
            } else {
                Text(
                    game.status ?: "Scheduled",
                    style = MaterialTheme.typography.labelSmall,
                    color = MaterialTheme.colorScheme.onSurfaceVariant
                )
            }
        }
    }
}

fun formatGameDate(dateString: String): String {
    return try {
        val parser = SimpleDateFormat("yyyy-MM-dd", Locale.getDefault())
        val formatter = SimpleDateFormat("MMM dd, yyyy", Locale.getDefault())
        val date = parser.parse(dateString)
        date?.let { formatter.format(it) } ?: dateString
    } catch (e: Exception) {
        dateString
    }
}
