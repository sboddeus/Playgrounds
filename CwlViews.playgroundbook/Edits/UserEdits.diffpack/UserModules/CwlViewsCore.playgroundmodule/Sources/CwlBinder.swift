
import CwlSignals
import CwlCore
import Foundation

/// Implementation for `BinderStorage` that wraps Cocoa objects.
open class AssociatedBinderStorage: NSObject {
    public typealias Instance = NSObject
    private var lifetimes: [Lifetime]? = nil
    
    /// The embed function will avoid embedding and let the AssociatedBinderStorage release if this function returns false.
    /// Override and alter logic if a subclass may require the storage to persist when lifetimes is empty and the dynamic delegate is unused.
    open var isInUse: Bool {
        guard let ls = lifetimes else { fatalError("Embed must be called before isInUse") }
        return ls.isEmpty == false || dynamicDelegate != nil
    }
    
    /// Implementation of the `BinderStorage` method to embed supplied lifetimes in an instance. This may be performed once-only for a given instance and storage (the storage should have the same lifetime as the instance and should not be disconnected once connected).
    ///
    /// - Parameters:
    ///   - lifetimes: lifetimes that will be stored in this storage
    ///   - instance: an NSObject where this storage will embed itself
    public func embed(lifetimes: [Lifetime], in instance: NSObjectProtocol) {
        assert(self.lifetimes == nil, "Bindings should be set once only")
        self.lifetimes = lifetimes
        guard isInUse else { return }
        
        assert(instance.associatedBinderStorage(subclass: AssociatedBinderStorage.self) == nil, "Bindings should be set once only")
        instance.setAssociatedBinderStorage(self)
    }
    
    /// Explicitly invoke `cancel` on each of the bindings.
    ///
    /// WARNING: if `cancel` is invoked outside the main thread, it will be *asynchronously* invoked on the main thread.
    /// Normally, a `cancel` effect is expected to have synchronous effect but it since `cancel` on Binder objects is usually used for breaking reference counted loops, it is considered that the synchronous effect of cancel is less important than avoiding deadlocks – and deadlocks would be easy to accidentally trigger if this were synchronously invoked. If you need synchronous effect, ensure that cancel is invoked on the main thread.
    public func cancel() {
        guard Thread.isMainThread else { DispatchQueue.main.async(execute: self.cancel); return }
        
        // `cancel` is mutating so we must use a `for var` (we can't use `forEach`)
        for var l in lifetimes ?? [] {
            l.cancel()
        }
        
        dynamicDelegate?.implementedSelectors = [:]
        dynamicDelegate = nil
    }
    
    deinit {
        cancel()
    }
    
    /// The `dynamicDelegate` is a work-around for the fact that some Cocoa objects change their behavior if you have a delegate that implements a given delegate method. Since Binders will likely implement *all* of their delegate methods, the dynamicDelegate can be used to selectively respond to particular selectors at runtime.
    public var dynamicDelegate: DynamicDelegate?
    
    /// An override of the NSObject method so that the dynamicDelegate can work. When the dynamicDelegate states that it can respond to a given selector, that selector is directed to the dynamicDelegate instead. This function will only be involved if Objective-C message sends are sent to the BinderStorage – a rare occurrence outside of deliberate delegate invocations.
    ///
    /// - Parameter selector: Objective-C selector that may be implemented by the dynamicDelegate
    /// - Returns: the dynamicDelegate, if it implements the selector
    open override func forwardingTarget(for selector: Selector) -> Any? {
        if let dd = dynamicDelegate, let value = dd.implementedSelectors[selector] {
            dd.associatedHandler = value
            return dd
        }
        return nil
    }
    
    /// An override of the NSObject method so that the dynamicDelegate can work.
    ///
    /// - Parameter selector: Objective-C selector that may be implemented by the dynamicDelegate
    /// - Returns: true if the dynamicDelegate implements the selector, otherwise returns the super implementation
    open override func responds(to selector: Selector) -> Bool {
        if let dd = dynamicDelegate, let value = dd.implementedSelectors[selector] {
            dd.associatedHandler = value
            return true
        }
        return super.responds(to: selector)
    }
}

/// Used in conjunction with `AssociatedBinderStorage`, subclasses of `DynamicDelegate` can implement all delegate methods at compile time but have the `AssociatedBinderStorage` report true to `responds(to:)` only in the cases where the delegate method is selected for enabling.
open class DynamicDelegate: NSObject, DefaultConstructable {
    var implementedSelectors = Dictionary<Selector, Any>()
    var associatedHandler: Any?
    
    public required override init() {
        super.init()
    }
    
    public func handlesSelector(_ selector: Selector) -> Bool {
        return implementedSelectors[selector] != nil
    }
    
