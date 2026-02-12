//
//  FlowerTimerView.swift
//  Hippominder
//
//  Autor: Mathias Hubrich & Claude (Anthropic)
//  Erstellt: 24. Januar 2026
//  Geaendert: 12. Februar 2026, 22:00 Uhr
//  Version: 8.0.0
//
//  Beschreibung: Blumen-Timer mit vorgerenderten Icon-Composer-Bildern
//  14 Zustände (0-12h/12d) als 1024x1024 PNGs mit transparentem Hintergrund
//  Farbgebung über colorMultiply() für die 3 Farbschemata
//

import SwiftUI

struct FlowerTimerView: View {
    let eventType: Horse.EventType
    let remainingDays: Int
    let interval: Int
    let nextDate: Date
    var colorScheme: FlowerColorScheme = .hellblau

    // Cached DateFormatter (expensive to create)
    private static let dateFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "dd.MM.yyyy"
        return f
    }()

    // Berechne gefuellte Bluetenblaetter basierend auf verbleibendem Fortschritt
    var filledPetals: Int {
        if remainingDays <= 0 { return 12 } // Ueberfaellig = voll
        let progress = Double(remainingDays) / Double(interval)
        return 12 - Int(progress * 12)
    }

    // Timer ist abgelaufen wenn 0 oder negative Tage uebrig
    var isExpired: Bool {
        remainingDays <= 0
    }

    // Formatierte Tage-Anzeige (localized)
    var formattedDays: String {
        if remainingDays == 1 || remainingDays == -1 {
            return "\(remainingDays) " + String(localized: "Tag")
        }
        return "\(remainingDays) " + String(localized: "Tage")
    }

    // Numerisches Datumsformat (DD.MM.YYYY)
    var formattedDate: String {
        Self.dateFormatter.string(from: nextDate)
    }

    // Bildname basierend auf Füllstand und Farbschema
    func flowerImageName(stempelDark: Bool) -> String {
        let base: String
        if filledPetals >= 12 {
            base = stempelDark ? "12d" : "12h"
        } else {
            base = "\(filledPetals)"
        }
        // Grau nutzt die Graustufen-Originale, Hellblau/Orange die eingefärbten
        switch colorScheme {
        case .grau:
            return "flower_\(base)"
        case .hellblau:
            return "flower_\(base)_hellblau"
        case .orange:
            return "flower_\(base)_orange"
        }
    }

    // Blink-State fuer ueberfaelligen Stempel
    @State private var stempelBlink = false

    var body: some View {
        VStack(spacing: 8) {
            // Vorgerendertes Blumen-Bild (direkt eingefärbt, kein Tinting nötig)
            // Bei Ueberfaelligkeit: Stempel blinkt zwischen hell und dunkel
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

            // Symbol mit 3D-Kreis-Hintergrund
            Symbol3DCircle(eventType: eventType)
                .padding(.top, 2)

            // Tage mit 3D-Badge
            Text(formattedDays)
                .font(.caption)
                .bold()
                .foregroundColor(isExpired ? .red : .primary)
                .padding(.horizontal, 8)
                .padding(.vertical, 2)
                .background(Badge3D())

            // Titel (localized)
            Text(eventType.localizedName)
                .font(.caption2)
                .foregroundColor(.secondary)

            // Naechster Termin
            Text(formattedDate)
                .font(.caption2)
                .foregroundColor(.gray)
                .frame(maxWidth: .infinity, alignment: .center)

            // Blinkende LED wenn abgelaufen
            if isExpired {
                LED3D()
            } else {
                Circle()
                    .fill(Color.clear)
                    .frame(width: 14, height: 14)
            }
        }
        .frame(width: 120)
        .padding(.vertical, 8)
    }
}

// MARK: - 3D Symbol-Kreis

struct Symbol3DCircle: View {
    let eventType: Horse.EventType

    var body: some View {
        ZStack {
            Circle()
                .fill(Color(white: 0.9))
                .frame(width: 36, height: 36)

            Circle()
                .fill(
                    LinearGradient(
                        colors: [.clear, .black.opacity(0.15)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: 36, height: 36)

            Circle()
                .fill(
                    RadialGradient(
                        colors: [.white.opacity(0.7), .clear],
                        center: UnitPoint(x: 0.3, y: 0.3),
                        startRadius: 0,
                        endRadius: 18
                    )
                )
                .frame(width: 36, height: 36)

            Circle()
                .stroke(
                    LinearGradient(
                        colors: [.white.opacity(0.8), .gray.opacity(0.3)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 1
                )
                .frame(width: 36, height: 36)

            Image(eventType.symbol)
                .resizable()
                .scaledToFit()
                .frame(width: 20, height: 20)
                .opacity(0.85)
        }
        .shadow(color: .black.opacity(0.15), radius: 2, x: 1, y: 1)
    }
}

// MARK: - 3D Badge

struct Badge3D: View {
    var body: some View {
        ZStack {
            Capsule()
                .fill(Color(white: 0.92))

            Capsule()
                .fill(
                    LinearGradient(
                        colors: [.clear, .black.opacity(0.08)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )

            Capsule()
                .fill(
                    LinearGradient(
                        colors: [.white.opacity(0.6), .clear],
                        startPoint: .top,
                        endPoint: .center
                    )
                )
                .padding(1)

            Capsule()
                .stroke(
                    LinearGradient(
                        colors: [.white.opacity(0.7), .gray.opacity(0.2)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 0.5
                )
        }
        .shadow(color: .black.opacity(0.1), radius: 1, x: 0.5, y: 0.5)
    }
}

// MARK: - 3D LED

struct LED3D: View {
    @State private var isOn = true

    var body: some View {
        ZStack {
            Circle()
                .fill(Color(white: 0.85))
                .frame(width: 18, height: 18)
                .overlay(
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [.clear, .black.opacity(0.15)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                )

            Circle()
                .fill(
                    RadialGradient(
                        colors: [.red, .red.opacity(0.8)],
                        center: .center,
                        startRadius: 0,
                        endRadius: 5
                    )
                )
                .frame(width: 10, height: 10)
                .opacity(isOn ? 1.0 : 0.4)
                .shadow(color: isOn ? .red.opacity(0.8) : .clear, radius: 6)
        }
        .shadow(color: .black.opacity(0.15), radius: 1, x: 0.5, y: 0.5)
        .onAppear {
            withAnimation(.easeInOut(duration: 0.8).repeatForever(autoreverses: true)) {
                isOn = false
            }
        }
    }
}

// MARK: - Preview

#Preview("Flower Timer") {
    HStack(spacing: 16) {
        FlowerTimerView(
            eventType: .hufschmied,
            remainingDays: 151,
            interval: 180,
            nextDate: Date().addingTimeInterval(151 * 86400),
            colorScheme: .hellblau
        )

        FlowerTimerView(
            eventType: .impfung,
            remainingDays: 46,
            interval: 49,
            nextDate: Date().addingTimeInterval(46 * 86400),
            colorScheme: .orange
        )

        FlowerTimerView(
            eventType: .wurmkur,
            remainingDays: 0,
            interval: 101,
            nextDate: Date(),
            colorScheme: .grau
        )
    }
    .padding()
}
