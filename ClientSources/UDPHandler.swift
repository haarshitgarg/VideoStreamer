import NIOCore
import NIOPosix

class UDPRequestHandler: ChannelInboundHandler {
    typealias InboundIn = AddressedEnvelope<ByteBuffer>
    typealias OutboundIn = AddressedEnvelope<ByteBuffer>

    public func channelRead(context: ChannelHandlerContext, data: NIOAny) {
        print("UDP Channel Read called")

        var buffer = self.unwrapInboundIn(data)
        let ans = buffer.data.readString(length:buffer.data.readableBytes)
        print("data: \(ans as String?)")
    }

}
