package com.statshark.nfl.ui.components

import androidx.compose.animation.*
import androidx.compose.animation.core.*
import androidx.compose.foundation.Canvas
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.foundation.verticalScroll
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.Close
import androidx.compose.material.icons.filled.Info
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.shadow
import androidx.compose.ui.geometry.Offset
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.Path
import androidx.compose.ui.graphics.drawscope.Stroke
import androidx.compose.ui.platform.LocalClipboardManager
import androidx.compose.ui.text.AnnotatedString
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.dp
import androidx.compose.ui.window.Dialog
import androidx.compose.ui.window.DialogProperties
import kotlinx.coroutines.delay
import java.text.SimpleDateFormat
import java.util.Date
import java.util.Locale

/**
 * App Error data class
 * Wrapped error with context for display
 */
data class AppError(
    val error: Throwable,
    val context: String = "",
    val timestamp: Date = Date()
) {
    val localizedDescription: String
        get() = error.message ?: "Unknown error occurred"

    val fullDescription: String
        get() {
            val dateFormat = SimpleDateFormat("MMMM dd, yyyy 'at' hh:mm:ss a", Locale.US)
            return """
                Error: $localizedDescription
                Context: ${context.ifEmpty { "None" }}
                Time: ${dateFormat.format(timestamp)}
                Type: ${error::class.simpleName}
            """.trimIndent()
        }

    val stackTrace: String
        get() = """
            $fullDescription

            Technical Details:
            ${error.stackTraceToString()}
        """.trimIndent()
}

/**
 * Shark with Nose Ring Component
 * Matching iOS SharkWithNoseRing
 */
@Composable
fun SharkWithNoseRing(
    size: Float = 80f,
    modifier: Modifier = Modifier
) {
    val infiniteTransition = rememberInfiniteTransition(label = "shark_animation")
    val rotation by infiniteTransition.animateFloat(
        initialValue = -5f,
        targetValue = 5f,
        animationSpec = infiniteRepeatable(
            animation = tween(2000, easing = LinearEasing),
            repeatMode = RepeatMode.Reverse
        ),
        label = "rotation"
    )

    Canvas(
        modifier = modifier.size(size.dp)
    ) {
        val centerX = size / 2
        val centerY = size / 2

        // Draw shark body (simple shark silhouette)
        val sharkPath = Path().apply {
            // Body
            moveTo(centerX * 0.3f, centerY)
            cubicTo(
                centerX * 0.3f, centerY * 0.5f,
                centerX * 0.7f, centerY * 0.5f,
                centerX * 1.5f, centerY
            )
            cubicTo(
                centerX * 0.7f, centerY * 1.5f,
                centerX * 0.3f, centerY * 1.5f,
                centerX * 0.3f, centerY
            )
            // Tail fin
            moveTo(centerX * 0.2f, centerY)
            lineTo(centerX * 0.1f, centerY * 0.5f)
            lineTo(centerX * 0.3f, centerY)
            // Dorsal fin
            moveTo(centerX * 0.8f, centerY * 0.6f)
            lineTo(centerX, centerY * 0.2f)
            lineTo(centerX * 1.2f, centerY * 0.6f)
        }

        // Draw shark
        drawPath(
            path = sharkPath,
            color = Color(0xFF607D8B), // Blue-gray shark color
            style = Stroke(width = 3f)
        )

        // Draw nose ring
        val noseX = centerX * 1.5f
        val noseY = centerY * 1.1f
        drawCircle(
            color = Color(0xFFFFD700), // Gold color for ring
            radius = 4f,
            center = Offset(noseX, noseY),
            style = Stroke(width = 2f)
        )
    }
}

/**
 * Error Overlay
 * Shows "Awe Snap this is Bull Shark" error message with animation
 * Matching iOS ErrorOverlay
 */
@Composable
fun ErrorOverlay(
    error: AppError,
    onDismiss: () -> Unit
) {
    var showDetails by remember { mutableStateOf(false) }

    Dialog(
        onDismissRequest = onDismiss,
        properties = DialogProperties(
            dismissOnBackPress = true,
            dismissOnClickOutside = true
        )
    ) {
        Box(
            modifier = Modifier.fillMaxSize(),
            contentAlignment = Alignment.Center
        ) {
            if (showDetails) {
                ErrorDetailsView(
                    error = error,
                    onClose = { showDetails = false }
                )
            } else {
                ErrorMessageView(
                    error = error,
                    onClose = onDismiss,
                    onShowDetails = { showDetails = true }
                )
            }
        }
    }
}

