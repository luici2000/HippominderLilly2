//
//  FlowerTimerViewLCD.swift
//  Hippominder
//
//  Autor: Mathias Hubrich & Claude (Anthropic)
//  Erstellt: 31. Oktober 2026
//  Version: 1.0.0
//
//  Beschreibung: Classic-Modus - das LCD des Original-Geraets von 2006.
//
//  Gebaut nach docs/original_geraet/:
//  - fet430_1.c (Avisaro AG fuer Roboterwerk Hubrich, Rev 1.1):
//    Segment 1-12 sind die Rosenblaetter, "Rosen fangen bei 1 Uhr an".
//    Segment 13 setzt den Mittelpunkt, 14 loescht ihn. Beim Clear bleibt
//    der Kranz stehen (LCD[0] = 0x01), ist also immer sichtbar.
//    Bei Alarm blinkt nur die Glocke, nicht die Symbole.
//  - Detail_Display.jpg: Logo oben rechts, Symbole unter den Rosen,
//    Mittelpunkt erscheint nach Ablauf.
//
//  Geometrie geteilt mit der Glas-Variante (FlowerGeometry).
//

import SwiftUI

// MARK: - LCD-Palette

/// Graugruenes Segment-LCD, Farben aus dem Flyerfoto des Geraets gemessen.
enum LCDPalette {
    /// Displayflaeche
    static let base = Color(red: 0.70, green: 0.77, blue: 0.69)
    /// Leichter Verlauf zum Rand, damit die Flaeche nicht flach wirkt
    static let baseEdge = Color(red: 0.63, green: 0.71, blue: 0.63)
    /// Eingeschaltetes Segment
    static let on = Color(red: 0.14, green: 0.17, blue: 0.15)
    /// Ausgeschaltetes Segment - bei echten LCDs schwach sichtbar
    static let ghost = Color(red: 0.62, green: 0.69, blue: 0.61)
    /// Gehaeuse um das Display
    static let bezel = Color(red: 0.34, green: 0.36, blue: 0.34)
}

// MARK: - Eine Rose im LCD

struct LCDRose: View {
    let filledPetals: Int
    let isExpired: Bool
    var size: CGFloat = 86

    private var petalWidth: CGFloat { size * FlowerGeometry.petalWidth }
    private var petalLength: CGFloat { size * FlowerGeometry.petalLength }
    private var radialDistance: CGFloat { size * FlowerGeometry.radialDistance }
    private var kranzDiameter: CGFloat { size * FlowerGeometry.stampDiameter }

    var body: some View {
        ZStack {
            // Segmente 1-12
            ForEach(0..<FlowerGeometry.petalCount, id: \.self) { index in
                Capsule()
                    .fill(index < filledPetals ? LCDPalette.on : LCDPalette.ghost)
                    .frame(width: petalWidth, height: petalLength)
                    .offset(y: -radialDistance)
                    .rotationEffect(.degrees(FlowerGeometry.angle(for: index)))
            }

            // Kranz - steht auch beim Clear, also immer sichtbar
            Circle()
                .strokeBorder(LCDPalette.on, lineWidth: max(1, size * 0.022))
                .frame(width: kranzDiameter, height: kranzDiameter)

            // Mittelpunkt - Segment 13, erscheint erst nach Ablauf
            if isExpired {
                Circle()
                    .fill(LCDPalette.on)
                    .frame(width: kranzDiameter * 0.56, height: kranzDiameter * 0.56)
            }
        }
        .frame(width: size, height: size)
    }
}

// MARK: - Rose mit Symbol und Restzeit

struct LCDFlowerTimerView: View {
    let eventType: Horse.EventType
    let remainingDays: Int
    let interval: Int
    let nextDate: Date
    var roseSize: CGFloat = 86

