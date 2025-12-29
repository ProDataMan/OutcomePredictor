package com.statshark.nfl.ui.screens.teams

import androidx.compose.foundation.background
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.items
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.ArrowBack
import androidx.compose.material.icons.filled.Person
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.Brush
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.layout.ContentScale
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.text.style.TextOverflow
import androidx.compose.ui.unit.dp
import androidx.hilt.navigation.compose.hiltViewModel
import androidx.lifecycle.compose.collectAsStateWithLifecycle
import androidx.navigation.NavController
import coil.compose.AsyncImage
import com.statshark.nfl.data.cache.PlayerCache
import com.statshark.nfl.data.model.ArticleDTO
import com.statshark.nfl.data.model.GameDTO
import com.statshark.nfl.data.model.PlayerDTO
import com.statshark.nfl.data.model.PlayerStatsDTO
import com.statshark.nfl.ui.navigation.Screen
import com.statshark.nfl.ui.theme.TeamColors
import java.text.SimpleDateFormat
import java.util.*

/**
 * Team Detail Screen
 * Shows team roster, game history, and news
 */
@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun TeamDetailScreen(
    teamId: String,
    navController: NavController,
    viewModel: TeamDetailViewModel = hiltViewModel()
) {
    val uiState by viewModel.uiState.collectAsStateWithLifecycle()
    val team = uiState.team

    Scaffold(
        topBar = {
            TopAppBar(
                title = {
                    Column {
                        Text(
                            text = team?.name ?: "Loading...",
                            style = MaterialTheme.typography.titleMedium
                        )
                        if (team != null) {
                            Text(
                                text = "${team.city} • ${team.conference} ${team.division}",
                                style = MaterialTheme.typography.bodySmall,
                                color = MaterialTheme.colorScheme.onPrimaryContainer.copy(alpha = 0.7f)
                            )
                        }
                    }
                },
                navigationIcon = {
                    IconButton(onClick = { navController.navigateUp() }) {
                        Icon(Icons.Default.ArrowBack, contentDescription = "Back")
                    }
                },
                colors = TopAppBarDefaults.topAppBarColors(
                    containerColor = team?.let {
                        TeamColors.getTeamColors(it.abbreviation).primary
                    } ?: MaterialTheme.colorScheme.primaryContainer,
                    titleContentColor = Color.White,
                    navigationIconContentColor = Color.White
                )
            )
        }
    ) { paddingValues ->
        if (team == null) {
            LoadingScreen()
        } else {
            var selectedTab by remember { mutableIntStateOf(0) }
            val tabs = listOf("Roster", "Games", "News")

            Column(
                modifier = Modifier
                    .fillMaxSize()
                    .padding(paddingValues)
            ) {
                // Team Header with gradient
                TeamHeader(
                    team = team,
                    selectedSeason = uiState.selectedSeason,
                    onSeasonChange = { viewModel.changeSeason(it) }
                )

                // Tabs
                TabRow(
                    selectedTabIndex = selectedTab,
                    containerColor = MaterialTheme.colorScheme.surface
                ) {
                    tabs.forEachIndexed { index, title ->
                        Tab(
                            selected = selectedTab == index,
                            onClick = { selectedTab = index },
                            text = { Text(title) }
                        )
                    }
                }

                // Tab Content
                when (selectedTab) {
                    0 -> RosterTab(
                        players = uiState.players,
                        isLoading = uiState.isLoadingRoster,
                        error = uiState.rosterError,
                        onRetry = { viewModel.retry() },
                        onPlayerClick = { playerId ->
                            // Store player in cache and navigate
                            uiState.players.find { it.id == playerId }?.let { player ->
                                PlayerCache.put(player)
                                navController.navigate(Screen.PlayerDetail.createRoute(playerId, team.abbreviation))
                            }
                        }
                    )
                    1 -> GamesTab(
                        games = uiState.games,
                        teamAbbreviation = team.abbreviation,
                        isLoading = uiState.isLoadingGames,
                        error = uiState.gamesError,
                        onRetry = { viewModel.retry() }
                    )
                    2 -> NewsTab(
                        news = uiState.news,
                        isLoading = uiState.isLoadingNews,
                        error = uiState.newsError,
                        onRetry = { viewModel.retry() }
                    )
                }
            }
        }
    }
}

/**
 * Team Header with gradient background
 */
