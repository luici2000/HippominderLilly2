//
//  WatchContentView.swift
//  Hippominder Watch App
//
//  Autor: Mathias Hubrich & Claude (Anthropic)
//  Erstellt: 13. Februar 2026
//  Version: 1.0.0
//
//  Beschreibung: Hauptansicht der Watch App mit Pferde-Uebersicht
//

import SwiftUI
import SwiftData
import WatchKit

struct WatchContentView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var horses: [Horse]
    @ObservedObject var syncReceiver = WatchSyncReceiver.shared
    /// Langer Druck auf die Liste oeffnet den Stil fuer alle Pferde
    @State private var zeigeStil = false
    /// Navigationspfad; Debug: Start mit "-demoDetail" springt direkt zur
    /// ersten Terminseite des ersten Pferdes
    @State private var pfad = NavigationPath()

    var body: some View {
        NavigationStack(path: $pfad) {
            if horses.isEmpty {
                VStack(spacing: 8) {
                    if syncReceiver.isSyncing {
                        ProgressView()
                            .padding(.bottom, 4)
                        Text("Synchronisiere...")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    } else {
                        Image(systemName: "figure.equestrian.sports")
                            .font(.largeTitle)
                            .foregroundColor(.gray)
                        Text("Keine Pferde")
                            .font(.headline)
                            .foregroundColor(.gray)
                        Text("Füge Pferde in der\niPhone-App hinzu")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                        // Nach einer Neuinstallation fehlt der Stand, bis das
                        // iPhone ihn schickt - hier laesst er sich holen
                        Button("Vom iPhone holen") {
                            WatchSyncReceiver.shared.bitteUmDatenFallsLeer()
                        }
                        .font(.caption2)
                        .padding(.top, 4)
                        // Auch ohne Pferde soll ablesbar sein, welcher
                        // Stand hier liegt
                        Text(Versionsinfo.zeileKurz)
                            .font(.system(size: 9))
                            .foregroundColor(.secondary)
                            .padding(.top, 2)
                    }
                }
            } else {
                List {
                    ForEach(horses) { horse in
                        WatchHorseRow(horse: horse) { eventType in
                            oeffneTermin(eventType, von: horse)
                        }
                    }

                    // Letzter Sync und Version. Die Version steht da, damit
                    // beim Bauen zu sehen ist, welcher Stand auf der Uhr
                    // wirklich liegt - die Uhr bekommt ihn oft spaeter als
                    // das iPhone.
                    Section {
                        VStack(spacing: 1) {
                            if let lastSync = syncReceiver.lastSyncDate {
                                Text("Sync \(lastSync, style: .relative) her")
                            }
                            Text(Versionsinfo.zeileKurz)
                            Text("Lange drücken: Stil")
                        }
                        .font(.system(size: 9))
                        .foregroundColor(.secondary)
                        .frame(maxWidth: .infinity)
                    }
                    .listRowBackground(Color.clear)
                }
                .navigationTitle("Hippominder")
                // Wie beim Zifferblatt: lange druecken, dann Stil und Farbe
                .simultaneousGesture(
                    LongPressGesture(minimumDuration: 0.6).onEnded { _ in zeigeStil = true }
                )
                .sheet(isPresented: $zeigeStil) {
                    NavigationStack { WatchStilView(pferd: nil) }
                }
                .navigationDestination(for: WatchEventTarget.self) { ziel in
                    if let horse = horses.first(where: { $0.id == ziel.horseID }) {
                        if let eventType = ziel.eventType {
                            WatchTermineView(horse: horse, start: eventType)
                        } else {
                            WatchUebersichtView(horse: horse)
                                .navigationTitle(horse.name)
                        }
                    }
                }
                .onAppear {
                    #if DEBUG
                    // "-demoDetail" oeffnet die Uebersicht, "-demoTermin"
                    // springt direkt auf die Hufschmied-Seite - beide Wege
                    // lassen sich so im Simulator ansehen, auch ohne iPhone.
                    let args = ProcessInfo.processInfo.arguments
                    let demoUebersicht = args.contains("-demoDetail")
                    let demoTermin = args.contains("-demoTermin")
                    // "-demoClassic" schaltet auf Classic, "-demoStil" oeffnet
                    // die Stil-Seite - lange druecken geht im Simulator nicht
                    if args.contains("-demoClassic") { WatchStil.shared.darstellung = .classic }
                    if args.contains("-demoGlas") { WatchStil.shared.darstellung = .glas }
                    if args.contains("-demoStil") {
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) { zeigeStil = true }
                    }
                    if demoUebersicht || demoTermin, let horse = horses.first, pfad.isEmpty {
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
                            if demoTermin {
                                oeffneTermin(.hufschmied, von: horse)
                            } else {
                                pfad.append(WatchEventTarget(horseID: horse.id, eventType: nil))
                            }
                        }
                    }
                    #endif
                }
            }
        }
        .task { seedDemoHorseIfRequested() }
    }

    /// A flower in the list jumps straight to its date, but puts the horse's
    /// overview underneath - so "back" always leads to the overview, the same
    /// as when you come from there.
    private func oeffneTermin(_ eventType: Horse.EventType, von horse: Horse) {
        pfad.append(WatchEventTarget(horseID: horse.id, eventType: nil))
        pfad.append(WatchEventTarget(horseID: horse.id, eventType: eventType))
    }

    /// Debug-Hilfe fuer den Simulator, wie auf dem iPhone: Start mit
    /// "-demoHorse" legt ein Demo-Pferd an, "-demoDaysAgo 30,120,10" setzt
    /// die Tage seit Hufschmied, Impfung, Wurmkur. Auf der Uhr gibt es
    /// sonst keinen Weg, Daten ohne iPhone hineinzubekommen. Laeuft ueber
    /// den Kontext der Ansicht, damit die Abfrage die Aenderung sofort sieht.
    private func seedDemoHorseIfRequested() {
        #if DEBUG
        let args = ProcessInfo.processInfo.arguments
        guard args.contains("-demoHorse") else { return }
        var daysAgo = [30, 120, 10]
        if let spec = UserDefaults.standard.string(forKey: "demoDaysAgo") {
            let parsed = spec.split(separator: ",").compactMap { Int($0.trimmingCharacters(in: .whitespaces)) }
            if parsed.count == 3 { daysAgo = parsed }
        }
        let today = Date()
        let dates = daysAgo.map { Calendar.current.date(byAdding: .day, value: -$0, to: today) ?? today }
        let horse: Horse
        if let existing = horses.first(where: { $0.name == "Demo" }) {
            horse = existing
        } else {
            horse = Horse(name: "Demo")
            modelContext.insert(horse)
        }
        horse.letzterHufschmiedTermin = dates[0]
        horse.letzterImpfungTermin = dates[1]
        horse.letzterWurmkurTermin = dates[2]
        do { try modelContext.save(); NSLog("Demo-Seed: gespeichert, Pferde jetzt %d", (try? modelContext.fetchCount(FetchDescriptor<Horse>())) ?? -1) } catch { NSLog("Demo-Seed: Fehler %@", "\(error)") }
        #endif
    }
}

