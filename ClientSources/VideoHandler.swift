import NIOCore
import NIOPosix

enum HandlerError: Error {
    case NilError
}
class ClientVideoHandler: ChannelInboundHandler {
    typealias InboundIn = AddressedEnvelope<ByteBuffer>
    typealias OutboundOut = AddressedEnvelope<ByteBuffer>
    let bufferSize: Int = 2000
    var remoteAddress: SocketAddress

    var nbytes = 0
    var message: [UInt8]

    public func channelActive(context: ChannelHandlerContext) {

        var buffer = context.channel.allocator.buffer(capacity: bufferSize)
        buffer.writeInteger(message.count)
        buffer.writeBytes(message)

        let envelope = AddressedEnvelope<ByteBuffer>(remoteAddress: remoteAddress, data: buffer)
        context.writeAndFlush(self.wrapOutboundOut(envelope), promise: nil)

    }

    public func channelRead(context: ChannelHandlerContext, data: NIOAny) {
        print("In the channel read")
        let envelope = self.unwrapInboundIn(data)
        let buffer = envelope.data

        //print(buffer.readableBytes)
        //print(buffer)
        //print("Remote address ip: \(envelope.remoteAddress.ipAddress as String?)")
        //print("Port is: \(envelope.remoteAddress.port as Int?)")

        let bytes: [UInt8]? = buffer.getBytes(at: buffer.readerIndex + 8, length: 10)
        print("\(bytes as [UInt8]?)")
        context.close(promise: nil)
    }

    public func errorCaught(context: ChannelHandlerContext, error: any Error) {
        print("Caught error: \(error)")
    }

    init(remoteAddress: SocketAddress) {
        message = [UInt8]()
        self.remoteAddress = remoteAddress
        for _ in 1...bufferSize {
            let x: UInt8 = 1
            message.append(x)
        }
    }
}
