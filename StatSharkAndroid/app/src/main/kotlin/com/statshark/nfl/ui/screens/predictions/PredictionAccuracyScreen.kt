package com.statshark.nfl.ui.screens.predictions

import androidx.compose.animation.core.animateFloatAsState
import androidx.compose.animation.core.tween
import androidx.compose.foundation.Canvas
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.foundation.verticalScroll
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.ArrowBack
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.geometry.Offset
import androidx.compose.ui.geometry.Size
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.StrokeCap
import androidx.compose.ui.graphics.drawscope.Stroke
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.dp
import androidx.navigation.NavController
import com.statshark.nfl.data.model.*
import com.statshark.nfl.ui.components.FeedbackButton
import java.text.SimpleDateFormat
import java.util.*

/**
 * Prediction Accuracy Screen
 * Shows historical prediction accuracy with trends and breakdowns
 */
@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun PredictionAccuracyScreen(
    accuracy: PredictionAccuracyDTO,
    navController: NavController
) {
    Scaffold(
        topBar = {
            TopAppBar(
                title = { Text("Prediction Accuracy") },
                navigationIcon = {
                    IconButton(onClick = { navController.navigateUp() }) {
                        Icon(Icons.Filled.ArrowBack, "Back")
                    }
                },
                actions = {
                    FeedbackButton(pageName = "Prediction Accuracy")
                }
            )
        }
    ) { padding ->
        Column(
            modifier = Modifier
                .fillMaxSize()
                .padding(padding)
                .verticalScroll(rememberScrollState())
        ) {
            // Overall Accuracy
            OverallAccuracySection(accuracy)

            Spacer(Modifier.height(24.dp))

            // Weekly Trend
            WeeklyTrendSection(accuracy.weeklyAccuracy)

            Spacer(Modifier.height(24.dp))

            // Confidence Breakdown
            ConfidenceBreakdownSection(accuracy.confidenceBreakdown)

            Spacer(Modifier.height(24.dp))

            // Model Info
            ModelInfoSection(accuracy.modelVersion, accuracy.lastUpdated)

            Spacer(Modifier.height(16.dp))
        }
    }
}

@Composable
fun OverallAccuracySection(accuracy: PredictionAccuracyDTO) {
    Column(
        modifier = Modifier
            .fillMaxWidth()
            .padding(16.dp),
        horizontalAlignment = Alignment.CenterHorizontally
    ) {
        Text(
            "Overall Accuracy",
            style = MaterialTheme.typography.titleLarge,
            fontWeight = FontWeight.Bold
        )

        Spacer(Modifier.height(16.dp))

        Box(
            contentAlignment = Alignment.Center,
            modifier = Modifier.size(200.dp)
        ) {
            CircularAccuracyIndicator(
                accuracy = accuracy.overallAccuracy,
                size = 200.dp
            )

            Column(horizontalAlignment = Alignment.CenterHorizontally) {
                Text(
                    "${accuracy.overallAccuracy.toInt()}%",
                    style = MaterialTheme.typography.displayMedium,
                    fontWeight = FontWeight.Bold,
                    color = getAccuracyColor(accuracy.overallAccuracy)
                )

                Text(
                    "${accuracy.correctPredictions} / ${accuracy.totalPredictions}",
                    style = MaterialTheme.typography.labelMedium,
                    color = MaterialTheme.colorScheme.onSurfaceVariant
                )
            }
        }
    }
}

