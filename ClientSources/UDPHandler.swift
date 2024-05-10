import NIOCore
import NIOPosix

class UDPRequestHandler: ChannelInboundHandler {
    typealias InboundIn = ByteBuffer

    public func channelActive(context: ChannelHandlerContext) {
        print("Channel active")
    }

}
