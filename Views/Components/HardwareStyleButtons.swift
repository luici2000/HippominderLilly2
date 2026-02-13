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
    @State private var showingInput = false
    @State private var inputText = ""

    private let buttonColor = Color(red: 0.35, green: 0.35, blue: 0.35)

    var body: some View {
        HStack(spacing: 6) {
            // Minus Button
            glassButton(symbol: "minus") {
                if value > 1 { value -= 1 }
            }

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
                        RoundedRectangle(cornerRadius: 6)
                            .fill(.ultraThinMaterial)
                            .overlay(
                                RoundedRectangle(cornerRadius: 6)
                                    .stroke(.white.opacity(0.3), lineWidth: 0.5)
                            )
                    )
            }
            .buttonStyle(.plain)

            // Plus Button
            glassButton(symbol: "plus") {
                value += 1
            }
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

    /// Reusable glass-style circle button (deduplicated minus/plus)
    @ViewBuilder
    private func glassButton(symbol: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            ZStack {
                RoundedRectangle(cornerRadius: 8)
                    .fill(.ultraThinMaterial)
                    .frame(width: 44, height: 44)
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(
                                LinearGradient(
                                    colors: [.white.opacity(0.5), .white.opacity(0.2)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: 1
                            )
                    )
                    .shadow(color: .black.opacity(0.1), radius: 2, x: 0, y: 1)

                Circle()
                    .fill(buttonColor)
                    .frame(width: 28, height: 28)
                    .overlay(
                        Circle()
                            .fill(
                                LinearGradient(
                                    colors: [.white.opacity(0.2), .clear],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                    )
                    .overlay(
                        Image(systemName: symbol)
                            .font(.system(size: 14, weight: .bold))
                            .foregroundColor(.white)
                    )
                    .shadow(color: .black.opacity(0.2), radius: 2, x: 0, y: 1)
            }
        }
        .buttonStyle(.plain)
    }
}
