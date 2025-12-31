package com.statshark.nfl.ui.screens.game

import androidx.compose.foundation.background
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.ArrowBack
import androidx.compose.material.icons.filled.TrendingUp
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Brush
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.res.painterResource
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.dp
import androidx.hilt.navigation.compose.hiltViewModel
import androidx.lifecycle.compose.collectAsStateWithLifecycle
import androidx.navigation.NavController
import com.statshark.nfl.data.model.GameDTO
import com.statshark.nfl.data.model.PredictionDTO
import com.statshark.nfl.data.model.TeamDTO
import com.statshark.nfl.ui.theme.TeamColors
import com.statshark.nfl.ui.components.FeedbackButton

/**
 * Game Detail Screen
 * Shows game information and AI prediction for upcoming games
 */
@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun GameDetailScreen(
    game: GameDTO,
    navController: NavController,
    viewModel: GameDetailViewModel = hiltViewModel()
) {
    val uiState by viewModel.uiState.collectAsStateWithLifecycle()

    LaunchedEffect(game) {
        viewModel.setGame(game)
    }

    Scaffold(
        topBar = {
            TopAppBar(
                title = { Text("Game Details") },
                navigationIcon = {
                    IconButton(onClick = { navController.navigateUp() }) {
                        Icon(Icons.Filled.ArrowBack, contentDescription = "Back")
                    }
                },
                actions = {
                    FeedbackButton(pageName = "Game Detail")
                },
                colors = TopAppBarDefaults.topAppBarColors(
                    containerColor = MaterialTheme.colorScheme.primaryContainer,
                    titleContentColor = MaterialTheme.colorScheme.onPrimaryContainer
                )
            )
        }
    ) { paddingValues ->
        LazyColumn(
            modifier = Modifier
                .fillMaxSize()
                .padding(paddingValues),
            contentPadding = PaddingValues(16.dp),
            verticalArrangement = Arrangement.spacedBy(16.dp)
        ) {
            item {
                GameHeaderCard(game)
            }

            item {
                TeamMatchupCard(game)
            }

            // Show prediction for future games
            if (game.homeScore == null && game.awayScore == null) {
                item {
                    PredictionCard(
                        prediction = uiState.prediction,
                        isLoading = uiState.isLoadingPrediction,
                        error = uiState.predictionError,
                        onRetry = { viewModel.retryPrediction() }
                    )
                }
            }
        }
    }
}

/**
 * Game Header Card
 */
@Composable
fun GameHeaderCard(game: GameDTO) {
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
            // Week and Season
            Text(
                text = "Week ${game.week} • ${game.season} Season",
                style = MaterialTheme.typography.labelLarge,
                color = MaterialTheme.colorScheme.onSurfaceVariant
            )

            Spacer(modifier = Modifier.height(8.dp))

            // Game Date
            Text(
                text = game.scheduledDate.take(10),
                style = MaterialTheme.typography.headlineSmall,
                fontWeight = FontWeight.Bold
            )

            Spacer(modifier = Modifier.height(8.dp))

            // Game Status
            val isCompleted = game.homeScore != null && game.awayScore != null
            val isInProgress = !isCompleted && game.status?.lowercase() == "in progress"

            Surface(
                shape = RoundedCornerShape(12.dp),
                color = when {
                    isCompleted -> MaterialTheme.colorScheme.primaryContainer
                    isInProgress -> Color(0xFFFF5722).copy(alpha = 0.2f)
                    else -> MaterialTheme.colorScheme.tertiaryContainer
                }
            ) {
                Row(
                    verticalAlignment = Alignment.CenterVertically,
                    horizontalArrangement = Arrangement.Center,
                    modifier = Modifier.padding(horizontal = 12.dp, vertical = 4.dp)
                ) {
                    if (isInProgress) {
                        Icon(
                            painter = painterResource(android.R.drawable.presence_video_online),
                            contentDescription = "Live",
                            tint = Color(0xFFFF5722),
                            modifier = Modifier.size(12.dp)
                        )
                        Spacer(modifier = Modifier.width(4.dp))
                    }
                    Text(
                        text = when {
                            isCompleted -> "Final"
                            isInProgress -> "LIVE"
                            else -> "Upcoming"
                        },
                        style = MaterialTheme.typography.labelMedium,
                        fontWeight = FontWeight.SemiBold,
                        color = when {
                            isCompleted -> MaterialTheme.colorScheme.onPrimaryContainer
                            isInProgress -> Color(0xFFFF5722)
                            else -> MaterialTheme.colorScheme.onTertiaryContainer
                        }
                    )
                }
            }
        }
    }
}

/**
 * Team Matchup Card
 */
