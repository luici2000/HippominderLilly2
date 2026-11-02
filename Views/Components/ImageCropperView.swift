//
//  ImageCropperView.swift
//  Hippominder
//
//  Autor: Mathias Hubrich & Claude (Anthropic)
//  Erstellt: 12. Februar 2026
//  Geaendert: 2. November 2026
//  Version: 2.0.0
//
//  Beschreibung: Bildzuschnitt mit sichtbarem Ausschnittfenster, Ziehen,
//  Zoomen per Finger und Regler - rund fuer das Profilbild, rechteckig im
//  Buehnenformat fuer das Hintergrundfoto.
//
//  Das Bild wird in voller Flaeche gezeigt und nur ausserhalb des Fensters
//  abgedunkelt. So ist sichtbar, was wegfaellt, statt es zu erraten.
//

import SwiftUI

#if os(iOS)
import UIKit

/// Welcher Ausschnitt gewaehlt wird
enum CropShape: Equatable {
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
    @State private var startScale: CGFloat = 1.0
    @State private var offset: CGSize = .zero
    @State private var startOffset: CGSize = .zero
    /// Fensterbreite auf dem Bildschirm - in dieser Einheit wurde der
    /// Versatz gemessen, das Speichern rechnet darauf um
    @State private var gemesseneFensterbreite: CGFloat = 0

    private let minZoom: CGFloat = 1.0
    private let maxZoom: CGFloat = 5.0

    var body: some View {
        NavigationStack {
            GeometryReader { geo in
                let fenster = fenstergroesse(in: geo.size)

                ZStack {
                    Color.black.ignoresSafeArea()

                    // Das Bild - fuellt das Fenster mindestens aus und laesst
                    // sich darueber hinaus schieben und zoomen
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFill()
                        .frame(width: fenster.width, height: fenster.height)
                        .scaleEffect(scale)
                        .offset(offset)
                        .frame(width: geo.size.width, height: geo.size.height)
                        .clipped()

                    // Alles ausserhalb des Ausschnitts abdunkeln
                    abdunklung(fenster: fenster, flaeche: geo.size)
                        .allowsHitTesting(false)

                    // Rahmen des Ausschnitts
                    form
                        .stroke(.white, lineWidth: 2)
                        .frame(width: fenster.width, height: fenster.height)
                        .shadow(color: .black.opacity(0.5), radius: 2)
                        .allowsHitTesting(false)
                }
                .contentShape(Rectangle())
                .gesture(ziehen.simultaneously(with: zoomen))
                // Der Versatz wird in dieser Fensterbreite gemessen; das
                // Speichern rechnet damit auf sein eigenes Mass um
                .onAppear { gemesseneFensterbreite = fenster.width }
                .onChange(of: fenster.width) { _, neu in gemesseneFensterbreite = neu }
            }
            .ignoresSafeArea(edges: .bottom)
            .safeAreaInset(edge: .bottom) { regler }
            .navigationTitle(titel)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Abbrechen") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Fertig") { cropAndSave() }.bold()
                }
            }
        }
    }

    // MARK: - Bedienung

    private var ziehen: some Gesture {
        DragGesture()
            .onChanged { wert in
                offset = CGSize(
                    width: startOffset.width + wert.translation.width,
                    height: startOffset.height + wert.translation.height
                )
            }
            .onEnded { _ in startOffset = offset }
    }

    private var zoomen: some Gesture {
        MagnificationGesture()
            .onChanged { wert in
                scale = min(maxZoom, max(minZoom, startScale * wert))
            }
            .onEnded { _ in startScale = scale }
    }

    private var regler: some View {
        HStack(spacing: 12) {
            Image(systemName: "photo")
                .font(.caption)
            Slider(value: $scale, in: minZoom...maxZoom)
                .onChange(of: scale) { _, neu in startScale = neu }
            Image(systemName: "photo.fill")
                .font(.title3)
        }
        .foregroundStyle(.white)
        .padding(.horizontal, 24)
        .padding(.vertical, 14)
        .background(.black.opacity(0.85))
    }

    // MARK: - Geometrie

    /// Das Ausschnittfenster, eingepasst in die verfuegbare Flaeche
    private func fenstergroesse(in flaeche: CGSize) -> CGSize {
        let breite = flaeche.width - 32
        switch shape {
        case .circle:
            let kante = min(breite, flaeche.height - 120)
            return CGSize(width: kante, height: kante)
        case .rect(let aspect):
            let hoehe = breite / max(0.2, aspect)
            if hoehe > flaeche.height - 120 {
                let h = flaeche.height - 120
                return CGSize(width: h * aspect, height: h)
            }
            return CGSize(width: breite, height: hoehe)
        }
    }

    private var form: AnyShape {
        switch shape {
        case .circle: return AnyShape(Circle())
        case .rect: return AnyShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        }
    }

    private func abdunklung(fenster: CGSize, flaeche: CGSize) -> some View {
        Rectangle()
            .fill(.black.opacity(0.6))
            .mask {
                ZStack {
                    Rectangle()
                    form
                        .frame(width: fenster.width, height: fenster.height)
                        .blendMode(.destinationOut)
                }
                .compositingGroup()
            }
    }

    private var titel: String {
        switch shape {
        case .circle: return String(localized: "Ausschnitt wählen")
        case .rect: return String(localized: "Hintergrund zuschneiden")
        }
    }

    // MARK: - Speichern

    private func cropAndSave() {
        // In der Ausgabe zaehlt nur das Verhaeltnis von Bild zu Fenster,
        // nicht die Bildschirmgroesse. Darum wird mit einem festen
        // Fenstermass gerechnet und am Ende hochskaliert.
        let basis: CGFloat = 320
        let fenster: CGSize
        switch shape {
        case .circle:
            fenster = CGSize(width: basis, height: basis)
        case .rect(let aspect):
            fenster = CGSize(width: basis, height: basis / max(0.2, aspect))
        }

        // Hintergrundfotos fuellen eine grosse Flaeche - in Fenstergroesse
        // gerendert waeren sie matschig
        let faktor: CGFloat = (shape == .circle) ? 2 : 4
        let ausgabe = CGSize(width: fenster.width * faktor, height: fenster.height * faktor)

        // Genau wie die Anzeige rechnen: scaledToFill ins Fenster, dann
        // der Zoom des Nutzers. Der Versatz kommt in Fenstereinheiten,
        // muss also mitskaliert werden.
        let fuellFaktor = max(fenster.width / image.size.width,
                              fenster.height / image.size.height)
        let breite = image.size.width * fuellFaktor * scale
        let hoehe = image.size.height * fuellFaktor * scale

        let versatzFaktor = gemesseneFensterbreite > 0
            ? fenster.width / gemesseneFensterbreite
            : 1

        let x = (fenster.width - breite) / 2 + offset.width * versatzFaktor
        let y = (fenster.height - hoehe) / 2 + offset.height * versatzFaktor

        let renderer = UIGraphicsImageRenderer(size: ausgabe)
        let ergebnis = renderer.image { _ in
            if case .circle = shape {
                UIBezierPath(ovalIn: CGRect(origin: .zero, size: ausgabe)).addClip()
            }
            image.draw(in: CGRect(
                x: x * faktor, y: y * faktor,
                width: breite * faktor, height: hoehe * faktor
            ))
        }

        onCrop(ergebnis)
    }

}
#endif
