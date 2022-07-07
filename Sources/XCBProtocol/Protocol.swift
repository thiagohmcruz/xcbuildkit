/// Implements a XCBProtocol Messages
/// Many of these types are synthetic, high level representations of messages
/// derived from Xcode
import Foundation

/// This protocol version represents the _Major_ version of Xcode that it was
/// tested with. Minor and Fix versions are unaccounted for due to excellent
/// compatibility across releases
let XCBProtocolVersion = "11"

/// Current build number. None of this is expected to be thread safe and Xcode
/// is forced to use J=1 ( IDEBuildOperationMaxNumberOfConcurrentCompileTasks )
/// for debugging and development purposes
/// -1 means we haven't built yet
///
// TODO: this isn't really useful to make public, but it's super hacky
/// find a better solution
private var gBuildNumber: Int64 = -1

private extension XCBEncoder {
    func getResponseMsgId(subtracting  offset: UInt64) throws -> UInt64 {
        // Consider finding ways to mitigate unexpected input in upstream code.
        // There may be possible ways that unexpected messages will make it this
        // far. Guard against possible integer underflow
        let id = try getMsgId()
        guard id >= offset else {
            log("bad offset for msg: " + String(describing: self.input))
            throw XCBProtocolError.unexpectedInput(for: self.input)
        }
        return id - offset
    }
}

public struct CreateSessionRequest: XCBProtocolMessage {
    public let workspace: String
    public let xcode: String
    public let xcbuildDataPath: String

    init(input: XCBInputStream) throws {
        var minput = input

        /// Perhaps this shouldn't fatal error
        guard let next = minput.next(),
            case let .array(msgInfo) = next,
            msgInfo.count > 2 else {
            throw XCBProtocolError.unexpectedInput(for: input)
        }

        if case let .string(workspaceInfo) = msgInfo[0] {
            self.workspace = workspaceInfo
        } else {
            self.workspace = ""
        }

        if case let .string(xcode) = msgInfo[1] {
            self.xcode = xcode
        } else {
            self.xcode = ""
        }

        if case let .string(xcbuildDataPath) = msgInfo[2] {
            self.xcbuildDataPath = xcbuildDataPath
        } else {
            self.xcbuildDataPath = ""
        }
    }
}

/// Input "Request" Messages
public struct TransferSessionPIFRequest: XCBProtocolMessage {
    public init(input _: XCBInputStream) throws {}
}

public struct TransferSessionPIFObjectsLegacyRequest: XCBProtocolMessage {
    public init(input _: XCBInputStream) throws {}
}

public struct SetSessionSystemInfoRequest: XCBProtocolMessage {
    public init(input _: XCBInputStream) throws {}
}

public struct SetSessionUserInfoRequest: XCBProtocolMessage {
    public init(input _: XCBInputStream) throws {}
}

public struct CreateBuildRequest: XCBProtocolMessage {
    public init(input _: XCBInputStream) throws {}
}

public struct BuildStartRequest: XCBProtocolMessage {
    public init(input _: XCBInputStream) throws {}
}

public struct BuildDescriptionTargetInfo: XCBProtocolMessage {
    public init(input _: XCBInputStream) throws {}
}

public struct IndexingInfoRequested: XCBProtocolMessage {
    public var bytes: [UInt8] = []

