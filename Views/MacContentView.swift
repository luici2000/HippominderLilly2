//
//  MacContentView.swift
//  Hippominder
//
//  Autor: Mathias Hubrich & Claude (Anthropic)
//  Erstellt: 13. Februar 2026
//  Geaendert: 16. Februar 2026
//  Version: 2.0.0
//
//  Beschreibung: macOS-spezifische Hauptansicht mit Sidebar-Navigation
//  Fenstergroesse ist begrenzt (nicht endlos vergroesserbar)
//  Jetzt mit vollem Feature-Umfang: Foto-Picker, Kalender, Debug, E-Mail
//

#if os(macOS)
import SwiftUI
import SwiftData
import PhotosUI
import EventKit
import AppKit
import UniformTypeIdentifiers

struct MacContentView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var horses: [Horse]
    @ObservedObject var globalSettings = GlobalSettings.shared
    @ObservedObject var storeManager = StoreManager.shared
    @ObservedObject var debugSettings = DebugSettings.shared

    @State private var selectedHorse: Horse?
    @State private var showingAddHorse = false
    @State private var showingContacts = false
    @State private var showingBetaInfo = false
    @State private var showingPaywall = false
    @State private var logoTapCount = 0

    var body: some View {
        NavigationSplitView {
            // Sidebar: Pferdeliste
            VStack(spacing: 0) {
                // Header
                HStack {
                    Image("hippominder_logo")
                        .resizable()
                        .scaledToFit()
                        .frame(height: 32)
                        .onTapGesture {
                            logoTapCount += 1
                            if logoTapCount >= 5 {
                                showingBetaInfo = true
                                logoTapCount = 0
                            }
                            DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                                logoTapCount = 0
                            }
                        }

                    Spacer()

                    // Farbschema
                    HStack(spacing: 6) {
                        ForEach(FlowerColorScheme.allCases) { scheme in
                            Button(action: {
                                withAnimation(.easeInOut(duration: 0.2)) {
                                    globalSettings.flowerColorScheme = scheme
                                }
                            }) {
                                Circle()
                                    .fill(scheme.strongColor)
                                    .frame(width: globalSettings.flowerColorScheme == scheme ? 14 : 10,
                                           height: globalSettings.flowerColorScheme == scheme ? 14 : 10)
                                    .opacity(globalSettings.flowerColorScheme == scheme ? 1.0 : 0.4)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 8)

                // Debug-Anzeige
                #if DEBUG
                if debugSettings.timeOffsetDays != 0 {
                    Text("DEBUG: \(debugSettings.simulatedDateString)")
                        .font(.caption)
                        .foregroundColor(.orange)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 2)
                        .background(Color.orange.opacity(0.2))
                        .cornerRadius(4)
                        .padding(.bottom, 4)
                }
                #endif

                Divider()

                if horses.isEmpty {
                    VStack(spacing: 12) {
                        Spacer()
                        Image("horse_silhouette")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 50, height: 50)
                            .opacity(0.3)
                        Text("Noch keine Pferde")
                            .font(.headline)
                            .foregroundColor(.gray)
                        Button("Pferd hinzufügen") {
                            showingAddHorse = true
                        }
                        Spacer()
                    }
                    .frame(maxWidth: .infinity)
                } else {
                    List(horses, selection: $selectedHorse) { horse in
                        MacHorseRow(horse: horse)
                            .tag(horse)
                            .contextMenu {
                                Button(role: .destructive) {
                                    if selectedHorse?.id == horse.id {
                                        selectedHorse = nil
                                    }
                                    modelContext.delete(horse)
                                } label: {
                                    Label("Pferd löschen", systemImage: "trash")
                                }
                            }
                    }
                    .listStyle(.sidebar)
                }
            }
            .navigationSplitViewColumnWidth(min: 220, ideal: 260, max: 320)
            .toolbar {
                ToolbarItem(placement: .automatic) {
                    Button(action: { showingContacts = true }) {
                        Label("Kontakte", systemImage: "person.2.fill")
                    }
                }
                ToolbarItem(placement: .automatic) {
                    Button(action: {
                        if storeManager.canAddHorse(currentCount: horses.count) {
                            showingAddHorse = true
                        } else {
                            showingPaywall = true
                        }
                    }) {
                        Label("Pferd hinzufügen", systemImage: "plus")
                    }
                }
            }
        } detail: {
            // Detail: Ausgewaehltes Pferd
            if let horse = selectedHorse {
                MacHorseDetailView(horse: horse)
            } else {
                VStack(spacing: 12) {
                    Image("hippominder_logo")
                        .resizable()
                        .scaledToFit()
                        .frame(height: 60)
                        .opacity(0.3)
                    Text("Wähle ein Pferd aus der Liste")
                        .font(.title3)
                        .foregroundColor(.secondary)
                }
            }
        }
        .sheet(isPresented: $showingAddHorse) {
            MacAddHorseView()
                .frame(width: 450, height: 450)
        }
        .sheet(isPresented: $showingContacts) {
            ContactsView()
                .frame(width: 500, height: 450)
        }
        .sheet(isPresented: $showingBetaInfo) {
            BetaInfoView()
                .frame(width: 500, height: 500)
        }
        .sheet(isPresented: $showingPaywall) {
            PaywallView()
                .frame(width: 400, height: 500)
        }
    }
}

