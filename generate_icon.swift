#!/usr/bin/env swift
import AppKit
import Foundation

// Generate VoiceInput app icon: a rounded-rect with a microphone + waveform

func drawIcon(size: CGFloat) -> NSImage {
    let image = NSImage(size: NSSize(width: size, height: size))
    image.lockFocus()

    guard let ctx = NSGraphicsContext.current?.cgContext else {
        image.unlockFocus()
        return image
    }

    let s = size // shorthand

    // --- Background: rounded rect with gradient ---
    let cornerRadius = s * 0.22
    let bgRect = CGRect(x: 0, y: 0, width: s, height: s)
    let bgPath = CGPath(roundedRect: bgRect, cornerWidth: cornerRadius, cornerHeight: cornerRadius, transform: nil)

    ctx.saveGState()
    ctx.addPath(bgPath)
    ctx.clip()

    // Gradient: deep blue-purple to vibrant blue
    let colorSpace = CGColorSpaceCreateDeviceRGB()
    let colors = [
        CGColor(red: 0.15, green: 0.10, blue: 0.35, alpha: 1.0),  // dark purple
        CGColor(red: 0.20, green: 0.30, blue: 0.70, alpha: 1.0),  // mid blue
        CGColor(red: 0.30, green: 0.55, blue: 0.95, alpha: 1.0),  // bright blue
    ] as CFArray
    let locations: [CGFloat] = [0.0, 0.5, 1.0]

    if let gradient = CGGradient(colorsSpace: colorSpace, colors: colors, locations: locations) {
        ctx.drawLinearGradient(gradient,
            start: CGPoint(x: 0, y: 0),
            end: CGPoint(x: s, y: s),
            options: [])
    }
    ctx.restoreGState()

    // --- Subtle inner glow ---
    ctx.saveGState()
    ctx.addPath(bgPath)
    ctx.clip()
    let glowColor = CGColor(red: 0.5, green: 0.7, blue: 1.0, alpha: 0.12)
    ctx.setFillColor(glowColor)
    let glowRect = CGRect(x: s * 0.1, y: s * 0.5, width: s * 0.8, height: s * 0.5)
    ctx.fillEllipse(in: glowRect)
    ctx.restoreGState()

    // --- Microphone body ---
    let micWidth = s * 0.18
    let micHeight = s * 0.28
    let micX = (s - micWidth) / 2
    let micY = s * 0.42

    // Mic capsule (rounded rect)
    let micRect = CGRect(x: micX, y: micY, width: micWidth, height: micHeight)
    let micPath = CGPath(roundedRect: micRect, cornerWidth: micWidth / 2, cornerHeight: micWidth / 2, transform: nil)

    // Mic gradient: white to light blue
    ctx.saveGState()
    ctx.addPath(micPath)
    ctx.clip()
    let micColors = [
        CGColor(red: 1.0, green: 1.0, blue: 1.0, alpha: 0.95),
        CGColor(red: 0.85, green: 0.92, blue: 1.0, alpha: 0.95),
    ] as CFArray
    if let micGrad = CGGradient(colorsSpace: colorSpace, colors: micColors, locations: [0.0, 1.0]) {
        ctx.drawLinearGradient(micGrad,
            start: CGPoint(x: micX, y: micY + micHeight),
            end: CGPoint(x: micX + micWidth, y: micY),
            options: [])
    }
    ctx.restoreGState()

    // --- Mic arc (U-shape holder) ---
    let arcCenterX = s / 2
    let arcCenterY = micY + micHeight * 0.15
    let arcRadius = micWidth * 0.85
    let lineW = s * 0.025

    ctx.saveGState()
    ctx.setStrokeColor(CGColor(red: 1, green: 1, blue: 1, alpha: 0.85))
    ctx.setLineWidth(lineW)
    ctx.setLineCap(.round)
    ctx.addArc(center: CGPoint(x: arcCenterX, y: arcCenterY),
               radius: arcRadius,
               startAngle: .pi * 0.15,
               endAngle: .pi * 0.85,
               clockwise: false)
    ctx.strokePath()
    ctx.restoreGState()

    // --- Mic stand (vertical line + base) ---
    let standTopY = arcCenterY - arcRadius + lineW / 2
    let standBottomY = s * 0.25

    ctx.saveGState()
    ctx.setStrokeColor(CGColor(red: 1, green: 1, blue: 1, alpha: 0.85))
    ctx.setLineWidth(lineW)
    ctx.setLineCap(.round)
    ctx.move(to: CGPoint(x: arcCenterX, y: standTopY))
    ctx.addLine(to: CGPoint(x: arcCenterX, y: standBottomY))
    ctx.strokePath()

    // Base line
    let baseHalf = s * 0.08
    ctx.move(to: CGPoint(x: arcCenterX - baseHalf, y: standBottomY))
    ctx.addLine(to: CGPoint(x: arcCenterX + baseHalf, y: standBottomY))
    ctx.strokePath()
    ctx.restoreGState()

    // --- Waveform bars (left side) ---
    let waveColor = CGColor(red: 0.6, green: 0.85, blue: 1.0, alpha: 0.8)
    let barWidth = s * 0.028
    let barSpacing = s * 0.048
    let waveCenterY = micY + micHeight * 0.5
    let leftHeights: [CGFloat] = [0.06, 0.12, 0.18, 0.10]

    ctx.saveGState()
    ctx.setLineCap(.round)
    ctx.setLineWidth(barWidth)

    for (i, h) in leftHeights.enumerated() {
        let x = micX - barSpacing * CGFloat(i + 1)
        let halfH = s * h
        ctx.setStrokeColor(CGColor(red: 0.6, green: 0.85, blue: 1.0, alpha: 0.8 - CGFloat(i) * 0.15))
        ctx.move(to: CGPoint(x: x, y: waveCenterY - halfH))
        ctx.addLine(to: CGPoint(x: x, y: waveCenterY + halfH))
        ctx.strokePath()
    }

    // --- Waveform bars (right side, mirror) ---
    let rightHeights: [CGFloat] = [0.08, 0.15, 0.11, 0.05]
    for (i, h) in rightHeights.enumerated() {
        let x = micX + micWidth + barSpacing * CGFloat(i + 1)
        let halfH = s * h
        ctx.setStrokeColor(CGColor(red: 0.6, green: 0.85, blue: 1.0, alpha: 0.8 - CGFloat(i) * 0.15))
        ctx.move(to: CGPoint(x: x, y: waveCenterY - halfH))
        ctx.addLine(to: CGPoint(x: x, y: waveCenterY + halfH))
        ctx.strokePath()
    }
    ctx.restoreGState()

    image.unlockFocus()
    return image
}

