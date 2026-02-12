//
//  ImageCropperView.swift
//  Hippominder
//
//  Autor: Mathias Hubrich & Claude (Anthropic)
//  Erstellt: 12. Februar 2026
//  Version: 1.0.0
//
//  Beschreibung: Bild-Zuschnitt mit Pinch-to-Zoom und Drag
//

import SwiftUI

struct ImageCropperView: View {
    let image: UIImage
    let onCrop: (UIImage) -> Void
    @Environment(\.dismiss) private var dismiss

    @State private var scale: CGFloat = 1.0
    @State private var lastScale: CGFloat = 1.0
    @State private var offset: CGSize = .zero
    @State private var lastOffset: CGSize = .zero

    private let cropSize: CGFloat = 280

    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                Text("Ausschnitt wählen")
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

                    Circle()
                        .stroke(Color.white, lineWidth: 2)
                        .frame(width: cropSize, height: cropSize)

                    Rectangle()
                        .fill(Color.black.opacity(0.4))
                        .frame(width: cropSize + 40, height: cropSize + 40)
                        .mask(
                            ZStack {
                                Rectangle()
                                Circle()
                                    .frame(width: cropSize, height: cropSize)
                                    .blendMode(.destinationOut)
                            }
                            .compositingGroup()
                        )
                        .allowsHitTesting(false)
                }
                .frame(width: cropSize, height: cropSize)
                .clipShape(RoundedRectangle(cornerRadius: 12))

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

    private func cropAndSave() {
        let renderer = UIGraphicsImageRenderer(size: CGSize(width: cropSize, height: cropSize))
        let cropped = renderer.image { ctx in
            let imageSize = image.size
            let drawWidth = cropSize * scale
            let drawHeight: CGFloat
            let aspectRatio = imageSize.width / imageSize.height

            if aspectRatio > 1 {
                drawHeight = drawWidth / aspectRatio
            } else {
                drawHeight = drawWidth
            }
            let actualDrawWidth = drawHeight * aspectRatio

            let drawX = (cropSize - actualDrawWidth) / 2 + offset.width
            let drawY = (cropSize - drawHeight) / 2 + offset.height

            image.draw(in: CGRect(x: drawX, y: drawY, width: actualDrawWidth, height: drawHeight))
        }

        let circleRenderer = UIGraphicsImageRenderer(size: CGSize(width: cropSize, height: cropSize))
        let circularImage = circleRenderer.image { ctx in
            let rect = CGRect(x: 0, y: 0, width: cropSize, height: cropSize)
            UIBezierPath(ovalIn: rect).addClip()
            cropped.draw(in: rect)
        }

        onCrop(circularImage)
    }
}
