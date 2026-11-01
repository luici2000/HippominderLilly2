//
//  WatchFlower.swift
//  Hippominder Watch App
//
//  Autor: Mathias Hubrich & Claude (Anthropic)
//  Erstellt: 1. November 2026
//
//  Beschreibung: Mathias' Blume fuer die Uhr. Rechnet mit FlowerGeometry
//  aus Models, also mit denselben Werten wie iPhone und Mac - und folgt
//  dem Geraet: Fuellung ab 1 Uhr im Uhrzeigersinn, Mitte leer bis zum
//  Ablauf, dann der fette Punkt.
//

import SwiftUI

struct WatchFlower: View {
    let filledPetals: Int
    let isExpired: Bool
    let color: Color
    var size: CGFloat = 34

    // Die schmaleren Geraete-Proportionen - auf kleinen Flaechen lesbarer
    private var petalWidth: CGFloat { max(1.8, size * LCDGeometry.petalWidth) }
    private var petalLength: CGFloat { size * LCDGeometry.petalLength }
    private var radialDistance: CGFloat { size * LCDGeometry.radialDistance }
    private var dotDiameter: CGFloat { size * LCDGeometry.dotDiameter }

    var body: some View {
        ZStack {
            ForEach(0..<FlowerGeometry.petalCount, id: \.self) { index in
                Capsule()
                    .fill(index < filledPetals ? color : Color.gray.opacity(0.3))
                    .frame(width: petalWidth, height: petalLength)
                    .offset(y: -radialDistance)
                    .rotationEffect(.degrees(FlowerGeometry.angle(for: index)))
            }

            if isExpired {
                Circle()
                    .fill(color)
                    .frame(width: dotDiameter, height: dotDiameter)
            }
        }
        .frame(width: size, height: size)
    }
}

#if DEBUG
#Preview("Blume auf der Uhr") {
    HStack(spacing: 8) {
        WatchFlower(filledPetals: 2, isExpired: false, color: .green)
        WatchFlower(filledPetals: 7, isExpired: false, color: .orange)
        WatchFlower(filledPetals: 12, isExpired: true, color: .red)
    }
    .padding()
}
#endif
