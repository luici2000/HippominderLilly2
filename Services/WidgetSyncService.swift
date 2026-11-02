//
//  WidgetSyncService.swift
//  Hippominder
//
//  Autor: Mathias Hubrich & Claude (Anthropic)
//  Erstellt: 2. November 2026
//
//  Beschreibung: Spiegelt die Anzeigedaten fuer das Widget und stoesst
//  dessen Aktualisierung an. Laeuft nur auf iOS - macOS und watchOS
//  haben kein Homescreen-Widget.
//

#if os(iOS)
import Foundation
import SwiftData
import WidgetKit

@MainActor
enum WidgetSyncService {

    /// Schreibt den aktuellen Stand und laedt das Widget neu.
    /// Aufzurufen, wo sich Termine aendern - sonst zeigt der
    /// Startbildschirm veraltete Blumen.
    static func aktualisiere(using context: ModelContext) {
        let descriptor = FetchDescriptor<Horse>(sortBy: [SortDescriptor(\.name)])
        guard let horses = try? context.fetch(descriptor) else { return }
        aktualisiere(with: horses)
    }

    static func aktualisiere(with horses: [Horse]) {
        let pferde = horses.map { horse in
            WidgetHorse(
                id: horse.id,
                name: horse.name,
                termine: Horse.EventType.allCases.map { typ in
                    WidgetEvent(
                        typ: typ.rawValue,
                        verbleibendeTage: horse.tageBis(fuer: typ),
                        intervall: horse.holeIntervall(fuer: typ)
                    )
                }
            )
        }

        WidgetBridge.schreibe(WidgetSnapshot(pferde: pferde, stand: Date()))
        WidgetCenter.shared.reloadTimelines(ofKind: WidgetBridge.kind)
    }
}
#endif
