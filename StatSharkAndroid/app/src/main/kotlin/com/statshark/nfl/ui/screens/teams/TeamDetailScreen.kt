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
import androidx.compose.ui.platform.LocalContext
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
import com.statshark.nfl.ui.navigation.Screen
import com.statshark.nfl.ui.theme.TeamColors
import java.util.Calendar

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
                        onPlayerClick = { player ->
                            // Store player in cache and navigate
                            PlayerCache.put(player)
                            navController.navigate(Screen.PlayerDetail.createRoute(player.id, team.abbreviation))
                        }
                    )
                    1 -> GamesTab(
                        games = uiState.games,
                        teamAbbreviation = team.abbreviation,
                        isLoading = uiState.isLoadingGames,
                        error = uiState.gamesError,
                        onRetry = { viewModel.retry() },
                        onGameClick = { game ->
                            // Store game in cache and navigate
                            com.statshark.nfl.data.cache.GameCache.put(game)
                            navController.navigate(Screen.GameDetail.createRoute(game.id))
                        }
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
    onPlayerClick: (PlayerDTO) -> Unit
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
                                color = MaterialTheme.colorScheme.primary,
                                modifier = Modifier.padding(bottom = 8.dp)
                            )
                        }

                        items(positionPlayers) { player ->
                            PlayerCard(
                                player = player,
                                onClick = { onPlayerClick(player) }
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
                        text = player.name,
                        style = MaterialTheme.typography.titleMedium,
                        fontWeight = FontWeight.Bold,
                        maxLines = 1,
                        overflow = TextOverflow.Ellipsis
                    )
                    Spacer(modifier = Modifier.width(8.dp))
                    player.jerseyNumber?.let {
                        Text(
                            text = "#$it",
                            style = MaterialTheme.typography.bodyMedium,
                            color = MaterialTheme.colorScheme.onSurfaceVariant
                        )
                    }
                }
                Text(
                    text = player.position,
                    style = MaterialTheme.typography.bodyMedium,
                    color = MaterialTheme.colorScheme.onSurfaceVariant
                )
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
    onRetry: () -> Unit,
    onGameClick: (GameDTO) -> Unit
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
                    GameCard(
                        game = game,
                        perspective = teamAbbreviation,
                        onClick = { onGameClick(game) }
                    )
                }
            }
        }
    }
}

@Composable
fun GameCard(game: GameDTO, perspective: String, onClick: () -> Unit) {
    val opponent = if (game.homeTeam.abbreviation == perspective) game.awayTeam else game.homeTeam
    val isHomeGame = game.homeTeam.abbreviation == perspective
    val gameResult = when {
        game.homeScore == null || game.awayScore == null -> "TBD"
        isHomeGame && game.homeScore > game.awayScore -> "W"
        !isHomeGame && game.awayScore > game.homeScore -> "W"
        else -> "L"
    }

    Card(
        modifier = Modifier
            .fillMaxWidth()
            .clickable(onClick = onClick),
        elevation = CardDefaults.cardElevation(defaultElevation = 2.dp)
    ) {
        Row(
            modifier = Modifier
                .fillMaxWidth()
                .padding(16.dp),
            verticalAlignment = Alignment.CenterVertically,
            horizontalArrangement = Arrangement.SpaceBetween
        ) {
            Row(verticalAlignment = Alignment.CenterVertically) {
                Text(if (isHomeGame) "vs" else "@", style = MaterialTheme.typography.bodyLarge)
                Spacer(modifier = Modifier.width(16.dp))
                Text(opponent.name, style = MaterialTheme.typography.titleMedium, fontWeight = FontWeight.Bold)
            }
            Column(horizontalAlignment = Alignment.End) {
                Text("$gameResult ${game.homeScore ?: "-"} - ${game.awayScore ?: "-"}", style = MaterialTheme.typography.titleMedium)
                Text("Week ${game.week}", style = MaterialTheme.typography.bodySmall, color = MaterialTheme.colorScheme.onSurfaceVariant)
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
        news.isEmpty() -> EmptyScreen("No news found")
        else -> {
            LazyColumn(
                modifier = Modifier.fillMaxSize(),
                contentPadding = PaddingValues(16.dp),
                verticalArrangement = Arrangement.spacedBy(12.dp)
            ) {
                items(news) { article ->
                    NewsCard(article = article)
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
    val context = LocalContext.current

    Card(
        modifier = Modifier
            .fillMaxWidth()
            .clickable { /* TODO: Open article in browser */ },
        elevation = CardDefaults.cardElevation(defaultElevation = 2.dp)
    ) {
        Column(modifier = Modifier.padding(16.dp)) {
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
                overflow = TextOverflow.Ellipsis
            )
            Spacer(modifier = Modifier.height(8.dp))
            Row(
                modifier = Modifier.fillMaxWidth(),
                horizontalArrangement = Arrangement.SpaceBetween,
                verticalAlignment = Alignment.CenterVertically
            ) {
                Text(
                    text = article.source,
                    style = MaterialTheme.typography.labelSmall,
                    color = MaterialTheme.colorScheme.onSurfaceVariant
                )
                Text(
                    text = "- ago", // TODO: Format date
                    style = MaterialTheme.typography.labelSmall,
                    color = MaterialTheme.colorScheme.onSurfaceVariant
                )
            }
        }
    }
}

/**
 * Generic Loading Screen
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
 * Generic Error Screen
 */
@Composable
fun ErrorScreen(error: String, onRetry: () -> Unit) {
    Box(
        modifier = Modifier
            .fillMaxSize()
            .padding(24.dp),
        contentAlignment = Alignment.Center
    ) {
        Column(horizontalAlignment = Alignment.CenterHorizontally) {
            Text(text = "Error: $error", color = MaterialTheme.colorScheme.error, textAlign = TextAlign.Center)
            Spacer(modifier = Modifier.height(16.dp))
            Button(onClick = onRetry) {
                Text("Retry")
            }
        }
    }
}

/**
 * Generic Empty Screen
 */
@Composable
fun EmptyScreen(message: String) {
    Box(
        modifier = Modifier.fillMaxSize(),
        contentAlignment = Alignment.Center
    ) {
        Text(text = message, style = MaterialTheme.typography.bodyLarge)
    }
}
