import Foundation
import MessagePack
import XCBProtocol

/// (input, data, context)
///
/// @param input is only useful for encoder
/// e.g. XCBDecoder(input: input).decodeMessage()
///
/// @param data used to forward messages
///
/// @param context is used to pass state around

open class PlistConverter {
    public struct PlistMimeType {
        static let xmlPlist    = "text/x-apple-plist+xml"
        static let binaryPlist = "application/x-apple-binary-plist"
    }
    
    //// Visible Stuffs ////////////////////////////////////////////////////////
    convenience init?(binaryData: Data, quiet: Bool = true) {
        self.init(binaryData, format: .binaryFormat_v1_0, quiet: quiet)
    }
    
    convenience init?(xml: String, quiet: Bool = true) {
        guard let xmlData = xml.data(using: .utf8) else { return nil }
        self.init(xmlData, format: .xmlFormat_v1_0, quiet: quiet)
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
    private init?(_ data: Data, format: CFPropertyListFormat, quiet: Bool = true) {               //
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
            if !quiet {                                                       //
                print("Error on CFPropertyListCreateWithData : ",             //
                  error!.takeUnretainedValue(), "Return nil")                 //
            }                                                              //            
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

public typealias XCBMessageHandler = (XCBInputStream, Data, Any?) -> Void

public extension UInt64{
    var uint8Array:[UInt8]{
        var x = self.bigEndian
        let data = Data(bytes: &x, count: MemoryLayout<UInt64>.size)
        return data.map{$0}
    }
    
    var uint8Array2:[UInt8]{
        var bigEndian:UInt64 = self.bigEndian
        let count = MemoryLayout<UInt64>.size
        let bytePtr = withUnsafePointer(to: &bigEndian) {
            $0.withMemoryRebound(to: UInt8.self, capacity: count) {
                UnsafeBufferPointer(start: $0, count: count)
            }
        }
        return Array(bytePtr)
    }

    var myuint8: [UInt8] {
        var bigEndian = self.bigEndian
        let count = MemoryLayout<UInt64>.size
        let bytePtr = withUnsafePointer(to: &bigEndian) {
            $0.withMemoryRebound(to: UInt8.self, capacity: count) {
                UnsafeBufferPointer(start: $0, count: count)
            }
        }
        return Array(bytePtr)
    }
}

public class BKBuildService {
    let shouldDump: Bool
    let shouldDumpHumanReadable: Bool

    // This needs to be serial in order to serialize the messages / prevent
    // crossing streams.
    internal static let writeQueue = DispatchQueue(label: "com.xcbuildkit.bkbuildservice")

    public init() {
        self.shouldDump = CommandLine.arguments.contains("--dump")
        self.shouldDumpHumanReadable = CommandLine.arguments.contains("--dump_h")
    }

    /// Starts a service on standard input

    func parseBasicTypes(_ rawValue: XCBRawValue) -> Any {
        switch rawValue {
        case let .uint(value):
            return value.uint8Array[value.uint8Array.count - 1]
        case let .array(value):
            return self.parseIterator(value.makeIterator())
        case .extended(let type, let data):
            return "extended(\(type), \(self.convertDataToString(data)))"
        case let .map(value):
            var dict: [String: Any] = [:]
            for (k,v) in value {
                dict["\(self.parseBasicTypes(k))"] = self.parseBasicTypes(v)
            }
            return "map(\(dict))"
        case let .binary(value):
            return "binary(\(self.convertDataToString(value)))"
        default:
            return String(describing: rawValue)
        }
    }

    func convertDataToString(_ data: Data) -> String {
        if let bplist = PlistConverter(binaryData: data)?.convertToXML() {
            return "bplist(\(bplist))"
        }
        let bytes = [UInt8](data)
        return self.convertBytesToString(bytes)
    }

    func convertBytesToString(_ bytes: [UInt8]) -> String {
        return String(bytes: bytes, encoding: .utf8) ?? String(bytes: bytes, encoding: .ascii) ?? "error: failed to encode"
    }

    func parseIterator(_ theIterator: XCBInputStream) -> [Any] {
        var iterator = theIterator
        var accumulatedBytes: [UInt8] = []
        var result: [Any] = []

        while let next = iterator.next() {
            let nextParsed = self.parseBasicTypes(next)
            if let nextParsedAsBytes = nextParsed as? UInt8 {
                accumulatedBytes.append(nextParsedAsBytes)
            } else {
                if accumulatedBytes.count > 0 {
                    result.append("uint(\(convertBytesToString(accumulatedBytes)))")
                    accumulatedBytes = []
                }
                result.append(nextParsed)
            }
        }

        if accumulatedBytes.count > 0 {
            result.append(convertBytesToString(accumulatedBytes))
            accumulatedBytes = []
        }

        return result
    }

    func prettyPrintRecursively(_ iterator: XCBInputStream) {
        parseIterator(iterator).forEach{ print($0) }
    }

    public func start(messageHandler: @escaping XCBMessageHandler, context:
        Any?) {
        let file = FileHandle.standardInput
        file.readabilityHandler = {
            h in
            let data = h.availableData
            guard data.count > 0 else {
                exit(0)
            }

            /// Unpack everything
            let result = Unpacker.unpackAll(data)
            if let first = result.first, case let .uint(id) = first {
                let msgId = id + 1
                log("respond.msgId" + String(describing: msgId))
            } else {
                log("missing id")
            }

            var resultItr = result.makeIterator()
            if self.shouldDump {
                // Dumps out the protocol
                // useful for debuging, code gen'ing protocol messages, and
                // upgrading Xcode versions
                result.forEach{ $0.prettyPrint() }
            } else if self.shouldDumpHumanReadable {
                // Foo
                self.prettyPrintRecursively(resultItr)
            } else {
                messageHandler(resultItr, data, context)
            }
        }
        repeat {
            sleep(1)
        } while true
    }

    public func write(_ v: XCBResponse) {
        // print("Datas", datasmap { $0.hbytes() }.joined())
        BKBuildService.writeQueue.sync {
            let datas = v.map {
                mm -> Data in
                log("Write: " + String(describing: mm))
                return XCBPacker.pack(mm)
            }

            datas.forEach { FileHandle.standardOutput.write($0) }
        }
    }
}

typealias Chunk = (XCBRawValue, Data)

// This is mostly an implementation detail for now
private enum Unpacker {
    public static func unpackOne(_ data: Data) -> Chunk? {
        return try? unpack(data)
    }

    static func startNext(_ data: Data) -> Data? {
        if data.count > 1 {
            // If there is remaining bytes, try to strip out unparseable bytes
            // and continue down the stream

            // Note: the first element is some length? This is not handled by
            // MessagePack.swift
            // FIXME: subdata is copying over and over?
            var mdata = data
            mdata = mdata.subdata(in: 1 ..< mdata.count - 1)
            return mdata
        } else {
            return nil
        }
    }

    public static func unpackAll(_ data: Data) -> [XCBRawValue] {
        var unpacked = [XCBRawValue]()
        var curr = data

        repeat {
            if let res = try? unpack(curr) {
                let (value, remainder) = res
                curr = remainder
                unpacked.append(value)
                continue
            }

            // At the end of a segment, there will be no more input
            if let next = startNext(curr) {
                curr = next
            } else {
                break
            }
        } while true
        return unpacked
    }
}
