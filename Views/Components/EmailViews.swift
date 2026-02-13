//
//  EmailViews.swift
//  Hippominder
//
//  Autor: Mathias Hubrich & Claude (Anthropic)
//  Erstellt: 12. Februar 2026
//  Version: 1.1.0
//
//  Beschreibung: E-Mail-Vorlagen und Mail-Composer (nur iOS)
//

import SwiftUI

#if os(iOS)
import MessageUI

// MARK: - E-Mail Vorlagen

/// Standard-E-Mail-Texte fuer verschiedene Anlaesse
struct EmailTemplates {
    let horse: Horse

    // Cached DateFormatters (expensive to create)
    private static let dateFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateStyle = .long
        return f
    }()

    private static let shortDateFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "dd.MM.yyyy"
        return f
    }()

    // MARK: - Termin-Erinnerung

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

        text += String(localized: "email.duedate \(Self.dateFormatter.string(from: nextDate))") + "\n"
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
            let dateStr = Self.dateFormatter.string(from: nextDate)
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

    private var notifyFlags: [ContactType: Bool] {
        [
            .apotheker: horse.notifyApotheker,
            .besitzer: horse.notifyBesitzer,
            .hufschmied: horse.notifyHufschmied,
            .stallbesitzer: horse.notifyStallbesitzer,
            .tierarzt: horse.notifyTierarzt
        ]
    }

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
                    Button("Schließen") { isPresented = false }
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
            alertMessage = "E-Mail ist auf diesem Gerät nicht konfiguriert."
            showingAlert = true
            return
        }

        let recipients: [String]
        if let typ = forType {
            recipients = contactSettings.recipients(for: typ, notifyFlags: notifyFlags).map { $0.email }
        } else {
            recipients = activeContacts.map { $0.email }
        }

        selectedRecipients = Array(Set(recipients))
        selectedSubject = subject
        selectedBody = body
        showingMailComposer = true
    }
}

// MARK: - Mail Composer

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
#endif
