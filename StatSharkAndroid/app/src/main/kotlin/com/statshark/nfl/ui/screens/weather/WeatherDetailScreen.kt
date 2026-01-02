package com.statshark.nfl.ui.screens.weather

import androidx.compose.foundation.layout.*
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.foundation.verticalScroll
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.*
import androidx.compose.material3.*
import androidx.compose.runtime.Composable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.vector.ImageVector
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.navigation.NavController
import com.statshark.nfl.data.model.GameWeatherDTO
import com.statshark.nfl.data.model.TeamWeatherStatsDTO
import com.statshark.nfl.data.model.ConditionStatsDTO
import com.statshark.nfl.ui.components.FeedbackButton
import kotlin.math.roundToInt

/**
 * Weather Detail Screen
 * Displays detailed weather forecast and team performance in weather conditions
 */
@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun WeatherDetailScreen(
    weather: GameWeatherDTO,
    homeTeamStats: TeamWeatherStatsDTO?,
    awayTeamStats: TeamWeatherStatsDTO?,
    navController: NavController
) {
    val scrollState = rememberScrollState()

    Scaffold(
        topBar = {
            TopAppBar(
                title = { Text("Weather Forecast") },
                navigationIcon = {
                    IconButton(onClick = { navController.navigateUp() }) {
                        Icon(Icons.Filled.ArrowBack, contentDescription = "Back")
                    }
                },
                actions = {
                    FeedbackButton(pageName = "Weather Detail")
                },
                colors = TopAppBarDefaults.topAppBarColors(
                    containerColor = MaterialTheme.colorScheme.primaryContainer,
                    titleContentColor = MaterialTheme.colorScheme.onPrimaryContainer
                )
            )
        }
    ) { paddingValues ->
        Column(
            modifier = Modifier
                .fillMaxSize()
                .padding(paddingValues)
                .verticalScroll(scrollState)
                .padding(16.dp),
            verticalArrangement = Arrangement.spacedBy(16.dp)
        ) {
            // Current Weather Forecast
            CurrentWeatherCard(weather)

            // Weather Impact Analysis
            WeatherImpactCard(weather)

            // Home Team Weather Performance
            if (homeTeamStats != null) {
                TeamWeatherPerformanceCard(
                    teamStats = homeTeamStats,
                    isHome = true
                )
            }

            // Away Team Weather Performance
            if (awayTeamStats != null) {
                TeamWeatherPerformanceCard(
                    teamStats = awayTeamStats,
                    isHome = false
                )
            }
        }
    }
}

/**
 * Current weather forecast card
 */
@Composable
private fun CurrentWeatherCard(weather: GameWeatherDTO) {
    Surface(
        modifier = Modifier.fillMaxWidth(),
        shape = RoundedCornerShape(12.dp),
        color = MaterialTheme.colorScheme.primaryContainer
    ) {
        Column(
            modifier = Modifier.padding(20.dp),
            horizontalAlignment = Alignment.CenterHorizontally,
            verticalArrangement = Arrangement.spacedBy(12.dp)
        ) {
            // Weather icon
            Icon(
                imageVector = getWeatherIcon(weather.condition),
                contentDescription = weather.condition,
                modifier = Modifier.size(64.dp),
                tint = MaterialTheme.colorScheme.onPrimaryContainer
            )

            // Temperature
            Text(
                text = "${weather.temperature.roundToInt()}°F",
                style = MaterialTheme.typography.displayLarge,
                fontWeight = FontWeight.Bold,
                color = MaterialTheme.colorScheme.onPrimaryContainer
            )

            // Condition
            Text(
                text = weather.condition,
                style = MaterialTheme.typography.titleLarge,
                color = MaterialTheme.colorScheme.onPrimaryContainer
            )

            Divider(
                modifier = Modifier.padding(vertical = 8.dp),
                color = MaterialTheme.colorScheme.onPrimaryContainer.copy(alpha = 0.2f)
            )

            // Weather details grid
            Row(
                modifier = Modifier.fillMaxWidth(),
                horizontalArrangement = Arrangement.SpaceEvenly
            ) {
                WeatherDetailItem(
                    icon = Icons.Filled.Air,
                    label = "Wind",
                    value = "${weather.windSpeed.roundToInt()} mph"
                )
                WeatherDetailItem(
                    icon = Icons.Filled.WaterDrop,
                    label = "Humidity",
                    value = "${weather.humidity.roundToInt()}%"
                )
                WeatherDetailItem(
                    icon = Icons.Filled.Cloud,
                    label = "Precip",
                    value = "${weather.precipitation.roundToInt()}%"
                )
            }
        }
    }
}

