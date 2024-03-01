//

import Cocoa

struct Pixel {
    var a: UInt8
    var r: UInt8
    var g: UInt8
    var b: UInt8

    // distance ignoring alpha channel
    func distance(from other: Pixel) -> Double {
        let maxDistance = sqrt(255.0 * 255.0 * 3.0)
        let dr = Double(other.r) - Double(r)
        let dg = Double(other.g) - Double(g)
        let db = Double(other.b) - Double(b)
        return sqrt(dr * dr + dg * dg + db * db) / maxDistance
    }
}

extension NSColor {
    private func componentToInt(_ c: CGFloat) -> UInt8 {
        return UInt8(255 * c)
    }

    func toPixel() -> Pixel {
        if colorSpace == NSColorSpace.sRGB {
            return Pixel(a: componentToInt(alphaComponent), r: componentToInt(redComponent), g: componentToInt(greenComponent), b: componentToInt(blueComponent))
        } else if let rgbColor = usingColorSpace(.sRGB) {
            return rgbColor.toPixel()
        }

        return Pixel(a: 0, r: 0, g: 0, b: 0)
    }
}

extension NSImage {
    func toPixels() -> [Pixel] {
        var returnPixels = [Pixel]()

        let pixelData = (self.cgImage(forProposedRect: nil, context: nil, hints: nil)!).dataProvider!.data
        let data: UnsafePointer<UInt8> = CFDataGetBytePtr(pixelData)

        for y in 0..<Int(size.height) {
            for x in 0..<Int(size.width) {
                let pos = CGPoint(x: x, y: y)

                let pixelInfo: Int = ((Int(size.width) * Int(pos.y) * 4) + Int(pos.x) * 4)

                let r = data[pixelInfo]
                let g = data[pixelInfo + 1]
                let b = data[pixelInfo + 2]
                let a = data[pixelInfo + 3]
                returnPixels.append(Pixel(a: a, r: r, g: g, b: b))
            }
        }
        return returnPixels
    }

    static func fromPixels(_ pixels: [Pixel], width: Int, height: Int) -> NSImage? {
        guard width > 0 && height > 0 else { return nil }
        guard pixels.count == width * height else { return nil }

        let rgbColorSpace = CGColorSpaceCreateDeviceRGB()
        let bitmapInfo = CGBitmapInfo(rawValue: CGImageAlphaInfo.premultipliedFirst.rawValue)
        let bitsPerComponent = 8
        let bitsPerPixel = 32

        var data = pixels
        guard let providerRef = CGDataProvider(data: NSData(bytes: &data,
                                                            length: data.count * MemoryLayout<Pixel>.size)
        )
        else { return nil }

        guard let cgim = CGImage(
            width: width,
            height: height,
            bitsPerComponent: bitsPerComponent,
            bitsPerPixel: bitsPerPixel,
            bytesPerRow: width * MemoryLayout<Pixel>.size,
            space: rgbColorSpace,
            bitmapInfo: bitmapInfo,
            provider: providerRef,
            decode: nil,
            shouldInterpolate: true,
            intent: .defaultIntent
        )
        else { return nil }

        return NSImage(cgImage: cgim, size: CGSize(width: width, height: height))
    }
}
