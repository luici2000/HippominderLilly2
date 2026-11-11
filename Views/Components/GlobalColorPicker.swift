//
//  GlobalColorPicker.swift
//  Hippominder
//
//  Farbschema-Auswahl der Hauptseite: drei 3D-Kugeln (Hellblau, Orange,
//  Grau) und fuer Glas eine freie Farbe. Plattformfrei, damit der Mac
//  dieselbe Auswahl in der Seitenleiste zeigt wie das iPhone oben.
//

import SwiftUI

// MARK: - Globale Farbschema-Auswahl (3D-Kugeln mit -45° Lichteinfall)

struct GlobalColorPicker: View {
    /// Aktives Schema; nil, wenn eine freie Farbe gewaehlt ist
    @Binding var selectedScheme: FlowerColorScheme?
    /// Freie Glasfarbe fuer die Glasblumen (nur auf der Hauptseite waehlbar)
    @Binding var customTint: Color
    /// Freie Farbe nur fuer die Glasblumen anbieten
    var showsCustomTint: Bool = true

    var body: some View {
        VStack(alignment: .trailing, spacing: 2) {
            Text("Farbschema")
                .font(.caption2)
                .foregroundColor(.secondary)

            HStack(spacing: 8) {
                ForEach(FlowerColorScheme.allCases) { scheme in
                    Button(action: {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            selectedScheme = scheme
                        }
                    }) {
                        ColorSphere3D(
                            baseColor: scheme.strongColor,
                            isSelected: selectedScheme == scheme,
                            size: 22
                        )
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel(Text(scheme.rawValue))
                    .accessibilityIdentifier("colorScheme_\(scheme.rawValue)")
                }

                // Freie Glasfarbe
                if showsCustomTint {
                    ColorPicker("Glasfarbe", selection: $customTint, supportsOpacity: false)
                        .labelsHidden()
                        .scaleEffect(0.8)
                        .frame(width: 24, height: 22)
                        .accessibilityIdentifier("colorScheme_custom")
                }
            }
        }
    }
}

// MARK: - Stempel-Kugel (wie der Blumen-Stempel, ohne Umrandung)

struct ColorSphere3D: View {
    let baseColor: Color
    let isSelected: Bool
    let size: CGFloat

    // Wie der Stempel in der Mitte der Blume: 3D-Kugel mit Glaseffekt, KEINE Umrandung

    var body: some View {
        ZStack {
            // Basis-Kreis mit Radial-Gradient (heller in der Mitte)
            Circle()
                .fill(
                    RadialGradient(
                        colors: [
                            baseColor.opacity(isSelected ? 1.0 : 0.35),
                            baseColor.opacity(isSelected ? 0.8 : 0.2)
                        ],
                        center: UnitPoint(x: 0.4, y: 0.4),
                        startRadius: 0,
                        endRadius: size / 2
                    )
                )
                .frame(width: size, height: size)

            // 3D Tiefe/Schatten (unten rechts)
            Circle()
                .fill(
                    LinearGradient(
                        colors: [.clear, .black.opacity(isSelected ? 0.25 : 0.1)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: size, height: size)

            // Highlight/Glanz (oben links, -45° Licht wie bei Icon Composer)
            Circle()
                .fill(
                    RadialGradient(
                        colors: [.white.opacity(isSelected ? 0.7 : 0.4), .clear],
                        center: UnitPoint(x: 0.3, y: 0.3),
                        startRadius: 0,
                        endRadius: size * 0.35
                    )
                )
                .frame(width: size, height: size)
        }
        .frame(width: size, height: size)
        .shadow(color: .black.opacity(0.15), radius: 1.5, x: 0.5, y: 0.5)
    }
}
