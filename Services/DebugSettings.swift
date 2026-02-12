//
//  DebugSettings.swift
//  Hippominder
//
//  Autor: Mathias Hubrich & Claude (Anthropic)
//  Erstellt: 25. Januar 2026, 11:38 Uhr
//  Geaendert: 25. Januar 2026, 12:00 Uhr
//  Version: 1.0.0
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
            // Speichere in UserDefaults fuer Persistenz
            UserDefaults.standard.set(timeOffsetDays, forKey: "debugTimeOffsetDays")
        }
    }

    /// Debug-Modus aktiv
    @Published var isDebugModeEnabled: Bool = false

    private init() {
        // Lade gespeicherten Wert
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
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.locale = Locale(identifier: "de_DE")
        return formatter.string(from: simulatedDate)
    }
}

// MARK: - Debug View

struct DebugTimeView: View {
    @ObservedObject var debugSettings = DebugSettings.shared
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                // Aktuelles simuliertes Datum
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

                // Zeit vorspulen Buttons
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

                // Zeit zurueckspulen
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

                // Reset Button
                Button(action: {
                    debugSettings.resetTime()
                }) {
                    Label("Zeit zuruecksetzen", systemImage: "arrow.counterclockwise")
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
                    Button("Fertig") {
                        dismiss()
                    }
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
        Button(action: {
            debugSettings.advanceTime(days: days)
        }) {
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

// MARK: - Globale App-Einstellungen

/// Singleton fuer globale App-Einstellungen (z.B. Farbschema)
class GlobalSettings: ObservableObject {
    static let shared = GlobalSettings()

    /// Farbschema-Index (0 = Hellblau, 1 = Orange, 2 = Grau)
    @Published var flowerColorSchemeIndex: Int = 0 {
        didSet {
            UserDefaults.standard.set(flowerColorSchemeIndex, forKey: "flowerColorSchemeIndex")
        }
    }

    private init() {
        flowerColorSchemeIndex = UserDefaults.standard.integer(forKey: "flowerColorSchemeIndex")
    }

    /// Aktuelles Farbschema
    var flowerColorScheme: FlowerColorScheme {
        get { FlowerColorScheme.allCases[safe: flowerColorSchemeIndex] ?? .hellblau }
        set { flowerColorSchemeIndex = FlowerColorScheme.allCases.firstIndex(of: newValue) ?? 0 }
    }
}

// MARK: - Farbschema Enum (global)

enum FlowerColorScheme: String, CaseIterable, Identifiable {
    case hellblau = "Hellblau"
    case orange = "Orange"
    case grau = "Grau"

    var id: String { rawValue }

    // Leichte Farbe fuer OFF-Zustand
    var lightColor: Color {
        switch self {
        case .hellblau: return Color(red: 0.7, green: 0.85, blue: 1.0)
        case .orange: return Color(red: 1.0, green: 0.85, blue: 0.7)
        case .grau: return Color(red: 0.85, green: 0.85, blue: 0.85)
        }
    }

    // Kraeftige Farbe fuer ON-Zustand
    var strongColor: Color {
        switch self {
        case .hellblau: return Color(red: 0.2, green: 0.5, blue: 0.9)
        case .orange: return Color(red: 0.95, green: 0.55, blue: 0.2)
        case .grau: return Color(red: 0.4, green: 0.4, blue: 0.4)
        }
    }

    // Vorschau-Farbe fuer Auswahl-UI
    var previewColor: Color {
        switch self {
        case .hellblau: return Color(red: 0.4, green: 0.7, blue: 1.0)
        case .orange: return Color(red: 1.0, green: 0.7, blue: 0.4)
        case .grau: return Color(red: 0.6, green: 0.6, blue: 0.6)
        }
    }

    // Tint-Farbe fuer blendMode(.color) Overlay auf Graustufen-Bildern
    var tintColor: Color {
        switch self {
        case .hellblau: return Color(red: 0.35, green: 0.6, blue: 0.95)
        case .orange: return Color(red: 0.95, green: 0.55, blue: 0.2)
        case .grau: return Color(white: 0.6)
        }
    }
}

// MARK: - Array Extension fuer sicheren Zugriff

extension Array {
    subscript(safe index: Index) -> Element? {
        return indices.contains(index) ? self[index] : nil
    }
}

// MARK: - Globale Kontaktverwaltung

/// Kontakt-Typen fuer die Benachrichtigung
enum ContactType: String, CaseIterable, Identifiable, Codable {
    case apotheker = "Apotheker"
    case besitzer = "Besitzer"
    case hufschmied = "Hufschmied"
    case stallbesitzer = "Stallbesitzer"
    case tierarzt = "Tierarzt"

    var id: String { rawValue }

    var icon: String {
        switch self {
        case .apotheker: return "cross.case.fill"
        case .besitzer: return "person.fill"
        case .hufschmied: return "hammer.fill"
        case .stallbesitzer: return "house.fill"
        case .tierarzt: return "stethoscope"
        }
    }
}

/// Einzelner Kontakt-Eintrag
struct ContactEntry: Codable, Identifiable {
    var id: String { type.rawValue }
    var type: ContactType
    var name: String
    var email: String
    var phone: String

    var hasEmail: Bool { !email.isEmpty }
}

/// Singleton fuer globale Kontaktverwaltung
class ContactSettings: ObservableObject {
    static let shared = ContactSettings()

    @Published var contacts: [ContactEntry] {
        didSet { save() }
    }

    private let storageKey = "globalContacts"

    private init() {
        if let data = UserDefaults.standard.data(forKey: storageKey),
           let decoded = try? JSONDecoder().decode([ContactEntry].self, from: data) {
            contacts = decoded
        } else {
            // Standard-Kontakte anlegen
            contacts = ContactType.allCases.map { type in
                ContactEntry(type: type, name: "", email: "", phone: "")
            }
        }
    }

    private func save() {
        if let data = try? JSONEncoder().encode(contacts) {
            UserDefaults.standard.set(data, forKey: storageKey)
        }
    }

    /// Kontakt fuer einen Typ holen
    func contact(for type: ContactType) -> ContactEntry {
        contacts.first { $0.type == type } ?? ContactEntry(type: type, name: "", email: "", phone: "")
    }

    /// Kontakt aktualisieren
    func update(_ entry: ContactEntry) {
        if let index = contacts.firstIndex(where: { $0.type == entry.type }) {
            contacts[index] = entry
        }
    }

    /// Alle Kontakte mit E-Mail-Adresse
    var contactsWithEmail: [ContactEntry] {
        contacts.filter { $0.hasEmail }
    }

    /// Empfaenger fuer einen bestimmten Termin-Typ (intelligente Zuordnung)
    func recipients(for eventType: Horse.EventType, notifyFlags: [ContactType: Bool]) -> [ContactEntry] {
        var result: [ContactEntry] = []

        // Typ-spezifische Empfaenger
        switch eventType {
        case .hufschmied:
            if notifyFlags[.hufschmied] == true { result.append(contact(for: .hufschmied)) }
        case .impfung:
            if notifyFlags[.tierarzt] == true { result.append(contact(for: .tierarzt)) }
        case .wurmkur:
            if notifyFlags[.tierarzt] == true { result.append(contact(for: .tierarzt)) }
            if notifyFlags[.apotheker] == true { result.append(contact(for: .apotheker)) }
        }

        // Immer auch Besitzer und Stallbesitzer wenn aktiviert
        if notifyFlags[.besitzer] == true { result.append(contact(for: .besitzer)) }
        if notifyFlags[.stallbesitzer] == true { result.append(contact(for: .stallbesitzer)) }

        // Nur die mit E-Mail, dedupliziert
        return result.filter { $0.hasEmail }
    }
}
