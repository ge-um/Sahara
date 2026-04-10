import XCTest

@MainActor
class ScreenshotTests: XCTestCase {
    var app: XCUIApplication!

    private var isMac: Bool {
        #if targetEnvironment(macCatalyst)
        return true
        #else
        return false
        #endif
    }

    private var isPhone: Bool {
        #if targetEnvironment(macCatalyst)
        return false
        #else
        return UIDevice.current.userInterfaceIdiom == .phone
        #endif
    }

    // MARK: - Setup

    override func setUpWithError() throws {
        continueAfterFailure = false
        app = XCUIApplication()
        app.launchArguments.append("-SCREENSHOT_MODE")

        #if !targetEnvironment(macCatalyst)
        setupSnapshot(app, waitForAnimations: false)
        #endif

        app.launch()

        #if targetEnvironment(macCatalyst)
        // Mac — 콘텐츠 렌더링 대기
        let firstTab = app.buttons["sahara.tab.gallery"]
        _ = firstTab.waitForExistence(timeout: 5)

        addUIInterruptionMonitor(withDescription: "notification") { alert in
            alert.buttons.element(boundBy: 1).tap()
            return true
        }
        #else
        if !isPhone {
            XCUIDevice.shared.orientation = .landscapeLeft
        }

        let springboard = XCUIApplication(bundleIdentifier: "com.apple.springboard")
        let alert = springboard.alerts.firstMatch
        if alert.waitForExistence(timeout: 3) {
            alert.buttons.element(boundBy: 1).tap()
        }
        #endif
    }

    // MARK: - Platform Helpers

    private func takeScreenshot(_ name: String) {
        #if targetEnvironment(macCatalyst)
        let window = app.windows.firstMatch
        _ = window.waitForExistence(timeout: 2)
        let screenshot = window.screenshot()
        let attachment = XCTAttachment(screenshot: screenshot)
        attachment.name = name
        attachment.lifetime = .keepAlways
        add(attachment)

        let lang = (try? String(contentsOfFile: "/tmp/sahara-screenshot-lang.txt", encoding: .utf8))?.trimmingCharacters(in: .whitespacesAndNewlines) ?? "ko"
        let dir = NSHomeDirectory() + "/sahara-mac-screenshots/\(lang)"
        try? FileManager.default.createDirectory(atPath: dir, withIntermediateDirectories: true)
        try? screenshot.pngRepresentation.write(to: URL(fileURLWithPath: "\(dir)/Mac (2880x1800)-\(name).png"))
        #else
        snapshot(name)
        #endif
    }

    private func flipCardForward(_ element: XCUIElement) {
        #if targetEnvironment(macCatalyst)
        let start = element.coordinate(withNormalizedOffset: CGVector(dx: 0.8, dy: 0.5))
        let end = element.coordinate(withNormalizedOffset: CGVector(dx: 0.2, dy: 0.5))
        start.press(forDuration: 0.1, thenDragTo: end)
        #else
        element.swipeLeft()
        #endif
    }

    private func flipCardBackward(_ element: XCUIElement) {
        #if targetEnvironment(macCatalyst)
        let start = element.coordinate(withNormalizedOffset: CGVector(dx: 0.2, dy: 0.5))
        let end = element.coordinate(withNormalizedOffset: CGVector(dx: 0.8, dy: 0.5))
        start.press(forDuration: 0.1, thenDragTo: end)
        #else
        element.swipeRight()
        #endif
    }

    // MARK: - 초기 설정

    func test_00_setupTheme() {
        let settingsTab = app.buttons["sahara.tab.settings"]
        guard settingsTab.waitForExistence(timeout: 5) else { return }
        settingsTab.tap()

        let bgTheme = app.otherElements["sahara.settings.backgroundTheme"]
        guard bgTheme.waitForExistence(timeout: 3) else { return }
        bgTheme.tap()

        let seg = app.segmentedControls.firstMatch
        if seg.waitForExistence(timeout: 3) {
            seg.buttons.element(boundBy: 1).tap()
        }

        let primaryGradient = app.otherElements["sahara.bgTheme.gradient.0"]
        if primaryGradient.waitForExistence(timeout: 3) { primaryGradient.tap() }

        let navRightButtons = app.buttons.matching(NSPredicate(format: "identifier == 'sahara.nav.save'"))
        if navRightButtons.firstMatch.waitForExistence(timeout: 2) {
            navRightButtons.firstMatch.tap()
        } else {
            app.coordinate(withNormalizedOffset: CGVector(dx: 0.9, dy: 0.12)).tap()
        }
    }

    // MARK: - 스크린샷

    func test_01_calendar() {
        navigateToMarch()
        takeScreenshot("01_어디서든_추억을_기록하세요")
    }

    func test_02_cardFlow() {
        navigateToMarch()

        let cell19 = app.cells.matching(identifier: "sahara.calendar.cell").element(boundBy: 18)
        guard cell19.waitForExistence(timeout: 3) else { return }
        cell19.tap()

        let cardCell = app.cells.firstMatch
        guard cardCell.waitForExistence(timeout: 3) else { return }
        cardCell.tap()

        // #06 card_back
        let cardFront = app.otherElements["sahara.photoCard.front"]
        guard cardFront.waitForExistence(timeout: 3) else { return }
        flipCardForward(cardFront)
        _ = app.otherElements["sahara.photoCard.back"].waitForExistence(timeout: 2)
        takeScreenshot("06_카드_뒷면엔_메모가_숨어있어요")

        // #04 card_info
        let cardBack = app.otherElements["sahara.photoCard.back"]
        flipCardBackward(cardBack)
        let editButton = app.buttons["sahara.cardDetail.edit"]
        guard editButton.waitForExistence(timeout: 3) else { return }
        editButton.tap()
        _ = app.buttons["sahara.cardInfo.photoEdit"].waitForExistence(timeout: 3)
        takeScreenshot("04_날짜_장소_메모를_기록하고")
    }

