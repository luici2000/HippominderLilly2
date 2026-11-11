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

struct WatchContentView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var horses: [Horse]
    @ObservedObject var syncReceiver = WatchSyncReceiver.shared
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
                        WatchHorseRow(horse: horse)
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
                        }
                        .font(.system(size: 9))
                        .foregroundColor(.secondary)
                        .frame(maxWidth: .infinity)
                    }
                    .listRowBackground(Color.clear)
                }
                .navigationTitle("Hippominder")
                .navigationDestination(for: WatchEventTarget.self) { ziel in
                    if let horse = horses.first(where: { $0.id == ziel.horseID }) {
                        WatchHorseDetailView(horse: horse, start: ziel.eventType)
                    }
                }
                .onAppear {
                    #if DEBUG
                    if ProcessInfo.processInfo.arguments.contains("-demoDetail"), let horse = horses.first, pfad.isEmpty {
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
                            pfad.append(WatchEventTarget(horseID: horse.id, eventType: .hufschmied))
                        }
                    }
                    #endif
                }
            }
        }
        .task { seedDemoHorseIfRequested() }
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
            NavigationLink(value: WatchEventTarget(horseID: horse.id, eventType: nextEvent.type)) {
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
                            .foregroundStyle(colorForDays(nextEvent.days))

                        Text(WatchWortlaut.naechster(nextEvent.type, tage: nextEvent.days))
                            .font(.caption2)
                            .foregroundColor(colorForDays(nextEvent.days))
                    }
                }
            }
            .buttonStyle(.plain)

            // Mini-Blumen statt Ampelpunkten: zeigen auch, wie weit das
            // Intervall schon gelaufen ist. 30 pt ist die Untergrenze, ab
            // der sich die zwoelf Blaetter noch zaehlen lassen (CLAUDE.md).
            // Jede Blume fuehrt direkt zu ihrem Termin.
            HStack(spacing: 10) {
                ForEach(Horse.EventType.allCases, id: \.self) { eventType in
                    let days = horse.tageBis(fuer: eventType)
                    NavigationLink(value: WatchEventTarget(horseID: horse.id, eventType: eventType)) {
                        VStack(spacing: 2) {
                            Image(eventType.symbol)
                                .resizable()
                                .scaledToFit()
                                .frame(width: 9, height: 9)
                                .foregroundStyle(.secondary)
                            WatchFlower(
                                filledPetals: FlowerGeometry.filledPetals(
                                    remainingDays: days,
                                    interval: horse.holeIntervall(fuer: eventType)
                                ),
                                isExpired: days <= 0,
                                color: colorForDays(days),
                                size: 30
                            )
                        }
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.top, 2)
        }
        .padding(.vertical, 2)
    }

    private func colorForDays(_ days: Int) -> Color {
        if days <= 0 { return .red }
        if days <= 7 { return .red }
        if days <= 14 { return .orange }
        return .green
    }
}

// MARK: - Detail-Ansicht (Watch)

/// Ziel eines Tipps in der Liste: dieses Pferd, dieser Termin
struct WatchEventTarget: Hashable {
    let horseID: UUID
    let eventType: Horse.EventType
}

/// Die drei Termine eines Pferdes als Seiten untereinander - Krone oder
/// Wischen wechselt von Hufschmied zu Impfung zu Wurmkur. Ein Tipp auf eine
/// Blume in der Liste landet direkt auf der passenden Seite.
struct WatchHorseDetailView: View {
    let horse: Horse
    let start: Horse.EventType
    @State private var seite: Horse.EventType

    init(horse: Horse, start: Horse.EventType) {
        self.horse = horse
        self.start = start
        _seite = State(initialValue: start)
    }

    var body: some View {
        TabView(selection: $seite) {
            ForEach(Horse.EventType.allCases, id: \.self) { eventType in
                WatchEventView(horse: horse, eventType: eventType)
                    .tag(eventType)
            }
        }
        .tabViewStyle(.verticalPage)
        .navigationTitle(horse.name)
    }
}

// MARK: - Terminseite (Watch)

/// Eine Seite fuer einen Termin: Glasblume, Resttage, "War heute da",
/// Intervall mit Glastasten. Das ist die Seite, auf der man im Stall landet.
struct WatchEventView: View {
    let horse: Horse
    let eventType: Horse.EventType

    @State private var gemeldet = false

    private var days: Int { horse.tageBis(fuer: eventType) }
    private var interval: Int { horse.holeIntervall(fuer: eventType) }

    private var statusColor: Color {
        if days <= 7 { return .red }
        if days <= 14 { return .orange }
        return .green
    }

    var body: some View {
        ScrollViewReader { proxy in
        ScrollView {
            VStack(spacing: 6) {
                HStack(spacing: 5) {
                    Image(eventType.symbol)
                        .resizable()
                        .scaledToFit()
                        .frame(width: 14, height: 14)
                        .foregroundStyle(.secondary)
                    Text(eventType.localizedName)
                        .font(.caption.bold())
                        .lineLimit(1)
                        .minimumScaleFactor(0.8)
                }

                WatchGlassFlower(
                    filledPetals: FlowerGeometry.filledPetals(remainingDays: days, interval: interval),
                    isExpired: days <= 0,
                    symbol: eventType.symbol,
                    size: 104
                )
                .padding(.vertical, 2)

                Text(WatchWortlaut.rest(tage: days))
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(statusColor)

                // Im Stall hat man die Uhr am Arm und das iPhone in der Tasche -
                // darum laesst sich der Termin hier direkt abhaken.
                Button {
                    erledigt()
                } label: {
                    Label(gemeldet ? "Eingetragen" : "War heute da",
                          systemImage: gemeldet ? "checkmark.circle.fill" : "checkmark")
                        .font(.system(size: 12, weight: .semibold))
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)
                .tint(gemeldet ? .green : WatchGlas.tint)
                .disabled(gemeldet)
                .padding(.top, 4)

                // Intervall mit Minus und Plus, wie die Tasten am iPhone
                HStack(spacing: 8) {
                    WatchGlassKey(symbol: "minus") { setzeIntervall(interval - 1) }
                    VStack(spacing: 0) {
                        Text("\(interval)")
                            .font(.system(size: 17, weight: .semibold))
                            .monospacedDigit()
                        Text("Tage")
                            .font(.system(size: 9))
                            .foregroundColor(.secondary)
                    }
                    .frame(minWidth: 44)
                    WatchGlassKey(symbol: "plus") { setzeIntervall(interval + 1) }
                }
                .padding(.top, 6)
                .id("unten")
            }
            .padding(.horizontal, 4)
            .padding(.bottom, 8)
        }
        .onAppear {
            #if DEBUG
            // "-demoScroll": zum Pruefen des unteren Teils im Simulator
            if ProcessInfo.processInfo.arguments.contains("-demoScroll") {
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) { proxy.scrollTo("unten", anchor: .bottom) }
            }
            #endif
        }
        // Ein Intervall, das noch in der Wartezeit steckt, geht beim
        // Verlassen sofort raus - sonst ueberschriebe das iPhone es wieder
        .onDisappear { WatchSyncReceiver.shared.meldeOffenesIntervall() }
        }
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
        let wert = max(1, neu)
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

    static func rest(tage: Int) -> String {
        if tage < -1 { return "\(-tage) Tage überfällig" }
        if tage == -1 { return "seit gestern fällig" }
        if tage == 0 { return "heute fällig" }
        if tage == 1 { return "morgen" }
        return "in \(tage) Tagen"
    }
}