/**
 * Individual weather detail item
 */
@Composable
private fun WeatherDetailItem(
    icon: ImageVector,
    label: String,
    value: String
) {
    Column(
        horizontalAlignment = Alignment.CenterHorizontally,
        verticalArrangement = Arrangement.spacedBy(4.dp)
    ) {
        Icon(
            imageVector = icon,
            contentDescription = label,
            modifier = Modifier.size(24.dp),
            tint = MaterialTheme.colorScheme.onPrimaryContainer
        )
        Text(
            text = label,
            style = MaterialTheme.typography.labelSmall,
            color = MaterialTheme.colorScheme.onPrimaryContainer.copy(alpha = 0.7f)
        )
        Text(
            text = value,
            style = MaterialTheme.typography.bodyMedium,
            fontWeight = FontWeight.SemiBold,
            color = MaterialTheme.colorScheme.onPrimaryContainer
        )
    }
}

/**
 * Weather impact analysis card
 */
@Composable
private fun WeatherImpactCard(weather: GameWeatherDTO) {
    Surface(
        modifier = Modifier.fillMaxWidth(),
        shape = RoundedCornerShape(12.dp),
        color = MaterialTheme.colorScheme.surfaceVariant
    ) {
        Column(
            modifier = Modifier.padding(16.dp),
            verticalArrangement = Arrangement.spacedBy(12.dp)
        ) {
            Text(
                text = "Weather Impact",
                style = MaterialTheme.typography.titleMedium,
                fontWeight = FontWeight.Bold,
                color = MaterialTheme.colorScheme.onSurfaceVariant
            )

            // Analyze weather impact
            val impacts = analyzeWeatherImpact(weather)
            impacts.forEach { impact ->
                WeatherImpactItem(impact)
            }
        }
    }
}

/**
 * Individual weather impact item
 */
@Composable
private fun WeatherImpactItem(impact: WeatherImpact) {
    Row(
        modifier = Modifier.fillMaxWidth(),
        horizontalArrangement = Arrangement.spacedBy(12.dp),
        verticalAlignment = Alignment.Top
    ) {
        Icon(
            imageVector = impact.icon,
            contentDescription = null,
            modifier = Modifier.size(20.dp),
            tint = impact.color
        )
        Column(
            modifier = Modifier.weight(1f),
            verticalArrangement = Arrangement.spacedBy(4.dp)
        ) {
            Text(
                text = impact.title,
                style = MaterialTheme.typography.bodyMedium,
                fontWeight = FontWeight.SemiBold,
                color = MaterialTheme.colorScheme.onSurfaceVariant
            )
            Text(
                text = impact.description,
                style = MaterialTheme.typography.bodySmall,
                color = MaterialTheme.colorScheme.onSurfaceVariant.copy(alpha = 0.7f)
            )
        }
    }
}

/**
 * Team weather performance card
 */
@Composable
private fun TeamWeatherPerformanceCard(
    teamStats: TeamWeatherStatsDTO,
    isHome: Boolean
) {
    val stats = if (isHome) teamStats.homeStats else teamStats.awayStats
    val location = if (isHome) "Home" else "Away"

    Surface(
        modifier = Modifier.fillMaxWidth(),
        shape = RoundedCornerShape(12.dp),
        color = MaterialTheme.colorScheme.surface
    ) {
        Column(
            modifier = Modifier.padding(16.dp),
            verticalArrangement = Arrangement.spacedBy(12.dp)
        ) {
            Text(
                text = "${teamStats.teamAbbreviation} Weather Performance ($location)",
                style = MaterialTheme.typography.titleMedium,
                fontWeight = FontWeight.Bold,
                color = MaterialTheme.colorScheme.onSurface
            )

            // Condition stats
            ConditionStatsItem("Clear", stats.clear)
            ConditionStatsItem("Rain", stats.rain)
            ConditionStatsItem("Snow", stats.snow)
            ConditionStatsItem("Wind", stats.wind)
            ConditionStatsItem("Cold", stats.cold)
            ConditionStatsItem("Hot", stats.hot)
        }
    }
}

/**
 * Individual condition stats item
 */
