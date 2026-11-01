//
//  FlowerGeometry.swift
//  Hippominder
//
//  Autor: Mathias Hubrich & Claude (Anthropic)
//  Erstellt: 31. Oktober 2026
//  Verschoben nach Models: 1. November 2026
//
//  Beschreibung: Mass und Rechnung der Blume, geteilt von allen
//  Darstellungen. Liegt in Models, weil das Watch-Target nur WatchApp
//  und Models synchronisiert - so rechnet die Uhr mit denselben Werten
//  wie iPhone und Mac.
//
//  Quellen: Proportionen an flower_6.png (1024x1024) vermessen, Aufbau
//  bestaetigt durch die Original-Firmware in docs/original_geraet.
//

import Foundation
import CoreGraphics

/// Alle Werte als Anteil der Blumenbreite.
/// Die Original-Firmware (fet430_1.c) bestaetigt den Aufbau:
/// 12 Segmente, "Rosen fangen bei 1 Uhr an".
enum FlowerGeometry {
    static let petalWidth: CGFloat = 0.117
    static let petalLength: CGFloat = 0.255
    /// Abstand Blumenmitte -> Mitte eines Bluetenblatts
    static let radialDistance: CGFloat = 0.363
    static let stampDiameter: CGFloat = 0.298
    static let petalCount = 12

    /// Winkel eines Blattes. Index 0 liegt auf 1 Uhr, dann im Uhrzeigersinn.
    static func angle(for index: Int) -> Double {
        Double(index + 1) * 30
    }

    /// Wie viele Blaetter gefuellt sind. Eine Quelle fuer alle
    /// Darstellungen, damit sie nie auseinanderlaufen.
    ///
    /// Ein Blatt deckt ein Zwoelftel des Intervalls ab, die Blume ist also
    /// schon voll bevor der Termin faellig ist - bei 90 Tagen ab 7 Tagen
    /// Rest. Den Unterschied zu wirklich faellig macht der Mittelpunkt.
    static func filledPetals(remainingDays: Int, interval: Int) -> Int {
        if remainingDays <= 0 { return petalCount }
        // interval 0 wuerde die Division zu .infinity machen, Int(.infinity) trappt
        guard interval > 0 else { return 0 }
        let remainingShare = Double(remainingDays) / Double(interval)
        let filled = petalCount - Int(remainingShare * Double(petalCount))
        return min(petalCount, max(0, filled))
    }
}

/// Am Foto des Original-Displays vermessen. Weicht bewusst leicht von
/// FlowerGeometry ab: die LCD-Segmente sind schmaler als in den
/// PNG-Vorlagen, und der Punkt nach Ablauf ist deutlich fetter.
enum LCDGeometry {
    static let petalWidth: CGFloat = 0.089
    static let petalLength: CGFloat = 0.23
    static let radialDistance: CGFloat = 0.354
    /// Punkt nach Ablauf - reicht fast an die Blattwurzeln
    static let dotDiameter: CGFloat = 0.38
}