    public func multiHandler<T>(_ t: T) {
        defer { associatedHandler = nil }
        (associatedHandler as! [(T) -> Void]).forEach { f in f(t) }
    }
    
    public func multiHandler<T, U>(_ t: T, _ u: U) {
        defer { associatedHandler = nil }
        (associatedHandler as! [(T, U) -> Void]).forEach { f in f(t, u) }
    }
    
    public func multiHandler<T, U, V>(_ t: T, _ u: U, _ v: V) {
        defer { associatedHandler = nil }
        (associatedHandler as! [(T, U, V) -> Void]).forEach { f in f(t, u, v) }
    }
    
    public func multiHandler<T, U, V, W>(_ t: T, _ u: U, _ v: V, _ w: W) {
        defer { associatedHandler = nil }
        (associatedHandler as! [(T, U, V, W) -> Void]).forEach { f in f(t, u, v, w) }
    }
    
    public func multiHandler<T, U, V, W, X>(_ t: T, _ u: U, _ v: V, _ w: W, _ x: X) {
        defer { associatedHandler = nil }
        (associatedHandler as! [(T, U, V, W, X) -> Void]).forEach { f in f(t, u, v, w, x) }
    }
    
    public func singleHandler<T, R>(_ t: T) -> R {
        defer { associatedHandler = nil }
        return (associatedHandler as! ((T) -> R))(t)
    }
    
    public func singleHandler<T, U, R>(_ t: T, _ u: U) -> R {
        defer { associatedHandler = nil }
        return (associatedHandler as! ((T, U) -> R))(t, u)
    }
    
    public func singleHandler<T, U, V, R>(_ t: T, _ u: U, _ v: V) -> R {
        defer { associatedHandler = nil }
        return (associatedHandler as! ((T, U, V) -> R))(t, u, v)
    }
    
    public func singleHandler<T, U, V, W, R>(_ t: T, _ u: U, _ v: V, _ w: W) -> R {
        defer { associatedHandler = nil }
        return (associatedHandler as! ((T, U, V, W) -> R))(t, u, v, w)
    }
    
    public func singleHandler<T, U, V, W, X, R>(_ t: T, _ u: U, _ v: V, _ w: W, _ x: X) -> R {
        defer { associatedHandler = nil }
        return (associatedHandler as! ((T, U, V, W, X) -> R))(t, u, v, w, x)
    }
    
    public func addSingleHandler1<T, R>(_ value: @escaping (T) -> R, _ selector: Selector) {
        precondition(implementedSelectors[selector] == nil, "It is not possible to add multiple handlers to a delegate that returns a value.")
        implementedSelectors[selector] = value
    }
    
    public func addSingleHandler2<T, U, R>(_ value: @escaping (T, U) -> R, _ selector: Selector) {
        precondition(implementedSelectors[selector] == nil, "It is not possible to add multiple handlers to a delegate that returns a value.")
        implementedSelectors[selector] = value
    }
    
    public func addSingleHandler3<T, U, V, R>(_ value: @escaping (T, U, V) -> R, _ selector: Selector) {
        precondition(implementedSelectors[selector] == nil, "It is not possible to add multiple handlers to a delegate that returns a value.")
        implementedSelectors[selector] = value
    }
    
    public func addSingleHandler4<T, U, V, W, R>(_ value: @escaping (T, U, V, W) -> R, _ selector: Selector) {
        precondition(implementedSelectors[selector] == nil, "It is not possible to add multiple handlers to a delegate that returns a value.")
        implementedSelectors[selector] = value
    }
    
    public func addSingleHandler5<T, U, V, W, X, R>(_ value: @escaping (T, U, V, W, X) -> R, _ selector: Selector) {
        precondition(implementedSelectors[selector] == nil, "It is not possible to add multiple handlers to a delegate that returns a value.")
        implementedSelectors[selector] = value
    }
    
    public func addMultiHandler1<T>(_ value: @escaping (T) -> Void, _ selector: Selector) {
        if let existing = implementedSelectors[selector] {
            var existingArray = existing as! [(T) -> Void]
            existingArray.append(value)
        } else {
            implementedSelectors[selector] = [value] as [(T) -> Void]
        }
    }
    
    public func addMultiHandler2<T, U>(_ value: @escaping (T, U) -> Void, _ selector: Selector) {
        if let existing = implementedSelectors[selector] {
            var existingArray = existing as! [(T, U) -> Void]
            existingArray.append(value)
        } else {
            implementedSelectors[selector] = [value] as [(T, U) -> Void]
        }
    }
    
