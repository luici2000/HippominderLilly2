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

        // Glasfarbe und Darstellung mitschicken, damit die Uhr dieselbe
        // Glasblume zeigt wie das iPhone
        let settings = GlobalSettings.shared
        let payload: [String: Any] = [
            "horses": horseData,
            "glassTint": [settings.glassTintRed, settings.glassTintGreen, settings.glassTintBlue],
            "designMode": settings.designModeRaw,
            "timestamp": Date().timeIntervalSince1970
        ]

        // applicationContext for guaranteed delivery
        try? WCSession.default.updateApplicationContext(payload)

        // sendMessage for real-time if reachable
        if WCSession.default.isReachable {
            WCSession.default.sendMessage(payload, replyHandler: nil)
        }
    }

    // MARK: - Rueckmeldung von der Uhr

    /// Kennzeichnet Rueckmeldungen der Uhr (siehe WatchSyncReceiver)
    private static let actionKey = "action"
    private static let actionTerminErledigt = "terminErledigt"
    private static let actionIntervallGeaendert = "intervallGeaendert"

    /// Traegt einen auf der Uhr abgehakten Termin oder ein dort geaendertes
    /// Intervall ein und spiegelt den neuen Stand zurueck, damit beide
    /// Geraete uebereinstimmen.
    fileprivate func verarbeiteUhrMeldung(_ payload: [String: Any]) {
        guard let action = payload[Self.actionKey] as? String,
              let container = modelContainer,
              let idString = payload["horseID"] as? String,
              let uuid = UUID(uuidString: idString),
              let typRaw = payload["eventType"] as? String,
              let eventType = Horse.EventType(rawValue: typRaw)
        else { return }

        let context = container.mainContext
        let descriptor = FetchDescriptor<Horse>(predicate: #Predicate { $0.id == uuid })
        guard let horse = try? context.fetch(descriptor).first else { return }

        switch action {
        case Self.actionTerminErledigt:
            guard let stamp = payload["datum"] as? TimeInterval else { return }
            horse.setzeTermin(Date(timeIntervalSince1970: stamp), fuer: eventType)
        case Self.actionIntervallGeaendert:
            guard let intervall = payload["intervall"] as? Int else { return }
            horse.setzeIntervall(max(1, intervall), fuer: eventType)
        default:
            return
        }
        try? context.save()

        NotificationService.shared.scheduleAllNotifications(for: horse)
        NotificationService.shared.updateBadge(using: context)
        syncToWatch()
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

    /// Sofortmeldung, wenn die Uhr gerade erreichbar ist
    nonisolated func session(_ session: WCSession, didReceiveMessage message: [String: Any]) {
        Task { @MainActor in
            self.verarbeiteUhrMeldung(message)
        }
    }

    /// Nachgereichte Meldung, wenn die Uhr ausser Reichweite war
    nonisolated func session(_ session: WCSession, didReceiveUserInfo userInfo: [String: Any] = [:]) {
        Task { @MainActor in
            self.verarbeiteUhrMeldung(userInfo)
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
