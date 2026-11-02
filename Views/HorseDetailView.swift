//
//  HorseDetailView.swift
//  Hippominder
//
//  Autor: Mathias Hubrich & Claude (Anthropic)
//  Erstellt: 24. Januar 2026
//  Geaendert: 12. Februar 2026, 22:00 Uhr
//  Version: 2.0.0
//
//  Beschreibung: Detailansicht eines Pferdes mit Blumen-Timern
//

import SwiftUI

#if os(iOS)
import PhotosUI
import EventKit
import UIKit

struct HorseDetailView: View {
    @Bindable var horse: Horse
    @Environment(\.modelContext) private var modelContext
    @ObservedObject var debugSettings = DebugSettings.shared
    @ObservedObject var globalSettings = GlobalSettings.shared

    @State private var selectedEventType: Horse.EventType?
    @State private var showingDatePicker = false
    @State private var selectedPhotoItem: PhotosPickerItem?
    @State private var showingDebugView = false
    @State private var logoTapCount = 0
    @State private var showingActionSheet = false
    @State private var showingCalendarAlert = false
    @State private var calendarAlertMessage = ""
    @State private var showingEmailPicker = false
    @State private var showingImageCropper = false
    @State private var rawImageData: Data?
    @State private var selectedBackgroundItem: PhotosPickerItem?

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                // Header mit Logo
                Image("hippominder_logo")
                    .resizable()
                    .scaledToFit()
                    .frame(height: 44)
                    #if DEBUG
                    .onTapGesture {
                        logoTapCount += 1
                        if logoTapCount >= 5 {
                            showingDebugView = true
                            logoTapCount = 0
                        }
                        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                            logoTapCount = 0
                        }
                    }
                    #endif
                    .padding(.top, 4)

                // Debug-Indikator
                #if DEBUG
                if debugSettings.timeOffsetDays != 0 {
                    Text("DEBUG: \(debugSettings.simulatedDateString)")
                        .font(.caption)
                        .foregroundColor(.orange)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 2)
                        .background(Color.orange.opacity(0.15))
                        .clipShape(Capsule())
                }
                #endif

                // Pferdename
                Text(horse.name)
                    .font(.largeTitle)
                    .bold()

                // Pferdebild
                ZStack(alignment: .bottomTrailing) {
                    if let image = horse.image {
                        image
                            .resizable()
                            .scaledToFill()
                            .frame(width: 120, height: 120)
                            .clipShape(Circle())
                    } else {
                        Circle()
                            .fill(Color.gray.opacity(0.15))
                            .frame(width: 120, height: 120)
                            .overlay(
                                Image("horse_silhouette")
                                    .resizable()
                                    .scaledToFit()
                                    .frame(width: 60, height: 60)
                                    .opacity(0.2)
                            )
                    }

                    PhotosPicker(selection: $selectedPhotoItem, matching: .images) {
                        ZStack {
                            Circle()
                                .fill(.ultraThinMaterial)
                                .frame(width: 32, height: 32)
                            Image(systemName: "camera.fill")
                                .font(.system(size: 13, weight: .semibold))
                                .foregroundColor(.secondary)
                        }
                        .shadow(color: .black.opacity(0.15), radius: 2, x: 0, y: 1)
                    }
                    .offset(x: 2, y: 2)
                }

                // Darstellung umschalten
                DesignModePicker(mode: Binding(
                    get: { globalSettings.designMode },
                    set: { globalSettings.designMode = $0 }
                ))
                .padding(.horizontal)

                // Die drei Timer - je nach Darstellung
                switch globalSettings.designMode {
                case .glass:
                    ZStack(alignment: .bottomTrailing) {
                        GlassFlowerStage(backgroundImage: horse.backgroundImage) {
                            HStack(alignment: .top, spacing: 4) {
                                ForEach(Horse.EventType.allCases, id: \.self) { eventType in
                                    Button(action: {
                                        selectedEventType = eventType
                                        showingActionSheet = true
                                    }) {
                                        GlassFlowerTimerView(
                                            eventType: eventType,
                                            remainingDays: horse.tageBis(fuer: eventType),
                                            interval: horse.holeIntervall(fuer: eventType),
                                            nextDate: horse.naechsterTermin(fuer: eventType),
                                            tint: globalSettings.glassTint
                                        )
                                    }
                                    .buttonStyle(.plain)
                                    .accessibilityIdentifier("flower_\(eventType.rawValue)")
                                }
                            }
                            .padding(.vertical, 16)
                        }
                        .frame(height: 250)

                        // Hintergrundfoto waehlen
                        PhotosPicker(selection: $selectedBackgroundItem, matching: .images) {
                            HStack(spacing: 5) {
                                Image(systemName: "photo.on.rectangle.angled")
                                    .font(.system(size: 12, weight: .semibold))
                                Text("Hintergrund")
                                    .font(.caption2.weight(.semibold))
                            }
                            .foregroundStyle(.white)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 6)
                            .background {
                                Capsule().fill(.ultraThinMaterial)
                                    .overlay { Capsule().fill(.white.opacity(0.12)) }
                                    .overlay { Capsule().strokeBorder(.white.opacity(0.45), lineWidth: 0.5) }
                            }
                        }
                        .padding(10)
                    }
                    .padding(.horizontal, 12)

                case .classic:
                    // Das LCD des Original-Geraets
                    LCDPanel(alarmActive: hasDueEvent) {
                        HStack(alignment: .top, spacing: 8) {
                            ForEach(Horse.EventType.allCases, id: \.self) { eventType in
                                Button(action: {
                                    selectedEventType = eventType
                                    showingActionSheet = true
                                }) {
                                    LCDFlowerTimerView(
                                        eventType: eventType,
                                        remainingDays: horse.tageBis(fuer: eventType),
                                        interval: horse.holeIntervall(fuer: eventType),
                                        nextDate: horse.naechsterTermin(fuer: eventType)
                                    )
                                }
                                .buttonStyle(.plain)
                                .accessibilityIdentifier("flower_\(eventType.rawValue)")
                            }
                        }
                    }
                    .padding(.horizontal, 12)

                case .blume:
                    // Mathias' vorgerenderte Icon-Composer-Blumen
                    HStack(alignment: .top, spacing: 20) {
                        ForEach(Horse.EventType.allCases, id: \.self) { eventType in
                            Button(action: {
                                selectedEventType = eventType
                                showingActionSheet = true
                            }) {
                                FlowerTimerView(
                                    eventType: eventType,
                                    remainingDays: horse.tageBis(fuer: eventType),
                                    interval: horse.holeIntervall(fuer: eventType),
                                    nextDate: horse.naechsterTermin(fuer: eventType),
                                    colorScheme: globalSettings.flowerColorScheme
                                )
                                .frame(width: 100)
                            }
                            .buttonStyle(.plain)
                            .accessibilityIdentifier("flower_\(eventType.rawValue)")
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 8)
                }

                // Einstellungen
                VStack(spacing: 14) {
                    HStack {
                        Image(systemName: "bell.fill")
                            .foregroundColor(.secondary)
                            .frame(width: 20)

                        Text("Erinnerung \(horse.benachrichtigungTageVorher) Tage vor Termin")
                            .font(.callout)

                        Spacer()

                        HardwareStyleButtons(value: Binding(
                            get: { horse.benachrichtigungTageVorher },
                            set: { horse.benachrichtigungTageVorher = max(1, $0) }
                        ), identifier: "reminder")
                    }
                    .padding(.horizontal)

                    ForEach(Horse.EventType.allCases, id: \.self) { eventType in
                        HStack {
                            // Template-Assets: ohne Farbe waere das Symbol blau
                            Image(eventType.symbol)
                                .resizable()
                                .scaledToFit()
                                .foregroundStyle(.primary)
                                .frame(width: 20, height: 20)
                                .opacity(0.7)

                            Text("\(eventType.localizedName)-\(String(localized: "Intervall"))")
                                .font(.callout)

                            Spacer()

                            HardwareStyleButtons(value: Binding(
                                get: { horse.holeIntervall(fuer: eventType) },
                                set: { horse.setzeIntervall(max(1, $0), fuer: eventType) }
                            ), identifier: "interval_\(eventType.rawValue)")
                        }
                        .padding(.horizontal)
                    }
                }

                // Benachrichtigungen verwalten
                VStack(spacing: 10) {
                    NavigationLink(destination: NotificationSettingsView(horse: horse)) {
                        DesignedActionButton(
                            title: "Benachrichtigungen verwalten",
                            systemImage: "bell.badge.fill",
                            mode: globalSettings.designMode,
                            subtitle: notifySubtitle,
                            trailingChevron: true
                        )
                    }
                    .buttonStyle(.plain)
                    .accessibilityIdentifier("manageNotifications")

                    DesignedActionButton(
                        title: "Termine im Kalender speichern",
                        systemImage: "calendar.badge.plus",
                        mode: globalSettings.designMode,
                        action: { saveToCalendar() }
                    )
                    .accessibilityIdentifier("saveCalendar")

                    DesignedActionButton(
                        title: "Erinnerung per E-Mail senden",
                        systemImage: "envelope.fill",
                        mode: globalSettings.designMode,
                        action: { showingEmailPicker = true }
                    )
                    .accessibilityIdentifier("sendEmail")
                }
                .padding(.horizontal)
                .padding(.bottom, 32)
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        // Erinnerungs-Vorlauf oder Intervalle geaendert -> Benachrichtigungen neu planen
        .onChange(of: horse.benachrichtigungTageVorher) { _, _ in rescheduleNotifications() }
        .onChange(of: horse.hufschmiedIntervall) { _, _ in rescheduleNotifications() }
        .onChange(of: horse.impfungIntervall) { _, _ in rescheduleNotifications() }
        .onChange(of: horse.wurmkurIntervall) { _, _ in rescheduleNotifications() }
        .confirmationDialog(
            selectedEventType?.localizedName ?? "Termin",
            isPresented: $showingActionSheet,
            titleVisibility: .visible
        ) {
            if let eventType = selectedEventType {
                Button("War heute da") {
                    horse.setzeTermin(debugSettings.simulatedDate, fuer: eventType)
                    NotificationService.shared.scheduleAllNotifications(for: horse)
                    WatchSyncService.shared.syncToWatch()
                }
                Button("Datum manuell wählen") {
                    showingDatePicker = true
                }
                Button("Abbrechen", role: .cancel) { }
            }
        }
        .sheet(isPresented: $showingDatePicker) {
            if let eventType = selectedEventType {
                DatePickerSheet(
                    title: "\(eventType.localizedName) \(String(localized: "Termin"))",
                    date: Binding(
                        get: { horse.holeTermin(fuer: eventType) },
                        set: {
                            horse.setzeTermin($0, fuer: eventType)
                            NotificationService.shared.scheduleAllNotifications(for: horse)
                            WatchSyncService.shared.syncToWatch()
                        }
                    ),
                    isPresented: $showingDatePicker
                )
            }
        }
        .onChange(of: selectedPhotoItem) { _, newItem in
            Task {
                if let data = try? await newItem?.loadTransferable(type: Data.self) {
                    rawImageData = data
                    showingImageCropper = true
                }
            }
        }
        .onChange(of: selectedBackgroundItem) { _, newItem in
            Task {
                guard let data = try? await newItem?.loadTransferable(type: Data.self) else { return }
                // Kein Rundschnitt: das Hintergrundfoto bleibt rechteckig und gross.
                // Skalieren laeuft abseits des Main Threads, sonst ruckelt die UI.
                let prepared = await Task.detached(priority: .userInitiated) {
                    BackgroundPhoto.downscaledJPEG(from: data) ?? data
                }.value
                horse.backgroundImageData = prepared
            }
        }
        .sheet(isPresented: $showingImageCropper) {
            if let data = rawImageData, let uiImage = UIImage(data: data) {
                ImageCropperView(image: uiImage) { croppedImage in
                    if let jpegData = croppedImage.jpegData(compressionQuality: 0.8) {
                        horse.imageData = jpegData
                    }
                    showingImageCropper = false
                }
            }
        }
        .sheet(isPresented: $showingDebugView) {
            DebugTimeView()
        }
        .alert("Kalender", isPresented: $showingCalendarAlert) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(calendarAlertMessage)
        }
        .sheet(isPresented: $showingEmailPicker) {
            EmailTypePickerView(
                horse: horse,
                isPresented: $showingEmailPicker
            )
        }
    }

    // MARK: - Benachrichtigungen neu planen

    private func rescheduleNotifications() {
        NotificationService.shared.scheduleAllNotifications(for: horse)
        WatchSyncService.shared.syncToWatch()
    }

    // MARK: - Aktive Benachrichtigungen zaehlen

    /// Mindestens ein Termin faellig - im Original blinkt dann die Glocke
    private var hasDueEvent: Bool {
        Horse.EventType.allCases.contains { horse.tageBis(fuer: $0) <= 0 }
    }

    private var notifySubtitle: String {
        let count = activeNotifyCount
        if count == 0 { return String(localized: "Keine Kontakte aktiviert") }
        if count == 1 { return String(localized: "1 Kontakt aktiv") }
        return String(localized: "\(count) Kontakte aktiv")
    }

    private var activeNotifyCount: Int {
        let contactSettings = ContactSettings.shared
        let flags: [(Bool, ContactType)] = [
            (horse.notifyHufschmied, .hufschmied),
            (horse.notifyTierarzt, .tierarzt),
            (horse.notifyApotheker, .apotheker),
            (horse.notifyBesitzer, .besitzer),
            (horse.notifyStallbesitzer, .stallbesitzer)
        ]
        return flags.filter { isOn, type in
            isOn && contactSettings.contact(for: type).hasEmail
        }.count
    }

    // MARK: - Kalender-Funktion

    private func saveToCalendar() {
        let eventStore = EKEventStore()

        eventStore.requestFullAccessToEvents { granted, error in
            DispatchQueue.main.async {
                if granted {
                    do {
                        var savedCount = 0
                        var skippedCount = 0

                        for eventType in Horse.EventType.allCases {
                            let eventTitle = "\(horse.name): \(eventType.localizedName)"
                            let eventDate = horse.naechsterTermin(fuer: eventType)

                            let startOfDay = Calendar.current.startOfDay(for: eventDate)
                            let endOfDay = Calendar.current.date(byAdding: .day, value: 1, to: startOfDay)!

                            let predicate = eventStore.predicateForEvents(
                                withStart: startOfDay,
                                end: endOfDay,
                                calendars: nil
                            )
                            let existingEvents = eventStore.events(matching: predicate)
                            let duplicateExists = existingEvents.contains { $0.title == eventTitle }

                            if duplicateExists {
                                skippedCount += 1
                                continue
                            }

                            let event = EKEvent(eventStore: eventStore)
                            event.title = eventTitle
                            event.startDate = startOfDay
                            event.endDate = startOfDay
                            event.isAllDay = true
                            event.calendar = eventStore.defaultCalendarForNewEvents
                            event.notes = "Hippominder Erinnerung für \(horse.name)\nIntervall: \(horse.holeIntervall(fuer: eventType)) Tage"

                            let alarm = EKAlarm(relativeOffset: TimeInterval(-horse.benachrichtigungTageVorher * 24 * 60 * 60))
                            event.addAlarm(alarm)

                            try eventStore.save(event, span: .thisEvent)
                            savedCount += 1
                        }

                        if skippedCount > 0 && savedCount > 0 {
                            calendarAlertMessage = "\(savedCount) Termine gespeichert, \(skippedCount) bereits vorhanden."
                        } else if skippedCount > 0 {
                            calendarAlertMessage = "Alle Termine sind bereits im Kalender vorhanden."
                        } else {
                            calendarAlertMessage = "Alle \(savedCount) Termine wurden als Ganztags-Termine gespeichert!"
                        }
                    } catch {
                        calendarAlertMessage = "Fehler beim Speichern: \(error.localizedDescription)"
                    }
                } else {
                    calendarAlertMessage = "Kein Zugriff auf den Kalender. Bitte in den Einstellungen erlauben."
                }
                showingCalendarAlert = true
            }
        }
    }
}

