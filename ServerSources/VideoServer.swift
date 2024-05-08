import NIOCore
import NIOPosix

enum VideoError: Error {
    case InvalidArguments 
    case PortInvalid
    case GenericError
}

class Server {
    let ServerName: String = "VideoServer"
    let group = MultiThreadedEventLoopGroup(numberOfThreads: System.coreCount)
    let UDPbootstrap: DatagramBootstrap
    let TCPbootstrap: ServerBootstrap
    
    var host: String = "127.0.0.1"
    var UDPport: Int = 8080
    var TCPport: Int = 6969

    init() {
        UDPbootstrap = DatagramBootstrap(group: self.group)
            .channelOption(ChannelOptions.datagramVectorReadMessageCount, value: 2)
            .channelOption(ChannelOptions.recvAllocator, value: FixedSizeRecvByteBufferAllocator(capacity: 128))
            .channelInitializer { channel in
                channel.eventLoop.makeCompletedFuture {
                    try channel.pipeline.syncOperations.addHandler(VideoHandler())
                }
            }
        TCPbootstrap = ServerBootstrap(group: self.group)
            .childChannelInitializer { channel in
                channel.eventLoop.makeCompletedFuture {
                    try channel.pipeline.syncOperations.addHandler(VideoHandler())
                }
            }
    }


    public func run(arguments: [String]) throws {
        try parseArguments(arguments)

        let UDPchannel = try UDPbootstrap.bind(host: host, port: self.UDPport).wait()
        let TCPchannel = try TCPbootstrap.bind(host: host, port: self.TCPport).wait()

        try UDPchannel.closeFuture.wait()
        try TCPchannel.closeFuture.wait()
    }

    private func parseArguments(_ arguments: [String]) throws {
        if arguments.count <= 2 {
            print("Setting up default server")
            self.PrintDetails()
            return
        }
        guard arguments.count == 3 else {
            throw VideoError.InvalidArguments
        }
        self.host = arguments[1]
        guard let port = Int(arguments[2]) else { throw VideoError.PortInvalid }
        self.UDPport = port

        self.PrintDetails()
    }

    private func runUPD() async throws {

        // Wait for the channel to close
        print("Channel closed. exiting..")
    }

}

extension Server {
    private func PrintDetails() {
        print("-----------------------------------------------")
        print("Server name is: \(self.ServerName)")
        print("Server IP: \(self.host)")
        print("Server TCP port: \(self.TCPport)")
        print("Server UDP port: \(self.UDPport)")
        print("-----------------------------------------------")
    }
}

@main
struct main {
    static let server: Server = Server.init()

    static func main() throws {
        do {
            try server.run(arguments: CommandLine.arguments)
        }
        catch VideoError.InvalidArguments {
            print("Invalid arguments to the Server")
        }
    }
}

