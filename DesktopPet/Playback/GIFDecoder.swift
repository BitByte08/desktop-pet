// GIFDecoder.swift
// Decodes GIF files using ImageIO.
//
// Root cause of ghosting / artifacts (and the fix):
//   The previous implementation drew each raw ImageIO frame onto a
//   persistent compositing canvas WITHOUT clearing it between frames.
//   This caused frames to accumulate on top of each other, producing
//   permanent ghosting / smearing artifacts.
//
//   ImageIO's CGImageSourceCreateImageAtIndex already handles GIF disposal
//   internally and returns a fully composited, full-canvas frame for each
//   index. We only need to use that image directly — no manual compositing
//   canvas is required at all.
//
//   The canvas approach is only needed when decoding raw sub-rect frame data
//   without ImageIO doing the compositing, which is not our case.

import ImageIO
import CoreGraphics
import Foundation

enum GIFDecoder {

    static func decode(url: URL) -> FrameSequence? {
        guard let source = CGImageSourceCreateWithURL(url as CFURL, nil) else { return nil }
        return decode(source: source)
    }

    static func decode(data: Data) -> FrameSequence? {
        guard let source = CGImageSourceCreateWithData(data as CFData, nil) else { return nil }
        return decode(source: source)
    }

    // MARK: - Core decode

    private static func decode(source: CGImageSource) -> FrameSequence? {
        let count = CGImageSourceGetCount(source)
        guard count > 0 else { return nil }

        var frames:  [CGImage]      = []
        var delays:  [TimeInterval] = []

        // Decode options: ask ImageIO to decompress immediately (not lazy).
        let options: CFDictionary = [
            kCGImageSourceShouldCacheImmediately: kCFBooleanTrue,
            kCGImageSourceShouldAllowFloat: kCFBooleanFalse
        ] as CFDictionary

        for i in 0..<count {
            // CGImageSourceCreateImageAtIndex returns a fully composited frame —
            // ImageIO handles GIF disposal internally. No manual canvas needed.
            guard let frame = CGImageSourceCreateImageAtIndex(source, i, options) else { continue }

            frames.append(frame)
            delays.append(gifFrameDelay(source: source, index: i))
        }

        guard !frames.isEmpty else { return nil }
        return FrameSequence(frames: frames, delays: delays)
    }

    // MARK: - Frame delay

    private static func gifFrameDelay(source: CGImageSource, index: Int) -> TimeInterval {
        guard let props = CGImageSourceCopyPropertiesAtIndex(source, index, nil) as? [CFString: Any],
              let gif   = props[kCGImagePropertyGIFDictionary] as? [CFString: Any]
        else { return 0.1 }

        let delay: TimeInterval
        if let u = gif[kCGImagePropertyGIFUnclampedDelayTime] as? TimeInterval, u > 0 {
            delay = u
        } else if let c = gif[kCGImagePropertyGIFDelayTime] as? TimeInterval {
            delay = c
        } else {
            delay = 0.1
        }
        // Enforce minimum to avoid runaway CPU on 0-delay GIFs
        return max(delay, 0.02)
    }
}
