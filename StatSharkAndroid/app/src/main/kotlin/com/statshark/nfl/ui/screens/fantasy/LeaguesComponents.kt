package com.statshark.nfl.ui.screens.fantasy

import android.content.Context
import androidx.compose.foundation.background
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.items
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.*
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.dp
import androidx.lifecycle.compose.collectAsStateWithLifecycle
import com.statshark.nfl.data.manager.FantasyLeagueManager
import com.statshark.nfl.data.model.*
import java.text.SimpleDateFormat
import java.util.*

/**
 * Leagues View - Main leagues list
 */
@Composable
fun LeaguesView(leagueManager: FantasyLeagueManager) {
    val leagues by leagueManager.leagues.collectAsState()
    val currentLeague by leagueManager.currentLeague.collectAsState()
    var showCreateDialog by remember { mutableStateOf(false) }
    var showJoinDialog by remember { mutableStateOf(false) }
    var selectedLeagueForDetail by remember { mutableStateOf<FantasyLeague?>(null) }

    if (leagues.isEmpty()) {
        // Empty state
        Column(
            modifier = Modifier
                .fillMaxSize()
                .padding(32.dp),
            horizontalAlignment = Alignment.CenterHorizontally,
            verticalArrangement = Arrangement.Center
        ) {
            Icon(
                imageVector = Icons.Default.EmojiEvents,
                contentDescription = null,
                modifier = Modifier.size(80.dp),
                tint = MaterialTheme.colorScheme.primary
            )

            Spacer(modifier = Modifier.height(16.dp))

            Text(
                text = "No Leagues Yet",
                style = MaterialTheme.typography.titleLarge,
                fontWeight = FontWeight.Bold
            )

            Spacer(modifier = Modifier.height(8.dp))

            Text(
                text = "Create or join a fantasy league to compete with friends",
                style = MaterialTheme.typography.bodyMedium,
                color = MaterialTheme.colorScheme.onSurfaceVariant,
                textAlign = TextAlign.Center
            )

            Spacer(modifier = Modifier.height(24.dp))

            Button(
                onClick = { showCreateDialog = true },
                modifier = Modifier.fillMaxWidth()
            ) {
                Icon(Icons.Default.Add, null)
                Spacer(Modifier.width(8.dp))
                Text("Create League")
            }

            Spacer(modifier = Modifier.height(12.dp))

            OutlinedButton(
                onClick = { showJoinDialog = true },
                modifier = Modifier.fillMaxWidth()
            ) {
                Icon(Icons.Default.PersonAdd, null)
                Spacer(Modifier.width(8.dp))
                Text("Join League")
            }

            Spacer(modifier = Modifier.height(24.dp))

            // Beta notice
            Card(
                colors = CardDefaults.cardColors(
                    containerColor = MaterialTheme.colorScheme.primaryContainer
                )
            ) {
                Column(
                    modifier = Modifier.padding(16.dp),
                    verticalArrangement = Arrangement.spacedBy(8.dp)
                ) {
                    Row(verticalAlignment = Alignment.CenterVertically) {
                        Icon(Icons.Default.Info, null, modifier = Modifier.size(20.dp))
                        Spacer(Modifier.width(8.dp))
                        Text("Beta Period", fontWeight = FontWeight.Bold)
                    }
                    Text(
                        "All leagues are FREE during beta. Entry fees shown are for display only.",
                        style = MaterialTheme.typography.bodySmall
                    )
                }
            }
        }
    } else {
        // Leagues list
        LazyColumn(
            modifier = Modifier.fillMaxSize(),
            contentPadding = PaddingValues(16.dp),
            verticalArrangement = Arrangement.spacedBy(12.dp)
        ) {
            item {
                Row(
                    modifier = Modifier.fillMaxWidth(),
                    horizontalArrangement = Arrangement.spacedBy(8.dp)
                ) {
                    Button(
                        onClick = { showCreateDialog = true },
                        modifier = Modifier.weight(1f)
                    ) {
                        Icon(Icons.Default.Add, null, modifier = Modifier.size(18.dp))
                        Spacer(Modifier.width(4.dp))
                        Text("Create")
                    }

                    OutlinedButton(
                        onClick = { showJoinDialog = true },
                        modifier = Modifier.weight(1f)
                    ) {
                        Icon(Icons.Default.PersonAdd, null, modifier = Modifier.size(18.dp))
                        Spacer(Modifier.width(4.dp))
                        Text("Join")
                    }
                }
            }

            items(leagues) { league ->
                LeagueCard(
                    league = league,
                    isCurrentLeague = league.id == currentLeague?.id,
                    onClick = { selectedLeagueForDetail = league },
                    onSetCurrent = { leagueManager.setCurrentLeague(league) }
                )
            }
        }
    }

    // Dialogs
    if (showCreateDialog) {
        CreateLeagueDialog(
            leagueManager = leagueManager,
            onDismiss = { showCreateDialog = false }
        )
    }

    if (showJoinDialog) {
        JoinLeagueDialog(
            leagueManager = leagueManager,
            onDismiss = { showJoinDialog = false }
        )
    }

    if (selectedLeagueForDetail != null) {
        LeagueDetailDialog(
            league = selectedLeagueForDetail!!,
            leagueManager = leagueManager,
            onDismiss = { selectedLeagueForDetail = null }
        )
    }
}

