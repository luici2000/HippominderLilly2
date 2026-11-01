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

/// Farben aus Detail_Display.jpg gemessen: der Grund ist ein entsaettigtes
/// Olivgrau (#959585), kein frisches Gruen.
enum LCDPalette {
    /// Displayflaeche
    static let base = Color(red: 0.66, green: 0.69, blue: 0.62)
    /// Leichter Verlauf zum Rand, damit die Flaeche nicht flach wirkt
    static let baseEdge = Color(red: 0.58, green: 0.61, blue: 0.54)
    /// Eingeschaltetes Segment
    static let on = Color(red: 0.16, green: 0.17, blue: 0.15)
    /// Kontur eines ausgeschalteten Segments - auf dem Geraet immer sichtbar
    static let ghostLine = Color(red: 0.16, green: 0.17, blue: 0.15).opacity(0.45)
    /// Fuellung eines ausgeschalteten Segments: knapp heller als der Grund
    static let ghostFill = Color(red: 0.69, green: 0.72, blue: 0.65)
    /// Gehaeuse um das Display
    static let bezel = Color(red: 0.34, green: 0.36, blue: 0.34)
}


// MARK: - Eine Rose im LCD

struct LCDRose: View {
    let filledPetals: Int
    let isExpired: Bool
    var size: CGFloat = 86

    private var petalWidth: CGFloat { size * LCDGeometry.petalWidth }
    private var petalLength: CGFloat { size * LCDGeometry.petalLength }
    private var radialDistance: CGFloat { size * LCDGeometry.radialDistance }
    private var dotDiameter: CGFloat { size * LCDGeometry.dotDiameter }

    var body: some View {
        ZStack {
            // Segmente 1-12, Start bei 1 Uhr im Uhrzeigersinn
            ForEach(0..<FlowerGeometry.petalCount, id: \.self) { index in
                segment(isOn: index < filledPetals)
                    .frame(width: petalWidth, height: petalLength)
                    .offset(y: -radialDistance)
                    .rotationEffect(.degrees(FlowerGeometry.angle(for: index)))
            }

            // Segment 13 - erscheint erst nach Ablauf. Die Mitte ist sonst leer;
            // auf dem Geraet gibt es dort keinen Ring.
            if isExpired {
                Circle()
                    .fill(LCDPalette.on)
                    .frame(width: dotDiameter, height: dotDiameter)
            }
        }
        .frame(width: size, height: size)
    }

    /// Ein ausgeschaltetes Segment bleibt auf einem echten LCD als feine
    /// Kontur sichtbar - das macht den Unterschied zu einer flachen Grafik.
    @ViewBuilder
    private func segment(isOn: Bool) -> some View {
        if isOn {
            Capsule().fill(LCDPalette.on)
        } else {
            Capsule()
                .fill(LCDPalette.ghostFill)
                .overlay {
                    Capsule().strokeBorder(LCDPalette.ghostLine, lineWidth: 0.7)
                }
        }
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
        FlowerGeometry.filledPetals(remainingDays: remainingDays, interval: interval)
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

            // Symbol unter der Rose, leicht links - so sitzt es auf dem Geraet.
            // Blinkt bewusst nicht: laut Firmware blinkt bei Alarm nur die Glocke.
            Image(eventType.symbol)
                .resizable()
                .renderingMode(.template)
                .scaledToFit()
                .frame(width: roseSize * 0.26, height: roseSize * 0.26)
                .foregroundStyle(LCDPalette.on)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.leading, roseSize * 0.14)

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

                // Mathias' Original-Logo aus Assets.xcassets, nicht nachgebaut
                Image("hippominder_logo")
                    .resizable()
                    .renderingMode(.template)
                    .scaledToFit()
                    .frame(height: 16)
                    .foregroundStyle(LCDPalette.on.opacity(0.85))
            }
            .padding(.horizontal, 12)
            .padding(.top, 8)

            content
                .padding(.top, 24)
                .padding(.bottom, 12)
        }
        // Das Display liegt vertieft hinter einer Scheibe: der Rahmen wirft
        // oben links Schatten, unten rechts faellt Licht ein (-45 Grad).
        .overlay {
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .stroke(
                    LinearGradient(
                        colors: [.black.opacity(0.3), .clear, .white.opacity(0.22)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 2.5
                )
                .blur(radius: 1.5)
                .padding(1)
        }
        // Schwacher Glanz der Scheibe
        .overlay {
            LinearGradient(
                colors: [.white.opacity(0.14), .clear, .clear],
                startPoint: .topLeading,
                endPoint: UnitPoint(x: 0.75, y: 0.7)
            )
            .allowsHitTesting(false)
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
        .onAppear { syncBell() }
        // Ohne das bliebe die Glocke haengen, wenn ein Termin erledigt oder
        // faellig wird waehrend die Ansicht offen ist
        .onChange(of: alarmActive) { _, _ in syncBell() }
    }

    private func syncBell() {
        guard alarmActive else {
            // Daueranimation anhalten: Wert ohne Animation zuruecksetzen
            withTransaction(Transaction(animation: nil)) { bellOn = true }
            return
        }
        withTransaction(Transaction(animation: nil)) { bellOn = true }
        withAnimation(.easeInOut(duration: 0.5).repeatForever(autoreverses: true)) {
            bellOn = false
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
