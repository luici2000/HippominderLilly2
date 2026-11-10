//
//  FlowerGeometryTests.swift
//  HippominderLilly2Tests
//
//  Autor: Mathias Hubrich & Claude (Anthropic)
//  Erstellt: 1. November 2026
//
//  Beschreibung: Prueft die Blumen-Rechnung, die alle drei Darstellungen
//  (Glas, Classic, Blume) und die Mini-Rose in der Liste gemeinsam nutzen.
//  Die Werte stammen aus Horse.preview und dem Original-Geraet.
//

import XCTest
@testable import Hippominder

final class FlowerGeometryTests: XCTestCase {

    // MARK: - Fuellstand

    func testFrischGesetzteBlumeIstLeer() {
        XCTAssertEqual(FlowerGeometry.filledPetals(remainingDays: 180, interval: 180), 0)
        XCTAssertEqual(FlowerGeometry.filledPetals(remainingDays: 42, interval: 42), 0)
    }

    func testWertAusHorsePreview() {
        // Mathias' Testpferd: Hufschmied 151/180, Impfung 46/49, Wurmkur 11/101
        XCTAssertEqual(FlowerGeometry.filledPetals(remainingDays: 151, interval: 180), 2)
        XCTAssertEqual(FlowerGeometry.filledPetals(remainingDays: 46, interval: 49), 1)
        XCTAssertEqual(FlowerGeometry.filledPetals(remainingDays: 11, interval: 101), 11)
    }

    func testHalbesIntervallFuelltSechsBlaetter() {
        XCTAssertEqual(FlowerGeometry.filledPetals(remainingDays: 50, interval: 100), 6)
    }

    func testFaelligUndUeberfaelligSindVoll() {
        XCTAssertEqual(FlowerGeometry.filledPetals(remainingDays: 0, interval: 90), 12)
        XCTAssertEqual(FlowerGeometry.filledPetals(remainingDays: -35, interval: 90), 12)
    }

    // MARK: - Grenzfaelle

    /// interval 0 machte die Division zu .infinity, und Int(.infinity) stuerzt ab
    func testIntervallNullStuerztNichtAb() {
        XCTAssertEqual(FlowerGeometry.filledPetals(remainingDays: 5, interval: 0), 0)
        XCTAssertEqual(FlowerGeometry.filledPetals(remainingDays: 0, interval: 0), 12)
        XCTAssertEqual(FlowerGeometry.filledPetals(remainingDays: 5, interval: -10), 0)
    }

    func testRestGroesserAlsIntervall() {
        XCTAssertEqual(FlowerGeometry.filledPetals(remainingDays: 999, interval: 10), 0)
    }

    func testErgebnisBleibtImmerImBereich() {
        for interval in [1, 7, 42, 90, 365, 3650] {
            for days in stride(from: -400, through: 400, by: 7) {
                let filled = FlowerGeometry.filledPetals(remainingDays: days, interval: interval)
                XCTAssertTrue((0...12).contains(filled),
                              "\(filled) Blaetter bei \(days)/\(interval) liegt ausserhalb 0...12")
            }
        }
    }

    // MARK: - Verlauf

    /// Die Blume darf beim Verstreichen der Tage nie zurueckspringen
    func testFuellstandWaechstMonoton() {
        for interval in [42, 90, 180, 365] {
            var previous = -1
            for remaining in stride(from: interval, through: 0, by: -1) {
                let filled = FlowerGeometry.filledPetals(remainingDays: remaining, interval: interval)
                XCTAssertGreaterThanOrEqual(
                    filled, previous,
                    "Intervall \(interval): bei \(remaining) Tagen Rest von \(previous) auf \(filled) gefallen"
                )
                previous = filled
            }
            XCTAssertEqual(previous, 12, "Intervall \(interval) endet nicht voll")
        }
    }

    // MARK: - Winkel

    /// Die Firmware des Geraets haelt fest: "Rosen fangen bei 1 Uhr an"
    func testErstesBlattLiegtAufEinUhr() {
        XCTAssertEqual(FlowerGeometry.angle(for: 0), 30)
    }

    func testLetztesBlattLiegtAufZwoelfUhr() {
        XCTAssertEqual(FlowerGeometry.angle(for: 11), 360)
    }

    func testBlaetterStehenInGleichenAbstaenden() {
        for index in 1..<FlowerGeometry.petalCount {
            let abstand = FlowerGeometry.angle(for: index) - FlowerGeometry.angle(for: index - 1)
            XCTAssertEqual(abstand, 30, accuracy: 0.0001)
        }
    }

    // MARK: - Aufloesung

    /// Ein Blatt deckt ein Zwoelftel ab, die Blume ist also vor dem Termin voll.
    /// Festgehalten, damit die Groessenordnung nicht unbemerkt kippt.
    func testBlumeIstVorFaelligkeitVoll() {
        let erwartet: [Int: Int] = [42: 3, 90: 7, 180: 14, 365: 30]
        for (interval, grenze) in erwartet {
            XCTAssertEqual(
                FlowerGeometry.filledPetals(remainingDays: grenze, interval: interval), 12,
                "Intervall \(interval) sollte bei \(grenze) Tagen Rest voll sein"
            )
            XCTAssertEqual(
                FlowerGeometry.filledPetals(remainingDays: grenze + 1, interval: interval), 11,
                "Intervall \(interval) sollte bei \(grenze + 1) Tagen Rest noch nicht voll sein"
            )
        }
    }
}
