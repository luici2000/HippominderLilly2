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

    /// Meldet dem iPhone, dass ein Termin heute erledigt wurde.
    ///
    /// Im Stall ist das iPhone oft nicht in Reichweite, darum
    /// `transferUserInfo`: das stellt zu, sobald wieder Verbindung besteht,
    /// statt die Meldung zu verlieren. Ist das iPhone erreichbar, geht
    /// zusaetzlich sofort eine Nachricht raus.
    func meldeTerminErledigt(horseID: UUID, eventType: Horse.EventType, datum: Date) {
        guard WCSession.default.activationState == .activated else { return }

        let payload: [String: Any] = [
            Self.actionKey: Self.actionTerminErledigt,
            "horseID": horseID.uuidString,
            "eventType": eventType.rawValue,
            "datum": datum.timeIntervalSince1970
        ]

        WCSession.default.transferUserInfo(payload)

        if WCSession.default.isReachable {
            WCSession.default.sendMessage(payload, replyHandler: nil)
        }
    }

    /// Kennzeichnet Rueckmeldungen der Uhr. Ein Datensatz vom iPhone traegt
    /// stattdessen "horses" - so lassen sich beide Richtungen unterscheiden.
    static let actionKey = "action"
    static let actionTerminErledigt = "terminErledigt"
    static let actionIntervallGeaendert = "intervallGeaendert"

    /// Meldet dem iPhone ein auf der Uhr geaendertes Intervall - gleicher
    /// Weg wie beim Abhaken: nachreichen, und sofort, wenn erreichbar.
    func meldeIntervall(horseID: UUID, eventType: Horse.EventType, intervall: Int) {
        guard WCSession.default.activationState == .activated else { return }
        let payload: [String: Any] = [
            Self.actionKey: Self.actionIntervallGeaendert,
            "horseID": horseID.uuidString,
            "eventType": eventType.rawValue,
            "intervall": intervall
        ]
        WCSession.default.transferUserInfo(payload)
        if WCSession.default.isReachable {
            WCSession.default.sendMessage(payload, replyHandler: nil)
        }
    }

    private func processPayload(_ payload: [String: Any]) {
        guard let container = modelContainer else { return }
        // Glasfarbe des iPhones uebernehmen, damit die Uhr dieselbe Blume zeigt
        if let tint = payload["glassTint"] as? [Double], tint.count == 3 {
            UserDefaults.standard.set(tint, forKey: WatchGlas.tintKey)
        }
        if let mode = payload["designMode"] as? String {
            UserDefaults.standard.set(mode, forKey: WatchGlas.designModeKey)
        }
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
