#!/usr/bin/env swift
import Cocoa

// Generate a macOS app icon: yellow eye on a dark background

let sizes: [(String, Int)] = [
    ("icon_16x16", 16),
    ("icon_16x16@2x", 32),
    ("icon_32x32", 32),
    ("icon_32x32@2x", 64),
    ("icon_128x128", 128),
    ("icon_128x128@2x", 256),
    ("icon_256x256", 256),
    ("icon_256x256@2x", 512),
    ("icon_512x512", 512),
    ("icon_512x512@2x", 1024),
]

let iconsetDir = "build/AppIcon.iconset"
let fm = FileManager.default
try? fm.removeItem(atPath: iconsetDir)
try fm.createDirectory(atPath: iconsetDir, withIntermediateDirectories: true)

for (name, px) in sizes {
    let size = CGFloat(px)
    let image = NSImage(size: NSSize(width: size, height: size))
    image.lockFocusFlipped(false)

    guard let ctx = NSGraphicsContext.current?.cgContext else {
        fatalError("No graphics context")
    }

    // --- Background: dark rounded rect (macOS squircle approximation) ---
    let rect = CGRect(x: 0, y: 0, width: size, height: size)
    let cornerRadius = size * 0.22
    let bgPath = NSBezierPath(roundedRect: rect, xRadius: cornerRadius, yRadius: cornerRadius)

    // Gradient: dark charcoal to slightly lighter
    let gradient = NSGradient(
        starting: NSColor(red: 0.12, green: 0.13, blue: 0.18, alpha: 1.0),
        ending: NSColor(red: 0.20, green: 0.22, blue: 0.28, alpha: 1.0)
    )!
    gradient.draw(in: bgPath, angle: -90)

    // Subtle inner border
    NSColor(white: 1.0, alpha: 0.08).setStroke()
    bgPath.lineWidth = max(1, size / 128)
    bgPath.stroke()

    // --- Eye symbol ---
    // Use SF Symbol at a size proportional to the icon
    let symbolPointSize = size * 0.38
    let config = NSImage.SymbolConfiguration(pointSize: symbolPointSize, weight: .medium)
    if let eyeImage = NSImage(systemSymbolName: "eye.fill", accessibilityDescription: nil)?
        .withSymbolConfiguration(config) {

        // Tint yellow
        let tinted = NSImage(size: eyeImage.size)
        tinted.lockFocus()
        NSColor.systemYellow.set()
        let eyeRect = NSRect(origin: .zero, size: eyeImage.size)
        eyeImage.draw(in: eyeRect)
        eyeRect.fill(using: .sourceAtop)
        tinted.unlockFocus()

        // Center the eye in the icon
        let eyeW = tinted.size.width
        let eyeH = tinted.size.height
        let drawRect = NSRect(
            x: (size - eyeW) / 2,
            y: (size - eyeH) / 2,
            width: eyeW,
            height: eyeH
        )
        tinted.draw(in: drawRect)
    }

    image.unlockFocus()

    // Write PNG
    guard let tiff = image.tiffRepresentation,
          let rep = NSBitmapImageRep(data: tiff),
          let png = rep.representation(using: .png, properties: [:]) else {
        fatalError("Failed to create PNG for \(name)")
    }
    let path = "\(iconsetDir)/\(name).png"
    try png.write(to: URL(fileURLWithPath: path))
    print("  \(name).png (\(px)x\(px))")
}

print("Converting to .icns...")
let proc = Process()
proc.executableURL = URL(fileURLWithPath: "/usr/bin/iconutil")
proc.arguments = ["-c", "icns", iconsetDir, "-o", "build/AppIcon.icns"]
try proc.run()
proc.waitUntilExit()

if proc.terminationStatus == 0 {
    try? fm.removeItem(atPath: iconsetDir)
    print("Created build/AppIcon.icns")
} else {
    print("iconutil failed with status \(proc.terminationStatus)")
    exit(1)
}
