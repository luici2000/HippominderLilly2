//
//  WatchGlassFlower.swift
//  Hippominder Watch App
//
//  Die Glasblume vom iPhone (FlowerTimerViewGlass) fuer die Uhr: getoentes
//  Milchglas, Glanz gegenrotiert, damit das Licht fuer alle Blaetter aus
//  -45 Grad (oben links) kommt. Masse aus FlowerGeometry, nichts kopiert.
//  Die Glasfarbe kommt vom iPhone mit dem Datensatz (WatchSyncReceiver).
//

import SwiftUI

enum WatchGlas {
    static let tintKey = "glassTint"
    static let designModeKey = "designMode"

    /// Glasfarbe des iPhones; bis zum ersten Abgleich das Hellblau
    static var tint: Color {
        if let a = UserDefaults.standard.array(forKey: tintKey) as? [Double], a.count == 3 {
            return Color(red: a[0], green: a[1], blue: a[2])
        }
        return Color(red: 0.34, green: 0.62, blue: 0.94)
    }
}

struct WatchGlassPetal: View {
    let angle: Double
    let isFilled: Bool
    let tint: Color

    var body: some View {
        if isFilled {
            Capsule()
                .fill(.ultraThinMaterial)
                .overlay { Capsule().fill(tint.opacity(0.85)) }
                .overlay { specular(strength: 0.6) }
                .overlay {
                    Capsule().strokeBorder(
                        LinearGradient(
                            colors: [.white.opacity(0.6), .white.opacity(0.2)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 1
                    )
                }
                .shadow(color: .black.opacity(0.5), radius: 2, x: 0, y: 1)
        } else {
            Capsule()
                .fill(.white.opacity(0.06))
                .overlay { specular(strength: 0.3) }
                .overlay {
                    Capsule().strokeBorder(
                        LinearGradient(
                            colors: [.white.opacity(0.55), .white.opacity(0.2)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 1
                    )
                }
        }
    }

    private func specular(strength: Double) -> some View {
        LinearGradient(
            colors: [.white.opacity(strength), .white.opacity(strength * 0.18), .clear],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        .rotationEffect(.degrees(-angle))
        .scaleEffect(2.6)
        .clipShape(Capsule())
    }
}

struct WatchGlassStamp: View {
    let tint: Color
    let symbol: String
    let size: CGFloat

    var body: some View {
        ZStack {
            Circle().fill(.ultraThinMaterial)
            Circle().fill(tint.opacity(0.58))
            Circle().fill(
                LinearGradient(
                    colors: [.white.opacity(0.3), .clear, .black.opacity(0.22)],
                    startPoint: UnitPoint(x: 0.2, y: 0.1),
                    endPoint: UnitPoint(x: 0.88, y: 0.95)
                )
            )
            Ellipse()
                .fill(
                    RadialGradient(
                        colors: [.white.opacity(0.9), .clear],
                        center: .center, startRadius: 0, endRadius: size * 0.28
                    )
                )
                .frame(width: size * 0.44, height: size * 0.24)
                .rotationEffect(.degrees(-45))
                .offset(x: -size * 0.17, y: -size * 0.19)
            Circle().strokeBorder(
                LinearGradient(
                    colors: [.white.opacity(0.68), .white.opacity(0.18)],
                    startPoint: .topLeading, endPoint: .bottomTrailing
                ),
                lineWidth: 1
            )
            // Template-Asset: ohne ausdrueckliche Farbe erschiene es in Akzentfarbe
            Image(symbol)
                .resizable()
                .scaledToFit()
                .foregroundStyle(.black)
                .frame(width: size * 0.5, height: size * 0.5)
                .shadow(color: .black.opacity(0.45), radius: 1.5, x: 0, y: 1)
        }
        .frame(width: size, height: size)
        .shadow(color: .black.opacity(0.3), radius: 3, x: 1, y: 2)
    }
}

struct WatchGlassFlower: View {
    let filledPetals: Int
    let isExpired: Bool
    let symbol: String
    var tint: Color = WatchGlas.tint
    var size: CGFloat = 100

    private var petalWidth: CGFloat { size * FlowerGeometry.petalWidth }
    private var petalLength: CGFloat { size * FlowerGeometry.petalLength }
    private var radialDistance: CGFloat { size * FlowerGeometry.radialDistance }
    private var stampSize: CGFloat { size * FlowerGeometry.stampDiameter }

    var body: some View {
        ZStack {
            ForEach(0..<FlowerGeometry.petalCount, id: \.self) { index in
                let angle = FlowerGeometry.angle(for: index)
                WatchGlassPetal(angle: angle, isFilled: index < filledPetals, tint: isExpired ? .red : tint)
                    .frame(width: petalWidth, height: petalLength)
                    .offset(y: -radialDistance)
                    .rotationEffect(.degrees(angle))
            }
            WatchGlassStamp(tint: isExpired ? .red : tint, symbol: symbol, size: stampSize)
        }
        .frame(width: size, height: size)
    }
}

/// Glastaste wie auf dem iPhone, fuer Minus und Plus
struct WatchGlassKey: View {
    let symbol: String
    var tint: Color = WatchGlas.tint
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            ZStack {
                RoundedRectangle(cornerRadius: 9, style: .continuous)
                    .fill(.ultraThinMaterial)
                    .overlay { RoundedRectangle(cornerRadius: 9, style: .continuous).fill(tint.opacity(0.62)) }
                    .overlay {
                        RoundedRectangle(cornerRadius: 9, style: .continuous).fill(
                            LinearGradient(
                                colors: [.white.opacity(0.55), .clear, .black.opacity(0.1)],
                                startPoint: .topLeading, endPoint: .bottomTrailing
                            )
                        )
                    }
                    .overlay {
                        RoundedRectangle(cornerRadius: 9, style: .continuous).strokeBorder(
                            LinearGradient(colors: [.white.opacity(0.85), .white.opacity(0.2)],
                                           startPoint: .topLeading, endPoint: .bottomTrailing),
                            lineWidth: 1
                        )
                    }
                Circle()
                    .fill(.white.opacity(0.88))
                    .frame(width: 20, height: 20)
                    .overlay {
                        Image(systemName: symbol)
                            .font(.system(size: 11, weight: .bold))
                            .foregroundStyle(tint)
                    }
                    .shadow(color: .black.opacity(0.25), radius: 1.5, x: 1, y: 1)
            }
            .frame(width: 36, height: 34)
        }
        .buttonStyle(.plain)
    }
}
