//
//  HorseDetailView.swift
//  Hippominder
//
//  Autor: Mathias Hubrich & Claude (Anthropic)
//  Erstellt: 24. Januar 2026
//  Geaendert: 12. Februar 2026, 20:00 Uhr
//  Version: 1.8.0
//
//  Beschreibung: Detailansicht eines Pferdes mit Blumen-Timern
//

import SwiftUI
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
                    // 5x tippen fuer Debug-Menue (nur in Debug-Builds)
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

                // Debug-Indikator (nur in Debug-Builds sichtbar)
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

                // Pferdebild - jetzt oben, antippbar zum Aendern
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

                    // Kamera-Button
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

                // Drei Blumen-Timer in einer Reihe
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

                // Einstellungen - iOS 26: kein Divider, stattdessen Section-Spacing
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

                    // Intervall-Einstellungen
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

                // Benachrichtigungen verwalten - Button zur Unterseite
                NavigationLink(destination: NotificationSettingsView(horse: horse)) {
                    HStack(spacing: 10) {
                        Image(systemName: "bell.badge.fill")
                            .font(.system(size: 16, weight: .semibold))

                        VStack(alignment: .leading, spacing: 2) {
                            Text("Benachrichtigungen verwalten")
                                .font(.subheadline.weight(.semibold))

                            // Kurzinfo: wie viele Kontakte aktiv
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

                // Action Buttons - iOS 26 Capsule-Style
                VStack(spacing: 10) {
                    // Kalender-Button
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
                        .overlay(
                            Capsule().fill(Color.blue.opacity(0.08))
                        )
                    }
                    .buttonStyle(.plain)

                    // E-Mail-Button
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
                        .overlay(
                            Capsule().fill(Color.green.opacity(0.08))
                        )
                    }
                    .buttonStyle(.plain)
                }
                .padding(.horizontal)
                .padding(.bottom, 32)
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .confirmationDialog(
            selectedEventType?.rawValue ?? "Termin",
            isPresented: $showingActionSheet,
            titleVisibility: .visible
        ) {
            if let eventType = selectedEventType {
                Button("War heute da") {
                    horse.setzeTermin(debugSettings.simulatedDate, fuer: eventType)
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
                        set: { horse.setzeTermin($0, fuer: eventType) }
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

    // MARK: - Kalender-Funktion (keine Duplikate, Ganztags-Termine)

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

                            // Pruefen ob bereits ein Termin fuer dieses Pferd und diesen Typ existiert
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

                            // Neuen Ganztags-Termin erstellen
                            let event = EKEvent(eventStore: eventStore)
                            event.title = eventTitle
                            event.startDate = startOfDay
                            event.endDate = startOfDay
                            event.isAllDay = true
                            event.calendar = eventStore.defaultCalendarForNewEvents
                            event.notes = "Hippominder Erinnerung fuer \(horse.name)\nIntervall: \(horse.holeIntervall(fuer: eventType)) Tage"

                            // Alarm X Tage vorher
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

// MARK: - Hardware-Stil Buttons mit Glass Design

struct HardwareStyleButtons: View {
    @Binding var value: Int
    @State private var showingInput = false
    @State private var inputText = ""

    // Dunkles Grau fuer die Buttons
    private let buttonColor = Color(red: 0.35, green: 0.35, blue: 0.35)

    var body: some View {
        HStack(spacing: 6) {
            // Minus Button mit Glass-Hintergrund
            Button(action: {
                if value > 1 { value -= 1 }
            }) {
                ZStack {
                    // Glass-Hintergrund
                    RoundedRectangle(cornerRadius: 8)
                        .fill(.ultraThinMaterial)
                        .frame(width: 44, height: 44)
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(
                                    LinearGradient(
                                        colors: [.white.opacity(0.5), .white.opacity(0.2)],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    ),
                                    lineWidth: 1
                                )
                        )
                        .shadow(color: .black.opacity(0.1), radius: 2, x: 0, y: 1)

                    // Dunkles Grau Kreis mit Minus (Glass-Stil)
                    Circle()
                        .fill(buttonColor)
                        .frame(width: 28, height: 28)
                        .overlay(
                            Circle()
                                .fill(
                                    LinearGradient(
                                        colors: [.white.opacity(0.2), .clear],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                        )
                        .overlay(
                            Image(systemName: "minus")
                                .font(.system(size: 14, weight: .bold))
                                .foregroundColor(.white)
                        )
                        .shadow(color: .black.opacity(0.2), radius: 2, x: 0, y: 1)
                }
            }
            .buttonStyle(.plain)

            // Wert in der Mitte mit Glass-Effekt - ANTIPPBAR (mehr Platz)
            Button(action: {
                inputText = "\(value)"
                showingInput = true
            }) {
                Text("\(value)")
                    .font(.system(size: 18, weight: .medium))
                    .foregroundColor(.primary)
                    .frame(width: 54, height: 44)
                    .background(
                        RoundedRectangle(cornerRadius: 6)
                            .fill(.ultraThinMaterial)
                            .overlay(
                                RoundedRectangle(cornerRadius: 6)
                                    .stroke(.white.opacity(0.3), lineWidth: 0.5)
                            )
                    )
            }
            .buttonStyle(.plain)

            // Plus Button mit Glass-Hintergrund
            Button(action: {
                value += 1
            }) {
                ZStack {
                    // Glass-Hintergrund
                    RoundedRectangle(cornerRadius: 8)
                        .fill(.ultraThinMaterial)
                        .frame(width: 44, height: 44)
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(
                                    LinearGradient(
                                        colors: [.white.opacity(0.5), .white.opacity(0.2)],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    ),
                                    lineWidth: 1
                                )
                        )
                        .shadow(color: .black.opacity(0.1), radius: 2, x: 0, y: 1)

                    // Dunkles Grau Kreis mit Plus (Glass-Stil)
                    Circle()
                        .fill(buttonColor)
                        .frame(width: 28, height: 28)
                        .overlay(
                            Circle()
                                .fill(
                                    LinearGradient(
                                        colors: [.white.opacity(0.2), .clear],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                        )
                        .overlay(
                            Image(systemName: "plus")
                                .font(.system(size: 14, weight: .bold))
                                .foregroundColor(.white)
                        )
                        .shadow(color: .black.opacity(0.2), radius: 2, x: 0, y: 1)
                }
            }
            .buttonStyle(.plain)
        }
        .alert("Wert eingeben", isPresented: $showingInput) {
            TextField("Tage", text: $inputText)
                .keyboardType(.numberPad)
            Button("OK") {
                if let newValue = Int(inputText), newValue > 0 {
                    value = newValue
                }
            }
            Button("Abbrechen", role: .cancel) { }
        }
    }
}

// MARK: - Benachrichtigungs-Einstellungen Unterseite

struct NotificationSettingsView: View {
    @Bindable var horse: Horse
    @ObservedObject var contactSettings = ContactSettings.shared

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Info-Text
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

                // Toggles
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

                // Hinweis auf globale Kontakte
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

// MARK: - Benachrichtigungs-Toggle Zeile (nutzt globale Kontakte)

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

// MARK: - E-Mail Vorlagen

/// Standard-E-Mail-Texte fuer verschiedene Anlaesse
struct EmailTemplates {
    let horse: Horse

    private var dateFormatter: DateFormatter {
        let f = DateFormatter()
        f.dateStyle = .long
        f.locale = Locale(identifier: "de_DE")
        return f
    }

    private var shortDateFormatter: DateFormatter {
        let f = DateFormatter()
        f.dateFormat = "dd.MM.yyyy"
        return f
    }

    // MARK: - Termin-Erinnerung (vor dem Termin)

    func terminErinnerungSubject(fuer typ: Horse.EventType) -> String {
        String(localized: "Terminerinnerung: \(typ.localizedName) für \(horse.name)")
    }

    func terminErinnerungBody(fuer typ: Horse.EventType) -> String {
        let days = horse.tageBis(fuer: typ)
        let nextDate = horse.naechsterTermin(fuer: typ)
        let typName = typ.localizedName

        var text = String(localized: "email.greeting") + "\n\n"

        if days > 0 {
            text += String(localized: "email.reminder.upcoming \(typName) \(horse.name) \(days)") + "\n\n"
        } else if days == 0 {
            text += String(localized: "email.reminder.today \(typName) \(horse.name)") + "\n\n"
        } else {
            text += String(localized: "email.reminder.overdue \(typName) \(horse.name) \(-days)") + "\n\n"
        }

        text += String(localized: "email.duedate \(dateFormatter.string(from: nextDate))") + "\n"
        text += String(localized: "email.interval \(horse.holeIntervall(fuer: typ))") + "\n\n"

        switch typ {
        case .hufschmied:
            text += String(localized: "email.action.farrier") + "\n"
        case .impfung:
            text += String(localized: "email.action.vaccination") + "\n"
        case .wurmkur:
            text += String(localized: "email.action.deworming") + "\n"
        }

        text += "\n" + String(localized: "email.regards")
        return text
    }

    // MARK: - Uebersicht aller Termine

    func uebersichtSubject() -> String {
        String(localized: "Hippominder: Terminübersicht für \(horse.name)")
    }

    func uebersichtBody() -> String {
        var text = String(localized: "email.greeting") + "\n\n"
        text += String(localized: "email.overview.intro \(horse.name)") + "\n\n"

        for typ in Horse.EventType.allCases {
            let days = horse.tageBis(fuer: typ)
            let nextDate = horse.naechsterTermin(fuer: typ)
            let dateStr = dateFormatter.string(from: nextDate)
            let typName = typ.localizedName

            if days < 0 {
                text += "⚠️ \(typName): \(dateStr) — " + String(localized: "email.status.overdue \(-days)") + "\n"
            } else if days == 0 {
                text += "🔴 \(typName): \(dateStr) — " + String(localized: "email.status.today") + "\n"
            } else if days <= 7 {
                text += "🟠 \(typName): \(dateStr) — " + String(localized: "email.status.indays \(days)") + "\n"
            } else {
                text += "🟢 \(typName): \(dateStr) — " + String(localized: "email.status.indays \(days)") + "\n"
            }
        }

        text += "\n" + String(localized: "email.reminderinfo \(horse.benachrichtigungTageVorher)") + "\n"
        text += "\n" + String(localized: "email.regards")
        return text
    }
}

// MARK: - E-Mail Auswahl Sheet

struct EmailTypePickerView: View {
    let horse: Horse
    @Binding var isPresented: Bool
    @State private var showingMailComposer = false
    @State private var selectedSubject = ""
    @State private var selectedBody = ""
    @State private var selectedRecipients: [String] = []
    @State private var mailResult: Result<MFMailComposeResult, Error>?
    @State private var showingAlert = false
    @State private var alertMessage = ""

    @ObservedObject var contactSettings = ContactSettings.shared
    private var templates: EmailTemplates { EmailTemplates(horse: horse) }

    // Notify-Flags aus dem Horse-Modell
    private var notifyFlags: [ContactType: Bool] {
        [
            .apotheker: horse.notifyApotheker,
            .besitzer: horse.notifyBesitzer,
            .hufschmied: horse.notifyHufschmied,
            .stallbesitzer: horse.notifyStallbesitzer,
            .tierarzt: horse.notifyTierarzt
        ]
    }

    // Alle aktiven Kontakte (Toggle an + E-Mail vorhanden)
    private var activeContacts: [ContactEntry] {
        ContactType.allCases.compactMap { type in
            guard notifyFlags[type] == true else { return nil }
            let entry = contactSettings.contact(for: type)
            return entry.hasEmail ? entry : nil
        }
    }

    var body: some View {
        NavigationStack {
            List {
                // Einzelne Termin-Erinnerungen
                Section(header: Text("Termin-Erinnerung senden")) {
                    ForEach(Horse.EventType.allCases, id: \.self) { typ in
                        let days = horse.tageBis(fuer: typ)
                        Button(action: {
                            prepareEmail(
                                subject: templates.terminErinnerungSubject(fuer: typ),
                                body: templates.terminErinnerungBody(fuer: typ),
                                forType: typ
                            )
                        }) {
                            HStack {
                                Image(typ.symbol)
                                    .resizable()
                                    .scaledToFit()
                                    .frame(width: 20, height: 20)
                                    .opacity(0.7)

                                VStack(alignment: .leading, spacing: 2) {
                                    Text("\(typ.localizedName)-\(String(localized: "Erinnerung"))")
                                        .font(.callout)
                                        .foregroundColor(.primary)
                                    if days < 0 {
                                        Text("\(-days) Tage überfällig!")
                                            .font(.caption)
                                            .foregroundColor(.red)
                                    } else if days == 0 {
                                        Text("Heute fällig!")
                                            .font(.caption)
                                            .foregroundColor(.red)
                                    } else {
                                        Text("in \(days) Tagen")
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                    }
                                }

                                Spacer()

                                Image(systemName: "envelope")
                                    .foregroundColor(.blue)
                            }
                        }
                    }
                }

                // Gesamtuebersicht
                Section(header: Text("Gesamtübersicht")) {
                    Button(action: {
                        prepareEmail(
                            subject: templates.uebersichtSubject(),
                            body: templates.uebersichtBody(),
                            forType: nil
                        )
                    }) {
                        HStack {
                            Image(systemName: "list.bullet.clipboard")
                                .frame(width: 20)
                                .foregroundColor(.secondary)

                            VStack(alignment: .leading, spacing: 2) {
                                Text("Alle Termine senden")
                                    .font(.callout)
                                    .foregroundColor(.primary)
                                Text("Übersicht aller fälligen Termine")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }

                            Spacer()

                            Image(systemName: "envelope")
                                .foregroundColor(.blue)
                        }
                    }
                }

                // Aktive Empfaenger
                if !activeContacts.isEmpty {
                    Section(header: Text("Aktive Empfänger")) {
                        ForEach(activeContacts) { contact in
                            HStack {
                                Image(systemName: contact.type.icon)
                                    .foregroundColor(.secondary)
                                    .frame(width: 20)
                                Text(contact.name.isEmpty ? contact.type.rawValue : contact.name)
                                    .font(.callout)
                                Spacer()
                                Text(contact.email)
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                } else {
                    Section {
                        HStack {
                            Image(systemName: "exclamationmark.triangle")
                                .foregroundColor(.orange)
                            Text("Keine Kontakte aktiviert. Bitte auf der Hauptseite unter 'Kontakte' E-Mail-Adressen eintragen.")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                }
            }
            .navigationTitle("E-Mail senden")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Schliessen") {
                        isPresented = false
                    }
                }
            }
            .sheet(isPresented: $showingMailComposer) {
                MailComposeView(
                    recipients: selectedRecipients,
                    subject: selectedSubject,
                    body: selectedBody,
                    result: $mailResult
                )
            }
            .alert("E-Mail", isPresented: $showingAlert) {
                Button("OK", role: .cancel) { }
            } message: {
                Text(alertMessage)
            }
        }
    }

    private func prepareEmail(subject: String, body: String, forType: Horse.EventType?) {
        guard MFMailComposeViewController.canSendMail() else {
            alertMessage = "E-Mail ist auf diesem Geraet nicht konfiguriert."
            showingAlert = true
            return
        }

        // Empfaenger ueber globale Kontakte
        let recipients: [String]
        if let typ = forType {
            recipients = contactSettings.recipients(for: typ, notifyFlags: notifyFlags).map { $0.email }
        } else {
            recipients = activeContacts.map { $0.email }
        }

        // Deduplizieren
        selectedRecipients = Array(Set(recipients))
        selectedSubject = subject
        selectedBody = body
        showingMailComposer = true
    }
}

// MARK: - Mail Composer View

struct MailComposeView: UIViewControllerRepresentable {
    let recipients: [String]
    let subject: String
    let body: String
    @Binding var result: Result<MFMailComposeResult, Error>?
    @Environment(\.dismiss) private var dismiss

    func makeUIViewController(context: Context) -> MFMailComposeViewController {
        let composer = MFMailComposeViewController()
        composer.mailComposeDelegate = context.coordinator
        composer.setToRecipients(recipients)
        composer.setSubject(subject)
        composer.setMessageBody(body, isHTML: false)
        return composer
    }

    func updateUIViewController(_ uiViewController: MFMailComposeViewController, context: Context) {}

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    class Coordinator: NSObject, MFMailComposeViewControllerDelegate {
        let parent: MailComposeView

        init(_ parent: MailComposeView) {
            self.parent = parent
        }

        func mailComposeController(_ controller: MFMailComposeViewController, didFinishWith result: MFMailComposeResult, error: Error?) {
            if let error = error {
                parent.result = .failure(error)
            } else {
                parent.result = .success(result)
            }
            parent.dismiss()
        }
    }
}

// MARK: - Bild-Zuschnitt View (Pinch-to-Zoom + Drag)

struct ImageCropperView: View {
    let image: UIImage
    let onCrop: (UIImage) -> Void
    @Environment(\.dismiss) private var dismiss

    @State private var scale: CGFloat = 1.0
    @State private var lastScale: CGFloat = 1.0
    @State private var offset: CGSize = .zero
    @State private var lastOffset: CGSize = .zero

    private let cropSize: CGFloat = 280

    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                Text("Ausschnitt waehlen")
                    .font(.headline)
                    .padding(.top)

                Text("Verschieben und zoomen zum Zuschneiden")
                    .font(.caption)
                    .foregroundColor(.secondary)

                // Crop-Bereich
                ZStack {
                    // Bild
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFill()
                        .frame(width: cropSize * scale, height: cropSize * scale)
                        .offset(offset)
                        .gesture(
                            DragGesture()
                                .onChanged { value in
                                    offset = CGSize(
                                        width: lastOffset.width + value.translation.width,
                                        height: lastOffset.height + value.translation.height
                                    )
                                }
                                .onEnded { _ in
                                    lastOffset = offset
                                }
                        )
                        .gesture(
                            MagnificationGesture()
                                .onChanged { value in
                                    scale = max(0.5, min(5.0, lastScale * value))
                                }
                                .onEnded { _ in
                                    lastScale = scale
                                }
                        )

                    // Kreis-Maske (alles ausserhalb abdunkeln)
                    Circle()
                        .stroke(Color.white, lineWidth: 2)
                        .frame(width: cropSize, height: cropSize)

                    // Abdunklung
                    Rectangle()
                        .fill(Color.black.opacity(0.4))
                        .frame(width: cropSize + 40, height: cropSize + 40)
                        .mask(
                            ZStack {
                                Rectangle()
                                Circle()
                                    .frame(width: cropSize, height: cropSize)
                                    .blendMode(.destinationOut)
                            }
                            .compositingGroup()
                        )
                        .allowsHitTesting(false)
                }
                .frame(width: cropSize, height: cropSize)
                .clipShape(RoundedRectangle(cornerRadius: 12))

                Spacer()
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Abbrechen") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Fertig") {
                        cropAndSave()
                    }
                    .bold()
                }
            }
        }
    }

    private func cropAndSave() {
        // Render den sichtbaren Bereich als UIImage
        let renderer = UIGraphicsImageRenderer(size: CGSize(width: cropSize, height: cropSize))
        let cropped = renderer.image { ctx in
            // Berechne das Bild im Crop-Bereich
            let imageSize = image.size
            let drawWidth = cropSize * scale
            let drawHeight: CGFloat
            let aspectRatio = imageSize.width / imageSize.height

            if aspectRatio > 1 {
                drawHeight = drawWidth / aspectRatio
            } else {
                drawHeight = drawWidth
            }
            let actualDrawWidth = drawHeight * aspectRatio

            let drawX = (cropSize - actualDrawWidth) / 2 + offset.width
            let drawY = (cropSize - drawHeight) / 2 + offset.height

            image.draw(in: CGRect(x: drawX, y: drawY, width: actualDrawWidth, height: drawHeight))
        }

        // In Kreis zuschneiden
        let circleRenderer = UIGraphicsImageRenderer(size: CGSize(width: cropSize, height: cropSize))
        let circularImage = circleRenderer.image { ctx in
            let rect = CGRect(x: 0, y: 0, width: cropSize, height: cropSize)
            UIBezierPath(ovalIn: rect).addClip()
            cropped.draw(in: rect)
        }

        onCrop(circularImage)
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
