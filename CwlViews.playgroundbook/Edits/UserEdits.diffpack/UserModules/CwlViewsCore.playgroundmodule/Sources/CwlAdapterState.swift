
import CwlCore
import CwlSignals
import Foundation

public protocol AdapterState {
    associatedtype Message
    associatedtype Notification
    
    typealias Output = (state: Self, notification: Notification?)
    
    static var defaultContext: (Exec, Bool) { get }
    
    static func initialize(message: Message, feedback: SignalMultiInput<Message>) throws -> Output?
    
    var instanceContext: (Exec, Bool) { get }
    
    func reduce(message: Message, feedback: SignalMultiInput<Message>) throws -> Output
    func resume() -> Notification?
}

public extension AdapterState {
    static var defaultContext: (Exec, Bool) {
        return (.direct, false)
    }
    
    var instanceContext: (Exec, Bool) {
        return Self.defaultContext
    }
    
    static func initialize(message: Message, feedback: SignalMultiInput<Message>) throws -> Output? {
        return nil
    }
}

public protocol NonPersistentAdapterState: AdapterState, Codable {
    init()
}

public extension NonPersistentAdapterState {
    init(from decoder: Decoder) throws {
        self.init()
    }
    
    func encode(to encoder: Encoder) throws {
    }
}

public extension Adapter {
    init<Value>() where TempValue<Value> == State {
        self.init(adapterState: TempValue<Value>())
    }
}

public protocol PersistentAdapterState: AdapterState, Codable {
    associatedtype PersistentValue: Codable
    init(value: PersistentValue)
    var value: PersistentValue { get }
}

extension PersistentAdapterState where Notification == PersistentValue {
    public func resume() -> Notification? {
        return value
    }
}

extension Adapter where State: PersistentAdapterState {
    public var state: Signal<State> {
        return combinedSignal.compactMap { content in content.state }
    }
}

public extension PersistentAdapterState {
    init(from decoder: Decoder) throws {
        let c = try decoder.singleValueContainer()
        let p = try c.decode(PersistentValue.self)
        self.init(value: p)
    }
    
    func encode(to encoder: Encoder) throws {
        var c = encoder.singleValueContainer()
        try c.encode(value)
    }
}

extension Adapter where State: PersistentAdapterState {
    public func logJson(prefix: String = "", formatting: JSONEncoder.OutputFormatting = .prettyPrinted) -> Lifetime {
        return codableValueChanged
            .startWith(())
            .subscribe { _ in
                let enc = JSONEncoder()
                enc.outputFormatting = formatting
                if let data = try? enc.encode(self), let string = String(data: data, encoding: .utf8) {
                    print("\(prefix)\(string)")
                }
        }
    }
}

public protocol PersistentContainerAdapterState: PersistentAdapterState, CodableContainer where PersistentValue: CodableContainer {}

extension PersistentContainerAdapterState {
    public var childCodableContainers: [CodableContainer] {
        return value.childCodableContainers
    }
    
    public var codableValueChanged: Signal<Void> {
        return value.codableValueChanged
    }
}
