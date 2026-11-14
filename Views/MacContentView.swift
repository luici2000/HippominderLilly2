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
                // Kopf wie auf dem iPhone: Logo links, rechts das Farbschema.
                // Glas: drei Schemata + freie Farbe, Blume: nur die drei,
                // Classic ist monochrom. Die Darstellung selbst wird wie am
                // iPhone auf der Detailseite umgeschaltet.
                HStack(alignment: .top) {
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

                    if globalSettings.designMode != .classic {
                        GlobalColorPicker(
                            selectedScheme: Binding(
                                get: {
                                    globalSettings.designMode == .glass
                                        ? globalSettings.matchingColorScheme
                                        : globalSettings.flowerColorScheme
                                },
                                set: { scheme in
                                    guard let scheme else { return }
                                    if globalSettings.designMode == .glass {
                                        globalSettings.flowerColorScheme = scheme
                                    } else {
                                        globalSettings.flowerColorSchemeIndex =
                                            FlowerColorScheme.allCases.firstIndex(of: scheme) ?? 0
                                    }
                                }
                            ),
                            customTint: Binding(
                                get: { globalSettings.glassTint },
                                set: { globalSettings.glassTint = $0 }
                            ),
                            showsCustomTint: globalSettings.designMode == .glass
                        )
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

                versionsFuss
            }
            .navigationSplitViewColumnWidth(min: 280, ideal: 320, max: 380)
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

    /// Version und Bauzeit unten in der Seitenleiste.
    ///
    /// Dieselbe Auskunft wie auf dem iPhone, damit beim Bauen zu sehen ist,
    /// welcher Stand hier wirklich laeuft. Antippen oeffnet die Beta-Info.
    private var versionsFuss: some View {
        Text(Versionsinfo.zeile)
            .font(.system(size: 10))
            .foregroundStyle(.tertiary)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 4)
            .contentShape(Rectangle())
            .onTapGesture { showingBetaInfo = true }
            .accessibilityIdentifier("versionsFuss")
    }
}

// MARK: - Pferde-Zeile (Mac) - wie HorseRowView auf dem iPhone

/// Dieselbe Zeile wie in der iPhone-Liste: Bild, Name, der naechste Termin
/// in Worten und rechts die drei Mini-Blumen statt Ampelpunkten.
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
            if let image = horse.image {
                image
                    .resizable()
                    .scaledToFill()
                    .frame(width: 40, height: 40)
                    .clipShape(Circle())
            } else {
                Circle()
                    .fill(Color.gray.opacity(0.2))
                    .frame(width: 40, height: 40)
                    .overlay(
                        Image("horse_silhouette")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 22, height: 22)
                            .opacity(0.3)
                    )
            }

            VStack(alignment: .leading, spacing: 3) {
                Text(horse.name)
                    .font(.headline)
                    .lineLimit(1)

                HStack(spacing: 4) {
                    // Template-Asset: ohne Farbe waere das Symbol in Akzentfarbe
                    Image(nextEvent.type.symbol)
                        .resizable()
                        .scaledToFit()
                        .foregroundStyle(.primary)
                        .frame(width: 12, height: 12)
                    // Zwei Zeilen erlaubt: in der schmalen Seitenleiste passt
                    // "Hufschmied in 41 Tagen" sonst nicht neben die Blumen
                    Text(wortlaut)
                        .font(.caption)
                        .foregroundColor(farbe)
                        .lineLimit(2)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }

            Spacer(minLength: 4)

            HStack(spacing: 6) {
                ForEach(Horse.EventType.allCases, id: \.self) { eventType in
                    TimerIndicator(
                        eventType: eventType,
                        days: horse.tageBis(fuer: eventType),
                        interval: horse.holeIntervall(fuer: eventType)
                    )
                }
            }
        }
        .padding(.vertical, 3)
    }

    /// Wortlaut wie am iPhone: "Hufschmied in 41 Tagen", "heute faellig!",
    /// "seit 3 Tagen ueberfaellig"
    private var wortlaut: String {
        let name = nextEvent.type.localizedName
        if nextEvent.days < 0 {
            return "\(name) \(String(localized: "seit")) \(-nextEvent.days) \(String(localized: "Tagen überfällig"))"
        }
        if nextEvent.days == 0 {
            return "\(name) \(String(localized: "heute fällig!"))"
        }
        return "\(name) \(String(localized: "in")) \(nextEvent.days) \(String(localized: "Tagen"))"
    }

    private var farbe: Color {
        if nextEvent.days <= 7 { return .red }
        if nextEvent.days <= 14 { return .orange }
        return .gray
    }
}

