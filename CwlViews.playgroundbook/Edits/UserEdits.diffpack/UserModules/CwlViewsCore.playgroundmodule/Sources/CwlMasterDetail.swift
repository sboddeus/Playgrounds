
import CwlSignals
import CwlCore
import Foundation

public enum MasterDetail<Master: CodableContainer, Detail: CodableContainer>: CodableContainer {
    case master(Master)
    case detail(Detail)
    
    public var childCodableContainers: [CodableContainer] {
        switch self {
        case .master(let tvm): return [tvm]
        case .detail(let dvm): return [dvm]
        }
    }
    
    enum Keys: CodingKey { case master, detail }
    
    public func encode(to encoder: Encoder) throws {
        var c = encoder.container(keyedBy: Keys.self)
        switch self {
        case .master(let tvm): try c.encode(tvm, forKey: .master)
        case .detail(let dvm): try c.encode(dvm, forKey: .detail)
        }
    }
    
    public init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: Keys.self)
        if let tvm = try c.decodeIfPresent(Master.self, forKey: .master) {
            self = .master(tvm)
        } else {
            self = .detail(try c.decode(Detail.self, forKey: .detail))
        }
    }
}

