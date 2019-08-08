
import CwlSignals
import CwlCore

public typealias Var<Value: Codable> = Adapter<VarState<Value>>

public struct VarState<Value: Codable>: PersistentAdapterState {
    public enum Message {
        case set(Value)
        case update(Value)
        case notify(Value)
    }
    public typealias Notification = Value
    
    public let value: Value
    public init(value: Value) {
        self.value = value
    }
    
    public func reduce(message: Message, feedback: SignalMultiInput<Message>) -> Output {
        switch message {
        case .set(let v): return Output(state: VarState<Value>(value: v), notification: v)
        case .update(let v): return Output(state: VarState<Value>(value: v), notification: nil)
        case .notify(let v): return Output(state: self, notification: v)
        }
    }
    
    public func resume() -> Notification? {
        return value
    }
    
    public static func initialize(message: Message, feedback: SignalMultiInput<Message>) -> Output? {
        switch message {
        case .set(let v): return Output(state: VarState<Value>(value: v), notification: v)
        case .update(let v): return Output(state: VarState<Value>(value: v), notification: nil)
        case .notify: return nil
        }
    }
}

extension VarState: Codable where Value: Codable {}

extension VarState: Lifetime where Value: Lifetime {
    public mutating func cancel() {
        var v = value
        v.cancel()
        self = VarState(value: v)
    }
}

extension VarState: CodableContainer where Value: CodableContainer {
    public var childCodableContainers: [CodableContainer] {
        return value.childCodableContainers
    }
    
    public var codableValueChanged: Signal<Void> {
        return value.codableValueChanged
    }
}

public extension Adapter {
    init<Value>(_ value: Value) where VarState<Value> == State {
        self.init(adapterState: VarState<Value>(value: value))
    }
}

public extension Adapter {
    func set<Value>() -> SignalInput<Value> where State.Message == VarState<Value>.Message {
        return Input().map { VarState<Value>.Message.set($0) }.bind(to: self)
    }
    
    func update<Value>() -> SignalInput<Value> where State.Message == VarState<Value>.Message {
        return Input().map { VarState<Value>.Message.update($0) }.bind(to: self)
    }
    
    func notify<Value>() -> SignalInput<Value> where State.Message == VarState<Value>.Message {
        return Input<Value>().map { VarState<Value>.Message.notify($0) }.bind(to: self)
    }
    
    func allChanges<Value>() -> Signal<Value> where State == VarState<Value> {
        return combinedSignal.compactMap { combined in combined.notification ?? combined.state.value }
    }
    
    func stateChanges<Value>() -> Signal<Value> where State == VarState<Value> {
        return combinedSignal.compactMap { combined in combined.state.value }
    }
}

public extension SignalInterface {
    func bind<InputInterface>(to interface: InputInterface) where InputInterface: SignalInputInterface, InputInterface.InputValue == VarState<OutputValue>.Message {
        return map { VarState<OutputValue>.Message.set($0) }.bind(to: interface)
    }
}

public extension SignalChannel {
    func bind<Target>(to interface: Target) -> InputInterface where Target: SignalInputInterface, Target.InputValue == VarState<Interface.OutputValue>.Message {
        return final { $0.map { VarState<Interface.OutputValue>.Message.set($0) }.bind(to: interface) }.input
    }
}

public extension BindingName {
    /// Build an action binding (callbacks triggered by the instance) from a name and a signal input.
    ///
    /// - Parameters:
    ///   - name: the binding name
    ///   - value: the binding argument
    /// - Returns: the binding
    static func --><A>(name: BindingName<Value, Source, Binding>, value: Adapter<VarState<A>>) -> Binding where SignalInput<A> == Value {
        return name.binding(with: value.set())
    }
}
