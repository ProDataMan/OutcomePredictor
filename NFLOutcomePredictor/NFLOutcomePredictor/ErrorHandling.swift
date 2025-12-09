import SwiftUI
import Combine

/// Global error container for unexpected exceptions.
@MainActor
class ErrorHandler: ObservableObject {
    @Published var currentError: AppError?

    static let shared = ErrorHandler()

    private init() {}

    func handle(_ error: Error, context: String = "") {
        currentError = AppError(
            error: error,
            context: context,
            timestamp: Date()
        )
    }

    func clear() {
        currentError = nil
    }
}

/// Wrapped error with context for display.
struct AppError: Identifiable {
    let id = UUID()
    let error: Error
    let context: String
    let timestamp: Date

    var localizedDescription: String {
        error.localizedDescription
    }

    var fullDescription: String {
        """
        Error: \(error.localizedDescription)
        Context: \(context.isEmpty ? "None" : context)
        Time: \(timestamp.formatted(date: .long, time: .standard))
        Type: \(String(describing: type(of: error)))
        """
    }

    var stackTrace: String {
        // In Swift, we don't have direct access to stack traces like in other languages
        // but we can show the error details
        """
        \(fullDescription)

        Technical Details:
        \(String(reflecting: error))
        """
    }
}

/// Error view overlay showing "Awe Snap this is Bull Shark".
struct ErrorOverlay: View {
    let error: AppError
    let onDismiss: () -> Void

    @State private var showDetails = false

    var body: some View {
        ZStack {
            // Dimmed background
            Color.black.opacity(0.4)
                .ignoresSafeArea()

            VStack(spacing: 0) {
                if showDetails {
                    // Details view
                    ErrorDetailsView(error: error, onClose: {
                        showDetails = false
                    })
                } else {
                    // Simple error message
                    ErrorMessageView(
                        error: error,
                        onClose: onDismiss,
                        onShowDetails: {
                            showDetails = true
                        }
                    )
                }
            }
        }
    }
}

/// Simple error message with Close and Show Details buttons.
struct ErrorMessageView: View {
    let error: AppError
    let onClose: () -> Void
    let onShowDetails: () -> Void

    @State private var showFirstMessage = false
    @State private var showShark = false
    @State private var showSecondMessage = false

    var body: some View {
        VStack(spacing: 24) {
            // Animated messages and shark
            VStack(spacing: 12) {
                // First message: "Awe Snap, Something bad happened!"
                if showFirstMessage {
                    Text("Awe Snap, Something bad happened!")
                        .font(.title2)
                        .fontWeight(.bold)
                        .multilineTextAlignment(.center)
                        .transition(.asymmetric(
                            insertion: .scale.combined(with: .opacity),
                            removal: .move(edge: .leading).combined(with: .opacity)
                        ))
                }

                // Shark with nose ring
                if showShark {
                    SharkWithNoseRing(size: 80)
                        .transition(.scale.combined(with: .opacity))
                }

                // Second message: "This is Bull Shark!"
                if showSecondMessage {
                    Text("This is Bull Shark!")
                        .font(.title2)
                        .fontWeight(.bold)
                        .multilineTextAlignment(.center)
                        .transition(.scale.combined(with: .opacity))
                }

                // Error description (always visible after animations)
                if showSecondMessage {
                    Text(error.localizedDescription)
                        .font(.body)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                        .transition(.opacity)
                }
            }
            .frame(minHeight: 200)

            // Buttons (always visible)
            VStack(spacing: 12) {
                Button(action: onClose) {
                    Text("Close")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.accentColor)
                        .foregroundColor(.white)
                        .cornerRadius(12)
                }

                Button(action: onShowDetails) {
                    HStack {
                        Image(systemName: "info.circle")
                        Text("Show Details")
                    }
                    .font(.subheadline)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color(.systemGray5))
                    .foregroundColor(.primary)
                    .cornerRadius(12)
                }
            }
            .padding(.horizontal, 24)
        }
        .padding(32)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color(.systemBackground))
                .shadow(color: .black.opacity(0.2), radius: 20, x: 0, y: 10)
        )
        .padding(40)
        .onAppear {
            startAnimation()
        }
    }

    private func startAnimation() {
        // Show first message immediately
        withAnimation(.easeOut(duration: 0.4)) {
            showFirstMessage = true
        }

        // Hide first message and show shark after 1.2 seconds
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) {
            withAnimation(.easeIn(duration: 0.3)) {
                showFirstMessage = false
            }

            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                withAnimation(.spring(response: 0.6, dampingFraction: 0.7)) {
                    showShark = true
                }
            }
        }

        // Show second message after 2.0 seconds
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            withAnimation(.easeOut(duration: 0.4)) {
                showSecondMessage = true
            }
        }
    }
}

/// Detailed error view with full stack trace.
struct ErrorDetailsView: View {
    let error: AppError
    let onClose: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Error Details")
                        .font(.title2)
                        .fontWeight(.bold)

                    Text(error.timestamp.formatted(date: .abbreviated, time: .standard))
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                Spacer()

                Button(action: onClose) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.title2)
                        .foregroundColor(.secondary)
                }
            }
            .padding()
            .background(Color(.systemGray6))

            // Scrollable details
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    // Error message
                    DetailSection(title: "Error Message") {
                        Text(error.localizedDescription)
                            .font(.body)
                    }

                    // Context
                    if !error.context.isEmpty {
                        DetailSection(title: "Context") {
                            Text(error.context)
                                .font(.body)
                        }
                    }

                    // Stack trace
                    DetailSection(title: "Stack Trace") {
                        Text(error.stackTrace)
                            .font(.system(.caption, design: .monospaced))
                            .textSelection(.enabled)
                    }

                    // Copy button
                    Button(action: {
                        UIPasteboard.general.string = error.stackTrace
                    }) {
                        HStack {
                            Image(systemName: "doc.on.doc")
                            Text("Copy Error Details")
                        }
                        .font(.subheadline)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.accentColor)
                        .foregroundColor(.white)
                        .cornerRadius(12)
                    }
                }
                .padding()
            }
        }
        .frame(maxWidth: .infinity, maxHeight: 600)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color(.systemBackground))
                .shadow(color: .black.opacity(0.2), radius: 20, x: 0, y: 10)
        )
        .padding(40)
    }
}

/// Reusable detail section.
struct DetailSection<Content: View>: View {
    let title: String
    @ViewBuilder let content: () -> Content

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.headline)
                .foregroundColor(.primary)

            content()
                .padding()
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color(.systemGray6))
                .cornerRadius(8)
        }
    }
}

/// View modifier to handle errors globally.
struct ErrorHandlingModifier: ViewModifier {
    @ObservedObject var errorHandler = ErrorHandler.shared

    func body(content: Content) -> some View {
        content
            .overlay {
                if let error = errorHandler.currentError {
                    ErrorOverlay(
                        error: error,
                        onDismiss: {
                            errorHandler.clear()
                        }
                    )
                    .transition(.opacity)
                    .zIndex(999)
                }
            }
    }
}

extension View {
    /// Adds global error handling to a view.
    func withErrorHandling() -> some View {
        modifier(ErrorHandlingModifier())
    }
}

/// Helper for wrapping async operations with error handling.
extension View {
    func handleErrors(context: String = "", perform: @escaping () async throws -> Void) -> some View {
        Task {
            do {
                try await perform()
            } catch {
                await MainActor.run {
                    ErrorHandler.shared.handle(error, context: context)
                }
            }
        }
        return self
    }
}
