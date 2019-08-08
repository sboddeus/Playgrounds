
import CwlSignals
import CwlCore
import Foundation

public struct ModelState<Wrapped, M, N>: AdapterState {
    public typealias Message = M
    public typealias Notification = N
    public let instanceContext: (Exec, Bool) 
    
    let reducer: (_ model: inout Wrapped, _ message: Message, _ feedback: SignalMultiInput<Message>) throws -> Notification?
    let resumer: (_ model: Wrapped) -> Notification?
    let wrapped: Wrapped
    
    init(previous: ModelState<Wrapped, M, N>, nextWrapped: Wrapped) {
        self.instanceContext = previous.instanceContext
        self.reducer = previous.reducer
        self.resumer = previous.resumer
        self.wrapped = nextWrapped
    }
    
    public init(async: Bool = false, initial: Wrapped, resumer: @escaping (_ model: Wrapped) -> Notification? = { _ in nil }, reducer: @escaping (_ model: inout Wrapped, _ message: Message, _ feedback: SignalMultiInput<Message>) throws -> Notification?) {
        self.instanceContext = (Exec.syncQueue(), async)
        self.reducer = reducer
        self.resumer = resumer
        self.wrapped = initial
    }
    
    public func reduce(message: Message, feedback: SignalMultiInput<Message>) throws -> (state: ModelState<Wrapped, Message, Notification>, notification: N?) {
        var nextWrapped = wrapped
        let n = try reducer(&nextWrapped, message, feedback)
        return (ModelState<Wrapped, M, N>(previous: self, nextWrapped: nextWrapped), n)
    }
    
    public func resume() -> Notification? {
        return resumer(wrapped)
    }
}


public extension Adapter {
    /// Access the internal state outside of the reactive pipeline.
    ///
    /// NOTE: this function is `throws` *not* `rethrows`. The function may throw regardless of whether the supplied `processor` may throw.
    ///
    /// - Parameter processor: performs work with the underlying state
    /// - Returns: the result from `processor`
    /// - Throws: Other than any error thrown from `processor`, this function can throw if no model value is available (it might not be initialized or the execution context may have delayed the response).
    func sync<Wrapped, R, M, N>(_ processor: (Wrapped) throws -> R) throws -> R where ModelState<Wrapped, M, N> == State {
        // Don't `peek` inside the `invokeSync` since that would require re-entering the `executionContext`.
        let wrapped = try combinedSignal.capture().get().state.wrapped
        return try executionContext.invokeSync { return try processor(wrapped) }
    }
    
    func slice<Wrapped, Processed, M, N>(resume: N? = nil, _ processor: @escaping (Wrapped, N) throws -> Signal<Processed>.Next) -> Signal<Processed> where ModelState<Wrapped, M, N> == State {
        let s: Signal<State.Output>
        if let r = resume {
            s = combinedSignal.compactMapActivation(context: executionContext) { ($0.state, r) }
        } else {
            s = combinedSignal
        }
        return s.transform(context: executionContext) { result in
            switch result {
            case .failure(let e): return .end(e)
            case .success(_, nil): return .none
            case .success(let wrapped, .some(let notification)):
                do {
                    return try processor(wrapped.wrapped, notification)
                } catch {
                    return .error(error)
                }
            }
        }
    }
    
    func slice<Value, Wrapped, Processed, M, N>(initial: Value, resume: N? = nil, _ processor: @escaping (inout Value, Wrapped, N) throws -> Signal<Processed>.Next) -> Signal<Processed> where ModelState<Wrapped, M, N> == State {
        let s: Signal<State.Output>
        if let r = resume {
            s = combinedSignal.compactMapActivation(context: executionContext) { ($0.state, r) }
        } else {
            s = combinedSignal
        }
        return s.transform(initialState: initial, context: executionContext) { value, result in
            switch result {
            case .failure(let e): return .end(e)
            case .success(_, nil): return .none
            case .success(let wrapped, .some(let notification)):
                do {
                    return try processor(&value, wrapped.wrapped, notification)
                } catch {
                    return .error(error)
                }
            }
        }
    }
    
    func logJson<Wrapped, M, N, Value>(keyPath: KeyPath<Wrapped, Value>, prefix: String = "", formatting: JSONEncoder.OutputFormatting = .prettyPrinted) -> Lifetime where State == ModelState<Wrapped, M, N>, Value: Encodable {
        return combinedSignal.subscribeValues(context: executionContext) { (state, _) in
            let enc = JSONEncoder()
            enc.outputFormatting = formatting
            if let data = try? enc.encode(state.wrapped[keyPath: keyPath]), let string = String(data: data, encoding: .utf8) {
                print("\(prefix)\(string)")
            }
        }
    }
}
