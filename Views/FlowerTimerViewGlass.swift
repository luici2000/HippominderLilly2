//
//  FlowerTimerViewGlass.swift
//  Hippominder
//
//  Autor: Mathias Hubrich & Claude (Anthropic)
//  Erstellt: 30. Oktober 2026
//  Version: 1.0.0
//
//  Beschreibung: Liquid Glass Edition der Blumen-Timer
//  Apple iOS 26 Liquid Glass Design mit -45 Grad Lichteinfall
//  Drop-in Ersatz fuer FlowerTimerView (Original bleibt erhalten)
//
//  Wechsel: In HorseDetailView "FlowerTimerView" durch
//  "GlassFlowerTimerView" ersetzen - fertig.
//

import SwiftUI

// MARK: - Liquid Glass Flower Timer

struct GlassFlowerTimerView: View {
    let eventType: Horse.EventType
    let remainingDays: Int
    let interval: Int
    let nextDate: Date
    var colorScheme: FlowerColorScheme = .hellblau

    private static let dateFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "dd.MM.yyyy"
        return f
    }()

    var filledPetals: Int {
        if remainingDays <= 0 { return 12 }
        let progress = Double(remainingDays) / Double(interval)
        return 12 - Int(progress * 12)
    }

    var isExpired: Bool { remainingDays <= 0 }

    var formattedDays: String {
        if remainingDays == 1 || remainingDays == -1 {
            return "\(remainingDays) " + String(localized: "Tag")
        }
        return "\(remainingDays) " + String(localized: "Tage")
    }

    var formattedDate: String {
        Self.dateFormatter.string(from: nextDate)
    }

    func flowerImageName(stempelDark: Bool) -> String {
        let base: String
        if filledPetals >= 12 {
            base = stempelDark ? "12d" : "12h"
        } else {
            base = "\(filledPetals)"
        }
        switch colorScheme {
        case .grau: return "flower_\(base)"
        case .hellblau: return "flower_\(base)_hellblau"
        case .orange: return "flower_\(base)_orange"
        }
    }

    @State private var stempelBlink = false

    private var glassAccent: Color { colorScheme.strongColor }

    var body: some View {
        VStack(spacing: 6) {
            // Blume mit Glass-Dome-Effekt
            ZStack {
                // Sanfter Farbschein hinter der Blume
                Circle()
                    .fill(glassAccent.opacity(0.08))
                    .frame(width: 120, height: 120)
                    .blur(radius: 14)

                // Blumen-Bild (identisch zum Original)
                if isExpired {
                    ZStack {
                        Image(flowerImageName(stempelDark: true))
                            .resizable()
                            .scaledToFit()
                            .frame(width: 110, height: 110)
                            .opacity(stempelBlink ? 1.0 : 0.0)

                        Image(flowerImageName(stempelDark: false))
                            .resizable()
                            .scaledToFit()
                            .frame(width: 110, height: 110)
                            .opacity(stempelBlink ? 0.0 : 1.0)
                    }
                    .onAppear {
                        withAnimation(.easeInOut(duration: 1.0).repeatForever(autoreverses: true)) {
                            stempelBlink = true
                        }
                    }
                } else {
                    Image(flowerImageName(stempelDark: true))
                        .resizable()
                        .scaledToFit()
                        .frame(width: 110, height: 110)
                }

                // Glass-Dome ueber der Blume
                GlassDomeOverlay()
                    .frame(width: 114, height: 114)
                    .allowsHitTesting(false)
            }

            // Symbol in Glaskugel
            GlassSymbolSphere(eventType: eventType, accent: glassAccent)
                .padding(.top, 2)

            // Tage in Glass-Badge
            Text(formattedDays)
                .font(.caption)
                .bold()
                .foregroundColor(isExpired ? .red : .primary)
                .padding(.horizontal, 10)
                .padding(.vertical, 3)
                .background(GlassBadgeBackground(isExpired: isExpired))

            // Titel
            Text(eventType.localizedName)
                .font(.caption2)
                .foregroundColor(.secondary)

            // Datum
            Text(formattedDate)
                .font(.caption2)
                .foregroundColor(.gray)
                .frame(maxWidth: .infinity, alignment: .center)

            // LED oder Platzhalter
            if isExpired {
                GlassLEDIndicator()
            } else {
                Circle()
                    .fill(Color.clear)
                    .frame(width: 14, height: 14)
            }
        }
        .frame(width: 130)
        .padding(.vertical, 10)
        .padding(.horizontal, 4)
        .background(GlassCardBackground(accent: glassAccent))
    }
}

