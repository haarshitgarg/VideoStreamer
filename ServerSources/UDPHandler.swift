import NIOCore
import NIOPosix

class UDPRequestHandler: ChannelInboundHandler {
    typealias InboundIn = ByteBuffer

    let remoteAddress: SocketAddress
    
    init(remoteAddress: SocketAddress) {
        self.remoteAddress = remoteAddress
    }

    public func channelActive(context: ChannelHandlerContext) {
        print("Channel Active with remote address: \(self.remoteAddress)")
    }
}
