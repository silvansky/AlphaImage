//

import Cocoa
import UniformTypeIdentifiers

// Based on: 
// - https://gist.github.com/raphaelhanneken/d77b6f9b01bef35709da
// - https://buckleyisms.com/blog/how-to-actually-implement-file-dragging-from-your-app-on-mac/

class ProcessedImageView: NSImageView, NSDraggingSource {
    var mouseDownEvent: NSEvent?

    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)

        isEditable = false
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)

        isEditable = false
    }

    override var registeredDraggedTypes: [NSPasteboard.PasteboardType] {
        return [ .png, .fileURL ]
    }

    func draggingSession(_: NSDraggingSession, sourceOperationMaskFor _: NSDraggingContext) -> NSDragOperation {
        return NSDragOperation.copy
    }

    func draggingSession(_: NSDraggingSession, endedAt _: NSPoint, operation: NSDragOperation) {
        
    }

    override func mouseDown(with theEvent: NSEvent) {
        mouseDownEvent = theEvent
    }

    override func mouseDragged(with event: NSEvent) {
        let mouseDown = mouseDownEvent!.locationInWindow
        let dragPoint = event.locationInWindow
        let dragDistance = hypot(mouseDown.x - dragPoint.x, mouseDown.y - dragPoint.y)

        if dragDistance < 3 {
            return
        }

        guard let image = self.image else {
            return
        }

        let size = NSSize(width: log10(image.size.width) * 30, height: log10(image.size.height) * 30)

        let fileItem = NSFilePromiseProvider(fileType: UTType.png.identifier, delegate: self)

        if let draggingImage = image.resize(withSize: size) {
            let draggingItem = NSDraggingItem(pasteboardWriter: fileItem)

            let draggingFrameOrigin = convert(mouseDown, from: nil)
            let draggingFrame = NSRect(origin: draggingFrameOrigin, size: draggingImage.size)
                .offsetBy(dx: -draggingImage.size.width / 2, dy: -draggingImage.size.height / 2)

            draggingItem.draggingFrame = draggingFrame

            draggingItem.imageComponentsProvider = {
                let component = NSDraggingImageComponent(key: NSDraggingItem.ImageComponentKey.icon)

                component.contents = image
                component.frame = NSRect(origin: NSPoint(), size: draggingFrame.size)
                return [component]
            }

            beginDraggingSession(with: [draggingItem], event: mouseDownEvent!, source: self)
        }
    }
}

extension ProcessedImageView: NSFilePromiseProviderDelegate {
    func filePromiseProvider(_ filePromiseProvider: NSFilePromiseProvider, fileNameForType fileType: String) -> String {
        let uid = UUID().uuidString
        return "alphaimage_\(uid).png"
    }

    func filePromiseProvider(_ filePromiseProvider: NSFilePromiseProvider, writePromiseTo url: URL, completionHandler: @escaping (Error?) -> Void) {
        guard let image else {
            completionHandler(NSError(domain: "com.alphaimage.saving", code: -1))
            return
        }

        do {
            try image.write(to: url)
            completionHandler(nil)
        } catch {
            completionHandler(error)
        }
    }
}

extension NSImage {
    func resize(withSize targetSize: NSSize) -> NSImage? {
        let frame = NSRect(x: 0, y: 0, width: targetSize.width, height: targetSize.height)
        guard let representation = self.bestRepresentation(for: frame, context: nil, hints: nil) else {
            return nil
        }
        let image = NSImage(size: targetSize, flipped: false, drawingHandler: { (_) -> Bool in
            return representation.draw(in: frame)
        })

        return image
    }

    func write(to url: URL) throws {
        guard let cgImage = self.cgImage(forProposedRect: nil, context: nil, hints: nil) else {
            throw NSError(domain: "com.alphaimage.saving", code: -2)
        }
        let newRep = NSBitmapImageRep(cgImage: cgImage)
        newRep.size = size // if you want the same size
        guard let pngData = newRep.representation(using: .png, properties: [:]) else {
            throw NSError(domain: "com.alphaimage.saving", code: -3)
        }
        try pngData.write(to: url)
    }
}
