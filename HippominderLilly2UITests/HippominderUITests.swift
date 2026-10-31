//
//  HippominderUITests.swift
//  HippominderLilly2UITests
//
//  Autor: Mathias Hubrich & Claude (Anthropic)
//  Erstellt: 31. Oktober 2026
//  Version: 1.0.0
//
//  Beschreibung: Durchlauf der iOS-App im Simulator.
//  Ablauf: Mitteilungs-Freigabe, Pferd anlegen, Glasblumen, Termine setzen,
//  Intervalle, Erinnerungs-Vorlauf, Kontakte, Benachrichtigungen, E-Mail, Kalender,
//  Farbschema. Dazu Design-Screenshots in verschiedenen Zustaenden.
//
//  Screenshots landen im Ordner aus der Umgebungsvariable UITEST_SCREENSHOT_DIR
//  (zusaetzlich als Attachment im xcresult).
//

import XCTest

final class HippominderUITests: XCTestCase {

    private let timeout: TimeInterval = 10

    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    // MARK: - Hilfen

    private func launch(_ arguments: [String] = []) -> XCUIApplication {
        let app = XCUIApplication()
        app.launchArguments = arguments
        app.launch()
        allowNotificationsIfAsked()
        return app
    }

    /// Mitteilungs-Freigabe der App (Systemdialog) bestaetigen, falls er erscheint
    private func allowNotificationsIfAsked() {
        let springboard = XCUIApplication(bundleIdentifier: "com.apple.springboard")
        let allow = springboard.buttons["Erlauben"]
        if allow.waitForExistence(timeout: 3) {
            allow.tap()
        } else if springboard.buttons["Allow"].exists {
            springboard.buttons["Allow"].tap()
        }
    }

    /// Beliebigen Systemdialog (Kalender, Kontakte ...) mit "Erlauben"/"OK" bestaetigen
    private func allowSystemDialogIfShown(timeout: TimeInterval = 3) {
        let springboard = XCUIApplication(bundleIdentifier: "com.apple.springboard")
        let candidates = ["Vollen Zugriff erlauben", "Erlauben", "Allow Full Access", "Allow", "OK"]
        let deadline = Date().addingTimeInterval(timeout)
        while Date() < deadline {
            for title in candidates where springboard.buttons[title].exists {
                springboard.buttons[title].tap()
                return
            }
            RunLoop.current.run(until: Date().addingTimeInterval(0.3))
        }
    }

    private func screenshot(_ name: String) {
        let shot = XCUIScreen.main.screenshot()
        let attachment = XCTAttachment(screenshot: shot)
        attachment.name = name
        attachment.lifetime = .keepAlways
        add(attachment)

        if let dir = ProcessInfo.processInfo.environment["UITEST_SCREENSHOT_DIR"], !dir.isEmpty {
            let url = URL(fileURLWithPath: dir).appendingPathComponent("\(name).png")
            try? FileManager.default.createDirectory(at: url.deletingLastPathComponent(), withIntermediateDirectories: true)
            try? shot.pngRepresentation.write(to: url)
        }
    }

    private func back(_ app: XCUIApplication) {
        let backButton = app.navigationBars.buttons.element(boundBy: 0)
        XCTAssertTrue(backButton.waitForExistence(timeout: timeout), "Zurueck-Knopf fehlt")
        backButton.tap()
    }

    private func openHorse(_ app: XCUIApplication, name: String) {
        let row = app.buttons["horseRow_\(name)"].firstMatch
        XCTAssertTrue(row.waitForExistence(timeout: timeout), "Pferd \(name) nicht in der Liste")
        row.tap()
        XCTAssertTrue(app.buttons["flower_Hufschmied"].waitForExistence(timeout: timeout), "Detailansicht ohne Glasblumen")
    }

    /// Tage-Wert aus dem Blumen-Button lesen ("11 Tage, Hufschmied, 12.11.2026")
    private func days(of flowerIdentifier: String, in app: XCUIApplication) -> Int? {
        let label = app.buttons[flowerIdentifier].label
        let first = label.split(separator: ",").first.map(String.init) ?? label
        let number = first.split(separator: " ").first.map(String.init) ?? ""
        return Int(number.replacingOccurrences(of: "−", with: "-"))
    }

    private func value(of identifier: String, in app: XCUIApplication) -> Int? {
        Int(app.buttons[identifier].label)
    }

