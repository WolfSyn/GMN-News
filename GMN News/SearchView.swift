//
//  SearchView.swift
//  GMN News
//
//  Created by Carlos Daniel Garcia on 5/16/25.
//

import SwiftUI
import FirebaseAnalytics   // ← for logging events

struct SearchView: View {
    @State private var query: String = ""
    @State private var searchTask: Task<Void, Never>? = nil
    @StateObject private var viewModel = NewsViewModel()
    @EnvironmentObject private var favoritesManager: FavoritesManager
    @EnvironmentObject private var sideMenu: SideMenuManager
    @Environment(\.colorScheme) private var colorScheme   // ← read current theme
    @AppStorage("articleFontSize") private var articleFontSize: Double = 16

    // Formatter for display (same as HomeView / Detail)
    private static let displayFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateStyle = .medium    // e.g. “May 25, 2025”
        f.timeStyle = .short     // e.g. “3:45 PM”
        return f
    }()

    init() {
        // iOS 15 or earlier: remove UITableView background so ZStack shows through.
        UITableView.appearance().backgroundColor = .clear
    }

    var body: some View {
        NavigationView {
            ZStack {
                // Always show CharcoalSplash behind everything
                Color("CharcoalSplash")
                    .ignoresSafeArea()

                VStack(spacing: 0) {
                    // MARK: — Search Bar —
                    HStack {
                        HStack {
                            Image(systemName: "magnifyingglass")
                                .foregroundColor(.secondary)
                            TextField("Search articles…", text: $query)
                                .foregroundColor(.primary)
                                .autocorrectionDisabled(true)
                                .textInputAutocapitalization(.none)
                                .onChange(of: query) {
                                    searchTask?.cancel()
                                    let trimmed = query.trimmingCharacters(in: .whitespaces)
                                    if trimmed.isEmpty {
                                        viewModel.articles = []
                                        return
                                    }
                                    searchTask = Task {
                                        try? await Task.sleep(nanoseconds: 300 * 1_000_000)
                                        // Log the search event
                                        Analytics.logEvent("search_performed", parameters: [
                                            "query": trimmed
                                        ])
                                        await viewModel.searchArticles(with: trimmed)
                                    }
                                }
                        }
                        .padding(12)
                        .background(Color("CardBackground"))
                        .cornerRadius(10)

                        if viewModel.isLoading {
                            ProgressView()
                                .padding(.trailing, 16)
                        }
                    }
                    .padding(.horizontal)
                    .padding(.top)

                    // MARK: — Results or Empty State —
                    if viewModel.articles.isEmpty {
                        Spacer()
                        Text(query.isEmpty
                             ? "Type to search articles"
                             : "No results for “\(query)”")
                            .foregroundColor(.secondary)
                        Spacer(minLength: 0)
                    } else {
                        List {
                            ForEach(viewModel.articles, id: \.id) { article in
                                // Inline card with date/time placed before "Read more"
                                ZStack(alignment: .topTrailing) {
                                    VStack(alignment: .leading, spacing: 8) {
                                        // 1) Image (210pt tall)
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

                                        // 2) Title
                                        Text(article.title)
                                            .font(.headline)
                                            .foregroundColor(
                                                colorScheme == .dark ? .white : .primary
                                            )
                                            .lineLimit(2)

                                        // 3) Deck / description
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

                                        // 4) Publish Date: raw + formatted (before Read more)
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

                                        // 5) Read more link (in-app)
                                        NavigationLink {
                                            ArticleDetailView(article: article)
                                                .onAppear {
                                                    Analytics.logEvent("article_opened", parameters: [
                                                        "article_id": article.id,
                                                        "article_title": article.title
                                                    ])
                                                }
                                        } label: {
                                            Text("Read more")
                                                .font(.caption.bold())
                                                .foregroundColor(.accentColor)
                                        }
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
                                .listRowBackground(Color.clear)
                                .onAppear {
                                    // Infinite‐scroll: load next page when last article appears
                                    if article.id == viewModel.articles.last?.id {
                                        Task { await viewModel.fetchNextPage() }
                                    }
                                }
                            }
                        }
                        .listStyle(.plain)
                        .scrollContentBackground(.hidden)  // iOS 16+
                        .listRowSeparator(.hidden)
                    }

                    Spacer(minLength: 0)
                }
            }
            .navigationTitle("Search")
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button { sideMenu.toggle() } label: {
                        Image(systemName: "line.horizontal.3")
                    }
                }
            }
            .onAppear {
                // Log screen view
                Analytics.logEvent(AnalyticsEventScreenView, parameters: [
                    AnalyticsParameterScreenName: "Search",
                    AnalyticsParameterScreenClass: "SearchView"
                ])
            }
        }
    }
}
