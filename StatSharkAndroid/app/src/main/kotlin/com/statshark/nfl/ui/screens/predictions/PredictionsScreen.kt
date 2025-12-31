package com.statshark.nfl.ui.screens.predictions

import androidx.compose.animation.*
import androidx.compose.foundation.background
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.items
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.Check
import androidx.compose.material.icons.filled.TrendingUp
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
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
import com.statshark.nfl.ui.navigation.Screen
import com.statshark.nfl.ui.theme.TeamColors
import com.statshark.nfl.ui.components.SkeletonGameCard
import com.statshark.nfl.ui.components.SkeletonList
import com.statshark.nfl.ui.components.FeedbackButton

/**
 * Predictions Screen
 * AI-powered game predictions
 */
@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun PredictionsScreen(
    navController: NavController,
    viewModel: PredictionsViewModel = hiltViewModel(),
    preSelectedHomeTeam: String? = null,
    preSelectedAwayTeam: String? = null
) {
    val uiState by viewModel.uiState.collectAsStateWithLifecycle()

    // Pre-select teams if provided
    LaunchedEffect(preSelectedHomeTeam, preSelectedAwayTeam) {
        if (preSelectedHomeTeam != null && preSelectedAwayTeam != null) {
            viewModel.preSelectTeams(preSelectedHomeTeam, preSelectedAwayTeam)
        }
    }

    Scaffold(
        topBar = {
            TopAppBar(
                title = {
                    Row(
                        verticalAlignment = Alignment.CenterVertically,
                        horizontalArrangement = Arrangement.spacedBy(8.dp)
                    ) {
                        Icon(
                            imageVector = Icons.Filled.TrendingUp,
                            contentDescription = null
                        )
                        Text("AI Predictions")
                    }
                },
                actions = {
                    FeedbackButton(pageName = "AI Predictions")
                },
                colors = TopAppBarDefaults.topAppBarColors(
                    containerColor = MaterialTheme.colorScheme.primaryContainer,
                    titleContentColor = MaterialTheme.colorScheme.onPrimaryContainer
                )
            )
        }
    ) { paddingValues ->
        when {
            uiState.isLoadingGames -> {
                LoadingScreen()
            }
            uiState.gamesError != null -> {
                ErrorScreen(
                    error = uiState.gamesError!!,
                    onRetry = { viewModel.retry() }
                )
            }
            uiState.upcomingGames.isEmpty() -> {
                EmptyScreen("No upcoming games found")
            }
            else -> {
                LazyColumn(
                    modifier = Modifier
                        .fillMaxSize()
                        .padding(paddingValues),
                    contentPadding = PaddingValues(16.dp),
                    verticalArrangement = Arrangement.spacedBy(16.dp)
                ) {
                    item {
                        InfoCard()
                    }

                    // Week and Confidence Filters
                    item {
                        FiltersCard(
                            availableWeeks = uiState.availableWeeks,
                            selectedWeek = uiState.selectedWeek,
                            currentWeek = uiState.currentWeek,
                            minConfidence = uiState.minConfidence,
                            onWeekSelected = { viewModel.setSelectedWeek(it) },
                            onConfidenceSelected = { viewModel.setMinConfidence(it) }
                        )
                    }

                    // Batch Predict Button
                    item {
                        BatchPredictButton(
                            isLoading = uiState.isLoadingBatch,
                            progress = uiState.batchProgress,
                            gamesCount = if (uiState.selectedWeek == null) {
                                uiState.upcomingGames.size
                            } else {
                                uiState.upcomingGames.count { it.week == uiState.selectedWeek }
                            },
                            onClick = { viewModel.predictAllGames() }
                        )
                    }

                    items(uiState.filteredGames) { game ->
                        GamePredictionCard(
                            game = game,
                            prediction = uiState.predictions[game.id],
                            isLoading = game.id in uiState.loadingPredictions,
                            error = uiState.predictionErrors[game.id],
                            onPredictClick = { viewModel.makePrediction(game) },
                            navController = navController
                        )
                    }
                }
            }
        }
    }
}

