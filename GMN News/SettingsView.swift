//
//  SettingsView.swift
//  GMN News
//
//  Created by Carlos Daniel Garcia on 5/17/25.
//

import SwiftUI
import MessageUI
import UIKit    // for UIApplication.open(_:)

struct SettingsView: View {
    @EnvironmentObject private var sideMenu: SideMenuManager
    @AppStorage("darkMode") private var darkMode = false
    @AppStorage("articleFontSize") private var articleFontSize: Double = 16
    @StateObject private var notifications = NotificationManager.shared

    // Mail composer state
    @State private var showingMailComposer = false
    @State private var mailResult: Result<MFMailComposeResult, Error>? = nil

    // Read version & build from Info.plist
    private var appVersion: String {
        let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "?"
        let build   = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "?"
        return "v\(version) (\(build))"
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            // Header
            HStack {
                Text("Settings")
                    .font(.title2).bold()
                Spacer()
                Button { sideMenu.close() } label: {
                    Image(systemName: "xmark.circle.fill")
                        .imageScale(.large)
                }
            }
            .padding(.bottom, 20)

            // Dark Mode
            Toggle("Dark Mode", isOn: $darkMode)

            // Notifications
            Toggle("Enable Notifications", isOn: Binding<Bool>(
                get: { notifications.isAuthorized },
                set: { enabled in
                    Task {
                        if enabled {
                            await notifications.requestAuthorization()
                        } else {
                            notifications.removeAllPending()
                        }
                    }
                }
            ))
            .padding(.vertical, 8)

            // Article Text Size Slider
            VStack(alignment: .leading, spacing: 8) {
                Text("Article Text Size: \(Int(articleFontSize))pt")
                    .font(.headline)
                Slider(value: $articleFontSize, in: 12...24, step: 1)
            }
            .padding(.vertical, 8)

            // Send Feedback Button
            Button("Send Feedback") {
                if MFMailComposeViewController.canSendMail() {
                    showingMailComposer = true
                } else if let url = URL(string: "mailto:gmn.news.official@gmail.com") {
                    UIApplication.shared.open(url)
                }
            }
            .padding(.vertical, 8)
            .sheet(isPresented: $showingMailComposer) {
                MailComposeView(result: $mailResult)
            }

            // Sign out stub
            Button("Sign Out") {
                // handle sign out
            }
            .foregroundColor(.red)

            Spacer()

            // App Version display at very bottom
            HStack {
                Spacer()
                Text(appVersion)
                    .font(.footnote)
                    .foregroundColor(.secondary)
                Spacer()
            }
        }
        .padding()
        .frame(maxHeight: .infinity)
    }
}

// MARK: – Mail composer bridge

struct MailComposeView: UIViewControllerRepresentable {
    @Environment(\.presentationMode) private var presentation
    @Binding var result: Result<MFMailComposeResult, Error>?

    func makeUIViewController(context: Context) -> MFMailComposeViewController {
        let vc = MFMailComposeViewController()
        vc.setToRecipients(["gmn.news.official@gmail.com"])
        vc.setSubject("GMN News Feedback")
        vc.mailComposeDelegate = context.coordinator
        return vc
    }

    func updateUIViewController(_ uiViewController: MFMailComposeViewController, context: Context) {}

    func makeCoordinator() -> Coordinator { Coordinator(self) }

    class Coordinator: NSObject, MFMailComposeViewControllerDelegate {
        let parent: MailComposeView

        init(_ parent: MailComposeView) {
            self.parent = parent
        }

        func mailComposeController(
            _ controller: MFMailComposeViewController,
            didFinishWith result: MFMailComposeResult,
            error: Error?
        ) {
            defer { parent.presentation.wrappedValue.dismiss() }
            if let error = error {
                parent.result = .failure(error)
            } else {
                parent.result = .success(result)
            }
        }
    }
}
