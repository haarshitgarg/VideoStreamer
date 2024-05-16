import NIOCore
import NIOPosix
import Foundation

class UDPRequestHandler: ChannelInboundHandler {
    typealias InboundIn = AddressedEnvelope<ByteBuffer>
    typealias OutboundIn = AddressedEnvelope<ByteBuffer>

    public func channelRead(context: ChannelHandlerContext, data: NIOAny) {
        print("UDP Channel Read called")

        var buffer = self.unwrapInboundIn(data)
        print("data: \(buffer.data.readBytes(length: 32) as [UInt8]?)")
    }

}
