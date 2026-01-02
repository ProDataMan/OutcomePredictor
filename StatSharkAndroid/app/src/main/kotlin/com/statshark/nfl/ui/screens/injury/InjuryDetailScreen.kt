package com.statshark.nfl.ui.screens.injury

import androidx.compose.foundation.background
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.foundation.verticalScroll
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.*
import androidx.compose.material3.*
import androidx.compose.runtime.Composable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.navigation.NavController
import com.statshark.nfl.data.model.TeamInjuryReportDTO
import com.statshark.nfl.data.model.InjuredPlayerDTO
import com.statshark.nfl.ui.components.FeedbackButton
import kotlin.math.roundToInt

/**
 * Injury Detail Screen
 * Displays detailed injury report for teams
 */
@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun InjuryDetailScreen(
    homeTeamReport: TeamInjuryReportDTO,
    awayTeamReport: TeamInjuryReportDTO,
    navController: NavController
) {
    val scrollState = rememberScrollState()

    Scaffold(
        topBar = {
            TopAppBar(
                title = { Text("Injury Report") },
                navigationIcon = {
                    IconButton(onClick = { navController.navigateUp() }) {
                        Icon(Icons.Filled.ArrowBack, contentDescription = "Back")
                    }
                },
                actions = {
                    FeedbackButton(pageName = "Injury Report")
                },
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
                .verticalScroll(scrollState)
                .padding(16.dp),
            verticalArrangement = Arrangement.spacedBy(16.dp)
        ) {
            // Injury Impact Comparison
            InjuryImpactComparisonCard(homeTeamReport, awayTeamReport)

            // Home Team Injuries
            TeamInjuryCard(homeTeamReport, isHome = true)

            // Away Team Injuries
            TeamInjuryCard(awayTeamReport, isHome = false)

            // Injury Legend
            InjuryLegendCard()
        }
    }
}

/**
 * Injury impact comparison card
 */
@Composable
private fun InjuryImpactComparisonCard(
    homeTeamReport: TeamInjuryReportDTO,
    awayTeamReport: TeamInjuryReportDTO
) {
    Surface(
        modifier = Modifier.fillMaxWidth(),
        shape = RoundedCornerShape(12.dp),
        color = MaterialTheme.colorScheme.primaryContainer
    ) {
        Column(
            modifier = Modifier.padding(16.dp),
            verticalArrangement = Arrangement.spacedBy(12.dp)
        ) {
            Text(
                text = "Injury Impact Analysis",
                style = MaterialTheme.typography.titleMedium,
                fontWeight = FontWeight.Bold,
                color = MaterialTheme.colorScheme.onPrimaryContainer
            )

            // Home team impact
            TeamImpactRow(
                teamName = homeTeamReport.team.abbreviation,
                impact = homeTeamReport.totalImpact,
                keyInjuryCount = homeTeamReport.keyInjuries.size
            )

            Divider(color = MaterialTheme.colorScheme.onPrimaryContainer.copy(alpha = 0.2f))

            // Away team impact
            TeamImpactRow(
                teamName = awayTeamReport.team.abbreviation,
                impact = awayTeamReport.totalImpact,
                keyInjuryCount = awayTeamReport.keyInjuries.size
            )

            // Impact differential analysis
            val impactDiff = homeTeamReport.totalImpact - awayTeamReport.totalImpact
            if (kotlin.math.abs(impactDiff) > 0.1) {
                Spacer(modifier = Modifier.height(4.dp))
                val advantageTeam = if (impactDiff < 0) {
                    homeTeamReport.team.abbreviation
                } else {
                    awayTeamReport.team.abbreviation
                }
                Text(
                    text = "⚠️ $advantageTeam has a health advantage",
                    style = MaterialTheme.typography.bodyMedium,
                    fontWeight = FontWeight.SemiBold,
                    color = MaterialTheme.colorScheme.tertiary
                )
            }
        }
    }
}

/**
 * Team impact row showing impact metrics
 */
@Composable
private fun TeamImpactRow(
    teamName: String,
    impact: Double,
    keyInjuryCount: Int
) {
    Row(
        modifier = Modifier.fillMaxWidth(),
        horizontalArrangement = Arrangement.SpaceBetween,
        verticalAlignment = Alignment.CenterVertically
    ) {
        Column(
            modifier = Modifier.weight(1f),
            verticalArrangement = Arrangement.spacedBy(4.dp)
        ) {
            Text(
                text = teamName,
                style = MaterialTheme.typography.titleMedium,
                fontWeight = FontWeight.Bold,
                color = MaterialTheme.colorScheme.onPrimaryContainer
            )
            Text(
                text = "$keyInjuryCount key ${if (keyInjuryCount == 1) "injury" else "injuries"}",
                style = MaterialTheme.typography.bodySmall,
                color = MaterialTheme.colorScheme.onPrimaryContainer.copy(alpha = 0.7f)
            )
        }

        // Impact severity badge
        ImpactBadge(impact)
    }
}

/**
 * Impact severity badge
 */
@Composable
private fun ImpactBadge(impact: Double) {
    val (color, label) = when {
        impact < 0.2 -> Pair(Color(0xFF4CAF50), "Low")
        impact < 0.4 -> Pair(Color(0xFFFFC107), "Medium")
        impact < 0.6 -> Pair(Color(0xFFFF9800), "High")
        else -> Pair(Color(0xFFF44336), "Severe")
    }

    Surface(
        shape = RoundedCornerShape(8.dp),
        color = color.copy(alpha = 0.2f),
        modifier = Modifier
    ) {
        Row(
            modifier = Modifier.padding(horizontal = 12.dp, vertical = 6.dp),
            horizontalArrangement = Arrangement.spacedBy(6.dp),
            verticalAlignment = Alignment.CenterVertically
        ) {
            Box(
                modifier = Modifier
                    .size(8.dp)
                    .clip(CircleShape)
                    .background(color)
            )
            Text(
                text = label,
                style = MaterialTheme.typography.labelMedium,
                fontWeight = FontWeight.Bold,
                color = color
            )
        }
    }
}

/**
 * Team injury card showing all injuries
 */
@Composable
private fun TeamInjuryCard(
    report: TeamInjuryReportDTO,
    isHome: Boolean
) {
    val location = if (isHome) "Home" else "Away"

    Surface(
        modifier = Modifier.fillMaxWidth(),
        shape = RoundedCornerShape(12.dp),
        color = MaterialTheme.colorScheme.surface
    ) {
        Column(
            modifier = Modifier.padding(16.dp),
            verticalArrangement = Arrangement.spacedBy(12.dp)
        ) {
            // Header
            Row(
                modifier = Modifier.fillMaxWidth(),
                horizontalArrangement = Arrangement.SpaceBetween,
                verticalAlignment = Alignment.CenterVertically
            ) {
                Column {
                    Text(
                        text = "${report.team.name}",
                        style = MaterialTheme.typography.titleMedium,
                        fontWeight = FontWeight.Bold,
                        color = MaterialTheme.colorScheme.onSurface
                    )
                    Text(
                        text = "$location Team • ${report.injuries.size} ${if (report.injuries.size == 1) "injury" else "injuries"}",
                        style = MaterialTheme.typography.bodySmall,
                        color = MaterialTheme.colorScheme.onSurface.copy(alpha = 0.6f)
                    )
                }
            }

            Divider()

            // Injuries list
            if (report.injuries.isEmpty()) {
                NoInjuriesCard()
            } else {
                report.injuries.forEach { injury ->
                    InjuryListItem(injury)
                }
            }
        }
    }
}

/**
 * No injuries card
 */
@Composable
private fun NoInjuriesCard() {
    Surface(
        modifier = Modifier.fillMaxWidth(),
        shape = RoundedCornerShape(8.dp),
        color = MaterialTheme.colorScheme.primaryContainer.copy(alpha = 0.3f)
    ) {
        Row(
            modifier = Modifier.padding(16.dp),
            horizontalArrangement = Arrangement.spacedBy(12.dp),
            verticalAlignment = Alignment.CenterVertically
        ) {
            Icon(
                imageVector = Icons.Filled.Check,
                contentDescription = null,
                tint = MaterialTheme.colorScheme.primary
            )
            Text(
                text = "No reported injuries",
                style = MaterialTheme.typography.bodyMedium,
                color = MaterialTheme.colorScheme.onSurface
            )
        }
    }
}

/**
 * Individual injury list item
 */
@Composable
private fun InjuryListItem(injury: InjuredPlayerDTO) {
    Surface(
        modifier = Modifier.fillMaxWidth(),
        shape = RoundedCornerShape(8.dp),
        color = MaterialTheme.colorScheme.surfaceVariant
    ) {
        Column(
            modifier = Modifier.padding(12.dp),
            verticalArrangement = Arrangement.spacedBy(8.dp)
        ) {
            // Player name and status
            Row(
                modifier = Modifier.fillMaxWidth(),
                horizontalArrangement = Arrangement.SpaceBetween,
                verticalAlignment = Alignment.CenterVertically
            ) {
                Column(
                    modifier = Modifier.weight(1f),
                    verticalArrangement = Arrangement.spacedBy(2.dp)
                ) {
                    Text(
                        text = injury.name,
                        style = MaterialTheme.typography.bodyLarge,
                        fontWeight = FontWeight.Bold,
                        color = MaterialTheme.colorScheme.onSurface
                    )
                    Text(
                        text = injury.position,
                        style = MaterialTheme.typography.bodySmall,
                        color = MaterialTheme.colorScheme.onSurface.copy(alpha = 0.6f)
                    )
                }

                InjuryStatusBadge(injury.status)
            }

            // Description if available
            if (!injury.description.isNullOrBlank()) {
                Text(
                    text = injury.description,
                    style = MaterialTheme.typography.bodyMedium,
                    color = MaterialTheme.colorScheme.onSurface.copy(alpha = 0.7f)
                )
            }

            // Impact indicator
            val impact = injury.calculateImpact()
            if (impact > 0.3) {
                Row(
                    horizontalArrangement = Arrangement.spacedBy(6.dp),
                    verticalAlignment = Alignment.CenterVertically
                ) {
                    Icon(
                        imageVector = Icons.Filled.Warning,
                        contentDescription = null,
                        modifier = Modifier.size(16.dp),
                        tint = MaterialTheme.colorScheme.error
                    )
                    Text(
                        text = "High impact player",
                        style = MaterialTheme.typography.labelSmall,
                        fontWeight = FontWeight.SemiBold,
                        color = MaterialTheme.colorScheme.error
                    )
                }
            }
        }
    }
}

/**
 * Injury status badge
 */
@Composable
private fun InjuryStatusBadge(status: String) {
    val (color, backgroundColor) = when (status.uppercase()) {
        "OUT" -> Pair(Color(0xFFD32F2F), Color(0xFFFFCDD2))
        "DOUBTFUL" -> Pair(Color(0xFFE64A19), Color(0xFFFFCCBC))
        "QUESTIONABLE" -> Pair(Color(0xFFF57C00), Color(0xFFFFE0B2))
        "PROBABLE" -> Pair(Color(0xFFFBC02D), Color(0xFFFFF9C4))
        else -> Pair(Color(0xFF388E3C), Color(0xFFC8E6C9))
    }

    Surface(
        shape = RoundedCornerShape(6.dp),
        color = backgroundColor.copy(alpha = 0.3f)
    ) {
        Text(
            text = status,
            style = MaterialTheme.typography.labelMedium,
            fontWeight = FontWeight.Bold,
            color = color,
            modifier = Modifier.padding(horizontal = 8.dp, vertical = 4.dp)
        )
    }
}

/**
 * Injury legend card explaining status levels
 */
@Composable
private fun InjuryLegendCard() {
    Surface(
        modifier = Modifier.fillMaxWidth(),
        shape = RoundedCornerShape(12.dp),
        color = MaterialTheme.colorScheme.surfaceVariant.copy(alpha = 0.5f)
    ) {
        Column(
            modifier = Modifier.padding(16.dp),
            verticalArrangement = Arrangement.spacedBy(8.dp)
        ) {
            Text(
                text = "Injury Status Guide",
                style = MaterialTheme.typography.titleSmall,
                fontWeight = FontWeight.Bold,
                color = MaterialTheme.colorScheme.onSurfaceVariant
            )

            LegendItem("Out", "Will not play in the game")
            LegendItem("Doubtful", "Unlikely to play (25% chance)")
            LegendItem("Questionable", "Uncertain to play (50% chance)")
            LegendItem("Probable", "Likely to play (75% chance)")
            LegendItem("Healthy", "No injury concerns")
        }
    }
}

/**
 * Individual legend item
 */
@Composable
private fun LegendItem(status: String, description: String) {
    Row(
        modifier = Modifier.fillMaxWidth(),
        horizontalArrangement = Arrangement.spacedBy(8.dp),
        verticalAlignment = Alignment.Top
    ) {
        InjuryStatusBadge(status)
        Text(
            text = description,
            style = MaterialTheme.typography.bodySmall,
            color = MaterialTheme.colorScheme.onSurfaceVariant.copy(alpha = 0.7f),
            modifier = Modifier.weight(1f)
        )
    }
}