@Composable
fun TeamHeader(
    team: com.statshark.nfl.data.model.TeamDTO,
    selectedSeason: Int,
    onSeasonChange: (Int) -> Unit
) {
    val colors = TeamColors.getTeamColors(team.abbreviation)
    val currentYear = Calendar.getInstance().get(Calendar.YEAR)
    val seasons = (currentYear downTo 2020).toList()

    Column(
        modifier = Modifier
            .fillMaxWidth()
            .background(
                brush = Brush.verticalGradient(
                    colors = listOf(
                        colors.primary,
                        colors.primary.copy(alpha = 0.7f)
                    )
                )
            )
            .padding(16.dp),
        horizontalAlignment = Alignment.CenterHorizontally
    ) {
        Text(
            text = team.abbreviation,
            style = MaterialTheme.typography.displaySmall,
            fontWeight = FontWeight.Bold,
            color = Color.White
        )

        Spacer(modifier = Modifier.height(8.dp))

        // Season Selector
        Row(
            horizontalArrangement = Arrangement.spacedBy(8.dp),
            verticalAlignment = Alignment.CenterVertically
        ) {
            Text(
                text = "Season:",
                style = MaterialTheme.typography.bodyMedium,
                color = Color.White.copy(alpha = 0.9f)
            )
            var expanded by remember { mutableStateOf(false) }
            Box {
                OutlinedButton(
                    onClick = { expanded = true },
                    colors = ButtonDefaults.outlinedButtonColors(
                        contentColor = Color.White
                    )
                ) {
                    Text(selectedSeason.toString())
                }
                DropdownMenu(
                    expanded = expanded,
                    onDismissRequest = { expanded = false }
                ) {
                    seasons.forEach { season ->
                        DropdownMenuItem(
                            text = { Text(season.toString()) },
                            onClick = {
                                onSeasonChange(season)
                                expanded = false
                            }
                        )
                    }
                }
            }
        }
    }
}

/**
 * Roster Tab
 */
@Composable
fun RosterTab(
    players: List<PlayerDTO>,
    isLoading: Boolean,
    error: String?,
    onRetry: () -> Unit,
    onPlayerClick: (String) -> Unit
) {
    when {
        isLoading -> LoadingScreen()
        error != null -> ErrorScreen(error, onRetry)
        players.isEmpty() -> EmptyScreen("No players found")
        else -> {
            val groupedPlayers = players.groupBy { it.position.first().toString() }
            val positionOrder = listOf("Q", "R", "W", "T", "O", "D", "L", "S", "C", "K", "P")

            LazyColumn(
                modifier = Modifier.fillMaxSize(),
                contentPadding = PaddingValues(16.dp),
                verticalArrangement = Arrangement.spacedBy(16.dp)
            ) {
                positionOrder.forEach { positionGroup ->
                    val positionPlayers = groupedPlayers.entries
                        .filter { it.key == positionGroup }
                        .flatMap { it.value }
                        .sortedBy { it.position }

                    if (positionPlayers.isNotEmpty()) {
                        item {
                            Text(
                                text = getPositionGroupName(positionGroup),
                                style = MaterialTheme.typography.titleMedium,
                                fontWeight = FontWeight.Bold,
                                color = MaterialTheme.colorScheme.primary
                            )
                        }

                        items(positionPlayers) { player ->
                            PlayerCard(
                                player = player,
                                onClick = { onPlayerClick(player.id) }
                            )
                        }
                    }
                }
            }
        }
    }
}

/**
 * Get position group display name
 */
fun getPositionGroupName(group: String): String = when (group) {
    "Q" -> "Quarterbacks"
    "R" -> "Running Backs"
    "W" -> "Wide Receivers"
    "T" -> "Tight Ends"
    "O" -> "Offensive Line"
    "D" -> "Defensive Line"
    "L" -> "Linebackers"
    "S" -> "Defensive Backs"
    "C" -> "Cornerbacks"
    "K" -> "Kickers"
    "P" -> "Punters"
    else -> "Other"
}

/**
 * Player Card
 */
