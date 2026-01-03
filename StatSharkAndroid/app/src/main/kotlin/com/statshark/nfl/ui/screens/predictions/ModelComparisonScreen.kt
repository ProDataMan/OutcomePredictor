package com.statshark.nfl.ui.screens.predictions

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
import androidx.compose.ui.res.painterResource
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.dp
import androidx.navigation.NavController
import coil.compose.AsyncImage
import com.statshark.nfl.R
import com.statshark.nfl.data.model.*
import com.statshark.nfl.ui.components.FeedbackButton
import com.statshark.nfl.ui.screens.teams.getTeamHelmetResource
import java.text.SimpleDateFormat
import java.util.*

/**
 * Model Comparison Screen
 * Shows predictions from multiple models side-by-side
 */
@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun ModelComparisonScreen(
    comparison: ModelComparisonDTO,
    navController: NavController
) {
    Scaffold(
        topBar = {
            TopAppBar(
                title = { Text("Model Comparison") },
                navigationIcon = {
                    IconButton(onClick = { navController.navigateUp() }) {
                        Icon(Icons.Filled.ArrowBack, "Back")
                    }
                },
                actions = {
                    FeedbackButton(pageName = "Model Comparison")
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
            // Game Header
            GameMatchupHeader(comparison.game)

            Spacer(Modifier.height(16.dp))

            // Consensus Section
            comparison.consensus?.let { consensus ->
                ConsensusSection(consensus)
                Spacer(Modifier.height(24.dp))
            }

            // Individual Models
            IndividualModelsSection(comparison.models, comparison.game)

            Spacer(Modifier.height(16.dp))
        }
    }
}

@Composable
fun GameMatchupHeader(game: GameDTO) {
    Column(
        modifier = Modifier
            .fillMaxWidth()
            .padding(16.dp),
        horizontalAlignment = Alignment.CenterHorizontally
    ) {
        Text(
            "Game Matchup",
            style = MaterialTheme.typography.titleMedium,
            fontWeight = FontWeight.Bold
        )

        Spacer(Modifier.height(16.dp))

        Row(
            modifier = Modifier.fillMaxWidth(),
            horizontalArrangement = Arrangement.SpaceEvenly,
            verticalAlignment = Alignment.CenterVertically
        ) {
            Column(horizontalAlignment = Alignment.CenterHorizontally) {
                val homeHelmet = getTeamHelmetResource(game.homeTeam.abbreviation)
                if (homeHelmet != null) {
                    AsyncImage(
                        model = homeHelmet,
                        contentDescription = game.homeTeam.name,
                        modifier = Modifier.size(60.dp),
                        placeholder = painterResource(R.drawable.ic_helmet_placeholder)
                    )
                }
                Text(
                    game.homeTeam.abbreviation,
                    style = MaterialTheme.typography.titleMedium,
                    fontWeight = FontWeight.Bold
                )
            }

            Text(
                "vs",
                style = MaterialTheme.typography.titleMedium,
                color = MaterialTheme.colorScheme.onSurfaceVariant
            )

            Column(horizontalAlignment = Alignment.CenterHorizontally) {
                val awayHelmet = getTeamHelmetResource(game.awayTeam.abbreviation)
                if (awayHelmet != null) {
                    AsyncImage(
                        model = awayHelmet,
                        contentDescription = game.awayTeam.name,
                        modifier = Modifier.size(60.dp),
                        placeholder = painterResource(R.drawable.ic_helmet_placeholder)
                    )
                }
                Text(
                    game.awayTeam.abbreviation,
                    style = MaterialTheme.typography.titleMedium,
                    fontWeight = FontWeight.Bold
                )
            }
        }

        Text(
            formatDate(game.scheduledDate),
            style = MaterialTheme.typography.labelMedium,
            color = MaterialTheme.colorScheme.onSurfaceVariant
        )
    }
}

@Composable
fun ConsensusSection(consensus: ConsensusDTO) {
    Column(
        modifier = Modifier
            .fillMaxWidth()
            .padding(horizontal = 16.dp)
    ) {
        Text(
            "Consensus Prediction",
            style = MaterialTheme.typography.titleMedium,
            fontWeight = FontWeight.Bold
        )

        Spacer(Modifier.height(12.dp))

        Card(
            colors = CardDefaults.cardColors(
                containerColor = MaterialTheme.colorScheme.primaryContainer
            )
        ) {
            Column(
                modifier = Modifier
                    .fillMaxWidth()
                    .padding(16.dp),
                verticalArrangement = Arrangement.spacedBy(8.dp)
            ) {
                ConsensusRow("Predicted Winner", consensus.predictedWinner, true)
                ConsensusRow("Model Agreement", "${consensus.agreementPercentage.toInt()}%", false)
                ConsensusRow("Avg Confidence", "${consensus.averageConfidence.toInt()}%", false)
                ConsensusRow("Models Analyzed", "${consensus.modelCount}", false)
            }
        }
    }
}

@Composable
fun ConsensusRow(label: String, value: String, isHighlighted: Boolean) {
    Row(
        modifier = Modifier.fillMaxWidth(),
        horizontalArrangement = Arrangement.SpaceBetween
    ) {
        Text(
            label,
            style = MaterialTheme.typography.bodyMedium,
            color = MaterialTheme.colorScheme.onPrimaryContainer
        )

        Text(
            value,
            style = MaterialTheme.typography.bodyMedium,
            fontWeight = if (isHighlighted) FontWeight.Bold else FontWeight.SemiBold,
            color = if (isHighlighted) {
                MaterialTheme.colorScheme.primary
            } else {
                MaterialTheme.colorScheme.onPrimaryContainer
            }
        )
    }
}

@Composable
fun IndividualModelsSection(models: List<PredictionModelDTO>, game: GameDTO) {
    Column(
        modifier = Modifier
            .fillMaxWidth()
            .padding(horizontal = 16.dp),
        verticalArrangement = Arrangement.spacedBy(16.dp)
    ) {
        Text(
            "Individual Models",
            style = MaterialTheme.typography.titleMedium,
            fontWeight = FontWeight.Bold
        )

        models.forEach { model ->
            ModelPredictionCard(model, game)
        }
    }
}

@Composable
fun ModelPredictionCard(model: PredictionModelDTO, game: GameDTO) {
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
            // Model Header
            Row(
                modifier = Modifier.fillMaxWidth(),
                horizontalArrangement = Arrangement.SpaceBetween,
                verticalAlignment = Alignment.CenterVertically
            ) {
                Column {
                    Text(
                        model.modelName,
                        style = MaterialTheme.typography.titleSmall,
                        fontWeight = FontWeight.Bold
                    )
                    Text(
                        "v${model.modelVersion}",
                        style = MaterialTheme.typography.labelSmall,
                        color = MaterialTheme.colorScheme.onSurfaceVariant
                    )
                }

                model.accuracy?.let { accuracy ->
                    Column(horizontalAlignment = Alignment.End) {
                        Text(
                            "${if (accuracy.overallAccuracy.isNaN() || accuracy.overallAccuracy.isInfinite()) 0 else accuracy.overallAccuracy.toInt()}%",
                            style = MaterialTheme.typography.titleSmall,
                            fontWeight = FontWeight.Bold,
                            color = getModelAccuracyColor(accuracy.overallAccuracy)
                        )
                        Text(
                            "Accuracy",
                            style = MaterialTheme.typography.labelSmall,
                            color = MaterialTheme.colorScheme.onSurfaceVariant
                        )
                    }
                }
            }

            HorizontalDivider()

            // Prediction
            ModelStatRow("Predicted Winner", model.predictedWinner, true)
            ModelStatRow("Confidence", "${model.confidence.toInt()}%", false)

            // Probabilities
            Row(
                modifier = Modifier.fillMaxWidth(),
                horizontalArrangement = Arrangement.spacedBy(16.dp)
            ) {
                Card(
                    modifier = Modifier.weight(1f),
                    colors = CardDefaults.cardColors(
                        containerColor = MaterialTheme.colorScheme.surface
                    )
                ) {
                    Column(
                        modifier = Modifier
                            .fillMaxWidth()
                            .padding(12.dp),
                        horizontalAlignment = Alignment.CenterHorizontally
                    ) {
                        Text(
                            game.homeTeam.abbreviation,
                            style = MaterialTheme.typography.labelSmall,
                            color = MaterialTheme.colorScheme.onSurfaceVariant
                        )
                        Text(
                            "${model.homeWinProbability.toInt()}%",
                            style = MaterialTheme.typography.bodyMedium,
                            fontWeight = FontWeight.SemiBold
                        )
                    }
                }

                Card(
                    modifier = Modifier.weight(1f),
                    colors = CardDefaults.cardColors(
                        containerColor = MaterialTheme.colorScheme.surface
                    )
                ) {
                    Column(
                        modifier = Modifier
                            .fillMaxWidth()
                            .padding(12.dp),
                        horizontalAlignment = Alignment.CenterHorizontally
                    ) {
                        Text(
                            game.awayTeam.abbreviation,
                            style = MaterialTheme.typography.labelSmall,
                            color = MaterialTheme.colorScheme.onSurfaceVariant
                        )
                        Text(
                            "${model.awayWinProbability.toInt()}%",
                            style = MaterialTheme.typography.bodyMedium,
                            fontWeight = FontWeight.SemiBold
                        )
                    }
                }
            }

            // Predicted Score
            if (model.predictedHomeScore != null && model.predictedAwayScore != null) {
                ModelStatRow(
                    "Predicted Score",
                    "${model.predictedHomeScore} - ${model.predictedAwayScore}",
                    false
                )
            }

            // Reasoning
            model.reasoning?.let { reasoning ->
                Card(
                    colors = CardDefaults.cardColors(
                        containerColor = MaterialTheme.colorScheme.surface
                    )
                ) {
                    Column(
                        modifier = Modifier
                            .fillMaxWidth()
                            .padding(12.dp)
                    ) {
                        Text(
                            "Analysis:",
                            style = MaterialTheme.typography.labelSmall,
                            fontWeight = FontWeight.SemiBold,
                            color = MaterialTheme.colorScheme.onSurfaceVariant
                        )
                        Spacer(Modifier.height(4.dp))
                        Text(
                            reasoning,
                            style = MaterialTheme.typography.bodySmall,
                            color = MaterialTheme.colorScheme.onSurfaceVariant
                        )
                    }
                }
            }
        }
    }
}

@Composable
fun ModelStatRow(label: String, value: String, isHighlighted: Boolean) {
    Row(
        modifier = Modifier.fillMaxWidth(),
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
            fontWeight = if (isHighlighted) FontWeight.Bold else FontWeight.SemiBold,
            color = if (isHighlighted) {
                MaterialTheme.colorScheme.primary
            } else {
                MaterialTheme.colorScheme.onSurface
            }
        )
    }
}

fun getModelAccuracyColor(accuracy: Double): Color {
    return when {
        accuracy >= 70 -> Color(0xFF4CAF50)
        accuracy >= 50 -> Color(0xFF2196F3)
        accuracy >= 30 -> Color(0xFFFF9800)
        else -> Color(0xFFF44336)
    }
}

fun formatDate(dateString: String): String {
    return try {
        val parser = SimpleDateFormat("yyyy-MM-dd", Locale.getDefault())
        val formatter = SimpleDateFormat("MMM dd, yyyy", Locale.getDefault())
        val date = parser.parse(dateString)
        date?.let { formatter.format(it) } ?: dateString
    } catch (e: Exception) {
        dateString
    }
}
