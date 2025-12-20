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
                VideoPlayer(player: player)
                    .frame(width: size, height: size)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .onAppear {
                        player.play()
                    }
                    .onDisappear {
                        player.pause()
                    }
            } else {
                // Fallback to static image if video fails to load
                Image("BullShark")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: size, height: size)
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

        // Loop the video
        NotificationCenter.default.addObserver(
            forName: .AVPlayerItemDidPlayToEndTime,
            object: playerItem,
            queue: .main
        ) { _ in
            newPlayer.seek(to: .zero)
            newPlayer.play()
        }

        player = newPlayer
    }
}

#Preview {
    VStack(spacing: 40) {
        SharkWithNoseRing(size: 80)
        SharkWithNoseRing(size: 120)
        SharkWithNoseRing(size: 200)
    }
}
