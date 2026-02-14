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
    @Query private var horses: [Horse]

    var body: some View {
        NavigationStack {
            if horses.isEmpty {
                VStack(spacing: 8) {
                    Image(systemName: "hare")
                        .font(.largeTitle)
                        .foregroundColor(.gray)
                    Text("Keine Pferde")
                        .font(.headline)
                        .foregroundColor(.gray)
                    Text("Fuege Pferde in der\niPhone-App hinzu")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
            } else {
                List(horses) { horse in
                    NavigationLink(destination: WatchHorseDetailView(horse: horse)) {
                        WatchHorseRow(horse: horse)
                    }
                }
                .navigationTitle("Hippominder")
            }
        }
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

            HStack(spacing: 4) {
                Image(systemName: nextEvent.type.systemSymbol)
                    .font(.caption2)
                    .foregroundColor(colorForDays(nextEvent.days))

                if nextEvent.days < 0 {
                    Text("\(nextEvent.type.localizedName) \(-nextEvent.days)d ueberfaellig")
                        .font(.caption2)
                        .foregroundColor(.red)
                } else if nextEvent.days == 0 {
                    Text("\(nextEvent.type.localizedName) heute!")
                        .font(.caption2)
                        .foregroundColor(.red)
                } else {
                    Text("\(nextEvent.type.localizedName) in \(nextEvent.days)d")
                        .font(.caption2)
                        .foregroundColor(colorForDays(nextEvent.days))
                }
            }

            // Mini-Ampeln
            HStack(spacing: 6) {
                ForEach(Horse.EventType.allCases, id: \.self) { eventType in
                    HStack(spacing: 2) {
                        Image(systemName: eventType.systemSymbol)
                            .font(.system(size: 8))
                        Circle()
                            .fill(colorForDays(horse.tageBis(fuer: eventType)))
                            .frame(width: 6, height: 6)
                    }
                }
            }
            .foregroundColor(.secondary)
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
            VStack(spacing: 12) {
                // Pferdename
                Text(horse.name)
                    .font(.title3.bold())

                // Timer fuer jeden Typ
                ForEach(Horse.EventType.allCases, id: \.self) { eventType in
                    WatchTimerCard(
                        eventType: eventType,
                        days: horse.tageBis(fuer: eventType),
                        interval: horse.holeIntervall(fuer: eventType)
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

    var body: some View {
        VStack(spacing: 6) {
            HStack {
                Image(systemName: eventType.systemSymbol)
                    .font(.caption)
                    .foregroundColor(statusColor)
                Text(eventType.localizedName)
                    .font(.caption.bold())
                Spacer()
                Text(days <= 0 ? "\(-days)d ueber" : "\(days)d")
                    .font(.caption.bold())
                    .foregroundColor(statusColor)
            }

            // Fortschrittsbalken
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 3)
                        .fill(Color.gray.opacity(0.3))
                        .frame(height: 6)

                    RoundedRectangle(cornerRadius: 3)
                        .fill(statusColor)
                        .frame(width: geo.size.width * min(1.0, max(0, progress)), height: 6)
                }
            }
            .frame(height: 6)

            Text("Intervall: \(interval) Tage")
                .font(.system(size: 9))
                .foregroundColor(.secondary)
        }
        .padding(8)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(Color.gray.opacity(0.15))
        )
    }
}
