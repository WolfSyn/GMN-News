//
//  ContentView.swift
//  GMN News
//
//  Created by Carlos Daniel Garcia on 5/16/25.
//

import SwiftUI

struct ContentView: View {
    @EnvironmentObject private var sideMenu: SideMenuManager
    @AppStorage("darkMode") private var darkMode = false

    var body: some View {
        ZStack(alignment: .leading) {
            TabView {
                HomeView()
                    .tabItem { Label("News", systemImage: "house.fill") }

                FavoritesView()
                    .tabItem { Label("Favorites", systemImage: "star.fill") }

                SearchView()
                    .tabItem { Label("Search", systemImage: "magnifyingglass") }
            }
            .disabled(sideMenu.isOpen) // prevent taps when menu is open

            // — The side menu —
            if sideMenu.isOpen {
                SettingsView()
                    .frame(width: 250)
                    .background(.ultraThinMaterial)
                    .transition(.move(edge: .leading))
            }
        }
        .animation(.easeInOut, value: sideMenu.isOpen)
        .preferredColorScheme(darkMode ? .dark : .light) // <- force light/dark themes 
    }
}
