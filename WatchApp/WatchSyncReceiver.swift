//
//  WatchSyncReceiver.swift
//  Hippominder Watch App
//
//  Autor: Mathias Hubrich & Claude (Anthropic)
//  Erstellt: 16. Februar 2026
//  Version: 1.0.0
//
//  Beschreibung: Empfaengt Pferdedaten vom iPhone via WatchConnectivity
//

#if os(watchOS)
import Foundation
import WatchConnectivity
import SwiftData

@MainActor
class WatchSyncReceiver: NSObject, ObservableObject {
    static let shared = WatchSyncReceiver()

    @Published var lastSyncDate: Date?
    @Published var isSyncing = false

    private var modelContainer: ModelContainer?

    private override init() {
        super.init()
    }

    func configure(with container: ModelContainer) {
        self.modelContainer = container
        guard WCSession.isSupported() else { return }
        WCSession.default.delegate = self
        WCSession.default.activate()
    }

    private func processPayload(_ payload: [String: Any]) {
        guard let container = modelContainer else { return }
        guard let horseDataArray = payload["horses"] as? [[String: Any]] else { return }

        Task { @MainActor in
            self.isSyncing = true
            let context = container.mainContext

            // Fetch existing horses
            let descriptor = FetchDescriptor<Horse>()
            let existingHorses = (try? context.fetch(descriptor)) ?? []
            var existingByID: [UUID: Horse] = [:]
            for horse in existingHorses {
                existingByID[horse.id] = horse
            }

            var receivedIDs: Set<UUID> = []

            for data in horseDataArray {
                guard let idString = data["id"] as? String,
                      let uuid = UUID(uuidString: idString),
                      let name = data["name"] as? String else { continue }

                receivedIDs.insert(uuid)

                let hufschmiedIntervall = data["hufschmiedIntervall"] as? Int ?? 42
                let impfungIntervall = data["impfungIntervall"] as? Int ?? 180
                let wurmkurIntervall = data["wurmkurIntervall"] as? Int ?? 90
                let hufschmiedTS = data["letzterHufschmiedTermin"] as? TimeInterval ?? Date().timeIntervalSince1970
                let impfungTS = data["letzterImpfungTermin"] as? TimeInterval ?? Date().timeIntervalSince1970
                let wurmkurTS = data["letzterWurmkurTermin"] as? TimeInterval ?? Date().timeIntervalSince1970
                let benachrichtigung = data["benachrichtigungTageVorher"] as? Int ?? 3

                if let existing = existingByID[uuid] {
                    // Update existing horse
                    existing.name = name
                    existing.hufschmiedIntervall = hufschmiedIntervall
                    existing.impfungIntervall = impfungIntervall
                    existing.wurmkurIntervall = wurmkurIntervall
                    existing.letzterHufschmiedTermin = Date(timeIntervalSince1970: hufschmiedTS)
                    existing.letzterImpfungTermin = Date(timeIntervalSince1970: impfungTS)
                    existing.letzterWurmkurTermin = Date(timeIntervalSince1970: wurmkurTS)
                    existing.benachrichtigungTageVorher = benachrichtigung
                } else {
                    // Insert new horse
                    let horse = Horse(
                        name: name,
                        hufschmiedIntervall: hufschmiedIntervall,
                        impfungIntervall: impfungIntervall,
                        wurmkurIntervall: wurmkurIntervall,
                        letzterHufschmiedTermin: Date(timeIntervalSince1970: hufschmiedTS),
                        letzterImpfungTermin: Date(timeIntervalSince1970: impfungTS),
                        letzterWurmkurTermin: Date(timeIntervalSince1970: wurmkurTS),
                        benachrichtigungTageVorher: benachrichtigung
                    )
                    // Preserve the UUID from iPhone
                    horse.id = uuid
                    context.insert(horse)
                }
            }

            // Delete horses that no longer exist on iPhone
            for (id, horse) in existingByID {
                if !receivedIDs.contains(id) {
                    context.delete(horse)
                }
            }

            try? context.save()
            self.lastSyncDate = Date()
            self.isSyncing = false
        }
    }
}

// MARK: - WCSessionDelegate

extension WatchSyncReceiver: WCSessionDelegate {
    nonisolated func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {
        if activationState == .activated {
            // Check for any pending applicationContext
            let context = session.receivedApplicationContext
            if !context.isEmpty {
                Task { @MainActor in
                    self.processPayload(context)
                }
            }
        }
    }

    nonisolated func session(_ session: WCSession, didReceiveApplicationContext applicationContext: [String: Any]) {
        Task { @MainActor in
            self.processPayload(applicationContext)
        }
    }

    nonisolated func session(_ session: WCSession, didReceiveMessage message: [String: Any]) {
        Task { @MainActor in
            self.processPayload(message)
        }
    }
}
#endif