    public init(input fooInput: XCBInputStream) throws {
        var minput = fooInput
        while let next = minput.next() {
            switch next {
                case let .uint(aff): 
                    bytes.append(UInt8(bitPattern: Int8(aff)))
                default: 
                    print("nothing to do")
            }
        }    
    }
    // let sessionHandle: String
    // let responseChannel: UInt64
    // // let request: XCBProtocol.BuildRequestMessagePayload
    // let request: Any?
    // let targetID: String 
    // let filePath: String?
    // let outputPathOnly: Bool

//     public init(input fooInput: XCBInputStream) throws {
//         var minput = fooInput

// //mach-o, binary, lib, executable

//         // guard let next = minput.next(),
//             // case let .array(msgInfo) = next else {
//             // case let .string(msgInfo) = next else {
//             // msgInfo.count > 2 else {
//             // fatalError("fooo222....")
//             // throw XCBProtocolError.unexpectedInput(for: fooInput)
//         // }

//         guard let next = minput.next() else {
//             fatalError("fooooooooooo no")
//         }

//         var result_aff: [String: Any] = [:]
//         var counter = 0
//         while let next = minput.next() {
//             // switch next {
//             //     case let .bool(aff): result_aff["foo bool(\(counter))"] = "\(aff)"
//             //     case let .int(aff): result_aff["foo int(\(counter))"] = "\(aff)"
//             //     case let .uint(aff): result_aff["foo uint(\(counter))"] = "\(aff)"
//             //     case let .float(aff): result_aff["foo float(\(counter))"] = "\(aff)"
//             //     case let .double(aff): result_aff["foo double(\(counter))"] = "\(aff)"
//             //     case let .string(aff): result_aff["foo string(\(counter))"] = "\(aff)"
//             //     case let .array(aff): result_aff["foo array(\(counter))"] = "\(aff)"
//             //     case let .map(aff): result_aff["foo map(\(counter))"] = "\(aff)"
//             //     case let .binary(aff): result_aff["foo binary(\(counter))"] = "\(aff)"
//             //     // case let .extended(, data)
//             //     default: fatalError("nope")
//             // }
//             switch next {
//                 case let .bool(aff): result_aff["foo bool(\(counter))"] = aff.description
//                 case let .int(aff): result_aff["foo int(\(counter))"] = aff.description
//                 case let .uint(aff): result_aff["foo uint(\(counter))"] = aff.description
//                 case let .float(aff): result_aff["foo float(\(counter))"] = aff.description
//                 case let .double(aff): result_aff["foo double(\(counter))"] = aff.description
//                 case let .string(aff): result_aff["foo string(\(counter))"] = aff.description
//                 case let .array(aff): result_aff["foo array(\(counter))"] = aff.description
//                 case let .map(aff): result_aff["foo map(\(counter))"] = aff.description
//                 case let .binary(aff): result_aff["foo binary(\(counter))"] = aff.description
//                 case let .binary(aff): result_aff["foo binary(\(counter))"] = aff.description
//                 // case let .extended(, data)
//                 default: fatalError("nope")
//             }
//             counter += 1
//         }
        
//         // fatalError("result_aff: \(result_aff)")
//         // fatalError("wot")

//         // var foo_out = ""
//         // while let foo = minput.next() {
//         //     foo_out += "\(foo)\n"
//         // }

//         // fatalError("foo_out: \(foo_out)")
//     }
}

/// Output "Response" messages
/// These are high level representations of how XCBuild responds to requests.

public struct CreateSessionResponse: XCBProtocolMessage {
    public init() throws {}

    /// Responses take an input from the segement of an input stream
    /// containing the input message
    public func encode(_: XCBEncoder) throws -> XCBResponse {
        return [
            XCBRawValue.uint(1),
            XCBRawValue.uint(0),
            XCBRawValue.uint(0),
            XCBRawValue.uint(0),
            XCBRawValue.uint(0),
            XCBRawValue.uint(0),
            XCBRawValue.uint(0),
            XCBRawValue.uint(0),
            XCBRawValue.uint(11),
            XCBRawValue.uint(0),
            XCBRawValue.uint(0),
            XCBRawValue.uint(0),
            XCBRawValue.string("STRING"),
            XCBRawValue.array([XCBRawValue.string("S0")]),
        ]
    }
}

public struct TransferSessionPIFResponse: XCBProtocolMessage {
    public init() {}

    public func encode(_: XCBEncoder) throws -> XCBResponse {
        return [
            XCBRawValue.uint(2),
            XCBRawValue.uint(0),
            XCBRawValue.uint(0),
            XCBRawValue.uint(0),
            XCBRawValue.uint(0),
            XCBRawValue.uint(0),
            XCBRawValue.uint(0),
            XCBRawValue.uint(0),
            XCBRawValue.uint(32),
            XCBRawValue.uint(0),
            XCBRawValue.uint(0),
            XCBRawValue.uint(0),

            XCBRawValue.string("TRANSFER_SESSION_PIF_RESPONSE"),
            XCBRawValue.array([XCBRawValue.array([])]),
            XCBRawValue.uint(3),
        ]
    }
}

public struct SetSessionSystemInfoResponse: XCBProtocolMessage {
    public init() {}

    public func encode(_: XCBEncoder) throws -> XCBResponse {
        return [
            XCBRawValue.uint(0),
            XCBRawValue.uint(0),
            XCBRawValue.uint(0),
            XCBRawValue.uint(0),
            XCBRawValue.uint(0),
            XCBRawValue.uint(0),
            XCBRawValue.uint(0),
            XCBRawValue.uint(6),
            XCBRawValue.uint(0),
            XCBRawValue.uint(0),
            XCBRawValue.uint(0),
            XCBRawValue.string("PING"),
            XCBRawValue.nil,
            XCBRawValue.uint(4),
            XCBRawValue.uint(0),
            XCBRawValue.uint(0),
            XCBRawValue.uint(0),
        ]
    }
}

