//
//  Versionsinfo.swift
//  Hippominder
//
//  Autor: Mathias Hubrich & Claude (Anthropic)
//  Erstellt: 9. November 2026
//
//  Beschreibung: Welche Version laeuft hier gerade?
//
//  Warum das wichtig ist: Beim Bauen auf das Geraet sieht man von
//  aussen nicht, ob der neue Stand wirklich angekommen ist. Die
//  Versionsnummer allein hilft dabei nicht - sie bleibt zwischen
//  zwei Builds gleich. Die Bauzeit aendert sich bei jedem Build,
//  und genau die steht darum mit in der Zeile.
//
//  Liegt in Models, weil das Watch-Target nur WatchApp und Models
//  mitnimmt - so zeigen iPhone, Mac und Uhr dieselbe Auskunft.
//

import Foundation

enum Versionsinfo {

    /// Was im App Store stehen wuerde, z. B. "3.1.0"
    static var version: String {
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "?"
    }

    /// Die laufende Nummer dahinter
    static var build: String {
        Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "?"
    }

    /// Wann dieses Bundle gebaut wurde.
    ///
    /// Gelesen vom Programm selbst: beim Bauen wird es neu geschrieben
    /// und signiert, sein Aenderungsdatum ist also die Bauzeit. Einmal
    /// ermittelt und behalten - das Datum aendert sich zur Laufzeit nicht.
    static let bauzeit: Date? = {
        let kandidaten = [
            Bundle.main.executableURL,
            Bundle.main.url(forResource: "Info", withExtension: "plist"),
            Bundle.main.bundleURL
        ]
        for url in kandidaten.compactMap({ $0 }) {
            if let datum = try? url.resourceValues(forKeys: [.contentModificationDateKey])
                .contentModificationDate {
                return datum
            }
        }
        return nil
    }()

    /// Bauzeit kurz: "9.11. 15:42"
    static var bauzeitKurz: String {
        guard let bauzeit else { return "" }
        let f = DateFormatter()
        f.locale = Locale(identifier: "de_DE")
        f.setLocalizedDateFormatFromTemplate("d.M. HH:mm")
        return f.string(from: bauzeit)
    }

    /// Bauzeit lang, fuer die Beta-Info: "9. November 2026, 15:42"
    static var bauzeitLang: String {
        guard let bauzeit else { return "unbekannt" }
        let f = DateFormatter()
        f.locale = Locale(identifier: "de_DE")
        f.dateStyle = .long
        f.timeStyle = .short
        return f.string(from: bauzeit)
    }

    /// Die eine Zeile fuer die Fusszeile: "3.1.0 (2) · 9.11. 15:42"
    static var zeile: String {
        let zeit = bauzeitKurz
        let kopf = "\(version) (\(build))"
        return zeit.isEmpty ? kopf : "\(kopf) · \(zeit)"
    }

    /// Kurzform fuer die Uhr, wo die Zeile sonst umbricht: "3.1.0 · 15:42"
    static var zeileKurz: String {
        guard let bauzeit else { return version }
        let f = DateFormatter()
        f.locale = Locale(identifier: "de_DE")
        f.setLocalizedDateFormatFromTemplate("HH:mm")
        return "\(version) · \(f.string(from: bauzeit))"
    }
}
