//
//  HorseBackupServiceTests.swift
//  HippominderLilly2Tests
//
//  Autor: Mathias Hubrich & Claude (Anthropic)
//  Erstellt: 22. November 2026
//
//  Beschreibung: Prueft die Datensicherung - das Netz unter dem
//  iCloud-Abgleich. Wenn hier etwas klemmt, merkt man es ausgerechnet
//  dann, wenn die Pferde schon weg sind.
//
//  Die Erwartungen wurden vorher ausgefuehrt, nicht geschaetzt. Dass
//  Datumsangaben den Umweg nur auf die Sekunde genau ueberstehen, ist
//  gemessen (ISO 8601 ohne Sekundenbruchteile) und steht darum als
//  eigener Test da - nicht als Toleranz, die jemand spaeter fuer
//  Schlamperei haelt.
//

import XCTest
import SwiftData
@testable import Hippominder

final class HorseBackupServiceTests: XCTestCase {

    // MARK: - Werkzeug

    /// Ein Speicher nur im Arbeitsspeicher: kein iCloud, keine Datei,
    /// nach dem Test spurlos weg.
    private func frischerSpeicher() throws -> ModelContext {
        let schema = Schema([Horse.self])
        let container = try ModelContainer(
            for: schema,
            // Without .none, SwiftData picks up the app's iCloud entitlement
            // and starts mirroring even an in-memory store.
            configurations: [ModelConfiguration(schema: schema, isStoredInMemoryOnly: true,
                                                cloudKitDatabase: .none)]
        )
        return ModelContext(container)
    }

    private func pferd(
        _ name: String,
        id: UUID = UUID(),
        hufschmied: Int = 42,
        impfung: Int = 180,
        wurmkur: Int = 90,
        letzterHufschmied: Date = Date(timeIntervalSince1970: 1_790_000_000),
        tageVorher: Int = 3
    ) -> Horse {
        let p = Horse(
            name: name,
            hufschmiedIntervall: hufschmied,
            impfungIntervall: impfung,
            wurmkurIntervall: wurmkur,
            letzterHufschmiedTermin: letzterHufschmied,
            benachrichtigungTageVorher: tageVorher
        )
        p.id = id
        return p
    }

    private func alle(_ context: ModelContext) throws -> [Horse] {
        try context.fetch(FetchDescriptor<Horse>(sortBy: [SortDescriptor(\.name)]))
    }

    // MARK: - Der eigentliche Fall

    func testSicherungKommtVollstaendigZurueck() throws {
        let quelle = try frischerSpeicher()
        let kennung = UUID()
        let bina = pferd("Bina", id: kennung, hufschmied: 35, impfung: 365, wurmkur: 101,
                         tageVorher: 7)
        bina.notifyHufschmied = true
        bina.notifyTierarzt = false
        bina.notifyBesitzer = true
        quelle.insert(bina)
        quelle.insert(pferd("Fanta"))
        try quelle.save()

        let daten = try HorseBackupService.exportieren(from: quelle)

        // Auf ein frisches Geraet einlesen - der Fall nach einem Verlust
        let ziel = try frischerSpeicher()
        let ergebnis = try HorseBackupService.importieren(daten, into: ziel)

        XCTAssertEqual(ergebnis.neu, 2)
        XCTAssertEqual(ergebnis.aktualisiert, 0)

        let zurueck = try alle(ziel)
        XCTAssertEqual(zurueck.map(\.name), ["Bina", "Fanta"])

        let binaZurueck = try XCTUnwrap(zurueck.first { $0.name == "Bina" })
        XCTAssertEqual(binaZurueck.id, kennung, "Die Kennung muss erhalten bleiben, sonst entstehen Doppelgaenger")
        XCTAssertEqual(binaZurueck.hufschmiedIntervall, 35)
        XCTAssertEqual(binaZurueck.impfungIntervall, 365)
        XCTAssertEqual(binaZurueck.wurmkurIntervall, 101)
        XCTAssertEqual(binaZurueck.benachrichtigungTageVorher, 7)
        XCTAssertTrue(binaZurueck.notifyHufschmied)
        XCTAssertFalse(binaZurueck.notifyTierarzt)
        XCTAssertTrue(binaZurueck.notifyBesitzer)
    }

    func testTermineUeberstehenDenUmwegAufDieSekunde() throws {
        // Mit Sekundenbruchteilen, damit der Verlust auffaellt statt
        // zufaellig durchzurutschen
        let genau = Date(timeIntervalSince1970: 1_790_000_000.123456)
        let quelle = try frischerSpeicher()
        quelle.insert(pferd("Bina", letzterHufschmied: genau))
        try quelle.save()

        let ziel = try frischerSpeicher()
        try HorseBackupService.importieren(
            try HorseBackupService.exportieren(from: quelle), into: ziel)

        let zurueck = try XCTUnwrap(try alle(ziel).first)
        let abweichung = abs(zurueck.letzterHufschmiedTermin.timeIntervalSince(genau))

        // ISO 8601 schreibt keine Sekundenbruchteile. Bei Terminen auf
        // Tagesbasis ist das egal - aber es muss bekannt sein.
        XCTAssertLessThan(abweichung, 1.0, "Mehr als eine Sekunde Versatz waere ein echter Fehler")
        XCTAssertEqual(
            Int(zurueck.letzterHufschmiedTermin.timeIntervalSince1970),
            Int(genau.timeIntervalSince1970),
            "Auf die Sekunde genau muss es stimmen"
        )
    }

