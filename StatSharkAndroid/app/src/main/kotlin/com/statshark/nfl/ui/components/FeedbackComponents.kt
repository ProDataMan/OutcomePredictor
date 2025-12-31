package com.statshark.nfl.ui.components

import android.content.Context
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.items
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.*
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.hilt.navigation.compose.hiltViewModel
import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import com.statshark.nfl.data.model.FeedbackDTO
import com.statshark.nfl.data.repository.NFLRepository
import dagger.hilt.android.lifecycle.HiltViewModel
import dagger.hilt.android.qualifiers.ApplicationContext
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.launch
import java.text.SimpleDateFormat
import java.util.*
import javax.inject.Inject

/**
 * Feedback Button Component
 * Can be added to any screen's top bar
 */
@Composable
fun FeedbackButton(
    pageName: String,
    modifier: Modifier = Modifier
) {
    var showDialog by remember { mutableStateOf(false) }

    IconButton(
        onClick = { showDialog = true },
        modifier = modifier
    ) {
        Icon(
            imageVector = Icons.Default.Feedback,
            contentDescription = "Send Feedback"
        )
    }

    if (showDialog) {
        FeedbackDialog(
            pageName = pageName,
            onDismiss = { showDialog = false }
        )
    }
}

/**
 * Feedback Dialog
 * Material Design 3 dialog for submitting feedback
 */
@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun FeedbackDialog(
    pageName: String,
    onDismiss: () -> Unit,
    viewModel: FeedbackViewModel = hiltViewModel()
) {
    val context = LocalContext.current
    val prefs = context.getSharedPreferences("feedback_prefs", Context.MODE_PRIVATE)

    var userId by remember { mutableStateOf(prefs.getString("userId", "") ?: "") }
    var feedbackText by remember { mutableStateOf("") }
    var isSubmitting by remember { mutableStateOf(false) }
    var showSuccess by remember { mutableStateOf(false) }
    var errorMessage by remember { mutableStateOf<String?>(null) }

    if (showSuccess) {
        AlertDialog(
            onDismissRequest = {
                showSuccess = false
                onDismiss()
            },
            icon = {
                Icon(
                    imageVector = Icons.Default.CheckCircle,
                    contentDescription = null,
                    tint = MaterialTheme.colorScheme.primary
                )
            },
            title = { Text("Thank You!") },
            text = { Text("Your feedback has been submitted successfully. We appreciate your input!") },
            confirmButton = {
                TextButton(onClick = {
                    showSuccess = false
                    onDismiss()
                }) {
                    Text("OK")
                }
            }
        )
    } else {
        AlertDialog(
            onDismissRequest = { if (!isSubmitting) onDismiss() },
            icon = {
                Icon(
                    imageVector = Icons.Default.Feedback,
                    contentDescription = null
                )
            },
            title = { Text("Send Feedback") },
            text = {
                Column(
                    modifier = Modifier.fillMaxWidth(),
                    verticalArrangement = Arrangement.spacedBy(16.dp)
                ) {
                    OutlinedTextField(
                        value = userId,
                        onValueChange = { userId = it },
                        label = { Text("Your Name or Email (optional)") },
                        singleLine = true,
                        modifier = Modifier.fillMaxWidth(),
                        enabled = !isSubmitting
                    )

                    OutlinedTextField(
                        value = feedbackText,
                        onValueChange = { feedbackText = it },
                        label = { Text("Feedback") },
                        placeholder = { Text("Share your feedback, suggestions, or report issues...") },
                        modifier = Modifier
                            .fillMaxWidth()
                            .height(150.dp),
                        maxLines = 6,
                        enabled = !isSubmitting
                    )

                    if (errorMessage != null) {
                        Text(
                            text = errorMessage!!,
                            color = MaterialTheme.colorScheme.error,
                            style = MaterialTheme.typography.bodySmall
                        )
                    }
                }
            },
            confirmButton = {
                TextButton(
                    onClick = {
                        val submitterId = userId.trim().ifEmpty { "anonymous" }
                        prefs.edit().putString("userId", submitterId).apply()

                        isSubmitting = true
                        errorMessage = null

                        viewModel.submitFeedback(
                            userId = submitterId,
                            page = pageName,
                            feedbackText = feedbackText.trim(),
                            onSuccess = {
                                isSubmitting = false
                                showSuccess = true
                            },
                            onError = { error ->
                                isSubmitting = false
                                errorMessage = error
                            }
                        )
                    },
                    enabled = feedbackText.trim().isNotEmpty() && !isSubmitting
                ) {
                    if (isSubmitting) {
                        CircularProgressIndicator(
                            modifier = Modifier.size(16.dp),
                            strokeWidth = 2.dp
                        )
                    } else {
                        Text("Send")
                    }
                }
            },
            dismissButton = {
                TextButton(
                    onClick = onDismiss,
                    enabled = !isSubmitting
                ) {
                    Text("Cancel")
                }
            }
        )
    }
}

