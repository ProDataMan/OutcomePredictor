import SwiftUI

/// Custom shark view with nose ring using SF Symbols and shapes
struct SharkWithNoseRing: View {
    let size: CGFloat

    var body: some View {
        ZStack {
            // Shark emoji as base (largest available shark representation)
            Text("🦈")
                .font(.system(size: size))

            // Nose ring overlay (positioned on the shark's "nose")
            Circle()
                .stroke(Color.yellow, lineWidth: size * 0.04)
                .frame(width: size * 0.15, height: size * 0.15)
                .offset(x: size * 0.15, y: size * 0.1)
        }
    }
}

#Preview {
    VStack(spacing: 40) {
        SharkWithNoseRing(size: 80)
        SharkWithNoseRing(size: 120)
        SharkWithNoseRing(size: 200)
    }
}
