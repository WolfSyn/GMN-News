//
//  NewsArticle.swift
//  GMN News
//
//  Created by Carlos Daniel Garcia on 3/29/25.
//

import Foundation

struct NewsResponse: Codable {
    let results: [NewsArticle]
}

struct NewsArticle: Identifiable, Codable {
    let id: Int
    let title: String
    let deck: String?
    let body: String?
    let image: ImageData?
    let publishDate: String?       // ← optional String
    let site_detail_url: String

    enum CodingKeys: String, CodingKey {
        case id, title, deck, image, body, site_detail_url
        case publishDate = "publish_date"   // ← map the JSON key
    }

    struct ImageData: Codable {
        let original: String?
    }
}

