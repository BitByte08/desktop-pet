// AppSettings.swift
// Per-instance settings backed by UserDefaults.
// Each pet has its own instanceID so keys never collide.
// Observable so SwiftUI views react to changes in real time.

import Foundation
import Combine
import AppKit

final class AppSettings: ObservableObject {

    // MARK: - Instance identity
    let instanceID: String   // e.g. "pet-1", "pet-2", …

    private let defaults = UserDefaults.standard

    // MARK: - Published Properties

    @Published var positionX: Double   { didSet { defaults.set(positionX,    forKey: k("positionX")) } }
    @Published var positionY: Double   { didSet { defaults.set(positionY,    forKey: k("positionY")) } }
    @Published var scale: Double       { didSet { defaults.set(scale,        forKey: k("scale")) } }
    @Published var opacity: Double     { didSet { defaults.set(opacity,      forKey: k("opacity")) } }
    @Published var speed: Double       { didSet { defaults.set(speed,        forKey: k("speed")) } }
    @Published var clickThrough: Bool  { didSet { defaults.set(clickThrough, forKey: k("clickThrough")) } }
    @Published var lockPosition: Bool  { didSet { defaults.set(lockPosition, forKey: k("lockPosition")) } }
    @Published var alwaysOnTop: Bool   { didSet { defaults.set(alwaysOnTop,  forKey: k("alwaysOnTop")) } }
    @Published var playing: Bool       { didSet { defaults.set(playing,      forKey: k("playing")) } }

    // Security-scoped bookmark for the last imported asset
    var assetBookmark: Data? {
        get { defaults.data(forKey: k("assetBookmark")) }
        set { defaults.set(newValue, forKey: k("assetBookmark")) }
    }

    // MARK: - Init

    init(instanceID: String) {
        self.instanceID = instanceID

        // Offset initial position so multiple pets don't stack exactly
        let idx = Int(instanceID.components(separatedBy: "-").last ?? "1") ?? 1
        let offset = Double((idx - 1) * 60)

        let id = instanceID   // local copy — self not yet available for k()
        func kk(_ s: String) -> String { "\(id).\(s)" }

        defaults.register(defaults: [
            kk("positionX"):    200.0 + offset,
            kk("positionY"):    200.0 + offset,
            kk("scale"):        1.0,
            kk("opacity"):      1.0,
            kk("speed"):        1.0,
            kk("clickThrough"): false,
            kk("lockPosition"): false,
            kk("alwaysOnTop"):  true,
            kk("playing"):      true,
        ])

        positionX    = defaults.double(forKey: kk("positionX"))
        positionY    = defaults.double(forKey: kk("positionY"))
        scale        = defaults.double(forKey: kk("scale"))
        opacity      = defaults.double(forKey: kk("opacity"))
        speed        = defaults.double(forKey: kk("speed"))
        clickThrough = defaults.bool(forKey: kk("clickThrough"))
        lockPosition = defaults.bool(forKey: kk("lockPosition"))
        alwaysOnTop  = defaults.bool(forKey: kk("alwaysOnTop"))
        playing      = defaults.bool(forKey: kk("playing"))
    }

    // MARK: - Key helper (usable after init)
    func k(_ base: String) -> String { "\(instanceID).\(base)" }

    // MARK: - Helpers

    func savePosition(_ point: NSPoint) {
        positionX = point.x
        positionY = point.y
    }

    func savedPosition() -> NSPoint {
        NSPoint(x: positionX, y: positionY)
    }

    /// Remove all UserDefaults keys for this instance.
    func removeAllKeys() {
        ["positionX","positionY","scale","opacity","speed",
         "clickThrough","lockPosition","alwaysOnTop","playing","assetBookmark"]
            .forEach { defaults.removeObject(forKey: k($0)) }
    }
}
