import NIOCore
import NIOPosix

class ClientVideoHandler: ChannelInboundHandler {
    typealias InboundIn = ByteBuffer
    typealias OutboundOut = ByteBuffer
    let message: String = "Hello server"

    public func channelActive(context: ChannelHandlerContext) {
        print("Client connected to: \(context.remoteAddress?.description ?? "unknown")")

        let buffer = context.channel.allocator.buffer(string: message)
        context.writeAndFlush(self.wrapOutboundOut(buffer), promise: nil)
    }

    public func channelRead(context: ChannelHandlerContext, data: NIOAny) {
        var unwrappedInboundData = self.unwrapInboundIn(data)
        var readableBuffer: ByteBuffer = ByteBuffer()
        readableBuffer.writeBuffer(&unwrappedInboundData)
        let string = String(buffer: readableBuffer)

        print("Client receives: \(string)")
    }

    public func errorCaught(context: ChannelHandlerContext, error: any Error) {
        print("Caught error: \(error)")
    }
}