// MARK: - Glass Dome Overlay (schwebt ueber der Blume)

struct GlassDomeOverlay: View {
    var body: some View {
        ZStack {
            // Glasrand-Ring mit -45 Grad Lichteinfall
            Circle()
                .stroke(
                    AngularGradient(
                        colors: [
                            .white.opacity(0.5),
                            .white.opacity(0.15),
                            .clear,
                            .clear,
                            .white.opacity(0.05),
                            .white.opacity(0.3),
                            .white.opacity(0.5)
                        ],
                        center: .center,
                        startAngle: .degrees(-135),
                        endAngle: .degrees(225)
                    ),
                    lineWidth: 1.5
                )

            // Spekularer Glanzpunkt oben links (-45 Grad)
            Ellipse()
                .fill(
                    RadialGradient(
                        colors: [.white.opacity(0.4), .clear],
                        center: .center,
                        startRadius: 0,
                        endRadius: 22
                    )
                )
                .frame(width: 34, height: 14)
                .rotationEffect(.degrees(-45))
                .offset(x: -22, y: -24)

            // Prismatischer Rand-Effekt (subtiler Regenbogen wie bei echtem Glas)
            Circle()
                .stroke(
                    AngularGradient(
                        colors: [
                            Color(red: 0.7, green: 0.85, blue: 1.0).opacity(0.15),
                            Color(red: 0.85, green: 0.7, blue: 1.0).opacity(0.1),
                            .clear,
                            .clear,
                            .clear,
                            Color(red: 1.0, green: 0.85, blue: 0.7).opacity(0.08),
                            Color(red: 0.7, green: 0.85, blue: 1.0).opacity(0.15)
                        ],
                        center: .center,
                        startAngle: .degrees(-135),
                        endAngle: .degrees(225)
                    ),
                    lineWidth: 3
                )
                .padding(2)
                .opacity(0.6)

            // Innere Refraktions-Linie
            Circle()
                .stroke(
                    RadialGradient(
                        colors: [.clear, .white.opacity(0.06)],
                        center: UnitPoint(x: 0.3, y: 0.3),
                        startRadius: 30,
                        endRadius: 55
                    ),
                    lineWidth: 1.5
                )
                .padding(5)
        }
    }
}

// MARK: - Glass Card Background (Karte hinter jedem Timer)

struct GlassCardBackground: View {
    let accent: Color
    @Environment(\.colorScheme) var isDark

    private var isLight: Bool { isDark == .light }

    var body: some View {
        ZStack {
            // Basis: echtes Apple Material
            RoundedRectangle(cornerRadius: 20)
                .fill(.ultraThinMaterial)

            // Zarter Farbakzent vom Farbschema
            RoundedRectangle(cornerRadius: 20)
                .fill(accent.opacity(0.04))

            // Glastiefe: hell oben links, dunkel unten rechts (-45 Grad Licht)
            RoundedRectangle(cornerRadius: 20)
                .fill(
                    LinearGradient(
                        colors: [
                            .white.opacity(isLight ? 0.18 : 0.04),
                            .clear,
                            .black.opacity(isLight ? 0.03 : 0.08)
                        ],
                        startPoint: UnitPoint(x: 0.15, y: 0.0),
                        endPoint: UnitPoint(x: 0.85, y: 1.0)
                    )
                )

            // Spekularer Rand (-45 Grad Lichteinfall, hell oben links)
            RoundedRectangle(cornerRadius: 20)
                .stroke(
                    AngularGradient(
                        colors: [
                            .white.opacity(0.65),
                            .white.opacity(0.35),
                            .white.opacity(0.12),
                            .clear,
                            .clear,
                            .clear,
                            .white.opacity(0.06),
                            .white.opacity(0.45),
                            .white.opacity(0.65)
                        ],
                        center: .center,
                        startAngle: .degrees(-135),
                        endAngle: .degrees(225)
                    ),
                    lineWidth: 1
                )

            // Innerer Glanz oben (Glass Highlight)
            RoundedRectangle(cornerRadius: 19)
                .stroke(
                    LinearGradient(
                        colors: [.white.opacity(0.25), .clear],
                        startPoint: UnitPoint(x: 0.1, y: 0.0),
                        endPoint: UnitPoint(x: 0.7, y: 0.4)
                    ),
                    lineWidth: 0.5
                )
                .padding(1)
        }
        // Zweistufiger Schatten fuer Tiefe
        .shadow(color: .black.opacity(0.1), radius: 8, x: 3, y: 5)
        .shadow(color: .black.opacity(0.05), radius: 2, x: 1, y: 1)
    }
}

