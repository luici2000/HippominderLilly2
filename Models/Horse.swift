//
//  Horse.swift
//  Hippominder
//
//  Autor: Mathias Hubrich & Claude (Anthropic)
//  Erstellt: 24. Januar 2026
//  Geaendert: 12. Februar 2026, 22:00 Uhr
//  Version: 2.0.0
//
//  Beschreibung: Datenmodell fuer Pferde mit Timer-Funktionen
//

import Foundation
import SwiftData
import SwiftUI

#if canImport(UIKit)
import UIKit
#elseif canImport(AppKit)
import AppKit
#endif

@Model
class Horse {
    var id: UUID
    var name: String
    var imageData: Data?

    // Intervalle in Tagen
    var hufschmiedIntervall: Int
    var impfungIntervall: Int
    var wurmkurIntervall: Int

    // Letzte Termine
    var letzterHufschmiedTermin: Date
    var letzterImpfungTermin: Date
    var letzterWurmkurTermin: Date

    // Benachrichtigung Tage vorher
    var benachrichtigungTageVorher: Int

    // Benachrichtigungs-Flags (pro Pferd, Kontaktdaten global in ContactSettings)
    var notifyApotheker: Bool = false
    var notifyBesitzer: Bool = false
    var notifyHufschmied: Bool = false
    var notifyStallbesitzer: Bool = false
    var notifyTierarzt: Bool = false

    init(
        name: String,
        imageData: Data? = nil,
        hufschmiedIntervall: Int = 42,
        impfungIntervall: Int = 180,
        wurmkurIntervall: Int = 90,
        letzterHufschmiedTermin: Date = Date(),
        letzterImpfungTermin: Date = Date(),
        letzterWurmkurTermin: Date = Date(),
        benachrichtigungTageVorher: Int = 3
    ) {
        self.id = UUID()
        self.name = name
        self.imageData = imageData
        self.hufschmiedIntervall = hufschmiedIntervall
        self.impfungIntervall = impfungIntervall
        self.wurmkurIntervall = wurmkurIntervall
        self.letzterHufschmiedTermin = letzterHufschmiedTermin
        self.letzterImpfungTermin = letzterImpfungTermin
        self.letzterWurmkurTermin = letzterWurmkurTermin
        self.benachrichtigungTageVorher = benachrichtigungTageVorher
    }

    // MARK: - Berechnete Eigenschaften

    /// Plattformuebergreifende Bild-Property
    var image: Image? {
        guard let data = imageData else { return nil }
        #if canImport(UIKit)
        guard let uiImage = UIImage(data: data) else { return nil }
        return Image(uiImage: uiImage)
        #elseif canImport(AppKit)
        guard let nsImage = NSImage(data: data) else { return nil }
        return Image(nsImage: nsImage)
        #endif
    }

    // Aktuelles Datum (nutzt Debug-Offset wenn aktiv)
    private var currentDate: Date {
        DebugSettings.shared.simulatedDate
    }

    // Tage bis zum naechsten Termin (negativ = ueberfaellig)
    var tageBisHufschmied: Int {
        let naechsterTermin = Calendar.current.date(byAdding: .day, value: hufschmiedIntervall, to: letzterHufschmiedTermin)!
        return Calendar.current.dateComponents([.day], from: currentDate, to: naechsterTermin).day ?? 0
    }

    var tageBisImpfung: Int {
        let naechsterTermin = Calendar.current.date(byAdding: .day, value: impfungIntervall, to: letzterImpfungTermin)!
        return Calendar.current.dateComponents([.day], from: currentDate, to: naechsterTermin).day ?? 0
    }

    var tageBisWurmkur: Int {
        let naechsterTermin = Calendar.current.date(byAdding: .day, value: wurmkurIntervall, to: letzterWurmkurTermin)!
        return Calendar.current.dateComponents([.day], from: currentDate, to: naechsterTermin).day ?? 0
    }

    // Naechste Termine
    var naechsterHufschmiedTermin: Date {
        Calendar.current.date(byAdding: .day, value: hufschmiedIntervall, to: letzterHufschmiedTermin)!
    }

    var naechsterImpfungTermin: Date {
        Calendar.current.date(byAdding: .day, value: impfungIntervall, to: letzterImpfungTermin)!
    }

