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

    var remoteAddress: SocketAddress
    var host: String
    var listeningPort: Int
    var serverPort: Int
    let clientName: String

    init(clientName: String, host: String, serverPort: Int, listeningPort: Int) throws {
        self.host = host
        self.serverPort = serverPort
        self.listeningPort = listeningPort
        self.clientName = clientName

        let y = try SocketAddress.makeAddressResolvingHost(host, port: serverPort) 
        self.remoteAddress = y

        group = MultiThreadedEventLoopGroup(numberOfThreads: 1)
        bootstrap = ClientBootstrap(group: group)
            .channelInitializer { channel in
                channel.pipeline.addHandler(ClientVideoHandler(remoteAddress: y))
            }
        PrintClientDetails()
    }

    // I am trying to run n number of clients so I have kept it asynchronus.
    // But if you are trying to just launch one client: from client perspective it should be synchronus
    // As nothing  else can be done without achieving a TCP connection to the server
    // Right now I hope this can be handled by my VideoHandlers
    func run() async throws {

        //let channel = try await self.bootstrap.bind(host: host, port: listeningPort).get()
        let channel = try await self.bootstrap.connect(to: SocketAddress.makeAddressResolvingHost(host, port: serverPort)).get()

        try await channel.closeFuture.get()
    }
}

extension Client {

    private func PrintClientDetails() {
        print("-----------------------------------------------")
        print("Client name: \(self.clientName)")
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

    @Option(help: "No of clients to use")
    var n: UInt = 1


    public mutating func run() throws {
        // Initialise all the clients
        var clients: [Client] = []
        for i in 1...n {
            var lPort : Int = 6000
            let clName: String = "Client \(i)"
            lPort += Int(i)
            let cl: Client = try Client.init(clientName: clName, host: self.host, serverPort: self.sPort, listeningPort: lPort)
            Task {
                try await cl.run()
            }
            clients.append(cl)
        }

        Thread.sleep(forTimeInterval: 10)

    }
}