// MARK: - Detail-Ansicht (Mac) - Aufbau wie HorseDetailView auf dem iPhone

/// Dieselbe Seite wie am iPhone: Logo, Name, rundes Bild, Umschalter der
/// Darstellung, dann die drei Blumen (Glasbuehne / LCD / PNG-Blumen),
/// darunter Erinnerung und Intervalle mit den Geraetetasten und die drei
/// Aktionsknoepfe. Nur die Fotoquellen sind Mac-eigen (Finder, Mediathek,
/// Drag & Drop) und das Zuschneiden laeuft ueber den Mac-Zuschnitt.
struct MacHorseDetailView: View {
    @Bindable var horse: Horse
    @Environment(\.modelContext) private var modelContext
    @ObservedObject var globalSettings = GlobalSettings.shared
    @ObservedObject var debugSettings = DebugSettings.shared

    @State private var selectedEventType: Horse.EventType?
    @State private var showingActionSheet = false
    @State private var showingDatePicker = false
    @State private var showingImageCropper = false
    @State private var rawNSImage: NSImage?
    @State private var isLoadingPhoto = false
    @State private var showingPhotoPicker = false
    @State private var isDropTargeted = false
    @State private var showingCalendarAlert = false
    @State private var calendarAlertMessage = ""
    @State private var showingNotificationSettings = false
    /// true: das gewaehlte Foto wird Hintergrund der Glasbuehne,
    /// false: es wird das runde Profilbild
    @State private var waehltHintergrund = false

    /// Breite wie auf dem iPad: Buehne, Blumen und Tasten bleiben in
    /// iPhone-Proportion und stehen mittig im Fenster.
    private let seitenBreite: CGFloat = 440

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                Image("hippominder_logo")
                    .resizable()
                    .scaledToFit()
                    .frame(height: 44)
                    .padding(.top, 4)

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

                Text(horse.name)
                    .font(.largeTitle)
                    .bold()

                profilbild

                DesignModePicker(mode: Binding(
                    get: { globalSettings.designMode },
                    set: { globalSettings.designMode = $0 }
                ))
                .padding(.horizontal)

                blumen

                einstellungen

