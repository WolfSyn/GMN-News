//
//  ArticleRow.swift
//  GMN News
//
//  Created by Carlos Daniel Garcia on 5/16/25.
//

import SwiftUI
import FirebaseAnalytics   // ← for logging events

struct ArticleRow: View {
    let article: NewsArticle
    @EnvironmentObject var favoritesManager: FavoritesManager
    @Environment(\.colorScheme) private var colorScheme   // ← read current theme

    var body: some View {
        ZStack(alignment: .topTrailing) {
            VStack(alignment: .leading, spacing: 12) {
                // — Image (210pt tall, scaledToFill) —
                if let imageUrl = article.image?.original,
                   !imageUrl.contains("default"),
                   let url = URL(string: imageUrl) {
                    AsyncImage(url: url) { phase in
                        if let image = phase.image {
                            image
                              .resizable()
                              .scaledToFill()
                              .frame(height: 210)
                              .clipped()
                        } else if phase.error != nil {
                            Color.gray.frame(height: 210)
                        } else {
                            ProgressView().frame(height: 210)
                        }
                    }
                } else {
                    Color.gray.frame(height: 210)
                }

                // — Title (dynamic color) —
                Text(article.title)
                    .font(.headline)
                    .foregroundColor(colorScheme == .dark ? .white : .primary)
                    .lineLimit(2)

                // — Deck / description (dynamic color) —
                if let deck = article.deck {
                    Text(deck)
                        .font(.subheadline)
                        .foregroundColor(
                            colorScheme == .dark
                                ? Color.white.opacity(0.7)
                                : .secondary
                        )
                        .lineLimit(3)
                }

                // — In-app “Read more” link with analytics —
                NavigationLink {
                    ArticleDetailView(article: article)
                } label: {
                    Text("Read more")
                }
                .font(.caption)
                .tint(.accentColor)
                .padding(.top, 2)
                .simultaneousGesture(TapGesture().onEnded {
                    Analytics.logEvent("article_opened", parameters: [
                        "article_id": article.id,
                        "article_title": article.title
                    ])
                })
            }
            .padding()
            .background(Color("CardBackground"))
            .cornerRadius(12)
            .shadow(color: Color.black.opacity(0.1), radius: 4, x: 0, y: 2)

            // ★ Favorites button with analytics
            Button {
                favoritesManager.toggle(article)
                Analytics.logEvent("favorite_tapped", parameters: [
                    "article_id": article.id,
                    "article_title": article.title
                ])
            } label: {
                Image(systemName: favoritesManager.isFavorite(article) ? "star.fill" : "star")
                    .foregroundColor(.yellow)
                    .padding(8)
                    .background(.ultraThinMaterial, in: Circle())
            }
            .buttonStyle(.plain)
            .padding(8)
        }
        .padding(.horizontal)
        .padding(.vertical, 4)
    }
}

