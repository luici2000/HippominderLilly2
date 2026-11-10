//
//  HardwareStyleButtons.swift
//  Hippominder
//
//  Plus/Minus-Tasten unter der Blumenbuehne, in zwei Fassungen:
//
//  Classic - Gehaeusetasten wie am Geraet: fast weisse, erhabene Taster
//  mit Schattenkante, dazwischen ein kleines olivgraues Display mit
//  dunkler Ziffer (Farben aus Detail_Display.jpg gemessen, LCDPalette).
//
//  Glas - dieselbe Form aus getoentem Milchglas in der gewaehlten
//  Glasfarbe (GlobalSettings.glassTint); das Pferdefoto dahinter wird
//  gebrochen sichtbar, wie bei den Bluetenblaettern. Blume nutzt Glas.
//
//  Licht kommt wie ueberall von oben links (-45 Grad): Kante oben links
//  hell, unten rechts dunkel, Schatten nach unten rechts.
//

import SwiftUI

struct HardwareStyleButtons: View {
    @Binding var value: Int
    var identifier: String? = nil
    @State private var showingInput = false
    @State private var inputText = ""

    @ObservedObject private var globalSettings = GlobalSettings.shared

    /// Am Foto des Geraets gemessen: Tastenflaeche #E6ECEE,
    /// Symbolkreis #1E3436 - fast weisser Taster, sehr dunkler Kreis
    private static let tasteHell = Color(red: 0.90, green: 0.925, blue: 0.933)
    private static let tasteKante = Color(red: 0.66, green: 0.70, blue: 0.72)
    private static let symbolKreis = Color(red: 0.118, green: 0.203, blue: 0.212)

    private let tastenGroesse: CGFloat = 44
    private let feldBreite: CGFloat = 54

    private var istClassic: Bool { globalSettings.designMode == .classic }
    private var tint: Color { globalSettings.glassTint }

    var body: some View {
        HStack(spacing: 6) {
            taste(symbol: "minus") {
                if value > 1 { value -= 1 }
            }
            .accessibilityIdentifier(identifier.map { "\($0)_minus" } ?? "")

            Button(action: {
                inputText = "\(value)"
                showingInput = true
            }) {
                Text("\(value)")
                    .font(.system(size: 18, weight: istClassic ? .semibold : .medium))
                    .monospacedDigit()
                    .foregroundStyle(istClassic ? LCDPalette.on : Color.primary)
                    .frame(width: feldBreite, height: tastenGroesse)
                    .background {
                        if istClassic { lcdFeld } else { glasFeld }
                    }
            }
            .buttonStyle(.plain)
            .accessibilityIdentifier(identifier.map { "\($0)_value" } ?? "")

            taste(symbol: "plus") {
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

    // MARK: - Taster

    @ViewBuilder
    private func taste(symbol: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            ZStack {
                if istClassic { tastenKoerper } else { glasKoerper }

                Circle()
                    .fill(istClassic ? Self.symbolKreis : Color.white.opacity(0.88))
                    .frame(width: 26, height: 26)
                    .overlay {
                        Circle().fill(
                            LinearGradient(
                                colors: [.white.opacity(istClassic ? 0.22 : 0.5), .clear],
                                startPoint: .topLeading,
                                endPoint: .bottom
                            )
                        )
                    }
                    .overlay {
                        Image(systemName: symbol)
                            .font(.system(size: 13, weight: .bold))
                            .foregroundStyle(istClassic ? Color.white : tint)
                    }
                    .shadow(color: .black.opacity(0.25), radius: 1.5, x: 1, y: 1)
            }
        }
        .buttonStyle(.plain)
    }

    /// Classic: erhabene Gehaeusetaste. Verlauf von oben links nach unten
    /// rechts, Kante oben links weiss und unten rechts dunkel, kraeftiger
    /// Schatten nach unten rechts - so hebt sie sich vom Gehaeuse ab.
    private var tastenKoerper: some View {
        RoundedRectangle(cornerRadius: 9, style: .continuous)
            .fill(
                LinearGradient(
                    colors: [.white, Self.tasteHell],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .frame(width: tastenGroesse, height: tastenGroesse)
            .overlay {
                RoundedRectangle(cornerRadius: 9, style: .continuous)
                    .strokeBorder(
                        LinearGradient(
                            colors: [.white, Self.tasteKante],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 1.2
                    )
            }
            .shadow(color: .black.opacity(0.30), radius: 2.5, x: 1.5, y: 2.5)
            .shadow(color: .black.opacity(0.10), radius: 0.5, x: 0, y: 0.5)
    }

    /// Classic: kleines olivgraues Display fuer die Ziffer, leicht ins
    /// Gehaeuse eingelassen (innerer Schatten oben links).
    private var lcdFeld: some View {
        RoundedRectangle(cornerRadius: 6, style: .continuous)
            .fill(
                LinearGradient(
                    colors: [LCDPalette.base, LCDPalette.baseEdge],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .overlay {
                RoundedRectangle(cornerRadius: 6, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: [.black.opacity(0.22), .clear],
                            startPoint: .topLeading,
                            endPoint: UnitPoint(x: 0.5, y: 0.7)
                        )
                    )
            }
            .overlay {
                RoundedRectangle(cornerRadius: 6, style: .continuous)
                    .strokeBorder(LCDPalette.bezel.opacity(0.7), lineWidth: 1)
            }
    }

    /// Glas: Milchglas in der Glasfarbe, wie die Bluetenblaetter.
    private var glasKoerper: some View {
        RoundedRectangle(cornerRadius: 11, style: .continuous)
            .fill(.ultraThinMaterial)
            .frame(width: tastenGroesse, height: tastenGroesse)
            .overlay {
                RoundedRectangle(cornerRadius: 11, style: .continuous)
                    .fill(tint.opacity(0.62))
            }
            .overlay {
                RoundedRectangle(cornerRadius: 11, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: [.white.opacity(0.55), .clear, .black.opacity(0.10)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
            }
            .overlay {
                RoundedRectangle(cornerRadius: 11, style: .continuous)
                    .strokeBorder(
                        LinearGradient(
                            colors: [.white.opacity(0.85), .white.opacity(0.2)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 1
                    )
            }
            .shadow(color: tint.opacity(0.35), radius: 4, x: 1, y: 2)
    }

    /// Glas: das Zahlenfeld, schwaecher getoent als die Taster.
    private var glasFeld: some View {
        RoundedRectangle(cornerRadius: 6, style: .continuous)
            .fill(.ultraThinMaterial)
            .overlay {
                RoundedRectangle(cornerRadius: 6, style: .continuous)
                    .fill(tint.opacity(0.22))
            }
            .overlay {
                RoundedRectangle(cornerRadius: 6, style: .continuous)
                    .strokeBorder(.white.opacity(0.5), lineWidth: 0.8)
            }
    }
}
