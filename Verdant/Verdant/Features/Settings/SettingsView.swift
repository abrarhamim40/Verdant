//
//  SettingsView.swift
//  Verdant
//
//  Created by Abrar Hamim on 5/19/26.
//
//  Settings tab — built without a paid Apple Developer account. Subscription
//  management + Apple Sign-In are deferred (Week 6, paid dev required).
//  What's here today: notifications permission status with a Settings
//  deep-link, user preferences (temperature unit, daily digest), an About
//  section with version + support link, and a developer-only Reset
//  onboarding toggle that only appears in DEBUG builds.

import SwiftUI
import SwiftData
import UIKit

struct SettingsView: View {
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false

    // SwiftData-backed user preferences. We assume at most one row; if it
    // doesn't exist we create one on first appear so the form has something
    // to bind to.
    @Query private var preferenceRows: [UserPreferences]

    @Environment(\.modelContext) private var modelContext
    @Environment(\.scenePhase) private var scenePhase

    @State private var notificationState: NotificationService.AuthorizationState = .notDetermined
    @State private var saveErrorMessage: String?

    private var preferences: UserPreferences? { preferenceRows.first }

    var body: some View {
        NavigationStack {
            Form {
                notificationsSection
                preferencesSection
                aboutSection
                #if DEBUG
                developerSection
                #endif
            }
            .navigationTitle("Settings")
            .background(Color.backgroundPrimary.ignoresSafeArea())
            .task {
                await ensurePreferencesRow()
                await refreshNotificationState()
            }
            .onChange(of: scenePhase) { _, newPhase in
                if newPhase == .active {
                    Task { await refreshNotificationState() }
                }
            }
            .alert("Couldn't save", isPresented: saveErrorBinding) {
                Button("OK") { saveErrorMessage = nil }
            } message: {
                Text(saveErrorMessage ?? "")
            }
        }
    }

    // MARK: - Notifications

    private var notificationsSection: some View {
        Section {
            HStack(spacing: 12) {
                Image(systemName: notificationIcon)
                    .font(.body)
                    .foregroundStyle(notificationTint)
                VStack(alignment: .leading, spacing: 2) {
                    Text("Notifications")
                        .font(.body)
                    Text(notificationStatusLabel)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                Spacer()
                if notificationState == .denied || notificationState == .notDetermined {
                    Button("Open Settings") { openAppSettings() }
                        .font(.subheadline.weight(.medium))
                        .buttonStyle(.borderless)
                }
            }
            .padding(.vertical, 4)
        } header: {
            Text("Reminders")
        } footer: {
            if notificationState == .denied {
                Text("Verdant can't show care reminders until you enable notifications in iOS Settings.")
                    .foregroundStyle(Color.terracotta)
            }
        }
    }

    private var notificationIcon: String {
        switch notificationState {
        case .granted, .provisional: return "bell.fill"
        case .denied:                return "bell.slash.fill"
        case .notDetermined:         return "bell"
        }
    }

    private var notificationTint: Color {
        switch notificationState {
        case .granted, .provisional: return Color.forestGreen
        case .denied:                return Color.terracotta
        case .notDetermined:         return .secondary
        }
    }

    private var notificationStatusLabel: String {
        switch notificationState {
        case .granted:       return "On — reminders fire at your scheduled times"
        case .provisional:   return "Provisional — silent delivery"
        case .denied:        return "Disabled in iOS Settings"
        case .notDetermined: return "Permission will be asked on first plant save"
        }
    }

    private func refreshNotificationState() async {
        notificationState = await NotificationService.shared.authorizationState()
    }

    // MARK: - Preferences

    @ViewBuilder
    private var preferencesSection: some View {
        if let prefs = preferences {
            Section {
                Picker("Temperature unit", selection: temperatureBinding(prefs)) {
                    Text("Celsius (°C)").tag("C")
                    Text("Fahrenheit (°F)").tag("F")
                }
                Toggle("Weekly digest", isOn: weeklyDigestBinding(prefs))
            } header: {
                Text("Preferences")
            } footer: {
                Text("Weekly digest summarizes your plant care once a week. Off by default.")
            }
        }
    }

    private func temperatureBinding(_ prefs: UserPreferences) -> Binding<String> {
        Binding(
            get: { prefs.temperatureUnit },
            set: { newValue in
                prefs.temperatureUnit = newValue
                persistOrAlert("temperature unit")
            }
        )
    }

    private func weeklyDigestBinding(_ prefs: UserPreferences) -> Binding<Bool> {
        Binding(
            get: { prefs.weeklyDigestEnabled },
            set: { newValue in
                prefs.weeklyDigestEnabled = newValue
                persistOrAlert("weekly digest")
            }
        )
    }

    // MARK: - About

    private var aboutSection: some View {
        Section {
            LabeledContent("Version", value: appVersionString)
            Link(destination: URL(string: "https://github.com/abrarhamim40/Verdant/issues")!) {
                HStack {
                    Label("Support & feedback", systemImage: "envelope")
                    Spacer()
                    Image(systemName: "arrow.up.right")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            }
            Link(destination: URL(string: "https://en.wikipedia.org/wiki/Botany")!) {
                HStack {
                    Label("About plant identification", systemImage: "info.circle")
                    Spacer()
                    Image(systemName: "arrow.up.right")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            }
        } header: {
            Text("About")
        } footer: {
            Text("Verdant uses Plant.id for species + disease detection and Google Gemini for personalized care plans. Identifications carry their source confidence.")
        }
    }

    private var appVersionString: String {
        let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
        let build = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1"
        return "\(version) (\(build))"
    }

    // MARK: - Developer

    #if DEBUG
    private var developerSection: some View {
        Section {
            Button {
                Haptics.warning()
                hasCompletedOnboarding = false
            } label: {
                Label("Replay onboarding", systemImage: "arrow.counterclockwise")
                    .foregroundStyle(Color.terracotta)
            }
        } header: {
            Text("Developer")
        } footer: {
            Text("Debug-only. Resets the @AppStorage flag so the onboarding screens run again on next launch.")
        }
    }
    #endif

    // MARK: - Persistence

    /// Creates a UserPreferences row on first launch if one doesn't exist
    /// yet. Cheap idempotent — does nothing when a row is already present.
    private func ensurePreferencesRow() async {
        guard preferenceRows.isEmpty else { return }
        let prefs = UserPreferences()
        modelContext.insert(prefs)
        try? modelContext.save()
    }

    private func persistOrAlert(_ field: String) {
        do {
            try modelContext.save()
            Haptics.selection()
        } catch {
            Haptics.error()
            saveErrorMessage = "Couldn't save the \(field). Try again."
        }
    }

    private var saveErrorBinding: Binding<Bool> {
        Binding(
            get: { saveErrorMessage != nil },
            set: { if !$0 { saveErrorMessage = nil } }
        )
    }

    // MARK: - System helpers

    private func openAppSettings() {
        Haptics.selection()
        guard let url = URL(string: UIApplication.openSettingsURLString) else { return }
        UIApplication.shared.open(url)
    }
}