@Composable
fun PlayerCard(
    player: PlayerDTO,
    onClick: () -> Unit
) {
    Card(
        modifier = Modifier
            .fillMaxWidth()
            .clickable(onClick = onClick),
        elevation = CardDefaults.cardElevation(defaultElevation = 2.dp)
    ) {
        Row(
            modifier = Modifier
                .fillMaxWidth()
                .padding(12.dp),
            verticalAlignment = Alignment.CenterVertically
        ) {
            // Player photo or placeholder
            Box(
                modifier = Modifier
                    .size(56.dp)
                    .clip(CircleShape)
                    .background(MaterialTheme.colorScheme.primaryContainer),
                contentAlignment = Alignment.Center
            ) {
                if (player.photoURL != null) {
                    AsyncImage(
                        model = player.photoURL,
                        contentDescription = player.name,
                        modifier = Modifier.fillMaxSize(),
                        contentScale = ContentScale.Crop
                    )
                } else {
                    Icon(
                        imageVector = Icons.Default.Person,
                        contentDescription = null,
                        tint = MaterialTheme.colorScheme.onPrimaryContainer,
                        modifier = Modifier.size(32.dp)
                    )
                }
            }

            Spacer(modifier = Modifier.width(12.dp))

            // Player info
            Column(modifier = Modifier.weight(1f)) {
                Row(verticalAlignment = Alignment.CenterVertically) {
                    Text(
                        text = "${player.jerseyNumber ?: "—"}",
                        style = MaterialTheme.typography.titleMedium,
                        fontWeight = FontWeight.Bold
                    )
                    Spacer(modifier = Modifier.width(8.dp))
                    Text(
                        text = player.name,
                        style = MaterialTheme.typography.titleMedium
                    )
                }
                Row(
                    modifier = Modifier.fillMaxWidth(),
                    horizontalArrangement = Arrangement.spacedBy(8.dp)
                ) {
                    Text(
                        text = player.position,
                        style = MaterialTheme.typography.bodyMedium,
                        color = MaterialTheme.colorScheme.primary,
                        fontWeight = FontWeight.Bold
                    )
                    if (player.height != null && player.weight != null) {
                        Text(
                            text = "•",
                            style = MaterialTheme.typography.bodyMedium,
                            color = MaterialTheme.colorScheme.onSurfaceVariant
                        )
                        Text(
                            text = "${player.height} • ${player.weight}lbs",
                            style = MaterialTheme.typography.bodyMedium,
                            color = MaterialTheme.colorScheme.onSurfaceVariant
                        )
                    }
                }
                if (player.college != null) {
                    Text(
                        text = player.college,
                        style = MaterialTheme.typography.bodySmall,
                        color = MaterialTheme.colorScheme.onSurfaceVariant
                    )
                }
            }

            // Stats preview
            player.stats?.let { stats ->
                Column(
                    horizontalAlignment = Alignment.End
                ) {
                    when (player.position.first()) {
                        'Q' -> {
                            stats.passingYards?.let {
                                Text(
                                    text = "${it} YDS",
                                    style = MaterialTheme.typography.bodyMedium,
                                    fontWeight = FontWeight.Bold
                                )
                            }
                            stats.passingTouchdowns?.let {
                                Text(
                                    text = "${it} TD",
                                    style = MaterialTheme.typography.bodySmall
                                )
                            }
                        }
                        'R' -> {
                            stats.rushingYards?.let {
                                Text(
                                    text = "${it} YDS",
                                    style = MaterialTheme.typography.bodyMedium,
                                    fontWeight = FontWeight.Bold
                                )
                            }
                            stats.rushingTouchdowns?.let {
                                Text(
                                    text = "${it} TD",
                                    style = MaterialTheme.typography.bodySmall
                                )
                            }
                        }
                        'W', 'T' -> {
                            stats.receivingYards?.let {
                                Text(
                                    text = "${it} YDS",
                                    style = MaterialTheme.typography.bodyMedium,
                                    fontWeight = FontWeight.Bold
                                )
                            }
                            stats.receptions?.let {
                                Text(
                                    text = "${it} REC",
                                    style = MaterialTheme.typography.bodySmall
                                )
                            }
                        }
                        'D', 'L', 'S', 'C' -> {
                            stats.tackles?.let {
                                Text(
                                    text = "${it} TKL",
                                    style = MaterialTheme.typography.bodyMedium,
                                    fontWeight = FontWeight.Bold
                                )
                            }
                            stats.sacks?.let {
                                Text(
                                    text = "${it} SCK",
                                    style = MaterialTheme.typography.bodySmall
                                )
                            }
                        }
                    }
                }
            }
        }
    }
}

/**
 * Games Tab
 */
@Composable
fun GamesTab(
    games: List<GameDTO>,
    teamAbbreviation: String,
    isLoading: Boolean,
    error: String?,
    onRetry: () -> Unit
) {
    when {
        isLoading -> LoadingScreen()
        error != null -> ErrorScreen(error, onRetry)
        games.isEmpty() -> EmptyScreen("No games found")
        else -> {
            LazyColumn(
                modifier = Modifier.fillMaxSize(),
                contentPadding = PaddingValues(16.dp),
                verticalArrangement = Arrangement.spacedBy(12.dp)
            ) {
                items(games) { game ->
                    GameCard(game, teamAbbreviation)
                }
            }
        }
    }
}

/**
 * Game Card
 */
