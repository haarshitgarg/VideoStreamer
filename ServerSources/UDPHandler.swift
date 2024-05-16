import NIOCore
import NIOPosix

class UDPRequestHandler: ChannelInboundHandler {
    typealias InboundIn = AddressedEnvelope<ByteBuffer>
    typealias OutboundOut = AddressedEnvelope<ByteBuffer>

    var sampleData: [UInt8] = [UInt8](repeating: 0, count: 32)

    let remoteAddress: SocketAddress
    
    init(remoteAddress: SocketAddress) {
        self.remoteAddress = remoteAddress
    }

    public func channelActive(context: ChannelHandlerContext) {
        print("[UDP Server] Channel Active with remote address: \(self.remoteAddress.ipAddress!):\(self.remoteAddress.port!)")
        
        // Make a buffer and make an envelope
        // Pass data to the client
        // This is where we will be bombarding UPD packets to the client

        for i in 1...250 {
            var x = self.sampleData
            x[0] = UInt8(i)
            let data = context.channel.allocator.buffer(bytes: x)
            let envelope = AddressedEnvelope<ByteBuffer>(remoteAddress: remoteAddress, data: data)

            context.writeAndFlush(self.wrapOutboundOut(envelope), promise: nil)
        }
    }
}
