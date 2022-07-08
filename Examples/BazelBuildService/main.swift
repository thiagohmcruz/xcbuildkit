import BKBuildService
import Foundation
import XCBProtocol

// https://gist.github.com/ngbaanh/7c437d99bea75161a59f5af25be99de4
open class PlistConverter {
    public struct PlistMimeType {
        static let xmlPlist    = "text/x-apple-plist+xml"
        static let binaryPlist = "application/x-apple-binary-plist"
    }
    
    //// Visible Stuffs ////////////////////////////////////////////////////////
    convenience init?(binaryData: Data) {
        self.init(binaryData, format: .binaryFormat_v1_0)
    }
    
    convenience init?(xml: String) {
        guard let xmlData = xml.data(using: .utf8) else { return nil }
        self.init(xmlData, format: .xmlFormat_v1_0)
    }
    
    open func convertToXML() -> String? {
        guard let xmlData = convert(to: .xmlFormat_v1_0) else { return nil }
        return String.init(data: xmlData, encoding: .utf8)
    }
    
    open func convertToBinary() -> Data? {
        return convert(to: .binaryFormat_v1_0)
    }
    
    
    ////////////////////////////////////////////////////////////////////////////
    //// Private ///////////////////////////////////////////////////////////////
    private var plist: CFPropertyList?                                        //
                                                                              //
    private init?(_ data: Data, format: CFPropertyListFormat) {               //
        var dataBytes = Array(data)                                           //
        let plistCoreData = CFDataCreate(kCFAllocatorDefault,                 //
                                         &dataBytes, dataBytes.count)         //
                                                                              //
        var error: Unmanaged<CFError>?                                        //
        var inputFormat = format                                              //
        let options = CFPropertyListMutabilityOptions                         //
                            .mutableContainersAndLeaves.rawValue              //
        plist = CFPropertyListCreateWithData(kCFAllocatorDefault,             //
                                             plistCoreData,                   //
                                             options,                         //
                                             &inputFormat,                    //
                                             &error)?.takeUnretainedValue()   //
        guard plist != nil, nil == error else {                               //
            print("Error on CFPropertyListCreateWithData : ",                 //
                  error!.takeUnretainedValue(), "Return nil")                 //
            error?.release()                                                  //
            return nil                                                        //
        }                                                                     //
        error?.release()                                                      //
    }                                                                         //
                                                                              //
    private func convert(to format: CFPropertyListFormat) -> Data? {          //
        var error: Unmanaged<CFError>?                                        //
        let binary = CFPropertyListCreateData(kCFAllocatorDefault,            //
                                              plist, format,                  //
                                              0, // unused, set 0             //
                                              &error)?.takeUnretainedValue()  //
        let data = Data.init(bytes: CFDataGetBytePtr(binary),                 //
                             count: CFDataGetLength(binary))                  //
        error?.release()                                                      //
        return data                                                           //
    }                                                                         //
                                                                              //
    ////////////////////////////////////////////////////////////////////////////
}

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

    /// Proxying response handler
    /// Every message is written to the XCBBuildService
    /// This simply injects Progress messages from the BEP
    static func fakePlistData() -> Data {
        if let dir = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first {
            let fileURL = dir.appendingPathComponent("foo.plist")
            if let data = try? Data(contentsOf: URL(fileURLWithPath: fileURL.path)) {
                // fatalError("plistfound: \(data)")
                return data
            }
        }

        fatalError("no plist bummer")
    }

    static func fooWrite(text: String) {
        if let dir = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first {
            let fileURL = dir.appendingPathComponent("foo.txt")
            let data = text.data(using: String.Encoding.utf8)!
            if FileManager.default.fileExists(atPath: fileURL.path) {
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

    static func fooDecode(foo_bytes: [UInt8]) -> String {
//  let fooBinary: [UInt8] = [0x62,0x70,0x6c,0x69,0x73,0x74,0x30,0x30,0xa1,0x01,0xd2,0x02,0x03,0x04,0x05,0x5e,0x6f,0x75,0x74,0x70,0x75,0x74,0x46,0x69,0x6c,0x65,0x50,0x61,0x74,0x68,0x5e,0x73,0x6f,0x75,0x72,0x63,0x65,0x46,0x69,0x6c,0x65,0x50,0x61,0x74,0x68,0x5f,0x10,0x3a,0x2f,0x69,0x4f,0x53,0x41,0x70,0x70,0x2e,0x62,0x75,0x69,0x6c,0x64,0x2f,0x44,0x65,0x62,0x75,0x67,0x2f,0x43,0x4c,0x49,0x2e,0x62,0x75,0x69,0x6c,0x64,0x2f,0x4f,0x62,0x6a,0x65,0x63,0x74,0x73,0x2d,0x6e,0x6f,0x72,0x6d,0x61,0x6c,0x2f,0x78,0x38,0x36,0x5f,0x36,0x34,0x2f,0x6d,0x61,0x69,0x6e,0x2e,0x6f,0x5f,0x10,0x36,0x2f,0x55,0x73,0x65,0x72,0x73,0x2f,0x74,0x68,0x69,0x61,0x67,0x6f,0x2f,0x44,0x65,0x76,0x65,0x6c,0x6f,0x70,0x6d,0x65,0x6e,0x74,0x2f,0x78,0x63,0x62,0x75,0x69,0x6c,0x64,0x6b,0x69,0x74,0x2f,0x69,0x4f,0x53,0x41,0x70,0x70,0x2f,0x43,0x4c,0x49,0x2f,0x6d,0x61,0x69,0x6e,0x2e,0x6d,0x08,0x0a,0x0f,0x1e,0x2d,0x6a,0x00,0x00,0x00,0x00,0x00,0x00,0x01,0x01,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x06,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0xa3]        
//  let foo_data = fakePlistData()
//  let foo_data = Data(bytes: fooBinary)
//  let foo_bytes = [UInt8](foo_data)
//  let foo_bytes = [UInt8](foo_data)

        let aff_ascii = String(bytes: foo_bytes, encoding: .ascii)
        let aff_iso2022JP = String(bytes: foo_bytes, encoding: .iso2022JP)
        let aff_isoLatin1 = String(bytes: foo_bytes, encoding: .isoLatin1)
        let aff_isoLatin2 = String(bytes: foo_bytes, encoding: .isoLatin2)
        let aff_japaneseEUC = String(bytes: foo_bytes, encoding: .japaneseEUC)
        let aff_macOSRoman = String(bytes: foo_bytes, encoding: .macOSRoman)
        let aff_nextstep = String(bytes: foo_bytes, encoding: .nextstep)
        let aff_nonLossyASCII = String(bytes: foo_bytes, encoding: .nonLossyASCII)
        let aff_shiftJIS = String(bytes: foo_bytes, encoding: .shiftJIS)
        let aff_symbol = String(bytes: foo_bytes, encoding: .symbol)
        let aff_unicode = String(bytes: foo_bytes, encoding: .unicode)
        let aff_utf16 = String(bytes: foo_bytes, encoding: .utf16)
        let aff_utf16BigEndian = String(bytes: foo_bytes, encoding: .utf16BigEndian)
        let aff_utf16LittleEndian = String(bytes: foo_bytes, encoding: .utf16LittleEndian)
        let aff_utf32 = String(bytes: foo_bytes, encoding: .utf32)
        let aff_utf32BigEndian = String(bytes: foo_bytes, encoding: .utf32BigEndian)
        let aff_utf32LittleEndian = String(bytes: foo_bytes, encoding: .utf32LittleEndian)
        let aff_utf8 = String(bytes: foo_bytes, encoding: .utf8)
        let aff_windowsCP1250 = String(bytes: foo_bytes, encoding: .windowsCP1250)
        let aff_windowsCP1251 = String(bytes: foo_bytes, encoding: .windowsCP1251)
        let aff_windowsCP1252 = String(bytes: foo_bytes, encoding: .windowsCP1252)
        let aff_windowsCP1253 = String(bytes: foo_bytes, encoding: .windowsCP1253)
        let aff_windowsCP1254 = String(bytes: foo_bytes, encoding: .windowsCP1254)

        let res_aff: [String: String] = [
            "aff_ascii": "\(aff_ascii)",
            "aff_iso2022JP": "\(aff_iso2022JP)",
            "aff_isoLatin1": "\(aff_isoLatin1)",
            "aff_isoLatin2": "\(aff_isoLatin2)",
            "aff_japaneseEUC": "\(aff_japaneseEUC)",
            "aff_macOSRoman": "\(aff_macOSRoman)",
            "aff_nextstep": "\(aff_nextstep)",
            "aff_nonLossyASCII": "\(aff_nonLossyASCII)",
            "aff_shiftJIS": "\(aff_shiftJIS)",
            "aff_symbol": "\(aff_symbol)",
            "aff_unicode": "\(aff_unicode)",
            "aff_utf16": "\(aff_utf16)",
            "aff_utf16BigEndian": "\(aff_utf16BigEndian)",
            "aff_utf16LittleEndian": "\(aff_utf16LittleEndian)",
            "aff_utf32": "\(aff_utf32)",
            "aff_utf32BigEndian": "\(aff_utf32BigEndian)",
            "aff_utf32LittleEndian": "\(aff_utf32LittleEndian)",
            "aff_utf8": "\(aff_utf8)",
            "aff_windowsCP1250": "\(aff_windowsCP1250)",
            "aff_windowsCP1251": "\(aff_windowsCP1251)",
            "aff_windowsCP1252": "\(aff_windowsCP1252)",
            "aff_windowsCP1253": "\(aff_windowsCP1253)",
            "aff_windowsCP1254": "\(aff_windowsCP1254)",
        ]

        return """
        foo_starts_here --------------------------------------------------------------------------------
        \(res_aff)
        foo_ends_here --------------------------------------------------------------------------------
        """
    }

    static func fakeIndexingInfoRes() -> Data {
        let xml = """
        <!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
        <plist version="1.0">
            <array>
                <dict>
                    <key>outputFilePath</key>
                    <string>/iOSApp.build/Debug/CLI.build/Objects-normal/x86_64/main.o</string>
                    <key>sourceFilePath</key>
                    <string>/Users/thiago/Development/xcbuildkit/iOSApp/CLI/main.m</string>
                </dict>
            </array>
        </plist>
        """
        guard let converter = PlistConverter(xml: xml) else {
            fatalError("Failed to allocate converter")
        }
        guard let fakeData = converter.convertToBinary() else {
            fatalError("Failed to convert XML to binary plist data")
        }

        return fakeData
    }

    // xcbuildkit iOSApp
    // static let fakeTargetID = "a218dfee841498f4d1c86fb12905507da6b8608e8d79fa8addd22be62fee6ac8"
    // rules_ios App-XCHammer
    static let fakeTargetID = "eb1d2e7ecb9a55be13946326c1fab37a0cabc05c1662dd9058afa744f013efb3"

    static func respond(input: XCBInputStream, data: Data, context: Any?) {
        let basicCtx = context as! BasicMessageContext
        let xcbbuildService = basicCtx.xcbbuildService
        let bkservice = basicCtx.bkservice
        let decoder = XCBDecoder(input: input)
        let encoder = XCBEncoder(input: input)

        // fooWrite(text: "\(decoder.decodeMessage() ?? nil)")

        if let msg = decoder.decodeMessage() {
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
            } 
            else if let msgIndex = msg as? IndexingInfoRequested {
                // let aff_ascii = String(bytes: msgIndex.bytes, encoding: .ascii)
                // fooWrite(text: aff_ascii!)
                
                let message = IndexingInfoReceivedResponse(targetID: fakeTargetID, data: fakeIndexingInfoRes())
                if let responseData = try? message.encode(encoder) {
                    bkservice.write(responseData)
                }
            }
            else if msg is BuildDescriptionTargetInfo {
                let message = IndexingInfoReceivedResponse(targetID: fakeTargetID, data: fakeIndexingInfoRes())
                if let responseData = try? message.encode(encoder) {
                    bkservice.write(responseData)
                }
            }
        }
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
