import SwiftUI

/// Team colors and branding information.
struct TeamBranding {
    let primaryColor: Color
    let secondaryColor: Color
    let helmetImageName: String

    /// Get branding for a team by abbreviation.
    static func branding(for abbreviation: String) -> TeamBranding {
        switch abbreviation {
        // NFC East
        case "DAL": return TeamBranding(primaryColor: Color(red: 0/255, green: 34/255, blue: 68/255),
                                        secondaryColor: Color(red: 134/255, green: 147/255, blue: 151/255),
                                        helmetImageName: "helmet_dal")
        case "PHI": return TeamBranding(primaryColor: Color(red: 0/255, green: 76/255, blue: 84/255),
                                        secondaryColor: Color(red: 165/255, green: 172/255, blue: 175/255),
                                        helmetImageName: "helmet_phi")
        case "NYG": return TeamBranding(primaryColor: Color(red: 1/255, green: 35/255, blue: 82/255),
                                        secondaryColor: Color(red: 163/255, green: 13/255, blue: 45/255),
                                        helmetImageName: "helmet_nyg")
        case "WAS": return TeamBranding(primaryColor: Color(red: 90/255, green: 20/255, blue: 20/255),
                                        secondaryColor: Color(red: 255/255, green: 182/255, blue: 18/255),
                                        helmetImageName: "helmet_was")

        // NFC North
        case "DET": return TeamBranding(primaryColor: Color(red: 0/255, green: 118/255, blue: 182/255),
                                        secondaryColor: Color(red: 176/255, green: 183/255, blue: 188/255),
                                        helmetImageName: "helmet_det")
        case "GB": return TeamBranding(primaryColor: Color(red: 24/255, green: 48/255, blue: 40/255),
                                       secondaryColor: Color(red: 255/255, green: 184/255, blue: 28/255),
                                       helmetImageName: "helmet_gb")
        case "MIN": return TeamBranding(primaryColor: Color(red: 79/255, green: 38/255, blue: 131/255),
                                        secondaryColor: Color(red: 255/255, green: 198/255, blue: 47/255),
                                        helmetImageName: "helmet_min")
        case "CHI": return TeamBranding(primaryColor: Color(red: 11/255, green: 22/255, blue: 42/255),
                                        secondaryColor: Color(red: 200/255, green: 56/255, blue: 3/255),
                                        helmetImageName: "helmet_chi")

        // NFC South
        case "TB": return TeamBranding(primaryColor: Color(red: 213/255, green: 10/255, blue: 10/255),
                                       secondaryColor: Color(red: 255/255, green: 121/255, blue: 0/255),
                                       helmetImageName: "helmet_tb")
        case "ATL": return TeamBranding(primaryColor: Color(red: 167/255, green: 25/255, blue: 48/255),
                                        secondaryColor: Color.black,
                                        helmetImageName: "helmet_atl")
        case "NO": return TeamBranding(primaryColor: Color(red: 211/255, green: 188/255, blue: 141/255),
                                       secondaryColor: Color.black,
                                       helmetImageName: "helmet_no")
        case "CAR": return TeamBranding(primaryColor: Color(red: 0/255, green: 133/255, blue: 202/255),
                                        secondaryColor: Color.black,
                                        helmetImageName: "helmet_car")

        // NFC West
        case "SF": return TeamBranding(primaryColor: Color(red: 170/255, green: 0/255, blue: 0/255),
                                       secondaryColor: Color(red: 173/255, green: 153/255, blue: 93/255),
                                       helmetImageName: "helmet_sf")
        case "SEA": return TeamBranding(primaryColor: Color(red: 0/255, green: 34/255, blue: 68/255),
                                        secondaryColor: Color(red: 105/255, green: 190/255, blue: 40/255),
                                        helmetImageName: "helmet_sea")
        case "LAR": return TeamBranding(primaryColor: Color(red: 0/255, green: 53/255, blue: 148/255),
                                        secondaryColor: Color(red: 255/255, green: 209/255, blue: 0/255),
                                        helmetImageName: "helmet_lar")
        case "ARI": return TeamBranding(primaryColor: Color(red: 151/255, green: 35/255, blue: 63/255),
                                        secondaryColor: Color(red: 255/255, green: 182/255, blue: 18/255),
                                        helmetImageName: "helmet_ari")

        // AFC East
        case "BUF": return TeamBranding(primaryColor: Color(red: 0/255, green: 51/255, blue: 141/255),
                                        secondaryColor: Color(red: 198/255, green: 12/255, blue: 48/255),
                                        helmetImageName: "helmet_buf")
        case "MIA": return TeamBranding(primaryColor: Color(red: 0/255, green: 142/255, blue: 151/255),
                                        secondaryColor: Color(red: 252/255, green: 76/255, blue: 2/255),
                                        helmetImageName: "helmet_mia")
        case "NYJ": return TeamBranding(primaryColor: Color(red: 18/255, green: 87/255, blue: 64/255),
                                        secondaryColor: Color.white,
                                        helmetImageName: "helmet_nyj")
        case "NE": return TeamBranding(primaryColor: Color(red: 0/255, green: 34/255, blue: 68/255),
                                       secondaryColor: Color(red: 198/255, green: 12/255, blue: 48/255),
                                       helmetImageName: "helmet_ne")

        // AFC North
        case "BAL": return TeamBranding(primaryColor: Color(red: 26/255, green: 25/255, blue: 95/255),
                                        secondaryColor: Color(red: 158/255, green: 124/255, blue: 12/255),
                                        helmetImageName: "helmet_bal")
        case "PIT": return TeamBranding(primaryColor: Color.black,
                                        secondaryColor: Color(red: 255/255, green: 182/255, blue: 18/255),
                                        helmetImageName: "helmet_pit")
        case "CIN": return TeamBranding(primaryColor: Color(red: 251/255, green: 79/255, blue: 20/255),
                                        secondaryColor: Color.black,
                                        helmetImageName: "helmet_cin")
        case "CLE": return TeamBranding(primaryColor: Color(red: 49/255, green: 29/255, blue: 0/255),
                                        secondaryColor: Color(red: 255/255, green: 60/255, blue: 0/255),
                                        helmetImageName: "helmet_cle")

        // AFC South
        case "HOU": return TeamBranding(primaryColor: Color(red: 3/255, green: 32/255, blue: 47/255),
                                        secondaryColor: Color(red: 167/255, green: 25/255, blue: 48/255),
                                        helmetImageName: "helmet_hou")
        case "IND": return TeamBranding(primaryColor: Color(red: 0/255, green: 44/255, blue: 95/255),
                                        secondaryColor: Color.white,
                                        helmetImageName: "helmet_ind")
        case "JAX": return TeamBranding(primaryColor: Color(red: 0/255, green: 103/255, blue: 120/255),
                                        secondaryColor: Color(red: 215/255, green: 162/255, blue: 42/255),
                                        helmetImageName: "helmet_jax")
        case "TEN": return TeamBranding(primaryColor: Color(red: 12/255, green: 35/255, blue: 64/255),
                                        secondaryColor: Color(red: 75/255, green: 146/255, blue: 219/255),
                                        helmetImageName: "helmet_ten")

        // AFC West
        case "KC": return TeamBranding(primaryColor: Color(red: 227/255, green: 24/255, blue: 55/255),
                                       secondaryColor: Color(red: 255/255, green: 184/255, blue: 28/255),
                                       helmetImageName: "helmet_kc")
        case "LAC": return TeamBranding(primaryColor: Color(red: 0/255, green: 128/255, blue: 198/255),
                                        secondaryColor: Color(red: 255/255, green: 194/255, blue: 14/255),
                                        helmetImageName: "helmet_lac")
        case "LV": return TeamBranding(primaryColor: Color.black,
                                       secondaryColor: Color(red: 165/255, green: 172/255, blue: 175/255),
                                       helmetImageName: "helmet_lv")
        case "DEN": return TeamBranding(primaryColor: Color(red: 251/255, green: 79/255, blue: 20/255),
                                        secondaryColor: Color(red: 0/255, green: 34/255, blue: 68/255),
                                        helmetImageName: "helmet_den")

        default: return TeamBranding(primaryColor: .gray, secondaryColor: .white, helmetImageName: "helmet_default")
        }
    }
}

/// View displaying a team helmet logo.
struct TeamHelmetView: View {
    let teamAbbreviation: String
    let size: CGFloat

    var body: some View {
        let branding = TeamBranding.branding(for: teamAbbreviation)

        Circle()
            .fill(
                LinearGradient(
                    colors: [branding.primaryColor, branding.secondaryColor.opacity(0.7)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .frame(width: size, height: size)
            .overlay {
                Text(teamAbbreviation)
                    .font(.system(size: size * 0.35, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
                    .shadow(color: .black.opacity(0.3), radius: 2, x: 0, y: 1)
            }
            .shadow(color: branding.primaryColor.opacity(0.3), radius: 4, x: 0, y: 2)
    }
}
