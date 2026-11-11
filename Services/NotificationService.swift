//
//  NotificationService.swift
//  Hippominder
//
//  Autor: Mathias Hubrich & Claude (Anthropic)
//  Erstellt: 24. Januar 2026
//  Geaendert: 12. Februar 2026, 22:00 Uhr
//  Version: 2.0.0
//
//  Beschreibung: Lokale Benachrichtigungen fuer Termine
//

import Foundation
import UserNotifications
import SwiftData

class NotificationService {
    static let shared = NotificationService()

    private init() {}

    /// Schedule a notification for a specific event type
    func scheduleNotification(
        for horse: Horse,
        eventType: Horse.EventType,
        daysBeforeEvent: Int
    ) {
        let center = UNUserNotificationCenter.current()

        // Beide Kennungen loeschen: sonst mahnt die woechentliche
        // Wiederholung weiter, obwohl der Termin eingetragen wurde
        let identifier = "\(horse.id.uuidString)-\(eventType.rawValue)"
        center.removePendingNotificationRequests(
            withIdentifiers: [identifier, Self.overdueIdentifier(identifier)]
        )

        // Calculate next appointment date
        let nextDate = horse.naechsterTermin(fuer: eventType)

        // Calculate notification date (X days before)
        guard let notificationDate = Calendar.current.date(byAdding: .day, value: -daysBeforeEvent, to: nextDate) else {
            return
        }

        let now = Date()

        // Ueberfaellig: weiter erinnern, nicht verstummen. Frueher wurde hier
        // abgebrochen - ausgerechnet dann, wenn der Termin vergessen wurde,
        // kam keine Meldung mehr. Jetzt woechentlich, bis er eingetragen ist.
        guard nextDate > now else {
            scheduleOverdueReminder(for: horse, eventType: eventType, identifier: identifier)
            return
        }

        // Vorlauf-Tag schon vorbei (z.B. Vorlauf 3 Tage, Termin in 2 Tagen) -> naechster 9-Uhr-Zeitpunkt
        var fireDate = notificationDate
        var fireComponents = Calendar.current.dateComponents([.year, .month, .day], from: fireDate)
        fireComponents.hour = 9
        fireComponents.minute = 0
        if let fireAt = Calendar.current.date(from: fireComponents), fireAt <= now {
            fireDate = Calendar.current.date(byAdding: .day, value: 1, to: Calendar.current.startOfDay(for: now)) ?? now
            if let todayNine = Calendar.current.date(bySettingHour: 9, minute: 0, second: 0, of: now), todayNine > now {
                fireDate = todayNine
            }
        }
        let remainingDays = max(0, Calendar.current.dateComponents([.day], from: Calendar.current.startOfDay(for: fireDate), to: Calendar.current.startOfDay(for: nextDate)).day ?? daysBeforeEvent)

        // Create notification content (localized)
        let content = UNMutableNotificationContent()
        content.title = "Hippominder"
        if remainingDays == 0 {
            content.body = "\(horse.name): \(eventType.localizedName) " + String(localized: "heute fällig!")
        } else {
            content.body = "\(horse.name): \(eventType.localizedName) " + String(localized: "in") + " \(remainingDays) " + String(localized: "Tagen fällig!")
        }
        content.sound = .default

        // Create trigger at 9:00 AM on notification day
        var components = Calendar.current.dateComponents([.year, .month, .day], from: fireDate)
        components.hour = 9
        components.minute = 0
        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)