/**
 * Feedback ViewModel
 */
@HiltViewModel
class FeedbackViewModel @Inject constructor(
    private val repository: NFLRepository
) : ViewModel() {

    fun submitFeedback(
        userId: String,
        page: String,
        feedbackText: String,
        onSuccess: () -> Unit,
        onError: (String) -> Unit
    ) {
        viewModelScope.launch {
            repository.submitFeedback(
                userId = userId,
                page = page,
                feedbackText = feedbackText
            ).fold(
                onSuccess = { onSuccess() },
                onFailure = { error ->
                    onError(error.message ?: "Failed to submit feedback")
                }
            )
        }
    }
}

/**
 * Admin Feedback Screen
 * Full-screen view for admin to manage feedback
 */
@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun AdminFeedbackScreen(
    onNavigateBack: () -> Unit,
    viewModel: AdminFeedbackViewModel = hiltViewModel()
) {
    val uiState by viewModel.uiState.collectAsState()
    val context = LocalContext.current
    val prefs = context.getSharedPreferences("admin_prefs", Context.MODE_PRIVATE)

    var adminUserId by remember {
        mutableStateOf(prefs.getString("adminUserId", "") ?: "")
    }

    LaunchedEffect(Unit) {
        val savedAdminId = prefs.getString("adminUserId", "")
        if (!savedAdminId.isNullOrEmpty()) {
            adminUserId = savedAdminId
            viewModel.authenticate(savedAdminId)
        }
    }

    Scaffold(
        topBar = {
            TopAppBar(
                title = { Text("User Feedback") },
                navigationIcon = {
                    IconButton(onClick = onNavigateBack) {
                        Icon(Icons.Default.ArrowBack, "Back")
                    }
                },
                actions = {
                    if (uiState.isAuthenticated && uiState.selectedFeedback.isNotEmpty()) {
                        TextButton(
                            onClick = { viewModel.markSelectedAsRead() }
                        ) {
                            Text("Mark Read (${uiState.selectedFeedback.size})")
                        }
                    }
                }
            )
        }
    ) { paddingValues ->
        Box(
            modifier = Modifier
                .fillMaxSize()
                .padding(paddingValues)
        ) {
            when {
                !uiState.isAuthenticated -> {
                    // Authentication screen
                    Column(
                        modifier = Modifier
                            .fillMaxSize()
                            .padding(32.dp),
                        horizontalAlignment = Alignment.CenterHorizontally,
                        verticalArrangement = Arrangement.Center
                    ) {
                        Icon(
                            imageVector = Icons.Default.Lock,
                            contentDescription = null,
                            modifier = Modifier.size(64.dp),
                            tint = MaterialTheme.colorScheme.primary
                        )

                        Spacer(modifier = Modifier.height(16.dp))

                        Text(
                            text = "Admin Access Required",
                            style = MaterialTheme.typography.headlineSmall,
                            fontWeight = FontWeight.Bold
                        )

                        Spacer(modifier = Modifier.height(8.dp))

                        Text(
                            text = "Enter your admin user ID to view feedback",
                            style = MaterialTheme.typography.bodyMedium,
                            color = MaterialTheme.colorScheme.onSurfaceVariant
                        )

                        Spacer(modifier = Modifier.height(24.dp))

                        OutlinedTextField(
                            value = adminUserId,
                            onValueChange = { adminUserId = it },
                            label = { Text("Admin User ID") },
                            singleLine = true,
                            modifier = Modifier.fillMaxWidth()
                        )

                        Spacer(modifier = Modifier.height(16.dp))

                        Button(
                            onClick = {
                                prefs.edit().putString("adminUserId", adminUserId).apply()
                                viewModel.authenticate(adminUserId)
                            },
                            enabled = adminUserId.trim().isNotEmpty() && !uiState.isLoading,
                            modifier = Modifier.fillMaxWidth()
                        ) {
                            if (uiState.isLoading) {
                                CircularProgressIndicator(
                                    modifier = Modifier.size(16.dp),
                                    color = MaterialTheme.colorScheme.onPrimary,
                                    strokeWidth = 2.dp
                                )
                            } else {
                                Text("Authenticate")
                            }
                        }

                        if (uiState.error != null && uiState.error.contains("401") || uiState.error?.contains("unauthorized") == true) {
                            Spacer(modifier = Modifier.height(8.dp))
                            Text(
                                text = "Invalid admin credentials",
                                color = MaterialTheme.colorScheme.error,
                                style = MaterialTheme.typography.bodySmall
                            )
                        }
                    }
                }

                uiState.isLoading -> {
                    CircularProgressIndicator(
                        modifier = Modifier.align(Alignment.Center)
                    )
                }

                uiState.error != null && uiState.isAuthenticated -> {
                    Column(
                        modifier = Modifier
                            .fillMaxSize()
                            .padding(32.dp),
                        horizontalAlignment = Alignment.CenterHorizontally,
                        verticalArrangement = Arrangement.Center
                    ) {
                        Icon(
                            imageVector = Icons.Default.Error,
                            contentDescription = null,
                            modifier = Modifier.size(48.dp),
                            tint = MaterialTheme.colorScheme.error
                        )

                        Spacer(modifier = Modifier.height(16.dp))

                        Text(
                            text = uiState.error ?: "Unknown error",
                            style = MaterialTheme.typography.bodyMedium,
                            color = MaterialTheme.colorScheme.onSurfaceVariant
                        )

                        Spacer(modifier = Modifier.height(16.dp))

                        Button(onClick = { viewModel.loadFeedback() }) {
                            Text("Retry")
                        }
                    }
                }

                uiState.feedbacks.isEmpty() && uiState.isAuthenticated -> {
                    Column(
                        modifier = Modifier
                            .fillMaxSize()
                            .padding(32.dp),
                        horizontalAlignment = Alignment.CenterHorizontally,
                        verticalArrangement = Arrangement.Center
                    ) {
                        Icon(
                            imageVector = Icons.Default.CheckCircle,
                            contentDescription = null,
                            modifier = Modifier.size(48.dp),
                            tint = MaterialTheme.colorScheme.primary
                        )

                        Spacer(modifier = Modifier.height(16.dp))

                        Text(
                            text = "No feedback yet",
                            style = MaterialTheme.typography.titleMedium
                        )

                        Text(
                            text = "Check back later for user feedback",
                            style = MaterialTheme.typography.bodySmall,
                            color = MaterialTheme.colorScheme.onSurfaceVariant
                        )
                    }
                }

                else -> {
                    LazyColumn(
                        modifier = Modifier.fillMaxSize(),
                        contentPadding = PaddingValues(16.dp),
                        verticalArrangement = Arrangement.spacedBy(8.dp)
                    ) {
                        item {
                            Card(
                                colors = CardDefaults.cardColors(
                                    containerColor = MaterialTheme.colorScheme.primaryContainer
                                )
                            ) {
                                Row(
                                    modifier = Modifier
                                        .fillMaxWidth()
                                        .padding(16.dp),
                                    horizontalArrangement = Arrangement.SpaceBetween
                                ) {
                                    Text(
                                        text = "Total: ${uiState.feedbacks.size}",
                                        style = MaterialTheme.typography.bodyMedium
                                    )
                                    Text(
                                        text = "Unread: ${uiState.unreadCount}",
                                        style = MaterialTheme.typography.bodyMedium,
                                        color = if (uiState.unreadCount > 0) {
                                            MaterialTheme.colorScheme.error
                                        } else {
                                            MaterialTheme.colorScheme.onPrimaryContainer
                                        },
                                        fontWeight = if (uiState.unreadCount > 0) FontWeight.Bold else FontWeight.Normal
                                    )
                                }
                            }
                        }

                        items(uiState.feedbacks) { feedback ->
                            FeedbackItem(
                                feedback = feedback,
                                isSelected = uiState.selectedFeedback.contains(feedback.id),
                                onToggleSelection = { viewModel.toggleSelection(feedback.id) }
                            )
                        }
                    }
                }
            }
        }
    }
}

