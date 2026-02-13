//
//  MacContentView.swift
//  Hippominder
//
//  Autor: Mathias Hubrich & Claude (Anthropic)
//  Erstellt: 13. Februar 2026
//  Version: 1.0.0
//
//  Beschreibung: macOS-spezifische Hauptansicht mit Sidebar-Navigation
//  Fenstergroesse ist begrenzt (nicht endlos vergroesserbar)
//

#if os(macOS)
import SwiftUI
import SwiftData

struct MacContentView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var horses: [Horse]
    @ObservedObject var globalSettings = GlobalSettings.shared
    @ObservedObject var storeManager = StoreManager.shared

    @State private var selectedHorse: Horse?
    @State private var showingAddHorse = false
    @State private var showingContacts = false

    var body: some View {
        NavigationSplitView {
            // Sidebar: Pferdeliste
            VStack(spacing: 0) {
                // Header
                HStack {
                    Image("hippominder_logo")
                        .resizable()
                        .scaledToFit()
                        .frame(height: 32)

                    Spacer()

                    // Farbschema
                    HStack(spacing: 6) {
                        ForEach(FlowerColorScheme.allCases) { scheme in
                            Button(action: {
                                withAnimation(.easeInOut(duration: 0.2)) {
                                    globalSettings.flowerColorScheme = scheme
                                }
                            }) {
                                Circle()
                                    .fill(scheme.strongColor)
                                    .frame(width: globalSettings.flowerColorScheme == scheme ? 14 : 10,
                                           height: globalSettings.flowerColorScheme == scheme ? 14 : 10)
                                    .opacity(globalSettings.flowerColorScheme == scheme ? 1.0 : 0.4)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 8)

                Divider()

                if horses.isEmpty {
                    VStack(spacing: 12) {
                        Spacer()
                        Image(systemName: "hare")
                            .font(.system(size: 40))
                            .foregroundColor(.gray.opacity(0.3))
                        Text("Noch keine Pferde")
                            .font(.headline)
                            .foregroundColor(.gray)
                        Button("Pferd hinzufügen") {
                            showingAddHorse = true
                        }
                        Spacer()
                    }
                    .frame(maxWidth: .infinity)
                } else {
                    List(horses, selection: $selectedHorse) { horse in
                        MacHorseRow(horse: horse)
                            .tag(horse)
                    }
                    .listStyle(.sidebar)
                }
            }
            .navigationSplitViewColumnWidth(min: 220, ideal: 260, max: 320)
            .toolbar {
                ToolbarItem(placement: .automatic) {
                    Button(action: { showingContacts = true }) {
                        Label("Kontakte", systemImage: "person.2.fill")
                    }
                }
                ToolbarItem(placement: .automatic) {
                    Button(action: {
                        if storeManager.canAddHorse(currentCount: horses.count) {
                            showingAddHorse = true
                        }
                    }) {
                        Label("Pferd hinzufügen", systemImage: "plus")
                    }
                }
            }
        } detail: {
            // Detail: Ausgewaehltes Pferd
            if let horse = selectedHorse {
                MacHorseDetailView(horse: horse)
            } else {
                VStack(spacing: 12) {
                    Image("hippominder_logo")
                        .resizable()
                        .scaledToFit()
                        .frame(height: 60)
                        .opacity(0.3)
                    Text("Wähle ein Pferd aus der Liste")
                        .font(.title3)
                        .foregroundColor(.secondary)
                }
            }
        }
        .sheet(isPresented: $showingAddHorse) {
            MacAddHorseView()
                .frame(width: 400, height: 350)
        }
        .sheet(isPresented: $showingContacts) {
            ContactsView()
                .frame(width: 500, height: 450)
        }
    }
}

// MARK: - Pferde-Zeile (Mac)

struct MacHorseRow: View {
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
        HStack(spacing: 10) {
            // Pferdebild
            if let image = horse.image {
                image
                    .resizable()
                    .scaledToFill()
                    .frame(width: 36, height: 36)
                    .clipShape(Circle())
            } else {
                Circle()
                    .fill(Color.gray.opacity(0.15))
                    .frame(width: 36, height: 36)
                    .overlay(
                        Image(systemName: "hare")
                            .font(.system(size: 16))
                            .foregroundColor(.gray.opacity(0.4))
                    )
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(horse.name)
                    .font(.body.bold())

                HStack(spacing: 3) {
                    Image(systemName: nextEvent.type.systemSymbol)
                        .font(.system(size: 9))
                    Text(nextEvent.days <= 0 ? "\(-nextEvent.days)d ueber" : "in \(nextEvent.days)d")
                        .font(.caption)
                }
                .foregroundColor(colorForDays(nextEvent.days))
            }

            Spacer()

            // Status-Punkte
            HStack(spacing: 4) {
                ForEach(Horse.EventType.allCases, id: \.self) { eventType in
                    Circle()
                        .fill(colorForDays(horse.tageBis(fuer: eventType)))
                        .frame(width: 7, height: 7)
                }
            }
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

// MARK: - Detail-Ansicht (Mac)

struct MacHorseDetailView: View {
    @Bindable var horse: Horse
    @ObservedObject var globalSettings = GlobalSettings.shared

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Pferdename + Bild
                HStack(spacing: 16) {
                    if let image = horse.image {
                        image
                            .resizable()
                            .scaledToFill()
                            .frame(width: 80, height: 80)
                            .clipShape(Circle())
                    } else {
                        Circle()
                            .fill(Color.gray.opacity(0.1))
                            .frame(width: 80, height: 80)
                            .overlay(
                                Image(systemName: "hare")
                                    .font(.title)
                                    .foregroundColor(.gray.opacity(0.3))
                            )
                    }

                    VStack(alignment: .leading, spacing: 4) {
                        Text(horse.name)
                            .font(.largeTitle.bold())

                        Text("Erinnerung \(horse.benachrichtigungTageVorher) Tage vorher")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }

                    Spacer()
                }
                .padding(.horizontal, 24)

                Divider()

                // Timer-Karten
                HStack(alignment: .top, spacing: 16) {
                    ForEach(Horse.EventType.allCases, id: \.self) { eventType in
                        MacTimerCard(
                            horse: horse,
                            eventType: eventType,
                            colorScheme: globalSettings.flowerColorScheme
                        )
                    }
                }
                .padding(.horizontal, 24)

                Divider()

                // Intervall-Einstellungen
                VStack(alignment: .leading, spacing: 12) {
                    Text("Intervalle")
                        .font(.headline)

                    ForEach(Horse.EventType.allCases, id: \.self) { eventType in
                        HStack {
                            Image(systemName: eventType.systemSymbol)
                                .frame(width: 20)
                                .foregroundColor(.secondary)
                            Text(eventType.localizedName)
                                .frame(width: 100, alignment: .leading)

                            Stepper(
                                "\(horse.holeIntervall(fuer: eventType)) Tage",
                                value: Binding(
                                    get: { horse.holeIntervall(fuer: eventType) },
                                    set: { horse.setzeIntervall(max(1, $0), fuer: eventType) }
                                ),
                                in: 1...365
                            )
                        }
                    }
                }
                .padding(.horizontal, 24)

                Spacer(minLength: 20)
            }
            .padding(.top, 16)
        }
        .frame(minWidth: 400)
    }
}

// MARK: - Timer-Karte (Mac)

struct MacTimerCard: View {
    let horse: Horse
    let eventType: Horse.EventType
    let colorScheme: FlowerColorScheme

    private var days: Int { horse.tageBis(fuer: eventType) }
    private var interval: Int { horse.holeIntervall(fuer: eventType) }

    private var progress: Double {
        if days <= 0 { return 1.0 }
        return 1.0 - (Double(days) / Double(interval))
    }

    private var statusColor: Color {
        if days <= 0 { return .red }
        if days <= 7 { return .red }
        if days <= 14 { return .orange }
        return .green
    }

    private static let dateFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "dd.MM.yyyy"
        return f
    }()

    var body: some View {
        VStack(spacing: 10) {
            // Blumen-Bild (aus Assets)
            Image(flowerImageName())
                .resizable()
                .scaledToFit()
                .frame(width: 80, height: 80)

            Image(systemName: eventType.systemSymbol)
                .font(.title3)
                .foregroundColor(statusColor)

            Text(eventType.localizedName)
                .font(.caption.bold())

            Text(days <= 0 ? "\(-days) Tage ueberfaellig" : "in \(days) Tagen")
                .font(.caption)
                .foregroundColor(statusColor)

            Text(Self.dateFormatter.string(from: horse.naechsterTermin(fuer: eventType)))
                .font(.caption2)
                .foregroundColor(.secondary)

            // Termin bestaetigen
            Button("War heute da") {
                horse.setzeTermin(DebugSettings.shared.simulatedDate, fuer: eventType)
            }
            .buttonStyle(.bordered)
            .controlSize(.small)
        }
        .padding(12)
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.gray.opacity(0.06))
        )
    }

    private func flowerImageName() -> String {
        let filledPetals = horse.gefuellteBlätter(fuer: eventType)
        let base: String
        if filledPetals >= 12 {
            base = "12d"
        } else {
            base = "\(filledPetals)"
        }
        switch colorScheme {
        case .grau: return "flower_\(base)"
        case .hellblau: return "flower_\(base)_hellblau"
        case .orange: return "flower_\(base)_orange"
        }
    }
}

