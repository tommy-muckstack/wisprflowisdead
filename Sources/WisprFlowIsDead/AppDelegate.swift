import AppKit
import Combine
import FlowCore
import FlowVoice
import SwiftUI
import Sparkle

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate, NSWindowDelegate {
    let controller = DictationController()
    let nav = HubNavigation()
    private(set) var hotkeys: HotkeyMonitor!
    private var bar: FlowBarPanel!
    private var statusItem: NSStatusItem!
    private var hubWindow: NSWindow?
    private var onboardingWindow: NSWindow?
    private var scratchpad: NSPanel?
    private var bag: Set<AnyCancellable> = []
    private var tapRetry: Timer?
    private let updaterController = SPUStandardUpdaterController(startingUpdater: false, updaterDelegate: nil, userDriverDelegate: nil)

    func applicationDidFinishLaunching(_ notification: Notification) {
        Theme.registerFonts()
        hotkeys = HotkeyMonitor(controller: controller)
        bar = FlowBarPanel(controller: controller)
        setUpStatusItem()
        updaterController.startUpdater()
        applyDockPolicy()

        controller.onSettingsChange = { [weak self] in
            self?.applyDockPolicy()
            self?.bar.place()
            self?.bar.refreshVisibility()
        }
        controller.$phase.combineLatest(controller.$notice, controller.$hiddenUntil)
            .receive(on: RunLoop.main)
            .sink { [weak self] _ in self?.bar.refreshVisibility() }
            .store(in: &bag)

        controller.toggleScratchpad = { [weak self] in self?.toggleScratchpad() }
        controller.refreshMicrophones()
        controller.loadModel()
        VoiceEngine.shared.warmMicrophone()
        startHotkeys()

        if controller.settings.onboardingComplete {
            bar.refreshVisibility()
        } else {
            showOnboarding()
        }
    }

    /// The event tap needs Accessibility; keep retrying until it is granted.
    private func startHotkeys() {
        hotkeys.start()
        guard !hotkeys.isRunning else { return }
        tapRetry = Timer.scheduledTimer(withTimeInterval: 2, repeats: true) { [weak self] timer in
            Task { @MainActor in
                guard let self else { return }
                self.hotkeys.start()
                if self.hotkeys.isRunning { timer.invalidate() }
            }
        }
    }

    func applicationShouldHandleReopen(_ sender: NSApplication, hasVisibleWindows flag: Bool) -> Bool {
        showHub(page: nav.page)
        return true
    }

    private func applyDockPolicy() {
        let windowOpen = hubWindow?.isVisible == true || onboardingWindow?.isVisible == true
        NSApp.setActivationPolicy(controller.settings.showInDock || windowOpen ? .regular : .accessory)
    }

    // MARK: Menu bar

    private func setUpStatusItem() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
        statusItem.button?.image = BrandAssets.menuBarIcon()
        let menu = NSMenu()
        menu.addItem(item("Open WisprFlowIsDead", #selector(openHub)))
        menu.addItem(item("Shortcuts…", #selector(openSettings)))
        menu.addItem(item("Scratchpad", #selector(openScratchpad)))
        menu.addItem(item("Notetaker", #selector(openNotetaker)))
        menu.addItem(item("Paste last transcript", #selector(pasteLast)))
        menu.addItem(item("Copy last transcript", #selector(copyLast)))
        menu.addItem(.separator())
        let updateItem = NSMenuItem(title: "Check for Updates…", action: #selector(SPUStandardUpdaterController.checkForUpdates(_:)), keyEquivalent: "")
        updateItem.target = updaterController
        menu.addItem(updateItem)
        menu.addItem(item("Quit", #selector(quit), key: "q"))
        statusItem.menu = menu
    }

    private func item(_ title: String, _ action: Selector, key: String = "") -> NSMenuItem {
        let i = NSMenuItem(title: title, action: action, keyEquivalent: key)
        i.target = self
        return i
    }

    @objc private func openHub() { showHub(page: .home) }
    @objc private func openSettings() { showHub(page: .settings) }
    @objc private func openScratchpad() { toggleScratchpad() }
    @objc private func openNotetaker() { showHub(page: .meetings) }
    @objc private func pasteLast() { controller.pasteLast() }
    @objc private func copyLast() { controller.copyLast() }
    @objc private func quit() { NSApp.terminate(nil) }

    // MARK: Windows

    func showHub(page: HubPage) {
        nav.page = page
        if hubWindow == nil {
            let w = NSWindow(contentRect: NSRect(x: 0, y: 0, width: 1040, height: 720),
                             styleMask: [.titled, .closable, .miniaturizable, .resizable, .fullSizeContentView],
                             backing: .buffered, defer: false)
            w.titlebarAppearsTransparent = true
            w.titleVisibility = .hidden
            w.isReleasedWhenClosed = false
            w.contentView = NSHostingView(rootView: HubView(controller: controller, nav: nav))
            w.center()
            w.delegate = self
            hubWindow = w
        }
        hubWindow?.makeKeyAndOrderFront(nil)
        applyDockPolicy()
        NSApp.activate(ignoringOtherApps: true)
    }

    func showOnboarding() {
        let w = NSWindow(contentRect: NSRect(x: 0, y: 0, width: 640, height: 520),
                         styleMask: [.titled, .closable, .fullSizeContentView],
                         backing: .buffered, defer: false)
        w.titlebarAppearsTransparent = true
        w.titleVisibility = .hidden
        w.isReleasedWhenClosed = false
        w.contentView = NSHostingView(rootView: OnboardingView(controller: controller) { [weak self] in
            self?.onboardingWindow?.close()
            self?.bar.refreshVisibility()
            self?.showHub(page: .home)
        })
        w.center()
        w.delegate = self
        onboardingWindow = w
        w.makeKeyAndOrderFront(nil)
        applyDockPolicy()
        NSApp.activate(ignoringOtherApps: true)
    }

    /// Floating notepad that stays above other apps (Opt+S by default).
    func toggleScratchpad() {
        if let p = scratchpad, p.isVisible { p.orderOut(nil); controller.scratchSink = nil; return }
        if scratchpad == nil {
            let p = NSPanel(contentRect: NSRect(x: 0, y: 0, width: 620, height: 420),
                            styleMask: [.titled, .closable, .resizable, .utilityWindow, .fullSizeContentView],
                            backing: .buffered, defer: false)
            p.title = "Scratchpad"
            p.titlebarAppearsTransparent = true
            p.isFloatingPanel = true
            p.level = .floating
            p.hidesOnDeactivate = false
            p.isReleasedWhenClosed = false
            p.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
            p.contentView = NSHostingView(rootView: ScratchpadView(controller: controller))
            p.center()
            p.delegate = self
            scratchpad = p
        }
        scratchpad?.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }

    func windowDidBecomeKey(_ notification: Notification) {
        guard (notification.object as? NSPanel) === scratchpad else { return }
        controller.scratchSink = { [weak self] text in
            guard let self else { return }
            let current = ScratchNote.search(self.controller.notes, query: "").first?.id
            ScratchpadView.append(text, to: self.controller, noteID: current)
        }
    }

    func windowDidResignKey(_ notification: Notification) {
        if (notification.object as? NSPanel) === scratchpad { controller.scratchSink = nil }
    }

    func windowWillClose(_ notification: Notification) {
        if (notification.object as? NSPanel) === scratchpad { controller.scratchSink = nil }
        DispatchQueue.main.async { [weak self] in self?.applyDockPolicy() }
    }
}
