import SwiftUI
import OutcomePredictorAPI

/// Feedback button that can be added to any view's toolbar or as a floating button.
struct FeedbackButton: View {
    @State private var showingFeedbackForm = false
    let pageName: String

    var body: some View {
        Button {
            showingFeedbackForm = true
        } label: {
            Image(systemName: "exclamationmark.bubble")
                .font(.system(size: 16))
        }
        .sheet(isPresented: $showingFeedbackForm) {
            FeedbackFormView(pageName: pageName)
        }
    }
}

/// Feedback form sheet for submitting user feedback.
struct FeedbackFormView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var dataManager = DataManager.shared

    let pageName: String

    @State private var feedbackText = ""
    @State private var isSubmitting = false
    @State private var submitError: String?
    @State private var showingSuccess = false
    @State private var userId = UserDefaults.standard.string(forKey: "userId") ?? ""

    var body: some View {
        NavigationView {
            Form {
                Section {
                    TextField("Your Name or Email (optional)", text: $userId)
                        .textContentType(.emailAddress)
                        .autocapitalization(.none)
                        .disableAutocorrection(true)
                } header: {
                    Text("Contact Info")
                } footer: {
                    Text("We'll use this to follow up if needed")
                }

                Section {
                    TextEditor(text: $feedbackText)
                        .frame(minHeight: 150)
                        .overlay(alignment: .topLeading) {
                            if feedbackText.isEmpty {
                                Text("Share your feedback, suggestions, or report issues...")
                                    .foregroundColor(.secondary)
                                    .padding(.top, 8)
                                    .padding(.leading, 5)
                                    .allowsHitTesting(false)
                            }
                        }
                } header: {
                    Text("Feedback")
                }

                if let error = submitError {
                    Section {
                        Text(error)
                            .foregroundColor(.red)
                            .font(.caption)
                    }
                }
            }
            .navigationTitle("Send Feedback")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .disabled(isSubmitting)
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button {
                        submitFeedback()
                    } label: {
                        if isSubmitting {
                            ProgressView()
                        } else {
                            Text("Send")
                                .fontWeight(.semibold)
                        }
                    }
                    .disabled(feedbackText.trimmed().isEmpty || isSubmitting)
                }
            }
            .alert("Thank You!", isPresented: $showingSuccess) {
                Button("OK") {
                    dismiss()
                }
            } message: {
                Text("Your feedback has been submitted successfully. We appreciate your input!")
            }
        }
    }

    private func submitFeedback() {
        // Use a default userId if empty
        let submitterId = userId.trimmed().isEmpty ? "anonymous" : userId.trimmed()

        // Save userId for future use
        UserDefaults.standard.set(submitterId, forKey: "userId")

        Task {
            isSubmitting = true
            submitError = nil

            do {
                _ = try await dataManager.submitFeedback(
                    userId: submitterId,
                    page: pageName,
                    feedbackText: feedbackText.trimmed()
                )

                await MainActor.run {
                    isSubmitting = false
                    showingSuccess = true
                }
            } catch {
                await MainActor.run {
                    isSubmitting = false
                    submitError = "Failed to submit feedback: \(error.localizedDescription)"
                }
            }
        }
    }
}