/**
 * Info Card explaining predictions
 */
@Composable
fun InfoCard() {
    Card(
        modifier = Modifier.fillMaxWidth(),
        colors = CardDefaults.cardColors(
            containerColor = MaterialTheme.colorScheme.primaryContainer
        )
    ) {
        Row(
            modifier = Modifier
                .fillMaxWidth()
                .padding(16.dp),
            horizontalArrangement = Arrangement.spacedBy(12.dp),
            verticalAlignment = Alignment.CenterVertically
        ) {
            Icon(
                imageVector = Icons.Filled.TrendingUp,
                contentDescription = null,
                tint = MaterialTheme.colorScheme.onPrimaryContainer,
                modifier = Modifier.size(40.dp)
            )
            Column {
                Text(
                    text = "AI-Powered Predictions",
                    style = MaterialTheme.typography.titleMedium,
                    fontWeight = FontWeight.Bold,
                    color = MaterialTheme.colorScheme.onPrimaryContainer
                )
                Text(
                    text = "Get intelligent game predictions based on team performance, player stats, and historical data",
                    style = MaterialTheme.typography.bodyMedium,
                    color = MaterialTheme.colorScheme.onPrimaryContainer.copy(alpha = 0.8f)
                )
            }
        }
    }
}

/**
 * Game Prediction Card
 */
@Composable
fun GamePredictionCard(
    game: GameDTO,
    prediction: PredictionDTO?,
    isLoading: Boolean,
    error: String?,
    onPredictClick: () -> Unit,
    navController: NavController
) {
    Card(
        modifier = Modifier.fillMaxWidth(),
        elevation = CardDefaults.cardElevation(defaultElevation = 4.dp)
    ) {
        Column(
            modifier = Modifier
                .fillMaxWidth()
                .padding(16.dp)
        ) {
            // Game Header
            GameHeader(game)

            Spacer(modifier = Modifier.height(12.dp))

            // Matchup
            GameMatchup(game, navController)

            Spacer(modifier = Modifier.height(16.dp))

            // Prediction Section
            AnimatedVisibility(
                visible = prediction != null,
                enter = expandVertically() + fadeIn(),
                exit = shrinkVertically() + fadeOut()
            ) {
                prediction?.let { pred ->
                    PredictionResult(prediction = pred, game = game)
                }
            }

            // Error Message
            error?.let {
                Text(
                    text = it,
                    style = MaterialTheme.typography.bodyMedium,
                    color = MaterialTheme.colorScheme.error,
                    modifier = Modifier.padding(vertical = 8.dp)
                )
            }

            // Predict Button
            if (prediction == null && !isLoading) {
                Button(
                    onClick = onPredictClick,
                    modifier = Modifier.fillMaxWidth()
                ) {
                    Icon(
                        imageVector = Icons.Filled.TrendingUp,
                        contentDescription = null,
                        modifier = Modifier.size(18.dp)
                    )
                    Spacer(modifier = Modifier.width(8.dp))
                    Text("Get AI Prediction")
                }
            }

            // Loading State
            if (isLoading) {
                Box(
                    modifier = Modifier
                        .fillMaxWidth()
                        .padding(16.dp),
                    contentAlignment = Alignment.Center
                ) {
                    Column(
                        horizontalAlignment = Alignment.CenterHorizontally,
                        verticalArrangement = Arrangement.spacedBy(8.dp)
                    ) {
                        CircularProgressIndicator()
                        Text(
                            text = "Analyzing game data...",
                            style = MaterialTheme.typography.bodyMedium,
                            color = MaterialTheme.colorScheme.onSurfaceVariant
                        )
                    }
                }
            }
        }
    }
}

/**
 * Game Header
 */