    public func addMultiHandler3<T, U, V>(_ value: @escaping (T, U, V) -> Void, _ selector: Selector) {
        if let existing = implementedSelectors[selector] {
            var existingArray = existing as! [(T, U, V) -> Void]
            existingArray.append(value)
        } else {
            implementedSelectors[selector] = [value] as [(T, U, V) -> Void]
        }
    }
    
    public func addMultiHandler4<T, U, V, W>(_ value: @escaping (T, U, V, W) -> Void, _ selector: Selector) {
        if let existing = implementedSelectors[selector] {
            var existingArray = existing as! [(T, U, V, W) -> Void]
            existingArray.append(value)
        } else {
            implementedSelectors[selector] = [value] as [(T, U, V, W) -> Void]
        }
    }
    
    public func addMultiHandler5<T, U, V, W, X>(_ value: @escaping (T, U, V, W, X) -> Void, _ selector: Selector) {
        if let existing = implementedSelectors[selector] {
            var existingArray = existing as! [(T, U, V, W, X) -> Void]
            existingArray.append(value)
        } else {
            implementedSelectors[selector] = [value] as [(T, U, V, W, X) -> Void]
        }
    }
}

private var associatedBinderStorageKey = NSObject()
public extension NSObjectProtocol {
    /// Accessor for any embedded AssociatedBinderStorage on an NSObject. This method is provided for debugging purposes; you should never normally need to access the storage obbject.
    ///
    /// - Parameter for: an NSObject
    /// - Returns: the embedded AssociatedBinderStorage (if any)
    func associatedBinderStorage<S: AssociatedBinderStorage>(subclass: S.Type) -> S? {
        return objc_getAssociatedObject(self, &associatedBinderStorageKey) as? S
    }
    
    /// Accessor for any embedded AssociatedBinderStorage on an NSObject. This method is provided for debugging purposes; you should never normally need to access the storage obbject.
    ///
    /// - Parameter newValue: an AssociatedBinderStorage or nil (if clearinging storage)
    func setAssociatedBinderStorage(_ newValue: AssociatedBinderStorage?) {
        objc_setAssociatedObject(self, &associatedBinderStorageKey, newValue, objc_AssociationPolicy.OBJC_ASSOCIATION_RETAIN)
    }
}

public enum BinderState<Preparer: BinderPreparer> {
    case pending(type: Preparer.Instance.Type, parameters: Preparer.Parameters, bindings: [Preparer.Binding])
    case constructed(Preparer.Output)
    case consumed
}

public protocol Binder: class {
    associatedtype Preparer: BinderPreparer
    
    var state: BinderState<Preparer> { get set }
    init(type: Preparer.Instance.Type, parameters: Preparer.Parameters, bindings: [Preparer.Binding]) 
}

public extension Binder {
    typealias Instance = Preparer.Instance
    typealias Parameters = Preparer.Parameters
    typealias Output = Preparer.Output
    
    /// Invokes `consume` on the underlying state. If the state is not `pending`, this will trigger a fatal error. State will be set to `consumed`.
    ///
    /// - Returns: the array of `Binding` from the state parameters.
    func consume() -> (type: Preparer.Instance.Type, parameters: Preparer.Parameters, bindings: [Preparer.Binding]) {
        guard case .pending(let type, let parameters, let bindings) = state else {
            fatalError("Attempted to consume bindings from already constructed or consumed binder.")
        }
        state = .consumed
        return (type: type, parameters: parameters, bindings: bindings)
    }
}

extension Binder where Preparer.Parameters == Void {
    /// A constructor used when dynamically assembling arrays of bindings
    ///
    /// - Parameters:
    ///   - bindings: array of bindings
    public init(type: Preparer.Instance.Type = Preparer.Instance.self, bindings: [Preparer.Binding]) {
        self.init(type: type, parameters: (), bindings: bindings)
    }
    
    /// A constructor for a binder.
    ///
    /// - Parameters:
    ///   - bindings: list of bindings
    public init(type: Preparer.Instance.Type = Preparer.Instance.self, _ bindings: Preparer.Binding...) {
        self.init(type: type, parameters: (), bindings: bindings)
    }
}

private extension Binder where Preparer: BinderApplyable {
    var constructed: Preparer.Output? {
        guard case .constructed(let output) = state else { return nil }
        return output
    }
}

public extension Binder where Preparer: BinderApplyable {
    func apply(to instance: Preparer.Instance) {
        let (_, _, bindings) = consume()
        let (preparer, instance, storage, lifetimes) = Preparer.bind(bindings) { _ in instance }
        _ = preparer.combine(lifetimes: lifetimes, instance: instance, storage: storage)
    }
}