// MARK: - Pferde-Zeile (Watch)

struct WatchHorseRow: View {
    let horse: Horse
    @ObservedObject private var stil = WatchStil.shared
    /// Tapping a flower: open that date (with the overview beneath it)
    var oeffneTermin: (Horse.EventType) -> Void

    private var nextEvent: (type: Horse.EventType, days: Int) {
        let events: [(Horse.EventType, Int)] = [
            (.hufschmied, horse.tageBisHufschmied),
            (.impfung, horse.tageBisImpfung),
            (.wurmkur, horse.tageBisWurmkur)
        ]
        return events.min(by: { $0.1 < $1.1 }).map { (type: $0.0, days: $0.1) } ?? (.hufschmied, 0)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            // Name und naechster Termin fuehren zum dringendsten Termin
            // Der Name fuehrt auf die Uebersicht - von dort blaettert man
            // nach unten durch die drei Termine. Vorher ging er direkt zum
            // dringendsten, was einen oft am Ende des Stapels absetzte.
            NavigationLink(value: WatchEventTarget(horseID: horse.id, eventType: nil)) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(horse.name)
                        .font(.headline)

                    HStack(spacing: 5) {
                        // Eigene Symbole wie auf dem iPhone; Template-Assets brauchen
                        // eine ausdrueckliche Farbe, sonst erscheinen sie in Akzentfarbe
                        Image(nextEvent.type.symbol)
                            .resizable()
                            .scaledToFit()
                            .frame(width: 13, height: 13)
                            .foregroundStyle(WatchFarbe.schrift(tage: nextEvent.days))

                        Text(WatchWortlaut.naechster(nextEvent.type, tage: nextEvent.days))
                            .font(.caption2)
                            .foregroundColor(WatchFarbe.schrift(tage: nextEvent.days))
                    }
                }
            }
            .buttonStyle(.plain)

            // Mini-Blumen statt Ampelpunkten: zeigen auch, wie weit das
            // Intervall schon gelaufen ist. 30 pt ist die Untergrenze, ab
            // der sich die zwoelf Blaetter noch zaehlen lassen (CLAUDE.md).
            // Jede Blume fuehrt direkt zu ihrem Termin. Die drei teilen sich
            // die Zeilenbreite, statt links zu kleben - auf der Ultra blieb
            // sonst die halbe Zeile leer.
            HStack(spacing: 0) {
                ForEach(Horse.EventType.allCases, id: \.self) { eventType in
                    let days = horse.tageBis(fuer: eventType)
                    Button {
                        oeffneTermin(eventType)
                    } label: {
                        VStack(spacing: 2) {
                            Image(eventType.symbol)
                                .resizable()
                                .scaledToFit()
                                .frame(width: 9, height: 9)
                                .foregroundStyle(stil.darstellung == .classic
                                                 ? AnyShapeStyle(LCDPalette.on) : AnyShapeStyle(.secondary))
                            WatchStilBlume(
                                filledPetals: FlowerGeometry.filledPetals(
                                    remainingDays: days,
                                    interval: horse.holeIntervall(fuer: eventType)
                                ),
                                isExpired: days <= 0,
                                symbol: eventType.symbol,
                                tint: stil.farbe(fuer: horse.id),
                                size: WatchMass.listenBlume,
                                mitSymbol: false,
                                eigenesFenster: false
                            )
                        }
                        .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.plain)
                }
            }
            // Classic: alle drei Rosen auf einem Display
            .lcdFlaeche(stil.darstellung == .classic)
            .padding(.top, 2)
        }
        .padding(.vertical, 2)
    }
}

