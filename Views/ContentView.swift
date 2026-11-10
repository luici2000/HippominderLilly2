//
//  ContentView.swift
//  Hippominder
//
//  Autor: Mathias Hubrich & Claude (Anthropic)
//  Erstellt: 24. Januar 2026
//  Geaendert: 13. Februar 2026
//  Version: 1.9.0
//
//  Beschreibung: Hauptansicht mit Pferdeuebersicht (iOS)
//

import SwiftUI
import SwiftData

#if os(iOS)
import UIKit

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var horses: [Horse]
    @ObservedObject var debugSettings = DebugSettings.shared
    @ObservedObject var globalSettings = GlobalSettings.shared

    @ObservedObject var storeManager = StoreManager.shared

    @State private var showingAddHorse = false
    @State private var showingContacts = false
    @State private var showingPaywall = false
    @State private var showingBetaInfo = false
    @State private var logoTapCount = 0
    @State private var navigationPath = NavigationPath()
    @State private var demoSeeded = false
    @State private var notificationsDumped = false
    /// Auf dem iPad gewaehltes Pferd (zweispaltige Ansicht)
    @State private var ausgewaehltesPferd: Horse?

    var body: some View {
        Group {
            // Nach Geraetetyp, nicht nach Groessenklasse: ein iPhone Pro Max
            // meldet quer ebenfalls .regular und waere mitten im Betrieb auf
            // die geteilte Ansicht gesprungen - die offene Detailseite haette
            // sich beim Drehen geschlossen.
            if UIDevice.current.userInterfaceIdiom == .pad {
                geteilteAnsicht
            } else {
                stapelAnsicht
            }
        }
        .onAppear { seedDemoHorseIfRequested() }
        .sheet(isPresented: $showingAddHorse, onDismiss: {
            WatchSyncService.shared.syncToWatch()
        }) {
            AddHorseView()
        }
        .sheet(isPresented: $showingContacts) { ContactsView() }
        .sheet(isPresented: $showingPaywall) { PaywallView() }
        .sheet(isPresented: $showingBetaInfo) { BetaInfoView() }
    }

    // MARK: - iPhone: ein Stapel

    private var stapelAnsicht: some View {
        NavigationStack(path: $navigationPath) {
            VStack(spacing: 0) {
            // Header-Bereich: Icons + Logo + Farbschema
            VStack(spacing: 0) {
                // Obere Zeile: Kontakte-Button | Logo | Pferd+-Button
                HStack(alignment: .top) {
                    // Kontakte-Button (Icon + Label getrennt)
                    Button(action: { showingContacts = true }) {
                        VStack(spacing: 3) {
                            Image(systemName: "person.2.fill")
                                .font(.system(size: 20))
                                .frame(width: 44, height: 36)
                            Text("Kontakte")
                                .font(.system(size: 9, weight: .medium))
                        }
                        .foregroundColor(.secondary)
                    }
                    .buttonStyle(.plain)

                    Spacer()

                    // Logo zentriert (5x tippen = Beta-Info / Debug)
                    Image("hippominder_logo")
                        .resizable()
                        .scaledToFit()
                        .frame(height: 50)
                        .onTapGesture {
                            logoTapCount += 1
                            if logoTapCount >= 5 {
                                showingBetaInfo = true
                                logoTapCount = 0
                            }
                            DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                                logoTapCount = 0
                            }
                        }

                    Spacer()

                    // Pferd hinzufuegen Button (Icon + Label getrennt)
                    Button(action: {
                        if storeManager.canAddHorse(currentCount: horses.count) {
                            showingAddHorse = true
                        } else {
                            showingPaywall = true
                        }
                    }) {
                        VStack(spacing: 3) {
                            Image("plushorse")
                                .resizable()
                                .scaledToFit()
                                .frame(width: 32, height: 32)
                                .clipShape(Circle())
                                .shadow(color: .black.opacity(0.2), radius: 2, x: 0, y: 1)
                                .frame(height: 36)
                            Text("Pferd +")
                                .font(.system(size: 9, weight: .medium))
                                .foregroundColor(.secondary)
                        }
                    }
                    .buttonStyle(.plain)
                }
                .padding(.horizontal, 12)
                .padding(.top, 4)

                // Farbschema-Auswahl rechts. Glas: drei Schemata + freie Farbe,
                // Blume: nur die drei Schemata, Classic ist monochrom.
                if globalSettings.designMode != .classic {
                    HStack {
                        Spacer()
                        GlobalColorPicker(
                            selectedScheme: Binding(
                                get: {
                                    globalSettings.designMode == .glass
                                        ? globalSettings.matchingColorScheme
                                        : globalSettings.flowerColorScheme
                                },
                                set: { scheme in
                                    guard let scheme else { return }
                                    if globalSettings.designMode == .glass {
                                        // Schema + Glasfarbe
                                        globalSettings.flowerColorScheme = scheme
                                    } else {
                                        // Blume: nur das Schema, die frei gewaehlte
                                        // Glasfarbe bleibt erhalten
                                        globalSettings.flowerColorSchemeIndex =
                                            FlowerColorScheme.allCases.firstIndex(of: scheme) ?? 0
                                    }
                                }
                            ),
                            customTint: Binding(
                                get: { globalSettings.glassTint },
                                set: { globalSettings.glassTint = $0 }
                            ),
                            showsCustomTint: globalSettings.designMode == .glass
                        )
                    }
                    .padding(.horizontal, 12)
                    .padding(.top, 2)
                }

                // Debug-Anzeige (nur in Debug-Builds)
                #if DEBUG
                if debugSettings.timeOffsetDays != 0 {
                    Text("DEBUG: \(debugSettings.simulatedDateString)")
                        .font(.caption)
                        .foregroundColor(.orange)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 2)
                        .background(Color.orange.opacity(0.2))
                        .cornerRadius(4)
                        .padding(.top, 2)
                }
                #endif
            }
            .padding(.bottom, 4)
            .frame(maxWidth: .infinity)
            .background(.ultraThinMaterial)

            // Inhalt
            Group {
                if horses.isEmpty {
                    // Leerer Zustand
                    VStack(spacing: 20) {
                        Spacer()

                        Image("horse_silhouette")
                            .resizable()
                            .scaledToFit()
                            .frame(height: 80)
                            .opacity(0.15)

                        Text("Noch keine Pferde")
                            .font(.title2)
                            .foregroundColor(.gray)

                        Button(action: { showingAddHorse = true }) {
                            Label("Pferd hinzufügen", systemImage: "plus.circle.fill")
                                .font(.headline)
                        }

                        Spacer()
                    }
                } else {
                    // Pferdeliste
                    List {
                        ForEach(horses) { horse in
                            NavigationLink(destination: HorseDetailView(horse: horse)) {
                                HorseRowView(horse: horse)
                            }
                            .accessibilityIdentifier("horseRow_\(horse.name)")
                        }
                        .onDelete(perform: deleteHorses)
                    }
                    .listStyle(.plain)
                }
            }

            versionsFuss
            }
            .navigationBarHidden(true)
            .navigationDestination(for: Horse.self) { horse in
                HorseDetailView(horse: horse)
            }
        }
    }

    // MARK: - iPad: Liste links, Pferd rechts

    private var geteilteAnsicht: some View {
        NavigationSplitView {
            VStack(spacing: 0) {
            // Header-Bereich: Icons + Logo + Farbschema
            VStack(spacing: 0) {
                // Obere Zeile: Kontakte-Button | Logo | Pferd+-Button
                HStack(alignment: .top) {
                    // Kontakte-Button (Icon + Label getrennt)
                    Button(action: { showingContacts = true }) {
                        VStack(spacing: 3) {
                            Image(systemName: "person.2.fill")
                                .font(.system(size: 20))
                                .frame(width: 44, height: 36)
                            Text("Kontakte")
                                .font(.system(size: 9, weight: .medium))
                        }
                        .foregroundColor(.secondary)
                    }
                    .buttonStyle(.plain)

                    Spacer()

                    // Logo zentriert (5x tippen = Beta-Info / Debug)
                    Image("hippominder_logo")
                        .resizable()
                        .scaledToFit()
                        .frame(height: 50)
                        .onTapGesture {
                            logoTapCount += 1
                            if logoTapCount >= 5 {
                                showingBetaInfo = true
                                logoTapCount = 0
                            }
                            DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                                logoTapCount = 0
                            }
                        }

                    Spacer()

                    // Pferd hinzufuegen Button (Icon + Label getrennt)
                    Button(action: {
                        if storeManager.canAddHorse(currentCount: horses.count) {
                            showingAddHorse = true
                        } else {
                            showingPaywall = true
                        }
                    }) {
                        VStack(spacing: 3) {
                            Image("plushorse")
                                .resizable()
                                .scaledToFit()
                                .frame(width: 32, height: 32)
                                .clipShape(Circle())
                                .shadow(color: .black.opacity(0.2), radius: 2, x: 0, y: 1)
                                .frame(height: 36)
                            Text("Pferd +")
                                .font(.system(size: 9, weight: .medium))
                                .foregroundColor(.secondary)
                        }
                    }
                    .buttonStyle(.plain)
                }
                .padding(.horizontal, 12)
                .padding(.top, 4)

                // Farbschema-Auswahl rechts. Glas: drei Schemata + freie Farbe,
                // Blume: nur die drei Schemata, Classic ist monochrom.
                if globalSettings.designMode != .classic {
                    HStack {
                        Spacer()
                        GlobalColorPicker(
                            selectedScheme: Binding(
                                get: {
                                    globalSettings.designMode == .glass
                                        ? globalSettings.matchingColorScheme
                                        : globalSettings.flowerColorScheme
                                },
                                set: { scheme in
                                    guard let scheme else { return }
                                    if globalSettings.designMode == .glass {
                                        // Schema + Glasfarbe
                                        globalSettings.flowerColorScheme = scheme
                                    } else {
                                        // Blume: nur das Schema, die frei gewaehlte
                                        // Glasfarbe bleibt erhalten
                                        globalSettings.flowerColorSchemeIndex =
                                            FlowerColorScheme.allCases.firstIndex(of: scheme) ?? 0
                                    }
                                }
                            ),
                            customTint: Binding(
                                get: { globalSettings.glassTint },
                                set: { globalSettings.glassTint = $0 }
                            ),
                            showsCustomTint: globalSettings.designMode == .glass
                        )
                    }
                    .padding(.horizontal, 12)
                    .padding(.top, 2)
                }

                // Debug-Anzeige (nur in Debug-Builds)
                #if DEBUG
                if debugSettings.timeOffsetDays != 0 {
                    Text("DEBUG: \(debugSettings.simulatedDateString)")
                        .font(.caption)
                        .foregroundColor(.orange)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 2)
                        .background(Color.orange.opacity(0.2))
                        .cornerRadius(4)
                        .padding(.top, 2)
                }
                #endif
            }
            .padding(.bottom, 4)
            .frame(maxWidth: .infinity)
            .background(.ultraThinMaterial)

            // Inhalt
            Group {
                if horses.isEmpty {
                    // Leerer Zustand
                    VStack(spacing: 20) {
                        Spacer()

                        Image("horse_silhouette")
                            .resizable()
                            .scaledToFit()
                            .frame(height: 80)
                            .opacity(0.15)

                        Text("Noch keine Pferde")
                            .font(.title2)
                            .foregroundColor(.gray)

                        Button(action: { showingAddHorse = true }) {
                            Label("Pferd hinzufügen", systemImage: "plus.circle.fill")
                                .font(.headline)
                        }

                        Spacer()
                    }
                } else {
                    // Pferdeliste
                    List(selection: $ausgewaehltesPferd) {
                        ForEach(horses) { horse in
                            HorseRowView(horse: horse)
                                .tag(horse)
                                .accessibilityIdentifier("horseRow_\(horse.name)")
                        }
                        .onDelete(perform: deleteHorses)
                    }
                    .listStyle(.plain)
                }
            }

            versionsFuss
            }
            .navigationBarHidden(true)
        } detail: {
            // Eigener Stapel: ohne ihn waere der Link zu den
            // Benachrichtigungen in der Detailansicht wirkungslos, und es
            // gaebe keine Leiste, ueber die sich die eingeklappte Liste
            // wieder oeffnen laesst.
            NavigationStack {
                if let pferd = ausgewaehltesPferd {
                    HorseDetailView(horse: pferd)
                } else {
                    auswahlHinweis
                }
            }
        }
        .navigationSplitViewStyle(.balanced)
    }

    /// Version und Bauzeit, ganz unten und klein.
    ///
    /// Steht da, damit beim Bauen aufs Geraet zu sehen ist, ob der neue
    /// Stand wirklich angekommen ist. Die Bauzeit ist dabei das
    /// Entscheidende - die Nummer allein bleibt zwischen zwei Builds gleich.
    /// Antippen oeffnet die Beta-Info, ohne fuenfmal aufs Logo zu muessen.
    private var versionsFuss: some View {
        Text(Versionsinfo.zeile)
            .font(.system(size: 10))
            .foregroundStyle(.tertiary)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 3)
            .contentShape(Rectangle())
            .onTapGesture { showingBetaInfo = true }
            .accessibilityIdentifier("versionsFuss")
    }

    /// Rechte Spalte, solange nichts gewaehlt ist
    private var auswahlHinweis: some View {
        VStack(spacing: 14) {
            Image("horse_silhouette")
                .resizable()
                .scaledToFit()
                .frame(height: 90)
                .opacity(0.15)
            Text("Pferd auswählen")
                .font(.title3)
                .foregroundStyle(.secondary)
        }
    }

    /// Debug-Hilfe fuer den Simulator: Start mit "-demoHorse" legt ein Demo-Pferd an
    /// (Foto optional per "-demoHorsePhoto /pfad/zum/bild.jpg") und oeffnet direkt die Detailansicht.
    private func seedDemoHorseIfRequested() {
        #if DEBUG
        let args = ProcessInfo.processInfo.arguments
        if args.contains("-dumpNotifications"), !notificationsDumped {
            notificationsDumped = true
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                NotificationService.shared.debugDumpPending()
            }
        }
        guard args.contains("-demoHorse"), !demoSeeded else { return }
        demoSeeded = true

        var photo: Data? = nil
        if let path = UserDefaults.standard.string(forKey: "demoHorsePhoto") {
            photo = try? Data(contentsOf: URL(fileURLWithPath: path))
        }
        // "-demoDaysAgo 30,120,10" = Tage seit Hufschmied, Impfung, Wurmkur
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
            horse.imageData = photo
            horse.letzterHufschmiedTermin = dates[0]
            horse.letzterImpfungTermin = dates[1]
            horse.letzterWurmkurTermin = dates[2]
        } else {
            horse = Horse(
                name: "Demo",
                imageData: photo,
                letzterHufschmiedTermin: dates[0],
                letzterImpfungTermin: dates[1],
                letzterWurmkurTermin: dates[2]
            )
            modelContext.insert(horse)
        }
        try? modelContext.save()

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
            // Auf dem iPad gibt es keinen Pfad, dort oeffnet die Auswahl
            // die rechte Spalte - sonst bliebe sie beim UI-Test leer
            if UIDevice.current.userInterfaceIdiom == .pad {
                ausgewaehltesPferd = horse
            } else if navigationPath.isEmpty {
                navigationPath.append(horse)
            }
        }
        #endif
    }

    private func deleteHorses(offsets: IndexSet) {
        withAnimation {
            for index in offsets {
                let pferd = horses[index]
                // Sonst zeigt die rechte Spalte auf dem iPad ein
                // geloeschtes Pferd weiter an
                if ausgewaehltesPferd == pferd { ausgewaehltesPferd = nil }
                NotificationService.shared.removeAllNotifications(for: pferd)
                modelContext.delete(pferd)
            }
        }
        // Sofort sichern, damit das Loeschen auch bei sofortigem App-Ende erhalten bleibt
        try? modelContext.save()
        // Sonst bliebe die Zahl am App-Symbol fuer ein geloeschtes Pferd stehen
        NotificationService.shared.updateBadge(using: modelContext)
        WatchSyncService.shared.syncToWatch()
    }
}