    // MARK: - Einlesen darf nie Daten vernichten

    func testEinlesenLaesstUnbekanntePferdeStehen() throws {
        let quelle = try frischerSpeicher()
        quelle.insert(pferd("Bina"))
        try quelle.save()
        let daten = try HorseBackupService.exportieren(from: quelle)

        // Auf dem Zielgeraet steht ein Pferd, das die Sicherung nicht kennt
        let ziel = try frischerSpeicher()
        ziel.insert(pferd("Amadeus"))
        try ziel.save()

        let ergebnis = try HorseBackupService.importieren(daten, into: ziel)

        XCTAssertEqual(ergebnis.neu, 1)
        XCTAssertEqual(ergebnis.aktualisiert, 0)
        XCTAssertEqual(try alle(ziel).map(\.name), ["Amadeus", "Bina"],
                       "Amadeus steht nicht in der Sicherung und muss trotzdem bleiben")
    }

    func testBekanntesPferdWirdAktualisiertStattVerdoppelt() throws {
        let kennung = UUID()
        let quelle = try frischerSpeicher()
        quelle.insert(pferd("Bina", id: kennung, hufschmied: 35))
        try quelle.save()
        let daten = try HorseBackupService.exportieren(from: quelle)

        // Dasselbe Pferd liegt schon da, aber mit anderem Intervall
        let ziel = try frischerSpeicher()
        ziel.insert(pferd("Bina", id: kennung, hufschmied: 60))
        try ziel.save()

        let ergebnis = try HorseBackupService.importieren(daten, into: ziel)

        XCTAssertEqual(ergebnis.neu, 0)
        XCTAssertEqual(ergebnis.aktualisiert, 1)
        let zurueck = try alle(ziel)
        XCTAssertEqual(zurueck.count, 1, "Kein Doppelgaenger")
        XCTAssertEqual(zurueck.first?.hufschmiedIntervall, 35, "Die Sicherung gewinnt")
    }

    func testZweimalEinlesenAendertNichtsMehr() throws {
        let quelle = try frischerSpeicher()
        quelle.insert(pferd("Bina"))
        quelle.insert(pferd("Fanta"))
        try quelle.save()
        let daten = try HorseBackupService.exportieren(from: quelle)

        let ziel = try frischerSpeicher()
        let erstes = try HorseBackupService.importieren(daten, into: ziel)
        let zweites = try HorseBackupService.importieren(daten, into: ziel)

        XCTAssertEqual(erstes.neu, 2)
        XCTAssertEqual(zweites.neu, 0, "Beim zweiten Mal darf nichts Neues entstehen")
        XCTAssertEqual(zweites.aktualisiert, 2)
        XCTAssertEqual(try alle(ziel).count, 2)
    }

    // MARK: - Was nicht passieren darf

    func testFremdeDateiWirftUndLaesstDenBestandInRuhe() throws {
        let ziel = try frischerSpeicher()
        ziel.insert(pferd("Bina"))
        try ziel.save()

        let unsinn = Data("{\"das\":\"ist keine Sicherung\"}".utf8)
        XCTAssertThrowsError(try HorseBackupService.importieren(unsinn, into: ziel))
        XCTAssertEqual(try alle(ziel).map(\.name), ["Bina"],
                       "Eine unlesbare Datei darf den Bestand nicht anruehren")
    }

    func testLeereSicherungLoeschtNichts() throws {
        let leer = try frischerSpeicher()
        let daten = try HorseBackupService.exportieren(from: leer)

        let ziel = try frischerSpeicher()
        ziel.insert(pferd("Bina"))
        try ziel.save()

        let ergebnis = try HorseBackupService.importieren(daten, into: ziel)

        XCTAssertEqual(ergebnis.neu, 0)
        XCTAssertEqual(ergebnis.aktualisiert, 0)
        XCTAssertEqual(try alle(ziel).count, 1, "Einlesen loescht grundsaetzlich nichts")
    }

    // MARK: - Dateiname

    func testDateinameTraegtDasDatum() {
        var teile = DateComponents()
        teile.year = 2026; teile.month = 11; teile.day = 9
        let tag = Calendar.current.date(from: teile)!
        XCTAssertEqual(HorseBackupService.dateiname(am: tag),
                       "Hippominder-Pferde-2026-11-09.json")
    }
}
