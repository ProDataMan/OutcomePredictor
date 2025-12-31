package com.statshark.nfl.ui.navigation

/**
 * Navigation routes for the app
 */
sealed class Screen(val route: String) {
    object Teams : Screen("teams")
    object Standings : Screen("standings")
    object Predictions : Screen("predictions?homeTeam={homeTeam}&awayTeam={awayTeam}") {
        fun createRoute(homeTeam: String? = null, awayTeam: String? = null): String {
            return if (homeTeam != null && awayTeam != null) {
                "predictions?homeTeam=$homeTeam&awayTeam=$awayTeam"
            } else {
                "predictions"
            }
        }
    }
    object Fantasy : Screen("fantasy")
    object Admin : Screen("admin")
    object TeamDetail : Screen("team/{teamId}") {
        fun createRoute(teamId: String) = "team/$teamId"
    }
    object GameDetail : Screen("game/{gameId}") {
        fun createRoute(gameId: String) = "game/$gameId"
    }
    object PlayerDetail : Screen("player/{playerId}/{teamId}") {
        fun createRoute(playerId: String, teamId: String) = "player/$playerId/$teamId"
    }
    object PredictionDetail : Screen("prediction-detail/{gameId}") {
        fun createRoute(gameId: String) = "prediction-detail/$gameId"
    }
    object ArticleDetail : Screen("article-detail/{articleId}") {
        fun createRoute(articleId: String) = "article-detail/$articleId"
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

    object Standings : BottomNavItem(
        route = Screen.Standings.route,
        title = "Standings",
        icon = android.R.drawable.ic_menu_sort_by_size  // TODO: Replace with proper icon
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

    object Admin : BottomNavItem(
        route = Screen.Admin.route,
        title = "Admin",
        icon = android.R.drawable.ic_lock_lock  // Shield/Admin icon
    )
}

val bottomNavItems = listOf(
    BottomNavItem.Teams,
    BottomNavItem.Standings,
    BottomNavItem.Predictions,
    BottomNavItem.Fantasy,
    BottomNavItem.Admin
)
