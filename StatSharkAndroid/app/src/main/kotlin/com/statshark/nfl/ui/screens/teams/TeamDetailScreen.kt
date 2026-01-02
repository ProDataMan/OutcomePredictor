package com.statshark.nfl.ui.screens.teams

import android.content.Intent
import android.net.Uri
import androidx.compose.foundation.Image
import androidx.compose.foundation.background
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.items
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.ArrowBack
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.Brush
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.layout.ContentScale
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.res.painterResource
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.text.style.TextOverflow
import androidx.compose.ui.unit.dp
import androidx.hilt.navigation.compose.hiltViewModel
import androidx.lifecycle.compose.collectAsStateWithLifecycle
import androidx.navigation.NavController
import coil.compose.AsyncImage
import com.statshark.nfl.R
import com.statshark.nfl.data.cache.PlayerCache
import com.statshark.nfl.data.model.ArticleDTO
import com.statshark.nfl.data.model.GameDTO
import com.statshark.nfl.data.model.PlayerDTO
import com.statshark.nfl.ui.navigation.Screen
import com.statshark.nfl.ui.theme.TeamColors
import com.statshark.nfl.ui.components.FeedbackButton
import com.statshark.nfl.data.cache.ArticleCache
import com.statshark.nfl.data.cache.GameCache
import java.text.SimpleDateFormat
import java.util.Calendar
import java.util.Locale

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
                            style = MaterialTheme.typography.titleLarge
                        )
                        if (team != null) {
                            Text(
                                text = listOfNotNull(team.city, team.conference, team.division).joinToString(" • "),
                                style = MaterialTheme.typography.bodyMedium,
                                color = Color.White.copy(alpha = 0.8f)
                            )
                        }
                    }
                },
                navigationIcon = {
                    IconButton(onClick = { navController.navigateUp() }) {
                        Icon(Icons.Filled.ArrowBack, contentDescription = "Back", tint = Color.White)
                    }
                },
                actions = {
                    FeedbackButton(pageName = "Team Detail")
                },
                colors = TopAppBarDefaults.topAppBarColors(
                    containerColor = uiState.team?.let { TeamColors.getPrimaryColor(it.abbreviation) } ?: MaterialTheme.colorScheme.surface,
                    titleContentColor = Color.White
                )
            )
        }
    ) { paddingValues ->
        if (team == null) {
            LoadingScreen(modifier = Modifier.padding(paddingValues))
        } else {
            var selectedTab by remember { mutableIntStateOf(0) }
            val tabs = listOf("Roster", "News")

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

                // Next Game Card
                if (uiState.games.isNotEmpty()) {
                    val upcomingGame = uiState.games.firstOrNull { game ->
                        game.homeScore == null && game.awayScore == null
                    }
                    upcomingGame?.let { game ->
                        Card(
                            modifier = Modifier
                                .fillMaxWidth()
                                .padding(horizontal = 16.dp, vertical = 8.dp)
                                .clickable {
                                    // Cache the game and navigate directly to game detail (which shows predictions)
                                    GameCache.put(game)
                                    navController.navigate(
                                        Screen.GameDetail.createRoute(game.id)
                                    )
                                },
                            colors = CardDefaults.cardColors(
                                containerColor = MaterialTheme.colorScheme.primaryContainer
                            )
                        ) {
                            Column(modifier = Modifier.padding(16.dp)) {
                                Text(
                                    text = "NEXT GAME",
                                    style = MaterialTheme.typography.labelSmall,
                                    fontWeight = FontWeight.Bold,
                                    color = MaterialTheme.colorScheme.primary
                                )
                                Spacer(modifier = Modifier.height(8.dp))
                                val opponent = if (game.homeTeam.abbreviation == team.abbreviation) game.awayTeam else game.homeTeam
                                val isHome = game.homeTeam.abbreviation == team.abbreviation
                                Text(
                                    text = "${if (isHome) "vs" else "@"} ${opponent.name}",
                                    style = MaterialTheme.typography.titleMedium,
                                    fontWeight = FontWeight.Bold
                                )
                                Text(
                                    text = "Week ${game.week} • ${game.date}",
                                    style = MaterialTheme.typography.bodyMedium,
                                    color = MaterialTheme.colorScheme.onSurfaceVariant
                                )
                            }
                        }
                    }
                }

                // Tabs
                TabRow(
                    selectedTabIndex = selectedTab,
                    containerColor = MaterialTheme.colorScheme.surfaceVariant
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
                            PlayerCache.put(player)
                            navController.navigate(Screen.PlayerDetail.createRoute(player.id, team.abbreviation))
                        }
                    )
                    1 -> NewsTab(
                        news = uiState.news,
                        isLoading = uiState.isLoadingNews,
                        error = uiState.newsError,
                        onRetry = { viewModel.retry() },
                        navController = navController
                    )
                }
            }
        }
    }
}

/**
 * Team Header with gradient background
 */
