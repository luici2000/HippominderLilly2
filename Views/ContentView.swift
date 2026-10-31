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

    var body: some View {
        NavigationStack {
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

                    // Die drei Farbschemata gehoeren zu den PNG-Blumen. Glas hat
                    // die freie Farbwahl, Classic ist monochrom.
                    if globalSettings.designMode.usesColorScheme {
                        HStack {
                            Spacer()
                            GlobalColorPicker(selectedScheme: Binding(
                                get: { globalSettings.flowerColorScheme },
                                set: { globalSettings.flowerColorScheme = $0 }
                            ))
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
                            }
                            .onDelete(perform: deleteHorses)
                        }
                        .listStyle(.plain)
                    }
                }
            }
            .navigationBarHidden(true)
            .sheet(isPresented: $showingAddHorse, onDismiss: {
                WatchSyncService.shared.syncToWatch()
            }) {
                AddHorseView()
            }
            .sheet(isPresented: $showingContacts) {
                ContactsView()
            }
            .sheet(isPresented: $showingPaywall) {
                PaywallView()
            }
            .sheet(isPresented: $showingBetaInfo) {
                BetaInfoView()
            }
        }
    }

    private func deleteHorses(offsets: IndexSet) {
        withAnimation {
            for index in offsets {
                modelContext.delete(horses[index])
            }
        }
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

    /// Gleiche Rechnung wie in den grossen Timern
    private var filledPetals: Int {
        if isExpired { return FlowerGeometry.petalCount }
        guard interval > 0 else { return 0 }
        let share = Double(days) / Double(interval)
        let filled = FlowerGeometry.petalCount - Int(share * Double(FlowerGeometry.petalCount))
        return min(FlowerGeometry.petalCount, max(0, filled))
    }

    var body: some View {
        VStack(spacing: 2) {
            Image(eventType.symbol)
                .resizable()
                .scaledToFit()
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
    @Binding var selectedScheme: FlowerColorScheme

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
