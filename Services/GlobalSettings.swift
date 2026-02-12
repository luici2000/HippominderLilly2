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

    private init() {
        flowerColorSchemeIndex = UserDefaults.standard.integer(forKey: "flowerColorSchemeIndex")
    }

    /// Aktuelles Farbschema
    var flowerColorScheme: FlowerColorScheme {
        get { FlowerColorScheme.allCases[safe: flowerColorSchemeIndex] ?? .hellblau }
        set { flowerColorSchemeIndex = FlowerColorScheme.allCases.firstIndex(of: newValue) ?? 0 }
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