/**
 * League Card Component
 */
@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun LeagueCard(
    league: FantasyLeague,
    isCurrentLeague: Boolean,
    onClick: () -> Unit,
    onSetCurrent: () -> Unit
) {
    Card(
        modifier = Modifier
            .fillMaxWidth()
            .clickable(onClick = onClick),
        elevation = CardDefaults.cardElevation(defaultElevation = if (isCurrentLeague) 8.dp else 2.dp),
        colors = CardDefaults.cardColors(
            containerColor = if (isCurrentLeague) {
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
                    verticalAlignment = Alignment.CenterVertically,
                    horizontalArrangement = Arrangement.spacedBy(8.dp)
                ) {
                    Icon(Icons.Default.EmojiEvents, null, modifier = Modifier.size(24.dp))
                    Text(
                        text = league.name,
                        style = MaterialTheme.typography.titleMedium,
                        fontWeight = FontWeight.Bold
                    )
                }

                if (isCurrentLeague) {
                    Text(
                        text = "CURRENT",
                        style = MaterialTheme.typography.labelSmall,
                        color = Color.White,
                        modifier = Modifier
                            .background(MaterialTheme.colorScheme.primary, CircleShape)
                            .padding(horizontal = 8.dp, vertical = 4.dp)
                    )
                }
            }

            Divider()

            Row(
                modifier = Modifier.fillMaxWidth(),
                horizontalArrangement = Arrangement.SpaceBetween
            ) {
                Column {
                    Text(
                        "Invite Code",
                        style = MaterialTheme.typography.labelSmall,
                        color = MaterialTheme.colorScheme.onSurfaceVariant
                    )
                    Text(
                        league.inviteCode,
                        style = MaterialTheme.typography.bodyLarge,
                        fontWeight = FontWeight.Bold,
                        color = MaterialTheme.colorScheme.primary
                    )
                }

                Column(horizontalAlignment = Alignment.End) {
                    Text(
                        "Members",
                        style = MaterialTheme.typography.labelSmall,
                        color = MaterialTheme.colorScheme.onSurfaceVariant
                    )
                    Text(
                        "${league.members.size}/${league.settings.maxMembers}",
                        style = MaterialTheme.typography.bodyLarge,
                        fontWeight = FontWeight.SemiBold
                    )
                }
            }

            Row(
                modifier = Modifier.fillMaxWidth(),
                horizontalArrangement = Arrangement.SpaceBetween,
                verticalAlignment = Alignment.CenterVertically
            ) {
                Text(
                    "${league.settings.scoringType.displayName} · ${league.settings.draftType.displayName}",
                    style = MaterialTheme.typography.bodySmall,
                    color = MaterialTheme.colorScheme.onSurfaceVariant
                )

                if (!isCurrentLeague) {
                    TextButton(onClick = onSetCurrent) {
                        Text("Set Current")
                    }
                }
            }
        }
    }
}

