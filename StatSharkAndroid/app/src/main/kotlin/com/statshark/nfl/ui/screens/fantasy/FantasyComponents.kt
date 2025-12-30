package com.statshark.nfl.ui.screens.fantasy

import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.Add
import androidx.compose.material.icons.filled.CheckCircle
import androidx.compose.material.icons.filled.Close
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.layout.ContentScale
import androidx.compose.ui.res.painterResource
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import coil.compose.AsyncImage
import com.statshark.nfl.R
import com.statshark.nfl.data.model.FantasyPlayer
import com.statshark.nfl.data.model.FantasyRoster
import com.statshark.nfl.data.model.PlayerDTO
import com.statshark.nfl.data.model.TeamDTO
import com.statshark.nfl.ui.screens.teams.getTeamHelmetResource
import com.statshark.nfl.ui.theme.TeamColors

/**
 * Fantasy Player Card for search/add
 */
@Composable
fun FantasyPlayerCard(
    player: PlayerDTO,
    team: TeamDTO,
    viewModel: FantasyViewModel
) {
    val isOnRoster = viewModel.isOnRoster(player.id)
    val isPositionFull = viewModel.isPositionFull(player.position)
    val fantasyPlayer = remember(player, team) { com.statshark.nfl.data.model.FantasyPlayer.from(player, team) }

    Card(
        modifier = Modifier.fillMaxWidth(),
        elevation = CardDefaults.cardElevation(defaultElevation = 2.dp)
    ) {
        Row(
            modifier = Modifier
                .fillMaxWidth()
                .padding(12.dp),
            verticalAlignment = Alignment.CenterVertically
        ) {
            // Player photo with team helmet placeholder
            val helmetResourceId = getTeamHelmetResource(team.abbreviation)
            AsyncImage(
                model = player.photoURL,
                contentDescription = player.name,
                placeholder = if (helmetResourceId != null) painterResource(helmetResourceId) else painterResource(R.drawable.ic_helmet_placeholder),
                error = if (helmetResourceId != null) painterResource(helmetResourceId) else painterResource(R.drawable.ic_helmet_placeholder),
                modifier = Modifier.size(60.dp).clip(CircleShape),
                contentScale = ContentScale.Crop
            )

            Spacer(Modifier.width(12.dp))

            Column(modifier = Modifier.weight(1f)) {
                Row(verticalAlignment = Alignment.CenterVertically) {
                    Text(player.name, style = MaterialTheme.typography.titleSmall, fontWeight = FontWeight.Bold, maxLines = 1)
                    player.jerseyNumber?.let {
                        Spacer(Modifier.width(8.dp))
                        Text("#$it", style = MaterialTheme.typography.bodySmall, color = MaterialTheme.colorScheme.onSurfaceVariant)
                    }
                }

                Row(verticalAlignment = Alignment.CenterVertically, horizontalArrangement = Arrangement.spacedBy(8.dp)) {
                    Surface(
                        shape = RoundedCornerShape(4.dp),
                        color = MaterialTheme.colorScheme.primaryContainer
                    ) {
                        Text(
                            player.position,
                            style = MaterialTheme.typography.labelSmall,
                            fontWeight = FontWeight.Bold,
                            color = MaterialTheme.colorScheme.onPrimaryContainer,
                            modifier = Modifier.padding(horizontal = 8.dp, vertical = 2.dp)
                        )
                    }

                    val helmetId = getTeamHelmetResource(team.abbreviation)
                    if (helmetId != null) {
                        androidx.compose.foundation.Image(
                            painter = painterResource(helmetId),
                            contentDescription = null,
                            modifier = Modifier.size(20.dp)
                        )
                    }
                    Text(team.abbreviation, style = MaterialTheme.typography.labelSmall, color = MaterialTheme.colorScheme.onSurfaceVariant)
                }

                if (player.stats != null) {
                    Text(
                        String.format("%.1f fantasy pts", fantasyPlayer.projectedPoints),
                        style = MaterialTheme.typography.labelMedium,
                        fontWeight = FontWeight.SemiBold,
                        color = MaterialTheme.colorScheme.tertiary
                    )
                }
            }

            if (isOnRoster) {
                Icon(Icons.Default.CheckCircle, "On roster", tint = MaterialTheme.colorScheme.tertiary, modifier = Modifier.size(28.dp))
            } else {
                IconButton(
                    onClick = { viewModel.addPlayer(player, team) },
                    enabled = !isPositionFull
                ) {
                    Icon(
                        Icons.Default.Add,
                        "Add to roster",
                        tint = if (isPositionFull) MaterialTheme.colorScheme.onSurfaceVariant else MaterialTheme.colorScheme.primary,
                        modifier = Modifier.size(28.dp)
                    )
                }
            }
        }
    }
}

