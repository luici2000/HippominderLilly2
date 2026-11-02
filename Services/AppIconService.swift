//
//  AppIconService.swift
//  Hippominder
//
//  Autor: Mathias Hubrich & Claude (Anthropic)
//  Erstellt: 2. November 2026
//
//  Beschreibung: Wechselt das App-Symbol, wenn Termine ueberfaellig sind.
//  Die rote Fassung entsteht aus Mathias' Original-Symbol - gleiches
//  Pferd, nur der Grund ins Rote verschoben.
//
//  iOS zeigt bei jedem Wechsel einen Hinweis an. Darum wird nur
//  gewechselt, wenn sich der Zustand wirklich aendert - nicht bei jedem
//  Start und nicht bei jedem Blick in die App.
//

#if os(iOS)
import UIKit

@MainActor
enum AppIconService {
    /// Name aus CFBundleAlternateIcons in der Info.plist
    private static let ueberfaelligName = "Ueberfaellig"

    static func aktualisiere(for horses: [Horse]) {
        let hatUeberfaellige = horses.contains { horse in
            Horse.EventType.allCases.contains { horse.tageBis(fuer: $0) <= 0 }
        }
        setze(ueberfaellig: hatUeberfaellige)
    }

    static func setze(ueberfaellig: Bool) {
        let anwendung = UIApplication.shared
        guard anwendung.supportsAlternateIcons else { return }

        let gewuenscht: String? = ueberfaellig ? ueberfaelligName : nil

        // Ohne diesen Vergleich kaeme der Systemhinweis bei jedem Aufruf
        guard anwendung.alternateIconName != gewuenscht else { return }

        anwendung.setAlternateIconName(gewuenscht) { fehler in
            if let fehler {
                print("App-Symbol konnte nicht gewechselt werden: \(fehler)")
            }
        }
    }
}
#endif
