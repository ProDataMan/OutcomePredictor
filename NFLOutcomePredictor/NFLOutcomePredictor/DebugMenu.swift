import SwiftUI

/// Debug menu for testing error handling.
struct DebugMenu: View {
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            List {
                Section("Test Error Handling") {
                    Button("Network Error") {
                        simulateNetworkError()
                    }

                    Button("Decoding Error") {
                        simulateDecodingError()
                    }

                    Button("Generic Error") {
                        simulateGenericError()
                    }

                    Button("Custom Error with Context") {
                        simulateCustomError()
                    }
                }

                Section("Info") {
                    Text("These buttons trigger error dialogs to test the 'Awe Snap this is Bull Shark' error handling.")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .navigationTitle("Debug Menu")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }

    private func simulateNetworkError() {
        let error = URLError(.notConnectedToInternet)
        ErrorHandler.shared.handle(error, context: "Testing network connectivity")
    }

    private func simulateDecodingError() {
        let error = DecodingError.dataCorrupted(
            DecodingError.Context(
                codingPath: [],
                debugDescription: "Invalid JSON response from server"
            )
        )
        ErrorHandler.shared.handle(error, context: "Parsing game prediction response")
    }

    private func simulateGenericError() {
        struct TestError: Error, LocalizedError {
            var errorDescription: String? {
                "Something unexpected happened while processing your request"
            }
        }

        ErrorHandler.shared.handle(TestError(), context: "")
    }

    private func simulateCustomError() {
        struct CustomError: Error, LocalizedError {
            var errorDescription: String? {
                "The server returned an invalid response for the Chiefs vs Raiders game"
            }
        }

        ErrorHandler.shared.handle(
            CustomError(),
            context: "Making prediction for Week 13, 2024 season"
        )
    }
}

#Preview {
    DebugMenu()
}