/// Die Farbregel der Uhr, einmal - fuer Liste, Uebersicht und Terminseite.
///
/// Vorher trug jede Seite ihre eigene: Ampelblumen (gruen, orange, rot) in
/// Liste und Uebersicht, die Glasfarbe auf der Terminseite, dazu gruene und
/// orange Schrift. Mathias am 22.11.2026: "ein grosses Farbdurcheinander".
///
/// Jetzt: Die Blume hat immer die Glasfarbe vom iPhone. Schrift ist weiss.
/// Farbe bekommt nur, was draengt - orange ab 14 Tagen, rot ab 7 - und rot
/// wird die Blume erst, wenn der Termin wirklich abgelaufen ist (dann
/// erscheint auch der Punkt in der Mitte, wie am Geraet).
enum WatchFarbe {
    static func schrift(tage: Int) -> Color {
        if tage <= 7 { return .red }
        if tage <= 14 { return .orange }
        return .primary
    }

}

/// Masse, die der Uhrengroesse folgen. Feste Punktwerte passten auf die
/// 41 mm und standen auf der Ultra verloren in der Flaeche. Bezug ist die
/// 41-mm-Uhr mit 176 pt Breite; alles auf ganze Punkte, sonst driftet der
/// Blattkranz (CLAUDE.md).
enum WatchMass {
    static let breite: CGFloat = WKInterfaceDevice.current().screenBounds.width
    static let faktor: CGFloat = breite / 176