// MARK: - Pferd hinzufuegen (Mac)

struct MacAddHorseView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    @State private var name = ""
    @State private var hufschmiedIntervall = 42
    @State private var impfungIntervall = 180
    @State private var wurmkurIntervall = 90

    var body: some View {
        VStack(spacing: 16) {
            Text("Neues Pferd")
                .font(.title2.bold())

            TextField("Pferdename", text: $name)
                .textFieldStyle(.roundedBorder)
                .padding(.horizontal)

            GroupBox("Intervalle (Tage)") {
                VStack(spacing: 8) {
                    Stepper("Hufschmied: \(hufschmiedIntervall)", value: $hufschmiedIntervall, in: 1...365)
                    Stepper("Impfung: \(impfungIntervall)", value: $impfungIntervall, in: 1...365)
                    Stepper("Wurmkur: \(wurmkurIntervall)", value: $wurmkurIntervall, in: 1...365)
                }
                .padding(4)
            }
            .padding(.horizontal)

            Spacer()

            HStack {
                Button("Abbrechen") { dismiss() }
                    .keyboardShortcut(.cancelAction)

                Spacer()

                Button("Speichern") { saveHorse() }
                    .keyboardShortcut(.defaultAction)
                    .disabled(name.isEmpty)
            }
            .padding(.horizontal)
            .padding(.bottom)
        }
        .padding(.top)
    }

    private func saveHorse() {
        let horse = Horse(
            name: name,
            hufschmiedIntervall: hufschmiedIntervall,
            impfungIntervall: impfungIntervall,
            wurmkurIntervall: wurmkurIntervall
        )
        modelContext.insert(horse)
        dismiss()
    }
}

#Preview {
    MacContentView()
        .modelContainer(for: Horse.self, inMemory: true)
}
#endif