// MARK: - Hintergrundfoto aufbereiten

/// Eigener Typ statt Methode in der View: so ist das Skalieren garantiert
/// nicht an den Main Actor gebunden.
enum BackgroundPhoto {
    /// Skaliert auf hoechstens 1600px lange Kante. Ohne das landen 12-MP-Fotos
    /// unveraendert in SwiftData.
    static func downscaledJPEG(from data: Data, maxEdge: CGFloat = 1600) -> Data? {
        guard let image = UIImage(data: data) else { return nil }
        let longest = max(image.size.width, image.size.height)
        guard longest > maxEdge else { return image.jpegData(compressionQuality: 0.85) }

        let factor = maxEdge / longest
        let target = CGSize(width: image.size.width * factor, height: image.size.height * factor)
        let renderer = UIGraphicsImageRenderer(size: target)
        let scaled = renderer.image { _ in
            image.draw(in: CGRect(origin: .zero, size: target))
        }
        return scaled.jpegData(compressionQuality: 0.85)
    }
}

// MARK: - Darstellung umschalten

struct DesignModePicker: View {
    @Binding var mode: DesignMode
    @Environment(\.colorScheme) private var colorScheme

    /// Aktive Pille: weiss im Hellen, mittleres Grau im Dunkeln - sonst
    /// steht weisse Schrift auf weissem Grund
    private var activeFill: Color {
        colorScheme == .dark ? Color(white: 0.36) : Color(white: 1.0)
    }