    /// Wartet, bis der Zahlenwert eines Hardware-Knopfs dem Erwartungswert entspricht
    @discardableResult
    private func waitForValue(_ identifier: String, toBe expected: Int, in app: XCUIApplication) -> Bool {
        let predicate = NSPredicate { _, _ in self.value(of: identifier, in: app) == expected }
        let expectation = XCTNSPredicateExpectation(predicate: predicate, object: nil)
        return XCTWaiter().wait(for: [expectation], timeout: timeout) == .completed
    }

    /// Alle Zeichen eines fokussierten Textfelds loeschen
    private func clearText(of field: XCUIElement) {
        let current = (field.value as? String) ?? ""
        guard !current.isEmpty else { return }
        field.typeText(String(repeating: XCUIKeyboardKey.delete.rawValue, count: current.count))
    }

    // MARK: - 1. Kompletter Funktionsdurchlauf

    func test01_vollstaendigerDurchlauf() throws {
        let app = launch()
        let horseName = "Testpferd"

        // --- Hauptseite, leerer Zustand ---
        XCTAssertTrue(app.staticTexts["Farbschema"].waitForExistence(timeout: timeout))
        // Ein Demo-Pferd aus einem frueheren Lauf wuerde die Paywall ausloesen
        // (ein Pferd kostenlos) - vorher wegwischen
        if app.buttons["horseRow_Demo"].exists {
            app.buttons["horseRow_Demo"].firstMatch.swipeLeft()
            let delete = app.buttons["Löschen"]
            XCTAssertTrue(delete.waitForExistence(timeout: timeout), "Loeschen per Wischen fehlt")
            delete.tap()
            XCTAssertFalse(app.buttons["horseRow_Demo"].waitForExistence(timeout: 2), "Demo-Pferd wurde nicht geloescht")
        }
        screenshot("01_hauptseite_leer")

        // --- Pferd anlegen ---
        if !app.buttons["horseRow_\(horseName)"].exists {
            let addButton = app.buttons["Pferd hinzufügen"].exists ? app.buttons["Pferd hinzufügen"] : app.buttons["Pferd +"]
            XCTAssertTrue(addButton.waitForExistence(timeout: timeout))
            addButton.tap()

            let nameField = app.textFields["Pferdename"]
            if !nameField.waitForExistence(timeout: timeout) {
                screenshot("01b_nach_pferd_plus")
                XCTFail("Formular 'Neues Pferd' erschien nicht")
            }
            nameField.tap()
            nameField.typeText(horseName)

            // Intervall-Stepper im Formular bedienen (Hufschmied 42 -> 43)
            let stepperButtons = app.steppers.firstMatch.buttons
            if stepperButtons.count >= 2 { stepperButtons.element(boundBy: 1).tap() }   // Plus

            screenshot("02_neues_pferd")
            app.buttons["Speichern"].tap()
        }
        XCTAssertTrue(app.buttons["horseRow_\(horseName)"].waitForExistence(timeout: timeout), "Neues Pferd fehlt in der Liste")
        screenshot("03_hauptseite_mit_pferd")

        // --- Detailansicht mit Glasblumen ---
        openHorse(app, name: horseName)
        screenshot("04_detail_glasblumen")

        for id in ["flower_Hufschmied", "flower_Impfung", "flower_Wurmkur"] {
            XCTAssertTrue(app.buttons[id].exists, "\(id) fehlt")
        }

        // --- Blume antippen -> "War heute da" ---
        app.buttons["flower_Hufschmied"].tap()
        let today = app.buttons["War heute da"]
        XCTAssertTrue(today.waitForExistence(timeout: timeout), "Dialog 'War heute da' fehlt")
        screenshot("05_termin_dialog")
        today.tap()
        let hufschmiedInterval = value(of: "interval_Hufschmied_value", in: app) ?? 42
        let expectation = XCTNSPredicateExpectation(
            predicate: NSPredicate { _, _ in self.days(of: "flower_Hufschmied", in: app) == hufschmiedInterval },
            object: nil
        )
        XCTAssertEqual(XCTWaiter().wait(for: [expectation], timeout: timeout), .completed,
                       "Nach 'War heute da' muessten \(hufschmiedInterval) Tage bleiben, Label: \(app.buttons["flower_Hufschmied"].label)")

        // --- Blume antippen -> Datum manuell waehlen ---
        app.buttons["flower_Impfung"].tap()
        let manual = app.buttons["Datum manuell wählen"]
        XCTAssertTrue(manual.waitForExistence(timeout: timeout))
        manual.tap()
        XCTAssertTrue(app.datePickers.firstMatch.waitForExistence(timeout: timeout), "Datumswahl fehlt")
        screenshot("06_datum_waehlen")
        app.buttons["Fertig"].tap()
        XCTAssertFalse(app.datePickers.firstMatch.waitForExistence(timeout: 2), "Datumswahl schliesst nicht")

        // --- Intervall per Plus/Minus und Eingabefeld ---
        let intervalBefore = value(of: "interval_Wurmkur_value", in: app) ?? 90
        app.buttons["interval_Wurmkur_plus"].tap()
        XCTAssertTrue(waitForValue("interval_Wurmkur_value", toBe: intervalBefore + 1, in: app), "Plus beim Wurmkur-Intervall wirkt nicht")
        app.buttons["interval_Wurmkur_minus"].tap()
        XCTAssertTrue(waitForValue("interval_Wurmkur_value", toBe: intervalBefore, in: app), "Minus beim Wurmkur-Intervall wirkt nicht")

        app.buttons["interval_Wurmkur_value"].tap()
        let inputField = app.textFields["Tage"]
        XCTAssertTrue(inputField.waitForExistence(timeout: timeout), "Eingabe-Dialog fehlt")
        inputField.tap()
        clearText(of: inputField)
        inputField.typeText("77")
        screenshot("06b_intervall_eingabe")
        app.buttons["OK"].tap()
        XCTAssertTrue(waitForValue("interval_Wurmkur_value", toBe: 77, in: app),
                      "Direkteingabe 77 wirkt nicht, Wert: \(app.buttons["interval_Wurmkur_value"].label)")
        let wurmkurDaysAfter = days(of: "flower_Wurmkur", in: app)
        XCTAssertNotNil(wurmkurDaysAfter)
        XCTAssertLessThanOrEqual(wurmkurDaysAfter ?? 999, 77, "Blume folgt dem neuen Intervall nicht")

        // --- Erinnerungs-Vorlauf ---
        let reminderBefore = value(of: "reminder_value", in: app) ?? 3
        app.buttons["reminder_plus"].tap()
        XCTAssertTrue(waitForValue("reminder_value", toBe: reminderBefore + 1, in: app), "Plus beim Vorlauf wirkt nicht")
        XCTAssertTrue(app.staticTexts["Erinnerung \(reminderBefore + 1) Tage vor Termin"].waitForExistence(timeout: timeout), "Text zum Vorlauf aktualisiert nicht")
        app.buttons["reminder_minus"].tap()
        XCTAssertTrue(waitForValue("reminder_value", toBe: reminderBefore, in: app), "Minus beim Vorlauf wirkt nicht")

        // --- Benachrichtigungen verwalten: ohne Kontakte alles gesperrt ---
        app.swipeUp()
        let manage = app.buttons["manageNotifications"]
        XCTAssertTrue(manage.waitForExistence(timeout: timeout))
        manage.tap()
        let toggle = app.switches["notify_Hufschmied"]
        XCTAssertTrue(toggle.waitForExistence(timeout: timeout), "Schalter Hufschmied fehlt")
        XCTAssertFalse(toggle.isEnabled, "Ohne Kontakt muss der Schalter gesperrt sein")
        XCTAssertTrue(app.staticTexts["Kein Kontakt hinterlegt"].firstMatch.exists)
        screenshot("07_benachrichtigungen_ohne_kontakt")
        back(app)
        back(app)

        // --- Kontakt anlegen ---
        app.buttons["Kontakte"].tap()
        let emailField = app.textFields["contact_Hufschmied_email"]
        XCTAssertTrue(emailField.waitForExistence(timeout: timeout), "Kontakte-Formular fehlt")
        let nameField = app.textFields["contact_Hufschmied_name"]
        nameField.tap()
        nameField.typeText("Schmied Test")
        emailField.tap()
        emailField.typeText("schmied@example.com")
        screenshot("08_kontakte")
        app.buttons["Fertig"].tap()

        // --- Benachrichtigung aktivieren ---
        openHorse(app, name: horseName)
        app.swipeUp()
        app.buttons["manageNotifications"].tap()
        let toggleNow = app.switches["notify_Hufschmied"]
        XCTAssertTrue(toggleNow.waitForExistence(timeout: timeout))
        XCTAssertTrue(toggleNow.isEnabled, "Mit E-Mail muss der Schalter frei sein")
        XCTAssertTrue(app.staticTexts["Schmied Test"].exists, "Kontaktname fehlt in der Zeile")
        if (toggleNow.value as? String) != "1" {
            toggleNow.tap()
        }
        XCTAssertEqual(toggleNow.value as? String, "1", "Schalter laesst sich nicht einschalten")
        screenshot("09_benachrichtigung_aktiv")
        back(app)
        XCTAssertTrue(app.staticTexts["1 Kontakt aktiv"].waitForExistence(timeout: timeout), "Zaehler '1 Kontakt aktiv' fehlt")

        // --- E-Mail-Sheet ---
        app.buttons["sendEmail"].tap()
        XCTAssertTrue(app.navigationBars["E-Mail senden"].waitForExistence(timeout: timeout))
        XCTAssertTrue(app.staticTexts["schmied@example.com"].exists, "Aktiver Empfaenger fehlt im E-Mail-Sheet")
        screenshot("10_email_sheet")
        // Im Simulator ist kein Mail-Konto eingerichtet -> Hinweis erwartet
        let reminderEntry = app.buttons.matching(NSPredicate(format: "label BEGINSWITH 'Hufschmied-Erinnerung'")).firstMatch
        XCTAssertTrue(reminderEntry.waitForExistence(timeout: timeout), "Eintrag 'Hufschmied-Erinnerung' fehlt")
        reminderEntry.tap()
        let mailHint = app.alerts.firstMatch
        if mailHint.waitForExistence(timeout: 3) {
            XCTAssertTrue(mailHint.staticTexts["E-Mail ist auf diesem Gerät nicht konfiguriert."].exists)
            mailHint.buttons["OK"].tap()
        }
        app.buttons["Schließen"].tap()

        // --- Kalender ---
        app.buttons["saveCalendar"].tap()
        allowSystemDialogIfShown(timeout: 4)
        let calendarAlert = app.alerts["Kalender"]
        XCTAssertTrue(calendarAlert.waitForExistence(timeout: timeout), "Kalender-Rueckmeldung fehlt")
        let calendarText = calendarAlert.staticTexts.allElementsBoundByIndex.map(\.label).joined(separator: " ")
        XCTAssertTrue(calendarText.contains("gespeichert") || calendarText.contains("vorhanden"),
                      "Unerwartete Kalender-Meldung: \(calendarText)")
        screenshot("11_kalender_meldung")
        calendarAlert.buttons["OK"].tap()

        // --- Farbschema auf der Hauptseite steuert die Glasblumen ---
        back(app)
        app.buttons["colorScheme_Orange"].tap()
        openHorse(app, name: horseName)
        screenshot("12_detail_orange")
        back(app)
        app.buttons["colorScheme_Grau"].tap()
        openHorse(app, name: horseName)
        screenshot("13_detail_grau")
        back(app)
        app.buttons["colorScheme_Hellblau"].tap()
        XCTAssertTrue(app.descendants(matching: .any)["colorScheme_custom"].firstMatch.waitForExistence(timeout: timeout), "Freie Farbwahl fehlt auf der Hauptseite")
        screenshot("14_hauptseite_farbschema")

        // --- Pferd loeschen ---
        app.buttons["horseRow_\(horseName)"].firstMatch.swipeLeft()
        let delete = app.buttons["Löschen"]
        XCTAssertTrue(delete.waitForExistence(timeout: timeout), "Loeschen per Wischen fehlt")
        delete.tap()
        XCTAssertFalse(app.buttons["horseRow_\(horseName)"].waitForExistence(timeout: 2), "Pferd wurde nicht geloescht")
    }

