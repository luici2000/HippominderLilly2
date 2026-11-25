//
//  HorseDatumTests.swift
//  HippominderLilly2Tests
//
//  Autor: Mathias Hubrich & Claude (Anthropic)
//  Erstellt: 25. November 2026
//
//  Beschreibung: Prueft die Datumsrechnung am Pferd. Darauf steht alles
//  andere: die Blume, die Ampelfarbe, die Benachrichtigungen, die Zahl am
//  App-Symbol. Ist "Tage bis" um eins daneben, ist die ganze App daneben.
//
//  Der Anlass: In den Benachrichtigungen lag genau hier ein Fehler - dort
//  wurde mit Uhrzeiten gerechnet statt mit Kalendertagen, und am
//  Faelligkeitstag kam darum keine Meldung. Am Pferd ist es richtig
//  gemacht; dieser Test haelt es fest.
//

import XCTest
@testable import Hippominder

final class HorseDatumTests: XCTestCase {

    private var kalender: Calendar { Calendar.current }
    private var urspruenglicherVersatz = 0

    override func setUp() {
        super.setUp()
        // Die Zeitreise aus dem Debug-Menue wuerde jede Erwartung
        // verschieben - fuer die Dauer des Tests auf heute zurueck
        urspruenglicherVersatz = DebugSettings.shared.timeOffsetDays
        DebugSettings.shared.resetTime()
    }

    override func tearDown() {
        DebugSettings.shared.timeOffsetDays = urspruenglicherVersatz
        super.tearDown()
    }

    /// Ein Pferd, dessen Hufschmied-Termin genau in `tage` Tagen faellig
    /// ist - zur angegebenen Uhrzeit an jenem Tag.
    private func pferdMitHufschmied(in tage: Int, umUhr stunde: Int, minute: Int = 0) -> Horse {
        let intervall = 42
        let heuteUmX = kalender.date(
            bySettingHour: stunde, minute: minute, second: 0, of: Date()
        )!
        let faellig = kalender.date(byAdding: .day, value: tage, to: heuteUmX)!
        let letzter = kalender.date(byAdding: .day, value: -intervall, to: faellig)!
        return Horse(name: "Testpferd",
                     hufschmiedIntervall: intervall,
                     letzterHufschmiedTermin: letzter)
    }

    // MARK: - Kalendertage, nicht Stunden

    func testTerminHeuteZeigtNullTageZuJederUhrzeit() {
        // Frueh am Tag, mittags, kurz vor Mitternacht: immer "heute".
        // Mit Stundenrechnung kaeme hier je nach Tageszeit 0 oder -1 heraus.
        for stunde in [0, 9, 12, 23] {
            let pferd = pferdMitHufschmied(in: 0, umUhr: stunde, minute: stunde == 23 ? 50 : 0)
            XCTAssertEqual(pferd.tageBisHufschmied, 0,
                           "Ein Termin von heute \(stunde) Uhr muss 0 Tage zeigen, nicht -1")
        }
    }

    func testMorgenIstEinTagAuchKurzVorMitternacht() {
        // Termin morgen um 00:05, jetzt ist es irgendwann heute: ein Tag.
        // Nach Stunden gerechnet waeren es je nach Uhrzeit null.
        let pferd = pferdMitHufschmied(in: 1, umUhr: 0, minute: 5)
        XCTAssertEqual(pferd.tageBisHufschmied, 1)
    }

    func testUeberfaelligZaehltNegativ() {
        let pferd = pferdMitHufschmied(in: -3, umUhr: 12)
        XCTAssertEqual(pferd.tageBisHufschmied, -3,
                       "Ueberfaellig muss negativ zaehlen - davon haengen Ampelfarbe und Mahnung ab")
    }

    // MARK: - Naechster Termin

    func testNaechsterTerminIstLetzterPlusIntervall() {
        let letzter = Date(timeIntervalSince1970: 1_790_000_000)
        let pferd = Horse(name: "Bina", hufschmiedIntervall: 35, letzterHufschmiedTermin: letzter)
        let erwartet = kalender.date(byAdding: .day, value: 35, to: letzter)!
        XCTAssertEqual(pferd.naechsterHufschmiedTermin, erwartet)
    }

    // MARK: - Die drei Termine duerfen sich nicht vermischen

    func testJederTerminGehoertZuSeinemTyp() {
        // Drei fast gleiche switch-Bloecke im Modell - genau dort versteckt
        // sich ein vertippter Fall, und man sieht es nur am falschen Datum.
        let pferd = Horse(name: "Bina")
        let hufschmied = Date(timeIntervalSince1970: 1_700_000_000)
        let impfung = Date(timeIntervalSince1970: 1_710_000_000)
        let wurmkur = Date(timeIntervalSince1970: 1_720_000_000)

        pferd.setzeTermin(hufschmied, fuer: .hufschmied)
        pferd.setzeTermin(impfung, fuer: .impfung)
        pferd.setzeTermin(wurmkur, fuer: .wurmkur)

        XCTAssertEqual(pferd.holeTermin(fuer: .hufschmied), hufschmied)
        XCTAssertEqual(pferd.holeTermin(fuer: .impfung), impfung)
        XCTAssertEqual(pferd.holeTermin(fuer: .wurmkur), wurmkur)
        XCTAssertEqual(pferd.letzterHufschmiedTermin, hufschmied)
        XCTAssertEqual(pferd.letzterImpfungTermin, impfung)
        XCTAssertEqual(pferd.letzterWurmkurTermin, wurmkur)
    }

    func testJedesIntervallGehoertZuSeinemTyp() {
        let pferd = Horse(name: "Bina")
        pferd.setzeIntervall(35, fuer: .hufschmied)
        pferd.setzeIntervall(365, fuer: .impfung)
        pferd.setzeIntervall(101, fuer: .wurmkur)

        XCTAssertEqual(pferd.holeIntervall(fuer: .hufschmied), 35)
        XCTAssertEqual(pferd.holeIntervall(fuer: .impfung), 365)
        XCTAssertEqual(pferd.holeIntervall(fuer: .wurmkur), 101)
        XCTAssertEqual(pferd.hufschmiedIntervall, 35)
        XCTAssertEqual(pferd.impfungIntervall, 365)
        XCTAssertEqual(pferd.wurmkurIntervall, 101)
    }

    func testTageBisFolgtDemTypUndNichtDerReihenfolge() {
        // Alle drei auf verschiedene Abstaende setzen und einzeln pruefen
        let pferd = Horse(name: "Bina")
        let heute = kalender.startOfDay(for: Date())
        pferd.setzeIntervall(10, fuer: .hufschmied)
        pferd.setzeIntervall(20, fuer: .impfung)
        pferd.setzeIntervall(30, fuer: .wurmkur)
        pferd.setzeTermin(heute, fuer: .hufschmied)
        pferd.setzeTermin(heute, fuer: .impfung)
        pferd.setzeTermin(heute, fuer: .wurmkur)

        XCTAssertEqual(pferd.tageBis(fuer: .hufschmied), 10)
        XCTAssertEqual(pferd.tageBis(fuer: .impfung), 20)
        XCTAssertEqual(pferd.tageBis(fuer: .wurmkur), 30)
    }
}
