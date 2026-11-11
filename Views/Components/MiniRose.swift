//
//  MiniRose.swift
//  Hippominder
//
//  Die kleine Blume der Pferdeliste samt Symbol darueber. Plattformfrei:
//  iPhone, iPad und Mac zeigen in der Liste dieselben drei Mini-Blumen
//  statt Ampelpunkten. Masse kommen aus Models/FlowerGeometry.swift.
//

import SwiftUI

// MARK: - Timer Indikator mit Icon

struct TimerIndicator: View {
    let eventType: Horse.EventType
    let days: Int
    let interval: Int

    private var indicatorColor: Color {
        if days <= 7 { return .red }
        if days <= 14 { return .orange }
        return .green
    }

    private var isExpired: Bool { days <= 0 }

    private var filledPetals: Int {
        FlowerGeometry.filledPetals(remainingDays: days, interval: interval)
    }

    var body: some View {
        VStack(spacing: 2) {
            Image(eventType.symbol)
                .resizable()
                .scaledToFit()
                .foregroundStyle(.primary)
                .frame(width: 11, height: 11)
                .opacity(0.7)

            MiniRose(
                filledPetals: filledPetals,
                isExpired: isExpired,
                color: indicatorColor
            )
        }
    }
}

// MARK: - Mini-Rose fuer die Liste

/// Dieselbe Blume wie in der Detailansicht, nur klein: zeigt auf einen Blick
/// wie weit das Intervall fortgeschritten ist, nicht nur ob es knapp wird.
struct MiniRose: View {
    let filledPetals: Int
    let isExpired: Bool
    let color: Color
    var size: CGFloat = 30

    private var petalWidth: CGFloat { max(1.8, size * LCDGeometry.petalWidth) }
    private var petalLength: CGFloat { size * LCDGeometry.petalLength }
    private var radialDistance: CGFloat { size * LCDGeometry.radialDistance }
    private var dotDiameter: CGFloat { size * LCDGeometry.dotDiameter }

    var body: some View {
        ZStack {
            ForEach(0..<FlowerGeometry.petalCount, id: \.self) { index in
                Capsule()
                    .fill(index < filledPetals ? color : Color.gray.opacity(0.25))
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