    var body: some View {
        HStack(spacing: 0) {
            ForEach(DesignMode.allCases) { candidate in
                Button {
                    withAnimation(.easeInOut(duration: 0.2)) { mode = candidate }
                } label: {
                    HStack(spacing: 5) {
                        Image(systemName: candidate.icon)
                            .font(.system(size: 11, weight: .semibold))
                        Text(candidate.localizedName)
                            .font(.caption.weight(.semibold))
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 7)
                    .foregroundStyle(mode == candidate ? Color.primary : Color.secondary)
                    .background {
                        if mode == candidate {
                            Capsule()
                                .fill(activeFill)
                                .shadow(color: .black.opacity(0.12), radius: 2, x: 0, y: 1)
                        }
                    }
                }
                .buttonStyle(.plain)
                .accessibilityIdentifier("designMode_\(candidate.rawValue)")
            }
        }
        .padding(3)
        .background(Capsule().fill(Color.gray.opacity(0.14)))
    }
}

// MARK: - Aktionsknopf, passend zur Darstellung

/// Glass: Material mit hellem Rand. Classic: erhabene helle Flaeche mit
/// weichem Schatten - wie die Pillen im urspruenglichen Hardware-Design.
struct DesignedActionButton: View {
    let title: LocalizedStringKey
    let systemImage: String
    let mode: DesignMode
    var subtitle: String?
    var trailingChevron = false
    var action: (() -> Void)?
    @Environment(\.colorScheme) private var colorScheme

