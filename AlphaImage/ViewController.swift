//

import Cocoa

class ViewController: NSViewController {
    @IBOutlet weak var processedImageView: NSImageView!
    @IBOutlet weak var sourceImageView: NSImageView!
    @IBOutlet weak var colorWell: NSColorWell!
    @IBOutlet weak var opacityThresholdSlider: NSSlider!
    @IBOutlet weak var transparencyThresholdSlider: NSSlider!

    private var sourcePixels: [Pixel] = []
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        processedImageView.wantsLayer = true
        processedImageView.layer?.backgroundColor = NSColor(patternImage: NSImage(named: "pattern")!).cgColor
        processedImageView.layer?.cornerRadius = 10
    }

    override var representedObject: Any? {
        didSet {
        // Update the view, if already loaded.
        }
    }

    @IBAction func imageDropped(_ sender: Any) {
        colorWell.color = .white
        if let image = sourceImageView.image {
            sourcePixels = image.toPixels()
        }

        processImage()
    }
    
    @IBAction func colorPicked(_ sender: Any) {
        processImage()
    }

    @IBAction func transparencyThresholdChanged(_ sender: Any) {
        processImage()
    }

    @IBAction func opacityThresholdChanged(_ sender: Any) {
        processImage()
    }
}

extension ViewController {

    // Based on https://docs.gimp.org/2.10/en/gimp-filter-color-to-alpha.html
    private func processImage() {
        guard let sourceImage = sourceImageView.image else {
            print("No source image!")
            return
        }

        let selectedColorPixel = colorWell.color.toPixel()
        let transparencyThreshold = transparencyThresholdSlider.doubleValue
        let opacityThreshold = opacityThresholdSlider.doubleValue

        let processedPixels = sourcePixels.map { pixel in
            let distance = pixel.distance(from: selectedColorPixel)
            var alpha: UInt8 = 1
            if distance < transparencyThreshold {
                alpha = 0
            } else if distance > opacityThreshold {
                alpha = 255
            } else {
                let k = (distance - transparencyThreshold) / (opacityThreshold - transparencyThreshold)
                if k == Double.nan || k == Double.infinity {
                    alpha = 0
                } else {
                    alpha = UInt8(255 * k)
                }
            }
            return Pixel(a: alpha, r: pixel.r, g: pixel.g, b: pixel.b)
        }

        if let processedImage = NSImage.fromPixels(processedPixels, width: Int(sourceImage.size.width), height: Int(sourceImage.size.height)) {
            processedImageView.image = processedImage
        } else {
            let alert = NSAlert()
            alert.messageText = "Failed to load image"
            alert.runModal()
        }
    }
}
