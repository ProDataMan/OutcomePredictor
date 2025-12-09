import SwiftUI

// App Icon Generator - Run this in a Playground or create a macOS app to export
struct AppIconGenerator: View {
    let size: CGFloat = 1024 // App Store size

    var body: some View {
        ZStack {
            // Background gradient
            LinearGradient(
                colors: [
                    Color(red: 0.1, green: 0.2, blue: 0.4),
                    Color(red: 0.05, green: 0.1, blue: 0.25)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )

            // Circular background element
            Circle()
                .fill(
                    RadialGradient(
                        colors: [
                            Color.white.opacity(0.15),
                            Color.clear
                        ],
                        center: .center,
                        startRadius: 0,
                        endRadius: size * 0.5
                    )
                )
                .frame(width: size * 0.8, height: size * 0.8)

            VStack(spacing: size * 0.08) {
                // Top: Football
                FootballIcon(size: size * 0.22)
                    .offset(x: -size * 0.15, y: -size * 0.05)

                // Middle: Crystal ball / prediction orb
                PredictionOrb(size: size * 0.35)

                // Bottom row: Basketball and Soccer ball
                HStack(spacing: size * 0.15) {
                    BasketballIcon(size: size * 0.18)
                    SoccerBallIcon(size: size * 0.18)
                }
                .offset(y: size * 0.02)
            }

            // AI/Tech accent
            ZStack {
                Circle()
                    .stroke(Color.cyan.opacity(0.6), lineWidth: 3)
                    .frame(width: size * 0.65, height: size * 0.65)

                // Data points
                ForEach(0..<8) { i in
                    Circle()
                        .fill(Color.cyan.opacity(0.8))
                        .frame(width: 8, height: 8)
                        .offset(
                            x: cos(Double(i) * .pi / 4) * size * 0.325,
                            y: sin(Double(i) * .pi / 4) * size * 0.325
                        )
                }
            }
            .opacity(0.4)
        }
        .frame(width: size, height: size)
    }
}

struct FootballIcon: View {
    let size: CGFloat

    var body: some View {
        ZStack {
            // Football shape
            Ellipse()
                .fill(
                    LinearGradient(
                        colors: [
                            Color(red: 0.6, green: 0.3, blue: 0.1),
                            Color(red: 0.4, green: 0.2, blue: 0.05)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: size, height: size * 0.6)

            // Laces
            VStack(spacing: size * 0.05) {
                ForEach(0..<4) { _ in
                    Rectangle()
                        .fill(Color.white)
                        .frame(width: size * 0.25, height: size * 0.04)
                }
            }
        }
    }
}

struct BasketballIcon: View {
    let size: CGFloat

    var body: some View {
        ZStack {
            Circle()
                .fill(
                    LinearGradient(
                        colors: [
                            Color.orange,
                            Color(red: 0.8, green: 0.4, blue: 0)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )

            // Lines
            Path { path in
                path.move(to: CGPoint(x: size * 0.5, y: 0))
                path.addLine(to: CGPoint(x: size * 0.5, y: size))
            }
            .stroke(Color.black.opacity(0.3), lineWidth: 2)

            Path { path in
                path.addArc(
                    center: CGPoint(x: size * 0.5, y: size * 0.5),
                    radius: size * 0.35,
                    startAngle: .degrees(-90),
                    endAngle: .degrees(90),
                    clockwise: false
                )
            }
            .stroke(Color.black.opacity(0.3), lineWidth: 2)
        }
        .frame(width: size, height: size)
    }
}

struct SoccerBallIcon: View {
    let size: CGFloat

    var body: some View {
        ZStack {
            Circle()
                .fill(Color.white)

            // Pentagon pattern
            Path { path in
                let center = CGPoint(x: size * 0.5, y: size * 0.4)
                let radius = size * 0.15

                for i in 0..<5 {
                    let angle = Double(i) * 2 * .pi / 5 - .pi / 2
                    let point = CGPoint(
                        x: center.x + cos(angle) * radius,
                        y: center.y + sin(angle) * radius
                    )
                    if i == 0 {
                        path.move(to: point)
                    } else {
                        path.addLine(to: point)
                    }
                }
                path.closeSubpath()
            }
            .fill(Color.black)

            // Hexagons (simplified)
            ForEach(0..<5) { i in
                let angle = Double(i) * 2 * .pi / 5 - .pi / 2
                Path { path in
                    let center = CGPoint(
                        x: size * 0.5 + cos(angle) * size * 0.28,
                        y: size * 0.4 + sin(angle) * size * 0.28
                    )
                    let radius = size * 0.12

                    for j in 0..<6 {
                        let hexAngle = Double(j) * 2 * .pi / 6
                        let point = CGPoint(
                            x: center.x + cos(hexAngle) * radius,
                            y: center.y + sin(hexAngle) * radius
                        )
                        if j == 0 {
                            path.move(to: point)
                        } else {
                            path.addLine(to: point)
                        }
                    }
                    path.closeSubpath()
                }
                .fill(Color.black)
            }
        }
        .frame(width: size, height: size)
    }
}

struct PredictionOrb: View {
    let size: CGFloat

    var body: some View {
        ZStack {
            // Outer glow
            Circle()
                .fill(
                    RadialGradient(
                        colors: [
                            Color.cyan.opacity(0.6),
                            Color.purple.opacity(0.3),
                            Color.clear
                        ],
                        center: .center,
                        startRadius: 0,
                        endRadius: size * 0.6
                    )
                )
                .frame(width: size * 1.2, height: size * 1.2)

            // Main orb
            Circle()
                .fill(
                    RadialGradient(
                        colors: [
                            Color.white.opacity(0.9),
                            Color.cyan.opacity(0.7),
                            Color.purple.opacity(0.5)
                        ],
                        center: UnitPoint(x: 0.3, y: 0.3),
                        startRadius: 0,
                        endRadius: size * 0.5
                    )
                )

            // Glass reflection
            Circle()
                .fill(
                    LinearGradient(
                        colors: [
                            Color.white.opacity(0.6),
                            Color.clear
                        ],
                        startPoint: .topLeading,
                        endPoint: .center
                    )
                )
                .frame(width: size * 0.4, height: size * 0.4)
                .offset(x: -size * 0.15, y: -size * 0.15)

            // Percentage symbol
            Text("%")
                .font(.system(size: size * 0.35, weight: .bold, design: .rounded))
                .foregroundStyle(
                    LinearGradient(
                        colors: [Color.white, Color.white.opacity(0.8)],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .shadow(color: .black.opacity(0.3), radius: 2, x: 0, y: 2)
        }
        .frame(width: size, height: size)
    }
}

#Preview {
    AppIconGenerator()
}
