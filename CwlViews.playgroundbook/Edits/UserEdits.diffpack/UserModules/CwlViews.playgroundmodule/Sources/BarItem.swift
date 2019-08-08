
import CwlSignals
import CwlCore
import CwlViewsCore
import CwlViewsUtilities
import UIKit

// MARK: - Binder Part 1: Binder
public class BarItem: Binder, BarItemConvertible {
    public var state: BinderState<Preparer>
    public required init(type: Preparer.Instance.Type, parameters: Preparer.Parameters, bindings: [Preparer.Binding]) {
        state = .pending(type: type, parameters: parameters, bindings: bindings)
    }
}

// MARK: - Binder Part 2: Binding
public extension BarItem {
    enum Binding: BarItemBinding {
        case inheritedBinding(Preparer.Inherited.Binding)
        
        //    0. Static bindings are applied at construction and are subsequently immutable.
        
        //    1. Value bindings may be applied at construction and may subsequently change.
        case image(Dynamic<UIImage?>)
        case imageInsets(Dynamic<UIEdgeInsets>)
        case isEnabled(Dynamic<Bool>)
        case landscapeImagePhone(Dynamic<UIImage?>)
        case landscapeImagePhoneInsets(Dynamic<UIEdgeInsets>)
        case tag(Dynamic<Int>)
        case title(Dynamic<String>)
        case titleTextAttributes(Dynamic<ScopedValues<UIControl.State, [NSAttributedString.Key: Any]>>)
        
        //    2. Signal bindings are performed on the object after construction.
        
        //    3. Action bindings are triggered by the object after construction.
        
        //    4. Delegate bindings require synchronous evaluation within the object's context.
    }
}

// MARK: - Binder Part 3: Preparer
public extension BarItem {
    struct Preparer: BinderEmbedderConstructor {
        public typealias Binding = BarItem.Binding
        public typealias Inherited = BinderBase
        public typealias Instance = UIBarItem
        
        public var inherited = Inherited()
        public init() {}
        public func constructStorage(instance: Instance) -> Storage { return Storage() }
        public func inheritedBinding(from: Binding) -> Inherited.Binding? {
            if case .inheritedBinding(let b) = from { return b } else { return nil }
        }
    }
}

// MARK: - Binder Part 4: Preparer overrides
public extension BarItem.Preparer {
    func applyBinding(_ binding: Binding, instance: Instance, storage: Storage) -> Lifetime? {
        switch binding {
        case .inheritedBinding(let x): return inherited.applyBinding(x, instance: instance, storage: storage)
            
            //    0. Static bindings are applied at construction and are subsequently immutable.
            
        //    1. Value bindings may be applied at construction and may subsequently change.
        case .image(let x): return x.apply(instance) { i, v in i.image = v }
        case .imageInsets(let x): return x.apply(instance) { i, v in i.imageInsets = v }
        case .isEnabled(let x): return x.apply(instance) { i, v in i.isEnabled = v }
        case .landscapeImagePhone(let x): return x.apply(instance) { i, v in i.landscapeImagePhone = v }
        case .landscapeImagePhoneInsets(let x): return x.apply(instance) { i, v in i.landscapeImagePhoneInsets = v }
        case .tag(let x): return x.apply(instance) { i, v in i.tag = v }
        case .title(let x): return x.apply(instance) { i, v in i.title = v }
        case .titleTextAttributes(let x):
            return x.apply(
                instance: instance,
                removeOld: { i, scope, v in i.setTitleTextAttributes([:], for: scope) },
                applyNew: { i, scope, v in i.setTitleTextAttributes(v, for: scope) }
            )
            
            //    2. Signal bindings are performed on the object after construction.
            
            //    3. Action bindings are triggered by the object after construction.
            
            //    4. Delegate bindings require synchronous evaluation within the object's context.
        }
    }
}

// MARK: - Binder Part 5: Storage and Delegate
extension BarItem.Preparer {
    public typealias Storage = AssociatedBinderStorage
}