// MARK: - Pferde-Zeile (Mac)

struct MacHorseRow: View {
    let horse: Horse

    private var nextEvent: (type: Horse.EventType, days: Int) {
        let events: [(Horse.EventType, Int)] = [
            (.hufschmied, horse.tageBisHufschmied),
            (.impfung, horse.tageBisImpfung),
            (.wurmkur, horse.tageBisWurmkur)
        ]
        return events.min(by: { $0.1 < $1.1 }).map { (type: $0.0, days: $0.1) } ?? (.hufschmied, 0)
    }

    var body: some View {
        HStack(spacing: 10) {
            // Pferdebild
            if let image = horse.image {
                image
                    .resizable()
                    .scaledToFill()
                    .frame(width: 36, height: 36)
                    .clipShape(Circle())
            } else {
                Circle()
                    .fill(Color.gray.opacity(0.15))
                    .frame(width: 36, height: 36)
                    .overlay(
                        Image("horse_silhouette")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 20, height: 20)
                            .opacity(0.4)
                    )
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(horse.name)
                    .font(.body.bold())

                HStack(spacing: 3) {
                    Image(systemName: nextEvent.type.systemSymbol)
                        .font(.system(size: 9))
                    Text(nextEvent.days <= 0 ? "\(-nextEvent.days)d ueber" : "in \(nextEvent.days)d")
                        .font(.caption)
                }
                .foregroundColor(colorForDays(nextEvent.days))
            }

            Spacer()

            // Status-Punkte
            HStack(spacing: 4) {
                ForEach(Horse.EventType.allCases, id: \.self) { eventType in
                    Circle()
                        .fill(colorForDays(horse.tageBis(fuer: eventType)))
                        .frame(width: 7, height: 7)
                }
            }
        }
        .padding(.vertical, 2)
    }

    private func colorForDays(_ days: Int) -> Color {
        if days <= 0 { return .red }
        if days <= 7 { return .red }
        if days <= 14 { return .orange }
        return .green
    }
}

// MARK: - Detail-Ansicht (Mac) - Voller Feature-Umfang wie iOS

struct MacHorseDetailView: View {
    @Bindable var horse: Horse
    @ObservedObject var globalSettings = GlobalSettings.shared
    @ObservedObject var debugSettings = DebugSettings.shared

    @State private var selectedEventType: Horse.EventType?
    @State private var showingDatePicker = false
    @State private var showingImageCropper = false
    @State private var rawNSImage: NSImage?
    @State private var isLoadingPhoto = false
    @State private var showingPhotoPicker = false
    @State private var isDropTargeted = false
    @State private var showingCalendarAlert = false
    @State private var calendarAlertMessage = ""
    @State private var showingNotificationSettings = false

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Pferdename + Bild mit Foto-Picker
                HStack(spacing: 16) {
                    ZStack(alignment: .bottomTrailing) {
                        if let image = horse.image {
                            image
                                .resizable()
                                .scaledToFill()
                                .frame(width: 80, height: 80)
                                .clipShape(Circle())
                        } else {
                            Circle()
                                .fill(Color.gray.opacity(0.1))
                                .frame(width: 80, height: 80)
                                .overlay(
                                    Image("horse_silhouette")
                                        .resizable()
                                        .scaledToFit()
                                        .frame(width: 40, height: 40)
                                        .opacity(0.3)
                                )
                        }

                        // Drop highlight
                        if isDropTargeted {
                            Circle()
                                .stroke(Color.accentColor, lineWidth: 3)
                                .frame(width: 80, height: 80)
                        }

                        if isLoadingPhoto {
                            Circle()
                                .fill(Color.black.opacity(0.3))
                                .frame(width: 80, height: 80)
                                .overlay(
                                    ProgressView()
                                        .scaleEffect(0.8)
                                        .tint(.white)
                                )
                        }

                        // Dropdown menu for photo sources
                        Menu {
                            Button {
                                openImageFromFinder()
                            } label: {
                                Label("Bild wählen…", systemImage: "folder")
                            }

                            Button {
                                showingPhotoPicker = true
                            } label: {
                                Label("Fotos-Mediathek", systemImage: "photo.on.rectangle")
                            }

                            if horse.imageData != nil {
                                Divider()
                                Button(role: .destructive) {
                                    horse.imageData = nil
                                } label: {
                                    Label("Foto entfernen", systemImage: "trash")
                                }
                            }
                        } label: {
                            ZStack {
                                Circle()
                                    .fill(Color(nsColor: .controlBackgroundColor))
                                    .frame(width: 28, height: 28)
                                Image(systemName: "camera.fill")
                                    .font(.system(size: 11, weight: .semibold))
                                    .foregroundColor(.secondary)
                            }
                            .shadow(color: .black.opacity(0.15), radius: 2, x: 0, y: 1)
                        }
                        .menuStyle(.borderlessButton)
                        .menuIndicator(.hidden)
                        .frame(width: 28, height: 28)
                        .offset(x: 2, y: 2)
                        .disabled(isLoadingPhoto)
                    }
                    // Drag & Drop support
                    .onDrop(of: [.image, .fileURL], isTargeted: $isDropTargeted) { providers in
                        handleImageDrop(providers: providers)
                        return true
                    }

                    VStack(alignment: .leading, spacing: 4) {
                        Text(horse.name)
                            .font(.largeTitle.bold())

                        HStack(spacing: 4) {
                            Image(systemName: "bell.fill")
                                .font(.caption)
                                .foregroundColor(.orange)
                            Text("Erinnerung \(horse.benachrichtigungTageVorher) Tage vorher")
                                .font(.caption)
                                .foregroundColor(.secondary)

                            Stepper("", value: Binding(
                                get: { horse.benachrichtigungTageVorher },
                                set: { horse.benachrichtigungTageVorher = max(1, $0) }
                            ), in: 1...30)
                            .labelsHidden()
                        }
                    }

                    Spacer()
                }
                .padding(.horizontal, 24)

