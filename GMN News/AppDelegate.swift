//
//  AppDelegate.swift
//  GMN News
//
//  Created by Carlos Daniel Garcia on 5/17/25.
//

import UIKit
import BackgroundTasks

class AppDelegate: NSObject, UIApplicationDelegate {
    
    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
    ) -> Bool {
        // Register the background‐refresh task
        BGTaskScheduler.shared.register(
            forTaskWithIdentifier: "com.yourcompany.gmnnews.refresh",
            using: nil
        ) { [weak self] task in
            guard
                let self = self,
                let refreshTask = task as? BGAppRefreshTask
            else {
                task.setTaskCompleted(success: false)
                return
            }
            self.handleAppRefresh(task: refreshTask)
        }
        
        // Schedule the first refresh
        scheduleAppRefresh()
        
        // ─── Debug: print permitted identifiers from Info.plist ───
        if let permitted = Bundle.main
            .object(forInfoDictionaryKey: "BGTaskSchedulerPermittedIdentifiers") as? [String] {
            print("🔍 Permitted BGTask IDs:", permitted)
        } else {
            print("🔍 No BGTaskSchedulerPermittedIdentifiers found in Info.plist")
        }
        // ───────────────────────────────────────────────────────────

        return true
    }

    private func scheduleAppRefresh() {
        let request = BGAppRefreshTaskRequest(identifier: "com.yourcompany.gmnnews.refresh")
        request.earliestBeginDate = Date(timeIntervalSinceNow: 15 * 60)
        do {
            try BGTaskScheduler.shared.submit(request)
        } catch {
            print("❌ Could not schedule app refresh: \(error)")
        }
    }

    private func handleAppRefresh(task: BGAppRefreshTask) {
        // Schedule the next refresh
        scheduleAppRefresh()

        // If the system is running out of time, cancel any ongoing work
        task.expirationHandler = {
            // clean-up if needed
        }

        // Perform your async fetch & notify logic
        Task {
            let fetchResult = await BackgroundFetchHandler.performFetch()
            task.setTaskCompleted(success: fetchResult == .newData)
        }
    }
}

/// Handles fetching the feed, checking for new articles, and firing notifications
import Foundation

struct BackgroundFetchHandler {
    static func performFetch() async -> UIBackgroundFetchResult {
        // 1) Build the URL
        let apiKey = "93b1c0cfd2ecca30289fb1ae6fe1d48c31069aec"
        let urlString = "https://www.gamespot.com/api/articles/?api_key=\(apiKey)&format=json&sort=publish_date:desc"
        guard let url = URL(string: urlString) else { return .failed }

        do {
            // 2) Fetch & decode
            let (data, _) = try await URLSession.shared.data(from: url)
            let decoded = try JSONDecoder().decode(NewsResponse.self, from: data)
            guard let newest = decoded.results.first else {
                return .noData
            }

            // 3) Compare to last notified ID
            let lastID = UserDefaults.lastNotifiedArticleID!
            if newest.id > lastID {
                // 4) Fire a local notification
                await NotificationManager.shared.scheduleNewArticleAlert(
                    title: "New Article: \(newest.title)",
                    body: newest.deck ?? ""
                )
                // 5) Record it so we don’t notify again
                UserDefaults.lastNotifiedArticleID = newest.id
                return .newData
            } else {
                return .noData
            }
        } catch {
            print("❌ Background fetch failed:", error)
            return .failed
        }
    }
}

