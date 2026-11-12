//
//  GlobalSettings.swift
//  Hippominder
//
//  Autor: Mathias Hubrich & Claude (Anthropic)
//  Erstellt: 12. Februar 2026
//  Version: 1.0.0
//
//  Beschreibung: Globale App-Einstellungen und Farbschema
//

import Foundation
import SwiftUI

#if canImport(UIKit)
import UIKit
#elseif canImport(AppKit)
import AppKit
#endif

// MARK: - Globale App-Einstellungen

/// Singleton fuer globale App-Einstellungen (z.B. Farbschema)
class GlobalSettings: ObservableObject {
    static let shared = GlobalSettings()

    /// Farbschema-Index (0 = Hellblau, 1 = Orange, 2 = Grau)
    @Published var flowerColorSchemeIndex: Int = 0 {
        didSet {
            UserDefaults.standard.set(flowerColorSchemeIndex, forKey: "flowerColorSchemeIndex")
        }
    }

    /// Darstellung der Blumen-Timer: Glass, Classic oder Blume
    @Published var designModeRaw: String = DesignMode.glass.rawValue {
        didSet { UserDefaults.standard.set(designModeRaw, forKey: "designMode") }
    }

    /// Freie Glasfarbe fuer die Glasblumen (RGB 0...1)
    @Published var glassTintRed: Double = 0.34 { didSet { persistTint() } }
    @Published var glassTintGreen: Double = 0.62 { didSet { persistTint() } }
    @Published var glassTintBlue: Double = 0.94 { didSet { persistTint() } }

    private init() {
        flowerColorSchemeIndex = UserDefaults.standard.integer(forKey: "flowerColorSchemeIndex")

        let d = UserDefaults.standard
        if let saved = d.string(forKey: "designMode") {
            designModeRaw = saved
        }
        if d.object(forKey: "glassTintRed") != nil {
            glassTintRed = d.double(forKey: "glassTintRed")
            glassTintGreen = d.double(forKey: "glassTintGreen")
            glassTintBlue = d.double(forKey: "glassTintBlue")
        } else {
            // Bestandsinstallation: Glasfarbe aus dem bisher gewaehlten Schema uebernehmen
            let rgb = flowerColorScheme.glassRGB
            glassTintRed = rgb.red
            glassTintGreen = rgb.green
            glassTintBlue = rgb.blue
        }
    }

    /// Aktuelles Farbschema. Setzen uebernimmt auch die Glasfarbe des Schemas,
    /// damit die drei Kugeln auf der Hauptseite die Glasblumen aller Pferde steuern.
    var flowerColorScheme: FlowerColorScheme {
        get { FlowerColorScheme.allCases[safe: flowerColorSchemeIndex] ?? .hellblau }
        set {
            flowerColorSchemeIndex = FlowerColorScheme.allCases.firstIndex(of: newValue) ?? 0
            let rgb = newValue.glassRGB
            glassTintRed = rgb.red
            glassTintGreen = rgb.green
            glassTintBlue = rgb.blue
        }
    }

    /// Die Farbe, die zu den Blumen auf dem Bildschirm passt.
    ///
    /// Glas: die frei gewaehlte Glasfarbe. Blume: die Farbe des gewaehlten
    /// Schemas, denn die PNG-Blumen kennen nur Hellblau, Orange und Grau.
    /// Vorher nahmen die Tasten unter orangen Blumen die lila Glasfarbe -
    /// das brachte die Farbschemata durcheinander (Mathias, 12.11.2026).
    var akzentFarbe: Color {
        designMode == .blume ? flowerColorScheme.glassColor : glassTint
    }

    /// Das Schema, dessen Glasfarbe gerade aktiv ist - nil bei frei gewaehlter Farbe
    var matchingColorScheme: FlowerColorScheme? {
        FlowerColorScheme.allCases.first { scheme in
            let rgb = scheme.glassRGB
            return abs(rgb.red - glassTintRed) < 0.02
                && abs(rgb.green - glassTintGreen) < 0.02
                && abs(rgb.blue - glassTintBlue) < 0.02
        }
    }

