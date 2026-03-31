// PetView.swift
// The NSView that hosts the CALayer render target.
// Handles:
//   - Displaying animation frames via CALayer.contents (GPU composited)
//   - Drag-to-reposition (when not locked or click-through)
//   - File drop import
//   - Cursor management

import AppKit
import QuartzCore
import CoreGraphics

protocol PetViewDelegate: AnyObject {
    func petView(_ view: PetView, didDropFileAt url: URL)
    func petViewDidFinishDrag(_ view: PetView)
}

final class PetView: NSView {

    // MARK: - Public
    weak var delegate: PetViewDelegate?
    var lockPosition: Bool = false
    var clickThrough: Bool = false

    // MARK: - Render Layer
    // We use a dedicated CALayer for the image content.
    // Setting layer.contents = cgImage is a zero-copy GPU upload on Apple Silicon.
    private let imageLayer = CALayer()

    // MARK: - Drag State
    private var dragStartMouseLocation: NSPoint?
    private var dragStartWindowOrigin: NSPoint?

    // MARK: - Init

    override init(frame: NSRect) {
        super.init(frame: frame)
        setup()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setup()
    }

    private func setup() {
        // Enable layer-backed rendering
        wantsLayer = true
        layer?.backgroundColor = CGColor.clear

        // Image layer fills the view
        imageLayer.frame = bounds
        imageLayer.contentsGravity = .resizeAspect
        imageLayer.backgroundColor = CGColor.clear
        imageLayer.autoresizingMask = [.layerWidthSizable, .layerHeightSizable]
        layer?.addSublayer(imageLayer)

        // Register as a drop target
        registerForDraggedTypes([.fileURL])
    }

    // MARK: - Frame Display

    /// Called by AnimationPlayer delegate on the main thread.
    /// Sets the CGImage as layer contents — GPU composited, no CPU pixel copy.
    func display(frame: CGImage) {
        // Disable implicit animation to avoid ghosting between frames
        CATransaction.begin()
        CATransaction.setDisableActions(true)
        imageLayer.contents = frame
        CATransaction.commit()
    }

    // MARK: - Layout

    override func layout() {
        super.layout()
        imageLayer.frame = bounds
    }

    // MARK: - Mouse Events (Drag)

    override func mouseDown(with event: NSEvent) {
        guard !lockPosition, !clickThrough else { return }
        dragStartMouseLocation = NSEvent.mouseLocation
        dragStartWindowOrigin = window?.frame.origin
    }

    override func mouseDragged(with event: NSEvent) {
        guard !lockPosition, !clickThrough,
              let startMouse = dragStartMouseLocation,
              let startOrigin = dragStartWindowOrigin,
              let window = window
        else { return }

        let current = NSEvent.mouseLocation
        let dx = current.x - startMouse.x
        let dy = current.y - startMouse.y

        window.setFrameOrigin(NSPoint(
            x: startOrigin.x + dx,
            y: startOrigin.y + dy
        ))
    }

    override func mouseUp(with event: NSEvent) {
        guard dragStartMouseLocation != nil else { return }
        dragStartMouseLocation = nil
        dragStartWindowOrigin = nil
        delegate?.petViewDidFinishDrag(self)
    }

    // MARK: - Drag & Drop Import

    override func draggingEntered(_ sender: NSDraggingInfo) -> NSDragOperation {
        return fileURL(from: sender) != nil ? .copy : []
    }

    override func performDragOperation(_ sender: NSDraggingInfo) -> Bool {
        guard let url = fileURL(from: sender) else { return false }
        delegate?.petView(self, didDropFileAt: url)
        return true
    }

    private func fileURL(from info: NSDraggingInfo) -> URL? {
        guard let item = info.draggingPasteboard.pasteboardItems?.first,
              let urlString = item.string(forType: .fileURL),
              let url = URL(string: urlString)
        else { return nil }

        let ext = url.pathExtension.lowercased()
        let supported = ["gif", "png", "apng", "mp4", "mov", "m4v"]
        return supported.contains(ext) ? url : nil
    }

    // MARK: - Hit Testing
    // When click-through is enabled, return nil so events pass to windows below.
    override func hitTest(_ point: NSPoint) -> NSView? {
        return clickThrough ? nil : super.hitTest(point)
    }
}
