import Cocoa

final class SnapGuidelineWindow: NSWindow {
    static let snapThreshold: CGFloat = 16

    private let guideView = SnapGuidelineView()

    init(screen: NSScreen) {
        super.init(
            contentRect: screen.frame,
            styleMask: .borderless,
            backing: .buffered,
            defer: false
        )
        isOpaque           = false
        backgroundColor    = .clear
        ignoresMouseEvents = true
        level              = .floating
        collectionBehavior = [.canJoinAllSpaces, .transient, .ignoresCycle]
        hasShadow          = false
        animationBehavior  = .none

        guideView.frame            = NSRect(origin: .zero, size: screen.frame.size)
        guideView.autoresizingMask = [.width, .height]
        contentView?.addSubview(guideView)
    }

    func update(screen: NSScreen, panelFrame: NSRect) {
        if frame != screen.frame {
            setFrame(screen.frame, display: false)
        }
        guideView.screenFrame  = screen.frame
        guideView.visibleFrame = screen.visibleFrame
        guideView.panelFrame   = panelFrame
        guideView.needsDisplay = true
    }
}

private final class SnapGuidelineView: NSView {
    var screenFrame: NSRect  = .zero
    var visibleFrame: NSRect = .zero
    var panelFrame: NSRect   = .zero

    override func draw(_ dirtyRect: NSRect) {
        guard let ctx = NSGraphicsContext.current?.cgContext else { return }

        let centerX    = screenFrame.midX - screenFrame.minX
        let suggestedY = visibleFrame.midY - screenFrame.minY
        let threshold  = SnapGuidelineWindow.snapThreshold

        let nearX = abs(panelFrame.midX - screenFrame.midX) < threshold
        let nearY = abs(panelFrame.midY - visibleFrame.midY) < threshold

        ctx.setLineCap(.round)
        ctx.setLineDash(phase: 0, lengths: [2, 7])

        draw(ctx, from: CGPoint(x: centerX, y: 0),           to: CGPoint(x: centerX, y: bounds.height), active: nearX)
        draw(ctx, from: CGPoint(x: 0, y: suggestedY),        to: CGPoint(x: bounds.width, y: suggestedY), active: nearY)
    }

    private func draw(_ ctx: CGContext, from: CGPoint, to: CGPoint, active: Bool) {
        if active {
            ctx.setStrokeColor(NSColor.controlAccentColor.withAlphaComponent(0.85).cgColor)
            ctx.setLineWidth(1.5)
        } else {
            ctx.setStrokeColor(NSColor(white: 0.55, alpha: 0.55).cgColor)
            ctx.setLineWidth(1.0)
        }
        ctx.move(to: from)
        ctx.addLine(to: to)
        ctx.strokePath()
    }
}
