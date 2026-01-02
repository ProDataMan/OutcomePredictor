import SwiftUI
import Charts

/// Historical prediction accuracy tracking view.
struct PredictionAccuracyView: View {
    let accuracy: PredictionAccuracyDTO

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Overall Accuracy Header
                overallAccuracySection

                // Weekly Trend Chart
                weeklyTrendSection

                // Confidence Breakdown
                confidenceBreakdownSection

                // Model Info
                modelInfoSection
            }
            .padding(.vertical)
        }
        .navigationTitle("Prediction Accuracy")
        .navigationBarTitleDisplayMode(.inline)
    }

    private var overallAccuracySection: some View {
        VStack(spacing: 16) {
            Text("Overall Accuracy")
                .font(.title2)
                .fontWeight(.bold)

            ZStack {
                Circle()
                    .stroke(Color.gray.opacity(0.2), lineWidth: 20)

                Circle()
                    .trim(from: 0, to: accuracy.overallAccuracy / 100)
                    .stroke(
                        accuracyColor(accuracy.overallAccuracy),
                        style: StrokeStyle(lineWidth: 20, lineCap: .round)
                    )
                    .rotationEffect(.degrees(-90))
                    .animation(.easeInOut(duration: 1.0), value: accuracy.overallAccuracy)

                VStack(spacing: 4) {
                    Text("\(Int(accuracy.overallAccuracy))%")
                        .font(.system(size: 48, weight: .bold))
                        .foregroundColor(accuracyColor(accuracy.overallAccuracy))

                    Text("\(accuracy.correctPredictions) / \(accuracy.totalPredictions)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .frame(width: 200, height: 200)
            .padding()
        }
    }

    private var weeklyTrendSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Weekly Trend")
                .font(.title3)
                .fontWeight(.bold)
                .padding(.horizontal)

            if #available(iOS 16.0, *) {
                Chart(accuracy.weeklyAccuracy) { week in
                    LineMark(
                        x: .value("Week", week.week),
                        y: .value("Accuracy", week.accuracy)
                    )
                    .foregroundStyle(Color.accentColor)

                    AreaMark(
                        x: .value("Week", week.week),
                        y: .value("Accuracy", week.accuracy)
                    )
                    .foregroundStyle(
                        LinearGradient(
                            colors: [Color.accentColor.opacity(0.3), Color.accentColor.opacity(0.1)],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                }
                .chartYScale(domain: 0...100)
                .chartYAxis {
                    AxisMarks(position: .leading) { value in
                        AxisValueLabel {
                            if let intValue = value.as(Int.self) {
                                Text("\(intValue)%")
                            }
                        }
                    }
                }
                .frame(height: 200)
                .padding(.horizontal)
            } else {
                // Fallback for iOS < 16
                WeeklyAccuracyList(weeklyAccuracy: accuracy.weeklyAccuracy)
                    .padding(.horizontal)
            }
        }
    }

    private var confidenceBreakdownSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Accuracy by Confidence")
                .font(.title3)
                .fontWeight(.bold)
                .padding(.horizontal)

            VStack(spacing: 12) {
                ForEach(accuracy.confidenceBreakdown) { breakdown in
                    ConfidenceBreakdownRow(breakdown: breakdown)
                }
            }
            .padding(.horizontal)
        }
    }

    private var modelInfoSection: some View {
        VStack(spacing: 8) {
            Text("Model Version: \(accuracy.modelVersion)")
                .font(.caption)
                .foregroundColor(.secondary)

            Text("Last Updated: \(formattedDate)")
                .font(.caption2)
                .foregroundColor(.secondary)
        }
        .padding()
    }

    private var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: accuracy.lastUpdated)
    }

    private func accuracyColor(_ accuracy: Double) -> Color {
        switch accuracy {
        case 70...100:
            return .green
        case 50..<70:
            return .blue
        case 30..<50:
            return .orange
        default:
            return .red
        }
    }
}

/// Fallback list view for weekly accuracy on iOS < 16.
struct WeeklyAccuracyList: View {
    let weeklyAccuracy: [WeeklyAccuracyDTO]

    var body: some View {
        VStack(spacing: 8) {
            ForEach(weeklyAccuracy) { week in
                HStack {
                    Text("Week \(week.week)")
                        .font(.subheadline)

                    Spacer()

                    Text("\(Int(week.accuracy))%")
                        .font(.subheadline)
                        .fontWeight(.semibold)

                    Text("(\(week.correctPredictions)/\(week.totalGames))")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .padding(.vertical, 8)
                .padding(.horizontal, 12)
                .background(Color(UIColor.systemGray6))
                .cornerRadius(8)
            }
        }
    }
}

/// Row displaying confidence breakdown information.
struct ConfidenceBreakdownRow: View {
    let breakdown: ConfidenceAccuracyDTO

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(breakdown.confidenceRange)
                    .font(.subheadline)
                    .fontWeight(.semibold)

                Spacer()

                Text("\(Int(breakdown.accuracy))%")
                    .font(.subheadline)
                    .fontWeight(.bold)
                    .foregroundColor(accuracyColor)

                Text("(\(breakdown.correctPredictions)/\(breakdown.totalPredictions))")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color.gray.opacity(0.2))
                        .frame(height: 8)

                    RoundedRectangle(cornerRadius: 4)
                        .fill(accuracyColor)
                        .frame(width: geometry.size.width * (breakdown.accuracy / 100), height: 8)
                }
            }
            .frame(height: 8)
        }
        .padding()
        .background(Color(UIColor.systemGray6))
        .cornerRadius(12)
    }

    private var accuracyColor: Color {
        switch breakdown.accuracy {
        case 70...100:
            return .green
        case 50..<70:
            return .blue
        case 30..<50:
            return .orange
        default:
            return .red
        }
    }
}

#Preview {
    NavigationStack {
        PredictionAccuracyView(
            accuracy: PredictionAccuracyDTO(
                overallAccuracy: 67.5,
                totalPredictions: 120,
                correctPredictions: 81,
                weeklyAccuracy: [
                    WeeklyAccuracyDTO(week: 1, season: 2024, accuracy: 62.5, totalGames: 16, correctPredictions: 10),
                    WeeklyAccuracyDTO(week: 2, season: 2024, accuracy: 68.75, totalGames: 16, correctPredictions: 11),
                    WeeklyAccuracyDTO(week: 3, season: 2024, accuracy: 75.0, totalGames: 16, correctPredictions: 12),
                    WeeklyAccuracyDTO(week: 4, season: 2024, accuracy: 71.4, totalGames: 14, correctPredictions: 10),
                    WeeklyAccuracyDTO(week: 5, season: 2024, accuracy: 64.3, totalGames: 14, correctPredictions: 9)
                ],
                confidenceBreakdown: [
                    ConfidenceAccuracyDTO(
                        confidenceRange: "High (70-100%)",
                        accuracy: 78.5,
                        totalPredictions: 42,
                        correctPredictions: 33,
                        minConfidence: 70,
                        maxConfidence: 100
                    ),
                    ConfidenceAccuracyDTO(
                        confidenceRange: "Medium (50-70%)",
                        accuracy: 62.3,
                        totalPredictions: 53,
                        correctPredictions: 33,
                        minConfidence: 50,
                        maxConfidence: 70
                    ),
                    ConfidenceAccuracyDTO(
                        confidenceRange: "Low (0-50%)",
                        accuracy: 60.0,
                        totalPredictions: 25,
                        correctPredictions: 15,
                        minConfidence: 0,
                        maxConfidence: 50
                    )
                ],
                modelVersion: "v2.1.0"
            )
        )
    }
}