@Composable
fun GameHeader(game: GameDTO) {
    val isCompleted = game.homeScore != null && game.awayScore != null
    val isInProgress = !isCompleted && game.status?.lowercase() == "in progress"

    Row(
        modifier = Modifier.fillMaxWidth(),
        horizontalArrangement = Arrangement.SpaceBetween,
        verticalAlignment = Alignment.CenterVertically
    ) {
        Column {
            // Week and LIVE badge
            Row(
                verticalAlignment = Alignment.CenterVertically,
                horizontalArrangement = Arrangement.spacedBy(8.dp)
            ) {
                Text(
                    text = "Week ${game.week}",
                    style = MaterialTheme.typography.labelLarge,
                    color = MaterialTheme.colorScheme.primary,
                    fontWeight = FontWeight.Bold
                )

                if (isInProgress) {
                    Surface(
                        shape = RoundedCornerShape(8.dp),
                        color = Color(0xFFFF5722).copy(alpha = 0.2f)
                    ) {
                        Row(
                            verticalAlignment = Alignment.CenterVertically,
                            horizontalArrangement = Arrangement.spacedBy(4.dp),
                            modifier = Modifier.padding(horizontal = 8.dp, vertical = 2.dp)
                        ) {
                            Box(
                                modifier = Modifier
                                    .size(6.dp)
                                    .clip(CircleShape)
                                    .background(Color(0xFFFF5722))
                            )
                            Text(
                                text = "LIVE",
                                style = MaterialTheme.typography.labelSmall,
                                color = Color(0xFFFF5722),
                                fontWeight = FontWeight.Bold
                            )
                        }
                    }
                }
            }

            Text(
                text = game.scheduledDate.take(10),
                style = MaterialTheme.typography.bodyMedium,
                color = MaterialTheme.colorScheme.onSurfaceVariant
            )
        }
        game.venue?.let { venue ->
            Text(
                text = venue,
                style = MaterialTheme.typography.bodySmall,
                color = MaterialTheme.colorScheme.onSurfaceVariant,
                maxLines = 1
            )
        }
    }
}

/**
 * Game Matchup
 */
@Composable
fun GameMatchup(game: GameDTO, navController: NavController) {
    Row(
        modifier = Modifier.fillMaxWidth(),
        horizontalArrangement = Arrangement.SpaceEvenly,
        verticalAlignment = Alignment.CenterVertically
    ) {
        // Away Team
        TeamDisplay(
            team = game.awayTeam,
            isHome = false,
            modifier = Modifier.weight(1f),
            navController = navController
        )

        // VS Separator
        Box(
            modifier = Modifier
                .size(48.dp)
                .clip(CircleShape)
                .background(MaterialTheme.colorScheme.surfaceVariant),
            contentAlignment = Alignment.Center
        ) {
            Text(
                text = "VS",
                style = MaterialTheme.typography.labelLarge,
                fontWeight = FontWeight.Bold,
                color = MaterialTheme.colorScheme.onSurfaceVariant
            )
        }

        // Home Team
        TeamDisplay(
            team = game.homeTeam,
            isHome = true,
            modifier = Modifier.weight(1f),
            navController = navController
        )
    }
}

/**
 * Team Display
 * Clickable team display that navigates to team detail
 */