@Composable
fun GameCard(game: GameDTO, viewingTeam: String) {
    val dateFormat = remember { SimpleDateFormat("MMM d, yyyy", Locale.US) }
    val isHomeGame = game.homeTeam.abbreviation == viewingTeam
    val opponent = if (isHomeGame) game.awayTeam else game.homeTeam
    val teamScore = if (isHomeGame) game.homeScore else game.awayScore
    val opponentScore = if (isHomeGame) game.awayScore else game.homeScore

    val result = if (teamScore != null && opponentScore != null) {
        when {
            teamScore > opponentScore -> "W"
            teamScore < opponentScore -> "L"
            else -> "T"
        }
    } else "—"

    val resultColor = when (result) {
        "W" -> Color(0xFF4CAF50)
        "L" -> Color(0xFFF44336)
        "T" -> Color(0xFFFF9800)
        else -> MaterialTheme.colorScheme.onSurfaceVariant
    }

    Card(
        modifier = Modifier.fillMaxWidth(),
        elevation = CardDefaults.cardElevation(defaultElevation = 2.dp)
    ) {
        Row(
            modifier = Modifier
                .fillMaxWidth()
                .padding(16.dp),
            verticalAlignment = Alignment.CenterVertically
        ) {
            // Result badge
            Box(
                modifier = Modifier
                    .size(40.dp)
                    .clip(CircleShape)
                    .background(resultColor),
                contentAlignment = Alignment.Center
            ) {
                Text(
                    text = result,
                    style = MaterialTheme.typography.titleMedium,
                    fontWeight = FontWeight.Bold,
                    color = Color.White
                )
            }

            Spacer(modifier = Modifier.width(16.dp))

            // Game info
            Column(modifier = Modifier.weight(1f)) {
                Row(
                    modifier = Modifier.fillMaxWidth(),
                    horizontalArrangement = Arrangement.SpaceBetween,
                    verticalAlignment = Alignment.CenterVertically
                ) {
                    Text(
                        text = "${if (isHomeGame) "vs" else "@"} ${opponent.abbreviation}",
                        style = MaterialTheme.typography.titleMedium,
                        fontWeight = FontWeight.Bold
                    )
                    if (teamScore != null && opponentScore != null) {
                        Text(
                            text = "$teamScore - $opponentScore",
                            style = MaterialTheme.typography.titleMedium,
                            fontWeight = FontWeight.Bold
                        )
                    }
                }
                Text(
                    text = dateFormat.format(game.date),
                    style = MaterialTheme.typography.bodyMedium,
                    color = MaterialTheme.colorScheme.onSurfaceVariant
                )
                Text(
                    text = "Week ${game.week}",
                    style = MaterialTheme.typography.bodySmall,
                    color = MaterialTheme.colorScheme.onSurfaceVariant
                )
            }
        }
    }
}

/**
 * News Tab
 */
@Composable
fun NewsTab(
    news: List<ArticleDTO>,
    isLoading: Boolean,
    error: String?,
    onRetry: () -> Unit
) {
    when {
        isLoading -> LoadingScreen()
        error != null -> ErrorScreen(error, onRetry)
        news.isEmpty() -> EmptyScreen("No news available")
        else -> {
            LazyColumn(
                modifier = Modifier.fillMaxSize(),
                contentPadding = PaddingValues(16.dp),
                verticalArrangement = Arrangement.spacedBy(12.dp)
            ) {
                items(news) { article ->
                    NewsCard(article)
                }
            }
        }
    }
}

/**
 * News Card
 */
@Composable
fun NewsCard(article: ArticleDTO) {
    val dateFormat = remember { SimpleDateFormat("MMM d, yyyy", Locale.US) }

    Card(
        modifier = Modifier.fillMaxWidth(),
        elevation = CardDefaults.cardElevation(defaultElevation = 2.dp)
    ) {
        Column(
            modifier = Modifier
                .fillMaxWidth()
                .padding(16.dp)
        ) {
            Text(
                text = article.title,
                style = MaterialTheme.typography.titleMedium,
                fontWeight = FontWeight.Bold,
                maxLines = 2,
                overflow = TextOverflow.Ellipsis
            )
            Spacer(modifier = Modifier.height(8.dp))
            Text(
                text = article.content,
                style = MaterialTheme.typography.bodyMedium,
                maxLines = 3,
                overflow = TextOverflow.Ellipsis,
                color = MaterialTheme.colorScheme.onSurfaceVariant
            )
            Spacer(modifier = Modifier.height(8.dp))
            Row(
                modifier = Modifier.fillMaxWidth(),
                horizontalArrangement = Arrangement.SpaceBetween
            ) {
                Text(
                    text = article.source,
                    style = MaterialTheme.typography.bodySmall,
                    color = MaterialTheme.colorScheme.primary,
                    fontWeight = FontWeight.Bold
                )
                Text(
                    text = dateFormat.format(article.date),
                    style = MaterialTheme.typography.bodySmall,
                    color = MaterialTheme.colorScheme.onSurfaceVariant
                )
            }
        }
    }
}

/**
 * Loading Screen
 */
@Composable
fun LoadingScreen() {
    Box(
        modifier = Modifier.fillMaxSize(),
        contentAlignment = Alignment.Center
    ) {
        CircularProgressIndicator()
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
        Text(
            text = message,
            style = MaterialTheme.typography.bodyLarge,
            color = MaterialTheme.colorScheme.onSurfaceVariant
        )
    }
}