public extension Binder where Preparer: BinderConstructor, Preparer.Instance == Preparer.Output {
    func instance() -> Preparer.Instance {
        if let output = constructed { return output }
        let (type, parameters, bindings) = consume()
        let (preparer, instance, storage, lifetimes) = Preparer.bind(bindings) { preparer in
            preparer.constructInstance(type: type, parameters: parameters)
        }
        let output = preparer.combine(lifetimes: lifetimes, instance: instance, storage: storage)
        state = .constructed(instance)
        return output
    }
    
    func instance(parameters: Parameters) -> Preparer.Instance {
        if let output = constructed { return output }
        let (type, _, bindings) = consume()
        let (preparer, instance, storage, lifetimes) = Preparer.bind(bindings) { preparer in
            preparer.constructInstance(type: type, parameters: parameters)
        }
        let output = preparer.combine(lifetimes: lifetimes, instance: instance, storage: storage)
        state = .constructed(instance)
        return output
    }
}

public extension Binder where Preparer: BinderApplyable, Preparer.Storage == Preparer.Output {
    func wrap(instance: Preparer.Instance) -> Preparer.Output {
        if let output = constructed { return output }
        let (_, _, bindings) = consume()
        let (preparer, instance, storage, lifetimes) = Preparer.bind(bindings) { _ in instance }
        let output = preparer.combine(lifetimes: lifetimes, instance: instance, storage: storage)
        state = .consumed
        return output
    }
}

public extension Binder where Preparer: BinderConstructor, Preparer.Storage == Preparer.Output {
    func construct() -> Preparer.Output {
        let (type, parameters, bindings) = consume()
        let (preparer, instance, storage, lifetimes) = Preparer.bind(bindings) { preparer in
            preparer.constructInstance(type: type, parameters: parameters)
        }
        let output = preparer.combine(lifetimes: lifetimes, instance: instance, storage: storage)
        state = .constructed(output)
        return output
    }
    
    func construct(parameters: Parameters) -> Preparer.Output {
        let (type, _, bindings) = consume()
        let (preparer, instance, storage, lifetimes) = Preparer.bind(bindings) { preparer in
            preparer.constructInstance(type: type, parameters: parameters)
        }
        let output = preparer.combine(lifetimes: lifetimes, instance: instance, storage: storage)
        state = .constructed(output)
        return output
    }
}

/// Preparers usually default construct the `Storage` except in specific cases where the storage needs a reference to the instance.
public protocol BinderApplyable: BinderPreparer {
    /// Constructs the `Storage`
    ///
    /// - Returns: the storage
    func constructStorage(instance: Instance) -> Storage
    
    /// - Returns: the output, after tying the lifetimes of the instance and storage together
    func combine(lifetimes: [Lifetime], instance: Instance, storage: Storage) -> Output
}

public extension BinderApplyable {
    static func bind(_ bindings: [Binding], to source: (_ preparer: Self) -> Instance) -> (Self, Instance, Storage, [Lifetime]) {
        var preparer = Self()
        for b in bindings {
            preparer.prepareBinding(b)
        }
        
        var lifetimes = [Lifetime]()
        let instance = source(preparer)
        let storage = preparer.constructStorage(instance: instance)
        
        preparer.prepareInstance(instance, storage: storage)
        
        for b in bindings {
            lifetimes += preparer.applyBinding(b, instance: instance, storage: storage)
        }
        
        lifetimes += preparer.finalizeInstance(instance, storage: storage)
        
        return (preparer, instance, storage, lifetimes)
    }
}

public struct BinderBase: BinderPreparer {
    public typealias Instance = Any
    public typealias Storage = Any
    
    public enum Binding: BinderBaseBinding {
        case lifetimes(Dynamic<[Lifetime]>)
        case adHocPrepare((Any) -> Void)
        case adHocFinalize((Any) -> Lifetime?)
    }
    
    public var inherited: BinderBase { get { return self } set { } }
    public var adHocPrepareClosures: [(Any) -> Void]?
    public var adHocFinalizeClosures: [(Any) -> Lifetime?]?
    
    public init() {}
    