// MARK: - Binder Part 6: BindingNames
extension BindingName where Binding: BarItemBinding {
    public typealias BarItemName<V> = BindingName<V, BarItem.Binding, Binding>
    private static func name<V>(_ source: @escaping (V) -> BarItem.Binding) -> BarItemName<V> {
        return BarItemName<V>(source: source, downcast: Binding.barItemBinding)
    }
}
public extension BindingName where Binding: BarItemBinding {
    // You can easily convert the `Binding` cases to `BindingName` using the following Xcode-style regex:
    // Replace: case ([^\(]+)\((.+)\)$
    // With:    static var $1: BarItemName<$2> { return .name(BarItem.Binding.$1) }
    
    //    0. Static bindings are applied at construction and are subsequently immutable.
    
    //    1. Value bindings may be applied at construction and may subsequently change.
    static var image: BarItemName<Dynamic<UIImage?>> { return .name(BarItem.Binding.image) }
    static var imageInsets: BarItemName<Dynamic<UIEdgeInsets>> { return .name(BarItem.Binding.imageInsets) }
    static var isEnabled: BarItemName<Dynamic<Bool>> { return .name(BarItem.Binding.isEnabled) }
    static var landscapeImagePhone: BarItemName<Dynamic<UIImage?>> { return .name(BarItem.Binding.landscapeImagePhone) }
    static var landscapeImagePhoneInsets: BarItemName<Dynamic<UIEdgeInsets>> { return .name(BarItem.Binding.landscapeImagePhoneInsets) }
    static var tag: BarItemName<Dynamic<Int>> { return .name(BarItem.Binding.tag) }
    static var title: BarItemName<Dynamic<String>> { return .name(BarItem.Binding.title) }
    static var titleTextAttributes: BarItemName<Dynamic<ScopedValues<UIControl.State, [NSAttributedString.Key: Any]>>> { return .name(BarItem.Binding.titleTextAttributes) }
    
    //    2. Signal bindings are performed on the object after construction.
    
    //    3. Action bindings are triggered by the object after construction.
    
    //    4. Delegate bindings require synchronous evaluation within the object's context.
}

// MARK: - Binder Part 7: Convertible protocols (if constructible)
public protocol BarItemConvertible {
    func uiBarItem() -> BarItem.Instance
}
extension UIBarItem: BarItemConvertible, DefaultConstructable {
    public func uiBarItem() -> BarItem.Instance { return self }
}
public extension BarItem {
    func uiBarItem() -> BarItem.Instance { return instance() }
}

// MARK: - Binder Part 8: Downcast protocols
public protocol BarItemBinding: BinderBaseBinding {
    static func barItemBinding(_ binding: BarItem.Binding) -> Self
    func asBarItemBinding() -> BarItem.Binding?
}
public extension BarItemBinding {
    static func binderBaseBinding(_ binding: BinderBase.Binding) -> Self {
        return barItemBinding(.inheritedBinding(binding))
    }
}
public extension BarItemBinding where Preparer.Inherited.Binding: BarItemBinding {
    func asBarItemBinding() -> BarItem.Binding? {
        return asInheritedBinding()?.asBarItemBinding()
    }
}
public extension BarItem.Binding {
    typealias Preparer = BarItem.Preparer
    func asInheritedBinding() -> Preparer.Inherited.Binding? { if case .inheritedBinding(let b) = self { return b } else { return nil } }
    func asBarItemBinding() -> BarItem.Binding? { return self }
    static func barItemBinding(_ binding: BarItem.Binding) -> BarItem.Binding {
        return binding
    }
}

// MARK: - Binder Part 1: Binder
public class BarButtonItem: Binder, BarButtonItemConvertible {
    public var state: BinderState<Preparer>
    public required init(type: Preparer.Instance.Type, parameters: Preparer.Parameters, bindings: [Preparer.Binding]) {
        state = .pending(type: type, parameters: parameters, bindings: bindings)
    }
}

// MARK: - Binder Part 2: Binding
public extension BarButtonItem {
    enum Binding: BarButtonItemBinding {
        case inheritedBinding(Preparer.Inherited.Binding)
        
        //    0. Static bindings are applied at construction and are subsequently immutable.
        case systemItem(Constant<UIBarButtonItem.SystemItem>)
        
