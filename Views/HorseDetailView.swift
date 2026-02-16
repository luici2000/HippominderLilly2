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
import MessageUI

struct HorseDetailView: View {
    @Bindable var horse: Horse
    @Environment(\.modelContext) private var modelContext
    @ObservedObject var debugSettings = DebugSettings.shared

    @State private var selectedEventType: Horse.EventType?
    @State private var showingDatePicker = false
    @State private var selectedPhotoItem: PhotosPickerItem?
    @State private var showingDebugView = false
    @State private var logoTapCount = 0
    @State private var showingActionSheet = false
    @State private var showingCalendarAlert = false
    @State private var calendarAlertMessage = ""
    @State private var showingEmailPicker = false
    @State private var mailResult: Result<MFMailComposeResult, Error>?
    @State private var showingImageCropper = false
    @State private var rawImageData: Data?

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

                // Drei Blumen-Timer
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
                                colorScheme: GlobalSettings.shared.flowerColorScheme
                            )
                            .frame(width: 100)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 8)

                // Einstellungen
                VStack(spacing: 14) {
                    HStack {
                        Image(systemName: "bell.fill")
                            .foregroundColor(.orange)
                            .frame(width: 20)

                        Text("Erinnerung \(horse.benachrichtigungTageVorher) Tage vor Termin")
                            .font(.callout)

                        Spacer()

                        HardwareStyleButtons(value: Binding(
                            get: { horse.benachrichtigungTageVorher },
                            set: { horse.benachrichtigungTageVorher = max(1, $0) }
                        ))
                    }
                    .padding(.horizontal)

                    ForEach(Horse.EventType.allCases, id: \.self) { eventType in
                        HStack {
                            Image(eventType.symbol)
                                .resizable()
                                .scaledToFit()
                                .frame(width: 20, height: 20)
                                .opacity(0.7)

                            Text("\(eventType.localizedName)-\(String(localized: "Intervall"))")
                                .font(.callout)

                            Spacer()

                            HardwareStyleButtons(value: Binding(
                                get: { horse.holeIntervall(fuer: eventType) },
                                set: { horse.setzeIntervall(max(1, $0), fuer: eventType) }
                            ))
                        }
                        .padding(.horizontal)
                    }
                }

                // Benachrichtigungen verwalten
                NavigationLink(destination: NotificationSettingsView(horse: horse)) {
                    HStack(spacing: 10) {
                        Image(systemName: "bell.badge.fill")
                            .font(.system(size: 16, weight: .semibold))

                        VStack(alignment: .leading, spacing: 2) {
                            Text("Benachrichtigungen verwalten")
                                .font(.subheadline.weight(.semibold))

                            let activeCount = activeNotifyCount
                            if activeCount > 0 {
                                Text("\(activeCount) Kontakt\(activeCount == 1 ? "" : "e") aktiv")
                                    .font(.caption2)
                                    .foregroundColor(.secondary)
                            } else {
                                Text("Keine Kontakte aktiviert")
                                    .font(.caption2)
                                    .foregroundColor(.orange)
                            }
                        }

                        Spacer()

                        Image(systemName: "chevron.right")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundColor(.secondary)
                    }
                    .foregroundColor(.primary)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .padding(.horizontal, 20)
                    .background(.ultraThinMaterial, in: Capsule())
                    .overlay(
                        Capsule().fill(Color.purple.opacity(0.08))
                    )
                }
                .buttonStyle(.plain)
                .padding(.horizontal)

                // Action Buttons
                VStack(spacing: 10) {
                    Button(action: { saveToCalendar() }) {
                        HStack(spacing: 10) {
                            Image(systemName: "calendar.badge.plus")
                                .font(.system(size: 16, weight: .semibold))
                            Text("Termine im Kalender speichern")
                                .font(.subheadline.weight(.semibold))
                        }
                        .foregroundColor(.primary)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(.ultraThinMaterial, in: Capsule())
                        .overlay(Capsule().fill(Color.blue.opacity(0.08)))
                    }
                    .buttonStyle(.plain)

                    Button(action: { showingEmailPicker = true }) {
                        HStack(spacing: 10) {
                            Image(systemName: "envelope.fill")
                                .font(.system(size: 16, weight: .semibold))
                            Text("Erinnerung per E-Mail senden")
                                .font(.subheadline.weight(.semibold))
                        }
                        .foregroundColor(.primary)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(.ultraThinMaterial, in: Capsule())
                        .overlay(Capsule().fill(Color.green.opacity(0.08)))
                    }
                    .buttonStyle(.plain)
                }
                .padding(.horizontal)
                .padding(.bottom, 32)
            }
        }
        .navigationBarTitleDisplayMode(.inline)
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

    // MARK: - Aktive Benachrichtigungen zaehlen

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

// MARK: - Benachrichtigungs-Einstellungen

struct NotificationSettingsView: View {
    @Bindable var horse: Horse
    @ObservedObject var contactSettings = ContactSettings.shared

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

                Spacer()
            }
            .padding(.top, 8)
        }
        .navigationTitle("Benachrichtigungen")
        .navigationBarTitleDisplayMode(.inline)
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
        }
        .padding(.vertical, 2)
        .opacity(contact.hasEmail ? 1.0 : 0.5)
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
