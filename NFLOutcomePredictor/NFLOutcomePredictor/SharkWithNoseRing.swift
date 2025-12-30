import SwiftUI
import AVKit

/// Custom shark view with Bull Shark video
struct SharkWithNoseRing: View {
    let size: CGFloat
    @State private var player: AVPlayer?

    var body: some View {
        ZStack {
            if let player = player {
                // Video player for Bull Shark animation
                // Use 9:16 aspect ratio to crop black side margins
                VideoPlayer(player: player)
                    .aspectRatio(9/16, contentMode: .fill)
                    .frame(width: size, height: size)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .onAppear {
                        player.play()
                    }
                    .onDisappear {
                        player.pause()
                        cleanupPlayer()
                    }
            } else {
                // Fallback to static image if video fails to load
                Image("BullShark")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: size, height: size)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
            }
        }
        .onAppear {
            setupPlayer()
        }
    }

    private func setupPlayer() {
        guard let videoURL = Bundle.main.url(forResource: "BullShark", withExtension: "mp4") else {
            print("⚠️ BullShark.mp4 not found in bundle")
            return
        }

        let playerItem = AVPlayerItem(url: videoURL)
        let newPlayer = AVPlayer(playerItem: playerItem)

        // Play once without looping
        // Removed: loopObserver for repeating video

        player = newPlayer
    }

    private func cleanupPlayer() {
        player = nil
    }
}

#Preview {
    VStack(spacing: 40) {
        SharkWithNoseRing(size: 80)
        SharkWithNoseRing(size: 120)
        SharkWithNoseRing(size: 200)
    }
}
