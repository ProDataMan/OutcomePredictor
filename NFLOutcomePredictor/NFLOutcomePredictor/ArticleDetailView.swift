import SwiftUI

/// Article detail view showing full article content.
struct ArticleDetailView: View {
    let article: ArticleDTO

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                // Article metadata
                VStack(alignment: .leading, spacing: 12) {
                    Text(article.title)
                        .font(.title)
                        .fontWeight(.bold)

                    HStack(spacing: 8) {
                        Text(article.source)
                            .font(.subheadline)
                            .foregroundColor(.secondary)

                        Text("•")
                            .foregroundColor(.secondary)

                        Text(article.publishedDate, style: .date)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }

                    if !article.teamAbbreviations.isEmpty {
                        HStack(spacing: 8) {
                            ForEach(article.teamAbbreviations, id: \.self) { team in
                                Text(team)
                                    .font(.caption)
                                    .fontWeight(.semibold)
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 4)
                                    .background(Color.accentColor.opacity(0.2))
                                    .cornerRadius(4)
                            }
                        }
                    }
                }
                .padding()
                .background(Color(.secondarySystemBackground))
                .cornerRadius(12)

                // Article content
                if !article.content.isEmpty {
                    Text(article.content)
                        .font(.body)
                        .lineSpacing(6)
                }

                // Source link
                if let urlString = article.url, let url = URL(string: urlString) {
                    Link(destination: url) {
                        HStack {
                            Image(systemName: "safari")
                                .font(.subheadline)

                            Text("Read Full Article")
                                .font(.subheadline)
                                .fontWeight(.semibold)

                            Spacer()

                            Image(systemName: "arrow.up.right")
                                .font(.caption)
                        }
                        .foregroundColor(.white)
                        .padding()
                        .background(Color.accentColor)
                        .cornerRadius(12)
                    }
                }
            }
            .padding()
        }
        .navigationTitle("Article")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                FeedbackButton(pageName: "Article Detail")
            }
        }
    }
}

// MARK: - Preview

struct ArticleDetailView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationStack {
            ArticleDetailView(
                article: ArticleDTO(
                    title: "Chiefs Defeat Bills in Playoff Thriller",
                    content: "The Kansas City Chiefs defeated the Buffalo Bills 27-24 in an overtime thriller at Arrowhead Stadium. Patrick Mahomes threw for 300 yards and 3 touchdowns in the victory.",
                    source: "ESPN",
                    publishedDate: Date(),
                    teamAbbreviations: ["KC", "BUF"],
                    url: "https://espn.com/nfl/story"
                )
            )
        }
    }
}