// MARK: - Glass Symbol Sphere (Glaskugel mit Event-Icon)

struct GlassSymbolSphere: View {
    let eventType: Horse.EventType
    let accent: Color
    @Environment(\.colorScheme) var isDark

    private var isLight: Bool { isDark == .light }

    var body: some View {
        ZStack {
            // Basis-Glaskugel
            Circle()
                .fill(.ultraThinMaterial)
                .frame(width: 38, height: 38)

            // Akzentfarbe
            Circle()
                .fill(accent.opacity(0.12))
                .frame(width: 38, height: 38)

            // Kugeltiefe (-45 Grad Licht)
            Circle()
                .fill(
                    LinearGradient(
                        colors: [
                            .white.opacity(isLight ? 0.22 : 0.06),
                            .clear,
                            .black.opacity(0.12)
                        ],
                        startPoint: UnitPoint(x: 0.2, y: 0.1),
                        endPoint: UnitPoint(x: 0.85, y: 0.95)
                    )
                )
                .frame(width: 38, height: 38)

            // Scharfer Glanzpunkt (-45 Grad, oben links)
            Ellipse()
                .fill(
                    RadialGradient(
                        colors: [.white.opacity(0.9), .clear],
                        center: .center,
                        startRadius: 0,
                        endRadius: 9
                    )
                )
                .frame(width: 14, height: 7)
                .rotationEffect(.degrees(-45))
                .offset(x: -7, y: -8)

            // Glas-Randring
            Circle()
                .stroke(
                    AngularGradient(
                        colors: [
                            .white.opacity(0.7),
                            .white.opacity(0.25),
                            .clear,
                            .clear,
                            .white.opacity(0.08),
                            .white.opacity(0.5),
                            .white.opacity(0.7)
                        ],
                        center: .center,
                        startAngle: .degrees(-135),
                        endAngle: .degrees(225)
                    ),
                    lineWidth: 1
                )
                .frame(width: 38, height: 38)

            // Event-Symbol
            Image(eventType.symbol)
                .resizable()
                .scaledToFit()
                .frame(width: 20, height: 20)
                .opacity(0.8)
        }
        .shadow(color: .black.opacity(0.15), radius: 3, x: 1.5, y: 2)
    }
}

// MARK: - Glass Badge Background (Tage-Anzeige)

struct GlassBadgeBackground: View {
    let isExpired: Bool
    @Environment(\.colorScheme) var isDark

    private var isLight: Bool { isDark == .light }

    var body: some View {
        ZStack {
            Capsule()
                .fill(.ultraThinMaterial)

            if isExpired {
                Capsule()
                    .fill(Color.red.opacity(0.12))
            }

            // Glastiefe
            Capsule()
                .fill(
                    LinearGradient(
                        colors: [
                            .white.opacity(isLight ? 0.28 : 0.05),
                            .clear,
                            .black.opacity(0.04)
                        ],
                        startPoint: UnitPoint(x: 0.15, y: 0.0),
                        endPoint: UnitPoint(x: 0.85, y: 1.0)
                    )
                )

            // Glasrand
            Capsule()
                .stroke(
                    LinearGradient(
                        colors: [.white.opacity(0.55), .white.opacity(0.12)],
                        startPoint: UnitPoint(x: 0.1, y: 0.0),
                        endPoint: UnitPoint(x: 0.9, y: 1.0)
                    ),
                    lineWidth: 0.5
                )
        }
        .shadow(color: .black.opacity(0.08), radius: 2, x: 0.5, y: 1)
    }
}

