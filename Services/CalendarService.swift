//
//  CalendarService.swift
//  Hippominder
//
//  Autor: Mathias Hubrich & Claude (Anthropic)
//  Erstellt: 24. Januar 2026
//  Geaendert: 25. Januar 2026, 12:00 Uhr
//  Version: 1.1.0
//
//  Beschreibung: Kalender-Integration fuer Termine
//

import Foundation
import EventKit

@MainActor
class CalendarService {
    static let shared = CalendarService()

    private let eventStore = EKEventStore()
    private var hasAccess = false

    private init() {}

    // MARK: - Zugriffsanfrage

    func requestAccess() async -> Bool {
        if #available(iOS 17.0, *) {
            do {
                hasAccess = try await eventStore.requestFullAccessToEvents()
                return hasAccess
            } catch {
                print("Calendar access error: \(error)")
                return false
            }
        } else {
            let granted = await withCheckedContinuation { continuation in
                eventStore.requestAccess(to: .event) { granted, _ in
                    continuation.resume(returning: granted)
                }
            }
            hasAccess = granted
            return granted
        }
    }

    // MARK: - Event erstellen

    func addEvent(
        for horse: Horse,
        eventType: Horse.EventType
    ) async -> Bool {
        if !hasAccess {
            let granted = await requestAccess()
            guard granted else { return false }
        }

        let nextDate = horse.naechsterTermin(fuer: eventType)
        let eventIdentifier = "\(horse.id.uuidString)-\(eventType.rawValue)"

        // Bestehenden Event entfernen
        await removeEvent(identifier: eventIdentifier)

        // Neuen Event erstellen
        let event = EKEvent(eventStore: eventStore)
        event.title = "\(horse.name) - \(eventType.rawValue)"
        event.startDate = nextDate
        event.endDate = Calendar.current.date(byAdding: .hour, value: 1, to: nextDate)
        event.calendar = eventStore.defaultCalendarForNewEvents
        event.notes = "Hippominder Erinnerung"

        // Erinnerung hinzufuegen
        let alarm = EKAlarm(relativeOffset: -TimeInterval(horse.benachrichtigungTageVorher * 24 * 60 * 60))
        event.addAlarm(alarm)

        do {
            try eventStore.save(event, span: .thisEvent)
            UserDefaults.standard.set(event.eventIdentifier, forKey: eventIdentifier)
            return true
        } catch {
            print("Error saving calendar event: \(error)")
            return false
        }
    }

    // MARK: - Event entfernen

    func removeEvent(identifier: String) async {
        guard hasAccess else { return }

        if let eventId = UserDefaults.standard.string(forKey: identifier),
           let event = eventStore.event(withIdentifier: eventId) {
            do {
                try eventStore.remove(event, span: .thisEvent)
                UserDefaults.standard.removeObject(forKey: identifier)
            } catch {
                print("Error removing calendar event: \(error)")
            }
        }
    }

    // MARK: - Alle Events fuer ein Pferd

    func addAllEvents(for horse: Horse) async {
        for eventType in Horse.EventType.allCases {
            _ = await addEvent(for: horse, eventType: eventType)
        }
    }

    func removeAllEvents(for horse: Horse) async {
        for eventType in Horse.EventType.allCases {
            let identifier = "\(horse.id.uuidString)-\(eventType.rawValue)"
            await removeEvent(identifier: identifier)
        }
    }
}
