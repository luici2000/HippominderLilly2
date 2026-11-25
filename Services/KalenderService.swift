//
//  KalenderService.swift
//  Hippominder
//
//  Haelt die Termine im Apple-Kalender aktuell.
//
//  Vorher (bis 25.11.2026): ein Knopf "Termine im Kalender speichern", der
//  die naechsten drei Termine einmal eintrug. Spaetere Aenderungen erreichten
//  den Kalender nie, und nach einer Aenderung legte der Knopf einen zweiten
//  Eintrag an, der alte blieb am alten Tag stehen. Mathias: "dann muss der
//  vorherige Termin aus dem Apple Kalender raus".
//
//  Jetzt: Der Knopf schaltet den Abgleich ein. Danach gibt es je Pferd und
//  Termin genau einen Eintrag. Bei jeder Aenderung (iPhone, Mac, Uhr,
//  Datensicherung - alles laeuft ueber NotificationService) wird der alte
//  geloescht und der neue gesetzt. Eintraege traegt eine Marke in der URL,
//  damit sie auch nach einer Umbenennung des Pferdes gefunden werden; was
//  der alte Knopf ohne Marke angelegt hat, wird am Titel erkannt.
//

import EventKit
import Foundation

enum KalenderMarke {
    static func url(pferdID: UUID, typ: Horse.EventType) -> URL {
        URL(string: "hippominder://termin/\(pferdID.uuidString)/\(typ.rawValue)")!
    }

    static func titel(pferdName: String, typ: Horse.EventType) -> String {
        "\(pferdName): \(typ.localizedName)"
    }

    /// Gehoert ein Kalendereintrag zu diesem Pferd und Termin?
    ///
    /// Mit Marke zaehlt nur die Marke - ein fremder Eintrag mit eigener URL
    /// wird nie angefasst. Ohne Marke nur, was der alte Knopf geschrieben hat:
    /// genau dieser Titel und eine Notiz, die mit "Hippominder" beginnt.
    static func gehoertZu(titel: String?, notiz: String?, url: URL?,
                          pferdID: UUID, pferdName: String, typ: Horse.EventType) -> Bool {
        if let url {
            return url == Self.url(pferdID: pferdID, typ: typ)
        }
        return titel == Self.titel(pferdName: pferdName, typ: typ)
            && (notiz?.hasPrefix("Hippominder") ?? false)
    }
}

@MainActor
final class KalenderService {
    static let shared = KalenderService()

    /// Je Geraet: ist der Abgleich eingeschaltet?
    static let schalterKey = "kalenderAbgleich"

    private let store = EKEventStore()
    private var wartend: [UUID: Task<Void, Never>] = [:]

    private init() {}

    var istAn: Bool { UserDefaults.standard.bool(forKey: Self.schalterKey) }

    private var darf: Bool {
        EKEventStore.authorizationStatus(for: .event) == .fullAccess
    }

    /// Der Knopf: Erlaubnis holen, Abgleich einschalten, alles eintragen.
    /// Gibt den Satz fuer die Meldung zurueck.
    func einschalten(_ pferde: [Horse]) async -> String {
        let erlaubt = (try? await store.requestFullAccessToEvents()) ?? false
        guard erlaubt else {
            return String(localized: "Kein Zugriff auf den Kalender. Bitte in den Einstellungen erlauben.")
        }
        UserDefaults.standard.set(true, forKey: Self.schalterKey)
        do {
            for pferd in pferde { try eintragen(pferd) }
            return String(localized: "Die Termine stehen im Kalender. Ab jetzt hält Hippominder sie dort aktuell – ein alter Eintrag wird ersetzt, sobald sich ein Termin ändert.")
        } catch {
            return String(localized: "Fehler beim Speichern: \(error.localizedDescription)")
        }
    }

    /// Nach jeder Aenderung an einem Pferd. Wartet kurz, weil Plus und Minus
    /// pro Tastendruck melden - eingetragen wird nur der Endstand.
    func abgleichen(_ pferd: Horse) {
        guard istAn, darf else { return }
        let id = pferd.id
        wartend[id]?.cancel()
        wartend[id] = Task { [weak self] in
            try? await Task.sleep(for: .seconds(1.5))
            guard !Task.isCancelled else { return }
            try? self?.eintragen(pferd)
            self?.wartend[id] = nil
        }
    }

    /// Pferd geloescht: seine Eintraege raus
    func entfernen(_ pferd: Horse) {
        guard istAn, darf else { return }
        wartend[pferd.id]?.cancel()
        for typ in Horse.EventType.allCases {
            try? loescheAlte(pferd, typ)
        }
        try? store.commit()
    }

    private func eintragen(_ pferd: Horse) throws {
        for typ in Horse.EventType.allCases {
            try loescheAlte(pferd, typ)

            let tag = Calendar.current.startOfDay(for: pferd.naechsterTermin(fuer: typ))
            let eintrag = EKEvent(eventStore: store)
            eintrag.title = KalenderMarke.titel(pferdName: pferd.name, typ: typ)
            eintrag.startDate = tag
            eintrag.endDate = tag
            eintrag.isAllDay = true
            eintrag.calendar = store.defaultCalendarForNewEvents
            eintrag.url = KalenderMarke.url(pferdID: pferd.id, typ: typ)
            eintrag.notes = "Hippominder Erinnerung für \(pferd.name)\nIntervall: \(pferd.holeIntervall(fuer: typ)) Tage"
            eintrag.addAlarm(EKAlarm(relativeOffset: TimeInterval(-pferd.benachrichtigungTageVorher * 24 * 60 * 60)))
            try store.save(eintrag, span: .thisEvent, commit: false)
        }
        try store.commit()
    }

    /// Sucht ein Jahr zurueck und drei voraus - EventKit erlaubt hoechstens
    /// vier Jahre je Abfrage, und mehr als 999 Tage Intervall gibt es nicht.
    private func loescheAlte(_ pferd: Horse, _ typ: Horse.EventType) throws {
        let kalender = Calendar.current
        let von = kalender.date(byAdding: .year, value: -1, to: .now) ?? .now
        let bis = kalender.date(byAdding: .day, value: -1,
                                to: kalender.date(byAdding: .year, value: 3, to: .now) ?? .now) ?? .now
        let abfrage = store.predicateForEvents(withStart: von, end: bis, calendars: nil)
        for eintrag in store.events(matching: abfrage)
        where KalenderMarke.gehoertZu(titel: eintrag.title, notiz: eintrag.notes, url: eintrag.url,
                                      pferdID: pferd.id, pferdName: pferd.name, typ: typ) {
            try store.remove(eintrag, span: .thisEvent, commit: false)
        }
    }
}