@Composable
fun TeamDisplay(
    team: com.statshark.nfl.data.model.TeamDTO,
    isHome: Boolean,
    modifier: Modifier = Modifier,
    navController: NavController
) {
    val colors = TeamColors.getTeamColors(team.abbreviation)

    Column(
        modifier = modifier
            .clickable {
                navController.navigate(Screen.TeamDetail.createRoute(team.abbreviation))
            }
            .padding(8.dp),
        horizontalAlignment = Alignment.CenterHorizontally
    ) {
        Box(
            modifier = Modifier
                .size(80.dp)
                .clip(CircleShape)
                .background(
                    brush = Brush.radialGradient(
                        colors = listOf(colors.primary, colors.primary.copy(alpha = 0.7f))
                    )
                ),
            contentAlignment = Alignment.Center
        ) {
            Text(
                text = team.abbreviation,
                style = MaterialTheme.typography.headlineSmall,
                fontWeight = FontWeight.Bold,
                color = Color.White
            )
        }
        Spacer(modifier = Modifier.height(8.dp))
        Text(
            text = team.name,
            style = MaterialTheme.typography.titleSmall,
            textAlign = TextAlign.Center,
            fontWeight = FontWeight.Bold
        )
        if (isHome) {
            Text(
                text = "(Home)",
                style = MaterialTheme.typography.bodySmall,
                color = MaterialTheme.colorScheme.onSurfaceVariant
            )
        }
    }
}

/**
 * Prediction Result
 */
