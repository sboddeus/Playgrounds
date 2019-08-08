
import CwlSignals
import CwlCore

public struct ToggleValue: PersistentAdapterState {
    public typealias Message = Void
    public typealias Notification = Bool
    
    public let value: Bool
    public init(value: Bool) {
        self.value = value
    }
    
    public func reduce(message: Void, feedback: SignalMultiInput<Message>) -> Output {
        return Output(state: ToggleValue(value: !value), notification: !value)
    }
    
    public func resume() -> Notification? { return value }
    
    public static func initialize(message: Message, feedback: SignalMultiInput<Message>) -> Output? {
        return nil
    }
}

public typealias ToggleVar = Adapter<ToggleValue>

public extension Adapter where State == ToggleValue {
    init(_ value: Bool) {
        self.init(adapterState: ToggleValue(value: value))
    }
}

