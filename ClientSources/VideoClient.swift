import NIOCore
import NIOPosix
import ArgumentParser
import Foundation


enum ClientError: Error {
    case InvalidArguments
    case PortInvalid
    case GenericError
}

struct Client {
    var group: MultiThreadedEventLoopGroup
    var bootstrap: ClientBootstrap

    var host: String
    var listeningPort: Int
    var serverPort: Int
    let clientId: UInt8

    init(clientId: UInt8, host: String, serverPort: Int, listeningPort: Int) throws {
        self.host = host
        self.serverPort = serverPort
        self.listeningPort = listeningPort
        self.clientId = clientId

        group = MultiThreadedEventLoopGroup(numberOfThreads: 1)
        self.bootstrap = ClientBootstrap(group: group)
        PrintClientDetails()
    }

    // But if you are trying to just launch one client: from client perspective it should be synchronus
    // As nothing  else can be done without achieving a TCP connection to the server
    // Right now I hope this can be handled by my VideoHandlers
    func run() async throws {
        let channel = try await self.bootstrap
            .channelInitializer { channel in
                channel.pipeline.addHandler(ClientTCPHandler(connectMessage: createTCPmessage()))
            }
            .connect(to: SocketAddress.makeAddressResolvingHost(host, port: serverPort)).get()
        print("Connection successfull to the server")
        try await channel.closeFuture.get()
    }

    func createTCPmessage() -> [UInt8] {
        // listening port, client name?, empty buffer (can be used later)
        let mask: Int = 255;

        // Note that max clients can be 256
        let id : UInt8 = UInt8(mask) & self.clientId
        let lPortBitOne: UInt8 = UInt8(self.listeningPort >> 8)
        let lPortBitTwo: UInt8 = UInt8(mask & self.listeningPort)

        var data = [UInt8](repeating: 0, count: 8)
        
        // first bit is for client id; next 2 bits for listening port info keep the other bits zero
        data[0] = id
        data[1] = lPortBitOne
        data[2] = lPortBitTwo

        return data
    }
}

extension Client {

    private func PrintClientDetails() {
        print("-----------------------------------------------")
        print("Client ID: \(self.clientId)")
        print("Client IP: \(self.host)")
        print("Client Listening port: \(self.listeningPort)")
        print("Server port: \(self.serverPort)")
        print("-----------------------------------------------")
    }
}

@main
struct main: ParsableCommand {

    @Option(help: "Host ip")
    var host: String = "127.0.0.1"

    @Option(help: "Server Port")
    var sPort: Int = 8080

    @Option(help: "Client ID")
    var n: UInt8 = 1

    @Option(help: "Listening port no")
    var lPort: Int = 6000

    public mutating func run() throws {
        // Initialise all the clients
        print("Closing the client")
        let cl: Client = try Client.init(clientId: n, host: self.host, serverPort: self.sPort, listeningPort: lPort)
        Task {
            try await cl.run()
        }

        while(true) {
            //Wait I guess
        }
    }


}
