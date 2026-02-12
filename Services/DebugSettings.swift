//
//  DebugSettings.swift
//  Hippominder
//
//  Autor: Mathias Hubrich & Claude (Anthropic)
//  Erstellt: 25. Januar 2026
//  Geaendert: 12. Februar 2026, 22:00 Uhr
//  Version: 2.0.0
//
//  Beschreibung: Debug-Einstellungen fuer Zeitsimulation
//

import Foundation
import SwiftUI

/// Singleton fuer Debug-Einstellungen
class DebugSettings: ObservableObject {
    static let shared = DebugSettings()

    /// Anzahl Tage die zur aktuellen Zeit addiert werden
    @Published var timeOffsetDays: Int = 0 {
        didSet {
            UserDefaults.standard.set(timeOffsetDays, forKey: "debugTimeOffsetDays")
        }
    }

    // Cached DateFormatter
    private static let dateFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateStyle = .medium
        f.locale = Locale(identifier: "de_DE")
        return f
    }()

    private init() {
        timeOffsetDays = UserDefaults.standard.integer(forKey: "debugTimeOffsetDays")
    }

    /// Simuliertes "aktuelles" Datum
    var simulatedDate: Date {
        Calendar.current.date(byAdding: .day, value: timeOffsetDays, to: Date()) ?? Date()
    }

    /// Zeit vorspulen
    func advanceTime(days: Int) {
        timeOffsetDays += days
    }

    /// Zeit zuruecksetzen
    func resetTime() {
        timeOffsetDays = 0
    }

    /// Formatiertes simuliertes Datum
    var simulatedDateString: String {
        Self.dateFormatter.string(from: simulatedDate)
    }
}

// MARK: - Debug View

struct DebugTimeView: View {
    @ObservedObject var debugSettings = DebugSettings.shared
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                VStack(spacing: 8) {
                    Text("Simuliertes Datum")
                        .font(.headline)

                    Text(debugSettings.simulatedDateString)
                        .font(.title)
                        .bold()

                    if debugSettings.timeOffsetDays != 0 {
                        Text("(\(debugSettings.timeOffsetDays > 0 ? "+" : "")\(debugSettings.timeOffsetDays) Tage)")
                            .font(.caption)
                            .foregroundColor(.orange)
                    }
                }
                .padding()
                .background(Color.gray.opacity(0.1))
                .cornerRadius(12)

                Divider()

                VStack(spacing: 16) {
                    Text("Zeit vorspulen")
                        .font(.headline)

                    HStack(spacing: 12) {
                        TimeButton(label: "+1 Tag", days: 1)
                        TimeButton(label: "+7 Tage", days: 7)
                        TimeButton(label: "+30 Tage", days: 30)
                    }

                    HStack(spacing: 12) {
                        TimeButton(label: "+90 Tage", days: 90)
                        TimeButton(label: "+180 Tage", days: 180)
                    }
                }

                Divider()

                VStack(spacing: 16) {
                    Text("Zeit zurückspulen")
                        .font(.headline)

                    HStack(spacing: 12) {
                        TimeButton(label: "-1 Tag", days: -1)
                        TimeButton(label: "-7 Tage", days: -7)
                        TimeButton(label: "-30 Tage", days: -30)
                    }
                }

                Spacer()

                Button(action: { debugSettings.resetTime() }) {
                    Label("Zeit zurücksetzen", systemImage: "arrow.counterclockwise")
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.red)
                        .cornerRadius(12)
                }
                .padding(.horizontal)
            }
            .padding()
            .navigationTitle("Debug: Zeit")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Fertig") { dismiss() }
                }
            }
        }
    }
}

struct TimeButton: View {
    let label: String
    let days: Int
    @ObservedObject var debugSettings = DebugSettings.shared

    var body: some View {
        Button(action: { debugSettings.advanceTime(days: days) }) {
            Text(label)
                .font(.subheadline)
                .bold()
                .foregroundColor(.white)
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
                .background(days > 0 ? Color.blue : Color.orange)
                .cornerRadius(8)
        }
    }
}

#Preview {
    DebugTimeView()
}
