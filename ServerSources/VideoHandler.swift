import NIOCore
import NIOPosix
import Foundation

enum FileErrors: Error {
    case NoFile(name: String)
    case GenericError
}
class VideoHandler: ChannelInboundHandler {
    let filemanager = FileManager.default

    typealias InboundIn = ByteBuffer

}



extension VideoHandler {
    /// Takes in a buffer and fills it based on readIndex
    private func createMessage(readIndex: Int, buffer: inout [UInt8]) {

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

extension VideoHandler {
    public func test(fpath: String) throws {
        let filePath: String = fpath
        try fileRead(path: filePath)
    }
}
