//
//  WatchSyncService.swift
//  Hippominder
//
//  Autor: Mathias Hubrich & Claude (Anthropic)
//  Erstellt: 16. Februar 2026
//  Version: 1.0.0
//
//  Beschreibung: Sendet Pferdedaten vom iPhone zur Apple Watch via WatchConnectivity
//

#if os(iOS)
import Foundation
import WatchConnectivity
import SwiftData

@MainActor
class WatchSyncService: NSObject, ObservableObject {
    static let shared = WatchSyncService()

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

    func syncToWatch() {
        guard let container = modelContainer else { return }
        guard WCSession.default.activationState == .activated else { return }

        let context = container.mainContext
        let descriptor = FetchDescriptor<Horse>()
        guard let horses = try? context.fetch(descriptor) else { return }

        let horseData: [[String: Any]] = horses.map { horse in
            [
                "id": horse.id.uuidString,
                "name": horse.name,
                "hufschmiedIntervall": horse.hufschmiedIntervall,
                "impfungIntervall": horse.impfungIntervall,
                "wurmkurIntervall": horse.wurmkurIntervall,
                "letzterHufschmiedTermin": horse.letzterHufschmiedTermin.timeIntervalSince1970,
                "letzterImpfungTermin": horse.letzterImpfungTermin.timeIntervalSince1970,
                "letzterWurmkurTermin": horse.letzterWurmkurTermin.timeIntervalSince1970,
                "benachrichtigungTageVorher": horse.benachrichtigungTageVorher
            ]
        }

        let payload: [String: Any] = [
            "horses": horseData,
            "timestamp": Date().timeIntervalSince1970
        ]

        // applicationContext for guaranteed delivery
        try? WCSession.default.updateApplicationContext(payload)

        // sendMessage for real-time if reachable
        if WCSession.default.isReachable {
            WCSession.default.sendMessage(payload, replyHandler: nil)
        }
    }
}

// MARK: - WCSessionDelegate

extension WatchSyncService: WCSessionDelegate {
    nonisolated func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {
        if activationState == .activated {
            Task { @MainActor in
                self.syncToWatch()
            }
        }
    }

    nonisolated func sessionDidBecomeInactive(_ session: WCSession) {}
    nonisolated func sessionDidDeactivate(_ session: WCSession) {
        session.activate()
    }

    nonisolated func sessionReachabilityDidChange(_ session: WCSession) {
        if session.isReachable {
            Task { @MainActor in
                self.syncToWatch()
            }
        }
    }
}
#endif
