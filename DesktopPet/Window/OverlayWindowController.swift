// OverlayWindowController.swift
// Owns and manages the transparent overlay NSWindow lifecycle.
// Coordinates between AppSettings, AnimationPlayer, VideoPlayer, and PetView.
// Handles asset loading, window sizing, and settings application.

import AppKit
import AVFoundation
import QuartzCore
import Combine

final class OverlayWindowController: NSWindowController {

    // MARK: - Dependencies
    private let settings: AppSettings
    private var cancellables = Set<AnyCancellable>()

    // MARK: - Playback
    private let animationPlayer = AnimationPlayer()
    private var videoPlayer: VideoPlayer?

    // MARK: - Views
    private var petView: PetView!

    // MARK: - State
    private var currentAssetURL: URL?
    private var isVideoMode: Bool = false

    // MARK: - Init

    init(settings: AppSettings) {
        self.settings = settings

        // Build the window
        let size = NSSize(width: 300, height: 300)
        let origin = settings.savedPosition()
        let rect = NSRect(origin: origin, size: size)
        let window = OverlayWindow(contentRect: rect)

        super.init(window: window)

        setupPetView()
        setupAnimationPlayer()
        applySettings()
        observeSettings()
    }

    required init?(coder: NSCoder) { fatalError("not used") }

    // MARK: - Setup

    private func setupPetView() {
        guard let window else { return }
        let view = PetView(frame: window.contentView!.bounds)
        view.autoresizingMask = [.width, .height]
        view.delegate = self
        window.contentView?.addSubview(view)
        self.petView = view
    }

    private func setupAnimationPlayer() {
        animationPlayer.delegate = self
        animationPlayer.speed = settings.speed
    }

    private func applySettings() {
        guard let window = window as? OverlayWindow else { return }
        window.setClickThrough(settings.clickThrough)
        window.setAlwaysOnTop(settings.alwaysOnTop)
        window.alphaValue = settings.opacity
        petView.lockPosition = settings.lockPosition
        petView.clickThrough = settings.clickThrough
        animationPlayer.speed = settings.speed
        if settings.playing {
            animationPlayer.play()
        }
    }

    // MARK: - Settings Observation
    // React to settings changes from the SwiftUI panel in real time.

    private func observeSettings() {
        settings.$opacity.sink { [weak self] v in
            self?.window?.alphaValue = v
        }.store(in: &cancellables)

        settings.$scale.sink { [weak self] v in
            self?.applyScale(v)
        }.store(in: &cancellables)

        settings.$clickThrough.sink { [weak self] v in
            (self?.window as? OverlayWindow)?.setClickThrough(v)
            self?.petView.clickThrough = v
        }.store(in: &cancellables)

        settings.$lockPosition.sink { [weak self] v in
            self?.petView.lockPosition = v
        }.store(in: &cancellables)

        settings.$alwaysOnTop.sink { [weak self] v in
            (self?.window as? OverlayWindow)?.setAlwaysOnTop(v)
        }.store(in: &cancellables)

        settings.$speed.sink { [weak self] v in
            self?.animationPlayer.speed = v
            self?.videoPlayer?.speed = Float(v)
        }.store(in: &cancellables)

        settings.$playing.sink { [weak self] v in
            guard let self else { return }
            if v { self.animationPlayer.play(); self.videoPlayer?.play() }
            else { self.animationPlayer.pause(); self.videoPlayer?.pause() }
        }.store(in: &cancellables)
    }

    // MARK: - Asset Loading

    /// Load a placeholder animation (first launch / no asset).
    func loadPlaceholder() {
        isVideoMode = false
        videoPlayer = nil
        removeVideoLayer()
        let seq = PlaceholderAnimation.make()
        resizeWindow(to: NSSize(width: 200, height: 200))
        animationPlayer.load(seq)
        if settings.playing { animationPlayer.play() }
    }

    /// Load an asset from a security-scoped bookmark (app restart).
    func loadAssetFromBookmark(_ bookmark: Data) {
        guard let url = SecurityScopedAccess.resolve(bookmark: bookmark) else {
            loadPlaceholder()
            return
        }
        _ = url.startAccessingSecurityScopedResource()
        loadAsset(url: url)
    }