@Composable
fun CircularAccuracyIndicator(accuracy: Double, size: androidx.compose.ui.unit.Dp) {
    var animationPlayed by remember { mutableStateOf(false) }
    val currentPercentage = animateFloatAsState(
        targetValue = if (animationPlayed) accuracy.toFloat() / 100f else 0f,
        animationSpec = tween(durationMillis = 1000),
        label = "accuracy_animation"
    )

    LaunchedEffect(key1 = true) {
        animationPlayed = true
    }

    Canvas(modifier = Modifier.size(size)) {
        val strokeWidth = 20.dp.toPx()

        // Background circle
        drawArc(
            color = Color.Gray.copy(alpha = 0.2f),
            startAngle = -90f,
            sweepAngle = 360f,
            useCenter = false,
            style = Stroke(width = strokeWidth, cap = StrokeCap.Round),
            size = Size(this.size.width, this.size.height)
        )

        // Progress arc
        drawArc(
            color = getAccuracyColor(accuracy),
            startAngle = -90f,
            sweepAngle = 360f * currentPercentage.value,
            useCenter = false,
            style = Stroke(width = strokeWidth, cap = StrokeCap.Round),
            size = Size(this.size.width, this.size.height)
        )
    }
}

@Composable
fun WeeklyTrendSection(weeklyAccuracy: List<WeeklyAccuracyDTO>) {
    Column(
        modifier = Modifier
            .fillMaxWidth()
            .padding(horizontal = 16.dp)
    ) {
        Text(
            "Weekly Trend",
            style = MaterialTheme.typography.titleMedium,
            fontWeight = FontWeight.Bold
        )

        Spacer(Modifier.height(12.dp))

        // Simple line chart
        WeeklyTrendChart(weeklyAccuracy)

        Spacer(Modifier.height(12.dp))

        // Week list
        Column(verticalArrangement = Arrangement.spacedBy(8.dp)) {
            weeklyAccuracy.forEach { week ->
                WeeklyAccuracyCard(week)
            }
        }
    }
}

@Composable
fun WeeklyTrendChart(weeklyAccuracy: List<WeeklyAccuracyDTO>) {
    if (weeklyAccuracy.isEmpty()) return

    val maxAccuracy = 100.0
    val minAccuracy = 0.0

    Canvas(
        modifier = Modifier
            .fillMaxWidth()
            .height(150.dp)
            .padding(vertical = 16.dp)
    ) {
        val width = size.width
        val height = size.height
        val spacing = width / (weeklyAccuracy.size - 1).coerceAtLeast(1)

        // Draw line
        for (i in 0 until weeklyAccuracy.size - 1) {
            val startX = i * spacing
            val startY = height - ((weeklyAccuracy[i].accuracy - minAccuracy) / (maxAccuracy - minAccuracy) * height).toFloat()

            val endX = (i + 1) * spacing
            val endY = height - ((weeklyAccuracy[i + 1].accuracy - minAccuracy) / (maxAccuracy - minAccuracy) * height).toFloat()

            drawLine(
                color = Color(0xFF2196F3),
                start = Offset(startX, startY),
                end = Offset(endX, endY),
                strokeWidth = 4.dp.toPx()
            )
        }

        // Draw points
        weeklyAccuracy.forEachIndexed { index, week ->
            val x = index * spacing
            val y = height - ((week.accuracy - minAccuracy) / (maxAccuracy - minAccuracy) * height).toFloat()

            drawCircle(
                color = Color(0xFF2196F3),
                radius = 6.dp.toPx(),
                center = Offset(x, y)
            )
        }
    }
}

@Composable
fun WeeklyAccuracyCard(week: WeeklyAccuracyDTO) {
    Card(
        colors = CardDefaults.cardColors(
            containerColor = MaterialTheme.colorScheme.surfaceVariant
        )
    ) {
        Row(
            modifier = Modifier
                .fillMaxWidth()
                .padding(16.dp),
            horizontalArrangement = Arrangement.SpaceBetween,
            verticalAlignment = Alignment.CenterVertically
        ) {
            Text(
                "Week ${week.week}",
                style = MaterialTheme.typography.bodyMedium
            )

            Row(
                horizontalArrangement = Arrangement.spacedBy(8.dp),
                verticalAlignment = Alignment.CenterVertically
            ) {
                Text(
                    "${week.accuracy.toInt()}%",
                    style = MaterialTheme.typography.bodyMedium,
                    fontWeight = FontWeight.SemiBold
                )

                Text(
                    "(${week.correctPredictions}/${week.totalGames})",
                    style = MaterialTheme.typography.labelSmall,
                    color = MaterialTheme.colorScheme.onSurfaceVariant
                )
            }
        }
    }
}

