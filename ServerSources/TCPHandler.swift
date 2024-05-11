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
        print("[TCP Server] Remote address of the client: \(context.remoteAddress?.ipAddress as String?)")

        let readbuffer = self.unwrapInboundIn(data)

        // 1st bit 1 or 0 means success or failure
        var writebuffer: ByteBuffer = context.channel.allocator.buffer(capacity: 16)
        var writeData: [UInt8] = [UInt8](repeating: 0, count: 8)

        do {
            let (lport, _)  = try parseMessage(message: readbuffer)
            let address = try SocketAddress.init(ipAddress: context.remoteAddress!.ipAddress!, port: lport!)
            Task {
                try await initUDPport(address)
            }
            writeData[0] = 1
        }
        catch (VideoError.ParseMessageError) {
            print("[TCP Server] Error parsing the messsage from the client")
            writeData[0] = 0
        }
        catch {
            print("[TCP Server] Error creating the socket address")
            writeData[0] = 0
        }

        writebuffer.writeBytes(writeData)
        
        context.write(self.wrapOutboundOut(writebuffer), promise:nil)
    }

    public func channelReadComplete(context: ChannelHandlerContext) {
        context.flush()
    }

    public func errorCaught(context: ChannelHandlerContext, error: any Error) {
        print("[TCP Server] Error: \(error)")

        // Closing only on error or else it is ready to read all the time
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

        print("[TCP Server] Client Id: \(client_id as UInt8?), Port: \(lPort as Int?)")


        return (lPort, client_id)
    }
}