/**
 * Fantasy Roster Player Card
 */
@Composable
fun FantasyRosterPlayerCard(
    player: FantasyPlayer,
    viewModel: FantasyViewModel
) {
    var showRemoveDialog by remember { mutableStateOf(false) }

    Card(
        modifier = Modifier.fillMaxWidth(),
        elevation = CardDefaults.cardElevation(defaultElevation = 2.dp)
    ) {
        Row(
            modifier = Modifier
                .fillMaxWidth()
                .padding(12.dp),
            verticalAlignment = Alignment.CenterVertically
        ) {
            val helmetResourceId = getTeamHelmetResource(player.teamAbbreviation)
            AsyncImage(
                model = player.photoURL,
                contentDescription = player.name,
                placeholder = if (helmetResourceId != null) painterResource(helmetResourceId) else painterResource(R.drawable.ic_helmet_placeholder),
                error = if (helmetResourceId != null) painterResource(helmetResourceId) else painterResource(R.drawable.ic_helmet_placeholder),
                modifier = Modifier.size(50.dp).clip(CircleShape),
                contentScale = ContentScale.Crop
            )

            Spacer(Modifier.width(12.dp))

            Column(modifier = Modifier.weight(1f)) {
                Row(verticalAlignment = Alignment.CenterVertically) {
                    Text(player.name, style = MaterialTheme.typography.titleSmall, fontWeight = FontWeight.Bold)
                    player.jerseyNumber?.let {
                        Spacer(Modifier.width(8.dp))
                        Text("#$it", style = MaterialTheme.typography.bodySmall, color = MaterialTheme.colorScheme.onSurfaceVariant)
                    }
                }

                Row(verticalAlignment = Alignment.CenterVertically, horizontalArrangement = Arrangement.spacedBy(8.dp)) {
                    val helmetId = getTeamHelmetResource(player.teamAbbreviation)
                    if (helmetId != null) {
                        androidx.compose.foundation.Image(
                            painter = painterResource(helmetId),
                            contentDescription = null,
                            modifier = Modifier.size(20.dp)
                        )
                    }
                    Text(player.teamAbbreviation, style = MaterialTheme.typography.labelSmall, color = MaterialTheme.colorScheme.onSurfaceVariant)
                }

                Text(
                    String.format("%.1f pts", player.projectedPoints),
                    style = MaterialTheme.typography.labelMedium,
                    fontWeight = FontWeight.SemiBold,
                    color = MaterialTheme.colorScheme.tertiary
                )
            }

            IconButton(onClick = { showRemoveDialog = true }) {
                Icon(Icons.Default.Close, "Remove", tint = MaterialTheme.colorScheme.error, modifier = Modifier.size(28.dp))
            }
        }
    }

    if (showRemoveDialog) {
        AlertDialog(
            onDismissRequest = { showRemoveDialog = false },
            title = { Text("Remove Player?") },
            text = { Text("Remove ${player.name} from your fantasy roster?") },
            confirmButton = {
                TextButton(onClick = {
                    viewModel.removePlayer(player)
                    showRemoveDialog = false
                }) {
                    Text("Remove", color = MaterialTheme.colorScheme.error)
                }
            },
            dismissButton = {
                TextButton(onClick = { showRemoveDialog = false }) {
                    Text("Cancel")
                }
            }
        )
    }
}

/**
 * Position Filter Chip
 */
@Composable
fun PositionFilterChip(
    position: String,
    isSelected: Boolean,
    isFull: Boolean,
    onClick: () -> Unit
) {
    val backgroundColor = when {
        isFull -> MaterialTheme.colorScheme.tertiaryContainer
        isSelected -> MaterialTheme.colorScheme.primary
        else -> MaterialTheme.colorScheme.surfaceVariant
    }

    val textColor = when {
        isFull -> MaterialTheme.colorScheme.onTertiaryContainer
        isSelected -> MaterialTheme.colorScheme.onPrimary
        else -> MaterialTheme.colorScheme.onSurfaceVariant
    }

    Surface(
        onClick = onClick,
        modifier = Modifier.height(32.dp),
        shape = RoundedCornerShape(16.dp),
        color = backgroundColor
    ) {
        Row(
            modifier = Modifier.padding(horizontal = 16.dp, vertical = 6.dp),
            verticalAlignment = Alignment.CenterVertically,
            horizontalArrangement = Arrangement.spacedBy(4.dp)
        ) {
            Text(
                text = position,
                style = MaterialTheme.typography.labelMedium,
                fontWeight = if (isSelected) FontWeight.Bold else FontWeight.Normal,
                color = textColor
            )
            if (isFull) {
                Icon(Icons.Default.CheckCircle, "Full", Modifier.size(14.dp), tint = textColor)
            }
        }
    }
}

/**
 * Team Filter Chip
 */