@Composable
fun FeedbackItem(
    feedback: FeedbackDTO,
    isSelected: Boolean,
    onToggleSelection: () -> Unit
) {
    Card(
        modifier = Modifier
            .fillMaxWidth()
            .clickable(onClick = onToggleSelection),
        colors = CardDefaults.cardColors(
            containerColor = if (isSelected) {
                MaterialTheme.colorScheme.primaryContainer
            } else {
                MaterialTheme.colorScheme.surface
            }
        )
    ) {
        Column(
            modifier = Modifier
                .fillMaxWidth()
                .padding(16.dp),
            verticalArrangement = Arrangement.spacedBy(8.dp)
        ) {
            Row(
                modifier = Modifier.fillMaxWidth(),
                horizontalArrangement = Arrangement.SpaceBetween,
                verticalAlignment = Alignment.CenterVertically
            ) {
                Row(
                    horizontalArrangement = Arrangement.spacedBy(8.dp),
                    verticalAlignment = Alignment.CenterVertically
                ) {
                    Icon(
                        imageVector = if (feedback.platform == "iOS") {
                            Icons.Default.Apple
                        } else {
                            Icons.Default.Android
                        },
                        contentDescription = feedback.platform,
                        tint = if (feedback.platform == "iOS") {
                            MaterialTheme.colorScheme.primary
                        } else {
                            MaterialTheme.colorScheme.tertiary
                        },
                        modifier = Modifier.size(16.dp)
                    )

                    Text(
                        text = feedback.page,
                        style = MaterialTheme.typography.titleSmall,
                        fontWeight = FontWeight.Bold
                    )
                }

                Row(
                    horizontalArrangement = Arrangement.spacedBy(8.dp),
                    verticalAlignment = Alignment.CenterVertically
                ) {
                    if (!feedback.isRead) {
                        Icon(
                            imageVector = Icons.Default.FiberManualRecord,
                            contentDescription = "Unread",
                            tint = MaterialTheme.colorScheme.error,
                            modifier = Modifier.size(8.dp)
                        )
                    }

                    if (isSelected) {
                        Icon(
                            imageVector = Icons.Default.CheckCircle,
                            contentDescription = "Selected",
                            tint = MaterialTheme.colorScheme.primary
                        )
                    }
                }
            }

            Text(
                text = feedback.feedbackText,
                style = MaterialTheme.typography.bodyMedium
            )

            Row(
                modifier = Modifier.fillMaxWidth(),
                horizontalArrangement = Arrangement.SpaceBetween
            ) {
                Row(
                    horizontalArrangement = Arrangement.spacedBy(4.dp),
                    verticalAlignment = Alignment.CenterVertically
                ) {
                    Icon(
                        imageVector = Icons.Default.Person,
                        contentDescription = null,
                        modifier = Modifier.size(12.dp),
                        tint = MaterialTheme.colorScheme.onSurfaceVariant
                    )
                    Text(
                        text = feedback.userId,
                        style = MaterialTheme.typography.bodySmall,
                        color = MaterialTheme.colorScheme.onSurfaceVariant
                    )
                }

                Text(
                    text = formatRelativeTime(feedback.createdAt),
                    style = MaterialTheme.typography.bodySmall,
                    color = MaterialTheme.colorScheme.onSurfaceVariant
                )
            }

            if (feedback.appVersion != null && feedback.deviceModel != null) {
                Text(
                    text = "${feedback.deviceModel} · v${feedback.appVersion}",
                    style = MaterialTheme.typography.bodySmall,
                    color = MaterialTheme.colorScheme.onSurfaceVariant
                )
            }
        }
    }
}

