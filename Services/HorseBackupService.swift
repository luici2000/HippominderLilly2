//
//  HorseBackupService.swift
//  Hippominder
//
//  Autor: Mathias Hubrich & Claude (Anthropic)
//  Erstellt: 9. November 2026
//
//  Beschreibung: Pferde als Datei sichern und zurueckholen.
//
//  Gedacht als Netz unter dem iCloud-Abgleich: wenn dort etwas schieflaeuft
//  oder jemand iCloud nicht nutzt, bleibt ein Weg, die Daten aus der Hand
//  zu geben und wiederzubekommen. Fotos sind absichtlich nicht enthalten -
//  sie machen die Datei um ein Vielfaches groesser und lassen sich leichter
//  neu waehlen als ein vergessenes Hufschmied-Intervall.
//

import Foundation
import SwiftData

// MARK: - Dateiformat

struct HorseBackupEntry: Codable {
    var id: UUID
    var name: String
    var hufschmiedIntervall: Int
    var impfungIntervall: Int
    var wurmkurIntervall: Int
    var letzterHufschmiedTermin: Date
    var letzterImpfungTermin: Date
    var letzterWurmkurTermin: Date
    var benachrichtigungTageVorher: Int
    var notifyApotheker: Bool
    var notifyBesitzer: Bool
    var notifyHufschmied: Bool
    var notifyStallbesitzer: Bool
    var notifyTierarzt: Bool
}

struct HorseBackup: Codable {
    /// Steigt, wenn sich das Format aendert - dann weiss ein spaeteres
    /// Einlesen, womit es zu tun hat
    var version: Int = 1
    var erstellt: Date
    var pferde: [HorseBackupEntry]
}

// MARK: - Sichern und Zurueckholen

enum HorseBackupService {

    static func exportieren(from context: ModelContext) throws -> Data {
        let descriptor = FetchDescriptor<Horse>(sortBy: [SortDescriptor(\.name)])
        let pferde = try context.fetch(descriptor)

        let sicherung = HorseBackup(
            erstellt: Date(),
            pferde: pferde.map { horse in
                HorseBackupEntry(
                    id: horse.id,
                    name: horse.name,
                    hufschmiedIntervall: horse.hufschmiedIntervall,
                    impfungIntervall: horse.impfungIntervall,
                    wurmkurIntervall: horse.wurmkurIntervall,
                    letzterHufschmiedTermin: horse.letzterHufschmiedTermin,
                    letzterImpfungTermin: horse.letzterImpfungTermin,
                    letzterWurmkurTermin: horse.letzterWurmkurTermin,
                    benachrichtigungTageVorher: horse.benachrichtigungTageVorher,
                    notifyApotheker: horse.notifyApotheker,
                    notifyBesitzer: horse.notifyBesitzer,
                    notifyHufschmied: horse.notifyHufschmied,
                    notifyStallbesitzer: horse.notifyStallbesitzer,
                    notifyTierarzt: horse.notifyTierarzt
                )
            }
        )

        let encoder = JSONEncoder()
        // Lesbar formatiert und nach Feldnamen sortiert: eine Sicherung,
        // in die man im Zweifel hineinschauen kann, ist mehr wert als
        // eine kompakte. Datumsangaben nach ISO 8601 - das verliert
        // Sekundenbruchteile, was bei Terminen auf Tagesbasis egal ist.
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        encoder.dateEncodingStrategy = .iso8601
        return try encoder.encode(sicherung)
    }

    /// Liest eine Sicherung ein. Bekannte Pferde werden aktualisiert,
    /// unbekannte angelegt - nichts wird geloescht, damit ein Einlesen
    /// nie Daten vernichtet.
    @discardableResult
    static func importieren(_ daten: Data, into context: ModelContext) throws -> (neu: Int, aktualisiert: Int) {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        let sicherung = try decoder.decode(HorseBackup.self, from: daten)

        let vorhandene = (try? context.fetch(FetchDescriptor<Horse>())) ?? []
        var nachID: [UUID: Horse] = [:]
        for pferd in vorhandene { nachID[pferd.id] = pferd }

        var neu = 0, aktualisiert = 0

        for eintrag in sicherung.pferde {
            if let pferd = nachID[eintrag.id] {
                uebernehmen(eintrag, in: pferd)
                aktualisiert += 1
            } else {
                let pferd = Horse(
                    name: eintrag.name,
                    hufschmiedIntervall: eintrag.hufschmiedIntervall,
                    impfungIntervall: eintrag.impfungIntervall,
                    wurmkurIntervall: eintrag.wurmkurIntervall,
                    letzterHufschmiedTermin: eintrag.letzterHufschmiedTermin,
                    letzterImpfungTermin: eintrag.letzterImpfungTermin,
                    letzterWurmkurTermin: eintrag.letzterWurmkurTermin,
                    benachrichtigungTageVorher: eintrag.benachrichtigungTageVorher
                )
                // Kennung uebernehmen, sonst entstehen beim naechsten
                // Einlesen Doppelgaenger
                pferd.id = eintrag.id
                uebernehmen(eintrag, in: pferd)
                context.insert(pferd)
                neu += 1
            }
        }

        try context.save()
        return (neu, aktualisiert)
    }

    private static func uebernehmen(_ eintrag: HorseBackupEntry, in pferd: Horse) {
        pferd.name = eintrag.name
        pferd.hufschmiedIntervall = eintrag.hufschmiedIntervall
        pferd.impfungIntervall = eintrag.impfungIntervall
        pferd.wurmkurIntervall = eintrag.wurmkurIntervall
        pferd.letzterHufschmiedTermin = eintrag.letzterHufschmiedTermin
        pferd.letzterImpfungTermin = eintrag.letzterImpfungTermin
        pferd.letzterWurmkurTermin = eintrag.letzterWurmkurTermin
        pferd.benachrichtigungTageVorher = eintrag.benachrichtigungTageVorher
        pferd.notifyApotheker = eintrag.notifyApotheker
        pferd.notifyBesitzer = eintrag.notifyBesitzer
        pferd.notifyHufschmied = eintrag.notifyHufschmied
        pferd.notifyStallbesitzer = eintrag.notifyStallbesitzer
        pferd.notifyTierarzt = eintrag.notifyTierarzt
    }

    /// Dateiname mit Datum, damit mehrere Sicherungen nebeneinander liegen
    static func dateiname(am datum: Date = Date()) -> String {
        let f = DateFormatter()
        f.dateFormat = "yyyy-MM-dd"
        return "Hippominder-Pferde-\(f.string(from: datum)).json"
    }
}
