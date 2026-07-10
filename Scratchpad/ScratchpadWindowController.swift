import Cocoa

private let kFrameKey = "scratchpadWindowFrame"
private let kTextKey  = "scratchpadTextContent"

class ScratchpadWindowController: NSWindowController, NSWindowDelegate {

    private(set) var textView: ScratchpadTextView!
    private var isHiding    = false
    private var guideWindow: SnapGuidelineWindow?
    private var dragMonitor: Any?

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

        let font = NSFont(name: "MesloLGS-Regular", size: 14)
            ?? NSFont(name: "Menlo-Regular", size: 14)
            ?? NSFont.monospacedSystemFont(ofSize: 14, weight: .regular)

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
        tv.textContainerInset                    = NSSize(width: 14, height: 0)

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
        hideGuidelines()
        saveFrame()
        window?.orderOut(nil)
        isHiding = false
    }

    var isVisible: Bool { window?.isVisible ?? false }

    // MARK: - Screen positioning

    private func moveToActiveScreenIfNeeded(_ panel: NSPanel) {
        let mouseLocation = NSEvent.mouseLocation
        guard let target = NSScreen.screens.first(where: { $0.frame.contains(mouseLocation) }) ?? NSScreen.main else { return }

        let panelCenter = NSPoint(x: panel.frame.midX, y: panel.frame.midY)
        guard let source = NSScreen.screens.first(where: { $0.frame.contains(panelCenter) }),
              source != target else { return }

        let sourceVF = source.visibleFrame
        let targetVF = target.visibleFrame
        let size     = panel.frame.size

        let relX = (panel.frame.minX - sourceVF.minX) / sourceVF.width
        let relY = (panel.frame.minY - sourceVF.minY) / sourceVF.height

        let newX = max(targetVF.minX, min(targetVF.minX + relX * targetVF.width, targetVF.maxX - size.width))
        let newY = max(targetVF.minY, min(targetVF.minY + relY * targetVF.height, targetVF.maxY - size.height))

        panel.setFrameOrigin(NSPoint(x: newX, y: newY))
    }

    // MARK: - Frame persistence

    private func saveFrame() {
        guard let f = window?.frame else { return }
        UserDefaults.standard.set(NSStringFromRect(f), forKey: kFrameKey)
    }

    // MARK: - Snap guidelines

    func windowWillMove(_ notification: Notification) {
        guard guideWindow == nil,
              let panel = window,
              let screen = panel.screen ?? NSScreen.main else { return }

        let gw = SnapGuidelineWindow(screen: screen)
        gw.order(.below, relativeTo: panel.windowNumber)
        guideWindow = gw
        updateGuidelines()

        dragMonitor = NSEvent.addGlobalMonitorForEvents(matching: .leftMouseUp) { [weak self] _ in
            self?.snapOnRelease()
            self?.hideGuidelines()
        }
    }

    private func updateGuidelines() {
        guard let gw = guideWindow,
              let panel = window,
              let screen = panel.screen ?? NSScreen.main else { return }
        gw.update(screen: screen, panelFrame: panel.frame)
    }

    private func snapOnRelease() {
        guard let panel = window,
              let screen = panel.screen ?? NSScreen.main else { return }

        let threshold  = SnapGuidelineWindow.snapThreshold
        let centerX    = screen.frame.midX
        let suggestedY = screen.visibleFrame.midY

        let nearX = abs(panel.frame.midX - centerX)    < threshold
        let nearY = abs(panel.frame.midY - suggestedY) < threshold
        guard nearX || nearY else { return }

        var origin = panel.frame.origin
        if nearX { origin.x = centerX    - panel.frame.width  / 2 }
        if nearY { origin.y = suggestedY - panel.frame.height / 2 }
        panel.setFrameOrigin(origin)
        saveFrame()
    }

    private func hideGuidelines() {
        guideWindow?.orderOut(nil)
        guideWindow = nil
        if let monitor = dragMonitor {
            NSEvent.removeMonitor(monitor)
            dragMonitor = nil
        }
    }

    // MARK: - NSWindowDelegate

    func windowDidResize(_ notification: Notification) { saveFrame() }

    func windowDidMove(_ notification: Notification) {
        saveFrame()
        if guideWindow != nil { updateGuidelines() }
    }

    func windowDidResignKey(_ notification: Notification) {
        hideWindow()
    }

    func windowWillClose(_ notification: Notification) {
        saveFrame()
        persistText()
    }
}
