
import CwlSignals
import CwlCore
import Foundation

public struct Constant<Value> {
    public typealias ValueType = Value
    public let value: Value
    public init(_ value: Value) {
        self.value = value
    }
    public static func constant(_ value: Value) -> Constant<Value> {
        return Constant<Value>(value)
    }
}

public struct InitialSubsequent<Value> {
    public let initial: Value?
    public let subsequent: SignalCapture<Value>?
    
    public init<Interface: SignalInterface>(signal: Interface) where Interface.OutputValue == Value {
        let capture = signal.capture()
        let values = capture.values
        self.init(initial: values.last, subsequent: capture)
    }
    
    public init(initial: Value? = nil, subsequent: SignalCapture<Value>? = nil) {
        self.initial = initial
        self.subsequent = subsequent
    }
    
    public func resume() -> Signal<Value>? {
        return subsequent?.resume()
    }
    
    public func apply<I: AnyObject>(_ instance: I, handler: @escaping (I, Value) -> Void) -> Lifetime? {
        return resume().flatMap { $0.apply(instance, handler: handler) }
    }
    
    public func apply<I: AnyObject, Storage: AnyObject>(_ instance: I, _ storage: Storage, handler: @escaping (I, Storage, Value) -> Void) -> Lifetime? {
        return resume().flatMap { $0.apply(instance, storage, handler: handler) }
    }
}

/// An either type for a value or a signal emitting values of that type. Used for "value" bindings (bindings which set a property on the underlying instance)
public enum Dynamic<Value> {
    public typealias ValueType = Value
    case constant(Value)
    case dynamic(Signal<Value>)
    
    /// Gets the initial (i.e. used in the constructor) value from the `Dynamic`
    public func initialSubsequent() -> InitialSubsequent<Value> {
        switch self {
        case .constant(let v):
            return InitialSubsequent<Value>(initial: v)
        case .dynamic(let signal):
            let sc = signal.capture()
            return InitialSubsequent<Value>(initial: sc.values.last, subsequent: sc)
        }
    }
    
    // Gets the subsequent (i.e. after construction) values from the `Dynamic`
    public func apply<I: AnyObject, B: AnyObject>(_ instance: I, _ storage: B, _ onError: Value? = nil, handler: @escaping (I, B, Value) -> Void) -> Lifetime? {
        switch self {
        case .constant(let v):
            handler(instance, storage, v)
            return nil
        case .dynamic(let signal):
            return signal.apply(instance, storage, onError, handler: handler)
        }
    }
    
    // Gets the subsequent (i.e. after construction) values from the `Dynamic`
    public func apply<I: AnyObject>(_ instance: I, handler: @escaping (I, Value) -> Void) -> Lifetime? {
        switch self {
        case .constant(let v):
            handler(instance, v)
            return nil
        case .dynamic(let signal):
            return signal.apply(instance, handler: handler)
        }
    }
}

extension Signal {
    public func apply<I: AnyObject, B: AnyObject>(_ instance: I, _ storage: B, _ onError: OutputValue? = nil, handler: @escaping (I, B, OutputValue) -> Void) -> Lifetime? {
        return signal.subscribe(context: .main) { [unowned instance, unowned storage] r in
            switch (r, onError) {
            case (.success(let v), _): handler(instance, storage, v)
            case (.failure, .some(let v)): handler(instance, storage, v)
            case (.failure, .none): break
            }
        }
    }
    
    public func apply<I: AnyObject>(_ instance: I, handler: @escaping (I, OutputValue) -> Void) -> Lifetime? {
        return signal.subscribeValues(context: .main) { [unowned instance] v in handler(instance, v) }
    }
}

public struct ScopedValues<Scope, Value>: ExpressibleByArrayLiteral {
    public typealias ArrayLiteralElement = ScopedValues<Scope, Value>
    
    public let pairs: [(scope: Scope, value: Value)]
    
    public init(arrayLiteral elements: ScopedValues<Scope, Value>...) {
        self.pairs = elements.flatMap { $0.pairs }
    }
    
    public init(pairs: [(Scope, Value)]) {
        self.pairs = pairs
    }
    
    public init(scope: Scope, value: Value) {
        self.pairs = [(scope, value)]
    }
    
    public static func value(_ value: Value, for scope: Scope) -> ScopedValues<Scope, Value> {
        return ScopedValues(scope: scope, value: value)
    }
}

extension Dynamic {
    // Gets the subsequent (i.e. after construction) values from the `Dynamic`
    public func apply<I: AnyObject, Scope, V>(instance: I, removeOld: @escaping (I, Scope, V) -> Void, applyNew: @escaping (I, Scope, V) -> Void) -> Lifetime? where ScopedValues<Scope, V> == Value {
        var previous: ScopedValues<Scope, V>? = nil
        return apply(instance) { i, v in
            for (scope, value) in previous?.pairs ?? [] {
                removeOld(instance, scope, value)
            }
            previous = v
            for (scope, value) in v.pairs {
                applyNew(instance, scope, value)
            }
        }
    }
}

public struct Callback<Value, CallbackValue> {
    public let value: Value
    public let callback: SignalInput<CallbackValue>
    
    public init(_ value: Value, _ callback: SignalInput<CallbackValue>) {
        self.value = value
        self.callback = callback
    }
}

extension SignalInterface {
    public func callbackBind<CallbackInputInterface: SignalInputInterface>(to callback: CallbackInputInterface) -> Signal<Callback<OutputValue, CallbackInputInterface.InputValue>> {
        return map { value in Callback(value, callback.input) }
    }
    
    public func ignoreCallback<CallbackValue>() -> Signal<Callback<OutputValue, CallbackValue>> {
        let (i, _) = Signal<CallbackValue>.create()
        return map { value in Callback(value, i) }
    }
}

/// This type encapsulates the idea that target-action pairs in Cocoa may target a specific object (by setting the target to non-nil) or may let the responder chain search for a responder that handles a specific selector.
public enum TargetAction {
    case firstResponder(Selector)
    case singleTarget(SignalInput<Any?>)
}

public protocol TargetActionSender: class {
    var action: Selector? { get set }
    var target: AnyObject? { get set }
}

extension TargetAction {
    public func apply<Source: TargetActionSender>(to instance: Source, constructTarget: () -> SignalActionTarget, selector: Selector = SignalActionTarget.selector) -> Lifetime? {
        switch self {
        case .firstResponder(let s):
            instance.target = nil
            instance.action = s
            return nil
        case .singleTarget(let s):
            let target = constructTarget()
            instance.target = target
            instance.action = SignalActionTarget.selector
            return target.signal.cancellableBind(to: s)
        }
    }
}
