//
//  WatchStil.swift
//  Hippominder Watch App
//
//  Wie die Uhr aussieht - eingestellt auf der Uhr selbst, wie bei den
//  Zifferblaettern: lange druecken, Stil waehlen, Krone dreht die Farbe.
//
//  Mathias, 25.11.2026: ein Stil fuer alle Pferde, die Farbe auf Wunsch je
//  Pferd, und die Uhr stellt das selbst ein. Bis man auf der Uhr eine Farbe
//  waehlt, gilt die Glasfarbe vom iPhone. Gespeichert nur auf der Uhr, wie
//  iPhone und iPad ihre Darstellung auch je Geraet behalten.
//

import SwiftUI

enum WatchDarstellung: String, CaseIterable, Identifiable {
    case glas, classic
    var id: String { rawValue }
    var name: String {
        switch self {
        case .glas: return "Glas"
        case .classic: return "Classic"
        }
    }
}

struct WatchFarbwahl: Identifiable, Equatable {
    let id: String
    let name: String
    let rot: Double, gruen: Double, blau: Double
    var farbe: Color { Color(red: rot, green: gruen, blue: blau) }
}

@MainActor
final class WatchStil: ObservableObject {
    static let shared = WatchStil()

    /// Die ersten drei sind die Farbschemata vom iPhone, gleiche Werte wie
    /// `FlowerColorScheme.glassRGB`. Kein Rot: Rot heisst auf der Uhr "abgelaufen".
    static let farben: [WatchFarbwahl] = [
        WatchFarbwahl(id: "hellblau", name: "Hellblau", rot: 0.34, gruen: 0.62, blau: 0.94),
        WatchFarbwahl(id: "orange", name: "Orange", rot: 0.96, gruen: 0.58, blau: 0.22),
        WatchFarbwahl(id: "grau", name: "Grau", rot: 0.56, gruen: 0.58, blau: 0.62),
        WatchFarbwahl(id: "tuerkis", name: "Türkis", rot: 0.22, gruen: 0.74, blau: 0.74),
        WatchFarbwahl(id: "gruen", name: "Grün", rot: 0.38, gruen: 0.76, blau: 0.42),
        WatchFarbwahl(id: "violett", name: "Violett", rot: 0.62, gruen: 0.48, blau: 0.92),
        WatchFarbwahl(id: "rosa", name: "Rosa", rot: 0.95, gruen: 0.52, blau: 0.72),
        WatchFarbwahl(id: "gelb", name: "Gelb", rot: 0.95, gruen: 0.82, blau: 0.28)
    ]

    private enum Schluessel {
        static let darstellung = "uhrDarstellung"
        static let farbe = "uhrFarbe"
        static let jePferd = "uhrFarbeJePferd"
    }

    @Published var darstellung: WatchDarstellung {
        didSet { UserDefaults.standard.set(darstellung.rawValue, forKey: Schluessel.darstellung) }
    }
    /// nil: noch nichts auf der Uhr gewaehlt - dann die Glasfarbe vom iPhone
    @Published var farbeID: String? {
        didSet { UserDefaults.standard.set(farbeID, forKey: Schluessel.farbe) }
    }
    /// Pferd (UUID) -> Farbe; fehlt ein Pferd, gilt die Farbe fuer alle
    @Published var jePferd: [String: String] {
        didSet { UserDefaults.standard.set(jePferd, forKey: Schluessel.jePferd) }
    }

    private init() {
        let d = UserDefaults.standard
        darstellung = WatchDarstellung(rawValue: d.string(forKey: Schluessel.darstellung) ?? "") ?? .glas
        farbeID = d.string(forKey: Schluessel.farbe)
        jePferd = d.dictionary(forKey: Schluessel.jePferd) as? [String: String] ?? [:]
    }

    static func wahl(_ id: String?) -> WatchFarbwahl? {
        guard let id else { return nil }
        return farben.first { $0.id == id }
    }

    /// Die Farbe fuer alle Pferde
    var grundfarbe: Color { Self.wahl(farbeID)?.farbe ?? WatchGlas.tint }

