import Cocoa

private let kFrameKey = "scratchpadWindowFrame"
private let kTextKey  = "scratchpadTextContent"

class ScratchpadWindowController: NSWindowController, NSWindowDelegate {

    private(set) var textView: ScratchpadTextView!
    private var isHiding = false

    init() {
        let savedFrameStr = UserDefaults.standard.string(forKey: kFrameKey)
        let defaultFrame  = NSRect(x: 0, y: 0, width: 500, height: 340)
        let frame         = savedFrameStr.map { NSRectFromString($0) } ?? defaultFrame

        let panel = NSPanel(
            contentRect: frame,
            styleMask: [.titled, .resizable, .fullSizeContentView],
            backing: .buffered,
            defer: false
        )

        super.init(window: panel)

        panel.delegate                   = self
        panel.titlebarAppearsTransparent = true
        panel.titleVisibility            = .hidden
        panel.isMovableByWindowBackground = true
        panel.level                      = .floating
        panel.collectionBehavior         = [.canJoinAllSpaces, .transient, .ignoresCycle]
        panel.minSize                    = NSSize(width: 280, height: 180)

        panel.standardWindowButton(.closeButton)?.isHidden    = true
        panel.standardWindowButton(.miniaturizeButton)?.isHidden = true
        panel.standardWindowButton(.zoomButton)?.isHidden     = true

        if savedFrameStr == nil { panel.center() }

        setupTextView()
        loadText()
        // Initial color pass (viewDidChangeEffectiveAppearance fires later)
        textView.applyColors()
    }

    required init?(coder: NSCoder) { fatalError() }

    // MARK: - Setup

    private func setupTextView() {
        guard let content = window?.contentView else { return }

        let font = NSFont(name: "MesloLGS-Regular", size: 15)
            ?? NSFont(name: "Menlo-Regular", size: 15)
            ?? NSFont.monospacedSystemFont(ofSize: 15, weight: .regular)

        let scroll = NSScrollView(frame: content.bounds)
        scroll.autoresizingMask  = [.width, .height]
        scroll.hasVerticalScroller   = true
        scroll.hasHorizontalScroller = false
        scroll.drawsBackground   = false
        scroll.borderType        = .noBorder

        let size = scroll.contentSize
        let tv   = ScratchpadTextView(frame: NSRect(origin: .zero, size: size))
        tv.minSize                 = NSSize(width: 0, height: size.height)
        tv.maxSize                 = NSSize(width: CGFloat.greatestFiniteMagnitude, height: CGFloat.greatestFiniteMagnitude)
        tv.isVerticallyResizable   = true
        tv.isHorizontallyResizable = false
        tv.autoresizingMask        = [.width]
        tv.textContainer?.widthTracksTextView = true
        tv.textContainer?.containerSize = NSSize(width: size.width, height: CGFloat.greatestFiniteMagnitude)

        tv.font                          = font
        tv.isRichText                    = false
        tv.importsGraphics               = false
        tv.allowsImageEditing            = false
        tv.isAutomaticQuoteSubstitutionEnabled   = false
        tv.isAutomaticDashSubstitutionEnabled    = false
        tv.isAutomaticSpellingCorrectionEnabled  = false
        tv.isAutomaticTextReplacementEnabled     = false
        tv.isContinuousSpellCheckingEnabled      = false
        tv.isGrammarCheckingEnabled              = false
        tv.textContainerInset                    = NSSize(width: 14, height: 14)

        tv.onEscape = { [weak self] in self?.hideWindow() }

        NotificationCenter.default.addObserver(
            self,
            selector: #selector(textDidChange),
            name: NSText.didChangeNotification,
            object: tv
        )

        scroll.documentView = tv
        content.addSubview(scroll)
        textView = tv
    }

    // MARK: - Text persistence

    private func loadText() {
        if let saved = UserDefaults.standard.string(forKey: kTextKey) {
            textView.string = saved
        }
    }

    func persistText() {
        UserDefaults.standard.set(textView.string, forKey: kTextKey)
    }

    @objc private func textDidChange() {
        persistText()
    }

    // MARK: - Show / Hide

    func showWindow() {
        guard let panel = window as? NSPanel else { return }
        moveToActiveScreenIfNeeded(panel)
        panel.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
        textView.setSelectedRange(NSRange(location: 0, length: 0))
        textView.scrollToBeginningOfDocument(nil)
        panel.makeFirstResponder(textView)
    }

    func hideWindow() {
        guard !isHiding else { return }
        isHiding = true
        saveFrame()
        window?.orderOut(nil)
        isHiding = false
    }

    var isVisible: Bool { window?.isVisible ?? false }

    // MARK: - Screen positioning

    private func moveToActiveScreenIfNeeded(_ panel: NSPanel) {
        let mouseLocation = NSEvent.mouseLocation
        guard let target = NSScreen.screens.first(where: { $0.frame.contains(mouseLocation) }) ?? NSScreen.main,
              panel.screen != target else { return }
        let size = panel.frame.size
        let sf   = target.visibleFrame
        panel.setFrameOrigin(NSPoint(x: sf.midX - size.width / 2, y: sf.midY - size.height / 2))
    }

    // MARK: - Frame persistence

    private func saveFrame() {
        guard let f = window?.frame else { return }
        UserDefaults.standard.set(NSStringFromRect(f), forKey: kFrameKey)
    }

    // MARK: - NSWindowDelegate

    func windowDidResize(_ notification: Notification) { saveFrame() }
    func windowDidMove(_ notification: Notification)   { saveFrame() }

    func windowDidResignKey(_ notification: Notification) {
        hideWindow()
    }

    func windowWillClose(_ notification: Notification) {
        saveFrame()
        persistText()
    }
}
