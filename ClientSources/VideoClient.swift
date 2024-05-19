import NIOCore
import NIOPosix
import ArgumentParser
import Foundation


enum ClientError: Error {
    case InvalidArguments
    case PortInvalid
    case GenericError
    case BufferFull
}


actor DataHandler {
    var packetBuffer: [[UInt8]] = [[UInt8]](repeating: [UInt8](), count: 3000)
    var readerIndex: Int = 0
    var emptyBuffer: Bool = true
    var noOfPackets: Int = 0

    public func printNoOfPackets() {
        print("[HANDLER] No of packets: \(self.noOfPackets)")
    }

    public func addToBuffer(bytes: [UInt8]?) throws {
        self.emptyBuffer = false
        guard bytes != nil
        else {
            print("[DATA HANDLER] found nil data bytes")
            return
        }
        let index: Int = Int(bytes![0]) << 8 | Int(bytes![1]) 
        packetBuffer[index] = bytes!
        noOfPackets += 1
    }

    public func getFromBuffer() -> [UInt8] {
        let d = self.packetBuffer[readerIndex]
        if(d == [UInt8]()) {
            return d
        }
        self.readerIndex += 1
        self.readerIndex = self.readerIndex%3000
        noOfPackets -= 1

        return d
    }

    public func isEmpty() -> Bool {
        if(noOfPackets == 0) {
            return true
        }
        return false
    }

}

struct Client {
    var group: MultiThreadedEventLoopGroup
    var tcpBootstrap: ClientBootstrap
    var udpBootstrap: DatagramBootstrap
    var ClientDataHandler: DataHandler = DataHandler.init()
    let imageViewer = PNGImage(imgData: Data())


    var host: String
    var listeningPort: Int
    var serverPort: Int
    let clientId: UInt8

    init(clientId: UInt8, host: String, serverPort: Int, listeningPort: Int) throws {
        self.host = host
        self.serverPort = serverPort
        self.listeningPort = listeningPort
        self.clientId = clientId

        let localAddress: SocketAddress = try SocketAddress.init(ipAddress: "127.0.0.1", port: self.listeningPort)

        group = MultiThreadedEventLoopGroup(numberOfThreads: 1)
        self.tcpBootstrap = ClientBootstrap(group: group).bind(to: localAddress)
        self.udpBootstrap = DatagramBootstrap(group: group)
        PrintClientDetails()
    }

    func run() async throws {
        let channel = try await self.tcpBootstrap
            .channelInitializer { channel in
                channel.pipeline.addHandler(TCPRequestHandler(connectMessage: createTCPmessage()))
            }
            .connect(to: SocketAddress.makeAddressResolvingHost(host, port: serverPort)).get()

        print("Connection successfull to the server")

        let localAddress: SocketAddress = try SocketAddress.init(ipAddress: "127.0.0.1", port: self.listeningPort)

        let udpchannel = try await self.udpBootstrap
            .channelInitializer { channel in 
                channel.pipeline.addHandler(UDPRequestHandler(dataHandler: ClientDataHandler))
            }
            .bind(to: localAddress).get()

        print("[CLIENT] UDP channel active")

        try await channel.closeFuture.get()
        try await udpchannel.closeFuture.get()
    }

    public func UpdateImage() throws{
        Task {
            var imgData: Data = Data()
            while(true) {
                if(await self.ClientDataHandler.isEmpty() == false) {
                    let newData = await self.ClientDataHandler.getFromBuffer()
                    imgData.append(contentsOf: newData[2...(newData.endIndex-1)]) 
                    try await imageViewer.UpdateData(newImage: imgData)
                }
            }
        }

        imageViewer.displayImage()
        

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

// Data management extension
extension Client {
    private func PrintClientDetails() {
        print("-----------------------------------------------")
        print("Client ID: \(self.clientId)")
        print("Server IP: \(self.host)")
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
        try cl.UpdateImage()

        while(true) {

        }

    }
}
