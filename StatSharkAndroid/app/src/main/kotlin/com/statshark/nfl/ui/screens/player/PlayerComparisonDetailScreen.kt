package com.statshark.nfl.ui.screens.player

import androidx.compose.foundation.horizontalScroll
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.foundation.verticalScroll
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.ArrowBack
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
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
import java.text.SimpleDateFormat
import java.util.*

/**
 * Enhanced Player Comparison Screen
 * Supports comparing multiple players using PlayerComparisonResponse DTO
 */
@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun PlayerComparisonDetailScreen(
    comparison: PlayerComparisonResponse,
    navController: NavController
) {
    var selectedCategory by remember { mutableStateOf(StatCategory.GENERAL) }

    Scaffold(
        topBar = {
            TopAppBar(
                title = { Text("Player Comparison") },
                navigationIcon = {
                    IconButton(onClick = { navController.navigateUp() }) {
                        Icon(Icons.Filled.ArrowBack, "Back")
                    }
                },
                actions = {
                    FeedbackButton(pageName = "Player Comparison Detail")
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
                    .horizontalScroll(rememberScrollState())
                    .padding(16.dp),
                horizontalArrangement = Arrangement.spacedBy(16.dp)
            ) {
                comparison.players.forEach { player ->
                    PlayerComparisonCard(player)
                }
            }

            // Category Selector
            CategorySelector(
                selectedCategory = selectedCategory,
                onCategorySelected = { selectedCategory = it },
                modifier = Modifier.padding(horizontal = 16.dp)
            )

            Spacer(Modifier.height(16.dp))

            // Stats Grid
            val filteredComparisons = comparison.comparisons.filter { it.category == selectedCategory }

            if (filteredComparisons.isEmpty()) {
                Text(
                    "No ${selectedCategory.value} statistics available",
                    modifier = Modifier
                        .fillMaxWidth()
                        .padding(32.dp),
                    textAlign = TextAlign.Center,
                    color = MaterialTheme.colorScheme.onSurfaceVariant
                )
            } else {
                Column(
                    modifier = Modifier.padding(horizontal = 16.dp),
                    verticalArrangement = Arrangement.spacedBy(12.dp)
                ) {
                    filteredComparisons.forEach { statComparison ->
                        StatComparisonCard(statComparison)
                    }
                }
            }

            // Season Info
            SeasonInfo(
                season = comparison.season,
                generatedAt = comparison.generatedAt,
                modifier = Modifier.padding(16.dp)
            )

            Spacer(Modifier.height(16.dp))
        }
    }
}

/**
 * Card displaying player information in comparison view
 */
@Composable
fun PlayerComparisonCard(player: PlayerDTO) {
    Card(
        modifier = Modifier.width(140.dp),
        colors = CardDefaults.cardColors(
            containerColor = MaterialTheme.colorScheme.surfaceVariant
        )
    ) {
        Column(
            modifier = Modifier
                .fillMaxWidth()
                .padding(16.dp),
            horizontalAlignment = Alignment.CenterHorizontally,
            verticalArrangement = Arrangement.spacedBy(8.dp)
        ) {
            // Player photo or placeholder
            AsyncImage(
                model = player.photoURL,
                contentDescription = player.name,
                placeholder = painterResource(R.drawable.ic_helmet_placeholder),
                error = painterResource(R.drawable.ic_helmet_placeholder),
                modifier = Modifier
                    .size(80.dp)
                    .clip(CircleShape),
                contentScale = ContentScale.Crop
            )

            Text(
                player.name,
                style = MaterialTheme.typography.titleSmall,
                fontWeight = FontWeight.Bold,
                textAlign = TextAlign.Center,
                maxLines = 2
            )

            Text(
                player.position,
                style = MaterialTheme.typography.labelMedium,
                color = MaterialTheme.colorScheme.onSurfaceVariant
            )

            player.jerseyNumber?.let { jerseyNum ->
                Surface(
                    shape = RoundedCornerShape(8.dp),
                    color = MaterialTheme.colorScheme.primary.copy(alpha = 0.2f)
                ) {
                    Text(
                        "#$jerseyNum",
                        style = MaterialTheme.typography.labelSmall,
                        color = MaterialTheme.colorScheme.primary,
                        modifier = Modifier.padding(horizontal = 8.dp, vertical = 4.dp)
                    )
                }
            }
        }
    }
}

/**
 * Category selector for filtering stats
 */
@Composable
fun CategorySelector(
    selectedCategory: StatCategory,
    onCategorySelected: (StatCategory) -> Unit,
    modifier: Modifier = Modifier
) {
    Row(
        modifier = modifier.horizontalScroll(rememberScrollState()),
        horizontalArrangement = Arrangement.spacedBy(8.dp)
    ) {
        StatCategory.values().forEach { category ->
            FilterChip(
                selected = selectedCategory == category,
                onClick = { onCategorySelected(category) },
                label = {
                    Text(
                        category.value.replaceFirstChar { it.uppercase() },
                        style = MaterialTheme.typography.labelMedium
                    )
                }
            )
        }
    }
}

/**
 * Card showing comparison for a specific statistic
 */
@Composable
fun StatComparisonCard(comparison: StatComparison) {
    Card(
        colors = CardDefaults.cardColors(
            containerColor = MaterialTheme.colorScheme.surfaceVariant
        )
    ) {
        Column(
            modifier = Modifier
                .fillMaxWidth()
                .padding(16.dp),
            verticalArrangement = Arrangement.spacedBy(12.dp)
        ) {
            Text(
                comparison.statName,
                style = MaterialTheme.typography.titleSmall,
                fontWeight = FontWeight.Bold
            )

            comparison.values.forEachIndexed { index, value ->
                Row(
                    modifier = Modifier.fillMaxWidth(),
                    horizontalArrangement = Arrangement.SpaceBetween,
                    verticalAlignment = Alignment.CenterVertically
                ) {
                    Text(
                        value.playerName,
                        style = MaterialTheme.typography.bodyMedium,
                        modifier = Modifier.weight(1f)
                    )

                    Text(
                        value.formattedValue,
                        style = MaterialTheme.typography.bodyMedium,
                        fontWeight = if (value.playerId == comparison.leaderPlayerId) {
                            FontWeight.Bold
                        } else {
                            FontWeight.Normal
                        },
                        color = if (value.playerId == comparison.leaderPlayerId) {
                            MaterialTheme.colorScheme.tertiary
                        } else {
                            MaterialTheme.colorScheme.onSurface
                        }
                    )

                    if (value.playerId == comparison.leaderPlayerId) {
                        Icon(
                            painter = painterResource(R.drawable.ic_helmet_placeholder),
                            contentDescription = "Leader",
                            tint = MaterialTheme.colorScheme.tertiary,
                            modifier = Modifier.size(16.dp).padding(start = 4.dp)
                        )
                    }
                }

                value.percentileRank?.let { percentile ->
                    LinearProgressIndicator(
                        progress = { (percentile / 100).toFloat() },
                        modifier = Modifier
                            .fillMaxWidth()
                            .height(4.dp)
                            .clip(RoundedCornerShape(2.dp)),
                        color = getPercentileColor(percentile),
                        trackColor = MaterialTheme.colorScheme.surfaceVariant
                    )
                }

                if (index < comparison.values.size - 1) {
                    HorizontalDivider()
                }
            }
        }
    }
}

/**
 * Season information display
 */
@Composable
fun SeasonInfo(season: Int, generatedAt: String, modifier: Modifier = Modifier) {
    Column(
        modifier = modifier.fillMaxWidth(),
        horizontalAlignment = Alignment.CenterHorizontally,
        verticalArrangement = Arrangement.spacedBy(4.dp)
    ) {
        Text(
            "Season: $season",
            style = MaterialTheme.typography.labelSmall,
            color = MaterialTheme.colorScheme.onSurfaceVariant
        )

        Text(
            "Generated: ${formatDate(generatedAt)}",
            style = MaterialTheme.typography.labelSmall,
            color = MaterialTheme.colorScheme.onSurfaceVariant
        )
    }
}

/**
 * Get color based on percentile rank
 */
fun getPercentileColor(percentile: Double): androidx.compose.ui.graphics.Color {
    return when {
        percentile >= 80 -> androidx.compose.ui.graphics.Color(0xFF4CAF50) // Green
        percentile >= 50 -> androidx.compose.ui.graphics.Color(0xFF2196F3) // Blue
        percentile >= 25 -> androidx.compose.ui.graphics.Color(0xFFFF9800) // Orange
        else -> androidx.compose.ui.graphics.Color(0xFFF44336) // Red
    }
}

/**
 * Format date string for display
 */
fun formatDate(dateString: String): String {
    return try {
        val parser = SimpleDateFormat("yyyy-MM-dd'T'HH:mm:ss", Locale.getDefault())
        val formatter = SimpleDateFormat("MMM dd, yyyy h:mm a", Locale.getDefault())
        val date = parser.parse(dateString)
        date?.let { formatter.format(it) } ?: dateString
    } catch (e: Exception) {
        dateString
    }
}