    /// Erhabene Flaeche: fast weiss im Hellen, dunkles Grau im Dunkeln -
    /// sonst steht weisse Schrift auf weissem Grund
    private var raisedFill: Color {
        colorScheme == .dark ? Color(white: 0.17) : Color(white: 0.98)
    }
    private var raisedHighlight: Color {
        colorScheme == .dark ? .white.opacity(0.08) : .white.opacity(0.9)
    }
    private var raisedEdge: Color {
        colorScheme == .dark ? .white.opacity(0.12) : .black.opacity(0.06)
    }

    var body: some View {
        if let action {
            Button(action: action) { content }
                .buttonStyle(.plain)
        } else {
            content
        }
    }

    private var content: some View {
        HStack(spacing: 10) {
            Image(systemName: systemImage)
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(.secondary)

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.subheadline.weight(.semibold))
                if let subtitle {
                    Text(subtitle)
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            }

            Spacer(minLength: 0)

            if trailingChevron {
                Image(systemName: "chevron.right")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(.secondary)
            }
        }
        .foregroundStyle(Color.primary)
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.vertical, 13)
        .padding(.horizontal, 18)
        .background(background)
    }

    @ViewBuilder
    private var background: some View {
        switch mode {
        case .glass:
            Capsule()
                .fill(.ultraThinMaterial)
                .overlay { Capsule().strokeBorder(.white.opacity(0.4), lineWidth: 0.5) }
                .shadow(color: .black.opacity(0.08), radius: 3, x: 1, y: 2)
        case .classic, .blume:
            Capsule()
                .fill(raisedFill)
                .overlay {
                    Capsule().fill(
                        LinearGradient(
                            colors: [raisedHighlight, .clear],
                            startPoint: .topLeading,
                            endPoint: .bottom
                        )
                    )
                }
                .overlay { Capsule().strokeBorder(raisedEdge, lineWidth: 0.5) }
                .shadow(color: .black.opacity(0.14), radius: 4, x: 1, y: 2)
        }
    }
}