    // #02 editor — 3/13 편집 화면 (그리기 탭)
    func test_02b_editor() {
        navigateToMarch()

        let cell13 = app.cells.matching(identifier: "sahara.calendar.cell").element(boundBy: 12)
        guard cell13.waitForExistence(timeout: 3) else { return }
        cell13.tap()

        let cardCell = app.cells.firstMatch
        guard cardCell.waitForExistence(timeout: 3) else { return }
        cardCell.tap()

        let editBtn = app.buttons["sahara.cardDetail.edit"]
        guard editBtn.waitForExistence(timeout: 3) else { return }
        editBtn.tap()

        let photoEditBtn = app.buttons["sahara.cardInfo.photoEdit"]
        guard photoEditBtn.waitForExistence(timeout: 3) else { return }
        photoEditBtn.tap()

        _ = app.otherElements["sahara.mediaEditor.view"].waitForExistence(timeout: 2)
        let drawingBtn = app.buttons["sahara.mediaEditor.mode.drawing"]
        guard drawingBtn.waitForExistence(timeout: 2) else { return }
        drawingBtn.tap()
        takeScreenshot("02_사진을_자유롭게_편집하고")
    }

    func test_03_cardFront() {
        navigateToMarch()

        let cell = app.cells.matching(identifier: "sahara.calendar.cell").element(boundBy: 20)
        guard cell.waitForExistence(timeout: 3) else { return }
        cell.tap()

        let cardCell = app.cells.firstMatch
        guard cardCell.waitForExistence(timeout: 3) else { return }
        cardCell.tap()

        _ = app.otherElements["sahara.photoCard.front"].waitForExistence(timeout: 3)
        takeScreenshot("03_나만의_카드로_만들어요")
    }

    func test_04_folderCards() {
        let folderBtn = app.buttons["sahara.gallery.folder"]
        guard folderBtn.waitForExistence(timeout: 5) else { return }
        folderBtn.tap()

        let firstFolder = app.cells.firstMatch
        guard firstFolder.waitForExistence(timeout: 3) else { return }
        firstFolder.tap()

        _ = app.cells.firstMatch.waitForExistence(timeout: 3)
        takeScreenshot("05_한_눈에_모아보세요")
    }

    func test_05_settings() {
        let settingsTab = app.buttons["sahara.tab.settings"]
        guard settingsTab.waitForExistence(timeout: 5) else { return }
        settingsTab.tap()

        let syncItem = app.otherElements["sahara.settings.cloudSync"]
        guard syncItem.waitForExistence(timeout: 3) else { return }
        let toggle = syncItem.switches.firstMatch
        if toggle.exists {
            toggle.tap()
            sleep(1)
            if app.alerts.buttons.firstMatch.waitForExistence(timeout: 3) {
                app.alerts.buttons.firstMatch.tap()
            } else if app.dialogs.buttons.firstMatch.waitForExistence(timeout: 1) {
                app.dialogs.buttons.firstMatch.tap()
            } else if app.sheets.buttons.firstMatch.waitForExistence(timeout: 1) {
                app.sheets.buttons.firstMatch.tap()
            }
            sleep(1)
        }
        takeScreenshot("09_동기화로_소중한_추억을_지켜주세요")
    }

    func test_06_backgroundTheme() {
        let settingsTab = app.buttons["sahara.tab.settings"]
        guard settingsTab.waitForExistence(timeout: 5) else { return }
        settingsTab.tap()

        let bgTheme = app.otherElements["sahara.settings.backgroundTheme"]
        guard bgTheme.waitForExistence(timeout: 3) else { return }
        bgTheme.tap()

        let seg = app.segmentedControls.firstMatch
        if seg.waitForExistence(timeout: 3) {
            seg.buttons.element(boundBy: 1).tap()
        }

        let warmGradient = app.otherElements["sahara.bgTheme.gradient.1"]
        if warmGradient.waitForExistence(timeout: 3) { warmGradient.tap() }

        let navSave = app.buttons.matching(NSPredicate(format: "identifier == 'sahara.nav.save'"))
        if navSave.firstMatch.waitForExistence(timeout: 2) {
            navSave.firstMatch.tap()
        } else {
            app.coordinate(withNormalizedOffset: CGVector(dx: 0.9, dy: 0.12)).tap()
        }

        let bgTheme2 = app.otherElements["sahara.settings.backgroundTheme"]
        guard bgTheme2.waitForExistence(timeout: 3) else { return }
        bgTheme2.tap()

        let seg2 = app.segmentedControls.firstMatch
        if seg2.waitForExistence(timeout: 3) {
            seg2.buttons.element(boundBy: 0).tap()
        }

        let whiteSolid = app.otherElements["sahara.bgTheme.solid.11"]
        if whiteSolid.waitForExistence(timeout: 2) { whiteSolid.tap() }

        takeScreenshot("07_테마를_바꿔_나만의_분위기를_만들고")
    }

    // MARK: - Helper

    private func navigateToMarch() {
        let prevButton = app.buttons["sahara.calendar.prev"]
        guard prevButton.waitForExistence(timeout: 5) else { return }
        prevButton.tap()
        sleep(1)
    }
}