    /// Aktuelle Darstellung
    var designMode: DesignMode {
        get { DesignMode(rawValue: designModeRaw) ?? .glass }
        set { designModeRaw = newValue.rawValue }
    }

    /// Glasfarbe als SwiftUI Color - beliebige Farbe, nicht auf Schemata beschraenkt
    var glassTint: Color {
        get { Color(red: glassTintRed, green: glassTintGreen, blue: glassTintBlue) }
        set {
            let rgb = newValue.rgbComponents
            glassTintRed = rgb.red
            glassTintGreen = rgb.green
            glassTintBlue = rgb.blue
        }
    }

    private func persistTint() {
        let d = UserDefaults.standard
        d.set(glassTintRed, forKey: "glassTintRed")
        d.set(glassTintGreen, forKey: "glassTintGreen")
        d.set(glassTintBlue, forKey: "glassTintBlue")
    }
}

// MARK: - Color nach RGB zerlegen

extension Color {
    /// Zerlegt die Farbe in sRGB-Komponenten (0...1)
    var rgbComponents: (red: Double, green: Double, blue: Double) {
        #if canImport(UIKit)
        var r: CGFloat = 0, g: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
        UIColor(self).getRed(&r, green: &g, blue: &b, alpha: &a)
        return (Double(r), Double(g), Double(b))
        #elseif canImport(AppKit)
        let ns = NSColor(self).usingColorSpace(.sRGB) ?? .white
        return (Double(ns.redComponent), Double(ns.greenComponent), Double(ns.blueComponent))
        #else
        return (0.34, 0.62, 0.94)
        #endif
    }
}

// MARK: - Darstellung

/// Drei Darstellungen derselben Blume:
/// - glass:   iOS 26 Liquid Glass, Pferdefoto scheint durch
/// - classic: das LCD des Original-Geraets von 2006
/// - blume:   Mathias' vorgerenderte Icon-Composer-Blumen
enum DesignMode: String, CaseIterable, Identifiable {
    case glass = "Glass"
    case classic = "Classic"
    case blume = "Blume"

    var id: String { rawValue }

    var localizedName: String {
        switch self {
        case .glass: return String(localized: "Glas")
        case .classic: return String(localized: "Classic")
        case .blume: return String(localized: "Blume")
        }
    }

    var icon: String {
        switch self {
        case .glass: return "circle.hexagongrid.fill"
        case .classic: return "dial.medium.fill"
        case .blume: return "camera.macro"
        }
    }

}

// MARK: - Farbschema Enum

enum FlowerColorScheme: String, CaseIterable, Identifiable {
    case hellblau = "Hellblau"
    case orange = "Orange"
    case grau = "Grau"

    var id: String { rawValue }

    /// Kraeftige Farbe fuer ON-Zustand (used by GlobalColorPicker)
    var strongColor: Color {
        switch self {
        case .hellblau: return Color(red: 0.2, green: 0.5, blue: 0.9)
        case .orange: return Color(red: 0.95, green: 0.55, blue: 0.2)
        case .grau: return Color(red: 0.4, green: 0.4, blue: 0.4)
        }
    }

    /// Glasfarbe des Schemas fuer die Glasblumen (RGB 0...1)
    var glassRGB: (red: Double, green: Double, blue: Double) {
        switch self {
        case .hellblau: return (0.34, 0.62, 0.94)
        case .orange: return (0.96, 0.58, 0.22)
        case .grau: return (0.56, 0.58, 0.62)
        }
    }

    var glassColor: Color {
        let rgb = glassRGB
        return Color(red: rgb.red, green: rgb.green, blue: rgb.blue)
    }
}

// MARK: - Array Extension fuer sicheren Zugriff

extension Array {
    subscript(safe index: Index) -> Element? {
        return indices.contains(index) ? self[index] : nil
    }
}