    /// Load an asset from a URL (file picker or drag-drop).
    func loadAsset(url: URL) {
        currentAssetURL = url
        let ext = url.pathExtension.lowercased()

        // Save bookmark for next launch
        if let bookmark = SecurityScopedAccess.bookmark(for: url) {
            settings.assetBookmark = bookmark
        }

        switch ext {
        case "gif":
            loadGIF(url: url)
        case "png", "apng":
            loadAPNG(url: url)
        case "mp4", "mov", "m4v", "avi", "mkv":
            loadVideo(url: url)
        default:
            // Try as PNG sequence directory or single image
            var isDir: ObjCBool = false
            if FileManager.default.fileExists(atPath: url.path, isDirectory: &isDir), isDir.boolValue {
                loadPNGSequence(directory: url)
            } else {
                loadAPNG(url: url) // fallback: try as image
            }
        }
    }

    private func loadGIF(url: URL) {
        isVideoMode = false
        removeVideoLayer()
        guard let seq = GIFDecoder.decode(url: url) else {
            loadPlaceholder(); return
        }
        let size = sizeForSequence(seq)
        resizeWindow(to: size)
        animationPlayer.load(seq)
        if settings.playing { animationPlayer.play() }
    }

    private func loadAPNG(url: URL) {
        isVideoMode = false
        removeVideoLayer()
        guard let seq = APNGDecoder.decode(url: url) else {
            loadPlaceholder(); return
        }
        let size = sizeForSequence(seq)
        resizeWindow(to: size)
        animationPlayer.load(seq)
        if settings.playing { animationPlayer.play() }
    }

    private func loadPNGSequence(directory: URL) {
        isVideoMode = false
        removeVideoLayer()
        guard let seq = PNGSequenceDecoder.decode(directory: directory) else {
            loadPlaceholder(); return
        }
        let size = sizeForSequence(seq)
        resizeWindow(to: size)
        animationPlayer.load(seq)
        if settings.playing { animationPlayer.play() }
    }

    private func loadVideo(url: URL) {
        isVideoMode = true
        animationPlayer.stop()

        guard let vp = VideoPlayer(url: url) else {
            loadPlaceholder(); return
        }
        videoPlayer = vp
        vp.speed = Float(settings.speed)

        // Add AVPlayerLayer to the pet view's layer
        if let rootLayer = petView.layer {
            vp.playerLayer.frame = rootLayer.bounds
            vp.playerLayer.autoresizingMask = [.layerWidthSizable, .layerHeightSizable]
            rootLayer.addSublayer(vp.playerLayer)
        }

        if settings.playing { vp.play() }
    }

    private func removeVideoLayer() {
        videoPlayer?.playerLayer.removeFromSuperlayer()
        videoPlayer = nil
    }

    // MARK: - Window Sizing

    private func sizeForSequence(_ seq: FrameSequence) -> NSSize {
        guard let first = seq.frames.first else { return NSSize(width: 200, height: 200) }
        naturalSize = NSSize(width: CGFloat(first.width), height: CGFloat(first.height))
        return NSSize(
            width: naturalSize.width * settings.scale,
            height: naturalSize.height * settings.scale
        )
    }

    private func resizeWindow(to size: NSSize) {
        guard let window else { return }
        let origin = window.frame.origin
        let newFrame = NSRect(origin: origin, size: size)
        window.setFrame(newFrame, display: true, animate: false)
    }

    /// Natural (unscaled) pixel size of the current asset.
    private var naturalSize: NSSize = NSSize(width: 200, height: 200)

    private func applyScale(_ scale: Double) {
        guard let window else { return }
        let center = NSPoint(x: window.frame.midX, y: window.frame.midY)
        let newW = naturalSize.width * scale
        let newH = naturalSize.height * scale
        let newOrigin = NSPoint(x: center.x - newW / 2, y: center.y - newH / 2)
        let newFrame = NSRect(origin: newOrigin, size: NSSize(width: newW, height: newH))
        window.setFrame(newFrame, display: true, animate: false)

        if let vp = videoPlayer, let rootLayer = petView.layer {
            vp.playerLayer.frame = rootLayer.bounds
        }
    }
}

// MARK: - AnimationPlayerDelegate

extension OverlayWindowController: AnimationPlayerDelegate {
    func animationPlayer(_ player: AnimationPlayer, didAdvanceTo frame: CGImage) {
        petView.display(frame: frame)
    }
}

// MARK: - PetViewDelegate

extension OverlayWindowController: PetViewDelegate {
    func petView(_ view: PetView, didDropFileAt url: URL) {
        loadAsset(url: url)
    }

    func petViewDidFinishDrag(_ view: PetView) {
        guard let window else { return }
        settings.savePosition(window.frame.origin)
    }
}
