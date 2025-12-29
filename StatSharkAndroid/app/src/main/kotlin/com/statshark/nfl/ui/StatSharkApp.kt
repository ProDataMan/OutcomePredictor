package com.statshark.nfl.ui

import androidx.compose.foundation.layout.padding
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
import com.statshark.nfl.ui.navigation.Screen
import com.statshark.nfl.ui.navigation.bottomNavItems
import com.statshark.nfl.ui.screens.fantasy.FantasyScreen
import com.statshark.nfl.ui.screens.predictions.PredictionsScreen
import com.statshark.nfl.ui.screens.teams.TeamDetailScreen
import com.statshark.nfl.ui.screens.teams.TeamsScreen

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
                                    imageVector = androidx.compose.material.icons.Icons.Default.Home,
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

            composable(Screen.Predictions.route) {
                PredictionsScreen(navController = navController)
            }

            composable(Screen.Fantasy.route) {
                FantasyScreen(navController = navController)
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

            // TODO: Add other detail screens
            // composable(Screen.GameDetail.route) { ... }
            // composable(Screen.PlayerDetail.route) { ... }
        }
    }
}
