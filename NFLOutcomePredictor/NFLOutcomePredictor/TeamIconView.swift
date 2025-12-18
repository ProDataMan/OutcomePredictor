import SwiftUI

/// Shows a team image asset if available (named `team_<ABBR>`), otherwise falls back to `TeamHelmetView`.
struct TeamIconView: View {
    let teamAbbreviation: String
    let size: CGFloat

    var body: some View {
        if let img = loadTeamImage() {
            Image(uiImage: img)
                .resizable()
                .scaledToFit()
                .frame(width: size, height: size)
                .clipShape(Circle())
                .shadow(radius: 4)
        } else {
            TeamHelmetView(teamAbbreviation: teamAbbreviation, size: size)
        }
    }

    private func loadTeamImage() -> UIImage? {
        // Try both lowercase and uppercase keys to be flexible with naming
        let candidates = ["team_\(teamAbbreviation.lowercased())", "team_\(teamAbbreviation)"]
        for name in candidates {
            if let img = UIImage(named: name) {
                return img
            }
        }
        return nil
    }
}

#if DEBUG
#Preview("Team Icon") {
    TeamIconView(teamAbbreviation: "KC", size: 80)
}
#endif