@Composable
fun TeamFilterChip(
    team: TeamDTO,
    isSelected: Boolean,
    onClick: () -> Unit
) {
    val backgroundColor = if (isSelected) {
        TeamColors.getPrimaryColor(team.abbreviation).copy(alpha = 0.2f)
    } else {
        MaterialTheme.colorScheme.surfaceVariant
    }

    val textColor = if (isSelected) {
        TeamColors.getPrimaryColor(team.abbreviation)
    } else {
        MaterialTheme.colorScheme.onSurfaceVariant
    }

    Surface(
        onClick = onClick,
        modifier = Modifier.height(32.dp),
        shape = RoundedCornerShape(16.dp),
        color = backgroundColor
    ) {
        Row(
            modifier = Modifier.padding(horizontal = 12.dp, vertical = 6.dp),
            verticalAlignment = Alignment.CenterVertically,
            horizontalArrangement = Arrangement.spacedBy(6.dp)
        ) {
            val helmetResourceId = getTeamHelmetResource(team.abbreviation)
            if (helmetResourceId != null) {
                androidx.compose.foundation.Image(
                    painter = painterResource(helmetResourceId),
                    contentDescription = null,
                    modifier = Modifier.size(20.dp)
                )
            }
            Text(
                text = team.abbreviation,
                style = MaterialTheme.typography.labelMedium,
                fontWeight = if (isSelected) FontWeight.Bold else FontWeight.Normal,
                color = textColor
            )
        }
    }
}

/**
 * Roster Summary Card
 */
@Composable
fun RosterSummaryCard(roster: FantasyRoster) {
    Card(
        modifier = Modifier.fillMaxWidth(),
        colors = CardDefaults.cardColors(containerColor = MaterialTheme.colorScheme.surfaceVariant)
    ) {
        Column(modifier = Modifier.padding(16.dp)) {
            Row(
                modifier = Modifier.fillMaxWidth(),
                horizontalArrangement = Arrangement.SpaceBetween
            ) {
                Column {
                    Text("Total Players", style = MaterialTheme.typography.labelSmall, color = MaterialTheme.colorScheme.onSurfaceVariant)
                    Text("${roster.totalPlayers}/${roster.maxPlayers}", style = MaterialTheme.typography.titleLarge, fontWeight = FontWeight.Bold)
                }

                Column(horizontalAlignment = Alignment.End) {
                    Text("Projected Points", style = MaterialTheme.typography.labelSmall, color = MaterialTheme.colorScheme.onSurfaceVariant)
                    Text(
                        String.format("%.1f", roster.totalProjectedPoints),
                        style = MaterialTheme.typography.titleLarge,
                        fontWeight = FontWeight.Bold,
                        color = MaterialTheme.colorScheme.primary
                    )
                }
            }

            Spacer(Modifier.height(16.dp))

            // Position breakdown
            Row(
                modifier = Modifier.fillMaxWidth(),
                horizontalArrangement = Arrangement.SpaceEvenly
            ) {
                PositionCount("QB", roster.quarterbacks.size, FantasyRoster.MAX_QBS)
                PositionCount("RB", roster.runningBacks.size, FantasyRoster.MAX_RBS)
                PositionCount("WR", roster.wideReceivers.size, FantasyRoster.MAX_WRS)
                PositionCount("TE", roster.tightEnds.size, FantasyRoster.MAX_TES)
            }
        }
    }
}

/**
 * Position Count Display
 */
@Composable
fun PositionCount(position: String, count: Int, max: Int) {
    Column(horizontalAlignment = Alignment.CenterHorizontally) {
        Text(position, style = MaterialTheme.typography.labelSmall, color = MaterialTheme.colorScheme.onSurfaceVariant)
        Text(
            "$count/$max",
            style = MaterialTheme.typography.labelMedium,
            fontWeight = FontWeight.SemiBold,
            color = if (count >= max) MaterialTheme.colorScheme.tertiary else MaterialTheme.colorScheme.onSurface
        )
    }
}

/**
 * Position Section in Roster
 */
@Composable
fun PositionSection(
    title: String,
    players: List<FantasyPlayer>,
    maxPlayers: Int,
    viewModel: FantasyViewModel
) {
    Column(verticalArrangement = Arrangement.spacedBy(8.dp)) {
        Row(horizontalArrangement = Arrangement.spacedBy(8.dp)) {
            Text(title, style = MaterialTheme.typography.titleMedium, fontWeight = FontWeight.Bold)
            Text("(${players.size}/$maxPlayers)", style = MaterialTheme.typography.bodyMedium, color = MaterialTheme.colorScheme.onSurfaceVariant)
        }

        players.forEach { player ->
            FantasyRosterPlayerCard(player = player, viewModel = viewModel)
        }
    }
}