    /// Drei Blumen nebeneinander ueber die Breite der Uebersicht. Der Rand
    /// bleibt frei, weil rechts die Seitenpunkte des Stapels sitzen.
    static let uebersichtBlume: CGFloat = ((breite - 34) / 3).rounded(.down)
    /// Kleine Blume in der Pferdeliste; 30 pt ist die Untergrenze
    static let listenBlume: CGFloat = (34 * faktor).rounded()
    /// Grosse Glasblume der Terminseite; gedeckelt, damit die Resttage
    /// darunter ohne Blaettern sichtbar bleiben
    static let terminBlume: CGFloat = (104 * min(faktor, 1.1)).rounded()

    static func schrift(_ punkt: CGFloat) -> CGFloat { (punkt * faktor).rounded() }
}

// MARK: - Detail-Ansicht (Watch)

/// Ziel eines Tipps in der Liste: dieses Pferd, dieser Termin
struct WatchEventTarget: Hashable {
    let horseID: UUID
    /// Welcher Termin gemeint ist - `nil` heisst: die Uebersicht zuerst
    let eventType: Horse.EventType?
}

/// Wie ein Pferd auf der Uhr aufgebaut ist, seit 25.11.2026:
///
///     Liste -> Uebersicht -> Terminseite
///
/// Jede Stufe ist eine eigene Seite, "zurueck" fuehrt immer eine Stufe
/// hoch. Vorher lagen Uebersicht und die drei Termine als Stapel uebereinander
/// (mit der Krone zu blaettern). Mathias kam von einer Terminseite nicht
/// direkt zurueck, sondern musste durch alle Termine scrollen. Die Blumen in
/// der Liste springen weiter direkt auf ihren Termin, legen aber die
/// Uebersicht darunter - zurueck landet man also auch dort.

// MARK: - Uebersichtsseite (Watch)

/// Alle drei Termine eines Pferdes nebeneinander, so wie in der Liste, nur
/// groesser. Ein Tipp auf eine Blume oeffnet ihre Seite.
struct WatchUebersichtView: View {
    let horse: Horse
    @ObservedObject private var stil = WatchStil.shared
    /// Langer Druck: Farbe nur fuer dieses Pferd
    @State private var zeigeFarbe = false

    private var dringendster: (type: Horse.EventType, days: Int) {
        let events = Horse.EventType.allCases.map { ($0, horse.tageBis(fuer: $0)) }
        return events.min(by: { $0.1 < $1.1 }).map { (type: $0.0, days: $0.1) } ?? (.hufschmied, 0)
    }

    var body: some View {
        VStack(spacing: WatchMass.schrift(8)) {
            Text(WatchWortlaut.naechster(dringendster.type, tage: dringendster.days))
                .font(.system(size: WatchMass.schrift(14), weight: .semibold))
                .foregroundColor(WatchFarbe.schrift(tage: dringendster.days))
                .multilineTextAlignment(.center)
                .lineLimit(2)
                .minimumScaleFactor(0.85)
                .padding(.horizontal, 8)

            // Dieselbe Glasblume wie auf der Terminseite, nur kleiner: das
            // Symbol sitzt in der Mitte, die Farbe ist die Glasfarbe.
            HStack(spacing: 5) {
                ForEach(Horse.EventType.allCases, id: \.self) { eventType in
                    let tage = horse.tageBis(fuer: eventType)
                    NavigationLink(value: WatchEventTarget(horseID: horse.id, eventType: eventType)) {
                        VStack(spacing: 4) {
                            WatchStilBlume(
                                filledPetals: FlowerGeometry.filledPetals(
                                    remainingDays: tage,
                                    interval: horse.holeIntervall(fuer: eventType)
                                ),
                                isExpired: tage <= 0,
                                symbol: eventType.symbol,
                                tint: stil.farbe(fuer: horse.id),
                                size: stil.darstellung == .classic
                                    ? WatchMass.uebersichtBlume - 8 : WatchMass.uebersichtBlume,
                                eigenesFenster: false
                            )
                            // Classic ist einfarbig wie das Geraet; die farbige
                            // Ueberschrift darueber traegt die Dringlichkeit
                            Text(WatchWortlaut.kurz(tage: tage))
                                .font(.system(size: WatchMass.schrift(12), weight: .medium))
                                .foregroundColor(stil.darstellung == .classic
                                                 ? LCDPalette.on : WatchFarbe.schrift(tage: tage))
                                .lineLimit(1)
                                .minimumScaleFactor(0.7)
                                .frame(width: WatchMass.uebersichtBlume)
                                // sonst schrumpft die Schrift, sobald die
                                // Ueberschrift zweizeilig wird
                                .fixedSize(horizontal: false, vertical: true)
                        }
                    }
                    .buttonStyle(.plain)
                }
            }
            .lcdFlaeche(stil.darstellung == .classic)

            Text(stil.darstellung == .glas ? "Antippen · lange drücken: Farbe" : "Blume antippen")
                .font(.system(size: WatchMass.schrift(10)))
                .foregroundColor(.secondary)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .contentShape(Rectangle())
        // Classic ist einfarbig, da gibt es keine Farbe je Pferd
        .simultaneousGesture(
            LongPressGesture(minimumDuration: 0.6).onEnded { _ in
                if stil.darstellung == .glas { zeigeFarbe = true }
            }
        )
        .sheet(isPresented: $zeigeFarbe) {
            NavigationStack { WatchStilView(pferd: horse) }
        }
        .onAppear {
            #if DEBUG
            if ProcessInfo.processInfo.arguments.contains("-demoPferdFarbe") {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) { zeigeFarbe = true }
            }
            #endif
        }
    }
}