/**
 * Simple error message with Close and Show Details buttons
 * Matching iOS ErrorMessageView
 */
@Composable
private fun ErrorMessageView(
    error: AppError,
    onClose: () -> Unit,
    onShowDetails: () -> Unit
) {
    var showFirstMessage by remember { mutableStateOf(false) }
    var showShark by remember { mutableStateOf(false) }
    var showSecondMessage by remember { mutableStateOf(false) }

    LaunchedEffect(Unit) {
        // Show first message immediately
        showFirstMessage = true
        delay(1200)

        // Hide first message and show shark
        showFirstMessage = false
        delay(300)
        showShark = true
        delay(800)

        // Show second message
        showSecondMessage = true
    }

    Card(
        modifier = Modifier
            .fillMaxWidth(0.9f)
            .padding(40.dp)
            .shadow(20.dp, RoundedCornerShape(20.dp)),
        shape = RoundedCornerShape(20.dp),
        colors = CardDefaults.cardColors(
            containerColor = MaterialTheme.colorScheme.surface
        )
    ) {
        Column(
            modifier = Modifier
                .padding(32.dp)
                .fillMaxWidth(),
            horizontalAlignment = Alignment.CenterHorizontally,
            verticalArrangement = Arrangement.spacedBy(24.dp)
        ) {
            // Animated messages and shark
            Box(
                modifier = Modifier.height(200.dp),
                contentAlignment = Alignment.Center
            ) {
                Column(
                    horizontalAlignment = Alignment.CenterHorizontally,
                    verticalArrangement = Arrangement.spacedBy(12.dp)
                ) {
                    // First message: "Awe Snap, Something bad happened!"
                    AnimatedVisibility(
                        visible = showFirstMessage,
                        enter = scaleIn() + fadeIn(),
                        exit = slideOutHorizontally() + fadeOut()
                    ) {
                        Text(
                            text = "Awe Snap, Something bad happened!",
                            style = MaterialTheme.typography.headlineSmall,
                            fontWeight = FontWeight.Bold,
                            textAlign = TextAlign.Center
                        )
                    }

                    // Shark with nose ring
                    AnimatedVisibility(
                        visible = showShark,
                        enter = scaleIn(
                            animationSpec = spring(
                                dampingRatio = 0.7f,
                                stiffness = Spring.StiffnessMedium
                            )
                        ) + fadeIn()
                    ) {
                        SharkWithNoseRing(size = 80f)
                    }

                    // Second message: "This is Bull Shark!"
                    AnimatedVisibility(
                        visible = showSecondMessage,
                        enter = scaleIn() + fadeIn()
                    ) {
                        Column(
                            horizontalAlignment = Alignment.CenterHorizontally,
                            verticalArrangement = Arrangement.spacedBy(8.dp)
                        ) {
                            Text(
                                text = "This is Bull Shark!",
                                style = MaterialTheme.typography.headlineSmall,
                                fontWeight = FontWeight.Bold,
                                textAlign = TextAlign.Center
                            )
                            Text(
                                text = error.localizedDescription,
                                style = MaterialTheme.typography.bodyMedium,
                                color = MaterialTheme.colorScheme.onSurfaceVariant,
                                textAlign = TextAlign.Center,
                                modifier = Modifier.padding(horizontal = 16.dp)
                            )
                        }
                    }
                }
            }

            // Buttons
            Column(
                modifier = Modifier.fillMaxWidth(),
                verticalArrangement = Arrangement.spacedBy(12.dp)
            ) {
                Button(
                    onClick = onClose,
                    modifier = Modifier.fillMaxWidth(),
                    colors = ButtonDefaults.buttonColors(
                        containerColor = MaterialTheme.colorScheme.primary
                    )
                ) {
                    Text(
                        text = "Close",
                        style = MaterialTheme.typography.titleMedium
                    )
                }

                OutlinedButton(
                    onClick = onShowDetails,
                    modifier = Modifier.fillMaxWidth()
                ) {
                    Icon(
                        imageVector = Icons.Filled.Info,
                        contentDescription = null,
                        modifier = Modifier.size(18.dp)
                    )
                    Spacer(modifier = Modifier.width(8.dp))
                    Text("Show Details")
                }
            }
        }
    }
}

/**
 * Detailed error view with full stack trace
 * Matching iOS ErrorDetailsView
 */
