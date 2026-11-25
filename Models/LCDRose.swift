//
//  LCDRose.swift
//  Hippominder
//
//  Die Rose des Classic-Modus: das Segment-LCD des Original-Geraets von 2006.
//  Liegt in Models, weil das Watch-Target nur WatchApp und Models
//  mitnimmt - so zeichnen iPhone, Mac und Uhr dieselbe Rose. Herkunft der
//  Masse und Farben: FlowerTimerViewLCD.swift und docs/original_geraet/.
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