        //    1. Value bindings may be applied at construction and may subsequently change.
        case backButtonBackgroundImage(Dynamic<ScopedValues<StateAndMetrics, UIImage?>>)
        case backButtonTitlePositionAdjustment(Dynamic<ScopedValues<UIBarMetrics, UIOffset>>)
        case backgroundImage(Dynamic<ScopedValues<StateStyleAndMetrics, UIImage?>>)
        case backgroundVerticalPositionAdjustment(Dynamic<ScopedValues<UIBarMetrics, CGFloat>>)
        case customView(Dynamic<ViewConvertible?>)
        case itemStyle(Dynamic<UIBarButtonItem.Style>)
        case possibleTitles(Dynamic<Set<String>?>)
        case tintColor(Dynamic<UIColor?>)
        case titlePositionAdjustment(Dynamic<ScopedValues<UIBarMetrics, UIOffset>>)
        case width(Dynamic<CGFloat>)
        
        //    2. Signal bindings are performed on the object after construction.
        
        //    3. Action bindings are triggered by the object after construction.
        case action(TargetAction)
        
        //    4. Delegate bindings require synchronous evaluation within the object's context.
    }
}

// MARK: - Binder Part 3: Preparer
public extension BarButtonItem {
    struct Preparer: BinderEmbedderConstructor {
        public typealias Binding = BarButtonItem.Binding
        public typealias Inherited = BarItem.Preparer
        public typealias Instance = UIBarButtonItem
        
        public var inherited = Inherited()
        public init() {}
        public func constructStorage(instance: Instance) -> Storage { return Storage() }
        public func inheritedBinding(from: Binding) -> Inherited.Binding? {
            if case .inheritedBinding(let b) = from { return b } else { return nil }
        }
        
        public var systemItem: UIBarButtonItem.SystemItem?
        public var customView = InitialSubsequent<ViewConvertible?>()
        public var itemStyle = InitialSubsequent<UIBarButtonItem.Style>()
        public var image = InitialSubsequent<UIImage?>()
        public var landscapeImagePhone = InitialSubsequent<UIImage?>()
        public var title = InitialSubsequent<String>()
    }
}

// MARK: - Binder Part 4: Preparer overrides
public extension BarButtonItem.Preparer {
    func constructInstance(type: Instance.Type, parameters: Parameters) -> Instance {
        let x: UIBarButtonItem
        if let si = systemItem {
            x = type.init(barButtonSystemItem: si, target: nil, action: nil)
        } else if case .some(.some(let cv)) = customView.initial {
            x = type.init(customView: cv.uiView())
        } else if case .some(.some(let i)) = image.initial {
            x = type.init(image: i, landscapeImagePhone: landscapeImagePhone.initial ?? nil, style: itemStyle.initial ?? .plain, target: nil, action: nil)
        } else {
            x = type.init(title: title.initial ?? nil, style: itemStyle.initial ?? .plain, target: nil, action: nil)
        }
        return x
    }
    
    mutating func prepareBinding(_ binding: Binding) {
        switch binding {
        case .inheritedBinding(.image(let x)): image = x.initialSubsequent()
        case .inheritedBinding(.landscapeImagePhone(let x)): landscapeImagePhone = x.initialSubsequent()
        case .inheritedBinding(.title(let x)): title = x.initialSubsequent()
        case .inheritedBinding(let x): inherited.prepareBinding(x)
            
        case .systemItem(let x): systemItem = x.value
        case .customView(let x): customView = x.initialSubsequent()
        case .itemStyle(let x): itemStyle = x.initialSubsequent()
        default: break
        }
    }
    
