//
//  FavoritesManager.swift
//  GMN News
//
//  Created by Carlos Daniel Garcia on 5/16/25.
//

import Foundation

@MainActor
class FavoritesManager: ObservableObject {
    @Published private(set) var favorites: [NewsArticle] = [] {
        didSet { save() }
    }
    
    private let key = "favorites"

    init() {
        load()
    }

    func isFavorite(_ article: NewsArticle) -> Bool {
        favorites.contains(where: { $0.id == article.id })
    }

    func toggle(_ article: NewsArticle) {
        if isFavorite(article) {
            favorites.removeAll { $0.id == article.id }
        } else {
            favorites.append(article)
        }
    }
    
    private func save() {
        guard let data = try? JSONEncoder().encode(favorites) else { return }
        UserDefaults.standard.set(data, forKey: key)
    }
    
    private func load() {
        guard
            let data = UserDefaults.standard.data(forKey: key),
            let decoded = try? JSONDecoder().decode([NewsArticle].self, from: data)
        else { return }
        favorites = decoded
    }
}
