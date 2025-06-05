//
//  NotificationManager.swift
//  GMN News
//
//  Created by Carlos Daniel Garcia on 5/17/25.
//


import Foundation
import UserNotifications

@MainActor
class NotificationManager: ObservableObject {
    static let shared = NotificationManager()
    
    @Published private(set) var isAuthorized = false
    
    private init() {
        Task { await checkAuthorization() }
    }
    
    /// Request permission from the user
    func requestAuthorization() async {
        let center = UNUserNotificationCenter.current()
        do {
            let granted = try await center.requestAuthorization(options: [.alert, .sound, .badge])
            DispatchQueue.main.async { self.isAuthorized = granted }
        } catch {
            print("❌ Notification auth error:", error)
        }
    }
    
    /// Check current authorization status
    func checkAuthorization() async {
        let settings = await UNUserNotificationCenter.current().notificationSettings()
        DispatchQueue.main.async {
            self.isAuthorized = (settings.authorizationStatus == .authorized)
        }
    }
    
    /// Schedule a simple local notification
    func scheduleNewArticleAlert(title: String, body: String) {
        guard isAuthorized else { return }
        let content = UNMutableNotificationContent()
        content.title = title
        content.body  = body
        content.sound = .default
        
        let req = UNNotificationRequest(
            identifier: UUID().uuidString,
            content: content,
            trigger: nil
        )
        UNUserNotificationCenter.current().add(req) { error in
            if let e = error { print("❌ Failed to schedule:", e) }
        }
    }
    
    /// Remove all pending notifications
    func removeAllPending() {
        UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
    }
    
    /// Schedule a test notification 5 seconds from now
    func scheduleTestNotification() {
        guard isAuthorized else { return }
        
        let content = UNMutableNotificationContent()
        content.title = "🛎️ Test Notification"
        content.body  = "If you see this, notifications are working!"
        content.sound = .default
        
        // Fire in 5 seconds
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 5, repeats: false)
        let request = UNNotificationRequest(
            identifier: "test_notification",
            content: content,
            trigger: trigger
        )
        
        UNUserNotificationCenter.current().add(request) { error in
            if let e = error {
                print("❌ Failed to schedule test notification:", e)
            } else {
                print("✅ Test notification scheduled for 5 seconds from now")
            }
        }
    }
}

// MARK: - UserDefaults helper for background fetch

extension UserDefaults {
    private static let lastArticleKey = "lastNotifiedArticleID"
    
    // The ID of the most-recent notified article.
    static var lastNotifiedArticleID: Int? {
        get {standard.integer(forKey: lastArticleKey) }
        set {standard.set(newValue, forKey: lastArticleKey)}
    }
}
