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
    let bootstrap: ServerBootstrap
    
    var host: String = "127.0.0.1"
    var port: Int = 8080

    init() {
        bootstrap = ServerBootstrap(group: self.group)
            .childChannelInitializer { channel in
                channel.eventLoop.makeCompletedFuture {
                    try channel.pipeline.syncOperations.addHandler(VideoHandler())
                }
            }
    }

    public func run(arguments: [String]) throws {
        try parseArguments(arguments)
    }

    private func parseArguments(_ arguments: [String]) throws {
        guard arguments.count == 3 else {
            throw VideoError.InvalidArguments
        }
        self.host = arguments[1]
        guard let port = Int(arguments[2]) else { throw VideoError.PortInvalid }
        self.port = port

        let channel = try bootstrap.bind(host: host, port: self.port).wait()
        print("Server started and listening on \(channel.localAddress!)")

        try channel.closeFuture.wait()
    }

}

extension Server {
    func PrintDetails() {
        print("Server name is: \(self.ServerName)")
        print("No of cores in your system: \(System.coreCount)")
    }
}

@main
struct main {
    static let server: Server = Server.init()

    static func main() throws {
        server.PrintDetails()
        do {
            try server.run(arguments: CommandLine.arguments)
        }
        catch VideoError.InvalidArguments {
            print("Invalid arguments to the Server")
        }
    }
}

