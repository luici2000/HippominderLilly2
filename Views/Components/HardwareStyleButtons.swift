//
//  HardwareStyleButtons.swift
//  Hippominder
//
//  Autor: Mathias Hubrich & Claude (Anthropic)
//  Erstellt: 12. Februar 2026
//  Version: 1.0.0
//
//  Beschreibung: Hardware-Stil +/- Stepper Buttons mit Glass Design
//

import SwiftUI

struct HardwareStyleButtons: View {
    @Binding var value: Int
    /// Optionaler Praefix fuer Accessibility-Identifier (UI-Tests): "<id>_minus", "<id>_value", "<id>_plus"
    var identifier: String? = nil
    @State private var showingInput = false
    @State private var inputText = ""

    @ObservedObject private var globalSettings = GlobalSettings.shared

    /// Am Foto des Geraets gemessen: Tastenflaeche #E6ECEE,
    /// Symbolkreis #1E3436 - fast weisser Taster, sehr dunkler Kreis
    private static let tasteHell = Color(red: 0.90, green: 0.925, blue: 0.933)
    private static let tasteKante = Color(red: 0.78, green: 0.81, blue: 0.82)
    private static let symbolKreis = Color(red: 0.118, green: 0.203, blue: 0.212)

    private var istClassic: Bool { globalSettings.designMode == .classic }

    var body: some View {
        HStack(spacing: 6) {
            // Minus Button
            glassButton(symbol: "minus") {
                if value > 1 { value -= 1 }
            }
            .accessibilityIdentifier(identifier.map { "\($0)_minus" } ?? "")

            // Tappable value display
            Button(action: {
                inputText = "\(value)"
                showingInput = true
            }) {
                Text("\(value)")
                    .font(.system(size: 18, weight: .medium))
                    .foregroundColor(.primary)
                    .frame(width: 54, height: 44)
                    .background(
                        // Classic: vertieftes Anzeigefenster wie auf dem
                        // Geraet, Glas: durchscheinend
                        RoundedRectangle(cornerRadius: 6)
                            .fill(istClassic
                                  ? AnyShapeStyle(Self.tasteHell.opacity(0.75))
                                  : AnyShapeStyle(.ultraThinMaterial))
                            .overlay(
                                RoundedRectangle(cornerRadius: 6)
                                    .stroke(.white.opacity(0.3), lineWidth: 0.5)
                            )
                    )
            }
            .buttonStyle(.plain)
            .accessibilityIdentifier(identifier.map { "\($0)_value" } ?? "")

            // Plus Button
            glassButton(symbol: "plus") {
                value += 1
            }
            .accessibilityIdentifier(identifier.map { "\($0)_plus" } ?? "")
        }
        .alert("Wert eingeben", isPresented: $showingInput) {
            TextField("Tage", text: $inputText)
                #if os(iOS)
                .keyboardType(.numberPad)
                #endif
            Button("OK") {
                if let newValue = Int(inputText), newValue > 0 {
                    value = newValue
                }
            }
            Button("Abbrechen", role: .cancel) { }
        }
    }

    /// Knopf im Stil der jeweiligen Darstellung
    @ViewBuilder
    private func glassButton(symbol: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            ZStack {
                if istClassic { tastenKoerper } else { glasKoerper }

                // Dunkler Kreis mit weissem Symbol - auf dem Geraet sitzt
                // in jeder Taste so einer
                Circle()
                    .fill(istClassic ? Self.symbolKreis : Color(white: 0.3))
                    .frame(width: 26, height: 26)
                    .overlay {
                        Circle().fill(
                            LinearGradient(
                                colors: [.white.opacity(0.22), .clear],
                                startPoint: .topLeading,
                                endPoint: .bottom
                            )
                        )
                    }
                    .overlay {
                        Image(systemName: symbol)
                            .font(.system(size: 13, weight: .bold))
                            .foregroundStyle(.white)
                    }
                    .shadow(color: .black.opacity(0.25), radius: 1.5, x: 0, y: 1)
            }
        }
        .buttonStyle(.plain)
    }

    /// Classic: Kunststofftaster wie auf dem Geraet - heller Koerper,
    /// Lichtkante oben, feine Fuge zum Gehaeuse
    private var tastenKoerper: some View {
        RoundedRectangle(cornerRadius: 9, style: .continuous)
            .fill(
                LinearGradient(
                    colors: [.white, Self.tasteHell],
                    startPoint: .top,
                    endPoint: .bottom
                )
            )
            .frame(width: 44, height: 44)
            .overlay {
                RoundedRectangle(cornerRadius: 9, style: .continuous)
                    .strokeBorder(Self.tasteKante, lineWidth: 0.8)
            }
            .shadow(color: .black.opacity(0.18), radius: 1.5, x: 0, y: 1.5)
    }

    /// Glas: durchscheinendes Material mit Glanzkante bei -45 Grad
    private var glasKoerper: some View {
        RoundedRectangle(cornerRadius: 11, style: .continuous)
            .fill(.ultraThinMaterial)
            .frame(width: 44, height: 44)
            .overlay {
                RoundedRectangle(cornerRadius: 11, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: [.white.opacity(0.3), .clear, .black.opacity(0.06)],
                            startPoint: UnitPoint(x: 0.15, y: 0),
                            endPoint: UnitPoint(x: 0.85, y: 1)
                        )
                    )
            }
            .overlay {
                RoundedRectangle(cornerRadius: 11, style: .continuous)
                    .strokeBorder(
                        LinearGradient(
                            colors: [.white.opacity(0.65), .white.opacity(0.15)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 1
                    )
            }
            .shadow(color: .black.opacity(0.12), radius: 3, x: 1, y: 2)
    }
}
