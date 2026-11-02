//
//  WidgetBridge.swift
//  Hippominder
//
//  Autor: Mathias Hubrich & Claude (Anthropic)
//  Erstellt: 2. November 2026
//
//  Beschreibung: Datenbruecke zwischen App und Widget.
//
//  Bewusst NICHT ueber eine geteilte SwiftData-Datenbank: die muesste
//  dafuer in eine App Group umziehen, und dabei waeren die vorhandenen
//  Pferde weg. Stattdessen spiegelt die App eine schlanke Kopie der
//  Anzeigedaten in die geteilten Einstellungen - wie beim Uhr-Sync auch.
//  Das Widget liest nur, schreibt nie.
//

import Foundation

// MARK: - Was das Widget braucht

struct WidgetEvent: Codable {
    /// Horse.EventType.rawValue
    let typ: String
    let verbleibendeTage: Int
    let intervall: Int

    var istUeberfaellig: Bool { verbleibendeTage <= 0 }

    var gefuellteBlaetter: Int {
        FlowerGeometry.filledPetals(remainingDays: verbleibendeTage, interval: intervall)
    }
}

struct WidgetHorse: Codable, Identifiable {
    let id: UUID
    let name: String
    let termine: [WidgetEvent]

    /// Der naechste anstehende Termin - das zeigt ein kleines Widget
    var dringendster: WidgetEvent? {
        termine.min(by: { $0.verbleibendeTage < $1.verbleibendeTage })
    }

    var ueberfaelligeAnzahl: Int {
        termine.filter(\.istUeberfaellig).count
    }
}

struct WidgetSnapshot: Codable {
    let pferde: [WidgetHorse]
    let stand: Date

    static let leer = WidgetSnapshot(pferde: [], stand: .distantPast)
}

// MARK: - Lesen und Schreiben

enum WidgetBridge {
    /// Muss in den Entitlements von App und Widget stehen
    static let appGroup = "group.com.roboterwerk.HippominderLilly2"
    private static let schluessel = "widgetSnapshot"
    /// Name des Widgets fuer WidgetCenter.reloadTimelines
    static let kind = "HippominderWidget"

    private static var speicher: UserDefaults? {
        UserDefaults(suiteName: appGroup)
    }

    static func schreibe(_ snapshot: WidgetSnapshot) {
        guard let speicher,
              let daten = try? JSONEncoder().encode(snapshot) else { return }
        speicher.set(daten, forKey: schluessel)
    }

    static func lies() -> WidgetSnapshot {
        guard let speicher,
              let daten = speicher.data(forKey: schluessel),
              let snapshot = try? JSONDecoder().decode(WidgetSnapshot.self, from: daten)
        else { return .leer }
        return snapshot
    }
}
