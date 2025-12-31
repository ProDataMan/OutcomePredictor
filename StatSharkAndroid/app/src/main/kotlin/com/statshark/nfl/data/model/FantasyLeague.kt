package com.statshark.nfl.data.model

import kotlinx.serialization.Serializable
import java.util.*

/**
 * Fantasy League Models
 * Matches iOS FantasyLeague implementation
 */

@Serializable
data class FantasyLeague(
    val id: String = UUID.randomUUID().toString(),
    var name: String,
    var inviteCode: String,
    val commissionerId: String,
    var members: List<LeagueMember>,
    var settings: LeagueSettings,
    var paymentInfo: LeaguePaymentInfo,
    val createdAt: Long = System.currentTimeMillis(),
    val season: Int
) {
    val totalPrizePool: Double
        get() {
            val totalFees = members.size * paymentInfo.entryFee
            return totalFees * (1.0 - paymentInfo.platformFeePercentage)
        }

    val isFull: Boolean
        get() = members.size >= settings.maxMembers

    val standings: List<LeagueMember>
        get() = members.sortedByDescending { it.totalPoints }

    companion object {
        fun generateInviteCode(): String {
            val characters = "ABCDEFGHJKLMNPQRSTUVWXYZ23456789"
            return (0 until 6).map { characters.random() }.joinToString("")
        }
    }
}

@Serializable
data class LeagueMember(
    val id: String = UUID.randomUUID().toString(),
    var name: String,
    var roster: FantasyRoster,
    val joinedAt: Long = System.currentTimeMillis(),
    var weeklyScores: Map<Int, Double> = emptyMap(),
    var paymentStatus: PaymentStatus = PaymentStatus.EXEMPT
) {
    val totalPoints: Double
        get() = weeklyScores.values.sum()

    val wins: Int
        get() = 0 // Will be calculated from matchup results

    val losses: Int
        get() = 0 // Will be calculated from matchup results
}

@Serializable
data class LeagueSettings(
    var maxMembers: Int = 10,
    var scoringType: ScoringType = ScoringType.PPR,
    var draftType: DraftType = DraftType.MANUAL,
    var entryFee: Double = 10.0,
    var playoffWeeks: Int = 3,
    var tradeDeadlineWeek: Int = 13
) {
    companion object {
        val default = LeagueSettings()
    }
}

@Serializable
enum class ScoringType {
    STANDARD,
    PPR,  // Point Per Reception
    HALF_PPR;

    val displayName: String
        get() = when (this) {
            STANDARD -> "Standard"
            PPR -> "PPR"
            HALF_PPR -> "Half PPR"
        }

    val description: String
        get() = when (this) {
            STANDARD -> "Standard scoring"
            PPR -> "1 point per reception"
            HALF_PPR -> "0.5 points per reception"
        }
}

@Serializable
enum class DraftType {
    MANUAL,
    SNAKE,
    AUCTION;

    val displayName: String
        get() = when (this) {
            MANUAL -> "Manual"
            SNAKE -> "Snake Draft"
            AUCTION -> "Auction Draft"
        }

    val description: String
        get() = when (this) {
            MANUAL -> "Build your team manually"
            SNAKE -> "Traditional snake draft"
            AUCTION -> "Auction-style draft"
        }
}

@Serializable
data class LeaguePaymentInfo(
    var entryFee: Double,
    var prizePool: Double,
    var platformFeePercentage: Double = 0.10, // 10% to StatShark
    var paymentsEnabled: Boolean = false,
    var transactions: List<PaymentTransaction> = emptyList()
) {
    val platformFee: Double
        get() = prizePool / (1.0 - platformFeePercentage) * platformFeePercentage
}

@Serializable
data class PaymentTransaction(
    val id: String = UUID.randomUUID().toString(),
    val memberId: String,
    val amount: Double,
    val type: TransactionType,
    val status: TransactionStatus,
    val timestamp: Long = System.currentTimeMillis(),
    val stripePaymentId: String? = null
)

@Serializable
enum class TransactionType {
    ENTRY_FEE,
    PAYOUT,
    REFUND;

    val displayName: String
        get() = when (this) {
            ENTRY_FEE -> "Entry Fee"
            PAYOUT -> "Prize Payout"
            REFUND -> "Refund"
        }
}

@Serializable
enum class TransactionStatus {
    PENDING,
    COMPLETED,
    FAILED,
    REFUNDED;

    val displayName: String
        get() = when (this) {
            PENDING -> "Pending"
            COMPLETED -> "Completed"
            FAILED -> "Failed"
            REFUNDED -> "Refunded"
        }
}

@Serializable
enum class PaymentStatus {
    PENDING,
    PAID,
    EXEMPT; // For beta period

    val displayText: String
        get() = when (this) {
            PENDING -> "Payment Pending"
            PAID -> "Paid"
            EXEMPT -> "FREE (Beta)"
        }
}

@Serializable
data class WeeklyMatchup(
    val id: String = UUID.randomUUID().toString(),
    val week: Int,
    val homeTeamId: String,
    val awayTeamId: String,
    var homeScore: Double? = null,
    var awayScore: Double? = null,
    var isComplete: Boolean = false
) {
    val winnerId: String?
        get() {
            val home = homeScore ?: return null
            val away = awayScore ?: return null
            return when {
                home > away -> homeTeamId
                away > home -> awayTeamId
                else -> null // Tie
            }
        }
}
