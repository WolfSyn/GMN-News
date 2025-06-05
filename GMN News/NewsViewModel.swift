//
//  NewsViewModel.swift
//  GMN News
//
//  Created by Carlos Daniel Garcia on 3/29/25.
//

import Foundation

@MainActor
class NewsViewModel: ObservableObject {
    @Published var articles: [NewsArticle] = []
    @Published var isLoading = false            // ← for the spinner in SearchView
    
    private let apiKey   = "93b1c0cfd2ecca30289fb1ae6fe1d48c31069aec"
    // ← Make apiUrl a computed property so it can reference apiKey
    private var apiUrl: String {
        "https://www.gamespot.com/api/articles/?api_key=\(apiKey)&format=json"
    }
    private let pageSize = 20
    
    private var offset           = 0
    private var canLoadMorePages = true
    private var isLoadingPage    = false
    
    /// Call this to load the first page (or to refresh)
    func fetchNews() async {
        await loadPage(reset: true)
    }
    
    /// Call this when the user scrolls to the bottom
    func fetchNextPage() async {
        await loadPage(reset: false)
    }
    
    private func loadPage(reset: Bool) async {
        guard !isLoadingPage else { return }
        isLoadingPage = true
        
        if reset {
            offset = 0
            canLoadMorePages = true
        }
        guard canLoadMorePages else {
            isLoadingPage = false
            return
        }
        
        // ─── 1) Build cache-busting URL ────────────────────────────────
        let ts = Int(Date().timeIntervalSince1970)
        let urlString = "\(apiUrl)&sort=publish_date:desc&limit=\(pageSize)&offset=\(offset)&_=\(ts)"
        print("🛰️ Fetching URL → \(urlString)")
        
        guard let url = URL(string: urlString) else {
            print("❌ Invalid URL: \(urlString)")
            isLoadingPage = false
            return
        }
        
        // ─── 2) Force no caching ────────────────────────────────────────
        var request = URLRequest(
            url: url,
            cachePolicy: .reloadIgnoringLocalCacheData,
            timeoutInterval: 30
        )
        request.setValue("no-cache", forHTTPHeaderField: "Cache-Control")
        request.setValue("no-cache", forHTTPHeaderField: "Pragma")
        
        do {
            // ─── 3) Fetch & decode ────────────────────────────────────────
            let (data, _) = try await URLSession.shared.data(for: request)
            let decoded     = try JSONDecoder().decode(NewsResponse.self, from: data)
            let newArticles = decoded.results
            
            // ─── 4) Reset or append ───────────────────────────────────────
            if reset {
                articles = newArticles
            } else {
                articles += newArticles
            }
            
            // ─── 5) Update pagination state ───────────────────────────────
            offset += newArticles.count
            canLoadMorePages = newArticles.count == pageSize
            print("✅ Loaded \(newArticles.count) articles (offset now \(offset)). More pages? \(canLoadMorePages)")
        } catch {
            print("❌ Error fetching page:", error)
        }
        
        isLoadingPage = false
    }
    
    // ─── NEW SEARCH METHOD ────────────────────────────────────────────────
    /// Searches articles by title containing `query`
    func searchArticles(with query: String) async {
        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        
        isLoading = true
        defer { isLoading = false }
        
        // Percent-encode the query
        let encoded = trimmed.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
        
        // Build a search URL (newest first, title filter)
        let urlString = "\(apiUrl)&sort=publish_date:desc&limit=\(pageSize)&filter=title:\(encoded)"
        guard let url = URL(string: urlString) else {
            print("❌ Invalid search URL: \(urlString)")
            return
        }
        
        do {
            let (data, _) = try await URLSession.shared.data(from: url)
            let decoded = try JSONDecoder().decode(NewsResponse.self, from: data)
            // Replace the articles array with search results
            articles = decoded.results
            // Reset infinite-scroll state
            offset = decoded.results.count
            canLoadMorePages = decoded.results.count == pageSize
        } catch {
            print("❌ Search failed:", error)
        }
    }
    // ────────────────────────────────────────────────────────────────────────
}