@OptIn(ExperimentalMaterial3Api::class)
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
        // Team Helmet
        val helmetResourceId = getTeamHelmetResource(team.abbreviation)
        if (helmetResourceId != null) {
            androidx.compose.foundation.Image(
                painter = painterResource(id = helmetResourceId),
                contentDescription = "${team.name} helmet",
                modifier = Modifier.size(120.dp)
            )
        }

        Spacer(modifier = Modifier.height(12.dp))

        Text(
            text = team.name,
            style = MaterialTheme.typography.headlineMedium,
            fontWeight = FontWeight.Bold,
            color = Color.White,
            textAlign = TextAlign.Center
        )

        Spacer(modifier = Modifier.height(4.dp))

        Text(
            text = "${team.city} • ${team.conference} ${team.division}",
            style = MaterialTheme.typography.bodyLarge,
            color = Color.White.copy(alpha = 0.9f)
        )

        Spacer(modifier = Modifier.height(12.dp))

        // Season Selector
        Row(
            horizontalArrangement = Arrangement.spacedBy(8.dp),
            verticalAlignment = Alignment.CenterVertically
        ) {
            Text(
                text = "Season:",
                style = MaterialTheme.typography.bodyLarge,
                color = Color.White.copy(alpha = 0.9f)
            )
            var expanded by remember { mutableStateOf(false) }
            ExposedDropdownMenuBox(expanded = expanded, onExpandedChange = { expanded = !expanded }) {
                OutlinedTextField(
                    value = selectedSeason.toString(),
                    onValueChange = {},
                    readOnly = true,
                    trailingIcon = { ExposedDropdownMenuDefaults.TrailingIcon(expanded = expanded) },
                    colors = ExposedDropdownMenuDefaults.outlinedTextFieldColors(
                        focusedBorderColor = Color.White,
                        unfocusedBorderColor = Color.White.copy(alpha = 0.5f),
                        focusedLabelColor = Color.White,
                        unfocusedLabelColor = Color.White.copy(alpha = 0.5f),
                        focusedTextColor = Color.White,
                        unfocusedTextColor = Color.White
                    ),
                    modifier = Modifier.menuAnchor()
                )
                ExposedDropdownMenu(
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
        players.isEmpty() -> EmptyScreen("No players found for this season")
        else -> {
            val groupedPlayers = players.groupBy { it.position }
                .entries.sortedBy { getPositionSortOrder(it.key) }

            LazyColumn(
                modifier = Modifier.fillMaxSize(),
                contentPadding = PaddingValues(vertical = 16.dp)
            ) {
                groupedPlayers.forEach { (position, playersInGroup) ->
                    item {
                        Text(
                            text = position,
                            style = MaterialTheme.typography.titleMedium,
                            fontWeight = FontWeight.Bold,
                            color = MaterialTheme.colorScheme.primary,
                            modifier = Modifier.padding(horizontal = 16.dp, vertical = 8.dp)
                        )
                    }
                    items(playersInGroup, key = { it.id }) { player ->
                        PlayerCard(
                            player = player,
                            onClick = { onPlayerClick(player) },
                            modifier = Modifier.padding(horizontal = 16.dp, vertical = 4.dp)
                        )
                    }
                }
            }
        }
    }
}

fun getPositionSortOrder(position: String): Int = when(position) {
    "QB" -> 1
    "RB" -> 2
    "FB" -> 3
    "WR" -> 4
    "TE" -> 5
    "T" -> 6
    "G" -> 7
    "C" -> 8
    "DE" -> 9
    "DT" -> 10
    "LB" -> 11
    "CB" -> 12
    "S" -> 13
    "K" -> 14
    "P" -> 15
    "LS" -> 16
    else -> 99
}

/**
 * Player Card with stats
 */
@Composable
fun PlayerCard(
    player: PlayerDTO,
    onClick: () -> Unit,
    modifier: Modifier = Modifier
) {
    Card(
        modifier = modifier
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
            AsyncImage(
                model = player.photoURL,
                contentDescription = player.name,
                placeholder = painterResource(id = R.drawable.ic_helmet_placeholder),
                error = painterResource(id = R.drawable.ic_helmet_placeholder),
                modifier = Modifier
                    .size(56.dp)
                    .clip(CircleShape),
                contentScale = ContentScale.Crop
            )

            Spacer(modifier = Modifier.width(12.dp))

            // Player info
            Column(modifier = Modifier.weight(1f)) {
                Row(verticalAlignment = Alignment.CenterVertically) {
                    Text(
                        text = player.name,
                        style = MaterialTheme.typography.titleSmall,
                        fontWeight = FontWeight.Bold,
                        maxLines = 1,
                        overflow = TextOverflow.Ellipsis
                    )
                    Spacer(modifier = Modifier.width(8.dp))
                    player.jerseyNumber?.let {
                        Text(
                            text = "#$it",
                            style = MaterialTheme.typography.bodySmall,
                            color = MaterialTheme.colorScheme.onSurfaceVariant
                        )
                    }
                }
                Text(
                    text = player.position,
                    style = MaterialTheme.typography.bodySmall,
                    color = MaterialTheme.colorScheme.onSurfaceVariant
                )

                // Player stats based on position
                player.stats?.let { stats ->
                    Spacer(modifier = Modifier.height(4.dp))
                    when (player.position) {
                        "QB" -> {
                            if (stats.passingYards != null || stats.passingTouchdowns != null) {
                                Text(
                                    text = buildString {
                                        stats.passingYards?.let { append("$it YDS") }
                                        if (stats.passingYards != null && stats.passingTouchdowns != null) append(" • ")
                                        stats.passingTouchdowns?.let { append("$it TD") }
                                    },
                                    style = MaterialTheme.typography.labelMedium,
                                    color = MaterialTheme.colorScheme.primary,
                                    fontWeight = FontWeight.SemiBold
                                )
                            }
                        }
                        "RB" -> {
                            if (stats.rushingYards != null || stats.rushingTouchdowns != null) {
                                Text(
                                    text = buildString {
                                        stats.rushingYards?.let { append("$it YDS") }
                                        if (stats.rushingYards != null && stats.rushingTouchdowns != null) append(" • ")
                                        stats.rushingTouchdowns?.let { append("$it TD") }
                                    },
                                    style = MaterialTheme.typography.labelMedium,
                                    color = MaterialTheme.colorScheme.primary,
                                    fontWeight = FontWeight.SemiBold
                                )
                            }
                        }
                        "WR", "TE" -> {
                            if (stats.receivingYards != null || stats.receivingTouchdowns != null) {
                                Text(
                                    text = buildString {
                                        stats.receivingYards?.let { append("$it YDS") }
                                        if (stats.receivingYards != null && stats.receivingTouchdowns != null) append(" • ")
                                        stats.receivingTouchdowns?.let { append("$it TD") }
                                    },
                                    style = MaterialTheme.typography.labelMedium,
                                    color = MaterialTheme.colorScheme.primary,
                                    fontWeight = FontWeight.SemiBold
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
    onRetry: () -> Unit,
    onGameClick: (GameDTO) -> Unit
) {
    when {
        isLoading -> LoadingScreen()
        error != null -> ErrorScreen(error, onRetry)
        games.isEmpty() -> EmptyScreen("No games found for this season")
        else -> {
            LazyColumn(
                modifier = Modifier.fillMaxSize(),
                contentPadding = PaddingValues(16.dp),
                verticalArrangement = Arrangement.spacedBy(12.dp)
            ) {
                items(games, key = { it.id }) { game ->
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
fun GameCard(
    game: GameDTO,
    perspective: String,
    onClick: () -> Unit
) {
    val opponent = if (game.homeTeam.abbreviation == perspective) game.awayTeam else game.homeTeam
    val isHomeGame = game.homeTeam.abbreviation == perspective
    val gameResult = when {
        game.homeScore == null || game.awayScore == null -> "TBD"
        isHomeGame && game.homeScore > game.awayScore -> "W"
        !isHomeGame && game.awayScore > game.homeScore -> "W"
        else -> "L"
    }
    val score = if (game.homeScore != null && game.awayScore != null) {
        if (isHomeGame) "${game.homeScore}-${game.awayScore}" else "${game.awayScore}-${game.homeScore}"
    } else {
        "- vs -"
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
                Spacer(modifier = Modifier.width(12.dp))
                Text("${if (isHomeGame) "vs" else "@"} ${opponent.name}", style = MaterialTheme.typography.bodyLarge, fontWeight = FontWeight.Bold)
            }
            Column(horizontalAlignment = Alignment.End) {
                Text("$gameResult $score", style = MaterialTheme.typography.bodyLarge, fontWeight = FontWeight.Bold)
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
    onRetry: () -> Unit,
    navController: NavController
) {
    when {
        isLoading -> LoadingScreen()
        error != null -> ErrorScreen(error, onRetry)
        news.isEmpty() -> EmptyScreen("No news found for this team")
        else -> {
            LazyColumn(
                modifier = Modifier.fillMaxSize(),
                contentPadding = PaddingValues(16.dp),
                verticalArrangement = Arrangement.spacedBy(12.dp)
            ) {
                items(news, key = { it.id }) { article ->
                    NewsCard(article = article, navController = navController)
                }
            }
        }
    }
}

/**
 * News Card
 */
@Composable
fun NewsCard(article: ArticleDTO, navController: NavController) {
    val dateFormat = remember { SimpleDateFormat("MMM d, yyyy", Locale.US) }

    Card(
        modifier = Modifier
            .fillMaxWidth()
            .clickable {
                // Cache article and navigate to detail screen
                ArticleCache.put(article)
                navController.navigate(Screen.ArticleDetail.createRoute(article.id))
            },
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
                    text = dateFormat.format(article.date),
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
fun LoadingScreen(modifier: Modifier = Modifier) {
    Box(
        modifier = modifier.fillMaxSize(),
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
        Column(horizontalAlignment = Alignment.CenterHorizontally, verticalArrangement = Arrangement.spacedBy(16.dp)) {
            Text(text = "Error: $error", color = MaterialTheme.colorScheme.error, textAlign = TextAlign.Center)
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