/**
 * Admin Feedback ViewModel
 */
@HiltViewModel
class AdminFeedbackViewModel @Inject constructor(
    private val repository: NFLRepository,
    @ApplicationContext private val context: Context
) : ViewModel() {

    private val _uiState = MutableStateFlow(AdminFeedbackUiState())
    val uiState: StateFlow<AdminFeedbackUiState> = _uiState.asStateFlow()

    private var adminUserId: String = ""

    fun authenticate(userId: String) {
        adminUserId = userId.trim()
        loadFeedback()
    }

    fun loadFeedback() {
        viewModelScope.launch {
            _uiState.value = _uiState.value.copy(isLoading = true, error = null)

            val feedbackResult = repository.fetchFeedback(adminUserId)
            val countResult = repository.fetchUnreadCount(adminUserId)

            feedbackResult.fold(
                onSuccess = { feedbacks ->
                    countResult.fold(
                        onSuccess = { count ->
                            _uiState.value = _uiState.value.copy(
                                feedbacks = feedbacks,
                                unreadCount = count,
                                isLoading = false,
                                isAuthenticated = true,
                                error = null
                            )
                        },
                        onFailure = { error ->
                            _uiState.value = _uiState.value.copy(
                                feedbacks = feedbacks,
                                unreadCount = 0,
                                isLoading = false,
                                isAuthenticated = true,
                                error = null
                            )
                        }
                    )
                },
                onFailure = { error ->
                    val errorMsg = error.message ?: "Unknown error"
                    _uiState.value = if (errorMsg.contains("401") || errorMsg.contains("unauthorized", ignoreCase = true)) {
                        _uiState.value.copy(
                            isLoading = false,
                            isAuthenticated = false,
                            error = errorMsg
                        )
                    } else {
                        _uiState.value.copy(
                            isLoading = false,
                            error = errorMsg
                        )
                    }
                }
            )
        }
    }

    fun toggleSelection(feedbackId: String) {
        val currentSelection = _uiState.value.selectedFeedback.toMutableSet()
        if (currentSelection.contains(feedbackId)) {
            currentSelection.remove(feedbackId)
        } else {
            currentSelection.add(feedbackId)
        }
        _uiState.value = _uiState.value.copy(selectedFeedback = currentSelection)
    }

    fun markSelectedAsRead() {
        val idsToMark = _uiState.value.selectedFeedback.toList()
        if (idsToMark.isEmpty()) return

        viewModelScope.launch {
            repository.markFeedbackAsRead(idsToMark).fold(
                onSuccess = {
                    val updatedFeedbacks = _uiState.value.feedbacks.map { feedback ->
                        if (idsToMark.contains(feedback.id)) {
                            feedback.copy(isRead = true)
                        } else {
                            feedback
                        }
                    }

                    _uiState.value = _uiState.value.copy(
                        feedbacks = updatedFeedbacks,
                        selectedFeedback = emptySet(),
                        unreadCount = updatedFeedbacks.count { !it.isRead }
                    )
                },
                onFailure = { error ->
                    _uiState.value = _uiState.value.copy(
                        error = error.message
                    )
                }
            )
        }
    }
}

