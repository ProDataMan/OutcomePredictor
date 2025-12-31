package com.statshark.nfl.ui.components

import androidx.compose.animation.core.*
import androidx.compose.foundation.background
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material3.*
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.composed
import androidx.compose.ui.draw.clip
import androidx.compose.ui.geometry.Offset
import androidx.compose.ui.graphics.Brush
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.unit.dp

/**
 * Shimmer effect modifier for skeleton loading states
 */
fun Modifier.shimmer(): Modifier = composed {
    val transition = rememberInfiniteTransition(label = "shimmer")
    val translateAnimation by transition.animateFloat(
        initialValue = 0f,
        targetValue = 1000f,
        animationSpec = infiniteRepeatable(
            animation = tween(durationMillis = 1500, easing = LinearEasing),
            repeatMode = RepeatMode.Restart
        ),
        label = "shimmer_translate"
    )

    val shimmerColors = listOf(
        Color.LightGray.copy(alpha = 0.3f),
        Color.LightGray.copy(alpha = 0.5f),
        Color.LightGray.copy(alpha = 0.3f)
    )

    background(
        brush = Brush.linearGradient(
            colors = shimmerColors,
            start = Offset(x = translateAnimation - 1000f, y = translateAnimation - 1000f),
            end = Offset(x = translateAnimation, y = translateAnimation)
        )
    )
}

/**
 * Skeleton Box - Basic skeleton shape
 */
@Composable
fun SkeletonBox(
    modifier: Modifier = Modifier,
    shape: androidx.compose.ui.graphics.Shape = RoundedCornerShape(8.dp)
) {
    Box(
        modifier = modifier
            .clip(shape)
            .background(Color.LightGray.copy(alpha = 0.3f))
            .shimmer()
    )
}

/**
 * Skeleton Circle
 */
@Composable
fun SkeletonCircle(
    size: androidx.compose.ui.unit.Dp,
    modifier: Modifier = Modifier
) {
    Box(
        modifier = modifier
            .size(size)
            .clip(CircleShape)
            .background(Color.LightGray.copy(alpha = 0.3f))
            .shimmer()
    )
}

/**
 * Skeleton Game Card
 */
@Composable
fun SkeletonGameCard() {
    Card(
        modifier = Modifier.fillMaxWidth(),
        elevation = CardDefaults.cardElevation(defaultElevation = 4.dp)
    ) {
        Column(
            modifier = Modifier
                .fillMaxWidth()
                .padding(16.dp),
            verticalArrangement = Arrangement.spacedBy(12.dp)
        ) {
            // Header
            Row(
                modifier = Modifier.fillMaxWidth(),
                horizontalArrangement = Arrangement.SpaceBetween
            ) {
                Column(verticalArrangement = Arrangement.spacedBy(4.dp)) {
                    SkeletonBox(
                        modifier = Modifier
                            .width(60.dp)
                            .height(16.dp)
                    )
                    SkeletonBox(
                        modifier = Modifier
                            .width(80.dp)
                            .height(12.dp)
                    )
                }
                SkeletonBox(
                    modifier = Modifier
                        .width(100.dp)
                        .height(12.dp)
                )
            }

            Spacer(modifier = Modifier.height(4.dp))

            // Teams
            Row(
                modifier = Modifier.fillMaxWidth(),
                horizontalArrangement = Arrangement.SpaceEvenly
            ) {
                // Away Team
                Column(
                    modifier = Modifier.weight(1f),
                    horizontalAlignment = Alignment.CenterHorizontally,
                    verticalArrangement = Arrangement.spacedBy(8.dp)
                ) {
                    SkeletonCircle(size = 80.dp)
                    SkeletonBox(
                        modifier = Modifier
                            .width(100.dp)
                            .height(14.dp)
                    )
                }

                // VS
                Box(
                    modifier = Modifier
                        .size(48.dp)
                        .clip(CircleShape)
                        .background(MaterialTheme.colorScheme.surfaceVariant)
                )

                // Home Team
                Column(
                    modifier = Modifier.weight(1f),
                    horizontalAlignment = Alignment.CenterHorizontally,
                    verticalArrangement = Arrangement.spacedBy(8.dp)
                ) {
                    SkeletonCircle(size = 80.dp)
                    SkeletonBox(
                        modifier = Modifier
                            .width(100.dp)
                            .height(14.dp)
                    )
                }
            }

            Spacer(modifier = Modifier.height(4.dp))

            // Button placeholder
            SkeletonBox(
                modifier = Modifier
                    .fillMaxWidth()
                    .height(48.dp)
            )
        }
    }
}

/**
 * Skeleton Prediction Result
 */
@Composable
fun SkeletonPredictionResult() {
    Column(
        modifier = Modifier
            .fillMaxWidth()
            .clip(RoundedCornerShape(12.dp))
            .background(MaterialTheme.colorScheme.tertiaryContainer)
            .padding(16.dp),
        verticalArrangement = Arrangement.spacedBy(12.dp)
    ) {
        // Winner section
        SkeletonBox(
            modifier = Modifier
                .width(120.dp)
                .height(16.dp)
        )

        SkeletonBox(
            modifier = Modifier
                .width(180.dp)
                .height(24.dp)
        )

        Spacer(modifier = Modifier.height(8.dp))

        // Probability bar
        SkeletonBox(
            modifier = Modifier
                .fillMaxWidth()
                .height(24.dp)
        )

        Spacer(modifier = Modifier.height(8.dp))

        // Confidence
        SkeletonBox(
            modifier = Modifier
                .fillMaxWidth()
                .height(8.dp)
        )

        Spacer(modifier = Modifier.height(8.dp))

        // Analysis header
        SkeletonBox(
            modifier = Modifier
                .width(80.dp)
                .height(14.dp)
        )

        // Analysis text
        Column(verticalArrangement = Arrangement.spacedBy(4.dp)) {
            SkeletonBox(
                modifier = Modifier
                    .fillMaxWidth()
                    .height(12.dp)
            )
            SkeletonBox(
                modifier = Modifier
                    .fillMaxWidth()
                    .height(12.dp)
            )
            SkeletonBox(
                modifier = Modifier
                    .width(200.dp)
                    .height(12.dp)
            )
        }
    }
}

/**
 * Skeleton Team Row (for standings/teams list)
 */
@Composable
fun SkeletonTeamRow() {
    Row(
        modifier = Modifier
            .fillMaxWidth()
            .padding(vertical = 8.dp, horizontal = 16.dp),
        horizontalArrangement = Arrangement.spacedBy(12.dp),
        verticalAlignment = Alignment.CenterVertically
    ) {
        SkeletonCircle(size = 40.dp)

        Column(
            modifier = Modifier.weight(1f),
            verticalArrangement = Arrangement.spacedBy(4.dp)
        ) {
            SkeletonBox(
                modifier = Modifier
                    .width(120.dp)
                    .height(14.dp)
            )
            SkeletonBox(
                modifier = Modifier
                    .width(80.dp)
                    .height(10.dp)
            )
        }

        SkeletonBox(
            modifier = Modifier
                .width(40.dp)
                .height(14.dp)
        )
    }
}

/**
 * Skeleton List - Shows multiple skeleton items
 */
@Composable
fun SkeletonList(
    count: Int = 5,
    itemContent: @Composable () -> Unit
) {
    Column(verticalArrangement = Arrangement.spacedBy(12.dp)) {
        repeat(count) {
            itemContent()
        }
    }
}