/**
 * Create League Dialog
 */
@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun CreateLeagueDialog(
    leagueManager: FantasyLeagueManager,
    onDismiss: () -> Unit
) {
    val context = LocalContext.current
    val prefs = context.getSharedPreferences("fantasy_prefs", Context.MODE_PRIVATE)

    var leagueName by remember { mutableStateOf("") }
    var commissionerName by remember { mutableStateOf(prefs.getString("team_name", "") ?: "") }
    var maxMembers by remember { mutableIntStateOf(10) }
    var scoringType by remember { mutableStateOf(ScoringType.PPR) }
    var draftType by remember { mutableStateOf(DraftType.MANUAL) }
    var entryFee by remember { mutableDoubleStateOf(10.0) }

    AlertDialog(
        onDismissRequest = onDismiss,
        title = { Text("Create Fantasy League") },
        text = {
            LazyColumn(
                verticalArrangement = Arrangement.spacedBy(12.dp)
            ) {
                item {
                    OutlinedTextField(
                        value = leagueName,
                        onValueChange = { leagueName = it },
                        label = { Text("League Name") },
                        singleLine = true,
                        modifier = Modifier.fillMaxWidth()
                    )
                }

                item {
                    OutlinedTextField(
                        value = commissionerName,
                        onValueChange = { commissionerName = it },
                        label = { Text("Your Name") },
                        singleLine = true,
                        modifier = Modifier.fillMaxWidth()
                    )
                }

                item {
                    Text("Max Members: $maxMembers", style = MaterialTheme.typography.bodyMedium)
                    Slider(
                        value = maxMembers.toFloat(),
                        onValueChange = { maxMembers = it.toInt() },
                        valueRange = 4f..20f,
                        steps = 15
                    )
                }

                item {
                    var scoringExpanded by remember { mutableStateOf(false) }
                    ExposedDropdownMenuBox(
                        expanded = scoringExpanded,
                        onExpandedChange = { scoringExpanded = it }
                    ) {
                        OutlinedTextField(
                            value = scoringType.displayName,
                            onValueChange = {},
                            readOnly = true,
                            label = { Text("Scoring Type") },
                            trailingIcon = { ExposedDropdownMenuDefaults.TrailingIcon(scoringExpanded) },
                            modifier = Modifier
                                .fillMaxWidth()
                                .menuAnchor()
                        )

                        ExposedDropdownMenu(
                            expanded = scoringExpanded,
                            onDismissRequest = { scoringExpanded = false }
                        ) {
                            ScoringType.entries.forEach { type ->
                                DropdownMenuItem(
                                    text = {
                                        Column {
                                            Text(type.displayName, fontWeight = FontWeight.Bold)
                                            Text(type.description, style = MaterialTheme.typography.bodySmall)
                                        }
                                    },
                                    onClick = {
                                        scoringType = type
                                        scoringExpanded = false
                                    }
                                )
                            }
                        }
                    }
                }

                item {
                    var draftExpanded by remember { mutableStateOf(false) }
                    ExposedDropdownMenuBox(
                        expanded = draftExpanded,
                        onExpandedChange = { draftExpanded = it }
                    ) {
                        OutlinedTextField(
                            value = draftType.displayName,
                            onValueChange = {},
                            readOnly = true,
                            label = { Text("Draft Type") },
                            trailingIcon = { ExposedDropdownMenuDefaults.TrailingIcon(draftExpanded) },
                            modifier = Modifier
                                .fillMaxWidth()
                                .menuAnchor()
                        )

                        ExposedDropdownMenu(
                            expanded = draftExpanded,
                            onDismissRequest = { draftExpanded = false }
                        ) {
                            DraftType.entries.forEach { type ->
                                DropdownMenuItem(
                                    text = {
                                        Column {
                                            Text(type.displayName, fontWeight = FontWeight.Bold)
                                            Text(type.description, style = MaterialTheme.typography.bodySmall)
                                        }
                                    },
                                    onClick = {
                                        draftType = type
                                        draftExpanded = false
                                    }
                                )
                            }
                        }
                    }
                }

                item {
                    Card(colors = CardDefaults.cardColors(containerColor = MaterialTheme.colorScheme.tertiaryContainer)) {
                        Column(modifier = Modifier.padding(12.dp)) {
                            Row(verticalAlignment = Alignment.CenterVertically) {
                                Icon(Icons.Default.Info, null, modifier = Modifier.size(16.dp))
                                Spacer(Modifier.width(8.dp))
                                Text("Entry Fee: $${String.format("%.2f", entryFee)}", fontWeight = FontWeight.Bold)
                                Spacer(Modifier.width(4.dp))
                                Text("(FREE)", color = MaterialTheme.colorScheme.primary, fontWeight = FontWeight.Bold)
                            }
                            Text(
                                "All leagues FREE during beta",
                                style = MaterialTheme.typography.bodySmall,
                                color = MaterialTheme.colorScheme.onTertiaryContainer
                            )
                        }
                    }
                }
            }
        },
        confirmButton = {
            TextButton(
                onClick = {
                    if (leagueName.trim().isNotEmpty() && commissionerName.trim().isNotEmpty()) {
                        // Save commissioner name
                        prefs.edit().putString("commissioner_name", commissionerName.trim()).apply()

                        // Get current roster from FantasyViewModel
                        val roster = FantasyRoster() // Use default or current roster

                        val commissionerMember = LeagueMember(
                            name = commissionerName.trim(),
                            roster = roster
                        )

                        val newLeague = FantasyLeague(
                            name = leagueName.trim(),
                            inviteCode = FantasyLeague.generateInviteCode(),
                            commissionerId = commissionerMember.id,
                            members = listOf(commissionerMember),
                            settings = LeagueSettings(
                                maxMembers = maxMembers,
                                scoringType = scoringType,
                                draftType = draftType,
                                entryFee = entryFee
                            ),
                            paymentInfo = LeaguePaymentInfo(
                                entryFee = entryFee,
                                prizePool = 0.0,
                                paymentsEnabled = FantasyLeagueManager.PAYMENTS_ENABLED
                            ),
                            season = Calendar.getInstance().get(Calendar.YEAR)
                        )

                        leagueManager.createLeague(newLeague)
                        onDismiss()
                    }
                },
                enabled = leagueName.trim().isNotEmpty() && commissionerName.trim().isNotEmpty()
            ) {
                Text("Create")
            }
        },
        dismissButton = {
            TextButton(onClick = onDismiss) {
                Text("Cancel")
            }
        }
    )
}

