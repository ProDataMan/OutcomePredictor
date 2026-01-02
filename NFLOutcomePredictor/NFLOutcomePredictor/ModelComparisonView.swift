import SwiftUI

/// Model comparison view showing predictions from multiple models.
struct ModelComparisonView: View {
    let comparison: ModelComparisonDTO

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Game Header
                gameHeader

                // Consensus Section
                if let consensus = comparison.consensus {
                    consensusSection(consensus)
                }

                // Individual Models
                modelsSection
            }
            .padding(.vertical)
        }
        .navigationTitle("Model Comparison")
        .navigationBarTitleDisplayMode(.inline)
    }

    private var gameHeader: some View {
        VStack(spacing: 16) {
            Text("Game Matchup")
                .font(.title3)
                .fontWeight(.bold)

            HStack(spacing: 20) {
                VStack {
                    TeamIconView(teamAbbreviation: comparison.game.homeTeam.abbreviation, size: 60)
                    Text(comparison.game.homeTeam.abbreviation)
                        .font(.headline)
                }

                Text("vs")
                    .font(.headline)
                    .foregroundColor(.secondary)

                VStack {
                    TeamIconView(teamAbbreviation: comparison.game.awayTeam.abbreviation, size: 60)
                    Text(comparison.game.awayTeam.abbreviation)
                        .font(.headline)
                }
            }

            Text(formattedDate)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding()
    }

    private func consensusSection(_ consensus: ConsensusDTO) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Consensus Prediction")
                .font(.title3)
                .fontWeight(.bold)
                .padding(.horizontal)

            VStack(spacing: 12) {
                HStack {
                    Text("Predicted Winner")
                        .font(.subheadline)
                        .foregroundColor(.secondary)

                    Spacer()

                    Text(consensus.predictedWinner)
                        .font(.headline)
                        .fontWeight(.bold)
                        .foregroundColor(.accentColor)
                }

                HStack {
                    Text("Model Agreement")
                        .font(.subheadline)
                        .foregroundColor(.secondary)

                    Spacer()

                    Text("\(Int(consensus.agreementPercentage))%")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                }

                HStack {
                    Text("Avg Confidence")
                        .font(.subheadline)
                        .foregroundColor(.secondary)

                    Spacer()

                    Text("\(Int(consensus.averageConfidence))%")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                }

                HStack {
                    Text("Models Analyzed")
                        .font(.subheadline)
                        .foregroundColor(.secondary)

                    Spacer()

                    Text("\(consensus.modelCount)")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                }
            }
            .padding()
            .background(Color(UIColor.systemGray6))
            .cornerRadius(12)
            .padding(.horizontal)
        }
    }

    private var modelsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Individual Models")
                .font(.title3)
                .fontWeight(.bold)
                .padding(.horizontal)

            ForEach(comparison.models) { model in
                ModelCard(model: model, game: comparison.game)
                    .padding(.horizontal)
            }
        }
    }

    private var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: comparison.game.date)
    }
}

/// Card displaying individual model prediction.
struct ModelCard: View {
    let model: PredictionModelDTO
    let game: GameDTO

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Model Header
            HStack {
                VStack(alignment: .leading) {
                    Text(model.modelName)
                        .font(.headline)
                        .fontWeight(.bold)

                    Text("v\(model.modelVersion)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                Spacer()

                if let accuracy = model.accuracy {
                    VStack(alignment: .trailing) {
                        Text("\(Int(accuracy.overallAccuracy))%")
                            .font(.headline)
                            .foregroundColor(accuracyColor(accuracy.overallAccuracy))

                        Text("Accuracy")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                }
            }

            // Prediction
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text("Predicted Winner:")
                        .font(.subheadline)
                        .foregroundColor(.secondary)

                    Spacer()

                    Text(model.predictedWinner)
                        .font(.subheadline)
                        .fontWeight(.bold)
                }

                HStack {
                    Text("Confidence:")
                        .font(.subheadline)
                        .foregroundColor(.secondary)

                    Spacer()

                    Text("\(Int(model.confidence))%")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                }

                // Probabilities
                HStack(spacing: 16) {
                    VStack {
                        Text("\(game.homeTeam.abbreviation)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Text("\(Int(model.homeWinProbability))%")
                            .font(.subheadline)
                            .fontWeight(.semibold)
                    }
                    .frame(maxWidth: .infinity)

                    VStack {
                        Text("\(game.awayTeam.abbreviation)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Text("\(Int(model.awayWinProbability))%")
                            .font(.subheadline)
                            .fontWeight(.semibold)
                    }
                    .frame(maxWidth: .infinity)
                }
                .padding(.vertical, 8)
                .background(Color(UIColor.systemGray5))
                .cornerRadius(8)

                // Predicted Score
                if let homeScore = model.predictedHomeScore, let awayScore = model.predictedAwayScore {
                    HStack {
                        Text("Predicted Score:")
                            .font(.subheadline)
                            .foregroundColor(.secondary)

                        Spacer()

                        Text("\(homeScore) - \(awayScore)")
                            .font(.subheadline)
                            .fontWeight(.semibold)
                    }
                }

                // Reasoning
                if let reasoning = model.reasoning {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Analysis:")
                            .font(.caption)
                            .fontWeight(.semibold)
                            .foregroundColor(.secondary)

                        Text(reasoning)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .padding(12)
                    .background(Color(UIColor.systemGray5))
                    .cornerRadius(8)
                }
            }
        }
        .padding()
        .background(Color(UIColor.systemGray6))
        .cornerRadius(12)
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

#Preview {
    NavigationStack {
        ModelComparisonView(
            comparison: ModelComparisonDTO(
                game: GameDTO(
                    id: "1",
                    homeTeam: TeamDTO(name: "Kansas City Chiefs", abbreviation: "KC", conference: "AFC", division: "West"),
                    awayTeam: TeamDTO(name: "Buffalo Bills", abbreviation: "BUF", conference: "AFC", division: "East"),
                    date: Date(),
                    week: 18,
                    season: 2024,
                    status: "scheduled"
                ),
                models: [
                    PredictionModelDTO(
                        id: "model1",
                        modelName: "ELO Rating",
                        modelVersion: "2.0",
                        predictedWinner: "KC",
                        confidence: 68.5,
                        homeWinProbability: 68.5,
                        awayWinProbability: 31.5,
                        predictedHomeScore: 28,
                        predictedAwayScore: 24,
                        reasoning: "KC has home field advantage and stronger offensive rating",
                        accuracy: ModelAccuracyDTO(overallAccuracy: 65.2, recentAccuracy: 72.5, totalPredictions: 120)
                    ),
                    PredictionModelDTO(
                        id: "model2",
                        modelName: "Machine Learning",
                        modelVersion: "3.1",
                        predictedWinner: "KC",
                        confidence: 72.3,
                        homeWinProbability: 72.3,
                        awayWinProbability: 27.7,
                        predictedHomeScore: 31,
                        predictedAwayScore: 21,
                        reasoning: "Historical matchup data favors KC in home games",
                        accuracy: ModelAccuracyDTO(overallAccuracy: 68.7, recentAccuracy: 75.0, totalPredictions: 150)
                    )
                ],
                consensus: ConsensusDTO(
                    predictedWinner: "KC",
                    agreementPercentage: 100.0,
                    averageConfidence: 70.4,
                    modelCount: 2
                )
            )
        )
    }
}
