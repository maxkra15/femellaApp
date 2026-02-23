import Foundation
import AppKit

let fileManager = FileManager.default
let directory = URL(fileURLWithPath: "femella/Assets.xcassets/AppIcon.appiconset")

do {
    let files = try fileManager.contentsOfDirectory(at: directory, includingPropertiesForKeys: nil)
    for file in files where file.pathExtension.lowercased() == "png" {
        guard let image = NSImage(contentsOf: file) else {
            print("Could not load \(file.lastPathComponent)")
            continue
        }
        
        // Convert to Core Graphics image to redraw it completely opaque
        guard let cgImage = image.cgImage(forProposedRect: nil, context: nil, hints: nil) else {
            print("Could not get cgImage for \(file.lastPathComponent)")
            continue
        }
        
        let width = cgImage.width
        let height = cgImage.height
        
        let colorSpace = CGColorSpaceCreateDeviceRGB()
        // Use noneSkipLast or noneSkipFirst to avoid alpha completely
        let bitmapInfo = CGBitmapInfo(rawValue: CGImageAlphaInfo.noneSkipLast.rawValue)
        
        guard let context = CGContext(data: nil,
                                      width: width,
                                      height: height,
                                      bitsPerComponent: 8,
                                      bytesPerRow: width * 4,
                                      space: colorSpace,
                                      bitmapInfo: bitmapInfo.rawValue) else {
            print("Could not create context for \(file.lastPathComponent)")
            continue
        }
        
        let rect = CGRect(x: 0, y: 0, width: width, height: height)
        // Draw white background
        context.setFillColor(CGColor.white)
        context.fill(rect)
        
        // Draw original image
        context.draw(cgImage, in: rect)
        
        guard let newCGImage = context.makeImage() else {
            print("Could not make image for \(file.lastPathComponent)")
            continue
        }
        
        let newImage = NSImage(cgImage: newCGImage, size: NSSize(width: width, height: height))
        guard let tiffData = newImage.tiffRepresentation,
              let bitmapImage = NSBitmapImageRep(data: tiffData),
              let pngData = bitmapImage.representation(using: .png, properties: [:]) else {
            print("Could not generate PNG data for \(file.lastPathComponent)")
            continue
        }
        
        try pngData.write(to: file, options: .atomic)
        print("Processed \(file.lastPathComponent)")
    }
} catch {
    print("Error: \(error)")
}