/**
 * Join League Dialog
 */
@Composable
fun JoinLeagueDialog(
    leagueManager: FantasyLeagueManager,
    onDismiss: () -> Unit
) {
    val context = LocalContext.current
    val prefs = context.getSharedPreferences("fantasy_prefs", Context.MODE_PRIVATE)

    var inviteCode by remember { mutableStateOf("") }
    var userName by remember { mutableStateOf(prefs.getString("team_name", "") ?: "") }
    var errorMessage by remember { mutableStateOf<String?>(null) }

    AlertDialog(
        onDismissRequest = onDismiss,
        title = { Text("Join Fantasy League") },
        text = {
            Column(verticalArrangement = Arrangement.spacedBy(16.dp)) {
                OutlinedTextField(
                    value = inviteCode,
                    onValueChange = {
                        inviteCode = it.uppercase().take(6)
                        errorMessage = null
                    },
                    label = { Text("Invite Code") },
                    singleLine = true,
                    modifier = Modifier.fillMaxWidth(),
                    supportingText = { Text("6-character code from league creator") }
                )

                OutlinedTextField(
                    value = userName,
                    onValueChange = { userName = it },
                    label = { Text("Your Name") },
                    singleLine = true,
                    modifier = Modifier.fillMaxWidth()
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
                    if (inviteCode.length == 6 && userName.trim().isNotEmpty()) {
                        prefs.edit().putString("team_name", userName.trim()).apply()

                        val roster = FantasyRoster() // Use default or current roster
                        val success = leagueManager.joinLeague(
                            inviteCode = inviteCode,
                            userName = userName.trim(),
                            roster = roster
                        )

                        if (success) {
                            onDismiss()
                        } else {
                            errorMessage = "Invalid invite code. Please check and try again."
                        }
                    }
                },
                enabled = inviteCode.length == 6 && userName.trim().isNotEmpty()
            ) {
                Text("Join")
            }
        },
        dismissButton = {
            TextButton(onClick = onDismiss) {
                Text("Cancel")
            }
        }
    )
}

