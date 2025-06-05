//
//  SplashScreen.swift
//  GMN News
//
//  Created by Carlos Daniel Garcia on 5/28/25.
//
import SwiftUI

struct SplashScreen: View {
    @State private var isAnimating = false
    @State private var showMainView = false

    var body: some View {
        ZStack {
            Color("CharcoalSplash")                  // match your app bg
                .ignoresSafeArea()

            if showMainView {
                ContentView()                  // or your top-level view
            } else {
                Image("Logo")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 200, height: 200)
                    .scaleEffect(isAnimating ? 1.0 : 0.6)
                    .opacity(isAnimating ? 1.0 : 0.0)
                    .onAppear {
                        // 1) Animate in
                        withAnimation(.easeOut(duration: 0.8)) {
                            isAnimating = true
                        }
                        // 2) After a short delay, show the main UI
                        DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) {
                            withAnimation(.easeIn(duration: 0.5)) {
                                showMainView = true
                            }
                        }
                    }
            }
        }
    }
}
