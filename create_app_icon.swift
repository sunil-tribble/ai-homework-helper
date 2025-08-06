#!/usr/bin/swift

import Foundation
import CoreGraphics
import AppKit

// Create a 1024x1024 app icon for AI Homework Helper
func createAppIcon() {
    let size = CGSize(width: 1024, height: 1024)
    
    // Create image with gradient background
    let image = NSImage(size: size)
    image.lockFocus()
    
    // Create gradient background (purple to blue)
    let gradient = NSGradient(colors: [
        NSColor(red: 0.5, green: 0.2, blue: 0.9, alpha: 1.0), // Purple
        NSColor(red: 0.2, green: 0.6, blue: 1.0, alpha: 1.0)  // Blue
    ])
    gradient?.draw(in: NSRect(origin: .zero, size: size), angle: -45)
    
    // Add rounded rectangle background
    let roundedRect = NSBezierPath(roundedRect: NSRect(x: 150, y: 150, width: 724, height: 724), 
                                   xRadius: 180, yRadius: 180)
    NSColor.white.withAlphaComponent(0.15).setFill()
    roundedRect.fill()
    
    // Draw AI brain symbol (simplified)
    let context = NSGraphicsContext.current?.cgContext
    context?.setLineWidth(24)
    context?.setStrokeColor(NSColor.white.cgColor)
    
    // Draw brain outline (simplified circuit pattern)
    let centerX: CGFloat = 512
    let centerY: CGFloat = 512
    
    // Main circle
    context?.addArc(center: CGPoint(x: centerX, y: centerY), 
                   radius: 250, 
                   startAngle: 0, 
                   endAngle: .pi * 2, 
                   clockwise: true)
    context?.strokePath()
    
    // Draw "AI" text
    let paragraphStyle = NSMutableParagraphStyle()
    paragraphStyle.alignment = .center
    
    let attributes: [NSAttributedString.Key: Any] = [
        .font: NSFont.systemFont(ofSize: 280, weight: .bold),
        .foregroundColor: NSColor.white,
        .paragraphStyle: paragraphStyle
    ]
    
    let text = "AI"
    let textRect = NSRect(x: 0, y: 380, width: 1024, height: 400)
    text.draw(in: textRect, withAttributes: attributes)
    
    // Draw "Helper" subtitle
    let subtitleAttributes: [NSAttributedString.Key: Any] = [
        .font: NSFont.systemFont(ofSize: 90, weight: .medium),
        .foregroundColor: NSColor.white.withAlphaComponent(0.9),
        .paragraphStyle: paragraphStyle
    ]
    
    let subtitle = "HELPER"
    let subtitleRect = NSRect(x: 0, y: 250, width: 1024, height: 150)
    subtitle.draw(in: subtitleRect, withAttributes: subtitleAttributes)
    
    // Add graduation cap accent
    context?.setLineWidth(16)
    context?.move(to: CGPoint(x: 700, y: 750))
    context?.addLine(to: CGPoint(x: 750, y: 700))
    context?.addLine(to: CGPoint(x: 800, y: 750))
    context?.addLine(to: CGPoint(x: 750, y: 800))
    context?.closePath()
    context?.strokePath()
    
    image.unlockFocus()
    
    // Save the image
    if let tiffData = image.tiffRepresentation,
       let bitmap = NSBitmapImageRep(data: tiffData),
       let pngData = bitmap.representation(using: .png, properties: [:]) {
        
        let outputPath = "/Users/sunilrao/dev/hw-hlp-2025/AIHomeworkHelper/AIHomeworkHelper/Assets.xcassets/AppIcon.appiconset/icon-1024.png"
        
        do {
            try pngData.write(to: URL(fileURLWithPath: outputPath))
            print("✅ App icon created successfully at: \(outputPath)")
        } catch {
            print("❌ Failed to save icon: \(error)")
        }
    }
}

// Run the function
createAppIcon()