    var naechsterWurmkurTermin: Date {
        Calendar.current.date(byAdding: .day, value: wurmkurIntervall, to: letzterWurmkurTermin)!
    }

    // Fortschritt (0.0 - 1.0)
    func fortschritt(fuer typ: EventType) -> Double {
        let tageVergangen: Int
        let intervall: Int

        switch typ {
        case .hufschmied:
            tageVergangen = Calendar.current.dateComponents([.day], from: letzterHufschmiedTermin, to: currentDate).day ?? 0
            intervall = hufschmiedIntervall
        case .impfung:
            tageVergangen = Calendar.current.dateComponents([.day], from: letzterImpfungTermin, to: currentDate).day ?? 0
            intervall = impfungIntervall
        case .wurmkur:
            tageVergangen = Calendar.current.dateComponents([.day], from: letzterWurmkurTermin, to: currentDate).day ?? 0
            intervall = wurmkurIntervall
        }

        return min(1.0, Double(tageVergangen) / Double(intervall))
    }

    // Gefuellte Bluetenblaetter (0-12)
    func gefuellteBlätter(fuer typ: EventType) -> Int {
        Int(fortschritt(fuer: typ) * 12)
    }

    // MARK: - Termin-Typen

    enum EventType: String, CaseIterable {
        case hufschmied = "Hufschmied"
        case impfung = "Impfung"
        case wurmkur = "Wurmkur"

        var localizedName: String {
            switch self {
            case .hufschmied: return String(localized: "Hufschmied")
            case .impfung: return String(localized: "Impfung")
            case .wurmkur: return String(localized: "Wurmkur")
            }
        }

        var symbol: String {
            switch self {
            case .hufschmied: return "schmied"
            case .impfung: return "spritze"
            case .wurmkur: return "wurm"
            }
        }

        var systemSymbol: String {
            switch self {
            case .hufschmied: return "hammer.fill"
            case .impfung: return "syringe.fill"
            case .wurmkur: return "leaf.fill"
            }
        }
    }

    // MARK: - Termin aktualisieren

    func setzeTermin(_ date: Date, fuer typ: EventType) {
        switch typ {
        case .hufschmied: letzterHufschmiedTermin = date
        case .impfung: letzterImpfungTermin = date
        case .wurmkur: letzterWurmkurTermin = date
        }
    }

    func holeTermin(fuer typ: EventType) -> Date {
        switch typ {
        case .hufschmied: return letzterHufschmiedTermin
        case .impfung: return letzterImpfungTermin
        case .wurmkur: return letzterWurmkurTermin
        }
    }

    func holeIntervall(fuer typ: EventType) -> Int {
        switch typ {
        case .hufschmied: return hufschmiedIntervall
        case .impfung: return impfungIntervall
        case .wurmkur: return wurmkurIntervall
        }
    }

    func setzeIntervall(_ value: Int, fuer typ: EventType) {
        switch typ {
        case .hufschmied: hufschmiedIntervall = value
        case .impfung: impfungIntervall = value
        case .wurmkur: wurmkurIntervall = value
        }
    }

    func tageBis(fuer typ: EventType) -> Int {
        switch typ {
        case .hufschmied: return tageBisHufschmied
        case .impfung: return tageBisImpfung
        case .wurmkur: return tageBisWurmkur
        }
    }

    func naechsterTermin(fuer typ: EventType) -> Date {
        switch typ {
        case .hufschmied: return naechsterHufschmiedTermin
        case .impfung: return naechsterImpfungTermin
        case .wurmkur: return naechsterWurmkurTermin
        }
    }
}

// MARK: - Preview Helper

#if DEBUG
extension Horse {
    static var preview: Horse {
        Horse(
            name: "Luici",
            hufschmiedIntervall: 180,
            impfungIntervall: 49,
            wurmkurIntervall: 101,
            letzterHufschmiedTermin: Calendar.current.date(byAdding: .day, value: -29, to: Date())!,
            letzterImpfungTermin: Calendar.current.date(byAdding: .day, value: -3, to: Date())!,
            letzterWurmkurTermin: Calendar.current.date(byAdding: .day, value: -90, to: Date())!
        )
    }
}
#endif
