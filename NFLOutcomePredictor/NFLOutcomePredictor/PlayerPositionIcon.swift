import SwiftUI

/// Position-specific silhouette icons for NFL players
struct PlayerPositionIcon: View {
    let position: String
    let size: CGFloat

    var body: some View {
        ZStack {
            Circle()
                .fill(LinearGradient(
                    colors: [positionColor.opacity(0.3), positionColor.opacity(0.1)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                ))

            positionIcon
                .font(.system(size: size * 0.5, weight: .bold))
                .foregroundColor(positionColor)
        }
        .frame(width: size, height: size)
    }

    private var positionIcon: some View {
        Group {
            switch normalizedPosition {
            // Quarterback - throwing motion
            case "QB":
                Image(systemName: "figure.basketball")
                    .rotationEffect(.degrees(-20))

            // Running Back - running motion
            case "RB", "FB":
                Image(systemName: "figure.run")

            // Wide Receiver - catching motion
            case "WR":
                Image(systemName: "figure.jumprope")

            // Tight End - blocking/receiving
            case "TE":
                Image(systemName: "figure.strengthtraining.traditional")

            // Offensive Line - blocking stance
            case "OL", "OT", "OG", "C":
                Image(systemName: "shield.fill")

            // Defensive Line - rushing
            case "DL", "DE", "DT":
                Image(systemName: "figure.martial.arts")

            // Linebacker - ready stance
            case "LB", "MLB", "OLB", "ILB":
                Image(systemName: "figure.boxing")

            // Cornerback/Safety - coverage
            case "CB", "S", "SS", "FS", "DB":
                Image(systemName: "figure.surfing")

            // Kicker/Punter - kicking motion
            case "K", "P":
                Image(systemName: "figure.soccer")

            // Long Snapper
            case "LS":
                Image(systemName: "figure.american.football")

            // Default - generic player
            default:
                Image(systemName: "figure.american.football")
            }
        }
    }

    private var normalizedPosition: String {
        // Normalize position string by removing numbers and trimming
        position.trimmingCharacters(in: .whitespacesAndNewlines)
            .components(separatedBy: CharacterSet.decimalDigits)
            .joined()
            .uppercased()
    }

    private var positionColor: Color {
        switch normalizedPosition {
        // Offensive positions - blue tones
        case "QB":
            return .blue
        case "RB", "FB":
            return .cyan
        case "WR":
            return .teal
        case "TE":
            return .mint
        case "OL", "OT", "OG", "C":
            return .indigo

        // Defensive positions - red tones
        case "DL", "DE", "DT":
            return .red
        case "LB", "MLB", "OLB", "ILB":
            return .orange
        case "CB", "S", "SS", "FS", "DB":
            return .pink

        // Special teams - green tones
        case "K", "P", "LS":
            return .green

        default:
            return .gray
        }
    }
}

#Preview {
    VStack(spacing: 20) {
        HStack(spacing: 16) {
            PlayerPositionIcon(position: "QB", size: 60)
            PlayerPositionIcon(position: "RB", size: 60)
            PlayerPositionIcon(position: "WR", size: 60)
            PlayerPositionIcon(position: "TE", size: 60)
        }

        HStack(spacing: 16) {
            PlayerPositionIcon(position: "DL", size: 60)
            PlayerPositionIcon(position: "LB", size: 60)
            PlayerPositionIcon(position: "CB", size: 60)
            PlayerPositionIcon(position: "S", size: 60)
        }

        HStack(spacing: 16) {
            PlayerPositionIcon(position: "K", size: 60)
            PlayerPositionIcon(position: "P", size: 60)
            PlayerPositionIcon(position: "OL", size: 60)
        }
    }
    .padding()
}