// MARK: - Benachrichtigungs-Einstellungen

struct NotificationSettingsView: View {
    @Bindable var horse: Horse
    @ObservedObject var contactSettings = ContactSettings.shared
    @State private var showingContacts = false

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                HStack(spacing: 8) {
                    Image(systemName: "info.circle")
                        .foregroundColor(.blue)
                    Text("Wähle aus, welche Kontakte bei fälligen Terminen für \(horse.name) benachrichtigt werden sollen.")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .padding()
                .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12))
                .padding(.horizontal)

                VStack(spacing: 2) {
                    NotifyToggleRow(type: .hufschmied, isOn: $horse.notifyHufschmied)
                    NotifyToggleRow(type: .tierarzt, isOn: $horse.notifyTierarzt)
                    NotifyToggleRow(type: .apotheker, isOn: $horse.notifyApotheker)
                    NotifyToggleRow(type: .besitzer, isOn: $horse.notifyBesitzer)
                    NotifyToggleRow(type: .stallbesitzer, isOn: $horse.notifyStallbesitzer)
                }
                .padding()
                .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16))
                .padding(.horizontal)

                HStack(spacing: 8) {
                    Image(systemName: "person.2.fill")
                        .foregroundColor(.secondary)
                    Text("Kontakte werden global für alle Pferde auf der Hauptseite verwaltet.")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .padding()
                .background(Color.gray.opacity(0.08), in: RoundedRectangle(cornerRadius: 12))
                .padding(.horizontal)

                // Direkt zu den Kontakten, damit niemand erst zur Hauptseite zurueck muss
                Button(action: { showingContacts = true }) {
                    HStack(spacing: 10) {
                        Image(systemName: "person.crop.circle.badge.plus")
                            .font(.system(size: 16, weight: .semibold))
                        Text("Kontakte bearbeiten")
                            .font(.subheadline.weight(.semibold))
                    }
                    .foregroundColor(.primary)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(.ultraThinMaterial, in: Capsule())
                    .overlay(Capsule().fill(Color.blue.opacity(0.08)))
                }
                .buttonStyle(.plain)
                .accessibilityIdentifier("editContacts")
                .padding(.horizontal)

                Spacer()
            }
            .padding(.top, 8)
        }
        .navigationTitle("Benachrichtigungen")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showingContacts) {
            ContactsView()
        }
    }
}