func savePNG(_ image: NSImage, to path: String) {
    guard let tiff = image.tiffRepresentation,
          let rep = NSBitmapImageRep(data: tiff),
          let png = rep.representation(using: .png, properties: [:]) else {
        print("Failed to create PNG for \(path)")
        return
    }
    do {
        try png.write(to: URL(fileURLWithPath: path))
    } catch {
        print("Failed to write \(path): \(error)")
    }
}

// --- Main ---
let iconsetPath = "/Users/liuxunya/VibeCodingPrj/voice-input-dist/VoiceInput.iconset"
let fm = FileManager.default
try? fm.removeItem(atPath: iconsetPath)
try! fm.createDirectory(atPath: iconsetPath, withIntermediateDirectories: true)

let sizes: [(String, CGFloat)] = [
    ("icon_16x16.png", 16),
    ("icon_16x16@2x.png", 32),
    ("icon_32x32.png", 32),
    ("icon_32x32@2x.png", 64),
    ("icon_128x128.png", 128),
    ("icon_128x128@2x.png", 256),
    ("icon_256x256.png", 256),
    ("icon_256x256@2x.png", 512),
    ("icon_512x512.png", 512),
    ("icon_512x512@2x.png", 1024),
]

for (name, size) in sizes {
    let img = drawIcon(size: size)
    savePNG(img, to: "\(iconsetPath)/\(name)")
    print("Generated \(name) (\(Int(size))x\(Int(size)))")
}

print("\nDone! Now run: iconutil -c icns VoiceInput.iconset")