// MARK: - Pferd Zeile

struct HorseRowView: View {
    @Bindable var horse: Horse

    var body: some View {
        HStack(spacing: 12) {
            // Pferdebild
            if let image = horse.image {
                image
                    .resizable()
                    .scaledToFill()
                    .frame(width: 50, height: 50)
                    .clipShape(Circle())
            } else {
                Circle()
                    .fill(Color.gray.opacity(0.2))
                    .frame(width: 50, height: 50)
                    .overlay(
                        Image("horse_silhouette")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 28, height: 28)
                            .opacity(0.3)
                    )
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(horse.name)
                    .font(.headline)

                // Naechster faelliger Termin
                let nextEvent = getNextEvent()
                HStack(spacing: 4) {
                    Image(nextEvent.type.symbol)
                        .resizable()
                        .scaledToFit()
                        .foregroundStyle(.primary)
                        .frame(width: 14, height: 14)
                    if nextEvent.days < 0 {
                        Text("\(nextEvent.type.localizedName) \(String(localized: "seit")) \(-nextEvent.days) \(String(localized: "Tagen überfällig"))")
                            .font(.caption)
                            .foregroundColor(.red)
                    } else if nextEvent.days == 0 {
                        Text("\(nextEvent.type.localizedName) \(String(localized: "heute fällig!"))")
                            .font(.caption)
                            .foregroundColor(.red)
                    } else {
                        Text("\(nextEvent.type.localizedName) \(String(localized: "in")) \(nextEvent.days) \(String(localized: "Tagen"))")
                            .font(.caption)
                            .foregroundColor(nextEvent.days <= 7 ? .red : (nextEvent.days <= 14 ? .orange : .gray))
                    }
                }
            }

            Spacer()

            // Timer-Indikatoren mit Icons
            HStack(spacing: 6) {
                ForEach(Horse.EventType.allCases, id: \.self) { eventType in
                    TimerIndicator(
                        eventType: eventType,
                        days: horse.tageBis(fuer: eventType),
                        interval: horse.holeIntervall(fuer: eventType)
                    )
                }
            }
        }
        .padding(.vertical, 4)
    }

    private func getNextEvent() -> (type: Horse.EventType, days: Int) {
        let events: [(Horse.EventType, Int)] = [
            (.hufschmied, horse.tageBisHufschmied),
            (.impfung, horse.tageBisImpfung),
            (.wurmkur, horse.tageBisWurmkur)
        ]
        return events.min(by: { $0.1 < $1.1 }).map { (type: $0.0, days: $0.1) } ?? (.hufschmied, 0)
    }
}

