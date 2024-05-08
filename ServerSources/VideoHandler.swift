import NIOCore
import NIOPosix

final class VideoHandler: ChannelInboundHandler {
    public typealias InboundIn = ByteBuffer
    public typealias OutboundOut = ByteBuffer

    public func channelRead(context: ChannelHandlerContext, data: NIOAny) {
        let buffer = self.unwrapInboundIn(data)

        print("Size: \(buffer.capacity)")
        print("Message: \(buffer.readableBytes)")

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