                // Debug-Anzeige
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

                Divider()

                // Timer-Karten
                HStack(alignment: .top, spacing: 16) {
                    ForEach(Horse.EventType.allCases, id: \.self) { eventType in
                        MacTimerCard(
                            horse: horse,
                            eventType: eventType,
                            colorScheme: globalSettings.flowerColorScheme,
                            onWarHeuteDa: {
                                horse.setzeTermin(debugSettings.simulatedDate, fuer: eventType)
                                NotificationService.shared.scheduleAllNotifications(for: horse)
                            },
                            onDatumWaehlen: {
                                selectedEventType = eventType
                                showingDatePicker = true
                            }
                        )
                    }
                }
                .padding(.horizontal, 24)

                Divider()

                // Intervall-Einstellungen
                VStack(alignment: .leading, spacing: 12) {
                    Text("Intervalle")
                        .font(.headline)

                    ForEach(Horse.EventType.allCases, id: \.self) { eventType in
                        HStack {
                            Image(systemName: eventType.systemSymbol)
                                .frame(width: 20)
                                .foregroundColor(.secondary)
                            Text(eventType.localizedName)
                                .frame(width: 100, alignment: .leading)

                            Stepper(
                                "\(horse.holeIntervall(fuer: eventType)) Tage",
                                value: Binding(
                                    get: { horse.holeIntervall(fuer: eventType) },
                                    set: { horse.setzeIntervall(max(1, $0), fuer: eventType) }
                                ),
                                in: 1...365
                            )
                        }
                    }
                }
                .padding(.horizontal, 24)

                Divider()