    public func inheritedBinding(from: BinderBase.Binding) -> BinderBase.Binding? { return nil }
    public mutating func prepareBinding(_ binding: Binding) {
        switch binding {
        case .adHocPrepare(let x): adHocPrepareClosures = adHocPrepareClosures?.appending(x) ?? [x]
        case .adHocFinalize(let x): adHocFinalizeClosures = adHocFinalizeClosures?.appending(x) ?? [x]
        default: break
        }
    }
    public func prepareInstance(_ instance: Instance, storage: Storage) {
        adHocPrepareClosures.map { array in array.forEach { c in c(instance) } }
    }
    public func applyBinding(_ binding: Binding, instance: Instance, storage: Storage) -> Lifetime? {
        switch binding {
        case .lifetimes(let x):
            switch x {
            case .constant(let lifetimes):
                return lifetimes.isEmpty ? nil : AggregateLifetime(lifetimes: lifetimes)
            case .dynamic(let signal):
                var previous: [Lifetime]?
                return signal.subscribe(context: .main) { next in
                    if var previous = previous {
                        for i in previous.indices {
                            previous[i].cancel()
                        }
                    }
                    if case .success(let next) = next {
                        previous = next
                    }
                }
            }
        case .adHocPrepare: return nil
        case .adHocFinalize: return nil
        }
    }
    public func finalizeInstance(_ instance: Instance, storage: Storage) -> Lifetime? {
        return adHocFinalizeClosures.map { array in AggregateLifetime(lifetimes: array.compactMap { c in c(instance) }) }
    }
    public func combine(lifetimes: [Lifetime], instance: Any, storage: Any) -> Any { return () }
}

public protocol BinderBaseBinding: Binding {
    static func binderBaseBinding(_ binding: BinderBase.Binding) -> Self
    func asBinderBaseBinding() -> BinderBase.Binding?
}
public extension BinderBaseBinding where Preparer.Inherited.Binding: BinderBaseBinding {
    func asBinderBaseBinding() -> BinderBase.Binding? {
        return asInheritedBinding()?.asBinderBaseBinding()
    }
}
public extension BinderBase.Binding {
    typealias Preparer = BinderBase
    func asInheritedBinding() -> Preparer.Inherited.Binding? { return nil }
    static func binderBaseBinding(_ binding: BinderBase.Binding) -> BinderBase.Binding { return binding }
}

extension BindingName where Binding: BinderBaseBinding {
    public typealias BinderBaseName<V> = BindingName<V, BinderBase.Binding, Binding>
    private static func name<V>(_ source: @escaping (V) -> BinderBase.Binding) -> BinderBaseName<V> {
        return BinderBaseName<V>(source: source, downcast: Binding.binderBaseBinding)
    }
}
public extension BindingName where Binding: BinderBaseBinding {
    // You can easily convert the `Binding` cases to `BindingName` using the following Xcode-style regex:
    // Replace: case ([^\(]+)\((.+)\)$
    // With:    static var $1: BinderBaseName<$2> { return .name(BinderBase.Binding.$1) }
    static var lifetimes: BinderBaseName<Dynamic<[Lifetime]>> { return .name(BinderBase.Binding.lifetimes) }
    
    static var adHocPrepare: BinderBaseName<(Binding.Preparer.Instance) -> Void> {
        return Binding.compositeName(
            value: { f in { (any: Any) -> Void in f(any as! Binding.Preparer.Instance) } },
            binding: BinderBase.Binding.adHocPrepare,
            downcast: Binding.binderBaseBinding
        )
    }
    
    static var adHocFinalize: BinderBaseName<(Binding.Preparer.Instance) -> Lifetime?> {
        return Binding.compositeName(
            value: { f in { (any: Any) -> Lifetime? in return f(any as! Binding.Preparer.Instance) } },
            binding: BinderBase.Binding.adHocFinalize,
            downcast: Binding.binderBaseBinding
        )
    }
}

public protocol BinderDelegateEmbedder: BinderEmbedder where Instance: HasDelegate {
    associatedtype Delegate: DynamicDelegate
    init(delegateClass: Delegate.Type)
    var delegateClass: Delegate.Type { get }
    var dynamicDelegate: Delegate? { get set }
    var delegateIsRequired: Bool { get }
    func prepareDelegate(instance: Instance, storage: Storage)
}

public typealias BinderDelegateEmbedderConstructor = BinderDelegateEmbedder & BinderConstructor

public protocol HasDelegate: class {
    associatedtype DelegateProtocol
    var delegate: DelegateProtocol? { get set }
}

public extension BinderDelegateEmbedder {
    init() {
        self.init(delegateClass: Delegate.self)
    }
    
    var delegateIsRequired: Bool { return dynamicDelegate != nil }
    
    mutating func delegate() -> Delegate {
        if let d = dynamicDelegate {
            return d
        } else {
            let d = delegateClass.init()
            dynamicDelegate = d
            return d
        }
    }
}

public extension BinderDelegateEmbedder where Delegate: DynamicDelegate {
    func prepareDelegate(instance: Instance, storage: Storage) {
        if delegateIsRequired {
            precondition(instance.delegate == nil, "Conflicting delegate applied to instance")
            if dynamicDelegate != nil {
                storage.dynamicDelegate = dynamicDelegate
            }
            instance.delegate = (storage as! Instance.DelegateProtocol)
        }
    }
    
