
import CwlSignals
import CwlCore
import CwlViewsCore
import CwlViewsUtilities
import UIKit



// MARK: - Binder Part 1: Binder
public class Slider: Binder, SliderConvertible {
    public var state: BinderState<Preparer>
    public required init(type: Preparer.Instance.Type, parameters: Preparer.Parameters, bindings: [Preparer.Binding]) {
        state = .pending(type: type, parameters: parameters, bindings: bindings)
    }
}

// MARK: - Binder Part 2: Binding
public extension Slider {
    enum Binding: SliderBinding {
        case inheritedBinding(Preparer.Inherited.Binding)
        
        //    0. Static bindings are applied at construction and are subsequently immutable.
        
        // 1. Value bindings may be applied at construction and may subsequently change.
        case isContinuous(Dynamic<Bool>)
        case maximumTrackImage(Dynamic<ScopedValues<UIControl.State, UIImage?>>)
        case maximumTrackTintColor(Dynamic<UIColor?>)
        case maximumValue(Dynamic<Float>)
        case maximumValueImage(Dynamic<UIImage?>)
        case minimumTrackImage(Dynamic<ScopedValues<UIControl.State, UIImage?>>)
        case minimumTrackTintColor(Dynamic<UIColor?>)
        case minimumValue(Dynamic<Float>)
        case minimumValueImage(Dynamic<UIImage?>)
        case thumbImage(Dynamic<ScopedValues<UIControl.State, UIImage?>>)
        case thumbTintColor(Dynamic<UIColor?>)
        case value(Dynamic<SetOrAnimate<Float>>)
        
        // 2. Signal bindings are performed on the object after construction.
        
        //    3. Action bindings are triggered by the object after construction.
        
        // 4. Delegate bindings require synchronous evaluation within the object's context.
    }
}

// MARK: - Binder Part 3: Preparer
public extension Slider {
    struct Preparer: BinderEmbedderConstructor {
        public typealias Binding = Slider.Binding
        public typealias Inherited = Control.Preparer
        public typealias Instance = UISlider
        
        public var inherited = Inherited()
        public init() {}
        public func constructStorage(instance: Instance) -> Storage { return Storage() }
        public func inheritedBinding(from: Binding) -> Inherited.Binding? {
            if case .inheritedBinding(let b) = from { return b } else { return nil }
        }
    }
}

// MARK: - Binder Part 4: Preparer overrides
public extension Slider.Preparer {
    func applyBinding(_ binding: Binding, instance: Instance, storage: Storage) -> Lifetime? {
        switch binding {
        case .inheritedBinding(let x): return inherited.applyBinding(x, instance: instance, storage: storage)
        case .isContinuous(let x): return x.apply(instance) { i, v in i.isContinuous = v }
        case .maximumTrackImage(let x):
            return x.apply(
                instance: instance,
                removeOld: { i, scope, v in i.setMaximumTrackImage(nil, for: scope) },
                applyNew: { i, scope, v in i.setMaximumTrackImage(v, for: scope) }
            )
        case .maximumTrackTintColor(let x): return x.apply(instance) { i, v in i.maximumTrackTintColor = v }
        case .maximumValue(let x): return x.apply(instance) { i, v in i.maximumValue = v }
        case .maximumValueImage(let x): return x.apply(instance) { i, v in i.maximumValueImage = v }
        case .minimumTrackImage(let x):
            return x.apply(
                instance: instance,
                removeOld: { i, scope, v in i.setMinimumTrackImage(nil, for: scope) },
                applyNew: { i, scope, v in i.setMinimumTrackImage(v, for: scope) }
            )
        case .minimumTrackTintColor(let x): return x.apply(instance) { i, v in i.minimumTrackTintColor = v }
        case .minimumValue(let x): return x.apply(instance) { i, v in i.minimumValue = v }
        case .minimumValueImage(let x): return x.apply(instance) { i, v in i.minimumValueImage = v }
        case .thumbImage(let x):
            return x.apply(
                instance: instance,
                removeOld: { i, scope, v in i.setThumbImage(nil, for: scope) },
                applyNew: { i, scope, v in i.setThumbImage(v, for: scope) }
            )
        case .thumbTintColor(let x): return x.apply(instance) { i, v in i.thumbTintColor = v }
        case .value(let x): return x.apply(instance) { i, v in i.setValue(v.value, animated: v.isAnimated) }
        }
    }
}