    // MARK: - 2. Design-Screenshots mit Demo-Pferd

    private func demoArguments(daysAgo: String, photo: Bool) -> [String] {
        var args = ["-demoHorse", "-demoDaysAgo", daysAgo]
        if photo, let path = ProcessInfo.processInfo.environment["UITEST_DEMO_PHOTO"], !path.isEmpty {
            args += ["-demoHorsePhoto", path]
        }
        return args
    }

    private func waitForDetail(_ app: XCUIApplication) {
        XCTAssertTrue(app.buttons["flower_Hufschmied"].waitForExistence(timeout: timeout), "Demo-Detailansicht fehlt")
        // Kurz warten, bis Material und Foto gerendert sind
        RunLoop.current.run(until: Date().addingTimeInterval(1.0))
    }

    func test02_designNormal() throws {
        let app = launch(demoArguments(daysAgo: "30,120,10", photo: true))
        waitForDetail(app)
        XCTAssertEqual(days(of: "flower_Hufschmied", in: app), 12)
        XCTAssertEqual(days(of: "flower_Impfung", in: app), 60)
        XCTAssertEqual(days(of: "flower_Wurmkur", in: app), 80)
        screenshot("20_design_normal_foto")
        back(app)
        XCTAssertTrue(app.buttons["horseRow_Demo"].waitForExistence(timeout: timeout))
        screenshot("25_hauptseite_mit_demo")
    }

