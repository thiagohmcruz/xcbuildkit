import BKBuildService
import Foundation
import XCBProtocol

struct BasicMessageContext {
    let xcbbuildService: XCBBuildServiceProcess
    let bkservice: BKBuildService
}

/// FIXME: support multiple workspaces
var gStream: BEPStream?

/// This example listens to a BEP stream to display some output.
///
/// All operations are delegated to XCBBuildService and we inject
/// progress from BEP.
enum BasicMessageHandler {
    static func startStream(bepPath: String, startBuildInput: XCBInputStream, bkservice: BKBuildService) throws {
        log("startStream " + String(describing: startBuildInput))
        let stream = try BEPStream(path: bepPath)
        var progressView: ProgressView?
        try stream.read {
            event in
            if let updatedView = ProgressView(event: event, last: progressView) {
                let encoder = XCBEncoder(input: startBuildInput)
                let response = BuildProgressUpdatedResponse(progress:
                    updatedView.progressPercent, message: updatedView.message)
                if let responseData = try? response.encode(encoder) {
                     bkservice.write(responseData)
                }
                progressView = updatedView
            }
        }
        gStream = stream
    }

    static func fakeIndexingInfoRes() -> Data {
        let xml = """
        <!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
        <plist version="1.0">
            <array>
                <dict>
                    <key>outputFilePath</key>
                    <string>/FooXCBKit.build/Debug-iphonesimulator/FooXCBKit.build/Objects-normal/x86_64/AppDelegate.o</string>
                    <key>sourceFilePath</key>
                    <string>/Users/thiago/Desktop/FooXCBKit/FooXCBKit/FooXCBKit/AppDelegate.m</string>
                </dict>
            </array>
        </plist>
        """
        guard let converter = BPlistConverter(xml: xml) else {
            fatalError("Failed to allocate converter")
        }
        guard let fakeData = converter.convertToBinary() else {
            fatalError("Failed to convert XML to binary plist data")
        }

        return fakeData
    }

    static let fakeTargetID = "331b048e25f370d7b433a2ac02b031474b7b4dd1a8f803262ad3ed1dbcecb10b"

    static func fooWrite(text: String, append: Bool = false) {
        if let dir = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first {
            let fileURL = dir.appendingPathComponent("foo.txt")
            let data = text.data(using: String.Encoding.utf8)!
            if FileManager.default.fileExists(atPath: fileURL.path) && append {
                if let fileHandle = try? FileHandle(forWritingTo: fileURL) {
                    fileHandle.seekToEndOfFile()
                    fileHandle.write(data)
                    fileHandle.closeFile()
                }
            } else {
                try? data.write(to: fileURL, options: .atomicWrite)
            }
        }
    }

