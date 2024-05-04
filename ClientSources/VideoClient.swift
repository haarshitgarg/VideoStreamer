import NIOCore
import NIOPosix

enum ClientError: Error {
    case InvalidArguments
    case PortInvalid
    case GenericError
}

class Client {
    var group: MultiThreadedEventLoopGroup
    var bootstrap: ClientBootstrap

    init() {
        group = MultiThreadedEventLoopGroup(numberOfThreads: 1)
        bootstrap = ClientBootstrap(group: group)
            .channelInitializer { channel in
                channel.pipeline.addHandler(ClientVideoHandler())
            }
    }

    func run(argument: [String]) throws {
        guard argument.count == 3 else { throw ClientError.InvalidArguments }
        let host: String = argument[1]
        var port: Int = 8080
        guard let x = Int(argument[2]) else { throw ClientError.PortInvalid }
        port = x
        let channel = try self.bootstrap.connect(host: host, port: port).wait()
        try channel.closeFuture.wait()
    }
}

@main
struct main {
    static func main() {
        let client = Client.init()
        do {
            try client.run(argument: CommandLine.arguments)
        }
        catch ClientError.InvalidArguments {
            print("Invalid arguments")
        }
        catch ClientError.PortInvalid {
            print("Invalid Port")
        }
        catch {
            print("Some error I did not check for")
        }
    }
}
