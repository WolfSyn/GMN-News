//
//  GMN_NewsApp.swift
//  GMN News
//
//  Created by Carlos Daniel Garcia on 3/29/25.
//

import SwiftUI
import FirebaseCore   // ← add this import

@main
struct GMN_NewsApp: App {
    // Adapt our AppDelegate
    @UIApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate

    @StateObject private var favoritesManager = FavoritesManager()
    @StateObject private var sideMenu = SideMenuManager()
    @AppStorage("darkMode") private var darkMode = false // ← read the stored toggle

    init() {
        FirebaseApp.configure()   // ← initialize Firebase Analytics
    }

    var body: some Scene {
        WindowGroup {
            SplashScreen()                                      // ← start here
                .environmentObject(favoritesManager)
                .environmentObject(sideMenu)
                // ↓ force the whole app into dark or light theme :)
                .preferredColorScheme(darkMode ? .dark : .light)
        }
    }
}