    func applyBinding(_ binding: Binding, instance: Instance, storage: Storage) -> Lifetime? {
        switch binding {
        case .inheritedBinding(.image): return image.apply(instance) { i, v in i.image = v }
        case .inheritedBinding(.landscapeImagePhone): return landscapeImagePhone.apply(instance) { i, v in i.landscapeImagePhone = v }
        case .inheritedBinding(.title): return title.apply(instance) { i, v in i.title = v }
        case .inheritedBinding(let x): return inherited.applyBinding(x, instance: instance, storage: storage)
            
        //    0. Static bindings are applied at construction and are subsequently immutable.
        case .systemItem: return nil
            
        //    1. Value bindings may be applied at construction and may subsequently change.
        case .backButtonBackgroundImage(let x):
            return x.apply(
                instance: instance,
                removeOld: { i, scope, v in i.setBackButtonBackgroundImage(nil, for: scope.controlState, barMetrics: scope.barMetrics) },
                applyNew: { i, scope, v in i.setBackButtonBackgroundImage(v, for: scope.controlState, barMetrics: scope.barMetrics) }
            )
        case .backButtonTitlePositionAdjustment(let x):
            return x.apply(
                instance: instance,
                removeOld: { i, scope, v in i.setBackButtonTitlePositionAdjustment(UIOffset(), for: scope) },
                applyNew: { i, scope, v in i.setBackButtonTitlePositionAdjustment(v, for: scope) }
            )
        case .backgroundImage(let x):
            return x.apply(
                instance: instance,
                removeOld: { i, scope, v in i.setBackgroundImage(nil, for: scope.controlState, style: scope.itemStyle, barMetrics: scope.barMetrics) },
                applyNew: { i, scope, v in i.setBackgroundImage(v, for: scope.controlState, style: scope.itemStyle, barMetrics: scope.barMetrics) }
            )
        case .backgroundVerticalPositionAdjustment(let x):
            return x.apply(
                instance: instance,
                removeOld: { i, scope, v in i.setBackgroundVerticalPositionAdjustment(0, for: scope) },
                applyNew: { i, scope, v in i.setBackgroundVerticalPositionAdjustment(v, for: scope) }
            )
        case .customView: return customView.apply(instance) { i, v in i.customView = v?.uiView() }
        case .itemStyle: return itemStyle.apply(instance) { i, v in i.style = v }
        case .possibleTitles(let x): return x.apply(instance) { i, v in i.possibleTitles = v }
        case .tintColor(let x): return x.apply(instance) { i, v in i.tintColor = v }
        case .titlePositionAdjustment(let x):
            return x.apply(
                instance: instance,
                removeOld: { i, scope, v in i.setTitlePositionAdjustment(UIOffset(), for: scope) },
                applyNew: { i, scope, v in i.setTitlePositionAdjustment(v, for: scope) }
            )
        case .width(let x): return x.apply(instance) { i, v in i.width = v }
            
            //    2. Signal bindings are performed on the object after construction.
            
        //    3. Action bindings are triggered by the object after construction.
        case .action(let x): return x.apply(to: instance, constructTarget: SignalActionTarget.init)
            
            //    4. Delegate bindings require synchronous evaluation within the object's context.
        }
    }
}

// MARK: - Binder Part 5: Storage and Delegate
extension BarButtonItem.Preparer {
    public typealias Storage = BarItem.Preparer.Storage
}

// MARK: - Binder Part 6: BindingNames
extension BindingName where Binding: BarButtonItemBinding {
    public typealias BarButtonItemName<V> = BindingName<V, BarButtonItem.Binding, Binding>
    private static func name<V>(_ source: @escaping (V) -> BarButtonItem.Binding) -> BarButtonItemName<V> {
        return BarButtonItemName<V>(source: source, downcast: Binding.barButtonItemBinding)
    }
}
public extension BindingName where Binding: BarButtonItemBinding {
    // You can easily convert the `Binding` cases to `BindingName` using the following Xcode-style regex:
    // Replace: case ([^\(]+)\((.+)\)$
    // With:    static var $1: BarButtonItemName<$2> { return .name(BarButtonItem.Binding.$1) }
    
    //    0. Static bindings are applied at construction and are subsequently immutable.
    static var systemItem: BarButtonItemName<Constant<UIBarButtonItem.SystemItem>> { return .name(BarButtonItem.Binding.systemItem) }
    
