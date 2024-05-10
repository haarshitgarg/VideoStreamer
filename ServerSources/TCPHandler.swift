import NIOCore
import NIOPosix

final class TCPRequestHandler: ChannelInboundHandler {
    public typealias InboundIn = ByteBuffer
    public typealias OutboundOut = ByteBuffer

    let initUDPport: (_ localAddress: SocketAddress) async throws -> ()

    init(initUDPport: @escaping (_ localAddress: SocketAddress) async throws -> ()) {
        self.initUDPport = initUDPport
    }


    public func channelRead(context: ChannelHandlerContext, data: NIOAny) {
        let buffer = self.unwrapInboundIn(data)
        print("Remote address of the client: \(context.remoteAddress?.ipAddress as String?)")

        print("Data: \(data)")
        print("Size: \(buffer.capacity)")
        do {
            let (lport, _)  = try parseMessage(message: buffer)
            let address = try SocketAddress.init(ipAddress: context.remoteAddress!.ipAddress!, port: lport!)
            Task {
                try await initUDPport(address)
            }

            print("Channel bound to someting")
        }
        catch {
            print("Parse Message error something something")
        }
        
        context.write(data, promise:nil)
    }

    public func channelReadComplete(context: ChannelHandlerContext) {
        context.flush()
    }

    public func errorCaught(context: ChannelHandlerContext, error: any Error) {
        print("Error: \(error)")

        context.close(promise: nil)
    }

}

extension TCPRequestHandler {

    private func parseMessage(message: ByteBuffer) throws -> (lPort: Int?, client_id: UInt8?) {
        var lPort: Int?
        var client_id: UInt8?

        guard let bytes = message.getBytes(at: 8, length: 3) else {
            throw VideoError.GenericError
        }

        client_id = bytes[0]
        lPort = (Int(bytes[1])<<8) | Int(bytes[2])

        print("Client Id: \(client_id as UInt8?), Port: \(lPort as Int?)")


        return (lPort, client_id)
    }
}
