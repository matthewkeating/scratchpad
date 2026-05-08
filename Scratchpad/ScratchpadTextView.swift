import Cocoa

class ScratchpadTextView: NSTextView {

    var onEscape: (() -> Void)?

    override func performKeyEquivalent(with event: NSEvent) -> Bool {
        let flags = event.modifierFlags.intersection([.command, .shift, .option, .control])
        if flags == .command {
            switch event.charactersIgnoringModifiers {
            case "a": selectAll(nil); return true
            case "c": copy(nil);      return true
            case "x": cut(nil);       return true
            case "v": paste(nil);     return true
            default: break
            }
        }
        return super.performKeyEquivalent(with: event)
    }

    override func keyDown(with event: NSEvent) {
        if event.keyCode == 53 { // kVK_Escape
            onEscape?()
        } else {
            super.keyDown(with: event)
        }
    }

    override func viewDidChangeEffectiveAppearance() {
        super.viewDidChangeEffectiveAppearance()
        applyColors()
    }

    func applyColors() {
        let isDark = effectiveAppearance.bestMatch(from: [.darkAqua, .aqua]) == .darkAqua
        let bg: NSColor
        let fg: NSColor

        if isDark {
            bg = NSColor(red: 0x1e/255.0, green: 0x1e/255.0, blue: 0x1e/255.0, alpha: 1)
            fg = NSColor(red: 0xc1/255.0, green: 0xc6/255.0, blue: 0xc6/255.0, alpha: 1)
        } else {
            bg = .white
            fg = NSColor(red: 0x27/255.0, green: 0x27/255.0, blue: 0x27/255.0, alpha: 1)
        }

        backgroundColor = bg
        textColor = fg
        insertionPointColor = fg

        // Re-color existing text uniformly (isRichText=false, uniform attrs)
        if let storage = textStorage, storage.length > 0 {
            storage.addAttribute(
                .foregroundColor, value: fg,
                range: NSRange(location: 0, length: storage.length)
            )
        }

        // Propagate bg up to the window
        window?.backgroundColor = bg
        enclosingScrollView?.backgroundColor = bg
    }
}