// MARK: - Binder Part 5: Storage and Delegate
extension Slider.Preparer {
    public typealias Storage = Control.Preparer.Storage
}

// MARK: - Binder Part 6: BindingNames
extension BindingName where Binding: SliderBinding {
    public typealias SliderName<V> = BindingName<V, Slider.Binding, Binding>
    private static func name<V>(_ source: @escaping (V) -> Slider.Binding) -> SliderName<V> {
        return SliderName<V>(source: source, downcast: Binding.sliderBinding)
    }
}
public extension BindingName where Binding: SliderBinding {
    // You can easily convert the `Binding` cases to `BindingName` using the following Xcode-style regex:
    // Replace: case ([^\(]+)\((.+)\)$
    // With:    static var $1: SliderName<$2> { return .name(Slider.Binding.$1) }
    
    //    0. Static bindings are applied at construction and are subsequently immutable.
    
    // 1. Value bindings may be applied at construction and may subsequently change.
    static var isContinuous: SliderName<Dynamic<Bool>> { return .name(Slider.Binding.isContinuous) }
    static var maximumTrackImage: SliderName<Dynamic<ScopedValues<UIControl.State, UIImage?>>> { return .name(Slider.Binding.maximumTrackImage) }
    static var maximumTrackTintColor: SliderName<Dynamic<UIColor?>> { return .name(Slider.Binding.maximumTrackTintColor) }
    static var maximumValue: SliderName<Dynamic<Float>> { return .name(Slider.Binding.maximumValue) }
    static var maximumValueImage: SliderName<Dynamic<UIImage?>> { return .name(Slider.Binding.maximumValueImage) }
    static var minimumTrackImage: SliderName<Dynamic<ScopedValues<UIControl.State, UIImage?>>> { return .name(Slider.Binding.minimumTrackImage) }
    static var minimumTrackTintColor: SliderName<Dynamic<UIColor?>> { return .name(Slider.Binding.minimumTrackTintColor) }
    static var minimumValue: SliderName<Dynamic<Float>> { return .name(Slider.Binding.minimumValue) }
    static var minimumValueImage: SliderName<Dynamic<UIImage?>> { return .name(Slider.Binding.minimumValueImage) }
    static var thumbImage: SliderName<Dynamic<ScopedValues<UIControl.State, UIImage?>>> { return .name(Slider.Binding.thumbImage) }
    static var thumbTintColor: SliderName<Dynamic<UIColor?>> { return .name(Slider.Binding.thumbTintColor) }
    static var value: SliderName<Dynamic<SetOrAnimate<Float>>> { return .name(Slider.Binding.value) }
    
    // 2. Signal bindings are performed on the object after construction.
    
    //    3. Action bindings are triggered by the object after construction.
    
    // 4. Delegate bindings require synchronous evaluation within the object's context.
}

// MARK: - Binder Part 7: Convertible protocols (if constructible)
public protocol SliderConvertible: ControlConvertible {
    func uiSlider() -> Slider.Instance
}
extension SliderConvertible {
    public func uiControl() -> Control.Instance { return uiSlider() }
}
extension UISlider: SliderConvertible {
    public func uiSlider() -> Slider.Instance { return self }
}
public extension Slider {
    func uiSlider() -> Slider.Instance { return instance() }
}

// MARK: - Binder Part 8: Downcast protocols
public protocol SliderBinding: ControlBinding {
    static func sliderBinding(_ binding: Slider.Binding) -> Self
    func asSliderBinding() -> Slider.Binding?
}
public extension SliderBinding {
    static func controlBinding(_ binding: Control.Binding) -> Self {
        return sliderBinding(.inheritedBinding(binding))
    }
}
public extension SliderBinding where Preparer.Inherited.Binding: SliderBinding {
    func asSliderBinding() -> Slider.Binding? {
        return asInheritedBinding()?.asSliderBinding()
    }
}
public extension Slider.Binding {
    typealias Preparer = Slider.Preparer
    func asInheritedBinding() -> Preparer.Inherited.Binding? { if case .inheritedBinding(let b) = self { return b } else { return nil } }
    func asSliderBinding() -> Slider.Binding? { return self }
    static func sliderBinding(_ binding: Slider.Binding) -> Slider.Binding {
        return binding
    }
}

// MARK: - Binder Part 9: Other supporting types
