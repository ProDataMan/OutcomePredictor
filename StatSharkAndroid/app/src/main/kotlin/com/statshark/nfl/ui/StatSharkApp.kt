package com.statshark.nfl.ui

import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.padding
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.Home
import androidx.compose.material3.*
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.ui.Modifier
import androidx.navigation.NavDestination.Companion.hierarchy
import androidx.navigation.NavGraph.Companion.findStartDestination
import androidx.navigation.NavType
import androidx.navigation.compose.NavHost
import androidx.navigation.compose.composable
import androidx.navigation.compose.currentBackStackEntryAsState
import androidx.navigation.compose.rememberNavController
import androidx.navigation.navArgument
import com.statshark.nfl.data.cache.GameCache
import com.statshark.nfl.data.cache.PlayerCache
import com.statshark.nfl.ui.navigation.Screen
import com.statshark.nfl.ui.navigation.bottomNavItems
import com.statshark.nfl.ui.screens.fantasy.FantasyScreen
import com.statshark.nfl.ui.screens.game.GameDetailScreen
import com.statshark.nfl.ui.screens.player.PlayerDetailScreen
import com.statshark.nfl.ui.screens.predictions.PredictionsScreen
import com.statshark.nfl.ui.screens.standings.StandingsScreen
import com.statshark.nfl.ui.screens.teams.TeamDetailScreen
import com.statshark.nfl.ui.screens.teams.TeamsScreen
import com.statshark.nfl.ui.components.AdminFeedbackScreen

/**
 * Main App Composable
 * Sets up navigation and bottom bar
 */
@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun StatSharkApp() {
    val navController = rememberNavController()
    val navBackStackEntry by navController.currentBackStackEntryAsState()
    val currentDestination = navBackStackEntry?.destination

    Box {
        Scaffold(
            bottomBar = {
                // Only show bottom bar on main screens
                if (currentDestination?.route in bottomNavItems.map { it.route }) {
                    NavigationBar {
                        bottomNavItems.forEach { item ->
                            NavigationBarItem(
                                icon = {
                                    // TODO: Replace with proper Material Icons
                                    Icon(
                                        imageVector = Icons.Filled.Home,
                                        contentDescription = item.title
                                    )
                                },
                                label = { Text(item.title) },
                                selected = currentDestination?.hierarchy?.any { it.route == item.route } == true,
                                onClick = {
                                    navController.navigate(item.route) {
                                        // Pop up to the start destination to avoid building up a large stack
                                        popUpTo(navController.graph.findStartDestination().id) {
                                            saveState = true
                                        }
                                        // Avoid multiple copies of the same destination
                                        launchSingleTop = true
                                        // Restore state when reselecting a previously selected item
                                        restoreState = true
                                    }
                                }
                            )
                        }
                    }
                }
            }
        ) { innerPadding ->
            NavHost(
                navController = navController,
                startDestination = Screen.Teams.route,
                modifier = Modifier.padding(innerPadding)
            ) {
                composable(Screen.Teams.route) {
                    TeamsScreen(navController = navController)
                }

                composable(Screen.Standings.route) {
                    StandingsScreen(navController = navController)
                }

                composable(Screen.Predictions.route) {
                    PredictionsScreen(navController = navController)
                }

                composable(Screen.Fantasy.route) {
                    FantasyScreen()
                }

                composable(Screen.Admin.route) {
                    AdminFeedbackScreen(
                        onNavigateBack = { navController.navigateUp() }
                    )
                }

                // Detail screens
                composable(
                    route = Screen.TeamDetail.route,
                    arguments = listOf(navArgument("teamId") { type = NavType.StringType })
                ) { backStackEntry ->
                    val teamId = backStackEntry.arguments?.getString("teamId") ?: return@composable
                    TeamDetailScreen(
                        teamId = teamId,
                        navController = navController
                    )
                }

                composable(
                    route = Screen.PlayerDetail.route,
                    arguments = listOf(
                        navArgument("playerId") { type = NavType.StringType },
                        navArgument("teamId") { type = NavType.StringType }
                    )
                ) { backStackEntry ->
                    val playerId = backStackEntry.arguments?.getString("playerId") ?: return@composable
                    val teamId = backStackEntry.arguments?.getString("teamId") ?: return@composable

                    // Retrieve player from cache
                    val player = PlayerCache.get(playerId)
                    if (player != null) {
                        PlayerDetailScreen(
                            player = player,
                            teamAbbreviation = teamId,
                            navController = navController
                        )
                    } else {
                        // Player not in cache, navigate back
                        navController.navigateUp()
                    }
                }

                // Game Detail Screen
                composable(
                    route = Screen.GameDetail.route,
                    arguments = listOf(navArgument("gameId") { type = NavType.StringType })
                ) { backStackEntry ->
                    val gameId = backStackEntry.arguments?.getString("gameId") ?: return@composable

                    // Retrieve game from cache
                    val game = GameCache.get(gameId)
                    if (game != null) {
                        GameDetailScreen(
                            game = game,
                            navController = navController
                        )
                    } else {
                        // Game not in cache, navigate back
                        navController.navigateUp()
                    }
                }
            }
        }

        // Global error handling overlay (matches iOS .withErrorHandling())
        com.statshark.nfl.ui.components.ErrorHandlingOverlay()
    }
}