@Composable
fun PredictionResult(
    prediction: PredictionDTO,
    game: GameDTO
) {
    Column(
        modifier = Modifier
            .fillMaxWidth()
            .clip(RoundedCornerShape(12.dp))
            .background(MaterialTheme.colorScheme.tertiaryContainer)
            .padding(16.dp)
    ) {
        // Winner Badge
        Row(
            verticalAlignment = Alignment.CenterVertically,
            horizontalArrangement = Arrangement.spacedBy(8.dp)
        ) {
            Icon(
                imageVector = Icons.Filled.Check,
                contentDescription = null,
                tint = MaterialTheme.colorScheme.tertiary,
                modifier = Modifier.size(24.dp)
            )
            Text(
                text = "Predicted Winner",
                style = MaterialTheme.typography.labelLarge,
                color = MaterialTheme.colorScheme.onTertiaryContainer
            )
        }

        Spacer(modifier = Modifier.height(8.dp))

        // Winner Name (calculated from probabilities)
        val predictedWinner = if (prediction.homeWinProbability > prediction.awayWinProbability) {
            game.homeTeam.abbreviation
        } else {
            game.awayTeam.abbreviation
        }

        val winnerTeam = if (predictedWinner == game.homeTeam.abbreviation) {
            game.homeTeam
        } else {
            game.awayTeam
        }

        Text(
            text = "${winnerTeam.name} ($predictedWinner)",
            style = MaterialTheme.typography.headlineSmall,
            fontWeight = FontWeight.Bold,
            color = MaterialTheme.colorScheme.onTertiaryContainer
        )

        Spacer(modifier = Modifier.height(12.dp))

        // Win Probability Bar
        Column(modifier = Modifier.fillMaxWidth()) {
            Text(
                text = "Win Probability",
                style = MaterialTheme.typography.labelSmall,
                fontWeight = FontWeight.SemiBold,
                color = MaterialTheme.colorScheme.onTertiaryContainer
            )
            Spacer(modifier = Modifier.height(4.dp))

            Row(
                modifier = Modifier.fillMaxWidth(),
                verticalAlignment = Alignment.CenterVertically
            ) {
                Text(
                    text = "${(prediction.awayWinProbability * 100).toInt()}%",
                    style = MaterialTheme.typography.bodySmall,
                    modifier = Modifier.width(40.dp)
                )

                Row(
                    modifier = Modifier
                        .weight(1f)
                        .height(24.dp)
                        .clip(RoundedCornerShape(4.dp)),
                    horizontalArrangement = Arrangement.Start
                ) {
                    Box(
                        modifier = Modifier
                            .fillMaxHeight()
                            .weight(prediction.awayWinProbability.toFloat())
                            .background(Color(0xFF2196F3)) // Blue for away
                    )
                    Box(
                        modifier = Modifier
                            .fillMaxHeight()
                            .weight(prediction.homeWinProbability.toFloat())
                            .background(Color(0xFFF44336)) // Red for home
                    )
                }

                Text(
                    text = "${(prediction.homeWinProbability * 100).toInt()}%",
                    style = MaterialTheme.typography.bodySmall,
                    modifier = Modifier.width(40.dp),
                    textAlign = TextAlign.End
                )
            }

            Row(
                modifier = Modifier.fillMaxWidth().padding(horizontal = 40.dp),
                horizontalArrangement = Arrangement.SpaceBetween
            ) {
                Text(
                    text = game.awayTeam.abbreviation,
                    style = MaterialTheme.typography.labelSmall,
                    color = MaterialTheme.colorScheme.onTertiaryContainer.copy(alpha = 0.7f)
                )
                Text(
                    text = game.homeTeam.abbreviation,
                    style = MaterialTheme.typography.labelSmall,
                    color = MaterialTheme.colorScheme.onTertiaryContainer.copy(alpha = 0.7f)
                )
            }
        }

        Spacer(modifier = Modifier.height(12.dp))

        // Confidence
        LinearProgressIndicator(
            progress = prediction.confidence.toFloat(),
            modifier = Modifier
                .fillMaxWidth()
                .height(8.dp)
                .clip(RoundedCornerShape(4.dp)),
        )

        Spacer(modifier = Modifier.height(4.dp))

        Text(
            text = "Confidence: ${(prediction.confidence * 100).toInt()}%",
            style = MaterialTheme.typography.bodySmall,
            color = MaterialTheme.colorScheme.onTertiaryContainer.copy(alpha = 0.7f)
        )

        // Vegas Odds if available
        prediction.vegasOdds?.let { odds ->
            Spacer(modifier = Modifier.height(16.dp))

            Surface(
                modifier = Modifier.fillMaxWidth(),
                color = Color(0xFFFF9800).copy(alpha = 0.15f),
                shape = RoundedCornerShape(8.dp)
            ) {
                Column(modifier = Modifier.padding(12.dp)) {
                    Row(
                        verticalAlignment = Alignment.CenterVertically,
                        horizontalArrangement = Arrangement.spacedBy(4.dp)
                    ) {
                        Icon(
                            painter = painterResource(android.R.drawable.ic_dialog_info),
                            contentDescription = null,
                            modifier = Modifier.size(16.dp),
                            tint = Color(0xFFFF9800)
                        )
                        Text(
                            text = "Vegas Odds",
                            style = MaterialTheme.typography.labelMedium,
                            fontWeight = FontWeight.Bold
                        )
                        odds.bookmaker?.let { bookmaker ->
                            Text(
                                text = "• $bookmaker",
                                style = MaterialTheme.typography.labelSmall,
                                color = MaterialTheme.colorScheme.onSurface.copy(alpha = 0.6f)
                            )
                        }
                    }

                    Spacer(modifier = Modifier.height(8.dp))

                    // Moneyline
                    if (odds.homeMoneyline != null && odds.awayMoneyline != null) {
                        Column {
                            Text(
                                text = "Moneyline",
                                style = MaterialTheme.typography.labelSmall,
                                color = MaterialTheme.colorScheme.onSurface.copy(alpha = 0.6f)
                            )
                            Row(
                                modifier = Modifier.fillMaxWidth(),
                                horizontalArrangement = Arrangement.spacedBy(16.dp)
                            ) {
                                Text(
                                    text = "${game.awayTeam.abbreviation}: ${if (odds.awayMoneyline > 0) "+" else ""}${odds.awayMoneyline}",
                                    style = MaterialTheme.typography.bodySmall
                                )
                                Text(
                                    text = "${game.homeTeam.abbreviation}: ${if (odds.homeMoneyline > 0) "+" else ""}${odds.homeMoneyline}",
                                    style = MaterialTheme.typography.bodySmall
                                )
                            }
                        }
                    }

                    // Spread
                    odds.spread?.let { spread ->
                        Spacer(modifier = Modifier.height(4.dp))
                        Row(horizontalArrangement = Arrangement.spacedBy(4.dp)) {
                            Text(
                                text = "Spread:",
                                style = MaterialTheme.typography.labelSmall,
                                color = MaterialTheme.colorScheme.onSurface.copy(alpha = 0.6f)
                            )
                            Text(
                                text = "${game.homeTeam.abbreviation} ${if (spread > 0) "+" else ""}${String.format("%.1f", spread)}",
                                style = MaterialTheme.typography.bodySmall
                            )
                        }
                    }

                    // Over/Under
                    odds.total?.let { total ->
                        Spacer(modifier = Modifier.height(4.dp))
                        Row(horizontalArrangement = Arrangement.spacedBy(4.dp)) {
                            Text(
                                text = "Over/Under:",
                                style = MaterialTheme.typography.labelSmall,
                                color = MaterialTheme.colorScheme.onSurface.copy(alpha = 0.6f)
                            )
                            Text(
                                text = String.format("%.1f", total),
                                style = MaterialTheme.typography.bodySmall
                            )
                        }
                    }

                    // AI vs Vegas comparison
                    if (odds.homeImpliedProbability != null && odds.awayImpliedProbability != null) {
                        Spacer(modifier = Modifier.height(8.dp))
                        Divider(color = MaterialTheme.colorScheme.onSurface.copy(alpha = 0.2f))
                        Spacer(modifier = Modifier.height(8.dp))

                        Text(
                            text = "AI vs Vegas",
                            style = MaterialTheme.typography.labelSmall,
                            fontWeight = FontWeight.SemiBold
                        )
                        Spacer(modifier = Modifier.height(4.dp))

                        Column(verticalArrangement = Arrangement.spacedBy(2.dp)) {
                            Row(horizontalArrangement = Arrangement.spacedBy(4.dp)) {
                                Text(
                                    text = "${game.homeTeam.abbreviation}:",
                                    style = MaterialTheme.typography.labelSmall,
                                    color = MaterialTheme.colorScheme.onSurface.copy(alpha = 0.6f),
                                    modifier = Modifier.width(35.dp)
                                )
                                Text(
                                    text = "AI: ${(prediction.homeWinProbability * 100).toInt()}% | Vegas: ${(odds.homeImpliedProbability * 100).toInt()}%",
                                    style = MaterialTheme.typography.bodySmall
                                )
                            }
                            Row(horizontalArrangement = Arrangement.spacedBy(4.dp)) {
                                Text(
                                    text = "${game.awayTeam.abbreviation}:",
                                    style = MaterialTheme.typography.labelSmall,
                                    color = MaterialTheme.colorScheme.onSurface.copy(alpha = 0.6f),
                                    modifier = Modifier.width(35.dp)
                                )
                                Text(
                                    text = "AI: ${(prediction.awayWinProbability * 100).toInt()}% | Vegas: ${(odds.awayImpliedProbability * 100).toInt()}%",
                                    style = MaterialTheme.typography.bodySmall
                                )
                            }
                        }
                    }
                }
            }
        }

        Spacer(modifier = Modifier.height(12.dp))

        // Reasoning
        Text(
            text = "Analysis",
            style = MaterialTheme.typography.labelMedium,
            fontWeight = FontWeight.Bold,
            color = MaterialTheme.colorScheme.onTertiaryContainer
        )
        Spacer(modifier = Modifier.height(4.dp))
        Text(
            text = prediction.reasoning,
            style = MaterialTheme.typography.bodyMedium,
            color = MaterialTheme.colorScheme.onTertiaryContainer.copy(alpha = 0.9f)
        )
    }
}

