import AppKit
import SwiftUI

final class FloatingPanel: NSPanel {
    init(contentRect: NSRect) {
        super.init(contentRect: contentRect, styleMask: [.borderless, .nonactivatingPanel], backing: .buffered, defer: false)
        level = .floating
        isOpaque = false
        backgroundColor = .clear
        hasShadow = false
        isMovableByWindowBackground = false
        hidesOnDeactivate = false
        acceptsMouseMovedEvents = true
        collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
    }

    override var canBecomeKey: Bool { true }
    override var canBecomeMain: Bool { false }
}

@MainActor
final class FollowState: ObservableObject {
    @Published var enabled = true
}

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    private var widget: FloatingPanel!
    private var passport: FloatingPanel?
    private var sceneManager: SceneManager!
    private let follow = FollowState()

    private var timer: Timer?
    private var velocity = CGPoint.zero
    private var hoveringCard = false
    private var mouseMonitor: Any?
    private var keyMonitor: Any?

    private let widgetSize = NSSize(width: 760, height: 540)

    func applicationDidFinishLaunching(_ notification: Notification) {
        sceneManager = SceneManager()
        sceneManager.onHoverChange = { [weak self] on in self?.hoveringCard = on }
        sceneManager.onElementSelected = { [weak self] e in self?.showPassport(e) }

        let mouse = NSEvent.mouseLocation
        widget = FloatingPanel(contentRect: NSRect(origin: CGPoint(x: mouse.x - widgetSize.width / 2, y: mouse.y - widgetSize.height / 2), size: widgetSize))
        let host = NSHostingView(rootView: MainView(manager: sceneManager, follow: follow, onQuit: { NSApp.terminate(nil) }))
        host.wantsLayer = true
        host.layer?.backgroundColor = .clear
        widget.contentView = host
        widget.orderFrontRegardless()

        startFollowing()
        keyMonitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { [weak self] ev in
            if ev.keyCode == 53 { self?.closePassport(); return nil } // Esc
            return ev
        }
    }

    // MARK: Следование за курсором

    private func startFollowing() {
        // Глобальный монитор «будит» анимацию сразу при движении мыши вне окна.
        mouseMonitor = NSEvent.addGlobalMonitorForEvents(matching: [.mouseMoved]) { _ in }
        timer = Timer.scheduledTimer(withTimeInterval: 1.0 / 60.0, repeats: true) { [weak self] _ in
            MainActor.assumeIsolated { self?.stepFollow() }
        }
        RunLoop.main.add(timer!, forMode: .common)
    }

    /// Пружинно-демпферная модель (полунеявный Эйлер):
    /// v ← v·(1 − d) + (target − pos)·k;  pos ← pos + v.
    /// k — жёсткость (скорость притяжения), d — затухание (гасит колебания).
    /// При k = 0.012 и d = 0.18 виджет догоняет курсор за ~0.5–1 с с лёгкой инерцией.
    private func stepFollow() {
        guard follow.enabled, passport == nil, widget.isVisible else { velocity = .zero; return }
        let mouse = NSEvent.mouseLocation
        let frame = widget.frame
        // Пока курсор внутри виджета (или над карточкой) — стоим на месте, чтобы было удобно кликать.
        if hoveringCard || frame.insetBy(dx: 40, dy: 40).contains(mouse) {
            velocity.x *= 0.7; velocity.y *= 0.7
        } else {
            let target = CGPoint(x: mouse.x - frame.width / 2, y: mouse.y - frame.height / 2)
            let k: CGFloat = 0.012, d: CGFloat = 0.18
            velocity.x = velocity.x * (1 - d) + (target.x - frame.minX) * k
            velocity.y = velocity.y * (1 - d) + (target.y - frame.minY) * k
        }
        guard abs(velocity.x) > 0.05 || abs(velocity.y) > 0.05 else { return }
        widget.setFrameOrigin(CGPoint(x: frame.minX + velocity.x, y: frame.minY + velocity.y))
    }

    // MARK: Паспорт

    private func showPassport(_ element: ChemicalElement) {
        guard passport == nil, let screen = widget.screen ?? NSScreen.main else { return }
        let panel = FloatingPanel(contentRect: screen.frame)
        panel.level = .modalPanel
        let host = NSHostingView(rootView: PassportView(element: element, allElements: ElementStore.shared.elements) { [weak self] in
            self?.closePassport()
        })
        panel.contentView = host
        panel.alphaValue = 0
        panel.makeKeyAndOrderFront(nil)
        passport = panel
        NSAnimationContext.runAnimationGroup { ctx in
            ctx.duration = 0.35
            panel.animator().alphaValue = 1
            widget.animator().alphaValue = 0
        }
        NSCursor.arrow.set()
    }

    private func closePassport() {
        guard let panel = passport else { return }
        passport = nil
        NSAnimationContext.runAnimationGroup({ ctx in
            ctx.duration = 0.3
            panel.animator().alphaValue = 0
            widget.animator().alphaValue = 1
        }, completionHandler: {
            panel.orderOut(nil)
        })
    }
}
