//
//  WebView.swift
//  GMN News
//
//  Created by Carlos Daniel Garcia on 5/19/25.
//

import SwiftUI
import WebKit

/// A SwiftUI wrapper for WKWebView
struct WebView: UIViewRepresentable {
    let url: URL

    func makeUIView(context: Context) -> WKWebView {
        return WKWebView()
    }

    func updateUIView(_ webView: WKWebView, context: Context) {
        webView.load(URLRequest(url: url))
    }
}