public struct SetSessionUserInfoResponse: XCBProtocolMessage {
    public init() {}

    public func encode(_ encoder: XCBEncoder) throws -> XCBResponse {
        return [
            XCBRawValue.uint(0),
            XCBRawValue.uint(0),
            XCBRawValue.uint(0),
            XCBRawValue.uint(0),
            XCBRawValue.uint(6),
            XCBRawValue.uint(0),
            XCBRawValue.uint(0),
            XCBRawValue.uint(0),
            XCBRawValue.string("PING"),
            XCBRawValue.nil,
            XCBRawValue.uint(try encoder.getMsgId() + 1),
        ]
    }
}

public struct CreateBuildResponse: XCBProtocolMessage {
    public init() {}

    public func encode(_: XCBEncoder) throws -> XCBResponse {
        gBuildNumber += 1

        return [
            XCBRawValue.uint(0),
            XCBRawValue.uint(0),
            XCBRawValue.uint(0),
            XCBRawValue.uint(0),
            XCBRawValue.uint(0),
            XCBRawValue.uint(0),
            XCBRawValue.uint(0),
            XCBRawValue.uint(24),

            XCBRawValue.uint(0),
            XCBRawValue.uint(0),
            XCBRawValue.uint(0),
            XCBRawValue.string("BUILD_CREATED"),
            [Int64(gBuildNumber)],
        ]
    }
}

public struct BuildStartResponse: XCBProtocolMessage {
    public init() {}

    public func encode(_ encoder: XCBEncoder) throws -> XCBResponse {
        return [
            // Begin prefix
            XCBRawValue.uint(try encoder.getMsgId()),
            XCBRawValue.uint(0),
            XCBRawValue.uint(0),
            XCBRawValue.uint(0),

            XCBRawValue.uint(0),
            XCBRawValue.uint(0),
            XCBRawValue.uint(0),

            XCBRawValue.uint(0),
            XCBRawValue.int(7),
            XCBRawValue.uint(0),
            XCBRawValue.uint(0),
            XCBRawValue.uint(0),
            XCBRawValue.string("BOOL"),
            XCBRawValue.array([XCBRawValue.bool(true)]),
            XCBRawValue.uint(try encoder.getMsgId()),
            // END

            XCBRawValue.uint(0),
            XCBRawValue.uint(0),
            XCBRawValue.uint(0),

            XCBRawValue.uint(0),
            XCBRawValue.uint(0),
            XCBRawValue.uint(0),

            XCBRawValue.uint(0),
            XCBRawValue.uint(7),
            XCBRawValue.uint(0),
            XCBRawValue.uint(0),
            XCBRawValue.uint(0),
            XCBRawValue.string("BOOL"),
            XCBRawValue.array([XCBRawValue.bool(true)]),
            XCBRawValue.uint(try encoder.getResponseMsgId(subtracting: 3)),
            // END
        ]
    }
}

/// Note: this is assumed to be used during a build
/// responding to a StartBuild request.
public struct BuildProgressUpdatedResponse: XCBProtocolMessage {
    let progress: Double
    let taskName: String
    let message: String
    let showInActivityLog: Bool

    public init(progress: Double = -1.0, taskName: String = "", message: String = "Updated 1 task", showInActivityLog: Bool = false) {
        self.progress = progress
        self.taskName = taskName
        self.message = message
        self.showInActivityLog = showInActivityLog
    }

    public func encode(_ encoder: XCBEncoder) throws -> XCBResponse {
        let padding = 14 // sizeof messages, random things
        let length = "BUILD_PROGRESS_UPDATED".utf8.count + self.taskName.utf8.count + self.message.utf8.count
        return [
            XCBRawValue.uint(try encoder.getResponseMsgId(subtracting: 3)),
            XCBRawValue.uint(0),
            XCBRawValue.uint(0),
            XCBRawValue.uint(0),
            XCBRawValue.uint(0),
            XCBRawValue.uint(0),
            XCBRawValue.uint(0),
            XCBRawValue.uint(0),
            XCBRawValue.uint(UInt64(length + padding)),
            XCBRawValue.uint(0),
            XCBRawValue.uint(0),
            XCBRawValue.uint(0),
            XCBRawValue.string("BUILD_PROGRESS_UPDATED"),
            XCBRawValue.array([.string(taskName), .string(self.message), .double(self.progress), .bool(self.showInActivityLog)]),
        ]
    }
}

public struct PlanningOperationWillStartResponse: XCBProtocolMessage {
    public init() {}