    //    1. Value bindings may be applied at construction and may subsequently change.
    static var backButtonBackgroundImage: BarButtonItemName<Dynamic<ScopedValues<StateAndMetrics, UIImage?>>> { return .name(BarButtonItem.Binding.backButtonBackgroundImage) }
    static var backButtonTitlePositionAdjustment: BarButtonItemName<Dynamic<ScopedValues<UIBarMetrics, UIOffset>>> { return .name(BarButtonItem.Binding.backButtonTitlePositionAdjustment) }
    static var backgroundImage: BarButtonItemName<Dynamic<ScopedValues<StateStyleAndMetrics, UIImage?>>> { return .name(BarButtonItem.Binding.backgroundImage) }
    static var backgroundVerticalPositionAdjustment: BarButtonItemName<Dynamic<ScopedValues<UIBarMetrics, CGFloat>>> { return .name(BarButtonItem.Binding.backgroundVerticalPositionAdjustment) }
    static var customView: BarButtonItemName<Dynamic<ViewConvertible?>> { return .name(BarButtonItem.Binding.customView) }
    static var itemStyle: BarButtonItemName<Dynamic<UIBarButtonItem.Style>> { return .name(BarButtonItem.Binding.itemStyle) }
    static var possibleTitles: BarButtonItemName<Dynamic<Set<String>?>> { return .name(BarButtonItem.Binding.possibleTitles) }
    static var tintColor: BarButtonItemName<Dynamic<UIColor?>> { return .name(BarButtonItem.Binding.tintColor) }
    static var titlePositionAdjustment: BarButtonItemName<Dynamic<ScopedValues<UIBarMetrics, UIOffset>>> { return .name(BarButtonItem.Binding.titlePositionAdjustment) }
    static var width: BarButtonItemName<Dynamic<CGFloat>> { return .name(BarButtonItem.Binding.width) }
    
    //    2. Signal bindings are performed on the object after construction.
    
    //    3. Action bindings are triggered by the object after construction.
    static var action: BarButtonItemName<TargetAction> { return .name(BarButtonItem.Binding.action) }
    
    //    4. Delegate bindings require synchronous evaluation within the object's context.
    
    // Composite binding names
    static func action<Value>(_ keyPath: KeyPath<Binding.Preparer.Instance, Value>) -> BarButtonItemName<SignalInput<Value>> {
        return Binding.keyPathActionName(keyPath, BarButtonItem.Binding.action, Binding.barButtonItemBinding)
    }
}

// MARK: - Binder Part 7: Convertible protocols (if constructible)
public protocol BarButtonItemConvertible: BarItemConvertible {
    func uiBarButtonItem() -> BarButtonItem.Instance
}
extension BarButtonItemConvertible {
    public func uiBarItem() -> BarItem.Instance { return uiBarButtonItem() }
}
extension UIBarButtonItem: BarButtonItemConvertible, TargetActionSender {
    public func uiBarButtonItem() -> BarButtonItem.Instance { return self }
}
public extension BarButtonItem {
    func uiBarButtonItem() -> BarButtonItem.Instance { return instance() }
}

// MARK: - Binder Part 8: Downcast protocols
public protocol BarButtonItemBinding: BarItemBinding {
    static func barButtonItemBinding(_ binding: BarButtonItem.Binding) -> Self
    func asBarButtonItemBinding() -> BarButtonItem.Binding?
}
public extension BarButtonItemBinding {
    static func barItemBinding(_ binding: BarItem.Binding) -> Self {
        return barButtonItemBinding(.inheritedBinding(binding))
    }
}
public extension BarButtonItemBinding where Preparer.Inherited.Binding: BarButtonItemBinding {
    func asBarButtonItemBinding() -> BarButtonItem.Binding? {
        return asInheritedBinding()?.asBarButtonItemBinding()
    }
}
public extension BarButtonItem.Binding {
    typealias Preparer = BarButtonItem.Preparer
    func asInheritedBinding() -> Preparer.Inherited.Binding? { if case .inheritedBinding(let b) = self { return b } else { return nil } }
    func asBarButtonItemBinding() -> BarButtonItem.Binding? { return self }
    static func barButtonItemBinding(_ binding: BarButtonItem.Binding) -> BarButtonItem.Binding {
        return binding
    }
}

