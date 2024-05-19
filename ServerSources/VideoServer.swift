import NIOCore
import NIOPosix
import ArgumentParser
import Foundation

enum VideoError: Error {
    case InvalidArguments 
    case PortInvalid
    case GenericError
    case ParseMessageError
    case BufferFull
}

actor DataHandler {
    var packetBuffer: [[UInt8]] = [[UInt8]](repeating: [UInt8](), count: 400)
    var readerIndex: Int = 0
    var writerIndex: Int = 0
    var emptyBuffer: Bool = true
    var noOfPackets: Int = 0

    public func printNoOfPackets() {
        print("[HANDLER] No of packets: \(self.noOfPackets)")
    }

    public func isFull() -> Bool {
        if(noOfPackets == 400) {
            return true
        }
        return false
    }

    public func addToBuffer(bytes: [UInt8]?) throws {
        if(self.isFull()) {
            throw VideoError.BufferFull
        }
        self.emptyBuffer = false
        guard bytes != nil
        else {
            print("[DATA HANDLER] found nil data bytes")
            return
        }
        packetBuffer[self.writerIndex] = bytes!
        noOfPackets += 1
        self.writerIndex += 1
        self.writerIndex = self.writerIndex % 400
    }

    public func getFromBuffer() -> [UInt8] {
        let old_index = self.readerIndex
        self.readerIndex += 1
        self.readerIndex = self.readerIndex%400
        noOfPackets -= 1

        return self.packetBuffer[old_index]
    }

    public func isEmpty() -> Bool {
        if(noOfPackets == 0) {
            return true
        }
        return false
    }

}

class Server {
    let ServerName: String = "VideoServer"

    let group = MultiThreadedEventLoopGroup(numberOfThreads: System.coreCount)
    let TCPbootstrap: ServerBootstrap

    //This is for future multi client support
    let UDPBootstrapList: [DatagramBootstrap]? = nil
    
    var host: String
    var UDPport: Int
    var TCPport: Int
    var udp_channel: Channel? = nil

    // Using a image. For future to be replaced by video
    var ServerDataHandler: DataHandler = DataHandler.init()
    let data: Data



    init(host_ip: String, tcp_port: Int, udp_port: Int) {
        self.host = host_ip
        self.TCPport = tcp_port
        self.UDPport = udp_port

        TCPbootstrap = ServerBootstrap(group: self.group)

        // Will give a runtime error for wrong image
        self.data = FileManager.default.contents(atPath: "/Users/harshitgarg/Swift-projects/VideoStreamer/Data/marioGameSS.png")!
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
        print("Inititalising new UDP port at address: \(remoteAddr)")

        let group = MultiThreadedEventLoopGroup(numberOfThreads: 1)
        self.udp_channel = try await DatagramBootstrap.init(group: group)
            .channelInitializer { channel in 
                channel.pipeline.addHandler(UDPRequestHandler(remoteAddress: remoteAddr))
            }
            .bind(host: self.host, port: self.UDPport).get()

        Task {
            try await sendUpdPackets(remoteAddr: remoteAddr)
        }

        Task {
            try await processImage()
        }

        try await udp_channel?.closeFuture.get()
    }

}

// Extension for image streaming. To be replaced by Video
extension Server {
    private func sendUpdPackets(remoteAddr: SocketAddress) async throws {
        while(true) {
            if(await self.ServerDataHandler.isEmpty() == false) {
                guard let data = self.udp_channel?.allocator.buffer(bytes: await self.ServerDataHandler.getFromBuffer())
                else {
                    throw VideoError.GenericError 
                }
                let envelope = AddressedEnvelope<ByteBuffer>(remoteAddress: remoteAddr, data: data)
                self.udp_channel?.writeAndFlush(envelope, promise: nil)
                await self.ServerDataHandler.printNoOfPackets()
            }
            else {
                //print("[SERVER] There is no data in the data buffer")
            }

            await Task.yield()
        }

    }

    private func processImage() async throws {
        var end: Int = 2045
        var readIndex = 0
        var count = 0
        while(true) {
            if(await self.ServerDataHandler.isFull() == false){
                end = min(readIndex+2045, self.data.endIndex-1)

                let bitOne: UInt8 = UInt8(255 & count)
                let bitTwo: UInt8 = UInt8((count>>8) & 255)
                var d: [UInt8] = [bitTwo, bitOne]

                d.append(contentsOf: self.data[readIndex...end])
                try await self.ServerDataHandler.addToBuffer(bytes: [UInt8](d))
                await self.ServerDataHandler.printNoOfPackets()

                print("Read index: \(readIndex)")
                print("end index: \(end)")

                readIndex = end + 1
                
                if(end == self.data.endIndex-1) {
                    print("End reached break")
                    break
                }
                count += 1
            }
            else {
                //print("[SERVER] Queue got full")
            }

            // Yielding the loop to do other things if any for better concorrency
            await Task.yield()
        }

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

    @Option(help: "to enable or disable server stand alone testing")
    var test: Bool = false

    public mutating func run() throws {
        if test {
            guard let data = FileManager.default.contents(atPath: "/Users/harshitgarg/Swift-projects/VideoStreamer/Data/marioGameSS.png")
            else {
                throw PNGErros.DataEmpty
            }

            let vh_test = VideoHandler(imgData: data)
            do {
                print("[SERVER Test] Enter the relative file path")
                //let file_path = "Data/marioGameSS.png" 
                //let png_test = try PNGImage(path: file_path)
                //try png_test.test()
                try vh_test.test()
            }
            catch (PNGErros.DataEmpty) {
                print("PNG file is empty")
            }
            catch {
                print("Something else with\(error)")
            }


        }
        else{
            let server: Server = Server.init(host_ip: ip, tcp_port: t, udp_port: u)
            do {
                try server.run()
            }
            catch VideoError.InvalidArguments {
                print("Invalid arguments to the Server")
            }
        }
    }
}