@Composable
fun TeamMatchupCard(game: GameDTO) {
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
            horizontalAlignment = Alignment.CenterHorizontally,
            verticalArrangement = Arrangement.spacedBy(16.dp)
        ) {
            // Away Team
            TeamRow(
                team = game.awayTeam,
                score = game.awayScore,
                isWinner = game.awayScore != null && game.homeScore != null && game.awayScore > game.homeScore!!
            )

            // VS Divider
            Text(
                text = "@",
                style = MaterialTheme.typography.titleMedium,
                fontWeight = FontWeight.Bold,
                color = MaterialTheme.colorScheme.onSurfaceVariant
            )

            // Home Team
            TeamRow(
                team = game.homeTeam,
                score = game.homeScore,
                isWinner = game.homeScore != null && game.awayScore != null && game.homeScore > game.awayScore!!
            )

            // Venue
            game.venue?.let { venue ->
                Row(
                    horizontalArrangement = Arrangement.Center,
                    verticalAlignment = Alignment.CenterVertically
                ) {
                    Icon(
                        painter = painterResource(android.R.drawable.ic_dialog_map),
                        contentDescription = null,
                        tint = MaterialTheme.colorScheme.onSurfaceVariant,
                        modifier = Modifier.size(16.dp)
                    )
                    Spacer(modifier = Modifier.width(4.dp))
                    Text(
                        text = venue,
                        style = MaterialTheme.typography.bodyMedium,
                        color = MaterialTheme.colorScheme.onSurfaceVariant
                    )
                }
            }
        }
    }
}

/**
 * Team Row Component
 */
@Composable
fun TeamRow(team: TeamDTO, score: Int?, isWinner: Boolean) {
    Row(
        modifier = Modifier.fillMaxWidth(),
        horizontalArrangement = Arrangement.SpaceBetween,
        verticalAlignment = Alignment.CenterVertically
    ) {
        Row(
            horizontalArrangement = Arrangement.Start,
            verticalAlignment = Alignment.CenterVertically
        ) {
            // Team helmet icon (if available)
            val helmetResourceId = getTeamHelmetResource(team.abbreviation)
            if (helmetResourceId != null) {
                androidx.compose.foundation.Image(
                    painter = painterResource(id = helmetResourceId),
                    contentDescription = "${team.name} helmet",
                    modifier = Modifier.size(48.dp)
                )
                Spacer(modifier = Modifier.width(12.dp))
            }

            Column {
                Text(
                    text = team.name,
                    style = MaterialTheme.typography.titleMedium,
                    fontWeight = if (isWinner) FontWeight.Bold else FontWeight.Normal
                )
                Text(
                    text = "${team.conference} ${team.division}",
                    style = MaterialTheme.typography.bodySmall,
                    color = MaterialTheme.colorScheme.onSurfaceVariant
                )
            }
        }

        if (score != null) {
            Text(
                text = score.toString(),
                style = MaterialTheme.typography.displayMedium,
                fontWeight = if (isWinner) FontWeight.Bold else FontWeight.Normal,
                color = if (isWinner) MaterialTheme.colorScheme.primary else MaterialTheme.colorScheme.onSurface
            )
        } else {
            Text(
                text = "—",
                style = MaterialTheme.typography.displayMedium,
                color = MaterialTheme.colorScheme.onSurfaceVariant
            )
        }
    }
}

/**
 * Prediction Card
 */
@Composable
fun PredictionCard(
    prediction: PredictionDTO?,
    isLoading: Boolean,
    error: String?,
    onRetry: () -> Unit
) {
    Card(
        modifier = Modifier.fillMaxWidth(),
        colors = CardDefaults.cardColors(
            containerColor = MaterialTheme.colorScheme.surfaceVariant
        )
    ) {
        Column(
            modifier = Modifier
                .fillMaxWidth()
                .padding(16.dp)
        ) {
            Row(
                verticalAlignment = Alignment.CenterVertically
            ) {
                Icon(
                    imageVector = Icons.Filled.TrendingUp,
                    contentDescription = null,
                    tint = MaterialTheme.colorScheme.primary
                )
                Spacer(modifier = Modifier.width(8.dp))
                Text(
                    text = "AI Prediction",
                    style = MaterialTheme.typography.titleLarge,
                    fontWeight = FontWeight.Bold
                )
            }

            Spacer(modifier = Modifier.height(16.dp))

            when {
                isLoading -> {
                    Box(
                        modifier = Modifier.fillMaxWidth(),
                        contentAlignment = Alignment.Center
                    ) {
                        CircularProgressIndicator()
                    }
                }
                error != null -> {
                    Column(
                        modifier = Modifier.fillMaxWidth(),
                        horizontalAlignment = Alignment.CenterHorizontally
                    ) {
                        Text(
                            text = error,
                            style = MaterialTheme.typography.bodyMedium,
                            color = MaterialTheme.colorScheme.error,
                            textAlign = TextAlign.Center
                        )
                        Spacer(modifier = Modifier.height(8.dp))
                        Button(onClick = onRetry) {
                            Text("Retry")
                        }
                    }
                }
                prediction != null -> {
                    PredictionContent(prediction)
                }
                else -> {
                    Text(
                        text = "Prediction unavailable",
                        style = MaterialTheme.typography.bodyMedium,
                        color = MaterialTheme.colorScheme.onSurfaceVariant,
                        textAlign = TextAlign.Center,
                        modifier = Modifier.fillMaxWidth()
                    )
                }
            }
        }
    }
}