                // Action Buttons
                VStack(spacing: 10) {
                    // Benachrichtigungen verwalten
                    Button(action: { showingNotificationSettings = true }) {
                        HStack(spacing: 10) {
                            Image(systemName: "bell.badge.fill")
                                .font(.system(size: 14, weight: .semibold))
                            VStack(alignment: .leading, spacing: 1) {
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
                                .font(.system(size: 11, weight: .semibold))
                                .foregroundColor(.secondary)
                        }
                        .foregroundColor(.primary)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                        .padding(.horizontal, 16)
                        .background(Color.purple.opacity(0.06), in: RoundedRectangle(cornerRadius: 8))
                    }
                    .buttonStyle(.plain)

                    // Kalender
                    Button(action: { saveToCalendar() }) {
                        HStack(spacing: 10) {
                            Image(systemName: "calendar.badge.plus")
                                .font(.system(size: 14, weight: .semibold))
                            Text("Termine im Kalender speichern")
                                .font(.subheadline.weight(.semibold))
                            Spacer()
                        }
                        .foregroundColor(.primary)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                        .padding(.horizontal, 16)
                        .background(Color.blue.opacity(0.06), in: RoundedRectangle(cornerRadius: 8))
                    }
                    .buttonStyle(.plain)

                    // E-Mail
                    Button(action: { sendEmail() }) {
                        HStack(spacing: 10) {
                            Image(systemName: "envelope.fill")
                                .font(.system(size: 14, weight: .semibold))
                            Text("Erinnerung per E-Mail senden")
                                .font(.subheadline.weight(.semibold))
                            Spacer()
                        }
                        .foregroundColor(.primary)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                        .padding(.horizontal, 16)
                        .background(Color.green.opacity(0.06), in: RoundedRectangle(cornerRadius: 8))
                    }
                    .buttonStyle(.plain)
                }
                .padding(.horizontal, 24)

                Spacer(minLength: 20)
            }
            .padding(.top, 16)
        }
        .frame(minWidth: 400)
        .sheet(isPresented: $showingDatePicker) {
            if let eventType = selectedEventType {
                MacDatePickerSheet(
                    title: "\(eventType.localizedName) Termin",
                    date: Binding(
                        get: { horse.holeTermin(fuer: eventType) },
                        set: {
                            horse.setzeTermin($0, fuer: eventType)
                            NotificationService.shared.scheduleAllNotifications(for: horse)
                        }
                    ),
                    isPresented: $showingDatePicker
                )
                .frame(width: 350, height: 380)
            }
        }
        .sheet(isPresented: $showingNotificationSettings) {
            MacNotificationSettingsView(horse: horse)
                .frame(width: 400, height: 400)
        }
        .sheet(isPresented: $showingImageCropper) {
            if let nsImage = rawNSImage {
                MacImageCropperView(image: nsImage) { croppedImage in
                    // JPEG encoding on background thread to avoid UI freeze
                    Task.detached(priority: .userInitiated) {
                        let tiffData = croppedImage.tiffRepresentation
                        let jpegData: Data? = tiffData.flatMap { data in
                            NSBitmapImageRep(data: data)?.representation(using: .jpeg, properties: [.compressionFactor: 0.8])
                        }
                        await MainActor.run {
                            if let jpegData = jpegData {
                                horse.imageData = jpegData
                            }
                            showingImageCropper = false
                        }
                    }
                }
                .frame(width: 400, height: 450)
            }
        }
        .sheet(isPresented: $showingPhotoPicker, onDismiss: {
            // Open cropper after PHPicker sheet is fully dismissed
            if rawNSImage != nil {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    showingImageCropper = true
                }
            }
        }) {
            MacPHPickerView { nsImage in
                rawNSImage = nsImage
            }
            .frame(width: 600, height: 500)
        }
        .alert("Kalender", isPresented: $showingCalendarAlert) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(calendarAlertMessage)
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

    // MARK: - Bild aus Finder (NSOpenPanel - schnell!)

    private func openImageFromFinder() {
        let panel = NSOpenPanel()
        panel.title = "Bild wählen"
        panel.allowedContentTypes = [.image]
        panel.allowsMultipleSelection = false
        panel.canChooseDirectories = false
        panel.directoryURL = FileManager.default.urls(for: .picturesDirectory, in: .userDomainMask).first

        if panel.runModal() == .OK, let url = panel.url {
            isLoadingPhoto = true
            DispatchQueue.global(qos: .userInitiated).async {
                guard let nsImage = NSImage(contentsOf: url) else {
                    DispatchQueue.main.async { isLoadingPhoto = false }
                    return
                }
                let downscaled = Self.downscaleImage(nsImage, maxDim: 1024)
                DispatchQueue.main.async {
                    isLoadingPhoto = false
                    rawNSImage = downscaled
                    showingImageCropper = true
                }
            }
        }
    }

    // Calls shared helper
    private static func downscaleImage(_ image: NSImage, maxDim: CGFloat) -> NSImage {
        return downscaleNSImage(image, maxDim: maxDim)
    }

    // MARK: - Drag & Drop Image Handler

    private func handleImageDrop(providers: [NSItemProvider]) {
        isLoadingPhoto = true
        for provider in providers {
            // 1. Try loading image data directly (works for images dragged from apps)
            if provider.hasItemConformingToTypeIdentifier("public.image") {
                provider.loadDataRepresentation(forTypeIdentifier: "public.image") { data, _ in
                    DispatchQueue.global(qos: .userInitiated).async {
                        guard let data = data, let nsImage = NSImage(data: data) else {
                            DispatchQueue.main.async { isLoadingPhoto = false }
                            return
                        }
                        let downscaled = Self.downscaleImage(nsImage, maxDim: 1024)
                        DispatchQueue.main.async {
                            isLoadingPhoto = false
                            rawNSImage = downscaled
                            showingImageCropper = true
                        }
                    }
                }
                return
            }
            // 2. Try file URL (for files dragged from Finder)
            if provider.hasItemConformingToTypeIdentifier("public.file-url") {
                provider.loadItem(forTypeIdentifier: "public.file-url", options: nil) { item, _ in
                    DispatchQueue.global(qos: .userInitiated).async {
                        guard let data = item as? Data,
                              let url = URL(dataRepresentation: data, relativeTo: nil),
                              let nsImage = NSImage(contentsOf: url) else {
                            DispatchQueue.main.async { isLoadingPhoto = false }
                            return
                        }
                        let downscaled = Self.downscaleImage(nsImage, maxDim: 1024)
                        DispatchQueue.main.async {
                            isLoadingPhoto = false
                            rawNSImage = downscaled
                            showingImageCropper = true
                        }
                    }
                }
                return
            }
            // 3. Try web URL (for images dragged from browsers)
            if provider.hasItemConformingToTypeIdentifier("public.url") {
                provider.loadItem(forTypeIdentifier: "public.url", options: nil) { item, _ in
                    DispatchQueue.global(qos: .userInitiated).async {
                        guard let data = item as? Data,
                              let url = URL(dataRepresentation: data, relativeTo: nil),
                              let imageData = try? Data(contentsOf: url),
                              let nsImage = NSImage(data: imageData) else {
                            DispatchQueue.main.async { isLoadingPhoto = false }
                            return
                        }
                        let downscaled = downscaleNSImage(nsImage, maxDim: 1024)
                        DispatchQueue.main.async {
                            isLoadingPhoto = false
                            rawNSImage = downscaled
                            showingImageCropper = true
                        }
                    }
                }
                return
            }
        }
        // No supported provider found
        isLoadingPhoto = false
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
                    calendarAlertMessage = "Kein Zugriff auf den Kalender. Bitte in den Systemeinstellungen erlauben."
                }
                showingCalendarAlert = true
            }
        }
    }

    // MARK: - E-Mail via macOS Mail.app

    private func sendEmail() {
        let contactSettings = ContactSettings.shared
        let notifyFlags: [ContactType: Bool] = [
            .apotheker: horse.notifyApotheker,
            .besitzer: horse.notifyBesitzer,
            .hufschmied: horse.notifyHufschmied,
            .stallbesitzer: horse.notifyStallbesitzer,
            .tierarzt: horse.notifyTierarzt
        ]

        let recipients = ContactType.allCases.compactMap { type -> String? in
            guard notifyFlags[type] == true else { return nil }
            let entry = contactSettings.contact(for: type)
            return entry.hasEmail ? entry.email : nil
        }

        let subject = "Hippominder: Terminübersicht für \(horse.name)"
        var body = "Hallo,\n\nHier die aktuelle Terminübersicht für \(horse.name):\n\n"

        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .long

        for typ in Horse.EventType.allCases {
            let days = horse.tageBis(fuer: typ)
            let nextDate = horse.naechsterTermin(fuer: typ)
            let dateStr = dateFormatter.string(from: nextDate)

            if days < 0 {
                body += "⚠️ \(typ.localizedName): \(dateStr) — \(-days) Tage überfällig\n"
            } else if days == 0 {
                body += "🔴 \(typ.localizedName): \(dateStr) — Heute fällig!\n"
            } else {
                body += "🟢 \(typ.localizedName): \(dateStr) — in \(days) Tagen\n"
            }
        }

        body += "\nErinnerung: \(horse.benachrichtigungTageVorher) Tage vorher\n\nViele Grüße"

        let recipientStr = recipients.joined(separator: ",")
        let encodedSubject = subject.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
        let encodedBody = body.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""

        if let url = URL(string: "mailto:\(recipientStr)?subject=\(encodedSubject)&body=\(encodedBody)") {
            NSWorkspace.shared.open(url)
        }
    }
}

