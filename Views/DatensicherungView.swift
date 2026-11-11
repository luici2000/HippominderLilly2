//
//  DatensicherungView.swift
//  Hippominder
//
//  Autor: Mathias Hubrich & Claude (Anthropic)
//  Erstellt: 9. November 2026
//  Geaendert: 11. November 2026 - laeuft jetzt auch auf dem Mac
//
//  Beschreibung: Pferde als Datei sichern und zurueckholen.
//  Das Netz unter dem iCloud-Abgleich - auch fuer alle, die iCloud
//  abgeschaltet haben.
//
//  Der Weg zur Datei ist das Einzige, was sich je Geraet unterscheidet:
//  auf dem iPhone das Teilen-Menue, auf dem Mac das Sichern-Fenster.
//  Gerechnet wird beidesmal in HorseBackupService.
//

import SwiftUI
import SwiftData
import UniformTypeIdentifiers

struct DatensicherungView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var horses: [Horse]

    #if os(iOS)
    @State private var exportDatei: SicherungsDatei?
    #else
    @State private var exportInhalt: SicherungsDokument?
    @State private var zeigeSichernFenster = false
    #endif

    @State private var zeigeDateiwahl = false
    @State private var meldung: Meldung?

    var body: some View {
        List {
            Section {
                Text("Eine Sicherung enthält Namen, Intervalle und Termine aller Pferde. Fotos sind nicht enthalten – die lassen sich leichter neu wählen als ein vergessenes Intervall.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .listRowBackground(Color.clear)
            }

            Section("Sichern") {
                Button {
                    sichern()
                } label: {
                    Label("\(horses.count) \(horses.count == 1 ? "Pferd" : "Pferde") sichern",
                          systemImage: "square.and.arrow.up")
                }
                .disabled(horses.isEmpty)
            }

            Section {
                Button {
                    zeigeDateiwahl = true
                } label: {
                    Label("Sicherung einlesen", systemImage: "square.and.arrow.down")
                }
            } footer: {
                Text("Beim Einlesen wird nichts gelöscht: bekannte Pferde werden aktualisiert, unbekannte kommen dazu.")
            }
        }
        .navigationTitle("Daten sichern")
        #if os(iOS)
        .navigationBarTitleDisplayMode(.inline)
        .sheet(item: $exportDatei) { datei in
            TeilenBlatt(datei: datei)
        }
        #else
        .fileExporter(
            isPresented: $zeigeSichernFenster,
            document: exportInhalt,
            contentType: .json,
            defaultFilename: HorseBackupService.dateiname()
        ) { ergebnis in
            if case .failure(let fehler) = ergebnis {
                meldung = Meldung(titel: "Sichern fehlgeschlagen", text: fehler.localizedDescription)
            }
        }
        #endif
        .fileImporter(
            isPresented: $zeigeDateiwahl,
            allowedContentTypes: [.json],
            allowsMultipleSelection: false
        ) { ergebnis in
            einlesen(ergebnis)
        }
        .alert(item: $meldung) { m in
            Alert(title: Text(m.titel), message: Text(m.text), dismissButton: .default(Text("OK")))
        }
    }

    // MARK: - Sichern

    private func sichern() {
        do {
            let daten = try HorseBackupService.exportieren(from: modelContext)
            #if os(iOS)
            // Auf dem iPhone geht die Datei ins Teilen-Menue, von dort nach
            // iCloud Drive, in eine Mail oder wohin auch immer
            let ziel = FileManager.default.temporaryDirectory
                .appendingPathComponent(HorseBackupService.dateiname())
            try daten.write(to: ziel)
            exportDatei = SicherungsDatei(url: ziel)
            #else
            // Auf dem Mac das gewohnte Sichern-Fenster, kein Umweg ueber
            // eine Zwischendatei
            exportInhalt = SicherungsDokument(daten: daten)
            zeigeSichernFenster = true
            #endif
        } catch {
            meldung = Meldung(titel: "Sichern fehlgeschlagen", text: error.localizedDescription)
        }
    }

    // MARK: - Einlesen

    private func einlesen(_ ergebnis: Result<[URL], Error>) {
        switch ergebnis {
        case .failure(let fehler):
            meldung = Meldung(titel: "Datei nicht lesbar", text: fehler.localizedDescription)

        case .success(let urls):
            guard let url = urls.first else { return }
            // Dateien aus der Dateien-App oder dem Finder liegen ausserhalb
            // der App und brauchen eine ausdrueckliche Freigabe
            let freigegeben = url.startAccessingSecurityScopedResource()
            defer { if freigegeben { url.stopAccessingSecurityScopedResource() } }

            do {
                let daten = try Data(contentsOf: url)
                let ergebnis = try HorseBackupService.importieren(daten, into: modelContext)

                // Termine und Anzeigen an den neuen Stand anpassen
                for pferd in horses {
                    NotificationService.shared.scheduleAllNotifications(for: pferd)
                }
                NotificationService.shared.updateBadge(using: modelContext)
                #if os(iOS)
                WatchSyncService.shared.syncToWatch()
                #endif

                meldung = Meldung(
                    titel: "Eingelesen",
                    text: "\(ergebnis.neu) neu, \(ergebnis.aktualisiert) aktualisiert."
                )
            } catch {
                meldung = Meldung(
                    titel: "Einlesen fehlgeschlagen",
                    text: "Die Datei konnte nicht gelesen werden. Stammt sie aus Hippominder?"
                )
            }
        }
    }
}

// MARK: - Hilfstypen

private struct Meldung: Identifiable {
    let titel: String
    let text: String
    var id: String { titel + text }
}

#if os(iOS)

private struct SicherungsDatei: Identifiable {
    let url: URL
    var id: String { url.absoluteString }
}

/// Reicht die Datei an das System weiter, damit sie in iCloud Drive,
/// per Mail oder sonstwohin gesichert werden kann
private struct TeilenBlatt: UIViewControllerRepresentable {
    let datei: SicherungsDatei

    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: [datei.url], applicationActivities: nil)
    }

    func updateUIViewController(_ controller: UIActivityViewController, context: Context) {}
}

#else

/// Traegt die fertigen Daten ins Sichern-Fenster des Macs.
///
/// Nur zum Schreiben gedacht: Gelesen wird ueber `fileImporter`, weil das
/// den Zugriff auf eine Datei ausserhalb der App ausdruecklich freigibt.
private struct SicherungsDokument: FileDocument {
    static var readableContentTypes: [UTType] { [.json] }

    let daten: Data

    init(daten: Data) {
        self.daten = daten
    }

    init(configuration: ReadConfiguration) throws {
        self.daten = configuration.file.regularFileContents ?? Data()
    }

    func fileWrapper(configuration: WriteConfiguration) throws -> FileWrapper {
        FileWrapper(regularFileWithContents: daten)
    }
}

#endif
