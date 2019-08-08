import CwlCore
import CwlSignals

extension Adapter: Lifetime {
    public func cancel() {
        if State.self is CodableContainer.Type, let value = combinedSignal.peek()?.state, var sc = value as? CodableContainer {
            sc.cancel()
        }
        input.cancel()
    }
}

extension Adapter: Codable where State: Codable {
    public init(from decoder: Decoder) throws {
        let c = try decoder.singleValueContainer()
        let p = try c.decode(State.self)
        self.init(adapterState: p)
    }
    
    public func encode(to encoder: Encoder) throws {
        if let s = combinedSignal.peek()?.state {
            var c = encoder.singleValueContainer()
            try c.encode(s)
        }
    }
}

extension Adapter: CodableContainer where State: PersistentAdapterState {
    public var childCodableContainers: [CodableContainer] {
        if let state = combinedSignal.peek()?.state {
            return (state as? CodableContainer)?.childCodableContainers ?? []
        } else {
            return []
        }
    }
    
    public var codableValueChanged: Signal<Void> {
        if State.self is CodableContainer.Type {
            return combinedSignal.flatMapLatest { (content: State.Output) -> Signal<Void> in
                let cc = content.state as! CodableContainer
                return cc.codableValueChanged.startWith(())
                }.dropActivation()
        }
        return combinedSignal.map { _ in () }.dropActivation()
    }
}
