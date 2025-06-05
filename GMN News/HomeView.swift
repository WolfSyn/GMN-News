//
//  ContentView.swift
//  GMN News
//
//  Created by Carlos Daniel Garcia on 3/29/25.
//

import SwiftUI
import FirebaseAnalytics   // ← import Analytics

struct HomeView: View {
    @StateObject private var viewModel = NewsViewModel()
    @EnvironmentObject private var favoritesManager: FavoritesManager
    @EnvironmentObject private var sideMenu: SideMenuManager
    @Environment(\.colorScheme) private var colorScheme

    // ① Pull in user’s chosen font size so we can do “articleFontSize - 6”
    @AppStorage("articleFontSize") private var articleFontSize: Double = 16

    // Formatter for display, same as in ArticleDetailView
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

                List {
                    ForEach(viewModel.articles, id: \.id) { article in
                        ZStack(alignment: .topTrailing) {
                            VStack(alignment: .leading, spacing: 12) {
                                // 1) Image
                                if let imageUrl = article.image?.original,
                                   !imageUrl.contains("default"),
                                   let url = URL(string: imageUrl) {
                                    AsyncImage(url: url) { phase in
                                        if let image = phase.image {
                                            image
                                                .resizable()
                                                .scaledToFill()
                                                .frame(height: 180)
                                                .clipped()
                                        } else if phase.error != nil {
                                            Color.gray.frame(height: 180)
                                        } else {
                                            ProgressView().frame(height: 180)
                                        }
                                    }
                                } else {
                                    Color.gray.frame(height: 180)
                                }

                                // 2) Title
                                Text(article.title)
                                    .font(.headline)
                                    .foregroundColor(
                                        colorScheme == .dark ? .white : .primary
                                    )
                                    .lineLimit(2)

                                // 3) Deck / description
                                Text(article.deck ?? "No description available")
                                    .font(.subheadline)
                                    .foregroundColor(
                                        colorScheme == .dark
                                            ? Color.white.opacity(0.7)
                                            : .secondary
                                    )
                                    .lineLimit(2)

                                // 4) Publish Date: raw + formatted (exactly as in ArticleDetailView)
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

                                // 5) Read more
                                NavigationLink("Read more") {
                                    ArticleDetailView(article: article)
                                        .onAppear {
                                            Analytics.logEvent("article_opened", parameters: [
                                                "article_id": article.id,
                                                "article_title": article.title
                                            ])
                                        }
                                }
                                .font(.caption.bold())
                                .tint(.accentColor)
                                .padding(.top, 4)
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
                        .onAppear {
                            // Infinite‐scroll: load next page when last article appears
                            if article.id == viewModel.articles.last?.id {
                                Task { await viewModel.fetchNextPage() }
                            }
                        }
                        .listRowBackground(Color.clear) // let ZStack show through
                    }
                }
                .listStyle(.plain)
                .scrollContentBackground(.hidden)
                .listRowSeparator(.hidden)
                .padding(.top)
            }
            .navigationTitle("GMN News")
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button { sideMenu.toggle() } label: {
                        Image(systemName: "line.horizontal.3")
                    }
                }
            }
            .task { await viewModel.fetchNews() }
            .refreshable { await viewModel.fetchNews() }
            .onAppear {
                // Log Home screen view
                Analytics.logEvent(AnalyticsEventScreenView, parameters: [
                    AnalyticsParameterScreenName: "Home",
                    AnalyticsParameterScreenClass: "HomeView"
                ])
            }
        }
    }
}

#Preview {
    HomeView()
        .environmentObject(FavoritesManager())
        .environmentObject(SideMenuManager())
}