@Composable
fun ConfidenceBreakdownSection(confidenceBreakdown: List<ConfidenceAccuracyDTO>) {
    Column(
        modifier = Modifier
            .fillMaxWidth()
            .padding(horizontal = 16.dp)
    ) {
        Text(
            "Accuracy by Confidence",
            style = MaterialTheme.typography.titleMedium,
            fontWeight = FontWeight.Bold
        )

        Spacer(Modifier.height(12.dp))

        Column(verticalArrangement = Arrangement.spacedBy(12.dp)) {
            confidenceBreakdown.forEach { breakdown ->
                ConfidenceBreakdownCard(breakdown)
            }
        }
    }
}

@Composable
fun ConfidenceBreakdownCard(breakdown: ConfidenceAccuracyDTO) {
    Card(
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
                modifier = Modifier.fillMaxWidth(),
                horizontalArrangement = Arrangement.SpaceBetween
            ) {
                Text(
                    breakdown.confidenceRange,
                    style = MaterialTheme.typography.bodyMedium,
                    fontWeight = FontWeight.SemiBold
                )

                Row(horizontalArrangement = Arrangement.spacedBy(4.dp)) {
                    Text(
                        "${breakdown.accuracy.toInt()}%",
                        style = MaterialTheme.typography.bodyMedium,
                        fontWeight = FontWeight.Bold,
                        color = getAccuracyColor(breakdown.accuracy)
                    )

                    Text(
                        "(${breakdown.correctPredictions}/${breakdown.totalPredictions})",
                        style = MaterialTheme.typography.labelSmall,
                        color = MaterialTheme.colorScheme.onSurfaceVariant
                    )
                }
            }

            Spacer(Modifier.height(8.dp))

            LinearProgressIndicator(
                progress = { (breakdown.accuracy / 100).toFloat() },
                modifier = Modifier
                    .fillMaxWidth()
                    .height(8.dp),
                color = getAccuracyColor(breakdown.accuracy),
                trackColor = MaterialTheme.colorScheme.surfaceVariant
            )
        }
    }
}

@Composable
fun ModelInfoSection(modelVersion: String, lastUpdated: String) {
    Column(
        modifier = Modifier
            .fillMaxWidth()
            .padding(horizontal = 16.dp),
        horizontalAlignment = Alignment.CenterHorizontally
    ) {
        Text(
            "Model Version: $modelVersion",
            style = MaterialTheme.typography.labelMedium,
            color = MaterialTheme.colorScheme.onSurfaceVariant
        )

        Text(
            "Last Updated: ${formatDateTime(lastUpdated)}",
            style = MaterialTheme.typography.labelSmall,
            color = MaterialTheme.colorScheme.onSurfaceVariant
        )
    }
}

fun getAccuracyColor(accuracy: Double): Color {
    return when {
        accuracy >= 70 -> Color(0xFF4CAF50) // Green
        accuracy >= 50 -> Color(0xFF2196F3) // Blue
        accuracy >= 30 -> Color(0xFFFF9800) // Orange
        else -> Color(0xFFF44336) // Red
    }
}

fun formatDateTime(dateTimeString: String): String {
    return try {
        val parser = SimpleDateFormat("yyyy-MM-dd'T'HH:mm:ss", Locale.getDefault())
        val formatter = SimpleDateFormat("MMM dd, yyyy h:mm a", Locale.getDefault())
        val date = parser.parse(dateTimeString)
        date?.let { formatter.format(it) } ?: dateTimeString
    } catch (e: Exception) {
        dateTimeString
    }
}