    func prepareInstance(_ instance: Instance, storage: Storage) {
        inheritedPrepareInstance(instance, storage: storage)
        
        prepareDelegate(instance: instance, storage: storage)
    }
}

public protocol BinderDelegateDerived: BinderEmbedderConstructor where Inherited: BinderDelegateEmbedderConstructor {
    init(delegateClass: Inherited.Delegate.Type)
}

public extension BinderDelegateDerived {
    typealias Delegate = Inherited.Delegate
    init() {
        self.init(delegateClass: Inherited.Delegate.self)
    }
    var dynamicDelegate: Inherited.Delegate? {
        get { return inherited.dynamicDelegate }
        set { inherited.dynamicDelegate = newValue }
    }
}

/// Preparers usually construct the `Instance` from a subclass type except in specific cases where additional non-binding parameters are required for instance construction.
public protocol BinderConstructor: BinderApplyable {
    /// Constructs the `Instance`
    ///
    /// - Parameter subclass: subclass of the instance type to use for construction
    /// - Returns: the instance
    func constructInstance(type: Instance.Type, parameters: Parameters) -> Instance
}

public extension BinderConstructor where Instance: DefaultConstructable {
    func constructInstance(type: Instance.Type, parameters: Parameters) -> Instance {
        return type.init()
    }
}

/// All NSObject instances can use AssociatedBinderStorage which embeds lifetimes in the Objective-C associated object storage.
public protocol BinderEmbedder: BinderApplyable where Instance: NSObjectProtocol, Storage: AssociatedBinderStorage, Output == Instance {}
public extension BinderEmbedder {
    func combine(lifetimes: [Lifetime], instance: Instance, storage: Storage) -> Output {
        storage.embed(lifetimes: lifetimes, in: instance)
        return instance
    }
}

/// A `BinderEmbedderConstructor` is the standard configuration for a constructable NSObject.
public typealias BinderEmbedderConstructor = BinderEmbedder & BinderConstructor

public protocol DefaultConstructable {
    init()
}

/// A preparer interprets a set of bindings and applies them to an instance.
public protocol BinderPreparer: DefaultConstructable {
    associatedtype Instance
    associatedtype Output = Instance
    associatedtype Parameters = Void
    associatedtype Binding
    associatedtype Storage
    associatedtype Inherited: BinderPreparer
    
    var inherited: Inherited { get set }
    
    func inheritedBinding(from: Binding) -> Inherited.Binding?
    
    /// A first scan of the bindings. Information about bindings present may be recorded during this time.
    ///
    /// NOTE: you don't need to process all bindings at your own level but you should pass inherited bindings through
    /// to the inherited preparer (unless you're handling it at your own level)
    ///
    /// - Parameter binding: the binding to apply
    mutating func prepareBinding(_ binding: Binding)
    
    /// Bindings which need to be applied before others can be applied at this special early stage
    ///
    /// NOTE: the first step should be to call `inheritedPrepareInstance`. `BinderDelegate` should call `prepareDelegate`
    ///
    /// - Parameters:
    ///   - instance: the instance
    ///   - storage: the storage
    func prepareInstance(_ instance: Instance, storage: Storage)
    
    /// Apply typical bindings.
    ///
    /// NOTE: you should process all bindings and pass inherited bindings through to the inherited preparer
    ///
    /// - Parameters:
    ///   - binding: the binding to apply
    ///   - instance: the instance
    ///   - storage: the storage
    /// - Returns: If maintaining bindings requires ongoing lifetime management, these lifetimes are maintained by returning instances of `Lifetime`.
    func applyBinding(_ binding: Binding, instance: Instance, storage: Storage) -> Lifetime?
    
    /// Bindings which need to be applied after others can be applied at this last stage.
    ///
    /// NOTE: the last step should be to call `inheritedFinalizedInstance`
    ///
    /// - Parameters:
    ///   - instance: the instance
    ///   - storage: the storage
    /// - Returns: If maintaining bindings requires ongoing lifetime management, these lifetimes are maintained by returning instances of `Lifetime`
    func finalizeInstance(_ instance: Instance, storage: Storage) -> Lifetime?
}

public extension BinderPreparer {
    mutating func inheritedPrepareBinding(_ binding: Binding) {
        guard let ls = inheritedBinding(from: binding) else { return }
        inherited.prepareBinding(ls)
    }
    
    mutating func prepareBinding(_ binding: Binding) {
        inheritedPrepareBinding(binding)
    }
    
    func inheritedPrepareInstance(_ instance: Instance, storage: Storage) {
        guard let i = instance as? Inherited.Instance, let s = storage as? Inherited.Storage else { return }
        inherited.prepareInstance(i, storage: s)
    }
    
