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
        
        // Make a buffer and make an envelope
        // Pass data to the client
        // This is where we will be bombarding UPD packets to the client

        let data = context.channel.allocator.buffer(string: "Hello from UDP server")
        let envelope = AddressedEnvelope<ByteBuffer>(remoteAddress: remoteAddress, data: data)

        context.writeAndFlush(self.wrapOutboundOut(envelope), promise: nil)
    }
}