    /// Umschalter Glas / Classic / Blume: je ein Screenshot, danach zurueck auf Glas
    func test07_designModi() throws {
        let app = launch(demoArguments(daysAgo: "30,120,10", photo: true))
        waitForDetail(app)
        for (mode, shot) in [("Glass", "30_modus_glas"), ("Classic", "31_modus_classic"), ("Blume", "32_modus_blume")] {
            let button = app.buttons["designMode_\(mode)"]
            XCTAssertTrue(button.waitForExistence(timeout: timeout), "Umschalter \(mode) fehlt")
            button.tap()
            XCTAssertTrue(app.buttons["flower_Hufschmied"].waitForExistence(timeout: timeout), "Blumen in \(mode) fehlen")
            XCTAssertEqual(days(of: "flower_Hufschmied", in: app), 12, "Tage in \(mode)")
            screenshot(shot)
            // Aktionsknoepfe unterhalb der Blumen
            app.swipeUp()
            XCTAssertTrue(app.buttons["sendEmail"].waitForExistence(timeout: timeout), "E-Mail-Knopf in \(mode) fehlt")
            screenshot(shot + "_knoepfe")
            app.swipeDown()
            // Hauptseite: Farbwahl je nach Modus
            back(app)
            XCTAssertTrue(app.buttons["horseRow_Demo"].waitForExistence(timeout: timeout))
            let custom = app.descendants(matching: .any)["colorScheme_custom"].exists
            let spheres = app.buttons["colorScheme_Hellblau"].exists
            switch mode {
            case "Glass":   XCTAssertTrue(custom && spheres, "Glas: Kugeln + Farbwahl")
            case "Blume":   XCTAssertTrue(spheres && !custom, "Blume: nur Kugeln")
            default:        XCTAssertTrue(!spheres && !custom, "Classic: keine Farbwahl")
            }
            screenshot(shot + "_hauptseite")
            app.buttons["horseRow_Demo"].tap()
            waitForDetail(app)
        }
        app.buttons["designMode_Glass"].tap()
    }

