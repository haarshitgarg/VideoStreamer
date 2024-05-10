import NIOCore
import NIOPosix
import ArgumentParser

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
            .channelOption(ChannelOptions.recvAllocator, value: FixedSizeRecvByteBufferAllocator(capacity: 8))
            .channelInitializer { channel in
                channel.eventLoop.makeCompletedFuture {
                    try channel.pipeline.syncOperations.addHandler(TCPRequestHandler())
                }
            }
        TCPbootstrap = ServerBootstrap(group: self.group)
            .childChannelInitializer { channel in
                channel.eventLoop.makeCompletedFuture {
                    try channel.pipeline.syncOperations.addHandler(TCPRequestHandler())
                }
            }
    }


    public func runTCP(host_ip: String, tcp_port: Int, udp_port: Int) throws {

        self.host = host_ip
        self.TCPport = tcp_port
        self.UDPport = udp_port

        PrintDetails()

        let UDPchannel = try UDPbootstrap.bind(host: host, port: self.UDPport).wait()
        let TCPchannel = try TCPbootstrap.bind(host: host, port: self.TCPport).wait()

        try UDPchannel.closeFuture.wait()
        try TCPchannel.closeFuture.wait()
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
struct main: ParsableCommand {
    static let server: Server = Server.init()
    
    @Option(help: "Server IP address")
    var ip: String = "127.0.0.1"

    @Option(help: "Server TCP port")
    var t: Int = 8080

    @Option(help: "Server UDP port")
    var u: Int = 6969

    public mutating func run() throws {
        let server: Server = Server.init()
        do {
            try server.runTCP(host_ip: ip, tcp_port: t, udp_port: u)
        }
        catch VideoError.InvalidArguments {
            print("Invalid arguments to the Server")
        }
    }
}

