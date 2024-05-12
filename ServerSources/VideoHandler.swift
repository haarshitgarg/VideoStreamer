import NIOCore
import NIOPosix
import Foundation

enum FileErrors: Error {
    case NoFile(name: String)
    case GenericError
}
class VideoHandler: ChannelInboundHandler {
    typealias InboundIn = ByteBuffer
    let filemanager = FileManager.default

    var sampleData: Data
    var currInd: Int = 0

    init(imgData: Data) {
        self.sampleData = imgData
    }

    let imageViewer = PNGImage(imgData: Data())
}



extension VideoHandler {
    /// Takes in a buffer and fills it based on readIndex
    private func createMessage(readIndex: Int) -> (Data, Int) {
        var end: Int = 0
        end = min(readIndex+2048, sampleData.endIndex - 1)
        return (sampleData[readIndex...end], end - readIndex + 1) 
    }

    private func fileRead(path: String) throws {
        let contents: Data? = filemanager.contents(atPath: path)
        print("Content at file path: \(path)")
        // Print the png file header
        for i in 0...7 {
            print("\(contents?[i] as UInt8?)")
        }
    }
}

// All the testing related functions
extension VideoHandler {

    private func updateData(imgData: inout Data) async throws{
        print("Sample data length: \(sampleData.endIndex-1)")
        while(currInd < sampleData.endIndex) {
            let (msg, i) = createMessage(readIndex: currInd)
            self.currInd += i
            imgData.append(msg)
            
            try await imageViewer.UpdateData(newImage: imgData)
        }

        print("Finished")
    }


    public func test() throws {
        try incrDisplay()
    }

    private func incrDisplay() throws {
        print("Incremental Display test")
        Task {
            var temp = Data()
            try await updateData(imgData: &temp)
        }

        print("Image Viewer created")
        imageViewer.displayImage()
    }
}
