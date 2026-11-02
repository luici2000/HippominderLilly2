//
//  FlowerTimerViewGlass.swift
//  Hippominder
//
//  Autor: Mathias Hubrich & Claude (Anthropic)
//  Erstellt: 30. Oktober 2026
//  Geaendert: 31. Oktober 2026
//  Version: 3.0.0
//
//  Beschreibung: Mathias' Blumen-Timer, aber aus echtem Glas.
//
//  Die Geometrie ist 1:1 aus den Icon-Composer-PNGs (flower_*.png)
//  vermessen: 12 Kapseln radial nach aussen, deutliche Luecke zur Mitte,
//  Stempel als eigener Kreis. Fuellung startet bei 1 Uhr im Uhrzeigersinn.
//
//  Neu ist nur das Material: statt vorgerenderter PNGs sind es Shapes mit
//  .ultraThinMaterial - dadurch wird das Pferdefoto dahinter gebrochen und
//  eingefaerbt sichtbar. Kein Hof, kein Schein.
//  Glasfarbe frei waehlbar ueber GlobalSettings.glassTint.
//
//  Das Original FlowerTimerView.swift (PNG-Variante) bleibt unberuehrt.
//

import SwiftUI


// MARK: - Einzelnes Glas-Bluetenblatt

struct GlassPetal: View {
    /// Drehwinkel - wird fuer die Gegenrotation des Glanzes gebraucht
    let angle: Double
    let isFilled: Bool
    let tint: Color

