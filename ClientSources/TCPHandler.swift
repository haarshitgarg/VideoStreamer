import NIOCore
import NIOPosix

enum HandlerError: Error {
    case NilError
}
class TCPRequestHandler: ChannelInboundHandler {
    typealias InboundIn = ByteBuffer
    typealias OutboundOut = ByteBuffer
    let bufferSize: Int = 8
    let connectMessage : [UInt8]

    var nbytes = 0

    public func channelActive(context: ChannelHandlerContext) {
        var buffer = context.channel.allocator.buffer(capacity: bufferSize)

        buffer.writeInteger(connectMessage.count)
        buffer.writeBytes(connectMessage)

        context.writeAndFlush(self.wrapOutboundOut(buffer), promise: nil)

    }

    public func channelRead(context: ChannelHandlerContext, data: NIOAny) {
        let buffer = self.unwrapInboundIn(data)
        print("Buffer capacity: \(buffer.capacity)")

        let bytes: [UInt8]? = buffer.getBytes(at: 0, length: 8)
        print("Data Bytes: \(bytes as [UInt8]?)")
        context.close(promise: nil)
    }

    public func errorCaught(context: ChannelHandlerContext, error: any Error) {
        print("Caught error: \(error)")
    }

    init(connectMessage: [UInt8]) {
        self.connectMessage = connectMessage 
    }
}