/**
 * League Detail Dialog - Full screen dialog with league info and standings
 */
@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun LeagueDetailDialog(
    league: FantasyLeague,
    leagueManager: FantasyLeagueManager,
    onDismiss: () -> Unit
) {
    var showLeaveConfirmation by remember { mutableStateOf(false) }

    AlertDialog(
        onDismissRequest = onDismiss,
        modifier = Modifier.fillMaxWidth(),
        title = {
            Row(
                modifier = Modifier.fillMaxWidth(),
                horizontalArrangement = Arrangement.SpaceBetween,
                verticalAlignment = Alignment.CenterVertically
            ) {
                Text(league.name)
                IconButton(onClick = { showLeaveConfirmation = true }) {
                    Icon(
                        Icons.Default.ExitToApp,
                        "Leave League",
                        tint = MaterialTheme.colorScheme.error
                    )
                }
            }
        },
        text = {
            LazyColumn(
                verticalArrangement = Arrangement.spacedBy(16.dp)
            ) {
                item {
                    Card(colors = CardDefaults.cardColors(containerColor = MaterialTheme.colorScheme.surfaceVariant)) {
                        Column(modifier = Modifier.padding(16.dp), verticalArrangement = Arrangement.spacedBy(8.dp)) {
                            Row(horizontalArrangement = Arrangement.SpaceBetween, modifier = Modifier.fillMaxWidth()) {
                                Text("Invite Code", style = MaterialTheme.typography.labelMedium)
                                Text(league.inviteCode, fontWeight = FontWeight.Bold)
                            }
                            Row(horizontalArrangement = Arrangement.SpaceBetween, modifier = Modifier.fillMaxWidth()) {
                                Text("Members", style = MaterialTheme.typography.labelMedium)
                                Text("${league.members.size}/${league.settings.maxMembers}")
                            }
                            Row(horizontalArrangement = Arrangement.SpaceBetween, modifier = Modifier.fillMaxWidth()) {
                                Text("Scoring", style = MaterialTheme.typography.labelMedium)
                                Text(league.settings.scoringType.displayName)
                            }
                            Row(horizontalArrangement = Arrangement.SpaceBetween, modifier = Modifier.fillMaxWidth()) {
                                Text("Entry Fee", style = MaterialTheme.typography.labelMedium)
                                Row {
                                    Text("$${String.format("%.2f", league.settings.entryFee)}")
                                    Spacer(Modifier.width(4.dp))
                                    Text("(FREE)", color = MaterialTheme.colorScheme.primary, fontWeight = FontWeight.Bold)
                                }
                            }
                        }
                    }
                }

                item {
                    Text("Standings", style = MaterialTheme.typography.titleMedium, fontWeight = FontWeight.Bold)
                }

                items(league.standings) { member ->
                    Card(colors = CardDefaults.cardColors(containerColor = MaterialTheme.colorScheme.surface)) {
                        Row(
                            modifier = Modifier
                                .fillMaxWidth()
                                .padding(12.dp),
                            horizontalArrangement = Arrangement.SpaceBetween,
                            verticalAlignment = Alignment.CenterVertically
                        ) {
                            Row(
                                horizontalArrangement = Arrangement.spacedBy(12.dp),
                                verticalAlignment = Alignment.CenterVertically
                            ) {
                                Text(
                                    "#${league.standings.indexOf(member) + 1}",
                                    style = MaterialTheme.typography.titleMedium,
                                    fontWeight = FontWeight.Bold,
                                    color = MaterialTheme.colorScheme.primary
                                )
                                Column {
                                    Text(member.name, fontWeight = FontWeight.SemiBold)
                                    Text(
                                        "${member.roster.totalPlayers} players",
                                        style = MaterialTheme.typography.bodySmall,
                                        color = MaterialTheme.colorScheme.onSurfaceVariant
                                    )
                                }
                            }

                            Column(horizontalAlignment = Alignment.End) {
                                Text(
                                    String.format("%.1f pts", member.totalPoints),
                                    fontWeight = FontWeight.Bold
                                )
                                Text(
                                    member.paymentStatus.displayText,
                                    style = MaterialTheme.typography.labelSmall,
                                    color = when (member.paymentStatus) {
                                        PaymentStatus.PAID -> Color(0xFF4CAF50)
                                        PaymentStatus.PENDING -> Color(0xFFFF9800)
                                        PaymentStatus.EXEMPT -> Color(0xFF2196F3)
                                    }
                                )
                            }
                        }
                    }
                }
            }
        },
        confirmButton = {
            TextButton(onClick = onDismiss) {
                Text("Close")
            }
        }
    )

    // Leave confirmation
    if (showLeaveConfirmation) {
        AlertDialog(
            onDismissRequest = { showLeaveConfirmation = false },
            title = { Text("Leave League?") },
            text = { Text("Are you sure you want to leave ${league.name}? This action cannot be undone.") },
            confirmButton = {
                TextButton(
                    onClick = {
                        leagueManager.leaveLeague(league.id)
                        showLeaveConfirmation = false
                        onDismiss()
                    },
                    colors = ButtonDefaults.textButtonColors(contentColor = MaterialTheme.colorScheme.error)
                ) {
                    Text("Leave")
                }
            },
            dismissButton = {
                TextButton(onClick = { showLeaveConfirmation = false }) {
                    Text("Cancel")
                }
            }
        )
    }
}