    private static let dateFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "dd.MM.yyyy"
        return f
    }()

    var filledPetals: Int {
        if remainingDays <= 0 { return FlowerGeometry.petalCount }
        let remainingShare = Double(remainingDays) / Double(interval)
        let filled = FlowerGeometry.petalCount - Int(remainingShare * Double(FlowerGeometry.petalCount))
        return min(FlowerGeometry.petalCount, max(0, filled))
    }

    var isExpired: Bool { remainingDays <= 0 }

    /// Abgelaufen zeigt das Geraet Alarm, keine Negativzahl.
    var formattedDays: String {
        if isExpired { return String(localized: "fällig") }
        if remainingDays == 1 { return "1 " + String(localized: "Tag") }
        return "\(remainingDays) " + String(localized: "Tage")
    }

    var body: some View {
        VStack(spacing: 3) {
            LCDRose(
                filledPetals: filledPetals,
                isExpired: isExpired,
                size: roseSize
            )

            // Symbol unter der Rose - blinkt bewusst nicht, wie im Original
            Image(eventType.symbol)
                .resizable()
                .renderingMode(.template)
                .scaledToFit()
                .frame(width: roseSize * 0.2, height: roseSize * 0.2)
                .foregroundStyle(LCDPalette.on)

            Text(formattedDays)
                .font(.system(size: roseSize * 0.12, weight: .semibold, design: .rounded))
                .monospacedDigit()
                .foregroundStyle(LCDPalette.on)
                .lineLimit(1)

            Text(Self.dateFormatter.string(from: nextDate))
                .font(.system(size: roseSize * 0.1, design: .rounded))
                .monospacedDigit()
                .foregroundStyle(LCDPalette.on.opacity(0.65))
                .lineLimit(1)
        }
    }
}

// MARK: - Das Display

/// Haelt die drei Rosen auf der LCD-Flaeche, mit Logo und Alarmglocke.
struct LCDPanel<Content: View>: View {
    /// Blinkt, wenn mindestens ein Termin faellig ist
    let alarmActive: Bool
    @ViewBuilder var content: Content

    @State private var bellOn = true

    var body: some View {
        ZStack(alignment: .top) {
            // Displayflaeche
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [LCDPalette.base, LCDPalette.baseEdge],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )

            // Kopfzeile: Glocke links, Schriftzug rechts - wie auf dem Geraet
            HStack {
                Image(systemName: "bell.fill")
                    .font(.system(size: 11))
                    .foregroundStyle(LCDPalette.on)
                    .opacity(alarmActive ? (bellOn ? 1 : 0) : 0)

                Spacer()

                Text("HIPPOMINDER")
                    .font(.system(size: 7, weight: .bold, design: .rounded))
                    .tracking(0.8)
                    .foregroundStyle(LCDPalette.on.opacity(0.75))
            }
            .padding(.horizontal, 12)
            .padding(.top, 8)

            content
                .padding(.top, 20)
                .padding(.bottom, 12)
        }
        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
        // Gehaeuserahmen
        .overlay {
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .strokeBorder(LCDPalette.bezel, lineWidth: 2)
        }
        .padding(7)
        .background {
            RoundedRectangle(cornerRadius: 17, style: .continuous)
                .fill(Color(white: 0.97))
                .overlay {
                    RoundedRectangle(cornerRadius: 17, style: .continuous)
                        .strokeBorder(Color.black.opacity(0.1), lineWidth: 0.5)
                }
                .shadow(color: .black.opacity(0.18), radius: 6, x: 2, y: 4)
        }
        .onAppear {
            guard alarmActive else { return }
            withAnimation(.easeInOut(duration: 0.5).repeatForever(autoreverses: true)) {
                bellOn = false
            }
        }
    }
}

// MARK: - Preview

#if DEBUG
#Preview("Classic LCD") {
    // Werte aus Horse.preview
    LCDPanel(alarmActive: true) {
        HStack(alignment: .top, spacing: 10) {
            LCDFlowerTimerView(
                eventType: .hufschmied,
                remainingDays: 151,
                interval: 180,
                nextDate: Date().addingTimeInterval(151 * 86400)
            )
            LCDFlowerTimerView(
                eventType: .impfung,
                remainingDays: 46,
                interval: 49,
                nextDate: Date().addingTimeInterval(46 * 86400)
            )
            LCDFlowerTimerView(
                eventType: .wurmkur,
                remainingDays: 0,
                interval: 101,
                nextDate: Date()
            )
        }
    }
    .padding()
}
#endif
