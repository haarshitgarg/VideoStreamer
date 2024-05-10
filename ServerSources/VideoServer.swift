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
    let TCPbootstrap: ServerBootstrap

    let UDPBootstrapList: [DatagramBootstrap]? = nil
    
    var host: String
    var UDPport: Int
    var TCPport: Int

    init(host_ip: String, tcp_port: Int, udp_port: Int) {
        self.host = host_ip
        self.TCPport = tcp_port
        self.UDPport = udp_port

        TCPbootstrap = ServerBootstrap(group: self.group)
            
    }


    public func run() throws {
        PrintDetails()
        let TCPchannel = try TCPbootstrap
            .childChannelInitializer { channel in
                channel.eventLoop.makeCompletedFuture {
                    try channel.pipeline.syncOperations.addHandler(TCPRequestHandler(initUDPport: self.initNewUDPport))
                }
            }.bind(host: self.host, port: self.TCPport).wait()

        try TCPchannel.closeFuture.wait()
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

    private func initNewUDPport(remoteAddr: SocketAddress) async throws {
        print("Inititalising new UDP port...")

        print(remoteAddr)

        let group = MultiThreadedEventLoopGroup(numberOfThreads: 1)
        let udp_channel = try await DatagramBootstrap.init(group: group)
            .channelInitializer { channel in 
                channel.pipeline.addHandler(UDPRequestHandler(remoteAddress: remoteAddr))
            }
            .bind(host: self.host, port: self.UDPport).get()

        try await udp_channel.closeFuture.get()
    }

}

@main
struct main: ParsableCommand {
    
    @Option(help: "Server IP address")
    var ip: String = "192.168.1.4"

    @Option(help: "Server TCP port")
    var t: Int = 8080

    @Option(help: "Server UDP port")
    var u: Int = 6969

    public mutating func run() throws {
        let server: Server = Server.init(host_ip: ip, tcp_port: t, udp_port: u)
        do {
            try server.run()
        }
        catch VideoError.InvalidArguments {
            print("Invalid arguments to the Server")
        }
    }
}

