//
//  AddHorseView.swift
//  Hippominder
//
//  Autor: Mathias Hubrich & Claude (Anthropic)
//  Erstellt: 24. Januar 2026
//  Geaendert: 25. Januar 2026, 12:00 Uhr
//  Version: 1.1.0
//
//  Beschreibung: Neues Pferd hinzufuegen
//

import SwiftUI
import PhotosUI

struct AddHorseView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    @State private var name = ""
    @State private var selectedPhotoItem: PhotosPickerItem?
    @State private var imageData: Data?

    @State private var hufschmiedIntervall = 42
    @State private var impfungIntervall = 180
    @State private var wurmkurIntervall = 90

    var body: some View {
        NavigationStack {
            Form {
                // Foto
                Section {
                    HStack {
                        Spacer()
                        VStack {
                            if let data = imageData, let uiImage = UIImage(data: data) {
                                Image(uiImage: uiImage)
                                    .resizable()
                                    .scaledToFill()
                                    .frame(width: 100, height: 100)
                                    .clipShape(Circle())
                            } else {
                                Circle()
                                    .fill(Color.gray.opacity(0.2))
                                    .frame(width: 100, height: 100)
                                    .overlay(
                                        Image(systemName: "camera.fill")
                                            .foregroundColor(.gray)
                                            .font(.title)
                                    )
                            }

                            PhotosPicker(selection: $selectedPhotoItem, matching: .images) {
                                Text("Foto auswählen")
                                    .font(.caption)
                            }
                        }
                        Spacer()
                    }
                }

                // Name
                Section("Name") {
                    TextField("Pferdename", text: $name)
                }

                // Intervalle
                Section("Intervalle (Tage)") {
                    Stepper("Hufschmied: \(hufschmiedIntervall)", value: $hufschmiedIntervall, in: 1...365)
                    Stepper("Impfung: \(impfungIntervall)", value: $impfungIntervall, in: 1...365)
                    Stepper("Wurmkur: \(wurmkurIntervall)", value: $wurmkurIntervall, in: 1...365)
                }
            }
            .navigationTitle("Neues Pferd")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Abbrechen") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button("Speichern") {
                        saveHorse()
                    }
                    .disabled(name.isEmpty)
                }
            }
            .onChange(of: selectedPhotoItem) { _, newItem in
                Task {
                    if let data = try? await newItem?.loadTransferable(type: Data.self) {
                        imageData = data
                    }
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

#Preview {
    AddHorseView()
        .modelContainer(for: Horse.self, inMemory: true)
}