/**
 * Probability Chip
 */
@Composable
fun ProbabilityChip(team: String, probability: Double) {
    Surface(
        shape = RoundedCornerShape(16.dp),
        color = MaterialTheme.colorScheme.surface,
        tonalElevation = 2.dp
    ) {
        Row(
            modifier = Modifier.padding(horizontal = 12.dp, vertical = 6.dp),
            horizontalArrangement = Arrangement.spacedBy(4.dp),
            verticalAlignment = Alignment.CenterVertically
        ) {
            Text(
                text = team,
                style = MaterialTheme.typography.labelMedium,
                fontWeight = FontWeight.Bold
            )
            Text(
                text = "${(probability * 100).toInt()}%",
                style = MaterialTheme.typography.labelMedium
            )
        }
    }
}

/**
 * Loading Screen - Shows skeleton cards
 */
@Composable
fun LoadingScreen() {
    Column(
        modifier = Modifier
            .fillMaxSize()
            .padding(16.dp),
        verticalArrangement = Arrangement.spacedBy(16.dp)
    ) {
        // Info card placeholder
        Card(
            modifier = Modifier.fillMaxWidth(),
            colors = CardDefaults.cardColors(
                containerColor = MaterialTheme.colorScheme.primaryContainer
            )
        ) {
            Box(
                modifier = Modifier
                    .fillMaxWidth()
                    .height(80.dp)
            )
        }

        // Skeleton game cards
        SkeletonList(count = 3) {
            SkeletonGameCard()
        }
    }
}

