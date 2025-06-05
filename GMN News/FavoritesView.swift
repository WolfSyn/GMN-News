//
//  FavoritesView.swift
//  GMN News
//
//  Created by Carlos Daniel Garcia on 5/16/25.
//

import SwiftUI
import FirebaseAnalytics

struct FavoritesView: View {
    @EnvironmentObject private var favoritesManager: FavoritesManager
    @EnvironmentObject private var sideMenu: SideMenuManager
    @Environment(\.colorScheme) private var colorScheme   // ← read current theme
    @AppStorage("articleFontSize") private var articleFontSize: Double = 16

    // Formatter for display (same as in HomeView/Detail)
    private static let displayFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateStyle = .medium    // e.g. “May 25, 2025”
        f.timeStyle = .short     // e.g. “3:45 PM”
        return f
    }()

    var body: some View {
        NavigationView {
            ZStack {
                // ← conditional background
                Group {
                    if colorScheme == .dark {
                        Color("CharcoalSplash")
                    } else {
                        Color.white
                    }
                }
                .ignoresSafeArea()

                if favoritesManager.favorites.isEmpty {
                    // Empty state
                    Text("No favorites yet")
                        .foregroundColor(
                            colorScheme == .dark
                                ? Color.white.opacity(0.7)
                                : .secondary
                        )
                        .navigationTitle("Favorites")
                } else {
                    List {
                        ForEach(favoritesManager.favorites, id: \.id) { article in
                            NavigationLink {
                                ArticleDetailView(article: article)
                            } label: {
                                ZStack(alignment: .topTrailing) {
                                    VStack(alignment: .leading, spacing: 8) {
                                        // — Image (210pt tall) —
                                        if let imageUrl = article.image?.original,
                                           let url = URL(string: imageUrl),
                                           !imageUrl.contains("default") {
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

                                        // — Title —
                                        Text(article.title)
                                            .font(.headline)
                                            .foregroundColor(
                                                colorScheme == .dark ? .white : .primary
                                            )
                                            .lineLimit(2)

                                        // — Deck / description —
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

                                        // — Publish Date: raw + formatted —
                                        if let raw = article.publishDate {
                                            Text("Publish Date: \(raw)")
                                                .font(.system(size: articleFontSize - 6))
                                                .foregroundColor(.blue)

                                            if let date = ISO8601DateFormatter().date(from: raw) {
                                                Text(Self.displayFormatter.string(from: date))
                                                    .font(.system(size: articleFontSize - 6))
                                                    .foregroundColor(.secondary)
                                            }
                                        } else {
                                            Text("No publishDate in model")
                                                .font(.system(size: articleFontSize - 6))
                                                .foregroundColor(.secondary)
                                        }
                                    }
                                    .padding()
                                    .background(Color("CardBackground"))
                                    .cornerRadius(12)
                                    .shadow(color: Color.black.opacity(0.1), radius: 4, x: 0, y: 2)

                                    // ★ Favorites button
                                    Button {
                                        favoritesManager.toggle(article)
                                        Analytics.logEvent("favorite_tapped", parameters: [
                                            "article_id": article.id,
                                            "article_title": article.title
                                        ])
                                    } label: {
                                        Image(systemName: favoritesManager.isFavorite(article)
                                                     ? "star.fill" : "star")
                                            .foregroundColor(.yellow)
                                            .padding(8)
                                            .background(.ultraThinMaterial, in: Circle())
                                    }
                                    .buttonStyle(.plain)
                                    .padding(8)
                                }
                            }
                            .buttonStyle(.plain)
                            .listRowBackground(Color.clear)
                        }
                    }
                    .listStyle(.plain)                 // no grouped insets
                    .scrollContentBackground(.hidden)  // lets the background show through
                    .listRowSeparator(.hidden)         // hide separators
                    .navigationTitle("Favorites")
                }
            }
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button {
                        sideMenu.toggle()
                    } label: {
                        Image(systemName: "line.horizontal.3")
                    }
                }
            }
        }
    }
}