/// Admin feedback view for viewing all submitted feedback.
struct AdminFeedbackView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var dataManager = DataManager.shared

    @State private var feedbacks: [FeedbackDTO] = []
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var adminUserId = UserDefaults.standard.string(forKey: "adminUserId") ?? ""
    @State private var isAuthenticated = false
    @State private var unreadCount = 0
    @State private var selectedFeedback: Set<String> = []

    var body: some View {
        NavigationView {
            Group {
                if !isAuthenticated {
                    authenticationView
                } else if isLoading {
                    ProgressView("Loading feedback...")
                } else if let error = errorMessage {
                    VStack(spacing: 16) {
                        Image(systemName: "exclamationmark.triangle")
                            .font(.system(size: 48))
                            .foregroundColor(.orange)
                        Text(error)
                            .multilineTextAlignment(.center)
                        Button("Retry") {
                            loadFeedback()
                        }
                        .buttonStyle(.bordered)
                    }
                    .padding()
                } else if feedbacks.isEmpty {
                    VStack(spacing: 16) {
                        Image(systemName: "checkmark.circle")
                            .font(.system(size: 48))
                            .foregroundColor(.green)
                        Text("No feedback yet")
                        Text("Check back later for user feedback")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                } else {
                    feedbackList
                }
            }
            .navigationTitle("User Feedback")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                if isAuthenticated {
                    ToolbarItem(placement: .cancellationAction) {
                        Button("Close") {
                            dismiss()
                        }
                    }

                    ToolbarItem(placement: .primaryAction) {
                        if !selectedFeedback.isEmpty {
                            Button("Mark Read (\(selectedFeedback.count))") {
                                markSelectedAsRead()
                            }
                        }
                    }
                }
            }
            .refreshable {
                if isAuthenticated {
                    loadFeedback()
                }
            }
        }
    }

    private var authenticationView: some View {
        VStack(spacing: 20) {
            Image(systemName: "lock.shield")
                .font(.system(size: 64))
                .foregroundColor(.blue)

            Text("Admin Access Required")
                .font(.title2)
                .fontWeight(.bold)

            Text("Enter your admin user ID to view feedback")
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)

            TextField("Admin User ID", text: $adminUserId)
                .textFieldStyle(.roundedBorder)
                .autocapitalization(.none)
                .disableAutocorrection(true)
                .padding(.horizontal, 32)

            Button("Authenticate") {
                authenticate()
            }
            .buttonStyle(.borderedProminent)
            .disabled(adminUserId.trimmed().isEmpty)
        }
        .padding()
    }

    private var feedbackList: some View {
        List {
            Section {
                HStack {
                    Text("Total: \(feedbacks.count)")
                    Spacer()
                    Text("Unread: \(unreadCount)")
                        .foregroundColor(.red)
                        .fontWeight(unreadCount > 0 ? .bold : .regular)
                }
                .font(.caption)
            }

            ForEach(feedbacks) { feedback in
                FeedbackRow(
                    feedback: feedback,
                    isSelected: selectedFeedback.contains(feedback.id)
                )
                .contentShape(Rectangle())
                .onTapGesture {
                    if selectedFeedback.contains(feedback.id) {
                        selectedFeedback.remove(feedback.id)
                    } else {
                        selectedFeedback.insert(feedback.id)
                    }
                }
            }
        }
    }

    private func authenticate() {
        let trimmedId = adminUserId.trimmed()
        guard !trimmedId.isEmpty else { return }

        UserDefaults.standard.set(trimmedId, forKey: "adminUserId")
        isAuthenticated = true
        loadFeedback()
    }

    private func loadFeedback() {
        Task {
            isLoading = true
            errorMessage = nil

            do {
                let loadedFeedbacks = try await dataManager.fetchFeedback(userId: adminUserId)
                let count = try await dataManager.fetchUnreadCount(userId: adminUserId)

                await MainActor.run {
                    feedbacks = loadedFeedbacks
                    unreadCount = count
                    isLoading = false
                }
            } catch {
                await MainActor.run {
                    if error.localizedDescription.contains("401") || error.localizedDescription.contains("unauthorized") {
                        errorMessage = "Invalid admin credentials"
                        isAuthenticated = false
                    } else {
                        errorMessage = "Failed to load feedback: \(error.localizedDescription)"
                    }
                    isLoading = false
                }
            }
        }
    }

    private func markSelectedAsRead() {
        let idsToMark = Array(selectedFeedback)

        Task {
            do {
                try await dataManager.markFeedbackAsRead(feedbackIds: idsToMark)

                await MainActor.run {
                    for id in idsToMark {
                        if let index = feedbacks.firstIndex(where: { $0.id == id }) {
                            var updatedFeedback = feedbacks[index]
                            // Can't mutate directly, need to update the array
                            feedbacks[index] = FeedbackDTO(
                                id: updatedFeedback.id,
                                userId: updatedFeedback.userId,
                                page: updatedFeedback.page,
                                platform: updatedFeedback.platform,
                                feedbackText: updatedFeedback.feedbackText,
                                appVersion: updatedFeedback.appVersion,
                                deviceModel: updatedFeedback.deviceModel,
                                createdAt: updatedFeedback.createdAt,
                                isRead: true
                            )
                        }
                    }
                    selectedFeedback.removeAll()
                    unreadCount = feedbacks.filter { !$0.isRead }.count
                }
            } catch {
                await MainActor.run {
                    errorMessage = "Failed to mark as read: \(error.localizedDescription)"
                }
            }
        }
    }
}

/// Row view for displaying a single feedback item.
struct FeedbackRow: View {
    let feedback: FeedbackDTO
    let isSelected: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: feedback.platform == "iOS" ? "applelogo" : "android")
                    .foregroundColor(feedback.platform == "iOS" ? .blue : .green)

                Text(feedback.page)
                    .font(.headline)

                Spacer()

                if !feedback.isRead {
                    Circle()
                        .fill(Color.red)
                        .frame(width: 8, height: 8)
                }

                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.blue)
                }
            }

            Text(feedback.feedbackText)
                .font(.body)
                .lineLimit(3)

            HStack {
                Label(feedback.userId, systemImage: "person")
                    .font(.caption)
                    .foregroundColor(.secondary)

                Spacer()

                Text(feedback.createdAt, style: .relative)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            if let version = feedback.appVersion, let device = feedback.deviceModel {
                Text("\(device) · v\(version)")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
        }
        .padding(.vertical, 4)
        .background(isSelected ? Color.accentColor.opacity(0.1) : Color.clear)
        .cornerRadius(8)
    }
}

// Helper extension for String trimming
extension String {
    func trimmed() -> String {
        return self.trimmingCharacters(in: .whitespacesAndNewlines)
    }
}

#Preview("Feedback Button") {
    NavigationView {
        VStack {
            Text("Sample Page")
        }
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                FeedbackButton(pageName: "Sample Page")
            }
        }
    }
}

#Preview("Admin View") {
    AdminFeedbackView()
}