    func prepareInstance(_ instance: Instance, storage: Storage) {
        inheritedPrepareInstance(instance, storage: storage)
    }
    
    func inheritedApplyBinding(_ binding: Binding, instance: Instance, storage: Storage) -> Lifetime? {
        guard let ls = inheritedBinding(from: binding), let i = instance as? Inherited.Instance, let s = storage as? Inherited.Storage else { return nil }
        return inherited.applyBinding(ls, instance: i, storage: s)
    }
    
    func applyBinding(_ binding: Binding, instance: Instance, storage: Storage) -> Lifetime? {
        return inheritedApplyBinding(binding, instance: instance, storage: storage)
    }
    
    func inheritedFinalizedInstance(_ instance: Instance, storage: Storage) -> Lifetime? {
        guard let i = instance as? Inherited.Instance, let s = storage as? Inherited.Storage else { return nil }
        return inherited.finalizeInstance(i, storage: s)
    }
    
    func finalizeInstance(_ instance: Instance, storage: Storage) -> Lifetime? {
        return inheritedFinalizedInstance(instance, storage: storage)
    }
}


import Foundation

public protocol Binding {
    associatedtype Preparer: BinderPreparer
    func asInheritedBinding() -> Preparer.Inherited.Binding?
}

extension Binding {
    public typealias Name<V> = BindingName<V, Self, Self>
    
    public static func compositeName<Value, Param, Intermediate>(value: @escaping (Value) -> Param, binding: @escaping (Param) -> Intermediate, downcast: @escaping (Intermediate) -> Self) -> BindingName<Value, Intermediate, Self> {
        return BindingName<Value, Intermediate, Self>(
            source: { v in binding(value(v)) },
            downcast: downcast
        )
    }
    
    public static func keyPathActionName<Instance, Value, Intermediate>(_ keyPath: KeyPath<Instance, Value>, _ binding: @escaping (TargetAction) -> Intermediate, _ downcast: @escaping (Intermediate) -> Self) -> BindingName<SignalInput<Value>, Intermediate, Self> {
        return compositeName(
            value: { input in
                TargetAction.singleTarget(
                    Input<Any?>().map { v in (v as! Instance)[keyPath: keyPath] }.bind(to: input)
                )
        },
            binding: binding,
            downcast: downcast
        )
    }
    
    public static func mappedInputName<Value, Mapped, Intermediate>(map: @escaping (Value) -> Mapped, binding: @escaping (SignalInput<Value>) -> Intermediate, downcast: @escaping (Intermediate) -> Self) -> BindingName<SignalInput<Mapped>, Intermediate, Self> {
        return compositeName(
            value: { Input<Value>().map(map).bind(to: $0) },
            binding: binding,
            downcast: downcast
        )
    }
    
    public static func mappedWrappedInputName<Value, Mapped, Param, Intermediate>(map: @escaping (Value) -> Mapped, wrap: @escaping (SignalInput<Value>) -> Param, binding: @escaping (Param) -> Intermediate, downcast: @escaping (Intermediate) -> Self) -> BindingName<SignalInput<Mapped>, Intermediate, Self> {
        return compositeName(
            value: { wrap(Input<Value>().map(map).bind(to: $0)) },
            binding: binding,
            downcast: downcast
        )
    }
}


infix operator --: AssignmentPrecedence
infix operator <--: AssignmentPrecedence
infix operator -->: AssignmentPrecedence

public struct BindingName<Value, Source, Binding> {
    public var source: (Value) -> Source
    public var downcast: (Source) -> Binding
    public init(source: @escaping (Value) -> Source, downcast: @escaping (Source) -> Binding) {
        self.source = source
        self.downcast = downcast
    }
    public func binding(with value: Value) -> Binding {
        return downcast(source(value))
    }
}

public extension BindingName {
    /// Build a signal binding (invocations on the instance after construction) from a name and a signal
    ///
    /// - Parameters:
    ///   - name: the binding name
    ///   - value: the binding argument
    /// - Returns: the binding
    static func <--<Interface: SignalInterface>(name: BindingName<Value, Source, Binding>, value: Interface) -> Binding where Signal<Interface.OutputValue> == Value {
        return name.binding(with: value.signal)
    }
    
    /// Build a value binding (property changes on the instance) from a name and a signal (values over time)
    ///
    /// - Parameters:
    ///   - name: the binding name
    ///   - value: the binding argument
    /// - Returns: the binding
    static func <--<Interface: SignalInterface>(name: BindingName<Value, Source, Binding>, value: Interface) -> Binding where Dynamic<Interface.OutputValue> == Value {
        return name.binding(with: Dynamic<Interface.OutputValue>.dynamic(value.signal))
    }
    
