//
//  BetaInfoView.swift
//  Hippominder
//
//  Autor: Mathias Hubrich & Claude (Anthropic)
//  Erstellt: 13. Februar 2026
//  Version: 1.0.0
//
//  Beschreibung: Versteckte Beta-Info-Ansicht (5x Logo tippen)
//  Zeigt App-Info und in Debug-Builds die Zeitsimulation
//

import SwiftUI

struct BetaInfoView: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var debugSettings = DebugSettings.shared
    @ObservedObject var storeManager = StoreManager.shared

    private var appVersion: String {
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "–"
    }

    private var buildNumber: String {
        Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "–"
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {

                    // App Logo & Info
                    VStack(spacing: 8) {
                        Image("hippominder_logo")
                            .resizable()
                            .scaledToFit()
                            .frame(height: 60)

                        Text("Hippominder")
                            .font(.title2.bold())

                        Text("Version \(appVersion) (Build \(buildNumber))")
                            .font(.caption)
                            .foregroundColor(.secondary)

                        Text("Beta-Testphase")
                            .font(.caption.bold())
                            .foregroundColor(.orange)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 4)
                            .background(Color.orange.opacity(0.15))
                            .cornerRadius(8)
                    }
                    .padding(.top, 8)

                    Divider()

                    // Status-Info
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Status")
                            .font(.headline)

                        InfoRow(label: "Pro-Status", value: storeManager.isPro ? "Aktiv" : "Kostenlos")
                        InfoRow(label: "Bundle ID", value: Bundle.main.bundleIdentifier ?? "–")
                        #if os(iOS)
                        InfoRow(label: "iOS", value: UIDevice.current.systemVersion)
                        InfoRow(label: "Geraet", value: UIDevice.current.model)
                        #elseif os(macOS)
                        InfoRow(label: "macOS", value: ProcessInfo.processInfo.operatingSystemVersionString)
                        InfoRow(label: "Geraet", value: "Mac")
                        #endif
                    }
                    .padding()
                    .background(Color.gray.opacity(0.08))
                    .cornerRadius(12)

                    // Debug-Bereich (nur in Debug-Builds sichtbar)
                    #if DEBUG
                    Divider()

                    VStack(spacing: 12) {
                        HStack {
                            Image(systemName: "clock.arrow.circlepath")
                                .foregroundColor(.orange)
                            Text("Zeitsimulation")
                                .font(.headline)
                        }

                        VStack(spacing: 8) {
                            Text("Simuliertes Datum")
                                .font(.subheadline)
                                .foregroundColor(.secondary)

                            Text(debugSettings.simulatedDateString)
                                .font(.title3.bold())

                            if debugSettings.timeOffsetDays != 0 {
                                Text("(\(debugSettings.timeOffsetDays > 0 ? "+" : "")\(debugSettings.timeOffsetDays) Tage)")
                                    .font(.caption)
                                    .foregroundColor(.orange)
                            }
                        }
                        .padding()
                        .background(Color.gray.opacity(0.08))
                        .cornerRadius(12)

                        // Vorspulen
                        VStack(spacing: 8) {
                            Text("Vorspulen")
                                .font(.subheadline.bold())
                            HStack(spacing: 8) {
                                DebugButton(label: "+1", days: 1)
                                DebugButton(label: "+7", days: 7)
                                DebugButton(label: "+30", days: 30)
                                DebugButton(label: "+90", days: 90)
                            }
                        }

                        // Zurueckspulen
                        VStack(spacing: 8) {
                            Text("Zurueckspulen")
                                .font(.subheadline.bold())
                            HStack(spacing: 8) {
                                DebugButton(label: "-1", days: -1)
                                DebugButton(label: "-7", days: -7)
                                DebugButton(label: "-30", days: -30)
                                DebugButton(label: "-90", days: -90)
                            }
                        }

                        // Reset
                        Button(action: { debugSettings.resetTime() }) {
                            Label("Zuruecksetzen", systemImage: "arrow.counterclockwise")
                                .font(.subheadline.bold())
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 10)
                                .background(Color.red)
                                .cornerRadius(8)
                        }
                        .padding(.horizontal, 40)
                    }
                    #endif

                    Divider()

                    // Credits
                    VStack(spacing: 4) {
                        Text("Entwickelt von")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Text("Mathias Hubrich & Lilly (Claude)")
                            .font(.caption.bold())
                        Text("© 2026 Roboterwerk")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                    .padding(.bottom, 16)
                }
                .padding(.horizontal)
            }
            .navigationTitle("Beta-Info")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Fertig") { dismiss() }
                }
            }
        }
    }
}

// MARK: - Info-Zeile

private struct InfoRow: View {
    let label: String
    let value: String

    var body: some View {
        HStack {
            Text(label)
                .font(.subheadline)
                .foregroundColor(.secondary)
            Spacer()
            Text(value)
                .font(.subheadline.bold())
        }
    }
}

// MARK: - Debug-Button (kompakt)

#if DEBUG
private struct DebugButton: View {
    let label: String
    let days: Int
    @ObservedObject var debugSettings = DebugSettings.shared

    var body: some View {
        Button(action: { debugSettings.advanceTime(days: days) }) {
            Text(label)
                .font(.system(size: 13, weight: .bold))
                .foregroundColor(.white)
                .frame(width: 50, height: 36)
                .background(days > 0 ? Color.blue : Color.orange)
                .cornerRadius(8)
        }
    }
}
#endif

#Preview {
    BetaInfoView()
}