/**
 * Fantasy Settings Dialog
 */
@Composable
fun FantasySettingsDialog(
    leagueManager: FantasyLeagueManager,
    fantasyManager: FantasyViewModel,
    onDismiss: () -> Unit
) {
    val context = LocalContext.current
    val prefs = context.getSharedPreferences("fantasy_prefs", Context.MODE_PRIVATE)
    val currentLeague by leagueManager.currentLeague.collectAsState()
    val leagues by leagueManager.leagues.collectAsState()

    var teamName by remember { mutableStateOf(prefs.getString("team_name", "") ?: "") }
    var editingLeague by remember { mutableStateOf<FantasyLeague?>(null) }
    var newLeagueName by remember { mutableStateOf("") }

    AlertDialog(
        onDismissRequest = onDismiss,
        title = { Text("Fantasy Settings") },
        text = {
            LazyColumn(verticalArrangement = Arrangement.spacedBy(16.dp)) {
                // Team Name Section
                item {
                    Text("Fantasy Team", style = MaterialTheme.typography.titleSmall, fontWeight = FontWeight.Bold)
                    Spacer(Modifier.height(8.dp))
                    OutlinedTextField(
                        value = teamName,
                        onValueChange = { teamName = it },
                        label = { Text("Team Name") },
                        singleLine = true,
                        modifier = Modifier.fillMaxWidth()
                    )
                    Spacer(Modifier.height(8.dp))
                    Button(
                        onClick = {
                            prefs.edit().putString("team_name", teamName.trim()).apply()
                            // Show confirmation
                        },
                        enabled = teamName.trim().isNotEmpty(),
                        modifier = Modifier.fillMaxWidth()
                    ) {
                        Text("Save Team Name")
                    }
                }

                // Current League Section
                if (currentLeague != null) {
                    item {
                        Divider()
                        Spacer(Modifier.height(8.dp))
                        Text("Current League", style = MaterialTheme.typography.titleSmall, fontWeight = FontWeight.Bold)
                    }

                    item {
                        Card(colors = CardDefaults.cardColors(containerColor = MaterialTheme.colorScheme.primaryContainer)) {
                            Column(modifier = Modifier.padding(16.dp), verticalArrangement = Arrangement.spacedBy(8.dp)) {
                                Row(horizontalArrangement = Arrangement.SpaceBetween, modifier = Modifier.fillMaxWidth()) {
                                    Text("League Name")
                                    Text(currentLeague!!.name, fontWeight = FontWeight.SemiBold)
                                }
                                Row(horizontalArrangement = Arrangement.SpaceBetween, modifier = Modifier.fillMaxWidth()) {
                                    Text("Invite Code")
                                    Text(currentLeague!!.inviteCode, fontWeight = FontWeight.Bold, color = MaterialTheme.colorScheme.primary)
                                }
                                Row(horizontalArrangement = Arrangement.SpaceBetween, modifier = Modifier.fillMaxWidth()) {
                                    Text("Members")
                                    Text("${currentLeague!!.members.size}")
                                }
                                Button(
                                    onClick = {
                                        editingLeague = currentLeague
                                        newLeagueName = currentLeague!!.name
                                    },
                                    modifier = Modifier.fillMaxWidth()
                                ) {
                                    Text("Edit League Name")
                                }
                            }
                        }
                    }
                }

                // All Leagues
                if (leagues.isNotEmpty()) {
                    item {
                        Divider()
                        Spacer(Modifier.height(8.dp))
                        Text("All Leagues", style = MaterialTheme.typography.titleSmall, fontWeight = FontWeight.Bold)
                    }

                    items(leagues.size) { index ->
                        val league = leagues[index]
                        Card(
                            colors = CardDefaults.cardColors(
                                containerColor = if (league.id == currentLeague?.id) {
                                    MaterialTheme.colorScheme.primaryContainer
                                } else {
                                    MaterialTheme.colorScheme.surface
                                }
                            )
                        ) {
                            Row(
                                modifier = Modifier
                                    .fillMaxWidth()
                                    .padding(16.dp),
                                horizontalArrangement = Arrangement.SpaceBetween,
                                verticalAlignment = Alignment.CenterVertically
                            ) {
                                Column {
                                    Row(verticalAlignment = Alignment.CenterVertically, horizontalArrangement = Arrangement.spacedBy(8.dp)) {
                                        Text(league.name, fontWeight = FontWeight.SemiBold)
                                        if (league.id == currentLeague?.id) {
                                            Text(
                                                "CURRENT",
                                                style = MaterialTheme.typography.labelSmall,
                                                color = Color.White,
                                                modifier = Modifier
                                                    .background(MaterialTheme.colorScheme.primary, CircleShape)
                                                    .padding(horizontal = 6.dp, vertical = 2.dp)
                                            )
                                        }
                                    }
                                    Text(
                                        "${league.members.size} members",
                                        style = MaterialTheme.typography.bodySmall,
                                        color = MaterialTheme.colorScheme.onSurfaceVariant
                                    )
                                }

                                if (league.id != currentLeague?.id) {
                                    TextButton(onClick = { leagueManager.setCurrentLeague(league) }) {
                                        Text("Set Current")
                                    }
                                }
                            }
                        }
                    }
                }
            }
        },
        confirmButton = {
            TextButton(onClick = onDismiss) {
                Text("Close")
            }
        },
        dismissButton = null
    )

    // Edit League Name Dialog
    if (editingLeague != null) {
        AlertDialog(
            onDismissRequest = { editingLeague = null },
            title = { Text("Edit League Name") },
            text = {
                OutlinedTextField(
                    value = newLeagueName,
                    onValueChange = { newLeagueName = it },
                    label = { Text("League Name") },
                    singleLine = true,
                    modifier = Modifier.fillMaxWidth()
                )
            },
            confirmButton = {
                TextButton(
                    onClick = {
                        if (newLeagueName.trim().isNotEmpty()) {
                            leagueManager.updateLeagueName(editingLeague!!.id, newLeagueName.trim())
                            editingLeague = null
                        }
                    },
                    enabled = newLeagueName.trim().isNotEmpty()
                ) {
                    Text("Save")
                }
            },
            dismissButton = {
                TextButton(onClick = { editingLeague = null }) {
                    Text("Cancel")
                }
            }
        )
    }
}
