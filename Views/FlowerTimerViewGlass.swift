//
//  FlowerTimerViewGlass.swift
//  Hippominder
//
//  Autor: Mathias Hubrich & Claude (Anthropic)
//  Erstellt: 30. Oktober 2026
//  Geaendert: 31. Oktober 2026
//  Version: 2.0.0
//
//  Beschreibung: Blumen-Timer aus echtem Glas.
//  Die 12 Bluetenblaetter sind SwiftUI-Shapes mit .ultraThinMaterial -
//  der Hintergrund (Pferdefoto) wird durch sie hindurch gebrochen und
//  eingefaerbt sichtbar. Kein Hof, kein Schein, keine PNGs.
//  Glasfarbe frei waehlbar ueber GlobalSettings.glassTint.
//  Lichteinfall konstant -45 Grad, auch bei gedrehten Blaettern.
//
//  Das Original FlowerTimerView.swift (PNG-Variante) bleibt unberuehrt.
//

import SwiftUI

// MARK: - Bluetenblatt-Form

/// Tropfenform: Spitze unten (Blumenmitte), runde Kuppe oben.
struct PetalShape: Shape {
    func path(in rect: CGRect) -> Path {
        let w = rect.width
        let h = rect.height
        var p = Path()

        p.move(to: CGPoint(x: w * 0.5, y: h))
        p.addCurve(
            to: CGPoint(x: w * 0.5, y: 0),
            control1: CGPoint(x: -w * 0.06, y: h * 0.60),
            control2: CGPoint(x: w * 0.14, y: h * 0.03)
        )
        p.addCurve(
            to: CGPoint(x: w * 0.5, y: h),
            control1: CGPoint(x: w * 0.86, y: h * 0.03),
            control2: CGPoint(x: w * 1.06, y: h * 0.60)
        )
        p.closeSubpath()
        return p
    }
}

// MARK: - Einzelnes Glas-Bluetenblatt

struct GlassPetal: View {
    /// Drehwinkel des Blattes - wird fuer die Gegenrotation des Glanzes gebraucht
    let angle: Double
    let isFilled: Bool
    let tint: Color

