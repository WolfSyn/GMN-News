//
//  ArticleDetailView.swift
//  GMN News
//
//  Created by Carlos Daniel Garcia on 5/19/25.
//

import SwiftUI
import SafariServices

// MARK: – Safari wrapper

struct SafariView: UIViewControllerRepresentable {
    let url: URL

    func makeUIViewController(context: Context) -> SFSafariViewController {
        SFSafariViewController(url: url)
    }

    func updateUIViewController(_ uiViewController: SFSafariViewController, context: Context) {}
}

// MARK: – ArticleDetailView

struct ArticleDetailView: View {
    let article: NewsArticle

    // ① Pull in the user’s chosen font size
    @AppStorage("articleFontSize") private var articleFontSize: Double = 16
    @Environment(\.colorScheme) private var colorScheme
    @State private var showSafari = false       // ← for presenting SafariView

    // Formatter for display
    private static let displayFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateStyle = .medium    // e.g. “May 20, 2025”
        f.timeStyle = .short     // e.g. “3:45 PM”
        return f
    }()

    var body: some View {
        NavigationView {
            ZStack {
                // conditional background
                Group {
                    if colorScheme == .dark {
                        Color("CharcoalSplash")
                    } else {
                        Color.white
                    }
                }
                .ignoresSafeArea()

                ScrollView {
                    VStack(alignment: .leading, spacing: 16) {
                        // 1) Main image
                        if let urlStr = article.image?.original,
                           let url = URL(string: urlStr) {
                            AsyncImage(url: url) { phase in
                                switch phase {
                                case .success(let img):
                                    img
                                        .resizable()
                                        .scaledToFit()
                                        .frame(maxHeight: 300)
                                        .clipped()
                                default:
                                    Color.gray.frame(height: 200)
                                }
                            }
                        }

                        // 2) Title & deck
                        Text(article.title)
                            .font(.system(size: articleFontSize + 4, weight: .bold))
                            .foregroundColor(colorScheme == .dark ? .white : .primary)

                        if let deck = article.deck {
                            Text(deck)
                                .font(.system(size: articleFontSize))
                                .foregroundColor(
                                    colorScheme == .dark
                                        ? Color.white.opacity(0.7)
                                        : .secondary
                                )
                        }

                        // 3) Publish date (raw + formatted)
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

                        Divider()
                            .background(
                                colorScheme == .dark
                                    ? Color.white.opacity(0.5)
                                    : Color.gray.opacity(0.5)
                            )

                        // 4) Body text with extra spacing between paragraphs
                        if let html = article.body {
                            let plain = html.strippingHTML()
                            Text(plain)
                                .font(.system(size: articleFontSize))
                                .foregroundColor(colorScheme == .dark ? .white : .primary)
                                // Increase line spacing so paragraphs (and line breaks) are more distinct:
                                .lineSpacing(8)
                                // Allow multiline wrapping correctly:
                                .fixedSize(horizontal: false, vertical: true)
                        } else {
                            Text("Content not available.")
                                .font(.system(size: articleFontSize))
                                .foregroundColor(.secondary)
                        }

                        // 5) Read Original Article button
                        if let link = URL(string: article.site_detail_url) {
                            Button(action: {
                                showSafari = true
                            }) {
                                HStack {
                                    Image(systemName: "safari")
                                    Text("Read Original Article")
                                        .bold()
                                }
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.accentColor.opacity(0.1))
                                .cornerRadius(8)
                            }
                            .padding(.top)
                            // present the SafariView sheet
                            .sheet(isPresented: $showSafari) {
                                SafariView(url: link)
                            }
                        }
                    }
                    .padding()
                    .background(Color("CardBackground"))
                    .cornerRadius(12)
                    .shadow(color: Color.black.opacity(0.1), radius: 4, x: 0, y: 2)
                    .padding()
                }
            }
            .navigationTitle("Article")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}

// MARK: – HTML‐stripping helper

extension String {
    /// Removes HTML tags (<…>) and decodes common HTML entities (&amp;, etc.)
    func strippingHTML() -> String {
        // 1) Remove tags
        let withoutTags = self.replacingOccurrences(
            of: "<[^>]+>",
            with: "",
            options: .regularExpression,
            range: nil
        )
        // 2) Decode entities via NSAttributedString
        guard let data = withoutTags.data(using: .utf8) else {
            return withoutTags
        }
        let decoded = (try? NSAttributedString(
            data: data,
            options: [
                .documentType: NSAttributedString.DocumentType.html,
                .characterEncoding: String.Encoding.utf8.rawValue
            ],
            documentAttributes: nil
        ))?.string
        return decoded ?? withoutTags
    }
}
