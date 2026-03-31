// OverlayWindow.swift
// Transparent, borderless, non-activating NSWindow subclass.
// This is the floating overlay that sits above all other windows.
//
// Key design decisions:
// - NSBorderlessWindowMask: no title bar, no chrome
// - backgroundColor = .clear + isOpaque = false: true transparency
// - NSWindowLevel.floating: stays above normal windows
// - collectionBehavior: joins all Spaces, works with fullscreen auxiliary
// - canBecomeKey = true: allows drag without activating the app
// - ignoresMouseEvents: toggled for click-through mode

import AppKit

final class OverlayWindow: NSWindow {

    // MARK: - Init

    init(contentRect: NSRect) {
        super.init(
            contentRect: contentRect,
            styleMask: [.borderless],
            backing: .buffered,
            defer: false
        )

        // Transparency
        isOpaque = false
        backgroundColor = .clear
        hasShadow = false

        // Float above normal windows
        level = .floating

        // Join all Spaces + work alongside fullscreen apps
        // .canJoinAllSpaces  — visible on every Space
        // .fullScreenAuxiliary — stays visible when another app goes fullscreen
        // .stationary        — does not move when switching Spaces
        collectionBehavior = [
            .canJoinAllSpaces,
            .fullScreenAuxiliary,
            .stationary
        ]

        // Allow the window to become key so drag events work
        // without bringing the app to the foreground
        isMovableByWindowBackground = false

        // Don't appear in the Window menu or Mission Control thumbnails
        isExcludedFromWindowsMenu = true

        // Prevent the window from being minimized
        styleMask.remove(.miniaturizable)
    }

    // MARK: - Key/Main overrides

    // Must return true so the window can receive mouse events for dragging
    // even though it has no title bar.
    override var canBecomeKey: Bool { true }
    override var canBecomeMain: Bool { false }

    // MARK: - Click-through

    /// When enabled, all mouse events pass through to windows below.
    func setClickThrough(_ enabled: Bool) {
        ignoresMouseEvents = enabled
    }

    // MARK: - Always-on-top

    func setAlwaysOnTop(_ enabled: Bool) {
        level = enabled ? .floating : .normal
    }
}