// MARK: - Benachrichtigungs-Toggle Zeile

struct NotifyToggleRow: View {
    let type: ContactType
    @Binding var isOn: Bool
    @ObservedObject var contactSettings = ContactSettings.shared

    private var contact: ContactEntry {
        contactSettings.contact(for: type)
    }

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: type.icon)
                .font(.system(size: 14))
                .foregroundColor(.secondary)
                .frame(width: 20)

            VStack(alignment: .leading, spacing: 1) {
                Text(type.rawValue)
                    .font(.callout)
                if contact.hasEmail {
                    Text(contact.name.isEmpty ? contact.email : "\(contact.name)")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                } else {
                    Text("Kein Kontakt hinterlegt")
                        .font(.caption2)
                        .foregroundColor(.orange)
                }
            }

            Spacer()

            Toggle("", isOn: $isOn)
                .labelsHidden()
                .disabled(!contact.hasEmail)
                .accessibilityIdentifier("notify_\(type.rawValue)")
        }
        .padding(.vertical, 2)
        .opacity(contact.hasEmail ? 1.0 : 0.7)
    }
}

// MARK: - Date Picker Sheet

struct DatePickerSheet: View {
    let title: String
    @Binding var date: Date
    @Binding var isPresented: Bool

    var body: some View {
        NavigationStack {
            VStack {
                DatePicker(
                    "Letzter Termin",
                    selection: $date,
                    displayedComponents: .date
                )
                .datePickerStyle(.graphical)
                .padding()

                Spacer()
            }
            .navigationTitle(title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Fertig") {
                        isPresented = false
                    }
                }
            }
        }
    }
}

#if DEBUG
#Preview {
    NavigationStack {
        HorseDetailView(horse: .preview)
    }
    .modelContainer(for: Horse.self, inMemory: true)
}
#endif

#endif // os(iOS)
