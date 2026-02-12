//
//  StoreManager.swift
//  Hippominder
//
//  Autor: Mathias Hubrich & Claude (Anthropic)
//  Erstellt: 12. Februar 2026
//  Version: 1.0.0
//
//  Beschreibung: In-App Purchase Manager mit StoreKit 2
//  Produkt: "Hippominder Pro" - Unbegrenzte Pferde (ab 2. Pferd)
//

import Foundation
import StoreKit

/// Produkt-IDs fuer In-App Purchases
enum StoreProduct: String {
    case pro = "com.roboterwerk.HippominderLilly2.pro"
}

/// StoreKit 2 Manager fuer In-App Purchases
@MainActor
class StoreManager: ObservableObject {
    static let shared = StoreManager()

    /// Ob der Nutzer "Pro" gekauft hat
    @Published var isPro: Bool = false

    /// Verfuegbare Produkte aus dem App Store
    @Published var products: [Product] = []

    /// Ladezustand
    @Published var isLoading: Bool = false

    /// Fehlermeldung
    @Published var errorMessage: String?

    /// Maximale Pferde in der kostenlosen Version
    static let freeHorseLimit = 1

    private var updateListenerTask: Task<Void, Never>?

    private init() {
        // Transaktions-Listener starten
        updateListenerTask = listenForTransactions()

        // Gespeicherten Status laden
        Task {
            await updatePurchaseStatus()
            await loadProducts()
        }
    }

    deinit {
        updateListenerTask?.cancel()
    }

    // MARK: - Produkte laden

    func loadProducts() async {
        isLoading = true
        errorMessage = nil

        do {
            let storeProducts = try await Product.products(for: [StoreProduct.pro.rawValue])
            products = storeProducts
        } catch {
            errorMessage = "Produkte konnten nicht geladen werden."
            print("StoreKit: Fehler beim Laden: \(error)")
        }

        isLoading = false
    }

    // MARK: - Kaufen

    func purchasePro() async {
        guard let product = products.first(where: { $0.id == StoreProduct.pro.rawValue }) else {
            errorMessage = "Produkt nicht verfuegbar."
            return
        }

        isLoading = true
        errorMessage = nil

        do {
            let result = try await product.purchase()

            switch result {
            case .success(let verification):
                let transaction = try checkVerified(verification)
                await transaction.finish()
                isPro = true

            case .userCancelled:
                break

            case .pending:
                errorMessage = "Kauf wird verarbeitet..."

            @unknown default:
                break
            }
        } catch {
            errorMessage = "Kauf fehlgeschlagen: \(error.localizedDescription)"
        }

        isLoading = false
    }

    // MARK: - Kauf wiederherstellen

    func restorePurchases() async {
        isLoading = true
        errorMessage = nil

        try? await AppStore.sync()
        await updatePurchaseStatus()

        if !isPro {
            errorMessage = "Kein aktiver Kauf gefunden."
        }

        isLoading = false
    }

    // MARK: - Status pruefen

    func updatePurchaseStatus() async {
        for await result in Transaction.currentEntitlements {
            guard let transaction = try? checkVerified(result) else { continue }
            if transaction.productID == StoreProduct.pro.rawValue {
                isPro = true
                return
            }
        }
        // Wenn kein Entitlement gefunden → nicht Pro
        // (Nicht auf false setzen wenn bereits true, fuer Offline-Support)
    }

    /// Pruefen ob ein Pferd hinzugefuegt werden darf
    func canAddHorse(currentCount: Int) -> Bool {
        return isPro || currentCount < StoreManager.freeHorseLimit
    }

    // MARK: - Private Helfer

    private func checkVerified<T>(_ result: VerificationResult<T>) throws -> T {
        switch result {
        case .unverified:
            throw StoreError.failedVerification
        case .verified(let safe):
            return safe
        }
    }

    private func listenForTransactions() -> Task<Void, Never> {
        return Task.detached {
            for await result in Transaction.updates {
                guard let transaction = try? await self.checkVerified(result) else { continue }
                await transaction.finish()
                await MainActor.run {
                    if transaction.productID == StoreProduct.pro.rawValue {
                        self.isPro = true
                    }
                }
            }
        }
    }
}

// MARK: - Store Fehler

enum StoreError: LocalizedError {
    case failedVerification

    var errorDescription: String? {
        switch self {
        case .failedVerification:
            return "Transaktion konnte nicht verifiziert werden."
        }
    }
}
