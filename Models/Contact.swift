//
//  Contact.swift
//  Hippominder
//
//  Autor: Mathias Hubrich & Claude (Anthropic)
//  Erstellt: 12. Februar 2026
//  Version: 1.0.0
//
//  Beschreibung: Kontaktverwaltung fuer E-Mail-Benachrichtigungen
//

import Foundation

// MARK: - Kontakt-Typen

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

// MARK: - Kontakt-Eintrag

/// Einzelner Kontakt-Eintrag
struct ContactEntry: Codable, Identifiable {
    var id: String { type.rawValue }
    var type: ContactType
    var name: String
    var email: String
    var phone: String

    var hasEmail: Bool { !email.isEmpty }
}

// MARK: - Kontakt-Verwaltung (Singleton)

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

        switch eventType {
        case .hufschmied:
            if notifyFlags[.hufschmied] == true { result.append(contact(for: .hufschmied)) }
        case .impfung:
            if notifyFlags[.tierarzt] == true { result.append(contact(for: .tierarzt)) }
        case .wurmkur:
            if notifyFlags[.tierarzt] == true { result.append(contact(for: .tierarzt)) }
            if notifyFlags[.apotheker] == true { result.append(contact(for: .apotheker)) }
        }

        if notifyFlags[.besitzer] == true { result.append(contact(for: .besitzer)) }
        if notifyFlags[.stallbesitzer] == true { result.append(contact(for: .stallbesitzer)) }

        return result.filter { $0.hasEmail }
    }
}