// MARK: - Timer-Karte (Mac) - mit "War heute da" und "Datum wählen"

struct MacTimerCard: View {
    let horse: Horse
    let eventType: Horse.EventType
    let colorScheme: FlowerColorScheme
    var onWarHeuteDa: () -> Void
    var onDatumWaehlen: () -> Void

    private var days: Int { horse.tageBis(fuer: eventType) }
    private var interval: Int { horse.holeIntervall(fuer: eventType) }

    private var progress: Double {
        if days <= 0 { return 1.0 }
        return 1.0 - (Double(days) / Double(interval))
    }

    private var statusColor: Color {
        if days <= 0 { return .red }
        if days <= 7 { return .red }
        if days <= 14 { return .orange }
        return .green
    }

    private static let dateFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "dd.MM.yyyy"
        return f
    }()

    var body: some View {
        VStack(spacing: 10) {
            // Blumen-Bild (aus Assets)
            Image(flowerImageName())
                .resizable()
                .scaledToFit()
                .frame(width: 80, height: 80)

            Image(systemName: eventType.systemSymbol)
                .font(.title3)
                .foregroundColor(statusColor)

            Text(eventType.localizedName)
                .font(.caption.bold())

            Text(days <= 0 ? "\(-days) Tage ueberfaellig" : "in \(days) Tagen")
                .font(.caption)
                .foregroundColor(statusColor)

            Text(Self.dateFormatter.string(from: horse.naechsterTermin(fuer: eventType)))
                .font(.caption2)
                .foregroundColor(.secondary)

            // Termin-Buttons
            VStack(spacing: 4) {
                Button("War heute da") {
                    onWarHeuteDa()
                }
                .buttonStyle(.bordered)
                .controlSize(.small)

                Button("Datum wählen") {
                    onDatumWaehlen()
                }
                .buttonStyle(.plain)
                .font(.caption2)
                .foregroundColor(.blue)
            }
        }
        .padding(12)
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.gray.opacity(0.06))
        )
    }

    private func flowerImageName() -> String {
        let filledPetals = horse.gefuellteBlätter(fuer: eventType)
        let base: String
        if filledPetals >= 12 {
            base = "12d"
        } else {
            base = "\(filledPetals)"
        }
        switch colorScheme {
        case .grau: return "flower_\(base)"
        case .hellblau: return "flower_\(base)_hellblau"
        case .orange: return "flower_\(base)_orange"
        }
    }
}