/**
 * Prediction Content
 */
@Composable
fun PredictionContent(prediction: PredictionDTO) {
    // Calculate predicted winner from probabilities
    val predictedWinner = if (prediction.homeWinProbability > prediction.awayWinProbability) {
        prediction.homeTeam.abbreviation
    } else {
        prediction.awayTeam.abbreviation
    }

    Column(
        modifier = Modifier.fillMaxWidth(),
        verticalArrangement = Arrangement.spacedBy(16.dp)
    ) {
        // Winner Display
        Surface(
            modifier = Modifier.fillMaxWidth(),
            shape = RoundedCornerShape(12.dp),
            color = MaterialTheme.colorScheme.primaryContainer
        ) {
            Column(
                modifier = Modifier
                    .fillMaxWidth()
                    .padding(16.dp),
                horizontalAlignment = Alignment.CenterHorizontally
            ) {
                // Team helmet icon
                val helmetResourceId = getTeamHelmetResource(predictedWinner)
                if (helmetResourceId != null) {
                    androidx.compose.foundation.Image(
                        painter = painterResource(id = helmetResourceId),
                        contentDescription = "$predictedWinner helmet",
                        modifier = Modifier.size(60.dp)
                    )
                    Spacer(modifier = Modifier.height(8.dp))
                }

                Text(
                    text = "${(prediction.confidence * 100).toInt()}% Win Probability",
                    style = MaterialTheme.typography.titleMedium,
                    fontWeight = FontWeight.Bold,
                    color = MaterialTheme.colorScheme.primary
                )

                Text(
                    text = "Predicted Winner: $predictedWinner",
                    style = MaterialTheme.typography.bodyMedium,
                    color = MaterialTheme.colorScheme.onPrimaryContainer
                )
            }
        }

        // AI Analysis
        Surface(
            modifier = Modifier.fillMaxWidth(),
            shape = RoundedCornerShape(8.dp),
            color = MaterialTheme.colorScheme.surface
        ) {
            Column(
                modifier = Modifier.padding(12.dp)
            ) {
                Text(
                    text = "Analysis",
                    style = MaterialTheme.typography.labelLarge,
                    fontWeight = FontWeight.SemiBold
                )
                Spacer(modifier = Modifier.height(4.dp))
                Text(
                    text = prediction.reasoning,
                    style = MaterialTheme.typography.bodySmall,
                    color = MaterialTheme.colorScheme.onSurfaceVariant
                )
            }
        }

        // Confidence Bar
        Column {
            Row(
                modifier = Modifier.fillMaxWidth(),
                horizontalArrangement = Arrangement.SpaceBetween
            ) {
                Text(
                    text = "Confidence",
                    style = MaterialTheme.typography.bodySmall
                )
                Text(
                    text = "${(prediction.confidence * 100).toInt()}%",
                    style = MaterialTheme.typography.bodySmall,
                    fontWeight = FontWeight.SemiBold
                )
            }
            Spacer(modifier = Modifier.height(4.dp))
            Box(
                modifier = Modifier
                    .fillMaxWidth()
                    .height(8.dp)
                    .background(
                        color = MaterialTheme.colorScheme.surfaceVariant,
                        shape = RoundedCornerShape(4.dp)
                    )
            ) {
                Box(
                    modifier = Modifier
                        .fillMaxWidth(prediction.confidence.toFloat())
                        .height(8.dp)
                        .background(
                            brush = Brush.horizontalGradient(
                                colors = listOf(
                                    MaterialTheme.colorScheme.primary,
                                    MaterialTheme.colorScheme.tertiary
                                )
                            ),
                            shape = RoundedCornerShape(4.dp)
                        )
                )
            }
        }

        // Vegas Odds (if available)
        prediction.vegasOdds?.let { odds ->
            Divider()
            Column {
                Text(
                    text = "Vegas Odds",
                    style = MaterialTheme.typography.labelLarge,
                    fontWeight = FontWeight.SemiBold
                )
                Spacer(modifier = Modifier.height(8.dp))
                odds.spread?.let { spread ->
                    Text(
                        text = "Spread: ${if (spread > 0) "+" else ""}$spread",
                        style = MaterialTheme.typography.bodyMedium
                    )
                }
                odds.total?.let { total ->
                    Text(
                        text = "Over/Under: $total",
                        style = MaterialTheme.typography.bodyMedium
                    )
                }
            }
        }
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