    /// Die Farbe eines Pferdes: seine eigene, sonst die fuer alle
    func farbe(fuer horseID: UUID) -> Color {
        Self.wahl(jePferd[horseID.uuidString])?.farbe ?? grundfarbe
    }

    func setzeFarbe(_ id: String?, fuer horseID: UUID) {
        jePferd[horseID.uuidString] = id
    }
}

// MARK: - Eine Blume im gewaehlten Stil

/// Zeichnet eine Blume so, wie es auf der Uhr eingestellt ist: Glas mit
/// dem Symbol in der Mitte, oder Classic als Rose im olivgrauen LCD-Fenster.
/// Im LCD bleibt die Mitte leer (CLAUDE.md), das Symbol steht darunter.
struct WatchStilBlume: View {
    let filledPetals: Int
    let isExpired: Bool
    let symbol: String
    let tint: Color
    let size: CGFloat
    /// Symbol zeigen? In der Liste steht es schon ueber der Blume.
    var mitSymbol = true
    /// Classic: eigenes LCD-Fenster, oder sitzt die Rose in einem
    /// gemeinsamen (`WatchLCDFlaeche`)? Mathias, 25.11.2026: mehrere Rosen
    /// gehoeren auf *ein* Display wie am Geraet, nicht in Einzelkaesten.
    var eigenesFenster = true
    @ObservedObject private var stil = WatchStil.shared

    var body: some View {
        switch stil.darstellung {
        case .glas:
            if mitSymbol {
                WatchGlassFlower(filledPetals: filledPetals, isExpired: isExpired,
                                 symbol: symbol, tint: tint, size: size)
            } else {
                WatchFlower(filledPetals: filledPetals, isExpired: isExpired,
                            color: isExpired ? .red : tint, size: size)
            }
        case .classic:
            if eigenesFenster {
                WatchLCDFenster(filledPetals: filledPetals, isExpired: isExpired,
                                symbol: mitSymbol ? symbol : nil, size: size)
            } else {
                WatchLCDRoseMitSymbol(filledPetals: filledPetals, isExpired: isExpired,
                                      symbol: mitSymbol ? symbol : nil, size: size)
            }
        }
    }
}

/// Rose ohne eigenen Grund, fuer ein gemeinsames LCD. Symbol darunter,
/// die Mitte bleibt leer.
struct WatchLCDRoseMitSymbol: View {
    let filledPetals: Int
    let isExpired: Bool
    let symbol: String?
    let size: CGFloat

    var body: some View {
        let symbolHoehe = symbol == nil ? 0 : (size * 0.17).rounded()
        VStack(spacing: 1) {
            LCDRose(filledPetals: filledPetals, isExpired: isExpired, size: size)
            if let symbol {
                Image(symbol)
                    .resizable()
                    .scaledToFit()
                    .foregroundStyle(LCDPalette.on)
                    .frame(height: symbolHoehe)
            }
        }
    }
}

/// Der olivgraue Grund des Geraetedisplays, als Hintergrund fuer mehrere
/// Rosen - ein Display, nicht drei.
struct WatchLCDFlaeche: ViewModifier {
    let aktiv: Bool
    func body(content: Content) -> some View {
        if aktiv {
            content
                .padding(.vertical, 5)
                .padding(.horizontal, 4)
                .background(
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .fill(LinearGradient(colors: [LCDPalette.base, LCDPalette.baseEdge],
                                             startPoint: .topLeading, endPoint: .bottomTrailing))
                )
        } else {
            content
        }
    }
}

extension View {
    /// Legt bei Classic ein gemeinsames LCD unter den Inhalt
    func lcdFlaeche(_ aktiv: Bool) -> some View { modifier(WatchLCDFlaeche(aktiv: aktiv)) }
}

/// Ein Stueck Geraetedisplay: olivgrauer Grund, darauf die Rose.
struct WatchLCDFenster: View {
    let filledPetals: Int
    let isExpired: Bool
    let symbol: String?
    let size: CGFloat