    var body: some View {
        PetalShape()
            // Basis: echtes Material - bricht und blurrt den Hintergrund
            .fill(.ultraThinMaterial)
            // Einfaerbung (leere Blaetter bleiben klar)
            .overlay {
                PetalShape()
                    .fill(tint.opacity(isFilled ? 0.26 : 0.04))
            }
            // Tiefe: innen unten rechts abgedunkelt
            .overlay {
                PetalShape()
                    .fill(
                        LinearGradient(
                            colors: [.clear, .black.opacity(isFilled ? 0.16 : 0.07)],
                            startPoint: UnitPoint(x: 0.25, y: 0.1),
                            endPoint: UnitPoint(x: 0.9, y: 0.95)
                        )
                    )
            }
            // Spekularer Glanz - gegenrotiert, damit das Licht fuer ALLE
            // Blaetter aus derselben Richtung (-45 Grad) kommt
            .overlay {
                LinearGradient(
                    colors: [
                        .white.opacity(isFilled ? 0.62 : 0.3),
                        .white.opacity(isFilled ? 0.12 : 0.06),
                        .clear
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .rotationEffect(.degrees(-angle))
                .scaleEffect(2.2)
                .clipShape(PetalShape())
            }
            // Glasrand
            .overlay {
                PetalShape()
                    .stroke(
                        LinearGradient(
                            colors: [
                                .white.opacity(isFilled ? 0.6 : 0.32),
                                .white.opacity(isFilled ? 0.14 : 0.08)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 1
                    )
            }
    }
}

// MARK: - Glas-Stempel (Blumenmitte mit Event-Symbol)

struct GlassStamp: View {
    let tint: Color
    let symbol: String
    let size: CGFloat

    var body: some View {
        ZStack {
            Circle()
                .fill(.ultraThinMaterial)

            Circle()
                .fill(tint.opacity(0.32))

            // Kugeltiefe
            Circle()
                .fill(
                    LinearGradient(
                        colors: [.white.opacity(0.3), .clear, .black.opacity(0.2)],
                        startPoint: UnitPoint(x: 0.2, y: 0.1),
                        endPoint: UnitPoint(x: 0.88, y: 0.95)
                    )
                )

            // Glanzpunkt oben links
            Ellipse()
                .fill(
                    RadialGradient(
                        colors: [.white.opacity(0.9), .clear],
                        center: .center,
                        startRadius: 0,
                        endRadius: size * 0.28
                    )
                )
                .frame(width: size * 0.44, height: size * 0.22)
                .rotationEffect(.degrees(-45))
                .offset(x: -size * 0.17, y: -size * 0.19)

            Circle()
                .stroke(
                    LinearGradient(
                        colors: [.white.opacity(0.68), .white.opacity(0.16)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 1
                )

            Image(symbol)
                .resizable()
                .scaledToFit()
                .frame(width: size * 0.46, height: size * 0.46)
                .shadow(color: .black.opacity(0.45), radius: 1.5, x: 0, y: 1)
        }
        .frame(width: size, height: size)
    }
}

// MARK: - Glasblume (12 Blaetter + Stempel)

struct GlassFlower: View {
    let filledPetals: Int
    let tint: Color
    let symbol: String
    var size: CGFloat = 124

    private var petalWidth: CGFloat { size * 0.30 }
    private var petalHeight: CGFloat { size * 0.44 }
    private var stampSize: CGFloat { size * 0.33 }

    var body: some View {
        ZStack {
            ForEach(0..<12, id: \.self) { index in
                let angle = Double(index) * 30

                GlassPetal(
                    angle: angle,
                    isFilled: index < filledPetals,
                    tint: tint
                )
                .frame(width: petalWidth, height: petalHeight)
                // Basis des Blattes auf die Blumenmitte schieben.
                // offset aendert das Layout-Frame nicht, deshalb dreht
                // rotationEffect danach um genau diese Mitte.
                .offset(y: -petalHeight / 2)
                .rotationEffect(.degrees(angle))
            }

            GlassStamp(tint: tint, symbol: symbol, size: stampSize)
        }
        .frame(width: size, height: size)
        .shadow(color: .black.opacity(0.25), radius: 7, x: 3, y: 5)
    }
}

// MARK: - Glas-Timer (Blume + Beschriftung, transparenter Hintergrund)

struct GlassFlowerTimerView: View {
    let eventType: Horse.EventType
    let remainingDays: Int
    let interval: Int
    let nextDate: Date
    var tint: Color = Color(red: 0.34, green: 0.62, blue: 0.94)
    var flowerSize: CGFloat = 124

    private static let dateFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "dd.MM.yyyy"
        return f
    }()

    /// Gefuellte Blaetter wachsen mit dem verstrichenen Anteil des Intervalls
    var filledPetals: Int {
        if remainingDays <= 0 { return 12 }
        let remainingShare = Double(remainingDays) / Double(interval)
        return min(12, max(0, 12 - Int(remainingShare * 12)))
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

    @State private var duePulse = false

    var body: some View {
        VStack(spacing: 7) {
            GlassFlower(
                filledPetals: filledPetals,
                tint: tint,
                symbol: eventType.symbol,
                size: flowerSize
            )

            // Tage als Glaspille
            Text(formattedDays)
                .font(.caption.bold())
                .foregroundStyle(.white)
                .padding(.horizontal, 11)
                .padding(.vertical, 3)
                .background {
                    ZStack {
                        Capsule().fill(.ultraThinMaterial)
                        Capsule().fill(
                            isExpired ? Color.red.opacity(0.34) : Color.white.opacity(0.1)
                        )
                        Capsule().strokeBorder(.white.opacity(0.45), lineWidth: 0.5)
                    }
                }
                .opacity(isExpired && duePulse ? 0.5 : 1.0)
                .onAppear {
                    guard isExpired else { return }
                    withAnimation(.easeInOut(duration: 1.0).repeatForever(autoreverses: true)) {
                        duePulse = true
                    }
                }

            Text(eventType.localizedName)
                .font(.caption2.weight(.semibold))
                .foregroundStyle(.white)
                .shadow(color: .black.opacity(0.55), radius: 3, x: 0, y: 1)

            Text(formattedDate)
                .font(.caption2)
                .foregroundStyle(.white.opacity(0.75))
                .shadow(color: .black.opacity(0.5), radius: 3, x: 0, y: 1)
        }
    }
}

// MARK: - Fotobuehne fuer die Glasblumen

/// Haelt das Pferdefoto hinter den Glasblumen, damit das Glas etwas zu brechen hat.
struct GlassFlowerStage<Content: View>: View {
    let backgroundImage: Image?
    @ViewBuilder var content: Content

    var body: some View {
        ZStack {
            Group {
                if let backgroundImage {
                    backgroundImage
                        .resizable()
                        .scaledToFill()
                } else {
                    LinearGradient(
                        colors: [
                            Color(red: 0.44, green: 0.48, blue: 0.54),
                            Color(red: 0.22, green: 0.25, blue: 0.30)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                }
            }
            .overlay(Color.black.opacity(0.18))

            content
        }
        .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
    }
}

// MARK: - Preview

#if DEBUG
#Preview("Glasblumen auf Foto") {
    GlassFlowerStage(backgroundImage: nil) {
        HStack(alignment: .top, spacing: 4) {
            GlassFlowerTimerView(
                eventType: .hufschmied,
                remainingDays: 151,
                interval: 180,
                nextDate: Date().addingTimeInterval(151 * 86400),
                tint: Color(red: 0.34, green: 0.62, blue: 0.94)
            )

            GlassFlowerTimerView(
                eventType: .impfung,
                remainingDays: 12,
                interval: 49,
                nextDate: Date().addingTimeInterval(12 * 86400),
                tint: Color(red: 0.34, green: 0.62, blue: 0.94)
            )

            GlassFlowerTimerView(
                eventType: .wurmkur,
                remainingDays: 0,
                interval: 101,
                nextDate: Date(),
                tint: Color(red: 0.34, green: 0.62, blue: 0.94)
            )
        }
        .padding(.vertical, 16)
    }
    .frame(height: 250)
    .padding()
}
#endif
