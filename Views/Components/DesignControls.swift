//
//  DesignControls.swift
//  Hippominder
//
//  Umschalter fuer die Darstellung (Glas / Classic / Blume) und der
//  dazu passende Aktionsknopf. Plattformfrei, damit iPhone, iPad und
//  Mac dieselben Bedienelemente zeigen - vorher lagen beide im
//  iOS-Block von HorseDetailView, und der Mac baute sich eigene.
//

import SwiftUI

// MARK: - Darstellung umschalten

struct DesignModePicker: View {
    @Binding var mode: DesignMode
    @Environment(\.colorScheme) private var colorScheme

    /// Aktive Pille: weiss im Hellen, mittleres Grau im Dunkeln - sonst
    /// steht weisse Schrift auf weissem Grund
    private var activeFill: Color {
        colorScheme == .dark ? Color(white: 0.36) : Color(white: 1.0)
    }

    var body: some View {
        HStack(spacing: 0) {
            ForEach(DesignMode.allCases) { candidate in
                Button {
                    withAnimation(.easeInOut(duration: 0.2)) { mode = candidate }
                } label: {
                    HStack(spacing: 5) {
                        Image(systemName: candidate.icon)
                            .font(.system(size: 11, weight: .semibold))
                        Text(candidate.localizedName)
                            .font(.caption.weight(.semibold))
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 7)
                    .foregroundStyle(mode == candidate ? Color.primary : Color.secondary)
                    .background {
                        if mode == candidate {
                            Capsule()
                                .fill(activeFill)
                                .shadow(color: .black.opacity(0.12), radius: 2, x: 0, y: 1)
                        }
                    }
                }
                .buttonStyle(.plain)
                .accessibilityIdentifier("designMode_\(candidate.rawValue)")
            }
        }
        .padding(3)
        .background(Capsule().fill(Color.gray.opacity(0.14)))
    }
}

// MARK: - Aktionsknopf, passend zur Darstellung

/// Glass: Material mit hellem Rand. Classic: erhabene helle Flaeche mit
/// weichem Schatten - wie die Pillen im urspruenglichen Hardware-Design.
struct DesignedActionButton: View {
    let title: LocalizedStringKey
    let systemImage: String
    let mode: DesignMode
    var subtitle: String?
    var trailingChevron = false
    var action: (() -> Void)?
    @Environment(\.colorScheme) private var colorScheme

    /// Erhabene Flaeche: fast weiss im Hellen, dunkles Grau im Dunkeln -
    /// sonst steht weisse Schrift auf weissem Grund
    private var raisedFill: Color {
        colorScheme == .dark ? Color(white: 0.17) : Color(white: 0.98)
    }
    private var raisedHighlight: Color {
        colorScheme == .dark ? .white.opacity(0.08) : .white.opacity(0.9)
    }
    private var raisedEdge: Color {
        colorScheme == .dark ? .white.opacity(0.12) : .black.opacity(0.06)
    }

    /// Classic: Farben am Foto des Geraets gemessen (#E6ECEE, Kante)
    private var tasteFill: Color {
        colorScheme == .dark ? Color(white: 0.19) : Color(red: 0.90, green: 0.925, blue: 0.933)
    }
    private var tasteKante: Color {
        colorScheme == .dark ? .white.opacity(0.14) : Color(red: 0.78, green: 0.81, blue: 0.82)
    }

    var body: some View {
        if let action {
            Button(action: action) { content }
                .buttonStyle(.plain)
        } else {
            content
        }
    }

    private var content: some View {
        HStack(spacing: 10) {
            Image(systemName: systemImage)
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(.secondary)

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.subheadline.weight(.semibold))
                if let subtitle {
                    Text(subtitle)
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            }

            Spacer(minLength: 0)

            if trailingChevron {
                Image(systemName: "chevron.right")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(.secondary)
            }
        }
        .foregroundStyle(Color.primary)
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.vertical, 13)
        .padding(.horizontal, 18)
        .background(background)
    }

    @ViewBuilder
    private var background: some View {
        switch mode {
        case .glass:
            // Echtes Glas: Material, Glanz von oben links (-45 Grad),
            // unten eine Spur Tiefe, helle Kante ringsum
            Capsule()
                .fill(.ultraThinMaterial)
                .overlay {
                    Capsule().fill(
                        LinearGradient(
                            colors: [.white.opacity(0.35), .clear, .black.opacity(0.07)],
                            startPoint: UnitPoint(x: 0.1, y: 0),
                            endPoint: UnitPoint(x: 0.9, y: 1)
                        )
                    )
                }
                .overlay {
                    Capsule().strokeBorder(
                        LinearGradient(
                            colors: [.white.opacity(0.7), .white.opacity(0.15)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 1
                    )
                }
                .shadow(color: .black.opacity(0.1), radius: 4, x: 1, y: 2)

        case .classic:
            // Kunststofftaster wie am Geraet: abgerundetes Rechteck statt
            // Kapsel, Lichtkante oben, feine Fuge ringsum
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [colorScheme == .dark ? Color(white: 0.24) : .white, tasteFill],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .overlay {
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .strokeBorder(tasteKante, lineWidth: 0.8)
                }
                .shadow(color: .black.opacity(0.18), radius: 2, x: 0, y: 2)

        case .blume:
            Capsule()
                .fill(raisedFill)
                .overlay {
                    Capsule().fill(
                        LinearGradient(
                            colors: [raisedHighlight, .clear],
                            startPoint: .topLeading,
                            endPoint: .bottom
                        )
                    )
                }
                .overlay { Capsule().strokeBorder(raisedEdge, lineWidth: 0.5) }
                .shadow(color: .black.opacity(0.14), radius: 4, x: 1, y: 2)
        }
    }
}