// MARK: - Pferd hinzufuegen (Mac) - mit Foto-Picker

struct MacAddHorseView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    @State private var name = ""
    @State private var imageData: Data?
    @State private var previewImage: NSImage?
    @State private var showingPhotoPicker = false
    @State private var hufschmiedIntervall = 42
    @State private var impfungIntervall = 180
    @State private var wurmkurIntervall = 90

    var body: some View {
        VStack(spacing: 16) {
            Text("Neues Pferd")
                .font(.title2.bold())

            // Foto
            HStack {
                Spacer()
                VStack(spacing: 6) {
                    if let img = previewImage {
                        Image(nsImage: img)
                            .resizable()
                            .scaledToFill()
                            .frame(width: 80, height: 80)
                            .clipShape(Circle())
                    } else {
                        Circle()
                            .fill(Color.gray.opacity(0.15))
                            .frame(width: 80, height: 80)
                            .overlay(
                                Image(systemName: "camera.fill")
                                    .foregroundColor(.gray)
                                    .font(.title2)
                            )
                    }

                    Menu {
                        Button {
                            openImageForNewHorse()
                        } label: {
                            Label("Bild wählen…", systemImage: "folder")
                        }
                        Button {
                            showingPhotoPicker = true
                        } label: {
                            Label("Fotos-Mediathek", systemImage: "photo.on.rectangle")
                        }
                    } label: {
                        Text("Foto auswählen")
                            .font(.caption)
                    }
                    .menuStyle(.borderlessButton)
                    .menuIndicator(.hidden)
                }
                Spacer()
            }

            TextField("Pferdename", text: $name)
                .textFieldStyle(.roundedBorder)
                .padding(.horizontal)

            GroupBox("Intervalle (Tage)") {
                VStack(spacing: 8) {
                    Stepper("Hufschmied: \(hufschmiedIntervall)", value: $hufschmiedIntervall, in: 1...365)
                    Stepper("Impfung: \(impfungIntervall)", value: $impfungIntervall, in: 1...365)
                    Stepper("Wurmkur: \(wurmkurIntervall)", value: $wurmkurIntervall, in: 1...365)
                }
                .padding(4)
            }
            .padding(.horizontal)

            Spacer()

            HStack {
                Button("Abbrechen") { dismiss() }
                    .keyboardShortcut(.cancelAction)

                Spacer()

                Button("Speichern") { saveHorse() }
                    .keyboardShortcut(.defaultAction)
                    .disabled(name.isEmpty)
            }
            .padding(.horizontal)
            .padding(.bottom)
        }
        .padding(.top)
        .sheet(isPresented: $showingPhotoPicker) {
            MacPHPickerView { nsImage in
                previewImage = nsImage
                if let tiffData = nsImage.tiffRepresentation,
                   let bitmap = NSBitmapImageRep(data: tiffData),
                   let jpegData = bitmap.representation(using: .jpeg, properties: [.compressionFactor: 0.8]) {
                    imageData = jpegData
                }
            }
            .frame(width: 600, height: 500)
        }
    }

    private func openImageForNewHorse() {
        let panel = NSOpenPanel()
        panel.title = "Bild wählen"
        panel.allowedContentTypes = [.image]
        panel.allowsMultipleSelection = false
        panel.canChooseDirectories = false
        panel.directoryURL = FileManager.default.urls(for: .picturesDirectory, in: .userDomainMask).first

        if panel.runModal() == .OK, let url = panel.url {
            DispatchQueue.global(qos: .userInitiated).async {
                guard let nsImage = NSImage(contentsOf: url) else { return }
                // Downscale for preview
                let maxDim: CGFloat = 1024
                let size = nsImage.size
                let finalImage: NSImage
                if size.width > maxDim || size.height > maxDim {
                    let ratio = min(maxDim / size.width, maxDim / size.height)
                    let newSize = NSSize(width: size.width * ratio, height: size.height * ratio)
                    let resized = NSImage(size: newSize)
                    resized.lockFocus()
                    nsImage.draw(in: NSRect(origin: .zero, size: newSize),
                                 from: NSRect(origin: .zero, size: size),
                                 operation: .copy, fraction: 1.0)
                    resized.unlockFocus()
                    finalImage = resized
                } else {
                    finalImage = nsImage
                }
                // JPEG encode
                let jpegData: Data? = finalImage.tiffRepresentation.flatMap {
                    NSBitmapImageRep(data: $0)?.representation(using: .jpeg, properties: [.compressionFactor: 0.8])
                }
                DispatchQueue.main.async {
                    previewImage = finalImage
                    imageData = jpegData
                }
            }
        }
    }

    private func saveHorse() {
        let horse = Horse(
            name: name,
            imageData: imageData,
            hufschmiedIntervall: hufschmiedIntervall,
            impfungIntervall: impfungIntervall,
            wurmkurIntervall: wurmkurIntervall
        )
        modelContext.insert(horse)
        dismiss()
    }
}