    public static var allBytes: [UInt8] = []
    public static func matches(for regex: String, in text: String) -> [String] {
        do {
            let regex = try NSRegularExpression(pattern: regex)
            let results = regex.matches(in: text,
                                        range: NSRange(text.startIndex..., in: text))
            return results.map {
                String(text[Range($0.range, in: text)!])
            }
        } catch let error {
            print("invalid regex: \(error.localizedDescription)")
            return []
        }
    }
    /// Proxying response handler
    /// Every message is written to the XCBBuildService
    /// This simply injects Progress messages from the BEP
    static func respond(input: XCBInputStream, data: Data, context: Any?) {
        let basicCtx = context as! BasicMessageContext
        let xcbbuildService = basicCtx.xcbbuildService
        let bkservice = basicCtx.bkservice
        let decoder = XCBDecoder(input: input)
        let encoder = XCBEncoder(input: input)

        if let msg = decoder.decodeMessage() {
            // let indexingMsg = msg as? IndexingInfoRequested

            if let createSessionRequest = msg as? CreateSessionRequest {
                xcbbuildService.startIfNecessary(xcode: createSessionRequest.xcode)
            }
            else if msg is BuildStartRequest {
                do {
                    let bepPath = "/tmp/bep.bep"
                    try startStream(bepPath: bepPath, startBuildInput: input, bkservice: bkservice)
                } catch {
                    fatalError("Failed to init stream" + error.localizedDescription)
                }

                // let message = BuildProgressUpdatedResponse()
                // if let responseData = try? message.encode(encoder) {
                //      bkservice.write(responseData)
                // }
            }
            else if let msgFoo = msg as? IndexingInfoRequested {
                // allBytes += data.bytes
                
                var responseChannel: Int = 16
                if data.bytes.readableString.contains("responseChannel") {
                    let aff = matches(for: "responseChannel\":.*?,", in: data.bytes.readableString).first!.components(separatedBy: ":")[1].components(separatedBy: ",")[0]
                    responseChannel = Int(aff)!
                    // fooWrite(text: "\n\n------------responseChannel\n\n\(Int(aff)!)\n\n------------\n\n", append: false)
                }
                // fooWrite(text: "\n\n------------rawValues\n\n\(msgFoo.rawValues)\n\n------------\n\n", append: true)
                // allBytes += msgFoo.bytes
                // fooWrite(text: "\n\n------------allBytes\n\n\(allBytes.count)\n\n------------\n\n", append: true)
                // // fooWrite(text: "\n\n------------\n\n\(msgFoo.bytes)\n\n------------\n\n", append: true)

                // if let json = try? JSONSerialization.jsonObject(with: Data(allBytes), options: []) as? [String: Any] {
                //     fooWrite(text: "\n\n------------\n\n\(json)\n\n------------\n\n", append: true)
                // } else {
                //     fooWrite(text: "\n\n------------\n\n\(allBytes.readableString)\n\n------------\n\n", append: true)
                // }
                // fooWrite(text: "\n\n------------\n\n\(fooIndexingMsg)\n\n------------\n\n", append: false)
                // if !fooIndexingMsg.contains("\"outputPathOnly\":true") {
                // if true {
                // if false {
                    // fooWrite(text: "\n\n------------\n\n\(fooIndexingMsg)\n\n------------\n\n", append: true)


                    let message2 = IndexingInfoReceivedResponse(targetID: fakeTargetID, data: fakeIndexingInfoRes(), responseChannel: responseChannel)
                    if let responseData = try? message2.encode(encoder) {
                        bkservice.write(responseData)
                    }
                    // let message = IndexingInfoReceivedResponse(targetID: fakeTargetID)
                    // if let responseData = try? message.encode(encoder) {
                    //     bkservice.write(responseData)
                    // }
                    // let message2 = IndexingInfoReceivedResponse(targetID: fakeTargetID, data: fakeIndexingInfoRes(arch: "arm64"))
                    // if let responseData = try? message2.encode(encoder) {
                    //     bkservice.write(responseData)
                    // }
                // }

            }
            else if msg is BuildDescriptionTargetInfo {
                // let message3 = BuildTargetPreparedForIndex(targetGUID: fakeTargetID)
                // if let responseData = try? message3.encode(encoder) {
                //     bkservice.write(responseData)
                // }
                
                let message4 = DocumentationInfoReceived()
                if let responseData = try? message4.encode(encoder) {
                    bkservice.write(responseData)
                }

                let message5 = BuildTargetPreparedForIndex(targetGUID: fakeTargetID)
                if let responseData = try? message5.encode(encoder) {
                    bkservice.write(responseData)
                }
                
                // var responseChannel: Int = 16
                // if data.bytes.readableString.contains("responseChannel") {
                //     let aff = matches(for: "responseChannel\":.*?,", in: data.bytes.readableString).first!.components(separatedBy: ":")[1].components(separatedBy: ",")[0]
                //     responseChannel = Int(aff)!
                // }
                // let message = IndexingInfoReceivedResponse(targetID: fakeTargetID, data: fakeIndexingInfoRes(), responseChannel: responseChannel)
                // if let responseData = try? message.encode(encoder) {
                //     bkservice.write(responseData)
                // }
                
                // let message2 = IndexingInfoReceivedResponse(targetID: fakeTargetID, data: fakeIndexingInfoRes(arch: "arm64"))
                // if let responseData = try? message2.encode(encoder) {
                //     bkservice.write(responseData)
                // }                          
            }       

        }        
        fooWrite(text: "\n\n------------all\n\n\(data.bytes.readableString)\n\n------------\n\n", append: true)
        xcbbuildService.write(data)
    }
}

let xcbbuildService = XCBBuildServiceProcess()
let bkservice = BKBuildService()

let context = BasicMessageContext(
    xcbbuildService: xcbbuildService,
    bkservice: bkservice
)

bkservice.start(messageHandler: BasicMessageHandler.respond, context: context)
