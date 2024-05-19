import NIOCore
import NIOPosix

class UDPRequestHandler: ChannelInboundHandler {
    typealias InboundIn = AddressedEnvelope<ByteBuffer>
    typealias OutboundOut = AddressedEnvelope<ByteBuffer>

    let remoteAddress: SocketAddress
    
    init(remoteAddress: SocketAddress) {
        self.remoteAddress = remoteAddress
    }

    public func channelActive(context: ChannelHandlerContext) {
        print("[UDP Server] Channel Active with remote address: \(self.remoteAddress.ipAddress!):\(self.remoteAddress.port!)")
    }
}