// MARK: - Binder Part 9: Other supporting types
public struct StateStyleAndMetrics {
    public let controlState: UIControl.State
    public let itemStyle: UIBarButtonItem.Style
    public let barMetrics: UIBarMetrics
    public init(state: UIControl.State = .normal, style: UIBarButtonItem.Style = .plain, metrics: UIBarMetrics = .default) {
        self.controlState = state
        self.itemStyle = style
        self.barMetrics = metrics
    }
}

public struct StateAndMetrics {
    public let controlState: UIControl.State
    public let barMetrics: UIBarMetrics
    public init(state: UIControl.State = .normal, metrics: UIBarMetrics = .default) {
        self.controlState = state
        self.barMetrics = metrics
    }
}

extension ScopedValues where Scope == StateAndMetrics {
    public static func normal(metrics: UIBarMetrics = .default, _ value: Value) -> ScopedValues<Scope, Value> {
        return .value(value, for: StateAndMetrics(state: .normal, metrics: metrics))
    }
    public static func highlighted(metrics: UIBarMetrics = .default, _ value: Value) -> ScopedValues<Scope, Value> {
        return .value(value, for: StateAndMetrics(state: .highlighted, metrics: metrics))
    }
    public static func disabled(metrics: UIBarMetrics = .default, _ value: Value) -> ScopedValues<Scope, Value> {
        return .value(value, for: StateAndMetrics(state: .disabled, metrics: metrics))
    }
    public static func selected(metrics: UIBarMetrics = .default, _ value: Value) -> ScopedValues<Scope, Value> {
        return .value(value, for: StateAndMetrics(state: .selected, metrics: metrics))
    }
    public static func focused(metrics: UIBarMetrics = .default, _ value: Value) -> ScopedValues<Scope, Value> {
        return .value(value, for: StateAndMetrics(state: .focused, metrics: metrics))
    }
    public static func application(metrics: UIBarMetrics = .default, _ value: Value) -> ScopedValues<Scope, Value> {
        return .value(value, for: StateAndMetrics(state: .application, metrics: metrics))
    }
    public static func reserved(metrics: UIBarMetrics = .default, _ value: Value) -> ScopedValues<Scope, Value> {
        return .value(value, for: StateAndMetrics(state: .reserved, metrics: metrics))
    }
}

extension ScopedValues where Scope == StateStyleAndMetrics {
    public static func normal(style: UIBarButtonItem.Style = .plain, metrics: UIBarMetrics = .default, _ value: Value) -> ScopedValues<Scope, Value> {
        return .value(value, for: StateStyleAndMetrics(state: .normal, metrics: metrics))
    }
    public static func highlighted(style: UIBarButtonItem.Style = .plain, metrics: UIBarMetrics = .default, _ value: Value) -> ScopedValues<Scope, Value> {
        return .value(value, for: StateStyleAndMetrics(state: .highlighted, metrics: metrics))
    }
    public static func disabled(style: UIBarButtonItem.Style = .plain, metrics: UIBarMetrics = .default, _ value: Value) -> ScopedValues<Scope, Value> {
        return .value(value, for: StateStyleAndMetrics(state: .disabled, metrics: metrics))
    }
    public static func selected(style: UIBarButtonItem.Style = .plain, metrics: UIBarMetrics = .default, _ value: Value) -> ScopedValues<Scope, Value> {
        return .value(value, for: StateStyleAndMetrics(state: .selected, metrics: metrics))
    }
    public static func focused(style: UIBarButtonItem.Style = .plain, metrics: UIBarMetrics = .default, _ value: Value) -> ScopedValues<Scope, Value> {
        return .value(value, for: StateStyleAndMetrics(state: .focused, metrics: metrics))
    }
    public static func application(style: UIBarButtonItem.Style = .plain, metrics: UIBarMetrics = .default, _ value: Value) -> ScopedValues<Scope, Value> {
        return .value(value, for: StateStyleAndMetrics(state: .application, metrics: metrics))
    }
    public static func reserved(style: UIBarButtonItem.Style = .plain, metrics: UIBarMetrics = .default, _ value: Value) -> ScopedValues<Scope, Value> {
        return .value(value, for: StateStyleAndMetrics(state: .reserved, metrics: metrics))
    }
}