    func test03_designOhneFoto() throws {
        let app = launch(demoArguments(daysAgo: "30,120,10", photo: false))
        waitForDetail(app)
        screenshot("21_design_ohne_foto")
    }

    func test04_designUeberfaellig() throws {
        let app = launch(demoArguments(daysAgo: "60,200,100", photo: true))
        waitForDetail(app)
        XCTAssertEqual(days(of: "flower_Hufschmied", in: app), -18)
        XCTAssertEqual(days(of: "flower_Impfung", in: app), -20)
        XCTAssertEqual(days(of: "flower_Wurmkur", in: app), -10)
        screenshot("22_design_ueberfaellig")
    }

    func test05_designEinTag() throws {
        let app = launch(demoArguments(daysAgo: "41,179,89", photo: true))
        waitForDetail(app)
        XCTAssertEqual(days(of: "flower_Hufschmied", in: app), 1)
        XCTAssertTrue(app.buttons["flower_Hufschmied"].label.hasPrefix("1 Tag,"), "Einzahl 'Tag' fehlt: \(app.buttons["flower_Hufschmied"].label)")
        screenshot("23_design_ein_tag")
    }

    func test06_designFrisch() throws {
        let app = launch(demoArguments(daysAgo: "0,0,0", photo: true))
        waitForDetail(app)
        XCTAssertEqual(days(of: "flower_Hufschmied", in: app), 42)
        screenshot("24_design_frisch")
    }
}
