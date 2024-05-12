import Foundation
import SwiftUI

enum PNGErros: Error {
    case DataEmpty
    case GenericError
}

class ImageView: NSView {
    var imgData: Data? {
        didSet {
            self.needsDisplay = true
        }
    }

    override func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)

        guard let imageData = imgData,
            let image = NSImage(data: imageData) else {
            return
        }

        // Draw the image in the view
        image.draw(in: bounds)
    }

}

class ImageWindowController: NSWindowController {
    convenience init(imageData: Data) {
        let window_ = NSWindow(contentRect: NSRect(x: 0, y: 0, width: 400, height: 400),
                              styleMask: [.titled, .closable, .miniaturizable, .resizable],
                              backing: .buffered,
                              defer: false)
        window_.title = "Image Viewer"
        
        let imageView = ImageView(frame: window_.contentLayoutRect)
        imageView.imgData = imageData
        window_.contentView = imageView
        
        self.init(window: window_)
        self.imageView_ = imageView
    }

    var imageView_: ImageView? = nil

    public func assignDelegate() {
        window?.delegate = self
    }

}

extension ImageWindowController: NSWindowDelegate {
    func windowShouldClose(_ sender: NSWindow) -> Bool {
        print("Window closed")
        NSApplication.shared.stop(self)
        return true
    }

    func updateImage(newImage: Data) {
        print("Updating the image")
        self.imageView_?.imgData = newImage
    }
}

struct PNGImage {
    var imgPath: String
    var filemanager = FileManager.default
    var image: Data
    var windowController: ImageWindowController

    init(path: String) throws {
        self.imgPath = path

        // Options are to load the image here in a data
        // Or read chunks as an when required
        // Pro: might be faster and definitely less memory
        // Con: If the image changes our iterator will be useless

        // For now going with reading the whole data
        guard let temp_image = filemanager.contents(atPath: path)
        else {
            throw PNGErros.DataEmpty
        }
        self.image = temp_image
        self.windowController = ImageWindowController(imageData: self.image)
    }

    public func nextImgBlock() throws -> [UInt8] {
        let data: [UInt8] = [UInt8](repeating: 0, count: 8)

        return data
    }

    public func displayImage()  {
        windowController.showWindow(nil)
        if windowController.isWindowLoaded {
            print("Window is loaded")
            windowController.assignDelegate()
        }
        NSApplication.shared.run()
    }

    private func getLength(from data: [UInt8]) -> Int {
        var t = data
        var len = 0
        var p = 0;
        for _ in data {
            len = (len | (Int(t.popLast()!) << (p*8)))
            p += 1
        }
        return len
    }

    private func UpdateData(newImage: Data) async throws {
        await self.windowController.updateImage(newImage: newImage)
    }
}

extension PNGImage {
    
    public func test() throws {
        print("Running Image preview")
        Task {
            try await testUpdateImage()
        }

        self.displayImage()

        print("Finished running the app")
        print("Printing the data")
        printIDAT()
    }

    private func testUpdateImage()  async throws {
        let IDAT: [UInt8] = [73, 68, 65, 84]
        var buffer: [UInt8] = [UInt8](repeating: 0, count: 4)

        var count = 0
        var newData = image

        for (i, byte) in self.image.enumerated() {
            buffer.removeFirst()
            buffer.append(UInt8(byte))

            if(buffer == IDAT) {
                if(count >= 10 && count<=11) {
                    var temp: [UInt8] = [UInt8](repeating:0, count: 4)
                    for k in (i-7)...(i-4) {
                        temp.append(self.image[Int(k)])
                    }
                    let x = i-7
                    let len = self.getLength(from: temp)

                    newData.replaceSubrange(x...(x+len+11), with: Data.init(count: len+12))
                    print("removed the subrange")
                }

                count += 1
            }
        }

        try await self.UpdateData(newImage: newData)
    }
    
    private func printIDAT() {
        let IDAT: [UInt8] = [73, 68, 65, 84]
        let IEND: [UInt8] = [73, 69, 78, 68]
        var buffer: [UInt8] = [UInt8](repeating: 0, count: 4)

        for (i, byte) in self.image.enumerated() {
            buffer.removeFirst()
            buffer.append(UInt8(byte))
            //print("Buffer: \(buffer)")

            if(buffer == IDAT) {
                print("IDAT found at index: \(i)")
                // Print the length of the IDAT data set;
                var temp: [UInt8] = [UInt8](repeating:0, count: 4)
                for x in (i-7)...(i-4) {
                    temp.append(self.image[Int(x)])
                }
                print("Size: \(self.getLength(from: temp))")
            }
            else if(buffer == IEND) {
                print("Final index: \(i)")
            }
        }
    }
}
