//
//  ContactsView.swift
//  Hippominder
//
//  Autor: Mathias Hubrich & Claude (Anthropic)
//  Erstellt: 12. Februar 2026
//  Version: 1.0.0
//
//  Beschreibung: Globale Kontaktverwaltung fuer E-Mail-Benachrichtigungen
//

import SwiftUI
#if os(iOS)
import ContactsUI
#endif

struct ContactsView: View {
    @ObservedObject var contactSettings = ContactSettings.shared
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            List {
                Section {
                    Text("Diese Kontakte gelten für alle Pferde. Pro Pferd kann eingestellt werden, wer benachrichtigt wird.")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .listRowBackground(Color.clear)
                }

                ForEach(ContactType.allCases) { type in
                    let entry = contactSettings.contact(for: type)
                    ContactEditRow(
                        type: type,
                        name: entry.name,
                        email: entry.email,
                        phone: entry.phone,
                        onUpdate: { name, email, phone in
                            contactSettings.update(ContactEntry(
                                type: type, name: name, email: email, phone: phone
                            ))
                        }
                    )
                }
            }
            .navigationTitle("Kontakte")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Fertig") { dismiss() }
                }
            }
        }
    }
}

// MARK: - Kontakt Bearbeitungszeile

struct ContactEditRow: View {
    let type: ContactType
    @State var name: String
    @State var email: String
    @State var phone: String
    let onUpdate: (String, String, String) -> Void
    @State private var showingContactPicker = false

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Titel mit Icon
            HStack(spacing: 8) {
                Image(systemName: type.icon)
                    .foregroundColor(.secondary)
                    .frame(width: 20)
                Text(type.rawValue)
                    .font(.subheadline.weight(.semibold))

                Spacer()

                // Apple Contacts Picker
                Button(action: { showingContactPicker = true }) {
                    Image(systemName: "person.crop.circle.badge.plus")
                        .font(.system(size: 20))
                        .foregroundColor(.blue)
                }
                .buttonStyle(.plain)
            }

            // Name
            HStack(spacing: 6) {
                Image(systemName: "person.text.rectangle")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .frame(width: 16)
                TextField("Name", text: $name)
                    .font(.callout)
                    .onChange(of: name) { _, _ in onUpdate(name, email, phone) }
            }

            // E-Mail
            HStack(spacing: 6) {
                Image(systemName: "envelope")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .frame(width: 16)
                TextField("E-Mail", text: $email)
                    .font(.callout)
                    #if os(iOS)
                    .keyboardType(.emailAddress)
                    .textContentType(.emailAddress)
                    .autocapitalization(.none)
                    #endif
                    .onChange(of: email) { _, _ in onUpdate(name, email, phone) }
            }

            // Telefon
            HStack(spacing: 6) {
                Image(systemName: "phone")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .frame(width: 16)
                TextField("Telefon", text: $phone)
                    .font(.callout)
                    #if os(iOS)
                    .keyboardType(.phonePad)
                    .textContentType(.telephoneNumber)
                    #endif
                    .onChange(of: phone) { _, _ in onUpdate(name, email, phone) }
            }
        }
        .padding(.vertical, 4)
        #if os(iOS)
        .sheet(isPresented: $showingContactPicker) {
            GlobalContactPickerView(
                selectedName: $name,
                selectedEmail: $email,
                selectedPhone: $phone,
                onDone: { onUpdate(name, email, phone) }
            )
        }
        #endif
    }
}

// MARK: - Contact Picker fuer globale Kontakte (nur iOS)

#if os(iOS)
struct GlobalContactPickerView: UIViewControllerRepresentable {
    @Binding var selectedName: String
    @Binding var selectedEmail: String
    @Binding var selectedPhone: String
    var onDone: () -> Void
    @Environment(\.dismiss) private var dismiss

    func makeUIViewController(context: Context) -> CNContactPickerViewController {
        let picker = CNContactPickerViewController()
        picker.delegate = context.coordinator
        return picker
    }

    func updateUIViewController(_ uiViewController: CNContactPickerViewController, context: Context) {}

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    class Coordinator: NSObject, CNContactPickerDelegate {
        let parent: GlobalContactPickerView

        init(_ parent: GlobalContactPickerView) {
            self.parent = parent
        }

        func contactPicker(_ picker: CNContactPickerViewController, didSelect contact: CNContact) {
            // Name
            let fullName = [contact.givenName, contact.familyName]
                .filter { !$0.isEmpty }
                .joined(separator: " ")
            if !fullName.isEmpty {
                parent.selectedName = fullName
            }

            // E-Mail (erste)
            if let email = contact.emailAddresses.first?.value as String? {
                parent.selectedEmail = email
            }

            // Telefon (erste)
            if let phone = contact.phoneNumbers.first?.value.stringValue {
                parent.selectedPhone = phone
            }

            parent.onDone()
            parent.dismiss()
        }

        func contactPickerDidCancel(_ picker: CNContactPickerViewController) {
            parent.dismiss()
        }
    }
}

#endif // os(iOS) for GlobalContactPickerView

#Preview {
    ContactsView()
}
