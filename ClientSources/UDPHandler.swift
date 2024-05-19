import NIOCore
import NIOPosix
import Foundation

class UDPRequestHandler: ChannelInboundHandler {
    typealias InboundIn = AddressedEnvelope<ByteBuffer>
    typealias OutboundIn = AddressedEnvelope<ByteBuffer>

    let dataHandler: DataHandler

    public func channelRead(context: ChannelHandlerContext, data: NIOAny) {
        var buffer = self.unwrapInboundIn(data)
        let myData = buffer.data.readBytes(length: buffer.data.readableBytes)

        Task {
            try await self.dataHandler.addToBuffer(bytes: myData)
        }

    }

    init(dataHandler: DataHandler) {
        self.dataHandler = dataHandler
    }

}