    var body: some View {
        if isFilled {
            // Sattes, getoentes Milchglas
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
                // Dunkler Saum: gibt dem Blatt auch vor hellem Foto eine Kante
                .shadow(color: .black.opacity(0.5), radius: 2.5, x: 0, y: 1)
        } else {
            // Klares Fensterglas - nur Kontur, maximaler Kontrast zum gefuellten
            Capsule()
                .fill(.black.opacity(0.1))
                .overlay { specular(strength: 0.3) }
                .overlay {
                    Capsule().strokeBorder(
                        LinearGradient(
                            colors: [.white.opacity(0.65), .white.opacity(0.28)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 1
                    )
                }
                .shadow(color: .black.opacity(0.35), radius: 1.5, x: 0, y: 1)
        }
    }

    /// Glanz gegenrotiert, damit das Licht fuer ALLE Blaetter aus -45 Grad kommt
    private func specular(strength: Double) -> some View {
        LinearGradient(
            colors: [
                .white.opacity(strength),
                .white.opacity(strength * 0.18),
                .clear
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        .rotationEffect(.degrees(-angle))
        .scaleEffect(2.6)
        .clipShape(Capsule())
    }
}

// MARK: - Glas-Stempel (Blumenmitte mit Event-Symbol)

struct GlassStamp: View {
    let tint: Color
    let symbol: String
    let size: CGFloat

    var body: some View {
        ZStack {
            Circle().fill(.ultraThinMaterial)

            Circle().fill(tint.opacity(0.58))

            // Kugeltiefe
            Circle().fill(
                LinearGradient(
                    colors: [.white.opacity(0.3), .clear, .black.opacity(0.22)],
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
                .frame(width: size * 0.44, height: size * 0.24)
                .rotationEffect(.degrees(-45))
                .offset(x: -size * 0.17, y: -size * 0.19)

            Circle().strokeBorder(
                LinearGradient(
                    colors: [.white.opacity(0.68), .white.opacity(0.18)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                ),
                lineWidth: 1
            )

            Image(symbol)
                .resizable()
                .scaledToFit()
                .foregroundStyle(.black)
                .frame(width: size * 0.5, height: size * 0.5)
                .shadow(color: .black.opacity(0.45), radius: 1.5, x: 0, y: 1)
        }
        .frame(width: size, height: size)
        .shadow(color: .black.opacity(0.3), radius: 4, x: 1, y: 2)
    }
}

// MARK: - Glasblume

struct GlassFlower: View {
    let filledPetals: Int
    let tint: Color
    let symbol: String
    var size: CGFloat = 106

    private var petalWidth: CGFloat { size * FlowerGeometry.petalWidth }
    private var petalLength: CGFloat { size * FlowerGeometry.petalLength }
    private var radialDistance: CGFloat { size * FlowerGeometry.radialDistance }
    private var stampSize: CGFloat { size * FlowerGeometry.stampDiameter }

    var body: some View {
        ZStack {
            ForEach(0..<FlowerGeometry.petalCount, id: \.self) { index in
                // Fuellung startet bei 1 Uhr und laeuft im Uhrzeigersinn
                let angle = Double(index + 1) * 30

                GlassPetal(
                    angle: angle,
                    isFilled: index < filledPetals,
                    tint: tint
                )
                .frame(width: petalWidth, height: petalLength)
                // offset aendert das Layout-Frame nicht, deshalb dreht
                // rotationEffect danach um die Blumenmitte
                .offset(y: -radialDistance)
                .rotationEffect(.degrees(angle))
            }

            GlassStamp(tint: tint, symbol: symbol, size: stampSize)
        }
        .frame(width: size, height: size)
    }
}

// MARK: - Glas-Timer (Blume + Beschriftung, transparenter Hintergrund)

struct GlassFlowerTimerView: View {
    let eventType: Horse.EventType
    let remainingDays: Int
    let interval: Int
    let nextDate: Date
    var tint: Color = Color(red: 0.34, green: 0.62, blue: 0.94)
    var flowerSize: CGFloat = 106

    private static let dateFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "dd.MM.yyyy"
        return f
    }()

    /// Gefuellte Blaetter wachsen mit dem verstrichenen Anteil des Intervalls
    var filledPetals: Int {
        FlowerGeometry.filledPetals(remainingDays: remainingDays, interval: interval)
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
        VStack(spacing: 6) {
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
                .lineLimit(1)
                .padding(.horizontal, 10)
                .padding(.vertical, 3)
                .background {
                    ZStack {
                        Capsule().fill(.ultraThinMaterial)
                        Capsule().fill(
                            isExpired ? Color.red.opacity(0.36) : Color.white.opacity(0.12)
                        )
                        Capsule().strokeBorder(.white.opacity(0.46), lineWidth: 0.5)
                    }
                }
                .opacity(isExpired && duePulse ? 0.5 : 1.0)
                .onAppear { syncPulse() }
                // Sonst pulst die Pille weiter, wenn der Termin waehrend der
                // Anzeige erledigt wird
                .onChange(of: isExpired) { _, _ in syncPulse() }

            Text(eventType.localizedName)
                .font(.caption2.weight(.semibold))
                .foregroundStyle(.white)
                .lineLimit(1)
                .shadow(color: .black.opacity(0.6), radius: 3, x: 0, y: 1)

            Text(formattedDate)
                .font(.caption2)
                .foregroundStyle(.white.opacity(0.75))
                .lineLimit(1)
                .shadow(color: .black.opacity(0.55), radius: 3, x: 0, y: 1)
        }
    }

    private func syncPulse() {
        withTransaction(Transaction(animation: nil)) { duePulse = false }
        guard isExpired else { return }
        withAnimation(.easeInOut(duration: 1.0).repeatForever(autoreverses: true)) {
            duePulse = true
        }
    }
}

// MARK: - Fotobuehne fuer die Glasblumen

/// Haelt das Pferdefoto hinter den Glasblumen, damit das Glas etwas zu brechen hat.
struct GlassFlowerStage<Content: View>: View {
    let backgroundImage: Image?
    @ViewBuilder var content: Content

    var body: some View {
        // Der Inhalt bestimmt die Hoehe, das Foto liegt dahinter. Vorher
        // war es umgekehrt mit fester Hoehe - bei groesserer Systemschrift
        // wurde der Text dann abgeschnitten.
        content
            .frame(maxWidth: .infinity)
            .background { untergrund }
            .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
    }

    private var untergrund: some View {
        ZStack {
            Group {
                if let backgroundImage {
                    backgroundImage
                        .resizable()
                        .scaledToFill()
                        // Echtes Glas zeigt den Hintergrund unscharf. Dazu
                        // praktisch: helle Fotos schlucken sonst die
                        // Bluetenblaetter, weil beide hell sind.
                        .blur(radius: 7)
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
            // Deutlich abdunkeln: die Blumen muessen auch auf einem hellen
            // Foto lesbar bleiben, nicht nur auf einem dunklen.
            .overlay(
                LinearGradient(
                    colors: [
                        Color(red: 0.07, green: 0.08, blue: 0.11).opacity(0.42),
                        Color(red: 0.07, green: 0.08, blue: 0.11).opacity(0.55)
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
            )
        }
    }
}

// MARK: - Preview

#if DEBUG
#Preview("Glasblumen auf Foto") {
    // Werte aus Horse.preview
    GlassFlowerStage(backgroundImage: nil) {
        HStack(alignment: .top, spacing: 2) {
            GlassFlowerTimerView(
                eventType: .hufschmied,
                remainingDays: 151,
                interval: 180,
                nextDate: Date().addingTimeInterval(151 * 86400),
                tint: Color(red: 0.34, green: 0.62, blue: 0.94)
            )

            GlassFlowerTimerView(
                eventType: .impfung,
                remainingDays: 46,
                interval: 49,
                nextDate: Date().addingTimeInterval(46 * 86400),
                tint: Color(red: 0.34, green: 0.62, blue: 0.94)
            )

            GlassFlowerTimerView(
                eventType: .wurmkur,
                remainingDays: 11,
                interval: 101,
                nextDate: Date().addingTimeInterval(11 * 86400),
                tint: Color(red: 0.34, green: 0.62, blue: 0.94)
            )
        }
        .padding(.vertical, 14)
    }
    .frame(height: 230)
    .padding()
}
#endif
