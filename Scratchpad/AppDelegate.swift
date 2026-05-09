import Cocoa
import Carbon.HIToolbox

class AppDelegate: NSObject, NSApplicationDelegate {

    private var statusItem: NSStatusItem!
    private var windowController: ScratchpadWindowController!
    private var hotKeyRef: EventHotKeyRef?
    private var eventHandlerRef: EventHandlerRef?
    private var showHideItem: NSMenuItem!
    private var aboutPanel: NSPanel?

    // MARK: - Lifecycle

    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.accessory)
        setupStatusItem()
        windowController = ScratchpadWindowController()
        setupHotKey()
    }

    func applicationWillTerminate(_ notification: Notification) {
        windowController.persistText()
        if let ref = hotKeyRef      { UnregisterEventHotKey(ref) }
        if let ref = eventHandlerRef { RemoveEventHandler(ref) }
    }

    // MARK: - Status item / menu

    private func setupStatusItem() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
        statusItem.button?.image = NSImage(
            systemSymbolName: "note.text",
            accessibilityDescription: "Scratchpad"
        )

        let menu = NSMenu()
        menu.delegate = self

        showHideItem = NSMenuItem(
            title: "Show Scratchpad",
            action: #selector(toggleWindow),
            keyEquivalent: ";"
        )
        showHideItem.keyEquivalentModifierMask = [.command, .shift]
        showHideItem.target = self
        menu.addItem(showHideItem)

        menu.addItem(.separator())

        let about = NSMenuItem(title: "About Scratchpad", action: #selector(showAbout), keyEquivalent: "")
        about.target = self
        menu.addItem(about)

        let github = NSMenuItem(title: "View README (on GitHub)...", action: #selector(openGitHub), keyEquivalent: "")
        github.target = self
        menu.addItem(github)

        menu.addItem(.separator())

        let quit = NSMenuItem(title: "Quit", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q")
        menu.addItem(quit)

        statusItem.menu = menu
    }

    // MARK: - Global hotkey (Carbon RegisterEventHotKey — no entitlement needed)

    private func setupHotKey() {
        var spec = EventTypeSpec(
            eventClass: OSType(kEventClassKeyboard),
            eventKind: UInt32(kEventHotKeyPressed)
        )
        let selfPtr = Unmanaged.passUnretained(self).toOpaque()

        // Non-capturing C closure — captures nothing from Swift heap
        let handler: EventHandlerProcPtr = { (_, _, userData) -> OSStatus in
            guard let ptr = userData else { return OSStatus(eventNotHandledErr) }
            let me = Unmanaged<AppDelegate>.fromOpaque(ptr).takeUnretainedValue()
            me.toggleWindow()
            return noErr
        }

        InstallEventHandler(
            GetApplicationEventTarget(),
            handler,
            1, &spec,
            selfPtr,
            &eventHandlerRef
        )

        // kVK_ANSI_Semicolon = 41
        let hkID = EventHotKeyID(signature: OSType(0x53435250), id: 1) // 'SCRP'
        RegisterEventHotKey(
            UInt32(kVK_ANSI_Semicolon),
            UInt32(cmdKey | shiftKey),
            hkID,
            GetApplicationEventTarget(),
            0,
            &hotKeyRef
        )
    }

    // MARK: - Actions

    @objc func toggleWindow() {
        if windowController.isVisible {
            windowController.hideWindow()
        } else {
            windowController.showWindow()
        }
    }

    @objc private func showAbout() {
        NSApp.activate(ignoringOtherApps: true)
        if let panel = aboutPanel, panel.isVisible {
            panel.makeKeyAndOrderFront(nil)
            return
        }
        aboutPanel = buildAboutPanel()
        aboutPanel?.makeKeyAndOrderFront(nil)
    }

    private func buildAboutPanel() -> NSPanel {
        let panel = NSPanel(
            contentRect: NSRect(x: 0, y: 0, width: 280, height: 320),
            styleMask: [.titled, .closable, .fullSizeContentView],
            backing: .buffered,
            defer: false
        )
        panel.titlebarAppearsTransparent = true
        panel.titleVisibility = .hidden
        panel.isMovableByWindowBackground = true
        panel.center()

        let content = panel.contentView!

        let iconConfig = NSImage.SymbolConfiguration(pointSize: 192, weight: .regular)
        let iconImage  = NSImage(systemSymbolName: "note.text", accessibilityDescription: nil)?
            .withSymbolConfiguration(iconConfig)
        let iconView = NSImageView(image: iconImage ?? NSImage())
        iconView.imageScaling = .scaleProportionallyUpOrDown
        NSLayoutConstraint.activate([
            iconView.widthAnchor.constraint(equalToConstant: 192),
            iconView.heightAnchor.constraint(equalToConstant: 192),
        ])

        let nameLabel = NSTextField(labelWithString: "Scratchpad")
        nameLabel.font = NSFont.boldSystemFont(ofSize: 17)
        nameLabel.alignment = .center

        let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? ""
        let versionLabel = NSTextField(labelWithString: "Version \(version)")
        versionLabel.font = NSFont.systemFont(ofSize: 13)
        versionLabel.textColor = .secondaryLabelColor
        versionLabel.alignment = .center

        let stack = NSStackView(views: [iconView, nameLabel, versionLabel])
        stack.orientation  = .vertical
        stack.alignment    = .centerX
        stack.spacing      = 10
        stack.translatesAutoresizingMaskIntoConstraints = false

        content.addSubview(stack)
        NSLayoutConstraint.activate([
            stack.centerXAnchor.constraint(equalTo: content.centerXAnchor),
            stack.centerYAnchor.constraint(equalTo: content.centerYAnchor),
        ])

        return panel
    }

    @objc private func openGitHub() {
        if let url = URL(string: "https://github.com/matthewkeating/scratchpad") {
            NSWorkspace.shared.open(url)
        }
    }
}

// MARK: - NSMenuDelegate

extension AppDelegate: NSMenuDelegate {
    func menuWillOpen(_ menu: NSMenu) {
        showHideItem.title = windowController.isVisible ? "Hide Scratchpad" : "Show Scratchpad"
    }
}