// MARK: - Timer Indikator mit Icon

struct TimerIndicator: View {
    let eventType: Horse.EventType
    let days: Int
    let interval: Int

    private var indicatorColor: Color {
        if days <= 7 { return .red }
        if days <= 14 { return .orange }
        return .green
    }

    private var isExpired: Bool { days <= 0 }

    private var filledPetals: Int {
        FlowerGeometry.filledPetals(remainingDays: days, interval: interval)
    }

    var body: some View {
        VStack(spacing: 2) {
            Image(eventType.symbol)
                .resizable()
                .scaledToFit()
                .foregroundStyle(.primary)
                .frame(width: 11, height: 11)
                .opacity(0.7)

            MiniRose(
                filledPetals: filledPetals,
                isExpired: isExpired,
                color: indicatorColor
            )
        }
    }
}

// MARK: - Mini-Rose fuer die Liste

/// Dieselbe Blume wie in der Detailansicht, nur klein: zeigt auf einen Blick
/// wie weit das Intervall fortgeschritten ist, nicht nur ob es knapp wird.
struct MiniRose: View {
    let filledPetals: Int
    let isExpired: Bool
    let color: Color
    var size: CGFloat = 30

    private var petalWidth: CGFloat { max(1.8, size * LCDGeometry.petalWidth) }
    private var petalLength: CGFloat { size * LCDGeometry.petalLength }
    private var radialDistance: CGFloat { size * LCDGeometry.radialDistance }
    private var dotDiameter: CGFloat { size * LCDGeometry.dotDiameter }

    var body: some View {
        ZStack {
            ForEach(0..<FlowerGeometry.petalCount, id: \.self) { index in
                Capsule()
                    .fill(index < filledPetals ? color : Color.gray.opacity(0.25))
                    .frame(width: petalWidth, height: petalLength)
                    .offset(y: -radialDistance)
                    .rotationEffect(.degrees(FlowerGeometry.angle(for: index)))
            }

            if isExpired {
                Circle()
                    .fill(color)
                    .frame(width: dotDiameter, height: dotDiameter)
            }
        }
        .frame(width: size, height: size)
    }
}

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

#Preview {
    ContentView()
        .modelContainer(for: Horse.self, inMemory: true)
}
#endif
