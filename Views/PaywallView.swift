//
//  PaywallView.swift
//  Hippominder
//
//  Autor: Mathias Hubrich & Claude (Anthropic)
//  Erstellt: 12. Februar 2026
//  Version: 1.0.0
//
//  Beschreibung: Paywall fuer Hippominder Pro (ab 2. Pferd)
//

import SwiftUI
import StoreKit

struct PaywallView: View {
    @ObservedObject var storeManager = StoreManager.shared
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    Spacer().frame(height: 16)

                    // Icon
                    Image("hippominder_logo")
                        .resizable()
                        .scaledToFit()
                        .frame(height: 80)

                    // Titel
                    Text("Hippominder Pro")
                        .font(.largeTitle)
                        .bold()

                    Text("Unbegrenzte Pferde verwalten")
                        .font(.title3)
                        .foregroundColor(.secondary)

                    // Features
                    VStack(alignment: .leading, spacing: 14) {
                        FeatureRow(icon: "checkmark.circle.fill", color: .green,
                                   text: "1 Pferd kostenlos")
                        FeatureRow(icon: "star.circle.fill", color: .orange,
                                   text: "Unbegrenzt viele Pferde")
                        FeatureRow(icon: "bell.circle.fill", color: .blue,
                                   text: "E-Mail-Benachrichtigungen")
                        FeatureRow(icon: "calendar.circle.fill", color: .purple,
                                   text: "Kalender-Integration")
                        FeatureRow(icon: "heart.circle.fill", color: .pink,
                                   text: "Unterstütze die Entwicklung")
                    }
                    .padding()
                    .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16))
                    .padding(.horizontal)

                    // Preis-Button
                    if let product = storeManager.products.first {
                        Button(action: {
                            Task { await storeManager.purchasePro() }
                        }) {
                            HStack {
                                if storeManager.isLoading {
                                    ProgressView()
                                        .tint(.white)
                                } else {
                                    Text("Pro freischalten für \(product.displayPrice)")
                                        .font(.headline)
                                }
                            }
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(
                                LinearGradient(
                                    colors: [Color.orange, Color(red: 1.0, green: 0.45, blue: 0.0)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                in: Capsule()
                            )
                            .shadow(color: .orange.opacity(0.3), radius: 8, x: 0, y: 4)
                        }
                        .disabled(storeManager.isLoading)
                        .padding(.horizontal, 32)
                    } else {
                        // Produkte noch nicht geladen
                        ProgressView("Lade Produkt-Informationen...")
                            .padding()
                            .task {
                                await storeManager.loadProducts()
                            }
                    }

                    // Wiederherstellen
                    Button(action: {
                        Task { await storeManager.restorePurchases() }
                    }) {
                        Text("Käufe wiederherstellen")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }

                    // Fehlermeldung
                    if let error = storeManager.errorMessage {
                        Text(error)
                            .font(.caption)
                            .foregroundColor(.red)
                            .padding(.horizontal)
                    }

                    // Legal
                    VStack(spacing: 4) {
                        Text("Einmaliger Kauf. Kein Abo.")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                        Text("Zahlung wird über deinen Apple-Account abgewickelt.")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                    .padding(.top, 8)

                    Spacer()
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Später") {
                        dismiss()
                    }
                }
            }
        }
    }
}

// MARK: - Feature-Zeile

struct FeatureRow: View {
    let icon: String
    let color: Color
    let text: String

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 22))
                .foregroundColor(color)
                .frame(width: 28)

            Text(text)
                .font(.callout)
        }
    }
}

#Preview {
    PaywallView()
}
