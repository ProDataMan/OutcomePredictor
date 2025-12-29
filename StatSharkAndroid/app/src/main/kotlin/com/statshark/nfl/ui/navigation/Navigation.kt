package com.statshark.nfl.ui.navigation

/**
 * Navigation routes for the app
 */
sealed class Screen(val route: String) {
    object Teams : Screen("teams")
    object Predictions : Screen("predictions")
    object Fantasy : Screen("fantasy")
    object TeamDetail : Screen("team/{teamId}") {
        fun createRoute(teamId: String) = "team/$teamId"
    }
    object GameDetail : Screen("game/{gameId}") {
        fun createRoute(gameId: String) = "game/$gameId"
    }
    object PlayerDetail : Screen("player/{playerId}") {
        fun createRoute(playerId: String) = "player/$playerId"
    }
}

/**
 * Bottom navigation destinations
 */
sealed class BottomNavItem(
    val route: String,
    val title: String,
    val icon: Int
) {
    object Teams : BottomNavItem(
        route = Screen.Teams.route,
        title = "Teams",
        icon = android.R.drawable.ic_menu_view  // TODO: Replace with proper icon
    )

    object Predictions : BottomNavItem(
        route = Screen.Predictions.route,
        title = "Predict",
        icon = android.R.drawable.ic_menu_compass  // TODO: Replace with proper icon
    )

    object Fantasy : BottomNavItem(
        route = Screen.Fantasy.route,
        title = "Fantasy",
        icon = android.R.drawable.ic_menu_myplaces  // TODO: Replace with proper icon
    )
}

val bottomNavItems = listOf(
    BottomNavItem.Teams,
    BottomNavItem.Predictions,
    BottomNavItem.Fantasy
)
