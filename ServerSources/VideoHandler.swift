import NIOCore
import NIOPosix

final class VideoHandler: ChannelInboundHandler {
    public typealias InboundIn = AddressedEnvelope<ByteBuffer>
    public typealias OutboundOut = ByteBuffer

    public func channelRead(context: ChannelHandlerContext, data: NIOAny) {
        let envelope = self.unwrapInboundIn(data)
        let buffer = envelope.data

        //let message: String?
        let socketAddr: String?
        let port: Int?

        //message = buffer.readString(length: buffer.readableBytes)
        socketAddr = envelope.remoteAddress.ipAddress
        port = envelope.remoteAddress.port

        print("Size: \(buffer.capacity)")
        print("Message: \(buffer.readableBytes)")
        print("SocketAddr: \(socketAddr as String?)")
        print("Client Listening port: \(port as Int?)")

        let header: [UInt8]? = buffer.getBytes(at: 0, length: 9)
        print("Header: \(header as [UInt8]?)")
        
        context.write(data, promise:nil)
    }

    public func channelReadComplete(context: ChannelHandlerContext) {
        print("Channel read complete")
        context.flush()
    }

    public func errorCaught(context: ChannelHandlerContext, error: any Error) {
        print("Error: \(error)")

        context.close(promise: nil)
    }
}
