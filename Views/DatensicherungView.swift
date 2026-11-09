//
//  DatensicherungView.swift
//  Hippominder
//
//  Autor: Mathias Hubrich & Claude (Anthropic)
//  Erstellt: 9. November 2026
//
//  Beschreibung: Pferde als Datei sichern und zurueckholen.
//  Das Netz unter dem iCloud-Abgleich - auch fuer alle, die iCloud
//  abgeschaltet haben.
//

import SwiftUI
import SwiftData
import UniformTypeIdentifiers

#if os(iOS)

struct DatensicherungView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var horses: [Horse]

    @State private var exportDatei: SicherungsDatei?
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
        .navigationBarTitleDisplayMode(.inline)
        .sheet(item: $exportDatei) { datei in
            TeilenBlatt(datei: datei)
        }
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
            let ziel = FileManager.default.temporaryDirectory
                .appendingPathComponent(HorseBackupService.dateiname())
            try daten.write(to: ziel)
            exportDatei = SicherungsDatei(url: ziel)
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
            // Dateien aus der Dateien-App liegen ausserhalb der App und
            // brauchen eine ausdrueckliche Freigabe
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
                WatchSyncService.shared.syncToWatch()

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

private struct SicherungsDatei: Identifiable {
    let url: URL
    var id: String { url.absoluteString }
}

private struct Meldung: Identifiable {
    let titel: String
    let text: String
    var id: String { titel + text }
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

#endif