extension ScopedValues where Scope == UIBarMetrics {
    public static func `default`(_ value: Value) -> ScopedValues<Scope, Value> {
        return ScopedValues<Scope, Value>(scope: .default, value: value)
    }
    public static func compact(_ value: Value) -> ScopedValues<Scope, Value> {
        return ScopedValues<Scope, Value>(scope: .compact, value: value)
    }
    public static func defaultPrompt(_ value: Value) -> ScopedValues<Scope, Value> {
        return ScopedValues<Scope, Value>(scope: .defaultPrompt, value: value)
    }
    public static func compactPrompt(_ value: Value) -> ScopedValues<Scope, Value> {
        return ScopedValues<Scope, Value>(scope: .compactPrompt, value: value)
    }
}

// MARK: - Binder Part 1: Binder
public class TabBarItem: Binder, TabBarItemConvertible {
    public var state: BinderState<Preparer>
    public required init(type: Preparer.Instance.Type, parameters: Preparer.Parameters, bindings: [Preparer.Binding]) {
        state = .pending(type: type, parameters: parameters, bindings: bindings)
    }
}

// MARK: - Binder Part 2: Binding
public extension TabBarItem {
    enum Binding: TabBarItemBinding {
        case inheritedBinding(Preparer.Inherited.Binding)
        
        //    0. Static bindings are applied at construction and are subsequently immutable.
        case systemItem(Constant<UITabBarItem.SystemItem?>)
        
        //    1. Value bindings may be applied at construction and may subsequently change.
        case badgeColor(Dynamic<UIColor?>)
        case badgeTextAttributes(Dynamic<ScopedValues<UIControl.State, [NSAttributedString.Key : Any]?>>)
        case badgeValue(Dynamic<String?>)
        case selectedImage(Dynamic<UIImage?>)
        case titlePositionAdjustment(Dynamic<UIOffset>)
        
        //    2. Signal bindings are performed on the object after construction.
        
        //    3. Action bindings are triggered by the object after construction.
        
        //    4. Delegate bindings require synchronous evaluation within the object's context.
    }
}

// MARK: - Binder Part 3: Preparer
public extension TabBarItem {
    struct Preparer: BinderEmbedderConstructor {
        public typealias Binding = TabBarItem.Binding
        public typealias Inherited = BarItem.Preparer
        public typealias Instance = UITabBarItem
        
        public var inherited = Inherited()
        public init() {}
        public func constructStorage(instance: Instance) -> Storage { return Storage() }
        public func inheritedBinding(from: Binding) -> Inherited.Binding? {
            if case .inheritedBinding(let b) = from { return b } else { return nil }
        }
        
        public var systemItem: UITabBarItem.SystemItem?
        public var title = InitialSubsequent<String>()
        public var image = InitialSubsequent<UIImage?>()
        public var selectedImage = InitialSubsequent<UIImage?>()
        public var tag = InitialSubsequent<Int>()
    }
}

// MARK: - Binder Part 4: Preparer overrides
public extension TabBarItem.Preparer {
    func constructInstance(type: Instance.Type, parameters: Parameters) -> Instance {
        let x: UITabBarItem
        if let si = systemItem {
            x = type.init(tabBarSystemItem: si, tag: tag.initial ?? 0)
        } else if let si = selectedImage.initial {
            x = type.init(title: title.initial ?? nil, image: image.initial ?? nil, selectedImage: si)
        } else {
            x = type.init(title: title.initial ?? nil, image: image.initial ?? nil, tag: tag.initial ?? 0)
        }
        return x
    }
    
    mutating func prepareBinding(_ binding: Binding) {
        switch binding {
        case .inheritedBinding(.image(let x)): image = x.initialSubsequent()
        case .inheritedBinding(.tag(let x)): tag = x.initialSubsequent()
        case .inheritedBinding(.title(let x)): title = x.initialSubsequent()
        case .inheritedBinding(let x): inherited.prepareBinding(x)
            
        case .selectedImage(let x): selectedImage = x.initialSubsequent()
        case .systemItem(let x): systemItem = x.value
        default: break
        }
    }
    