// MARK: - Glass LED Indicator (blinkt bei ueberfaellig)

struct GlassLEDIndicator: View {
    @State private var isOn = true
    @Environment(\.colorScheme) var isDark

    private var isLight: Bool { isDark == .light }

    var body: some View {
        ZStack {
            // Glasgehaeuse
            Circle()
                .fill(.ultraThinMaterial)
                .frame(width: 20, height: 20)

            // Gehaeusetiefe
            Circle()
                .fill(
                    LinearGradient(
                        colors: [
                            .white.opacity(isLight ? 0.18 : 0.04),
                            .clear,
                            .black.opacity(0.08)
                        ],
                        startPoint: UnitPoint(x: 0.2, y: 0.1),
                        endPoint: UnitPoint(x: 0.85, y: 0.95)
                    )
                )
                .frame(width: 20, height: 20)

            // Glasrand
            Circle()
                .stroke(
                    AngularGradient(
                        colors: [
                            .white.opacity(0.5),
                            .white.opacity(0.15),
                            .clear,
                            .clear,
                            .white.opacity(0.05),
                            .white.opacity(0.35),
                            .white.opacity(0.5)
                        ],
                        center: .center,
                        startAngle: .degrees(-135),
                        endAngle: .degrees(225)
                    ),
                    lineWidth: 0.8
                )
                .frame(width: 20, height: 20)

            // LED-Leuchtpunkt
            Circle()
                .fill(
                    RadialGradient(
                        colors: [
                            Color.red.opacity(isOn ? 1.0 : 0.3),
                            Color.red.opacity(isOn ? 0.7 : 0.15)
                        ],
                        center: .center,
                        startRadius: 0,
                        endRadius: 5
                    )
                )
                .frame(width: 10, height: 10)

            // LED-Glow durch das Glas
            if isOn {
                Circle()
                    .fill(Color.red.opacity(0.25))
                    .frame(width: 16, height: 16)
                    .blur(radius: 4)
            }

            // Winziger Glanzpunkt auf der LED
            Ellipse()
                .fill(
                    RadialGradient(
                        colors: [.white.opacity(isOn ? 0.65 : 0.3), .clear],
                        center: .center,
                        startRadius: 0,
                        endRadius: 3
                    )
                )
                .frame(width: 5, height: 3)
                .offset(x: -1.5, y: -2)
        }
        .shadow(color: isOn ? .red.opacity(0.35) : .clear, radius: 6)
        .shadow(color: .black.opacity(0.1), radius: 1.5, x: 0.5, y: 1)
        .onAppear {
            withAnimation(.easeInOut(duration: 0.8).repeatForever(autoreverses: true)) {
                isOn = false
            }
        }
    }
}

// MARK: - Preview

#Preview("Liquid Glass Flower Timer") {
    ZStack {
        LinearGradient(
            colors: [Color.blue.opacity(0.08), Color.purple.opacity(0.04)],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        .ignoresSafeArea()

        HStack(spacing: 12) {
            GlassFlowerTimerView(
                eventType: .hufschmied,
                remainingDays: 151,
                interval: 180,
                nextDate: Date().addingTimeInterval(151 * 86400),
                colorScheme: .hellblau
            )

            GlassFlowerTimerView(
                eventType: .impfung,
                remainingDays: 46,
                interval: 49,
                nextDate: Date().addingTimeInterval(46 * 86400),
                colorScheme: .orange
            )

            GlassFlowerTimerView(
                eventType: .wurmkur,
                remainingDays: 0,
                interval: 101,
                nextDate: Date(),
                colorScheme: .grau
            )
        }
        .padding()
    }
}