// MARK: - Terminseiten (Watch)

/// Die drei Termine eines Pferdes nebeneinander: nach links und rechts
/// wischen wechselt den Termin, "zurueck" fuehrt zur Uebersicht.
/// Mathias, 25.11.2026: lieber wischen als scrollen.
struct WatchTermineView: View {
    let horse: Horse
    @State private var seite: Horse.EventType

    init(horse: Horse, start: Horse.EventType) {
        self.horse = horse
        _seite = State(initialValue: start)
    }

    var body: some View {
        TabView(selection: $seite) {
            ForEach(Horse.EventType.allCases, id: \.self) { eventType in
                WatchEventView(horse: horse, eventType: eventType)
                    .tag(eventType)
            }
        }
        .tabViewStyle(.page)
        .navigationTitle(horse.name)
    }
}

/// Eine Seite fuer einen Termin. Oben, so gross es geht: die Blume und die
/// Resttage. Mit der Krone nach unten: "War heute da" und die Wiederholung.
///
/// Verlauf: Bis 25.11. 20 Uhr hingen alle Tasten unter der Blume, die Seite
/// scrollte ohne klare Grenze. Dann kurz alles auf einen Bildschirm, mit
/// eigener Intervallseite - dafuer schrumpfte die Blume auf der 41 mm auf
/// 56 pt. Mathias danach: Blume wieder gross, Einstellungen darunter mit
/// der Krone. Die Blume hat wieder 104 pt (41 mm); auf der 41 mm fuellt der
/// erste Teil den Bildschirm, "War heute da" kommt erst mit der Krone.
struct WatchEventView: View {
    let horse: Horse
    let eventType: Horse.EventType
    @ObservedObject private var stil = WatchStil.shared

    @State private var gemeldet = false

    private var days: Int { horse.tageBis(fuer: eventType) }
    private var interval: Int { horse.holeIntervall(fuer: eventType) }

