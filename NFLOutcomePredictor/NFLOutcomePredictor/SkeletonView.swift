import SwiftUI

// MARK: - Skeleton View Modifier

struct ShimmerEffect: ViewModifier {
    @State private var phase: CGFloat = 0

    func body(content: Content) -> some View {
        content
            .overlay(
                LinearGradient(
                    gradient: Gradient(colors: [
                        Color.gray.opacity(0.3),
                        Color.gray.opacity(0.1),
                        Color.gray.opacity(0.3)
                    ]),
                    startPoint: .leading,
                    endPoint: .trailing
                )
                .offset(x: phase)
                .mask(content)
            )
            .onAppear {
                withAnimation(Animation.linear(duration: 1.5).repeatForever(autoreverses: false)) {
                    phase = 300
                }
            }
    }
}

extension View {
    func shimmer() -> some View {
        modifier(ShimmerEffect())
    }
}

// MARK: - Skeleton Shapes

struct SkeletonRectangle: View {
    var width: CGFloat? = nil
    var height: CGFloat
    var cornerRadius: CGFloat = 8

    var body: some View {
        RoundedRectangle(cornerRadius: cornerRadius)
            .fill(Color(UIColor.systemGray5))
            .frame(width: width, height: height)
            .shimmer()
    }
}

struct SkeletonCircle: View {
    var size: CGFloat

    var body: some View {
        Circle()
            .fill(Color(UIColor.systemGray5))
            .frame(width: size, height: size)
            .shimmer()
    }
}

// MARK: - Skeleton Game Card

struct SkeletonGameCard: View {
    var body: some View {
        VStack(spacing: 8) {
            // Date placeholder
            SkeletonRectangle(width: 80, height: 12, cornerRadius: 4)

            // Teams placeholder
            HStack(spacing: 12) {
                VStack(spacing: 4) {
                    SkeletonCircle(size: 30)
                    SkeletonRectangle(width: 30, height: 10, cornerRadius: 4)
                }

                SkeletonRectangle(width: 12, height: 10, cornerRadius: 4)

                VStack(spacing: 4) {
                    SkeletonCircle(size: 30)
                    SkeletonRectangle(width: 30, height: 10, cornerRadius: 4)
                }
            }

            // Week placeholder
            SkeletonRectangle(width: 50, height: 10, cornerRadius: 4)
        }
        .padding(12)
        .frame(width: 140)
        .background(Color(UIColor.systemGray6))
        .cornerRadius(12)
    }
}

// MARK: - Skeleton Team Row

struct SkeletonTeamRow: View {
    var body: some View {
        HStack(spacing: 12) {
            SkeletonCircle(size: 50)

            VStack(alignment: .leading, spacing: 6) {
                SkeletonRectangle(width: 120, height: 14, cornerRadius: 4)
                SkeletonRectangle(width: 80, height: 10, cornerRadius: 4)
            }

            Spacer()
        }
        .padding()
        .background(Color(UIColor.systemGray6))
        .cornerRadius(12)
    }
}

// MARK: - Skeleton Prediction Card

struct SkeletonPredictionCard: View {
    var body: some View {
        VStack(spacing: 16) {
            // Winner section
            VStack(spacing: 8) {
                SkeletonCircle(size: 80)
                SkeletonRectangle(width: 150, height: 16, cornerRadius: 4)
                SkeletonRectangle(width: 120, height: 12, cornerRadius: 4)
            }
            .padding()
            .background(Color.green.opacity(0.1))
            .cornerRadius(12)

            // Analysis section
            VStack(alignment: .leading, spacing: 8) {
                SkeletonRectangle(width: 100, height: 14, cornerRadius: 4)
                SkeletonRectangle(height: 12, cornerRadius: 4)
                SkeletonRectangle(height: 12, cornerRadius: 4)
                SkeletonRectangle(width: 200, height: 12, cornerRadius: 4)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding()
            .background(Color(UIColor.systemGray6))
            .cornerRadius(12)

            // Confidence section
            VStack(spacing: 8) {
                HStack {
                    SkeletonRectangle(width: 80, height: 12, cornerRadius: 4)
                    Spacer()
                    SkeletonRectangle(width: 40, height: 12, cornerRadius: 4)
                }
                SkeletonRectangle(height: 8, cornerRadius: 4)
            }
            .padding()
            .background(Color(UIColor.systemGray6))
            .cornerRadius(12)
        }
    }
}

// MARK: - Skeleton Standings Row

struct SkeletonStandingsRow: View {
    var body: some View {
        HStack(spacing: 12) {
            // Rank
            SkeletonRectangle(width: 20, height: 12, cornerRadius: 4)

            // Team
            SkeletonCircle(size: 32)
            SkeletonRectangle(width: 60, height: 12, cornerRadius: 4)

            Spacer()

            // Stats
            SkeletonRectangle(width: 40, height: 12, cornerRadius: 4)
            SkeletonRectangle(width: 30, height: 12, cornerRadius: 4)
        }
        .padding(.vertical, 8)
        .padding(.horizontal)
    }
}

// MARK: - Skeleton List

struct SkeletonList<Content: View>: View {
    let count: Int
    let content: () -> Content

    init(count: Int = 5, @ViewBuilder content: @escaping () -> Content) {
        self.count = count
        self.content = content
    }

    var body: some View {
        VStack(spacing: 12) {
            ForEach(0..<count, id: \.self) { _ in
                content()
            }
        }
    }
}

#Preview("Game Cards") {
    ScrollView(.horizontal) {
        HStack(spacing: 12) {
            ForEach(0..<3) { _ in
                SkeletonGameCard()
            }
        }
        .padding()
    }
}

#Preview("Team Rows") {
    VStack(spacing: 12) {
        ForEach(0..<3) { _ in
            SkeletonTeamRow()
        }
    }
    .padding()
}

#Preview("Prediction Card") {
    SkeletonPredictionCard()
        .padding()
}

#Preview("Standings") {
    VStack {
        ForEach(0..<5) { _ in
            SkeletonStandingsRow()
        }
    }
}
