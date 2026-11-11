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
    /// Debug: Start mit "-demoDetail" springt direkt in die Detailansicht
    @State private var demoDetail = false

    var body: some View {
        NavigationStack {
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
                        NavigationLink(destination: WatchHorseDetailView(horse: horse)) {
                            WatchHorseRow(horse: horse)
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
                        }
                        .font(.system(size: 9))
                        .foregroundColor(.secondary)
                        .frame(maxWidth: .infinity)
                    }
                    .listRowBackground(Color.clear)
                }
                .navigationTitle("Hippominder")
                .navigationDestination(isPresented: $demoDetail) {
                    if let horse = horses.first {
                        WatchHorseDetailView(horse: horse)
                    }
                }
                .onAppear {
                    #if DEBUG
                    if ProcessInfo.processInfo.arguments.contains("-demoDetail") {
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) { demoDetail = true }
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

            // Mini-Blumen statt Ampelpunkten: zeigen auch, wie weit das
            // Intervall schon gelaufen ist. 30 pt ist die Untergrenze, ab
            // der sich die zwoelf Blaetter noch zaehlen lassen (CLAUDE.md).
            HStack(spacing: 10) {
                ForEach(Horse.EventType.allCases, id: \.self) { eventType in
                    let days = horse.tageBis(fuer: eventType)
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

struct WatchHorseDetailView: View {
    let horse: Horse

    var body: some View {
        ScrollView {
            VStack(spacing: 10) {
                // Der Name steht schon in der Titelzeile, darum hier nicht
                // noch einmal.

                // Timer fuer jeden Typ
                ForEach(Horse.EventType.allCases, id: \.self) { eventType in
                    WatchTimerCard(
                        eventType: eventType,
                        days: horse.tageBis(fuer: eventType),
                        interval: horse.holeIntervall(fuer: eventType),
                        horse: horse
                    )
                }
            }
            .padding(.horizontal, 4)
        }
        .navigationTitle(horse.name)
    }
}

// MARK: - Timer-Karte (Watch)

struct WatchTimerCard: View {
    let eventType: Horse.EventType
    let days: Int
    let interval: Int
    /// Fehlt in der Vorschau, dann wird nur angezeigt
    var horse: Horse? = nil

    @State private var gemeldet = false

    private var filledPetals: Int {
        FlowerGeometry.filledPetals(remainingDays: days, interval: interval)
    }

    private var statusColor: Color {
        if days <= 0 { return .red }
        if days <= 7 { return .red }
        if days <= 14 { return .orange }
        return .green
    }

    /// Traegt den Termin sofort lokal ein, damit die Uhr nicht auf das
    /// iPhone warten muss, und meldet ihn dorthin. Der naechste Sync vom
    /// iPhone bestaetigt denselben Stand.
    private func erledigt(_ horse: Horse) {
        let jetzt = Date()
        horse.setzeTermin(jetzt, fuer: eventType)
        WatchSyncReceiver.shared.meldeTerminErledigt(
            horseID: horse.id,
            eventType: eventType,
            datum: jetzt
        )
        withAnimation { gemeldet = true }
    }

    var body: some View {
        VStack(spacing: 6) {
            // Name oben, Blume in der Mitte, Resttage gross darunter - so
            // bricht auf der 41-mm-Uhr nichts um, und das Wichtigste steht
            // unter dem Bild, wie auf dem Geraet.
            HStack(spacing: 5) {
                Image(eventType.symbol)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 15, height: 15)
                    .foregroundStyle(statusColor)
                Text(eventType.localizedName)
                    .font(.caption.bold())
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
                Spacer(minLength: 0)
            }

            WatchFlower(
                filledPetals: filledPetals,
                isExpired: days <= 0,
                color: statusColor,
                size: 48
            )
            .padding(.vertical, 2)

            Text(WatchWortlaut.rest(tage: days))
                .font(.system(size: 15, weight: .semibold))
                .foregroundColor(statusColor)

            Text("Intervall \(interval) Tage")
                .font(.system(size: 9))
                .foregroundColor(.secondary)

            // Im Stall hat man die Uhr am Arm und das iPhone in der Tasche -
            // darum laesst sich der Termin hier direkt abhaken.
            if let horse {
                Button {
                    erledigt(horse)
                } label: {
                    Label(gemeldet ? "Eingetragen" : "War heute da",
                          systemImage: gemeldet ? "checkmark.circle.fill" : "checkmark")
                        .font(.system(size: 11, weight: .semibold))
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)
                .tint(gemeldet ? .green : .accentColor)
                .disabled(gemeldet)
                .padding(.top, 2)
            }
        }
        .padding(8)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(Color.gray.opacity(0.15))
        )
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