    /// Build an action binding (callbacks triggered by the instance) from a name and a signal input.
    ///
    /// - Parameters:
    ///   - name: the binding name
    ///   - value: the binding argument
    /// - Returns: the binding
    static func --><InputInterface: SignalInputInterface>(name: BindingName<Value, Source, Binding>, value: InputInterface) -> Binding where SignalInput<InputInterface.InputValue> == Value {
        return name.binding(with: value.input)
    }
    
    /// Build a static binding (construction-only property) from a name and a constant value
    ///
    /// - Parameters:
    ///   - name: the binding name
    ///   - value: the binding argument
    /// - Returns: the binding
    static func --<A>(name: BindingName<Value, Source, Binding>, value: A) -> Binding where Constant<A> == Value {
        return name.binding(with: Value.constant(value))
    }
    
    /// Build a value binding (property changes on the instance) from a name and a constant value
    ///
    /// - Parameters:
    ///   - name: the binding name
    ///   - value: the binding argument
    /// - Returns: the binding
    static func --<A>(name: BindingName<Value, Source, Binding>, value: A) -> Binding where Dynamic<A> == Value {
        return name.binding(with: Dynamic<A>.constant(value))
    }
    
    /// Build a delegate binding (synchronous callback) from a name and function with no parameters
    ///
    /// - Parameters:
    ///   - name: the binding name
    ///   - value: the binding argument
    /// - Returns: the binding
    static func --<R>(name: BindingName<Value, Source, Binding>, value: @escaping () -> R) -> Binding where Value == () -> R {
        return name.binding(with: value)
    }
    
    /// Build a delegate binding (synchronous callback) from a name and function with one parameter
    ///
    /// - Parameters:
    ///   - name: the binding name
    ///   - value: the binding argument
    /// - Returns: the binding
    static func --<A, R>(name: BindingName<Value, Source, Binding>, value: @escaping (A) -> R) -> Binding where Value == (A) -> R {
        return name.binding(with: value)
    }
    
    /// Build a delegate binding (synchronous callback) from a name and function with two parameters
    ///
    /// - Parameters:
    ///   - name: the binding name
    ///   - value: the binding argument
    /// - Returns: the binding
    static func --<A, B, R>(name: BindingName<Value, Source, Binding>, value: @escaping (A, B) -> R) -> Binding where Value == (A, B) -> R {
        return name.binding(with: value)
    }
    
    /// Build a delegate binding (synchronous callback) from a name and function with three parameters
    ///
    /// - Parameters:
    ///   - name: the binding name
    ///   - value: the binding argument
    /// - Returns: the binding
    static func --<A, B, C, R>(name: BindingName<Value, Source, Binding>, value: @escaping (A, B, C) -> R) -> Binding where Value == (A, B, C) -> R {
        return name.binding(with: value)
    }
    
    /// Build a delegate binding (synchronous callback) from a name and function with four parameters
    ///
    /// - Parameters:
    ///   - name: the binding name
    ///   - value: the binding argument
    /// - Returns: the binding
    static func --<A, B, C, D, R>(name: BindingName<Value, Source, Binding>, value: @escaping (A, B, C, D) -> R) -> Binding where Value == (A, B, C, D) -> R {
        return name.binding(with: value)
    }
    
    /// Build a delegate binding (synchronous callback) from a name and function with five parameters
    ///
    /// - Parameters:
    ///   - name: the binding name
    ///   - value: the binding argument
    /// - Returns: the binding
    static func --<A, B, C, D, E, R>(name: BindingName<Value, Source, Binding>, value: @escaping (A, B, C, D, E) -> R) -> Binding where Value == (A, B, C, D, E) -> R {
        return name.binding(with: value)
    }
}

public extension BindingName where Value == TargetAction {
    /// Build an `TargetAction` binding (callbacks triggered by the instance) from a name and a signal input.
    ///
    /// - Parameters:
    ///   - name: the binding name
    ///   - value: the binding argument
    /// - Returns: the binding
    static func --><InputInterface: SignalInputInterface>(name: BindingName<TargetAction, Source, Binding>, value: InputInterface) -> Binding where InputInterface.InputValue == Any? {
        return name.binding(with: .singleTarget(value.input))
    }
    
    /// Build a first-responder `TargetAction` binding (callbacks triggered by the instance) from a name and a selector.
    ///
    /// - Parameters:
    ///   - name: the binding name
    ///   - value: the binding argument
    /// - Returns: the binding
    static func -->(name: BindingName<TargetAction, Source, Binding>, value: Selector) -> Binding {
        return name.binding(with: TargetAction.firstResponder(value))
    }
}