// MARK: - Date Picker Sheet (Mac)

struct MacDatePickerSheet: View {
    let title: String
    @Binding var date: Date
    @Binding var isPresented: Bool

    var body: some View {
        VStack(spacing: 16) {
            Text(title)
                .font(.headline)
                .padding(.top, 16)

            DatePicker(
                "Letzter Termin",
                selection: $date,
                displayedComponents: .date
            )
            .datePickerStyle(.graphical)
            .padding(.horizontal)

            Spacer()

            HStack {
                Button("Abbrechen") { isPresented = false }
                    .keyboardShortcut(.cancelAction)
                Spacer()
                Button("Fertig") { isPresented = false }
                    .keyboardShortcut(.defaultAction)
            }
            .padding()
        }
    }
}

// MARK: - Benachrichtigungs-Einstellungen (Mac)

struct MacNotificationSettingsView: View {
    @Bindable var horse: Horse
    @ObservedObject var contactSettings = ContactSettings.shared
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(spacing: 16) {
            Text("Benachrichtigungen")
                .font(.title2.bold())
                .padding(.top, 16)

            HStack(spacing: 8) {
                Image(systemName: "info.circle")
                    .foregroundColor(.blue)
                Text("Wähle aus, welche Kontakte bei fälligen Terminen für \(horse.name) benachrichtigt werden sollen.")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding(.horizontal)

            VStack(spacing: 2) {
                MacNotifyToggleRow(type: .hufschmied, isOn: $horse.notifyHufschmied)
                MacNotifyToggleRow(type: .tierarzt, isOn: $horse.notifyTierarzt)
                MacNotifyToggleRow(type: .apotheker, isOn: $horse.notifyApotheker)
                MacNotifyToggleRow(type: .besitzer, isOn: $horse.notifyBesitzer)
                MacNotifyToggleRow(type: .stallbesitzer, isOn: $horse.notifyStallbesitzer)
            }
            .padding(.horizontal)

            HStack(spacing: 8) {
                Image(systemName: "person.2.fill")
                    .foregroundColor(.secondary)
                Text("Kontakte werden global für alle Pferde auf der Hauptseite verwaltet.")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding(.horizontal)

            Spacer()

            HStack {
                Spacer()
                Button("Fertig") { dismiss() }
                    .keyboardShortcut(.defaultAction)
            }
            .padding()
        }
    }
}

struct MacNotifyToggleRow: View {
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
                    Text(contact.name.isEmpty ? contact.email : contact.name)
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
        .padding(.vertical, 4)
        .padding(.horizontal, 8)
        .opacity(contact.hasEmail ? 1.0 : 0.5)
    }
}

// MARK: - PHPickerViewController (schneller Foto-Picker, out-of-process)

struct MacPHPickerView: NSViewControllerRepresentable {
    let onImageSelected: (NSImage) -> Void
    @Environment(\.dismiss) private var dismiss

    func makeNSViewController(context: Context) -> PHPickerViewController {
        var config = PHPickerConfiguration()
        config.filter = .images
        config.selectionLimit = 1
        // .compatible = system delivers a pre-converted smaller image (much faster!)
        config.preferredAssetRepresentationMode = .compatible
        let picker = PHPickerViewController(configuration: config)
        picker.delegate = context.coordinator
        return picker
    }

