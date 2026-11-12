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
    /// Bitte um den vollen Stand, wenn hier keine Pferde liegen
    static let actionBitteDaten = "bitteDaten"

    /// Fragt das iPhone nach den Pferden, wenn der eigene Speicher leer ist.
    ///
    /// Nach einer Neuinstallation der Watch-App ist der Speicher leer, und
    /// der applicationContext, den das iPhone vorher geschickt hat, ist mit
    /// der alten Installation weg. Das iPhone schickt erst wieder, wenn
    /// seine App laeuft - im Stall hilft das nicht. Darum fragt die Uhr
    /// selbst; ist das iPhone in Reichweite, wird seine App dafuer im
    /// Hintergrund geweckt. Nur wenn noetig, denn Funk kostet Strom.
    func bitteUmDatenFallsLeer() {
        guard WCSession.default.activationState == .activated,
              WCSession.default.isReachable,
              speicherIstLeer else { return }
        isSyncing = true
        WCSession.default.sendMessage(
            [Self.actionKey: Self.actionBitteDaten],
            replyHandler: { [weak self] antwort in
                Task { @MainActor in self?.processPayload(antwort) }
            },
            errorHandler: { [weak self] _ in
                Task { @MainActor in self?.isSyncing = false }
            }
        )
    }

    private var speicherIstLeer: Bool {
        guard let container = modelContainer else { return false }
        var descriptor = FetchDescriptor<Horse>()
        descriptor.fetchLimit = 1
        return ((try? container.mainContext.fetch(descriptor)) ?? []).isEmpty
    }

    /// Wartet nach dem letzten Tastendruck, bevor gefunkt wird
    private var intervallMelder: Task<Void, Never>?
    /// Der noch nicht gemeldete Stand, damit er beim Verlassen der Seite
    /// nicht in der Wartezeit verlorengeht
    private var offenesIntervall: (horseID: UUID, eventType: Horse.EventType, intervall: Int)?
    private static let intervallRuhezeit: Duration = .milliseconds(1200)

    /// Meldet dem iPhone ein auf der Uhr geaendertes Intervall - gleicher
    /// Weg wie beim Abhaken: nachreichen, und sofort, wenn erreichbar.
    ///
    /// Aber **nicht bei jedem Tastendruck.** Das Intervall wird mit Plus und
    /// Minus eingestellt; von 42 auf 56 sind das vierzehn Druecker. Jeder
    /// schickte bisher zwei Funksprueche los, und das iPhone antwortete auf
    /// jeden mit dem vollen Datensatz - rund sechzig Funkvorgaenge fuer eine
    /// einzige Einstellung. Der Funk ist auf der Uhr der groesste
    /// Stromfresser, groesser als alles Zeichnen.
    ///
    /// Darum: oertlich sofort speichern (die Anzeige bleibt flink), aber erst
    /// melden, wenn Mathias mit dem Tippen fertig ist. Nur der letzte Wert
    /// zaehlt - die Zwischenstufen interessieren das iPhone nicht.
    func meldeIntervall(horseID: UUID, eventType: Horse.EventType, intervall: Int) {
        guard WCSession.default.activationState == .activated else { return }

        intervallMelder?.cancel()
        offenesIntervall = (horseID, eventType, intervall)
        intervallMelder = Task { @MainActor [weak self] in
            try? await Task.sleep(for: Self.intervallRuhezeit)
            guard !Task.isCancelled else { return }
            self?.meldeOffenesIntervall()
        }
    }

    /// Schickt einen noch wartenden Wert sofort los. Gehoert ans Verlassen
    /// der Seite und ins Verschwinden der App - sonst ginge eine Einstellung
    /// verloren, die noch in der Wartezeit steckt, und das iPhone wuerde den
    /// alten Wert beim naechsten Abgleich wieder darueberschreiben.
    func meldeOffenesIntervall() {
        intervallMelder?.cancel()
        intervallMelder = nil
        guard let offen = offenesIntervall else { return }
        offenesIntervall = nil
        sendeIntervall(horseID: offen.horseID, eventType: offen.eventType, intervall: offen.intervall)
    }

    private func sendeIntervall(horseID: UUID, eventType: Horse.EventType, intervall: Int) {
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
        isSyncing = false
        // Glasfarbe des iPhones uebernehmen, damit die Uhr dieselbe Blume zeigt
        if let tint = payload["glassTint"] as? [Double], tint.count == 3 {
            UserDefaults.standard.set(tint, forKey: WatchGlas.tintKey)
        }
        if let mode = payload["designMode"] as? String {
            UserDefaults.standard.set(mode, forKey: WatchGlas.designModeKey)
        }
        guard let horseDataArray = payload["horses"] as? [[String: Any]] else { return }
        // Leere Liste nie uebernehmen: sie kommt vom iPhone, bevor iCloud
        // geladen ist, nicht weil die Pferde weg waeren. Doppelt genaeht -
        // das iPhone schickt sie seit 12.11.2026 auch nicht mehr.
        guard !horseDataArray.isEmpty else { isSyncing = false; return }

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
            Task { @MainActor in
                if !context.isEmpty {
                    self.processPayload(context)
                }
                self.bitteUmDatenFallsLeer()
            }
        }
    }

    /// iPhone kommt in Reichweite: wenn hier noch nichts liegt, jetzt fragen
    nonisolated func sessionReachabilityDidChange(_ session: WCSession) {
        if session.isReachable {
            Task { @MainActor in
                self.bitteUmDatenFallsLeer()
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