    var body: some View {
        ScrollViewReader { proxy in
        ScrollView {
            VStack(spacing: 10) {
                // Erster Bildschirm
                VStack(spacing: 4) {
                    HStack(spacing: 5) {
                        Image(eventType.symbol)
                            .resizable()
                            .scaledToFit()
                            .frame(width: 13, height: 13)
                            .foregroundStyle(.secondary)
                        Text(eventType.localizedName)
                            .font(.caption.bold())
                            .lineLimit(1)
                            .minimumScaleFactor(0.8)
                    }

                    WatchStilBlume(
                        filledPetals: FlowerGeometry.filledPetals(remainingDays: days, interval: interval),
                        isExpired: days <= 0,
                        symbol: eventType.symbol,
                        tint: stil.farbe(fuer: horse.id),
                        size: WatchMass.terminBlume
                    )

                    Text(WatchWortlaut.rest(tage: days))
                        .font(.system(size: WatchMass.schrift(16), weight: .semibold))
                        .foregroundColor(WatchFarbe.schrift(tage: days))
                        .lineLimit(1)
                        .minimumScaleFactor(0.8)
                }
                .padding(.bottom, 6)

                // Darunter, mit der Krone erreichbar
                // Im Stall hat man die Uhr am Arm und das iPhone in der
                // Tasche - darum laesst sich der Termin hier abhaken.
                Button {
                    erledigt()
                } label: {
                    Label(gemeldet ? "Eingetragen" : "War heute da",
                          systemImage: gemeldet ? "checkmark.circle.fill" : "checkmark")
                        .font(.system(size: 14, weight: .semibold))
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)
                .tint(gemeldet ? .green : stil.farbe(fuer: horse.id))
                .disabled(gemeldet)

                VStack(spacing: 4) {
                    Text("Wiederholung")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundColor(.secondary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    HStack(spacing: 8) {
                        WatchGlassKey(symbol: "minus", tint: stil.farbe(fuer: horse.id)) {
                            setzeIntervall(interval - 1)
                        }
                        VStack(spacing: 0) {
                            Text("\(interval)")
                                .font(.system(size: 18, weight: .semibold))
                                .monospacedDigit()
                            Text("Tage")
                                .font(.system(size: 9))
                                .foregroundColor(.secondary)
                        }
                        .frame(minWidth: 48)
                        WatchGlassKey(symbol: "plus", tint: stil.farbe(fuer: horse.id)) {
                            setzeIntervall(interval + 1)
                        }
                    }
                }
                .padding(.top, 4)
                .id("unten")
            }
            .padding(.horizontal, 6)
            .padding(.bottom, 14) // Platz fuer die Seitenpunkte
        }
        .onAppear {
            #if DEBUG
            // "-demoScroll": den unteren Teil im Simulator ansehen
            if ProcessInfo.processInfo.arguments.contains("-demoScroll") {
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) {
                    proxy.scrollTo("unten", anchor: .bottom)
                }
            }
            #endif
        }
        }
        // Ein Intervall, das noch in der Wartezeit steckt, geht beim
        // Verlassen sofort raus - sonst ueberschriebe das iPhone es wieder
        .onDisappear { WatchSyncReceiver.shared.meldeOffenesIntervall() }
    }

    /// Traegt den Termin sofort lokal ein, damit die Uhr nicht auf das
    /// iPhone warten muss, und meldet ihn dorthin.
    private func erledigt() {
        let jetzt = Date()
        horse.setzeTermin(jetzt, fuer: eventType)
        WatchSyncReceiver.shared.meldeTerminErledigt(horseID: horse.id, eventType: eventType, datum: jetzt)
        withAnimation { gemeldet = true }
    }

    private func setzeIntervall(_ neu: Int) {
        let wert = min(999, max(1, neu))
        horse.setzeIntervall(wert, fuer: eventType)
        WatchSyncReceiver.shared.meldeIntervall(horseID: horse.id, eventType: eventType, intervall: wert)
    }
}

// MARK: - Wortlaut

/// Ganze Woerter mit Umlauten statt "12d" und "ueberfaellig" - auf der Uhr
/// ist Platz dafuer, und so liest es sich wie auf dem iPhone.
enum WatchWortlaut {
    static func naechster(_ typ: Horse.EventType, tage: Int) -> String {
        if tage < 0 { return "\(typ.localizedName) \(-tage) Tage überfällig" }
        if tage == 0 { return "\(typ.localizedName) heute!" }
        if tage == 1 { return "\(typ.localizedName) morgen" }
        return "\(typ.localizedName) in \(tage) Tagen"
    }

    /// Platzsparend fuer die Uebersicht, wo drei nebeneinander stehen
    static func kurz(tage: Int) -> String {
        if tage < 0 { return "\(-tage) T. über" }
        if tage == 0 { return "heute" }
        return "\(tage) T."
    }

    static func rest(tage: Int) -> String {
        if tage < -1 { return "\(-tage) Tage überfällig" }
        if tage == -1 { return "seit gestern fällig" }
        if tage == 0 { return "heute fällig" }
        if tage == 1 { return "morgen" }
        return "in \(tage) Tagen"
    }
}