/**
 * Error Screen
 */
@Composable
fun ErrorScreen(error: String, onRetry: () -> Unit) {
    Box(
        modifier = Modifier.fillMaxSize(),
        contentAlignment = Alignment.Center
    ) {
        Column(
            horizontalAlignment = Alignment.CenterHorizontally,
            verticalArrangement = Arrangement.spacedBy(16.dp)
        ) {
            Text(
                text = error,
                style = MaterialTheme.typography.bodyLarge,
                color = MaterialTheme.colorScheme.error,
                textAlign = TextAlign.Center
            )
            Button(onClick = onRetry) {
                Text("Retry")
            }
        }
    }
}

/**
 * Empty Screen
 */
@Composable
fun EmptyScreen(message: String) {
    Box(
        modifier = Modifier.fillMaxSize(),
        contentAlignment = Alignment.Center
    ) {
        Column(
            horizontalAlignment = Alignment.CenterHorizontally,
            verticalArrangement = Arrangement.spacedBy(8.dp)
        ) {
            Icon(
                imageVector = Icons.Filled.TrendingUp,
                contentDescription = null,
                modifier = Modifier.size(64.dp),
                tint = MaterialTheme.colorScheme.onSurfaceVariant.copy(alpha = 0.5f)
            )
            Text(
                text = message,
                style = MaterialTheme.typography.bodyLarge,
                color = MaterialTheme.colorScheme.onSurfaceVariant
            )
        }
    }
}

/**
 * Filters Card - Week and Confidence Filters
 */