    func updateNSViewController(_ nsViewController: PHPickerViewController, context: Context) {}

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    class Coordinator: NSObject, PHPickerViewControllerDelegate {
        let parent: MacPHPickerView

        init(_ parent: MacPHPickerView) {
            self.parent = parent
        }

        func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
            guard let result = results.first else {
                parent.dismiss()
                return
            }

            let provider = result.itemProvider

            // loadObject delivers a ready-made NSImage (fastest method)
            if provider.canLoadObject(ofClass: NSImage.self) {
                provider.loadObject(ofClass: NSImage.self) { object, _ in
                    DispatchQueue.global(qos: .userInitiated).async {
                        guard let image = object as? NSImage else {
                            DispatchQueue.main.async { self.parent.dismiss() }
                            return
                        }
                        // Downscale if needed
                        let maxDim: CGFloat = 1024
                        let size = image.size
                        let finalImage: NSImage
                        if size.width > maxDim || size.height > maxDim {
                            let ratio = min(maxDim / size.width, maxDim / size.height)
                            let newSize = NSSize(width: size.width * ratio, height: size.height * ratio)
                            let resized = NSImage(size: newSize)
                            resized.lockFocus()
                            image.draw(in: NSRect(origin: .zero, size: newSize),
                                       from: NSRect(origin: .zero, size: size),
                                       operation: .copy, fraction: 1.0)
                            resized.unlockFocus()
                            finalImage = resized
                        } else {
                            finalImage = image
                        }
                        DispatchQueue.main.async {
                            self.parent.onImageSelected(finalImage)
                            self.parent.dismiss()
                        }
                    }
                }
            } else {
                parent.dismiss()
            }
        }
    }
}

// MARK: - Bild-Zuschnitt (Mac) - mit Zoom und Drag

struct MacImageCropperView: View {
    let image: NSImage
    let onCrop: (NSImage) -> Void
    @Environment(\.dismiss) private var dismiss

    @State private var scale: CGFloat = 1.0
    @State private var lastScale: CGFloat = 1.0
    @State private var offset: CGSize = .zero
    @State private var lastOffset: CGSize = .zero

    private let cropSize: CGFloat = 250

    var body: some View {
        VStack(spacing: 16) {
            Text("Ausschnitt wählen")
                .font(.headline)
                .padding(.top, 16)

            Text("Verschieben und zoomen zum Zuschneiden")
                .font(.caption)
                .foregroundColor(.secondary)

            // Crop area
            ZStack {
                Image(nsImage: image)
                    .resizable()
                    .scaledToFit()
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

                Circle()
                    .stroke(Color.white, lineWidth: 2)
                    .frame(width: cropSize, height: cropSize)

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

            // Zoom-Slider
            HStack {
                Image(systemName: "minus.magnifyingglass")
                    .foregroundColor(.secondary)
                Slider(value: $scale, in: 0.5...5.0)
                    .onChange(of: scale) { _, _ in
                        lastScale = scale
                    }
                Image(systemName: "plus.magnifyingglass")
                    .foregroundColor(.secondary)
            }
            .padding(.horizontal, 40)

            Spacer()

            HStack {
                Button("Abbrechen") { dismiss() }
                    .keyboardShortcut(.cancelAction)
                Spacer()
                Button("Fertig") { cropAndSave() }
                    .keyboardShortcut(.defaultAction)
                    .buttonStyle(.borderedProminent)
            }
            .padding()
        }
    }

    private func cropAndSave() {
        let size = NSSize(width: cropSize, height: cropSize)
        let croppedImage = NSImage(size: size)

        croppedImage.lockFocus()

        // Circular clip
        let clipPath = NSBezierPath(ovalIn: NSRect(origin: .zero, size: size))
        clipPath.addClip()

        // Draw the image with scale and offset (scaledToFit logic)
        let imageSize = image.size
        let aspectRatio = imageSize.width / imageSize.height
        let drawWidth: CGFloat
        let drawHeight: CGFloat
        if aspectRatio > 1 {
            // Landscape: width fills, height is smaller
            drawWidth = cropSize * scale
            drawHeight = drawWidth / aspectRatio
        } else {
            // Portrait: height fills, width is smaller
            drawHeight = cropSize * scale
            drawWidth = drawHeight * aspectRatio
        }

        let drawX = (cropSize - drawWidth) / 2 + offset.width
        let drawY = (cropSize - drawHeight) / 2 - offset.height // Y is flipped on macOS

        image.draw(in: NSRect(x: drawX, y: drawY, width: drawWidth, height: drawHeight))

        croppedImage.unlockFocus()

        onCrop(croppedImage)
    }
}

// MARK: - Shared Helper: Downscale NSImage

private func downscaleNSImage(_ image: NSImage, maxDim: CGFloat) -> NSImage {
    let size = image.size
    guard size.width > maxDim || size.height > maxDim else { return image }
    let ratio = min(maxDim / size.width, maxDim / size.height)
    let newSize = NSSize(width: size.width * ratio, height: size.height * ratio)
    let resized = NSImage(size: newSize)
    resized.lockFocus()
    image.draw(in: NSRect(origin: .zero, size: newSize),
               from: NSRect(origin: .zero, size: size),
               operation: .copy, fraction: 1.0)
    resized.unlockFocus()
    return resized
}

#Preview {
    MacContentView()
        .modelContainer(for: Horse.self, inMemory: true)
}
#endif
