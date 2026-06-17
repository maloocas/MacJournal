import SwiftUI
import AppKit

// MARK: - Pop-Out TD List Window Manager

final class PopOutWindowManager {
    static let shared = PopOutWindowManager()

    private var panel: NSPanel?
    private var controller: NSWindowController?

    private init() {}

    /// Opens the floating pop-out window, or closes it if already open.
    func toggle() {
        if let p = panel, p.isVisible {
            p.close()
            panel = nil
            controller = nil
            return
        }
        show()
    }

    var isVisible: Bool {
        panel?.isVisible ?? false
    }

    private func show() {
        // Close any stale instance
        panel?.close()
        panel = nil

        let contentView = PopOutTDListView()
        let host = NSHostingController(rootView: contentView)

        let p = NSPanel(
            contentRect: NSRect(x: 0, y: 0, width: 320, height: 420),
            styleMask: [.titled, .closable, .miniaturizable, .resizable],
            backing: .buffered,
            defer: false
        )
        p.title = "TD List"
        p.contentViewController = host
        p.isFloatingPanel = true
        p.level = .floating
        p.hidesOnDeactivate = false
        p.isReleasedWhenClosed = false
        p.minSize = NSSize(width: 100, height: 150)

        // Restore last-used size/position, or center on first open
        p.setFrameAutosaveName("PopOutTDList")
        let savedKey = "NSWindow Frame PopOutTDList"
        if UserDefaults.standard.object(forKey: savedKey) == nil,
           let screen = NSScreen.main {
            let sr = screen.visibleFrame
            let x = sr.midX - p.frame.width / 2
            let y = sr.midY - p.frame.height / 2
            p.setFrameOrigin(NSPoint(x: x, y: y))
        }

        // Wrap in a window controller so the window stays alive
        let wc = NSWindowController(window: p)
        wc.showWindow(nil)
        controller = wc
        panel = p

        // Activate the app so the floating panel can receive events
        NSApp.activate(ignoringOtherApps: false)
        p.makeKeyAndOrderFront(nil)
    }

    func dismiss() {
        panel?.close()
        panel = nil
        controller = nil
    }
}
