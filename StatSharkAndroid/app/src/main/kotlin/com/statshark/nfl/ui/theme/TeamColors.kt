package com.statshark.nfl.ui.theme

import androidx.compose.ui.graphics.Color

/**
 * NFL Team Colors
 * Official team branding colors for all 32 teams
 */
object TeamColors {

    // Team color data class
    data class TeamBranding(
        val primary: Color,
        val secondary: Color
    )

    private val teamColorMap = mapOf(
        // NFC East
        "DAL" to TeamBranding(Color(0xFF003594), Color(0xFF869397)),
        "NYG" to TeamBranding(Color(0xFF0B2265), Color(0xFFA71930)),
        "PHI" to TeamBranding(Color(0xFF004C54), Color(0xFFA5ACAF)),
        "WAS" to TeamBranding(Color(0xFF773141), Color(0xFFFFB612)),

        // NFC North
        "CHI" to TeamBranding(Color(0xFF0B162A), Color(0xFFC83803)),
        "DET" to TeamBranding(Color(0xFF0076B6), Color(0xFFB0B7BC)),
        "GB" to TeamBranding(Color(0xFF203731), Color(0xFFFFB612)),
        "MIN" to TeamBranding(Color(0xFF4F2683), Color(0xFFFFC62F)),

        // NFC South
        "ATL" to TeamBranding(Color(0xFFA71930), Color(0xFF000000)),
        "CAR" to TeamBranding(Color(0xFF0085CA), Color(0xFF000000)),
        "NO" to TeamBranding(Color(0xFFD3BC8D), Color(0xFF101820)),
        "TB" to TeamBranding(Color(0xFFD50A0A), Color(0xFF34302B)),

        // NFC West
        "ARI" to TeamBranding(Color(0xFF97233F), Color(0xFF000000)),
        "LAR" to TeamBranding(Color(0xFF003594), Color(0xFFFFA300)),
        "SF" to TeamBranding(Color(0xFFAA0000), Color(0xFFB3995D)),
        "SEA" to TeamBranding(Color(0xFF002244), Color(0xFF69BE28)),

        // AFC East
        "BUF" to TeamBranding(Color(0xFF00338D), Color(0xFFC60C30)),
        "MIA" to TeamBranding(Color(0xFF008E97), Color(0xFFFC4C02)),
        "NE" to TeamBranding(Color(0xFF002244), Color(0xFFC60C30)),
        "NYJ" to TeamBranding(Color(0xFF125740), Color(0xFF000000)),

        // AFC North
        "BAL" to TeamBranding(Color(0xFF241773), Color(0xFF000000)),
        "CIN" to TeamBranding(Color(0xFFFB4F14), Color(0xFF000000)),
        "CLE" to TeamBranding(Color(0xFFFF3C00), Color(0xFF311D00)),
        "PIT" to TeamBranding(Color(0xFFFFB612), Color(0xFF101820)),

        // AFC South
        "HOU" to TeamBranding(Color(0xFF03202F), Color(0xFFA71930)),
        "IND" to TeamBranding(Color(0xFF002C5F), Color(0xFFA2AAAD)),
        "JAX" to TeamBranding(Color(0xFF006778), Color(0xFFD7A22A)),
        "TEN" to TeamBranding(Color(0xFF0C2340), Color(0xFF4B92DB)),

        // AFC West
        "DEN" to TeamBranding(Color(0xFFFB4F14), Color(0xFF002244)),
        "KC" to TeamBranding(Color(0xFFE31837), Color(0xFFFFB81C)),
        "LV" to TeamBranding(Color(0xFF000000), Color(0xFFA5ACAF)),
        "LAC" to TeamBranding(Color(0xFF007BC7), Color(0xFFFFC20E))
    )

    /**
     * Get team branding colors
     */
    fun getTeamColors(abbreviation: String): TeamBranding {
        return teamColorMap[abbreviation] ?: TeamBranding(
            primary = Color(0xFF6B7280), // Gray fallback
            secondary = Color(0xFF9CA3AF)
        )
    }

    /**
     * Get primary color for a team
     */
    fun getPrimaryColor(abbreviation: String): Color {
        return getTeamColors(abbreviation).primary
    }

    /**
     * Get secondary color for a team
     */
    fun getSecondaryColor(abbreviation: String): Color {
        return getTeamColors(abbreviation).secondary
    }

    /**
     * Get conference for a team
     */
    fun getConference(abbreviation: String): String {
        return when (abbreviation) {
            "DAL", "NYG", "PHI", "WAS",
            "CHI", "DET", "GB", "MIN",
            "ATL", "CAR", "NO", "TB",
            "ARI", "LAR", "SF", "SEA" -> "NFC"
            else -> "AFC"
        }
    }

    /**
     * Get division for a team
     */
    fun getDivision(abbreviation: String): String {
        return when (abbreviation) {
            "DAL", "NYG", "PHI", "WAS" -> "NFC East"
            "CHI", "DET", "GB", "MIN" -> "NFC North"
            "ATL", "CAR", "NO", "TB" -> "NFC South"
            "ARI", "LAR", "SF", "SEA" -> "NFC West"
            "BUF", "MIA", "NE", "NYJ" -> "AFC East"
            "BAL", "CIN", "CLE", "PIT" -> "AFC North"
            "HOU", "IND", "JAX", "TEN" -> "AFC South"
            "DEN", "KC", "LV", "LAC" -> "AFC West"
            else -> "Unknown"
        }
    }
}