                aktionen
                    .padding(.horizontal)
                    .padding(.bottom, 32)
            }
            .frame(maxWidth: seitenBreite)
            .frame(maxWidth: .infinity)
        }
        .frame(minWidth: 400)
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
                    NotificationService.shared.updateBadge(using: modelContext)
                }
                Button("Datum manuell wählen") {
                    showingDatePicker = true
                }
                Button("Abbrechen", role: .cancel) { }
            }
        }
        .sheet(isPresented: $showingDatePicker) {
            if let eventType = selectedEventType {
                MacDatePickerSheet(
                    title: "\(eventType.localizedName) Termin",
                    date: Binding(
                        get: { horse.holeTermin(fuer: eventType) },
                        set: {
                            horse.setzeTermin($0, fuer: eventType)
                            NotificationService.shared.scheduleAllNotifications(for: horse)
                            NotificationService.shared.updateBadge(using: modelContext)
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
                // Profilbild rund, Hintergrund rechteckig im Format der
                // Buehne - sonst wird der gewaehlte Ausschnitt nochmal
                // beschnitten (siehe CLAUDE.md, Profilbild != Hintergrundfoto)
                let hintergrund = waehltHintergrund
                MacImageCropperView(
                    image: nsImage,
                    shape: hintergrund ? .rect(aspect: GlassFlowerStageMasse.format) : .circle
                ) { croppedImage in
                    // JPEG encoding on background thread to avoid UI freeze
                    Task.detached(priority: .userInitiated) {
                        let tiffData = croppedImage.tiffRepresentation
                        let jpegData: Data? = tiffData.flatMap { data in
                            NSBitmapImageRep(data: data)?.representation(
                                using: .jpeg,
                                properties: [.compressionFactor: hintergrund ? 0.85 : 0.8]
                            )
                        }
                        await MainActor.run {
                            if let jpegData {
                                if hintergrund {
                                    horse.backgroundImageData = jpegData
                                } else {
                                    horse.imageData = jpegData
                                }
                            }
                            showingImageCropper = false
                        }
                    }
                }
                .frame(width: 440, height: 480)
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

    // MARK: - Bausteine

    /// Rundes Profilbild wie am iPhone (120 pt), Kamera-Knopf unten rechts.
    /// Am Mac oeffnet der Knopf ein Menue mit Finder und Mediathek; ein
    /// Bild laesst sich auch direkt auf das Foto ziehen.
    private var profilbild: some View {
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

            if isDropTargeted {
                Circle()
                    .stroke(Color.accentColor, lineWidth: 3)
                    .frame(width: 120, height: 120)
            }

            if isLoadingPhoto {
                Circle()
                    .fill(Color.black.opacity(0.3))
                    .frame(width: 120, height: 120)
                    .overlay(ProgressView().scaleEffect(0.8).tint(.white))
            }

            fotoMenue(hintergrund: false, entfernbar: horse.imageData != nil) {
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
            .frame(width: 32, height: 32)
            .offset(x: 2, y: 2)
            .disabled(isLoadingPhoto)
        }
        .onDrop(of: [.image, .fileURL], isTargeted: $isDropTargeted) { providers in
            waehltHintergrund = false
            handleImageDrop(providers: providers)
            return true
        }
    }

    /// Menue der Fotoquellen. `hintergrund` entscheidet, wohin das Bild geht.
    private func fotoMenue<Inhalt: View>(
        hintergrund: Bool,
        entfernbar: Bool,
        @ViewBuilder label: () -> Inhalt
    ) -> some View {
        Menu {
            Button {
                waehltHintergrund = hintergrund
                openImageFromFinder()
            } label: {
                Label("Bild wählen…", systemImage: "folder")
            }

            Button {
                waehltHintergrund = hintergrund
                showingPhotoPicker = true
            } label: {
                Label("Fotos-Mediathek", systemImage: "photo.on.rectangle")
            }

            if entfernbar {
                Divider()
                Button(role: .destructive) {
                    if hintergrund {
                        horse.backgroundImageData = nil
                    } else {
                        horse.imageData = nil
                    }
                } label: {
                    Label("Foto entfernen", systemImage: "trash")
                }
            }
        } label: {
            label()
        }
        .menuStyle(.borderlessButton)
        .menuIndicator(.hidden)
    }

    /// Die drei Blumen - je nach Darstellung, Aufbau wie am iPhone
    @ViewBuilder
    private var blumen: some View {
        switch globalSettings.designMode {
        case .glass:
            ZStack(alignment: .bottomTrailing) {
                GlassFlowerStage(backgroundImage: horse.backgroundImage) { blumengroesse in
                    HStack(alignment: .top, spacing: 4) {
                        ForEach(Horse.EventType.allCases, id: \.self) { eventType in
                            Button(action: { terminWaehlen(eventType) }) {
                                GlassFlowerTimerView(
                                    eventType: eventType,
                                    remainingDays: horse.tageBis(fuer: eventType),
                                    interval: horse.holeIntervall(fuer: eventType),
                                    nextDate: horse.naechsterTermin(fuer: eventType),
                                    tint: globalSettings.glassTint,
                                    flowerSize: blumengroesse
                                )
                            }
                            .buttonStyle(.plain)
                            .accessibilityIdentifier("flower_\(eventType.rawValue)")
                        }
                    }
                }

                // Hintergrundfoto der Buehne - nur das Symbol, wie am iPhone
                fotoMenue(hintergrund: true, entfernbar: horse.backgroundImageData != nil) {
                    Image(systemName: "photo.on.rectangle.angled")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(.white)
                        .frame(width: 30, height: 30)
                        .background {
                            Circle().fill(.ultraThinMaterial)
                                .overlay { Circle().fill(.black.opacity(0.25)) }
                                .overlay { Circle().strokeBorder(.white.opacity(0.45), lineWidth: 0.5) }
                        }
                }
                .frame(width: 30, height: 30)
                .padding(8)
                .accessibilityLabel("Hintergrundfoto wählen")
            }
            .padding(.horizontal, 12)

        case .classic:
            LCDPanel(alarmActive: hasDueEvent) { rosenGroesse in
                HStack(alignment: .top, spacing: 0) {
                    ForEach(Horse.EventType.allCases, id: \.self) { eventType in
                        Button(action: { terminWaehlen(eventType) }) {
                            LCDFlowerTimerView(
                                eventType: eventType,
                                remainingDays: horse.tageBis(fuer: eventType),
                                interval: horse.holeIntervall(fuer: eventType),
                                nextDate: horse.naechsterTermin(fuer: eventType),
                                roseSize: rosenGroesse
                            )
                        }
                        .buttonStyle(.plain)
                        .accessibilityIdentifier("flower_\(eventType.rawValue)")
                    }
                }
            }
            .padding(.horizontal, 12)

        case .blume:
            HStack(alignment: .top, spacing: 20) {
                ForEach(Horse.EventType.allCases, id: \.self) { eventType in
                    Button(action: { terminWaehlen(eventType) }) {
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
    }

    /// Erinnerung und Intervalle mit den Geraetetasten (Plus / Minus)
    private var einstellungen: some View {
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
    }

    /// Die drei Aktionsknoepfe, passend zur Darstellung
    private var aktionen: some View {
        VStack(spacing: 10) {
            DesignedActionButton(
                title: "Benachrichtigungen verwalten",
                systemImage: "bell.badge.fill",
                mode: globalSettings.designMode,
                subtitle: notifySubtitle,
                trailingChevron: true,
                action: { showingNotificationSettings = true }
            )
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
                action: { sendEmail() }
            )
            .accessibilityIdentifier("sendEmail")
        }
    }

    private func terminWaehlen(_ eventType: Horse.EventType) {
        selectedEventType = eventType
        showingActionSheet = true
    }

    private func rescheduleNotifications() {
        NotificationService.shared.scheduleAllNotifications(for: horse)
    }

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

/// Ausschnitt waehlen: rund fuer das Profilbild, rechteckig im Format der
/// Glasbuehne fuer das Hintergrundfoto. Das Ergebnis wird dreifach so gross
/// wie der Rahmen auf dem Bildschirm gerendert, damit es auf dem
/// Retina-Display scharf bleibt.
struct MacImageCropperView: View {
    enum Shape {
        case circle
        /// Breite zu Hoehe
        case rect(aspect: CGFloat)
    }

    let image: NSImage
    var shape: Shape = .circle
    let onCrop: (NSImage) -> Void
    @Environment(\.dismiss) private var dismiss

    @State private var scale: CGFloat = 1.0
    @State private var lastScale: CGFloat = 1.0
    @State private var offset: CGSize = .zero
    @State private var lastOffset: CGSize = .zero

    /// Rahmen auf dem Bildschirm
    private var cropWidth: CGFloat {
        switch shape {
        case .circle: return 250
        case .rect: return 360
        }
    }
    private var cropHeight: CGFloat {
        switch shape {
        case .circle: return 250
        case .rect(let aspect): return (360 / aspect).rounded()
        }
    }
    /// Ausgabe in Pixeln je Punkt des Rahmens
    private let ausgabeFaktor: CGFloat = 3

    private var istRund: Bool {
        if case .circle = shape { return true }
        return false
    }

    /// Das Bild fuellt den Rahmen in der laengeren Richtung (scaledToFill
    /// bei Faktor 1), so bleibt bei jedem Format etwas zu sehen.
    private var bildGroesse: CGSize {
        let aspect = image.size.width / max(1, image.size.height)
        var w = cropWidth, h = cropWidth / aspect
        if h < cropHeight { h = cropHeight; w = cropHeight * aspect }
        return CGSize(width: w * scale, height: h * scale)
    }

    var body: some View {
        VStack(spacing: 16) {
            Text("Ausschnitt wählen")
                .font(.headline)
                .padding(.top, 16)

            Text("Verschieben und zoomen zum Zuschneiden")
                .font(.caption)
                .foregroundColor(.secondary)

            ZStack {
                Image(nsImage: image)
                    .resizable()
                    .frame(width: bildGroesse.width, height: bildGroesse.height)
                    .offset(offset)
                    .gesture(
                        DragGesture()
                            .onChanged { value in
                                offset = CGSize(
                                    width: lastOffset.width + value.translation.width,
                                    height: lastOffset.height + value.translation.height
                                )
                            }
                            .onEnded { _ in lastOffset = offset }
                    )
                    .gesture(
                        MagnificationGesture()
                            .onChanged { value in
                                scale = max(0.5, min(5.0, lastScale * value))
                            }
                            .onEnded { _ in lastScale = scale }
                    )

                // Abdunkeln ausserhalb des Ausschnitts
                Rectangle()
                    .fill(Color.black.opacity(0.4))
                    .frame(width: cropWidth + 40, height: cropHeight + 40)
                    .mask(
                        ZStack {
                            Rectangle()
                            maske
                                .frame(width: cropWidth, height: cropHeight)
                                .blendMode(.destinationOut)
                        }
                        .compositingGroup()
                    )
                    .allowsHitTesting(false)

                rahmen
                    .frame(width: cropWidth, height: cropHeight)
                    .allowsHitTesting(false)
            }
            .frame(width: cropWidth, height: cropHeight)
            .clipShape(RoundedRectangle(cornerRadius: 12))

            HStack {
                Image(systemName: "minus.magnifyingglass")
                    .foregroundColor(.secondary)
                Slider(value: $scale, in: 0.5...5.0)
                    .onChange(of: scale) { _, _ in lastScale = scale }
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

    @ViewBuilder private var maske: some View {
        if istRund { Circle() } else { RoundedRectangle(cornerRadius: 16, style: .continuous) }
    }

    @ViewBuilder private var rahmen: some View {
        if istRund {
            Circle().stroke(Color.white, lineWidth: 2)
        } else {
            RoundedRectangle(cornerRadius: 16, style: .continuous).stroke(Color.white, lineWidth: 2)
        }
    }

    private func cropAndSave() {
        let k = ausgabeFaktor
        let size = NSSize(width: cropWidth * k, height: cropHeight * k)
        let croppedImage = NSImage(size: size)

        croppedImage.lockFocus()

        if istRund {
            NSBezierPath(ovalIn: NSRect(origin: .zero, size: size)).addClip()
        }

        // Dieselbe Rechnung wie auf dem Bildschirm, nur k-fach:
        // Bild mittig im Rahmen, dann um den Versatz verschoben.
        let b = bildGroesse
        let drawX = (cropWidth - b.width) / 2 + offset.width
        let drawY = (cropHeight - b.height) / 2 - offset.height // Y ist am Mac gespiegelt

        image.draw(in: NSRect(x: drawX * k, y: drawY * k, width: b.width * k, height: b.height * k))

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