@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun FiltersCard(
    availableWeeks: List<Int>,
    selectedWeek: Int?,
    currentWeek: Int?,
    minConfidence: Double,
    onWeekSelected: (Int?) -> Unit,
    onConfidenceSelected: (Double) -> Unit
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
                .padding(16.dp),
            verticalArrangement = Arrangement.spacedBy(12.dp)
        ) {
            Text(
                text = "Filters",
                style = MaterialTheme.typography.titleSmall,
                fontWeight = FontWeight.Bold
            )

            // Week Filter
            var weekExpanded by remember { mutableStateOf(false) }
            ExposedDropdownMenuBox(
                expanded = weekExpanded,
                onExpandedChange = { weekExpanded = it }
            ) {
                OutlinedTextField(
                    value = selectedWeek?.let { "Week $it${if (it == currentWeek) " (Current)" else ""}" } ?: "All Weeks",
                    onValueChange = {},
                    readOnly = true,
                    label = { Text("Week") },
                    trailingIcon = { ExposedDropdownMenuDefaults.TrailingIcon(expanded = weekExpanded) },
                    modifier = Modifier
                        .fillMaxWidth()
                        .menuAnchor(),
                    colors = OutlinedTextFieldDefaults.colors()
                )

                ExposedDropdownMenu(
                    expanded = weekExpanded,
                    onDismissRequest = { weekExpanded = false }
                ) {
                    DropdownMenuItem(
                        text = { Text("All Weeks") },
                        onClick = {
                            onWeekSelected(null)
                            weekExpanded = false
                        }
                    )
                    availableWeeks.forEach { week ->
                        DropdownMenuItem(
                            text = {
                                Row(
                                    horizontalArrangement = Arrangement.spacedBy(8.dp),
                                    verticalAlignment = Alignment.CenterVertically
                                ) {
                                    Text("Week $week")
                                    if (week == currentWeek) {
                                        Text(
                                            text = "(Current)",
                                            style = MaterialTheme.typography.bodySmall,
                                            color = MaterialTheme.colorScheme.primary
                                        )
                                    }
                                }
                            },
                            onClick = {
                                onWeekSelected(week)
                                weekExpanded = false
                            }
                        )
                    }
                }
            }

            // Confidence Filter
            var confidenceExpanded by remember { mutableStateOf(false) }
            val confidenceOptions = listOf(
                "All Predictions" to 0.0,
                "50%+ Confidence" to 0.5,
                "60%+ Confidence" to 0.6,
                "70%+ Confidence" to 0.7,
                "80%+ Confidence" to 0.8
            )

            ExposedDropdownMenuBox(
                expanded = confidenceExpanded,
                onExpandedChange = { confidenceExpanded = it }
            ) {
                OutlinedTextField(
                    value = confidenceOptions.find { it.second == minConfidence }?.first ?: "All Predictions",
                    onValueChange = {},
                    readOnly = true,
                    label = { Text("Confidence") },
                    trailingIcon = { ExposedDropdownMenuDefaults.TrailingIcon(expanded = confidenceExpanded) },
                    modifier = Modifier
                        .fillMaxWidth()
                        .menuAnchor(),
                    colors = OutlinedTextFieldDefaults.colors()
                )

                ExposedDropdownMenu(
                    expanded = confidenceExpanded,
                    onDismissRequest = { confidenceExpanded = false }
                ) {
                    confidenceOptions.forEach { (label, value) ->
                        DropdownMenuItem(
                            text = { Text(label) },
                            onClick = {
                                onConfidenceSelected(value)
                                confidenceExpanded = false
                            }
                        )
                    }
                }
            }
        }
    }
}

/**
 * Batch Predict Button
 */
@Composable
fun BatchPredictButton(
    isLoading: Boolean,
    progress: Float,
    gamesCount: Int,
    onClick: () -> Unit
) {
    Card(
        modifier = Modifier.fillMaxWidth(),
        colors = CardDefaults.cardColors(
            containerColor = MaterialTheme.colorScheme.primaryContainer
        )
    ) {
        if (isLoading) {
            Column(
                modifier = Modifier
                    .fillMaxWidth()
                    .padding(16.dp),
                verticalArrangement = Arrangement.spacedBy(8.dp)
            ) {
                LinearProgressIndicator(
                    progress = progress,
                    modifier = Modifier.fillMaxWidth()
                )
                Text(
                    text = "Predicting games: ${(progress * 100).toInt()}%",
                    style = MaterialTheme.typography.bodyMedium,
                    color = MaterialTheme.colorScheme.onPrimaryContainer
                )
            }
        } else {
            Button(
                onClick = onClick,
                modifier = Modifier
                    .fillMaxWidth()
                    .padding(16.dp),
                enabled = gamesCount > 0
            ) {
                Icon(
                    painter = painterResource(android.R.drawable.ic_media_play),
                    contentDescription = null,
                    modifier = Modifier.size(18.dp)
                )
                Spacer(modifier = Modifier.width(8.dp))
                Text("Predict All $gamesCount Games")
            }
        }
    }
}
