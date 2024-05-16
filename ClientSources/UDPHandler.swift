import NIOCore
import NIOPosix
import Foundation

class UDPRequestHandler: ChannelInboundHandler {
    typealias InboundIn = AddressedEnvelope<ByteBuffer>
    typealias OutboundIn = AddressedEnvelope<ByteBuffer>

    let dataHandler: DataHandler

    public func channelRead(context: ChannelHandlerContext, data: NIOAny) {
        print("[UDP CLIENT] UDP Channel Read called")
        var buffer = self.unwrapInboundIn(data)
        let myData = buffer.data.readBytes(length: buffer.data.readableBytes)
        Task {
            await self.dataHandler.addToBuffer(bytes:myData)
        }

        print("[UDP CLIENT] data: \(myData as [UInt8]?)")
    }

    init(dataHandler: DataHandler) {
        self.dataHandler = dataHandler
    }

}