@Composable
private fun ConditionStatsItem(
    condition: String,
    stats: ConditionStatsDTO
) {
    if (stats.games == 0) return

    Surface(
        modifier = Modifier.fillMaxWidth(),
        shape = RoundedCornerShape(8.dp),
        color = MaterialTheme.colorScheme.surfaceVariant.copy(alpha = 0.5f)
    ) {
        Column(
            modifier = Modifier.padding(12.dp),
            verticalArrangement = Arrangement.spacedBy(8.dp)
        ) {
            Row(
                modifier = Modifier.fillMaxWidth(),
                horizontalArrangement = Arrangement.SpaceBetween,
                verticalAlignment = Alignment.CenterVertically
            ) {
                Text(
                    text = condition,
                    style = MaterialTheme.typography.bodyMedium,
                    fontWeight = FontWeight.SemiBold,
                    color = MaterialTheme.colorScheme.onSurface
                )
                Text(
                    text = "${stats.wins}-${stats.losses} (${stats.winPercentage.roundToInt()}%)",
                    style = MaterialTheme.typography.bodyMedium,
                    fontWeight = FontWeight.Bold,
                    color = if (stats.winPercentage >= 50) {
                        MaterialTheme.colorScheme.primary
                    } else {
                        MaterialTheme.colorScheme.error
                    }
                )
            }

            Row(
                modifier = Modifier.fillMaxWidth(),
                horizontalArrangement = Arrangement.SpaceBetween
            ) {
                Text(
                    text = "Games: ${stats.games}",
                    style = MaterialTheme.typography.bodySmall,
                    color = MaterialTheme.colorScheme.onSurface.copy(alpha = 0.7f)
                )
                Text(
                    text = "Avg Scored: ${stats.avgPointsScored.roundToInt()}",
                    style = MaterialTheme.typography.bodySmall,
                    color = MaterialTheme.colorScheme.onSurface.copy(alpha = 0.7f)
                )
                Text(
                    text = "Avg Allowed: ${stats.avgPointsAllowed.roundToInt()}",
                    style = MaterialTheme.typography.bodySmall,
                    color = MaterialTheme.colorScheme.onSurface.copy(alpha = 0.7f)
                )
            }
        }
    }
}

/**
 * Get weather icon based on condition
 */
private fun getWeatherIcon(condition: String): ImageVector {
    return when (condition.lowercase()) {
        "clear", "sunny" -> Icons.Filled.WbSunny
        "partly cloudy", "cloudy", "overcast" -> Icons.Filled.Cloud
        "rain", "light rain", "heavy rain", "showers" -> Icons.Filled.WaterDrop
        "snow", "light snow", "heavy snow" -> Icons.Filled.AcUnit
        "wind", "windy" -> Icons.Filled.Air
        "fog", "mist" -> Icons.Filled.Cloud
        else -> Icons.Filled.Cloud
    }
}

/**
 * Weather impact data class
 */
private data class WeatherImpact(
    val icon: ImageVector,
    val color: androidx.compose.ui.graphics.Color,
    val title: String,
    val description: String
)

/**
 * Analyze weather impact on game
 */
@Composable
private fun analyzeWeatherImpact(weather: GameWeatherDTO): List<WeatherImpact> {
    val impacts = mutableListOf<WeatherImpact>()

    // Temperature impact
    if (weather.temperature < 32) {
        impacts.add(
            WeatherImpact(
                icon = Icons.Filled.AcUnit,
                color = MaterialTheme.colorScheme.primary,
                title = "Freezing Conditions",
                description = "Below-freezing temperatures can affect ball handling and favor running game"
            )
        )
    } else if (weather.temperature > 85) {
        impacts.add(
            WeatherImpact(
                icon = Icons.Filled.WbSunny,
                color = MaterialTheme.colorScheme.tertiary,
                title = "Hot Weather",
                description = "High temperatures may lead to fatigue and increased injury risk"
            )
        )
    }

    // Wind impact
    if (weather.windSpeed > 15) {
        impacts.add(
            WeatherImpact(
                icon = Icons.Filled.Air,
                color = MaterialTheme.colorScheme.secondary,
                title = "High Winds",
                description = "Strong winds can affect passing game and kicking accuracy"
            )
        )
    }

    // Precipitation impact
    if (weather.precipitation > 50) {
        impacts.add(
            WeatherImpact(
                icon = Icons.Filled.WaterDrop,
                color = MaterialTheme.colorScheme.error,
                title = "Rain Expected",
                description = "Wet conditions favor running game and increase fumble risk"
            )
        )
    }

    // Default message if no significant impact
    if (impacts.isEmpty()) {
        impacts.add(
            WeatherImpact(
                icon = Icons.Filled.Check,
                color = MaterialTheme.colorScheme.primary,
                title = "Favorable Conditions",
                description = "Weather conditions should not significantly impact gameplay"
            )
        )
    }

    return impacts
}
