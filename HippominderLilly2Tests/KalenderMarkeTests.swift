//
//  KalenderMarkeTests.swift
//  Welcher Kalendereintrag darf Hippominder loeschen?
//
//  Das ist die gefaehrliche Stelle des Kalenderabgleichs: Vor jedem neuen
//  Eintrag wird der alte geloescht. Erwischt die Regel einen fremden
//  Termin, ist er weg. Darum steht hier jeder Fall einzeln.
//

import XCTest
@testable import Hippominder

final class KalenderMarkeTests: XCTestCase {

    private let bina = UUID()
    private let anderesPferd = UUID()

    private func gehoert(titel: String?, notiz: String?, url: URL?,
                         id: UUID? = nil, name: String = "Bina",
                         typ: Horse.EventType = .hufschmied) -> Bool {
        KalenderMarke.gehoertZu(titel: titel, notiz: notiz, url: url,
                                pferdID: id ?? bina, pferdName: name, typ: typ)
    }

    func testEigenerEintragMitMarke() {
        let url = KalenderMarke.url(pferdID: bina, typ: .hufschmied)
        XCTAssertTrue(gehoert(titel: "Bina: Hufschmied", notiz: "Hippominder …", url: url))
    }

    func testMarkeFindetAuchNachUmbenennung() {
        let url = KalenderMarke.url(pferdID: bina, typ: .hufschmied)
        XCTAssertTrue(gehoert(titel: "Bina: Hufschmied", notiz: nil, url: url, name: "Bina vom Hof"))
    }

    func testMarkeEinesAnderenTerminsBleibt() {
        let url = KalenderMarke.url(pferdID: bina, typ: .impfung)
        XCTAssertFalse(gehoert(titel: "Bina: Hufschmied", notiz: "Hippominder", url: url))
    }

    func testMarkeEinesAnderenPferdesBleibt() {
        let url = KalenderMarke.url(pferdID: anderesPferd, typ: .hufschmied)
        XCTAssertFalse(gehoert(titel: "Bina: Hufschmied", notiz: "Hippominder", url: url))
    }

    func testAltbestandVomKnopfWirdErkannt() {
        XCTAssertTrue(gehoert(titel: "Bina: Hufschmied",
                              notiz: "Hippominder Erinnerung für Bina\nIntervall: 42 Tage", url: nil))
    }

    /// Mathias' eigener Termin, zufaellig gleich benannt: bleibt stehen
    func testGleicherTitelOhneHippominderNotizBleibt() {
        XCTAssertFalse(gehoert(titel: "Bina: Hufschmied", notiz: "Schmied Huber, 80 €", url: nil))
        XCTAssertFalse(gehoert(titel: "Bina: Hufschmied", notiz: nil, url: nil))
    }

    /// Fremde URL (z. B. ein Termin aus einer anderen App) wird nie angefasst
    func testFremdeURLBleibtAuchBeiPassendemTitel() {
        XCTAssertFalse(gehoert(titel: "Bina: Hufschmied", notiz: "Hippominder",
                               url: URL(string: "https://example.com/termin")!))
    }

    func testAnderesPferdGleicherTypBleibt() {
        XCTAssertFalse(gehoert(titel: "Lilly: Hufschmied",
                               notiz: "Hippominder Erinnerung für Lilly", url: nil))
    }
}