@Composable
private fun ErrorDetailsView(
    error: AppError,
    onClose: () -> Unit
) {
    val clipboardManager = LocalClipboardManager.current
    val dateFormat = remember { SimpleDateFormat("MMM dd, yyyy hh:mm a", Locale.US) }

    Card(
        modifier = Modifier
            .fillMaxWidth(0.9f)
            .fillMaxHeight(0.8f)
            .padding(40.dp)
            .shadow(20.dp, RoundedCornerShape(20.dp)),
        shape = RoundedCornerShape(20.dp),
        colors = CardDefaults.cardColors(
            containerColor = MaterialTheme.colorScheme.surface
        )
    ) {
        Column(
            modifier = Modifier.fillMaxSize()
        ) {
            // Header
            Surface(
                color = MaterialTheme.colorScheme.surfaceVariant
            ) {
                Row(
                    modifier = Modifier
                        .fillMaxWidth()
                        .padding(16.dp),
                    horizontalArrangement = Arrangement.SpaceBetween,
                    verticalAlignment = Alignment.CenterVertically
                ) {
                    Column {
                        Text(
                            text = "Error Details",
                            style = MaterialTheme.typography.headlineSmall,
                            fontWeight = FontWeight.Bold
                        )
                        Text(
                            text = dateFormat.format(error.timestamp),
                            style = MaterialTheme.typography.bodySmall,
                            color = MaterialTheme.colorScheme.onSurfaceVariant
                        )
                    }

                    IconButton(onClick = onClose) {
                        Icon(
                            imageVector = Icons.Filled.Close,
                            contentDescription = "Close"
                        )
                    }
                }
            }

            // Scrollable details
            Column(
                modifier = Modifier
                    .weight(1f)
                    .verticalScroll(rememberScrollState())
                    .padding(16.dp),
                verticalArrangement = Arrangement.spacedBy(16.dp)
            ) {
                // Error message
                DetailSection(title = "Error Message") {
                    Text(
                        text = error.localizedDescription,
                        style = MaterialTheme.typography.bodyMedium
                    )
                }

                // Context
                if (error.context.isNotEmpty()) {
                    DetailSection(title = "Context") {
                        Text(
                            text = error.context,
                            style = MaterialTheme.typography.bodyMedium
                        )
                    }
                }

                // Stack trace
                DetailSection(title = "Stack Trace") {
                    Text(
                        text = error.stackTrace,
                        style = MaterialTheme.typography.bodySmall.copy(
                            fontFamily = androidx.compose.ui.text.font.FontFamily.Monospace
                        )
                    )
                }

                // Copy button
                Button(
                    onClick = {
                        clipboardManager.setText(AnnotatedString(error.stackTrace))
                    },
                    modifier = Modifier.fillMaxWidth()
                ) {
                    Icon(
                        painter = androidx.compose.ui.res.painterResource(android.R.drawable.ic_menu_upload),
                        contentDescription = null,
                        modifier = Modifier.size(18.dp)
                    )
                    Spacer(modifier = Modifier.width(8.dp))
                    Text("Copy Error Details")
                }
            }
        }
    }
}

/**
 * Reusable detail section
 * Matching iOS DetailSection
 */
@Composable
private fun DetailSection(
    title: String,
    content: @Composable () -> Unit
) {
    Column(
        verticalArrangement = Arrangement.spacedBy(8.dp)
    ) {
        Text(
            text = title,
            style = MaterialTheme.typography.titleMedium,
            fontWeight = FontWeight.SemiBold
        )
        Surface(
            modifier = Modifier.fillMaxWidth(),
            shape = RoundedCornerShape(8.dp),
            color = MaterialTheme.colorScheme.surfaceVariant
        ) {
            Box(modifier = Modifier.padding(12.dp)) {
                content()
            }
        }
    }
}

/**
 * Error Handler Singleton
 * Global error container for unexpected exceptions
 * Matching iOS ErrorHandler
 */
object ErrorHandler {
    private val _currentError = mutableStateOf<AppError?>(null)
    val currentError: AppError? by _currentError

    fun handle(error: Throwable, context: String = "") {
        _currentError.value = AppError(
            error = error,
            context = context,
            timestamp = Date()
        )
    }

    fun clear() {
        _currentError.value = null
    }
}

/**
 * Composable function to show error overlay when error exists
 * Use this at the root of your app to handle errors globally
 * Matching iOS .withErrorHandling() modifier
 */
@Composable
fun ErrorHandlingOverlay() {
    val error = ErrorHandler.currentError

    if (error != null) {
        ErrorOverlay(
            error = error,
            onDismiss = { ErrorHandler.clear() }
        )
    }
}
