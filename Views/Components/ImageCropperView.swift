//
//  ImageCropperView.swift
//  Hippominder
//
//  Autor: Mathias Hubrich & Claude (Anthropic)
//  Erstellt: 12. Februar 2026
//  Version: 1.2.0
//
//  Beschreibung: Bild-Zuschnitt mit Pinch-to-Zoom, Drag und Zoom-Slider (nur iOS)
//

import SwiftUI

#if os(iOS)
import UIKit

/// Welcher Ausschnitt gewaehlt wird
enum CropShape {
    /// Rund - fuer das Profilbild
    case circle
    /// Rechteckig im angegebenen Seitenverhaeltnis (Breite/Hoehe) -
    /// fuer das Hintergrundfoto, das die Fotobuehne fuellt
    case rect(aspect: CGFloat)
}

struct ImageCropperView: View {
    let image: UIImage
    var shape: CropShape = .circle
    let onCrop: (UIImage) -> Void
    @Environment(\.dismiss) private var dismiss

    @State private var scale: CGFloat = 1.0
    @State private var lastScale: CGFloat = 1.0
    @State private var offset: CGSize = .zero
    @State private var lastOffset: CGSize = .zero

    private let cropSize: CGFloat = 280

    /// Hoehe des Ausschnittfensters
    private var cropHeight: CGFloat {
        switch shape {
        case .circle: return cropSize
        case .rect(let aspect): return cropSize / max(0.2, aspect)
        }
    }

    private var titel: String {
        switch shape {
        case .circle: return String(localized: "Ausschnitt wählen")
        case .rect: return String(localized: "Hintergrund zuschneiden")
        }
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                Text(titel)
                    .font(.headline)
                    .padding(.top)

                Text("Verschieben und zoomen zum Zuschneiden")
                    .font(.caption)
                    .foregroundColor(.secondary)

                // Crop area
                ZStack {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFill()
                        .frame(width: cropSize * scale, height: cropSize * scale)
                        .offset(offset)
                        .gesture(
                            DragGesture()
                                .onChanged { value in
                                    offset = CGSize(
                                        width: lastOffset.width + value.translation.width,
                                        height: lastOffset.height + value.translation.height
                                    )
                                }
                                .onEnded { _ in
                                    lastOffset = offset
                                }
                        )
                        .gesture(
                            MagnificationGesture()
                                .onChanged { value in
                                    scale = max(0.5, min(5.0, lastScale * value))
                                }
                                .onEnded { _ in
                                    lastScale = scale
                                }
                        )

                    // Rahmen des gewaehlten Ausschnitts
                    ausschnittForm
                        .stroke(Color.white, lineWidth: 2)
                        .frame(width: cropSize, height: cropHeight)

                    // Alles ausserhalb abdunkeln
                    Rectangle()
                        .fill(Color.black.opacity(0.45))
                        .frame(width: cropSize + 60, height: cropSize + 60)
                        .mask(
                            ZStack {
                                Rectangle()
                                ausschnittForm
                                    .frame(width: cropSize, height: cropHeight)
                                    .blendMode(.destinationOut)
                            }
                            .compositingGroup()
                        )
                        .allowsHitTesting(false)
                }
                .frame(width: cropSize, height: cropSize)
                .clipShape(RoundedRectangle(cornerRadius: 12))

                // Zoom-Slider
                HStack {
                    Image(systemName: "minus.magnifyingglass")
                        .foregroundColor(.secondary)
                    Slider(value: $scale, in: 0.5...5.0)
                        .onChange(of: scale) { _, _ in
                            lastScale = scale
                        }
                    Image(systemName: "plus.magnifyingglass")
                        .foregroundColor(.secondary)
                }
                .padding(.horizontal, 40)

                Spacer()
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Abbrechen") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Fertig") { cropAndSave() }
                        .bold()
                }
            }
        }
    }

    /// Form des Ausschnittfensters, als Shape fuer Rahmen und Maske
    private var ausschnittForm: AnyShape {
        switch shape {
        case .circle: return AnyShape(Circle())
        case .rect: return AnyShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
        }
    }

    private func cropAndSave() {
        // Das Ausschnittfenster ist beim Hintergrund breiter als hoch,
        // beim Profilbild quadratisch.
        let ziel = CGSize(width: cropSize, height: cropHeight)

        // Hintergrundfotos fuellen eine grosse Flaeche - in Fenstergroesse
        // gerendert waeren sie matschig.
        let skalierung: CGFloat
        switch shape {
        case .circle: skalierung = 1
        case .rect: skalierung = 4
        }
        let ausgabe = CGSize(width: ziel.width * skalierung, height: ziel.height * skalierung)

        let renderer = UIGraphicsImageRenderer(size: ausgabe)
        let ergebnis = renderer.image { _ in
            // Das Bild wird genauso gezeichnet wie in der Vorschau, nur
            // um die Ausgabegroesse hochskaliert - sonst sitzt der
            // Ausschnitt woanders als auf dem Bildschirm gewaehlt.
            let aspectRatio = image.size.width / image.size.height
            let drawWidth = cropSize * scale
            let drawHeight = aspectRatio > 1 ? drawWidth / aspectRatio : drawWidth
            let actualDrawWidth = drawHeight * aspectRatio

            let drawX = (cropSize - actualDrawWidth) / 2 + offset.width
            let drawY = (cropHeight - drawHeight) / 2 + offset.height

            if case .circle = shape {
                UIBezierPath(ovalIn: CGRect(origin: .zero, size: ausgabe)).addClip()
            }

            image.draw(in: CGRect(
                x: drawX * skalierung,
                y: drawY * skalierung,
                width: actualDrawWidth * skalierung,
                height: drawHeight * skalierung
            ))
        }

        onCrop(ergebnis)
    }
}
#endif