        // Schedule
        let request = UNNotificationRequest(identifier: identifier, content: content, trigger: trigger)
        center.add(request) { error in
            if let error = error {
                print("Error scheduling notification: \(error)")
            }
        }
    }

    /// Woechentliche Erinnerung fuer einen bereits verstrichenen Termin.
    ///
    /// Taeglich waere aufdringlich, einmalig zu wenig: ohne Wiederholung
    /// bliebe es bei einer einzigen Meldung, und wer die wegwischt, hoert
    /// nie wieder davon. Die Wiederholung endet, sobald der Termin
    /// eingetragen wird - dann plant scheduleNotification neu.
    private func scheduleOverdueReminder(
        for horse: Horse,
        eventType: Horse.EventType,
        identifier: String
    ) {
        let center = UNUserNotificationCenter.current()

        let content = UNMutableNotificationContent()
        content.title = "Hippominder"
        content.body = "\(horse.name): \(eventType.localizedName) "
            + String(localized: "ist überfällig")
        content.sound = .default

        // Woechentlich, verankert am naechsten 9-Uhr-Zeitpunkt. Dadurch
        // kommt die erste Meldung innerhalb eines Tages statt erst beim
        // naechsten passenden Wochentag.
        //
        // Frueher stand hier zusaetzlich eine einmalige Meldung fuer genau
        // diesen Zeitpunkt. Vor 9 Uhr traf die aber auf denselben Wochentag
        // wie die Wiederholung - beide feuerten gleichzeitig und es kamen
        // zwei identische Hinweise.
        let now = Date()
        let naechsteNeun = Calendar.current.date(bySettingHour: 9, minute: 0, second: 0, of: now)
            .flatMap { $0 > now ? $0 : Calendar.current.date(byAdding: .day, value: 1, to: $0) }
            ?? now

        var weekly = Calendar.current.dateComponents([.weekday], from: naechsteNeun)
        weekly.hour = 9
        weekly.minute = 0

        center.add(UNNotificationRequest(
            identifier: Self.overdueIdentifier(identifier),
            content: content,
            trigger: UNCalendarNotificationTrigger(dateMatching: weekly, repeats: true)
        ))
    }

    /// Kennung der woechentlichen Wiederholung, abgeleitet von der Hauptmeldung
    static func overdueIdentifier(_ base: String) -> String { base + "-ueberfaellig" }

    // MARK: - Zahl am App-Symbol

    /// Setzt die rote Zahl am App-Symbol auf die Anzahl ueberfaelliger
    /// Termine ueber alle Pferde. So ist vom Startbildschirm aus sichtbar,
    /// dass etwas ansteht, ohne die App zu oeffnen.
    func updateBadge(for horses: [Horse]) {
        let ueberfaellig = horses.reduce(0) { summe, horse in
            summe + Horse.EventType.allCases.filter { horse.tageBis(fuer: $0) <= 0 }.count
        }
        UNUserNotificationCenter.current().setBadgeCount(ueberfaellig) { error in
            if let error {
                print("Error setting badge: \(error)")
            }
        }
    }

    /// Variante fuer Aufrufer, die nur ihren Kontext zur Hand haben -
    /// die Zahl zaehlt immer alle Pferde, nicht nur das gerade bearbeitete.
    @MainActor
    func updateBadge(using context: ModelContext) {
        let descriptor = FetchDescriptor<Horse>()
        guard let horses = try? context.fetch(descriptor) else { return }
        updateBadge(for: horses)
        #if os(iOS)
        AppIconService.aktualisiere(for: horses)
        #endif
    }

    /// Schedule notifications for all event types of a horse
    func scheduleAllNotifications(for horse: Horse) {
        for eventType in Horse.EventType.allCases {
            scheduleNotification(
                for: horse,
                eventType: eventType,
                daysBeforeEvent: horse.benachrichtigungTageVorher
            )
        }
    }

    /// Remove all notifications for a horse
    func removeAllNotifications(for horse: Horse) {
        let center = UNUserNotificationCenter.current()
        let identifiers = Horse.EventType.allCases.flatMap { typ -> [String] in
            let base = "\(horse.id.uuidString)-\(typ.rawValue)"
            return [base, Self.overdueIdentifier(base)]
        }
        center.removePendingNotificationRequests(withIdentifiers: identifiers)
    }

    /// Geplante Benachrichtigungen entfernen, deren Pferd nicht mehr existiert
    /// (z.B. wenn die App direkt nach dem Loeschen beendet wurde)
    func removeOrphanedNotifications(validHorseIDs: [UUID]) {
        let validPrefixes = validHorseIDs.map { $0.uuidString }
        let center = UNUserNotificationCenter.current()
        center.getPendingNotificationRequests { requests in
            let orphaned = requests
                .map(\.identifier)
                .filter { identifier in !validPrefixes.contains { identifier.hasPrefix($0) } }
            if !orphaned.isEmpty {
                center.removePendingNotificationRequests(withIdentifiers: orphaned)
            }
        }
    }

    #if DEBUG
    /// Debug-Hilfe: Berechtigungsstatus und alle geplanten Benachrichtigungen auf die Konsole schreiben
    func debugDumpPending() {
        let center = UNUserNotificationCenter.current()
        center.getNotificationSettings { settings in
            NSLog("NOTIFY_AUTH: %d", settings.authorizationStatus.rawValue)
            center.getPendingNotificationRequests { requests in
                NSLog("NOTIFY_PENDING_COUNT: %d", requests.count)
                for request in requests {
                    var when = "-"
                    if let trigger = request.trigger as? UNCalendarNotificationTrigger,
                       let date = trigger.nextTriggerDate() {
                        when = ISO8601DateFormatter().string(from: date)
                    }
                    NSLog("NOTIFY_PENDING: %@ | %@ | %@", request.identifier, when, request.content.body)
                }
            }
        }
    }
    #endif
}