    var body: some View {
        let rand = (size * 0.06).rounded()
        let symbolHoehe = symbol == nil ? 0 : (size * 0.16).rounded()
        let rose = (size - 2 * rand - symbolHoehe).rounded(.down)
        VStack(spacing: 0) {
            LCDRose(filledPetals: filledPetals, isExpired: isExpired, size: rose)
            if let symbol {
                Image(symbol)
                    .resizable()
                    .scaledToFit()
                    .foregroundStyle(LCDPalette.on)
                    .frame(height: symbolHoehe)
            }
        }
        .frame(width: size, height: size)
        .background(
            RoundedRectangle(cornerRadius: (size * 0.14).rounded(), style: .continuous)
                .fill(LinearGradient(colors: [LCDPalette.base, LCDPalette.baseEdge],
                                     startPoint: .topLeading, endPoint: .bottomTrailing))
        )
    }
}

// MARK: - Stil-Seite

/// Was ein langer Druck oeffnet. Ohne Pferd: Stil und Farbe fuer alle.
/// Mit Pferd: nur die Farbe dieses Pferdes.
struct WatchStilView: View {
    let pferd: Horse?
    @ObservedObject private var stil = WatchStil.shared
    @State private var index: Double = 0

    /// Wahlmoeglichkeiten der Krone. Beim Pferd steht vorne "wie alle".
    private var optionen: [WatchFarbwahl?] {
        (pferd == nil ? [] : [nil]) + WatchStil.farben.map { Optional($0) }
    }

    private var gewaehlt: WatchFarbwahl? {
        let i = min(max(Int(index.rounded()), 0), optionen.count - 1)
        return optionen[i]
    }

    private var vorschauFarbe: Color {
        gewaehlt?.farbe ?? stil.grundfarbe
    }

    var body: some View {
        VStack(spacing: 5) {
            if pferd == nil {
                // Zwei flache Schalter statt grosser Knoepfe - sonst rutscht
                // die Seite auf der 41 mm unter den Titel
                HStack(spacing: 6) {
                    ForEach(WatchDarstellung.allCases) { art in
                        let an = stil.darstellung == art
                        Button { stil.darstellung = art } label: {
                            Text(art.name)
                                .font(.system(size: 13, weight: .semibold))
                                .foregroundStyle(an ? Color.black : Color.white)
                                .padding(.vertical, 5)
                                .frame(maxWidth: .infinity)
                                .background(Capsule().fill(an ? Color.white : Color.white.opacity(0.16)))
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal, 6)
            }

            WatchStilBlume(filledPetals: 8, isExpired: false, symbol: Horse.EventType.hufschmied.symbol,
                           tint: vorschauFarbe, size: (60 * WatchMass.faktor).rounded())

            if stil.darstellung == .classic {
                Text("Classic ist einfarbig wie das Original")
                    .font(.system(size: 11))
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
            } else {
                Text(gewaehlt?.name ?? "wie alle Pferde")
                    .font(.system(size: 14, weight: .semibold))
                HStack(spacing: 3) {
                    ForEach(optionen.indices, id: \.self) { i in
                        Circle()
                            .fill(optionen[i]?.farbe ?? stil.grundfarbe)
                            .frame(width: i == Int(index.rounded()) ? 9 : 6,
                                   height: i == Int(index.rounded()) ? 9 : 6)
                            .overlay {
                                if optionen[i] == nil {
                                    Circle().strokeBorder(.white, lineWidth: 1)
                                }
                            }
                    }
                }
                Text("Krone dreht die Farbe")
                    .font(.system(size: 9))
                    .foregroundColor(.secondary)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .focusable(stil.darstellung == .glas)
        .digitalCrownRotation($index, from: 0, through: Double(optionen.count - 1), by: 1,
                              sensitivity: .low, isContinuous: false,
                              isHapticFeedbackEnabled: true)
        .onAppear { index = Double(startIndex) }
        .onChange(of: Int(index.rounded())) { _, _ in uebernimm() }
        .navigationTitle(pferd?.name ?? "Stil")
    }

    private var startIndex: Int {
        let id = pferd.map { stil.jePferd[$0.id.uuidString] } ?? stil.farbeID
        return optionen.firstIndex { $0?.id == id } ?? 0
    }

    private func uebernimm() {
        if let pferd {
            stil.setzeFarbe(gewaehlt?.id, fuer: pferd.id)
        } else {
            stil.farbeID = gewaehlt?.id
        }
    }
}