data class AdminFeedbackUiState(
    val feedbacks: List<FeedbackDTO> = emptyList(),
    val unreadCount: Int = 0,
    val isLoading: Boolean = false,
    val isAuthenticated: Boolean = false,
    val error: String? = null,
    val selectedFeedback: Set<String> = emptySet()
)

/**
 * Format timestamp as relative time
 */
private fun formatRelativeTime(timestamp: String): String {
    return try {
        val format = SimpleDateFormat("yyyy-MM-dd'T'HH:mm:ss.SSS'Z'", Locale.US)
        format.timeZone = TimeZone.getTimeZone("UTC")
        val date = format.parse(timestamp) ?: return timestamp

        val now = Date()
        val diffMs = now.time - date.time
        val diffSec = diffMs / 1000
        val diffMin = diffSec / 60
        val diffHour = diffMin / 60
        val diffDay = diffHour / 24

        when {
            diffSec < 60 -> "Just now"
            diffMin < 60 -> "$diffMin min ago"
            diffHour < 24 -> "$diffHour hr ago"
            diffDay < 7 -> "$diffDay days ago"
            else -> {
                val displayFormat = SimpleDateFormat("MMM d", Locale.US)
                displayFormat.format(date)
            }
        }
    } catch (e: Exception) {
        timestamp
    }
}

// Extension for FeedbackDTO to have a copy method if not auto-generated
private fun FeedbackDTO.copy(
    id: String = this.id,
    userId: String = this.userId,
    page: String = this.page,
    platform: String = this.platform,
    feedbackText: String = this.feedbackText,
    appVersion: String? = this.appVersion,
    deviceModel: String? = this.deviceModel,
    createdAt: String = this.createdAt,
    isRead: Boolean = this.isRead
) = FeedbackDTO(
    id = id,
    userId = userId,
    page = page,
    platform = platform,
    feedbackText = feedbackText,
    appVersion = appVersion,
    deviceModel = deviceModel,
    createdAt = createdAt,
    isRead = isRead
)