    public func encode(_ encoder: XCBEncoder) throws -> XCBResponse {
        return [
            XCBRawValue.uint(0), XCBRawValue.uint(0), XCBRawValue.uint(0), XCBRawValue.uint(0), XCBRawValue.uint(0), XCBRawValue.uint(0), XCBRawValue.uint(0),
            XCBRawValue.uint(72),
            XCBRawValue.uint(0),
            XCBRawValue.uint(0),
            XCBRawValue.uint(0),
            XCBRawValue.string("PLANNING_OPERATION_WILL_START"),
            XCBRawValue.array([XCBRawValue.string("S0"), XCBRawValue.string("FC5F5C50-8B9C-43D6-8F5A-031E967F5CC0")]),
            XCBRawValue.uint(try encoder.getResponseMsgId(subtracting: 3)),
        ]
    }
}

public struct PlanningOperationWillEndResponse: XCBProtocolMessage {
    public init() {}

    public func encode(_ encoder: XCBEncoder) throws -> XCBResponse {
        return [
            XCBRawValue.uint(0), XCBRawValue.uint(0), XCBRawValue.uint(0), XCBRawValue.uint(0), XCBRawValue.uint(0), XCBRawValue.uint(0), XCBRawValue.uint(0),
            XCBRawValue.uint(70),
            XCBRawValue.uint(0),
            XCBRawValue.uint(0),
            XCBRawValue.uint(0),
            XCBRawValue.string("PLANNING_OPERATION_FINISHED"),
            XCBRawValue.array([XCBRawValue.string("S0"), XCBRawValue.string("FC5F5C50-8B9C-43D6-8F5A-031E967F5CC0")]),
            XCBRawValue.uint(try encoder.getResponseMsgId(subtracting: 3)),
        ]
    }
}

public struct BuildOperationEndedResponse: XCBProtocolMessage {
    public init() {}

    public func encode(_: XCBEncoder) throws -> XCBResponse {
        return [
            XCBRawValue.uint(0),
            XCBRawValue.uint(0),
            XCBRawValue.uint(0),
            XCBRawValue.uint(0),

            XCBRawValue.uint(0),
            XCBRawValue.uint(0),
            XCBRawValue.uint(0),
            XCBRawValue.uint(42),
            XCBRawValue.uint(0),
            XCBRawValue.uint(0),
            XCBRawValue.uint(0),
            XCBRawValue.string("BUILD_OPERATION_ENDED"),
            [Int64(gBuildNumber), Int64(0), XCBRawValue.nil],
        ]
    }
}

public struct IndexingInfoReceivedResponse: XCBProtocolMessage {
    let targetID: String
    let data: Data?

    public init(targetID: String = "", data: Data? = nil) {
        self.targetID = targetID
        self.data = data
    }

    public func encode(_: XCBEncoder) throws -> XCBResponse {
        var foo_inputs = [XCBRawValue]()
        if let theData = self.data {
            foo_inputs = [XCBRawValue.string(self.targetID), XCBRawValue.binary(theData)]
        } else {
            foo_inputs = [XCBRawValue.string(self.targetID)]
        }
        
        return [
            XCBRawValue.uint(26),
            XCBRawValue.uint(0),
            XCBRawValue.uint(0),
            XCBRawValue.uint(0),
            XCBRawValue.uint(0),
            XCBRawValue.uint(0),
            XCBRawValue.uint(0),
            XCBRawValue.uint(0),
            XCBRawValue.uint(37),
            XCBRawValue.uint(1),
            XCBRawValue.uint(0),
            XCBRawValue.uint(0),
            XCBRawValue.string("INDEXING_INFO_RECEIVED"),
            XCBRawValue.array(foo_inputs),
        ]
    }
}

public struct BuildTargetPreparedForIndex: XCBProtocolMessage {
    let targetGUID: String

    public init(targetGUID: String) {
        self.targetGUID = targetGUID
    }

    public func encode(_: XCBEncoder) throws -> XCBResponse {
        return [
            XCBRawValue.uint(24),
            XCBRawValue.uint(0),
            XCBRawValue.uint(0),
            XCBRawValue.uint(0),
            XCBRawValue.uint(0),
            XCBRawValue.uint(0),
            XCBRawValue.uint(0),
            XCBRawValue.uint(0),
            XCBRawValue.uint(109),
            XCBRawValue.uint(0),
            XCBRawValue.uint(0),
            XCBRawValue.uint(0),
            XCBRawValue.string("BUILD_TARGET_PREPARED_FOR_INDEX"),
            XCBRawValue.array([
                XCBRawValue.string(self.targetGUID),
                XCBRawValue.array([
                    XCBRawValue.double(677604523.7527775),
                ]),
            ]),
        ]
    }
}

