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

    /// Freie Glasfarbe fuer die Glasblumen (RGB 0...1)
    @Published var glassTintRed: Double = 0.34 { didSet { persistTint() } }
    @Published var glassTintGreen: Double = 0.62 { didSet { persistTint() } }
    @Published var glassTintBlue: Double = 0.94 { didSet { persistTint() } }

    private init() {
        flowerColorSchemeIndex = UserDefaults.standard.integer(forKey: "flowerColorSchemeIndex")

        let d = UserDefaults.standard
        if d.object(forKey: "glassTintRed") != nil {
            glassTintRed = d.double(forKey: "glassTintRed")
            glassTintGreen = d.double(forKey: "glassTintGreen")
            glassTintBlue = d.double(forKey: "glassTintBlue")
        }
    }

    /// Aktuelles Farbschema
    var flowerColorScheme: FlowerColorScheme {
        get { FlowerColorScheme.allCases[safe: flowerColorSchemeIndex] ?? .hellblau }
        set { flowerColorSchemeIndex = FlowerColorScheme.allCases.firstIndex(of: newValue) ?? 0 }
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
}

// MARK: - Array Extension fuer sicheren Zugriff

extension Array {
    subscript(safe index: Index) -> Element? {
        return indices.contains(index) ? self[index] : nil
    }
}