    func applyBinding(_ binding: Binding, instance: Instance, storage: Storage) -> Lifetime? {
        switch binding {
        case .inheritedBinding(.tag): return tag.resume()?.apply(instance) { i, v in i.tag = v }
        case .inheritedBinding(.image): return image.resume()?.apply(instance) { i, v in i.image = v }
        case .inheritedBinding(.title): return title.resume()?.apply(instance) { i, v in i.title = v }
        case .inheritedBinding(let x): return inherited.applyBinding(x, instance: instance, storage: storage)
            
        case .systemItem: return nil
            
        case .badgeValue(let x): return x.apply(instance) { i, v in i.badgeValue = v }
        case .selectedImage: return selectedImage.resume()?.apply(instance) { i, v in i.selectedImage = v }
        case .titlePositionAdjustment(let x): return x.apply(instance) { i, v in i.titlePositionAdjustment = v }
            
        case .badgeColor(let x): return x.apply(instance) { i, v in i.badgeColor = v }
        case .badgeTextAttributes(let x):
            return x.apply(
                instance: instance,
                removeOld: { i, scope, v in i.setBadgeTextAttributes(nil, for: scope) },
                applyNew: { i, scope, v in i.setBadgeTextAttributes(v, for: scope) }
            )
        }
    }
}

// MARK: - Binder Part 5: Storage and Delegate
extension TabBarItem.Preparer {
    public typealias Storage = BarItem.Preparer.Storage
}

// MARK: - Binder Part 6: BindingNames
extension BindingName where Binding: TabBarItemBinding {
    public typealias TabBarItemName<V> = BindingName<V, TabBarItem.Binding, Binding>
    private static func name<V>(_ source: @escaping (V) -> TabBarItem.Binding) -> TabBarItemName<V> {
        return TabBarItemName<V>(source: source, downcast: Binding.tabBarItemBinding)
    }
}
public extension BindingName where Binding: TabBarItemBinding {
    // You can easily convert the `Binding` cases to `BindingName` using the following Xcode-style regex:
    // Replace: case ([^\(]+)\((.+)\)$
    // With:    static var $1: TabBarItemName<$2> { return .name(TabBarItem.Binding.$1) }
}

// MARK: - Binder Part 7: Convertible protocols (if constructible)
public protocol TabBarItemConvertible: BarItemConvertible {
    func uiTabBarItem() -> TabBarItem.Instance
}
extension TabBarItemConvertible {
    public func uiBarItem() -> BarItem.Instance { return uiTabBarItem() }
}
extension UITabBarItem: TabBarItemConvertible {
    public func uiTabBarItem() -> TabBarItem.Instance { return self }
}
public extension TabBarItem {
    func uiTabBarItem() -> TabBarItem.Instance { return instance() }
}

// MARK: - Binder Part 8: Downcast protocols
public protocol TabBarItemBinding: BarItemBinding {
    static func tabBarItemBinding(_ binding: TabBarItem.Binding) -> Self
    func asTabBarItemBinding() -> TabBarItem.Binding?
}
public extension TabBarItemBinding {
    static func barItemBinding(_ binding: BarItem.Binding) -> Self {
        return tabBarItemBinding(.inheritedBinding(binding))
    }
}
public extension TabBarItemBinding where Preparer.Inherited.Binding: TabBarItemBinding {
    func asTabBarItemBinding() -> TabBarItem.Binding? {
        return asInheritedBinding()?.asTabBarItemBinding()
    }
}
public extension TabBarItem.Binding {
    typealias Preparer = TabBarItem.Preparer
    func asInheritedBinding() -> Preparer.Inherited.Binding? { if case .inheritedBinding(let b) = self { return b } else { return nil } }
    func asTabBarItemBinding() -> TabBarItem.Binding? { return self }
    static func tabBarItemBinding(_ binding: TabBarItem.Binding) -> TabBarItem.Binding {
        return binding
    }
}
