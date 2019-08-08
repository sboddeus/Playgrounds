
import CwlSignals
import CwlCore
import CwlViewsCore
import CwlViewsUtilities
import UIKit

// MARK: - Binder Part 1: Binder
public class Layer: Binder, LayerConvertible {
    public var state: BinderState<Preparer>
    public required init(type: Preparer.Instance.Type, parameters: Preparer.Parameters, bindings: [Preparer.Binding]) {
        state = .pending(type: type, parameters: parameters, bindings: bindings)
    }
}

// MARK: - Binder Part 2: Binding
public extension Layer {
    enum Binding: LayerBinding {
        case inheritedBinding(Preparer.Inherited.Binding)
        
        //    0. Static bindings are applied at construction and are subsequently immutable.
        
        //    1. Value bindings may be applied at construction and may subsequently change.
        case actions(Dynamic<[String: SignalInput<[AnyHashable: Any]?>?]>)
        case affineTransform(Dynamic<CGAffineTransform>)
        case anchorPoint(Dynamic<CGPoint>)
        case anchorPointZ(Dynamic<CGFloat>)
        case backgroundColor(Dynamic<CGColor>)
        case borderColor(Dynamic<CGColor>)
        case borderWidth(Dynamic<CGFloat>)
        case bounds(Dynamic<CGRect>)
        case contents(Dynamic<Any?>)
        case contentsCenter(Dynamic<CGRect>)
        case contentsGravity(Dynamic<CALayerContentsGravity>)
        case contentsRect(Dynamic<CGRect>)
        case contentsScale(Dynamic<CGFloat>)
        case cornerRadius(Dynamic<CGFloat>)
        case drawsAsynchronously(Dynamic<Bool>)
        case edgeAntialiasingMask(Dynamic<CAEdgeAntialiasingMask>)
        case frame(Dynamic<CGRect>)
        case isDoubleSided(Dynamic<Bool>)
        case isGeometryFlipped(Dynamic<Bool>)
        case isHidden(Dynamic<Bool>)
        case isOpaque(Dynamic<Bool>)
        case magnificationFilter(Dynamic<CALayerContentsFilter>)
        case mask(Dynamic<LayerConvertible?>)
        case masksToBounds(Dynamic<Bool>)
        case minificationFilter(Dynamic<CALayerContentsFilter>)
        case minificationFilterBias(Dynamic<Float>)
        case name(Dynamic<String>)
        case needsDisplayOnBoundsChange(Dynamic<Bool>)
        case opacity(Dynamic<Float>)
        case position(Dynamic<CGPoint>)
        case rasterizationScale(Dynamic<CGFloat>)
        case shadowColor(Dynamic<CGColor?>)
        case shadowOffset(Dynamic<CGSize>)
        case shadowOpacity(Dynamic<Float>)
        case shadowPath(Dynamic<CGPath?>)
        case shadowRadius(Dynamic<CGFloat>)
        case shouldRasterize(Dynamic<Bool>)
        case style(Dynamic<[AnyHashable: Any]>)
        case sublayers(Dynamic<[LayerConvertible]>)
        case sublayerTransform(Dynamic<CATransform3D>)
        case transform(Dynamic<CATransform3D>)
        case zPosition(Dynamic<CGFloat>)
        
        @available(macOS 10.13, *) @available(iOS, unavailable) case autoresizingMask(Dynamic<CAAutoresizingMask>)
        @available(macOS 10.13, *) @available(iOS, unavailable) case backgroundFilters(Dynamic<[CIFilter]?>)
        @available(macOS 10.13, *) @available(iOS, unavailable) case compositingFilter(Dynamic<CIFilter?>)
        @available(macOS 10.13, *) @available(iOS, unavailable) case constraints(Dynamic<[CAConstraint]>)
        @available(macOS 10.13, *) @available(iOS, unavailable) case filters(Dynamic<[CIFilter]?>)
        
        //    2. Signal bindings are performed on the object after construction.
        case addAnimation(Signal<AnimationForKey>)
        case needsDisplay(Signal<Void>)
        case needsDisplayInRect(Signal<CGRect>)
        case removeAllAnimations(Signal<Void>)
        case removeAnimationForKey(Signal<String>)
        case scrollRectToVisible(Signal<CGRect>)
        
        //    3. Action bindings are triggered by the object after construction.
        
        //    4. Delegate bindings require synchronous evaluation within the object's context.
        case display((CALayer) -> Void)
        case draw((CALayer, CGContext) -> Void)
        case layoutSublayers((CALayer) -> Void)
        case willDraw((CALayer) -> Void)
    }
    
    #if os(macOS)
    typealias CAAutoresizingMask = QuartzCore.CAAutoresizingMask
    typealias CIFilter = QuartzCore.CIFilter
    typealias CAConstraint = QuartzCore.CAConstraint
    #else
    typealias CAConstraint = ()
    typealias CAAutoresizingMask = ()
    typealias CIFilter = ()
    #endif
}

// MARK: - Binder Part 3: Preparer
public extension Layer {
    struct Preparer: BinderDelegateEmbedderConstructor {
        public typealias Binding = Layer.Binding
        public typealias Inherited = BinderBase
        public typealias Instance = CALayer
        
        public var inherited = Inherited()
        public var dynamicDelegate: Delegate? = nil
        public let delegateClass: Delegate.Type
        public init(delegateClass: Delegate.Type) {
            self.delegateClass = delegateClass
        }
        public func constructStorage(instance: Instance) -> Storage { return Storage() }
        public func inheritedBinding(from: Binding) -> Inherited.Binding? {
            if case .inheritedBinding(let b) = from { return b } else { return nil }
        }
    }
}

// MARK: - Binder Part 4: Preparer overrides
public extension Layer.Preparer {
    mutating func prepareBinding(_ binding: Binding) {
        switch binding {
        case .inheritedBinding(let x): inherited.prepareBinding(x)
        case .display(let x): delegate().addMultiHandler1(x, #selector(CALayerDelegate.display(_:)))
        case .draw(let x): delegate().addMultiHandler2(x, #selector(CALayerDelegate.draw(_:in:)))
        case .willDraw(let x): delegate().addMultiHandler1(x, #selector(CALayerDelegate.layerWillDraw(_:)))
        case .layoutSublayers(let x): delegate().addMultiHandler1(x, #selector(CALayerDelegate.layoutSublayers(of:)))
        default: break
        }
    }
    
    func applyBinding(_ binding: Binding, instance: Instance, storage: Storage) -> Lifetime? {
        switch binding {
        case .inheritedBinding(let x): return inherited.applyBinding(x, instance: instance, storage: storage)
            
            //    0. Static bindings are applied at construction and are subsequently immutable.
            
        //    1. Value bindings may be applied at construction and may subsequently change.
        case .actions(let x):
            return x.apply(instance, storage) { i, s, v in
                var actions = i.actions ?? [String: CAAction]()
                for (key, input) in v {
                    if let i = input {
                        actions[key] = s
                        storage.layerActions[key] = i
                    } else {
                        actions[key] = NSNull()
                        s.layerActions.removeValue(forKey: key)
                    }
                }
                i.actions = actions
            }
        case .affineTransform(let x): return x.apply(instance) { i, v in i.setAffineTransform(v) }
        case .anchorPoint(let x): return x.apply(instance) { i, v in i.anchorPoint = v }
        case .anchorPointZ(let x): return x.apply(instance) { i, v in i.anchorPointZ = v }
        case .backgroundColor(let x): return x.apply(instance) { i, v in i.backgroundColor = v }
        case .borderColor(let x): return x.apply(instance) { i, v in i.borderColor = v }
        case .borderWidth(let x): return x.apply(instance) { i, v in i.borderWidth = v }
        case .bounds(let x): return x.apply(instance) { i, v in i.bounds = v }
        case .contents(let x): return x.apply(instance) { i, v in i.contents = v }
        case .contentsCenter(let x): return x.apply(instance) { i, v in i.contentsCenter = v }
        case .contentsGravity(let x): return x.apply(instance) { i, v in i.contentsGravity = v }
        case .contentsRect(let x): return x.apply(instance) { i, v in i.contentsRect = v }
        case .contentsScale(let x): return x.apply(instance) { i, v in i.contentsScale = v }
        case .cornerRadius(let x): return x.apply(instance) { i, v in i.cornerRadius = v }
        case .drawsAsynchronously(let x): return x.apply(instance) { i, v in i.drawsAsynchronously = v }
        case .edgeAntialiasingMask(let x): return x.apply(instance) { i, v in i.edgeAntialiasingMask = v }
        case .frame(let x): return x.apply(instance) { i, v in i.frame = v }
        case .isDoubleSided(let x): return x.apply(instance) { i, v in i.isDoubleSided = v }
        case .isGeometryFlipped(let x): return x.apply(instance) { i, v in i.isGeometryFlipped = v }
        case .isHidden(let x): return x.apply(instance) { i, v in i.isHidden = v }
        case .isOpaque(let x): return x.apply(instance) { i, v in i.isOpaque = v }
        case .magnificationFilter(let x): return x.apply(instance) { i, v in i.magnificationFilter = v }
        case .mask(let x): return x.apply(instance) { i, v in i.mask = v?.caLayer() }
        case .masksToBounds(let x): return x.apply(instance) { i, v in i.masksToBounds = v }
        case .minificationFilter(let x): return x.apply(instance) { i, v in i.minificationFilter = v }
        case .minificationFilterBias(let x): return x.apply(instance) { i, v in i.minificationFilterBias = v }
        case .name(let x): return x.apply(instance) { i,v in i.name = v }
        case .needsDisplayOnBoundsChange(let x): return x.apply(instance) { i, v in i.needsDisplayOnBoundsChange = v }
        case .opacity(let x): return x.apply(instance) { i, v in i.opacity = v }
        case .position(let x): return x.apply(instance) { i, v in i.position = v }
        case .rasterizationScale(let x): return x.apply(instance) { i, v in i.rasterizationScale = v }
        case .shadowColor(let x): return x.apply(instance) { i, v in i.shadowColor = v }
        case .shadowOffset(let x): return x.apply(instance) { i, v in i.shadowOffset = v }
        case .shadowOpacity(let x): return x.apply(instance) { i, v in i.shadowOpacity = v }
        case .shadowPath(let x): return x.apply(instance) { i, v in i.shadowPath = v }
        case .shadowRadius(let x): return x.apply(instance) { i, v in i.shadowRadius = v }
        case .shouldRasterize(let x): return x.apply(instance) { i, v in i.shouldRasterize = v }
        case .style(let x): return x.apply(instance) { i,v in i.style = v }
        case .sublayers(let x): return x.apply(instance) { i, v in i.sublayers = v.map { $0.caLayer() } }
        case .sublayerTransform(let x): return x.apply(instance) { i, v in i.sublayerTransform = v }
        case .transform(let x): return x.apply(instance) { i, v in i.transform = v }
        case .zPosition(let x): return x.apply(instance) { i, v in i.zPosition = v }
            
        case .autoresizingMask(let x):
            #if os(macOS)
            return x.apply(instance) { i, v in i.autoresizingMask = v }
            #else
            return nil
            #endif
        case .backgroundFilters(let x):
            #if os(macOS)
            return x.apply(instance) { i, v in i.backgroundFilters = v }
            #else
            return nil
            #endif
        case .compositingFilter(let x):
            #if os(macOS)
            return x.apply(instance) { i, v in i.compositingFilter = v }
            #else
            return nil
            #endif
        case .constraints(let x):
            #if os(macOS)
            return x.apply(instance) { i, v in i.constraints = v }
            #else
            return nil
            #endif
        case .filters(let x):
            #if os(macOS)
            return x.apply(instance) { i, v in i.filters = v }
            #else
            return nil
            #endif
            
        //    2. Signal bindings are performed on the object after construction.
        case .addAnimation(let x): return x.apply(instance) { i, v in i.addAnimationForKey(v) }
        case .needsDisplay(let x): return x.apply(instance) { i, v in i.setNeedsDisplay() }
        case .needsDisplayInRect(let x): return x.apply(instance) { i, v in i.setNeedsDisplay(v) }
        case .removeAllAnimations(let x): return x.apply(instance) { i, v in i.removeAllAnimations() }
        case .removeAnimationForKey(let x): return x.apply(instance) { i, v in i.removeAnimation(forKey: v) }
        case .scrollRectToVisible(let x): return x.apply(instance) { i, v in i.scrollRectToVisible(v) }
            
            //    3. Action bindings are triggered by the object after construction.
            
        //    4. Delegate bindings require synchronous evaluation within the object's context.
        case .display: return nil
        case .draw: return nil
        case .layoutSublayers: return nil
        case .willDraw: return nil
        }
    }
}

// MARK: - Binder Part 5: Storage and Delegate
extension Layer.Preparer {
    open class Storage: AssociatedBinderStorage, CAAction, CALayerDelegate {
        // LayerBinderStorage implementation
        open var layerActions = [String: SignalInput<[AnyHashable: Any]?>]()
        @objc open func run(forKey event: String, object anObject: Any, arguments dict: [AnyHashable: Any]?) {
            _ = layerActions[event]?.send(value: dict)
        }
        
        open func action(for layer: CALayer, forKey event: String) -> CAAction? {
            return layerActions[event] != nil ? self : nil
        }
    }
    
    open class Delegate: DynamicDelegate, CALayerDelegate {
        open func layerWillDraw(_ layer: CALayer) {
            multiHandler(layer)
        }
        
        open func display(_ layer: CALayer) {
            multiHandler(layer)
        }
        
        @objc(drawLayer:inContext:) open func draw(_ layer: CALayer, in ctx: CGContext) {
            multiHandler(layer, ctx)
        }
        
        open func layoutSublayers(of layer: CALayer) {
            multiHandler(layer)
        }
    }
}

// MARK: - Binder Part 6: BindingNames
extension BindingName where Binding: LayerBinding {
    public typealias LayerName<V> = BindingName<V, Layer.Binding, Binding>
    private static func name<V>(_ source: @escaping (V) -> Layer.Binding) -> LayerName<V> {
        return LayerName<V>(source: source, downcast: Binding.layerBinding)
    }
}
public extension BindingName where Binding: LayerBinding {
    // You can easily convert the `Binding` cases to `BindingName` using the following Xcode-style regex:
    // Replace: case ([^\(]+)\((.+)\)$
    // With:    static var $1: LayerName<$2> { return .name(Layer.Binding.$1) }
    
    //    0. Static bindings are applied at construction and are subsequently immutable.
    
    //    1. Value bindings may be applied at construction and may subsequently change.
    static var actions: LayerName<Dynamic<[String: SignalInput<[AnyHashable: Any]?>?]>> { return .name(Layer.Binding.actions) }
    static var affineTransform: LayerName<Dynamic<CGAffineTransform>> { return .name(Layer.Binding.affineTransform) }
    static var anchorPoint: LayerName<Dynamic<CGPoint>> { return .name(Layer.Binding.anchorPoint) }
    static var anchorPointZ: LayerName<Dynamic<CGFloat>> { return .name(Layer.Binding.anchorPointZ) }
    static var backgroundColor: LayerName<Dynamic<CGColor>> { return .name(Layer.Binding.backgroundColor) }
    static var borderColor: LayerName<Dynamic<CGColor>> { return .name(Layer.Binding.borderColor) }
    static var borderWidth: LayerName<Dynamic<CGFloat>> { return .name(Layer.Binding.borderWidth) }
    static var bounds: LayerName<Dynamic<CGRect>> { return .name(Layer.Binding.bounds) }
    static var contents: LayerName<Dynamic<Any?>> { return .name(Layer.Binding.contents) }
    static var contentsCenter: LayerName<Dynamic<CGRect>> { return .name(Layer.Binding.contentsCenter) }
    static var contentsGravity: LayerName<Dynamic<CALayerContentsGravity>> { return .name(Layer.Binding.contentsGravity) }
    static var contentsRect: LayerName<Dynamic<CGRect>> { return .name(Layer.Binding.contentsRect) }
    static var contentsScale: LayerName<Dynamic<CGFloat>> { return .name(Layer.Binding.contentsScale) }
    static var cornerRadius: LayerName<Dynamic<CGFloat>> { return .name(Layer.Binding.cornerRadius) }
    static var drawsAsynchronously: LayerName<Dynamic<Bool>> { return .name(Layer.Binding.drawsAsynchronously) }
    static var edgeAntialiasingMask: LayerName<Dynamic<CAEdgeAntialiasingMask>> { return .name(Layer.Binding.edgeAntialiasingMask) }
    static var frame: LayerName<Dynamic<CGRect>> { return .name(Layer.Binding.frame) }
    static var isDoubleSided: LayerName<Dynamic<Bool>> { return .name(Layer.Binding.isDoubleSided) }
    static var isGeometryFlipped: LayerName<Dynamic<Bool>> { return .name(Layer.Binding.isGeometryFlipped) }
    static var isHidden: LayerName<Dynamic<Bool>> { return .name(Layer.Binding.isHidden) }
    static var isOpaque: LayerName<Dynamic<Bool>> { return .name(Layer.Binding.isOpaque) }
    static var magnificationFilter: LayerName<Dynamic<CALayerContentsFilter>> { return .name(Layer.Binding.magnificationFilter) }
    static var mask: LayerName<Dynamic<LayerConvertible?>> { return .name(Layer.Binding.mask) }
    static var masksToBounds: LayerName<Dynamic<Bool>> { return .name(Layer.Binding.masksToBounds) }
    static var minificationFilter: LayerName<Dynamic<CALayerContentsFilter>> { return .name(Layer.Binding.minificationFilter) }
    static var minificationFilterBias: LayerName<Dynamic<Float>> { return .name(Layer.Binding.minificationFilterBias) }
    static var name: LayerName<Dynamic<String>> { return .name(Layer.Binding.name) }
    static var needsDisplayOnBoundsChange: LayerName<Dynamic<Bool>> { return .name(Layer.Binding.needsDisplayOnBoundsChange) }
    static var opacity: LayerName<Dynamic<Float>> { return .name(Layer.Binding.opacity) }
    static var position: LayerName<Dynamic<CGPoint>> { return .name(Layer.Binding.position) }
    static var rasterizationScale: LayerName<Dynamic<CGFloat>> { return .name(Layer.Binding.rasterizationScale) }
    static var shadowColor: LayerName<Dynamic<CGColor?>> { return .name(Layer.Binding.shadowColor) }
    static var shadowOffset: LayerName<Dynamic<CGSize>> { return .name(Layer.Binding.shadowOffset) }
    static var shadowOpacity: LayerName<Dynamic<Float>> { return .name(Layer.Binding.shadowOpacity) }
    static var shadowPath: LayerName<Dynamic<CGPath?>> { return .name(Layer.Binding.shadowPath) }
    static var shadowRadius: LayerName<Dynamic<CGFloat>> { return .name(Layer.Binding.shadowRadius) }
    static var shouldRasterize: LayerName<Dynamic<Bool>> { return .name(Layer.Binding.shouldRasterize) }
    static var style: LayerName<Dynamic<[AnyHashable: Any]>> { return .name(Layer.Binding.style) }
    static var sublayers: LayerName<Dynamic<[LayerConvertible]>> { return .name(Layer.Binding.sublayers) }
    static var sublayerTransform: LayerName<Dynamic<CATransform3D>> { return .name(Layer.Binding.sublayerTransform) }
    static var transform: LayerName<Dynamic<CATransform3D>> { return .name(Layer.Binding.transform) }
    static var zPosition: LayerName<Dynamic<CGFloat>> { return .name(Layer.Binding.zPosition) }
    
    @available(macOS 10.13, *) @available(iOS, unavailable) static var autoresizingMask: LayerName<Dynamic<Layer.CAAutoresizingMask>> { return .name(Layer.Binding.autoresizingMask) }
    @available(macOS 10.13, *) @available(iOS, unavailable) static var backgroundFilters: LayerName<Dynamic<[Layer.CIFilter]?>> { return .name(Layer.Binding.backgroundFilters) }
    @available(macOS 10.13, *) @available(iOS, unavailable) static var compositingFilter: LayerName<Dynamic<Layer.CIFilter?>> { return .name(Layer.Binding.compositingFilter) }
    @available(macOS 10.13, *) @available(iOS, unavailable) static var constraints: LayerName<Dynamic<[Layer.CAConstraint]>> { return .name(Layer.Binding.constraints) }
    @available(macOS 10.13, *) @available(iOS, unavailable) static var filters: LayerName<Dynamic<[Layer.CIFilter]?>> { return .name(Layer.Binding.filters) }
    
    //    2. Signal bindings are performed on the object after construction.
    static var addAnimation: LayerName<Signal<AnimationForKey>> { return .name(Layer.Binding.addAnimation) }
    static var needsDisplay: LayerName<Signal<Void>> { return .name(Layer.Binding.needsDisplay) }
    static var needsDisplayInRect: LayerName<Signal<CGRect>> { return .name(Layer.Binding.needsDisplayInRect) }
    static var removeAllAnimations: LayerName<Signal<Void>> { return .name(Layer.Binding.removeAllAnimations) }
    static var removeAnimationForKey: LayerName<Signal<String>> { return .name(Layer.Binding.removeAnimationForKey) }
    static var scrollRectToVisible: LayerName<Signal<CGRect>> { return .name(Layer.Binding.scrollRectToVisible) }
    
    //    3. Action bindings are triggered by the object after construction.
    
    //    4. Delegate bindings require synchronous evaluation within the object's context.
    static var display: LayerName<(CALayer) -> Void> { return .name(Layer.Binding.display) }
    static var draw: LayerName<(CALayer, CGContext) -> Void> { return .name(Layer.Binding.draw) }
    static var layoutSublayers: LayerName<(CALayer) -> Void> { return .name(Layer.Binding.layoutSublayers) }
    static var willDraw: LayerName<(CALayer) -> Void> { return .name(Layer.Binding.willDraw) }
}

// MARK: - Binder Part 7: Convertible protocols (if constructible)
public protocol LayerConvertible {
    func caLayer() -> Layer.Instance
}
extension CALayer: LayerConvertible, HasDelegate, DefaultConstructable {
    public func caLayer() -> Layer.Instance { return self }
}
public extension Layer {
    func caLayer() -> Layer.Instance { return instance() }
}

// MARK: - Binder Part 8: Downcast protocols
public protocol LayerBinding: BinderBaseBinding {
    static func layerBinding(_ binding: Layer.Binding) -> Self
    func asLayerBinding() -> Layer.Binding?
}
public extension LayerBinding {
    static func binderBaseBinding(_ binding: BinderBase.Binding) -> Self {
        return layerBinding(.inheritedBinding(binding))
    }
}
public extension LayerBinding where Preparer.Inherited.Binding: LayerBinding {
    func asLayerBinding() -> Layer.Binding? {
        return asInheritedBinding()?.asLayerBinding()
    }
}
public extension Layer.Binding {
    typealias Preparer = Layer.Preparer
    func asInheritedBinding() -> Preparer.Inherited.Binding? { if case .inheritedBinding(let b) = self { return b } else { return nil } }
    func asLayerBinding() -> Layer.Binding? { return self }
    static func layerBinding(_ binding: Layer.Binding) -> Layer.Binding {
        return binding
    }
}

// MARK: - Binder Part 9: Other supporting types
public struct AnimationForKey {
    public let animation: CAAnimation
    public let key: String?
    
    public init(animation: CAAnimation, forKey: String? = nil) {
        self.animation = animation
        self.key = forKey
    }
    
    public static var fade: AnimationForKey {
        let t = CATransition()
        t.type = CATransitionType.fade
        
        // NOTE: fade animations are always applied under key kCATransition so it's pointless trying to set a key
        return AnimationForKey(animation: t, forKey: nil)
    }
    
    public enum Direction {
        case left, right, top, bottom
        func transition(ofType: CATransitionType, forKey: String? = nil) -> AnimationForKey {
            let t = CATransition()
            t.type = ofType
            switch self {
            case .left: t.subtype = CATransitionSubtype.fromLeft
            case .right: t.subtype = CATransitionSubtype.fromRight
            case .top: t.subtype = CATransitionSubtype.fromTop
            case .bottom: t.subtype = CATransitionSubtype.fromBottom
            }
            return AnimationForKey(animation: t, forKey: forKey)
        }
    }
    
    public static func moveIn(from: Direction, forKey: String? = nil) -> AnimationForKey {
        return from.transition(ofType: CATransitionType.moveIn, forKey: forKey)
    }
    
    public static func push(from: Direction, forKey: String? = nil) -> AnimationForKey {
        return from.transition(ofType: CATransitionType.push, forKey: forKey)
    }
    
    public static func reveal(from: Direction, forKey: String? = nil) -> AnimationForKey {
        return from.transition(ofType: CATransitionType.reveal, forKey: forKey)
    }
}

public extension CALayer {
    func addAnimationForKey(_ animationForKey: AnimationForKey) {
        add(animationForKey.animation, forKey: animationForKey.key)
    }
}

// MARK: - Binder Part 1: Binder
public class GestureRecognizer: Binder, GestureRecognizerConvertible {
    public var state: BinderState<Preparer>
    public required init(type: Preparer.Instance.Type, parameters: Preparer.Parameters, bindings: [Preparer.Binding]) {
        state = .pending(type: type, parameters: parameters, bindings: bindings)
    }
}

// MARK: - Binder Part 2: Binding
public extension GestureRecognizer {
    enum Binding: GestureRecognizerBinding {
        case inheritedBinding(Preparer.Inherited.Binding)
        
        //    0. Static bindings are applied at construction and are subsequently immutable.
        
        // 1. Value bindings may be applied at construction and may subsequently change.
        case allowedPressTypes(Dynamic<[NSNumber]>)
        case allowedTouchTypes(Dynamic<[NSNumber]>)
        case cancelsTouchesInView(Dynamic<Bool>)
        case delaysTouchesBegan(Dynamic<Bool>)
        case delaysTouchesEnded(Dynamic<Bool>)
        case requiresExclusiveTouchType(Dynamic<Bool>)
        
        // 2. Signal bindings are performed on the object after construction.
        
        // 3. Action bindings are triggered by the object after construction.
        case action(SignalInput<Any?>)
        
        // 4. Delegate bindings require synchronous evaluation within the object's context.
        case shouldBegin((UIGestureRecognizer) -> Bool)
        case shouldBeRequiredToFail((UIGestureRecognizer, _ by: UIGestureRecognizer) -> Bool)
        case shouldReceivePress((UIGestureRecognizer, UIPress) -> Bool)
        case shouldReceiveTouch((UIGestureRecognizer, UITouch) -> Bool)
        case shouldRecognizeSimultanously((UIGestureRecognizer, UIGestureRecognizer) -> Bool)
        case shouldRequireFailure((UIGestureRecognizer, _ of: UIGestureRecognizer) -> Bool)
    }
}

// MARK: - Binder Part 3: Preparer
public extension GestureRecognizer {
    struct Preparer: BinderDelegateEmbedderConstructor {
        public typealias Binding = GestureRecognizer.Binding
        public typealias Inherited = BinderBase
        public typealias Instance = UIGestureRecognizer
        
        public var inherited = Inherited()
        public var dynamicDelegate: Delegate? = nil
        public let delegateClass: Delegate.Type
        public init(delegateClass: Delegate.Type) {
            self.delegateClass = delegateClass
        }
        public func constructStorage(instance: Instance) -> Storage { return Storage() }
        public func inheritedBinding(from: Binding) -> Inherited.Binding? {
            if case .inheritedBinding(let b) = from { return b } else { return nil }
        }
    }
}

// MARK: - Binder Part 4: Preparer overrides
public extension GestureRecognizer.Preparer {
    mutating func prepareBinding(_ binding: Binding) {
        switch binding {
        case .inheritedBinding(let preceeding): inherited.prepareBinding(preceeding)
            
        case .shouldBegin(let x): delegate().addSingleHandler1(x, #selector(UIGestureRecognizerDelegate.gestureRecognizerShouldBegin(_:)))
        case .shouldBeRequiredToFail(let x): delegate().addSingleHandler2(x, #selector(UIGestureRecognizerDelegate.gestureRecognizer(_:shouldBeRequiredToFailBy:)))
        case .shouldReceivePress(let x): delegate().addSingleHandler2(x, #selector(UIGestureRecognizerDelegate.gestureRecognizer(_:shouldReceive:) as((UIGestureRecognizerDelegate) -> (UIGestureRecognizer, UIPress) -> Bool)?))
        case .shouldReceiveTouch(let x): delegate().addSingleHandler2(x, #selector(UIGestureRecognizerDelegate.gestureRecognizer(_:shouldReceive:) as((UIGestureRecognizerDelegate) -> (UIGestureRecognizer, UITouch) -> Bool)?))
        case .shouldRecognizeSimultanously(let x): delegate().addSingleHandler2(x, #selector(UIGestureRecognizerDelegate.gestureRecognizer(_:shouldRecognizeSimultaneouslyWith:)))
        case .shouldRequireFailure(let x): delegate().addSingleHandler2(x, #selector(UIGestureRecognizerDelegate.gestureRecognizer(_:shouldRequireFailureOf:)))
        default: break
        }
    }
    
    func applyBinding(_ binding: Binding, instance: Instance, storage: Storage) -> Lifetime? {
        switch binding {
        case .inheritedBinding(let x): return inherited.applyBinding(x, instance: instance, storage: storage)
            
            //    0. Static bindings are applied at construction and are subsequently immutable.
            
        // 1. Value bindings may be applied at construction and may subsequently change.
        case .allowedPressTypes(let x): return x.apply(instance) { i, v in i.allowedPressTypes = v }
        case .allowedTouchTypes(let x): return x.apply(instance) { i, v in i.allowedTouchTypes = v }
        case .cancelsTouchesInView(let x): return x.apply(instance) { i, v in i.cancelsTouchesInView = v }
        case .delaysTouchesBegan(let x): return x.apply(instance) { i, v in i.delaysTouchesBegan = v }
        case .delaysTouchesEnded(let x): return x.apply(instance) { i, v in i.delaysTouchesEnded = v }
            
        case .requiresExclusiveTouchType(let x): return x.apply(instance) { i, v in i.requiresExclusiveTouchType = v }
            
            // 2. Signal bindings are performed on the object after construction.
            
        // 3. Action bindings are triggered by the object after construction.
        case .action(let x):
            let target = SignalActionTarget()
            instance.addTarget(target, action: SignalActionTarget.selector)
            return target.signal.cancellableBind(to: x)
            
        // 4. Delegate bindings require synchronous evaluation within the object's context.
        case .shouldBegin: return nil
        case .shouldReceiveTouch: return nil
        case .shouldRecognizeSimultanously: return nil
        case .shouldRequireFailure: return nil
        case .shouldBeRequiredToFail: return nil
        case .shouldReceivePress: return nil
        }
    }
}

// MARK: - Binder Part 5: Storage and Delegate
extension GestureRecognizer.Preparer {
    open class Storage: AssociatedBinderStorage, UIGestureRecognizerDelegate {}
    
    open class Delegate: DynamicDelegate, UIGestureRecognizerDelegate {
        open func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
            return singleHandler(gestureRecognizer)
        }
        
        open func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldReceive touch: UITouch) -> Bool {
            return singleHandler(gestureRecognizer, touch)
        }
        
        open func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
            return singleHandler(gestureRecognizer, otherGestureRecognizer)
        }
        
        open func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRequireFailureOf otherGestureRecognizer: UIGestureRecognizer) -> Bool {
            return singleHandler(gestureRecognizer, otherGestureRecognizer)
        }
        
        open func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldBeRequiredToFailBy otherGestureRecognizer: UIGestureRecognizer) -> Bool {
            return singleHandler(gestureRecognizer, otherGestureRecognizer)
        }
        
        open func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldReceive press: UIPress) -> Bool {
            return singleHandler(gestureRecognizer, press)
        }
    }
}

// MARK: - Binder Part 6: BindingNames
extension BindingName where Binding: GestureRecognizerBinding {
    public typealias GestureRecognizerName<V> = BindingName<V, GestureRecognizer.Binding, Binding>
    private static func name<V>(_ source: @escaping (V) -> GestureRecognizer.Binding) -> GestureRecognizerName<V> {
        return GestureRecognizerName<V>(source: source, downcast: Binding.gestureRecognizerBinding)
    }
}
public extension BindingName where Binding: GestureRecognizerBinding {
    // You can easily convert the `Binding` cases to `BindingName` using the following Xcode-style regex:
    // Replace: case ([^\(]+)\((.+)\)$
    // With:    static var $1: GestureRecognizerName<$2> { return .name(GestureRecognizer.Binding.$1) }
    
    //    0. Static bindings are applied at construction and are subsequently immutable.
    
    // 1. Value bindings may be applied at construction and may subsequently change.
    static var allowedPressTypes: GestureRecognizerName<Dynamic<[NSNumber]>> { return .name(GestureRecognizer.Binding.allowedPressTypes) }
    static var allowedTouchTypes: GestureRecognizerName<Dynamic<[NSNumber]>> { return .name(GestureRecognizer.Binding.allowedTouchTypes) }
    static var cancelsTouchesInView: GestureRecognizerName<Dynamic<Bool>> { return .name(GestureRecognizer.Binding.cancelsTouchesInView) }
    static var delaysTouchesBegan: GestureRecognizerName<Dynamic<Bool>> { return .name(GestureRecognizer.Binding.delaysTouchesBegan) }
    static var delaysTouchesEnded: GestureRecognizerName<Dynamic<Bool>> { return .name(GestureRecognizer.Binding.delaysTouchesEnded) }
    static var requiresExclusiveTouchType: GestureRecognizerName<Dynamic<Bool>> { return .name(GestureRecognizer.Binding.requiresExclusiveTouchType) }
    
    // 2. Signal bindings are performed on the object after construction.
    
    // 3. Action bindings are triggered by the object after construction.
    static var action: GestureRecognizerName<SignalInput<Any?>> { return .name(GestureRecognizer.Binding.action) }
    
    // 4. Delegate bindings require synchronous evaluation within the object's context.
    static var shouldBegin: GestureRecognizerName<(UIGestureRecognizer) -> Bool> { return .name(GestureRecognizer.Binding.shouldBegin) }
    static var shouldBeRequiredToFail: GestureRecognizerName<(UIGestureRecognizer, _ by: UIGestureRecognizer) -> Bool> { return .name(GestureRecognizer.Binding.shouldBeRequiredToFail) }
    static var shouldReceivePress: GestureRecognizerName<(UIGestureRecognizer, UIPress) -> Bool> { return .name(GestureRecognizer.Binding.shouldReceivePress) }
    static var shouldReceiveTouch: GestureRecognizerName<(UIGestureRecognizer, UITouch) -> Bool> { return .name(GestureRecognizer.Binding.shouldReceiveTouch) }
    static var shouldRecognizeSimultanously: GestureRecognizerName<(UIGestureRecognizer, UIGestureRecognizer) -> Bool> { return .name(GestureRecognizer.Binding.shouldRecognizeSimultanously) }
    static var shouldRequireFailure: GestureRecognizerName<(UIGestureRecognizer, _ of: UIGestureRecognizer) -> Bool> { return .name(GestureRecognizer.Binding.shouldRequireFailure) }
    
    // Composite binding names
    static func action<Value>(_ keyPath: KeyPath<Binding.Preparer.Instance, Value>) -> GestureRecognizerName<SignalInput<Value>> {
        return Binding.mappedInputName(
            map: { sender in (sender as! Binding.Preparer.Instance)[keyPath: keyPath] },
            binding: GestureRecognizer.Binding.action,
            downcast: Binding.gestureRecognizerBinding
        )
    }
}

// MARK: - Binder Part 7: Convertible protocols (if constructible)
public protocol GestureRecognizerConvertible {
    func uiGestureRecognizer() -> GestureRecognizer.Instance
}
extension UIGestureRecognizer: GestureRecognizerConvertible, DefaultConstructable, HasDelegate {
    public func uiGestureRecognizer() -> GestureRecognizer.Instance { return self }
}
public extension GestureRecognizer {
    func uiGestureRecognizer() -> GestureRecognizer.Instance { return instance() }
}

// MARK: - Binder Part 8: Downcast protocols
public protocol GestureRecognizerBinding: BinderBaseBinding {
    static func gestureRecognizerBinding(_ binding: GestureRecognizer.Binding) -> Self
    func asGestureRecognizerBinding() -> GestureRecognizer.Binding?
}
public extension GestureRecognizerBinding {
    static func binderBaseBinding(_ binding: BinderBase.Binding) -> Self {
        return gestureRecognizerBinding(.inheritedBinding(binding))
    }
}
public extension GestureRecognizerBinding where Preparer.Inherited.Binding: GestureRecognizerBinding {
    func asGestureRecognizerBinding() -> GestureRecognizer.Binding? {
        return asInheritedBinding()?.asGestureRecognizerBinding()
    }
}
public extension GestureRecognizer.Binding {
    typealias Preparer = GestureRecognizer.Preparer
    func asInheritedBinding() -> Preparer.Inherited.Binding? { if case .inheritedBinding(let b) = self { return b } else { return nil } }
    func asGestureRecognizerBinding() -> GestureRecognizer.Binding? { return self }
    static func gestureRecognizerBinding(_ binding: GestureRecognizer.Binding) -> GestureRecognizer.Binding {
        return binding
    }
}

// MARK: - Binder Part 9: Other supporting types


// MARK: - Binder Part 1: Binder
public class View: Binder, ViewConvertible {
    public var state: BinderState<Preparer>
    public required init(type: Preparer.Instance.Type, parameters: Preparer.Parameters, bindings: [Preparer.Binding]) {
        state = .pending(type: type, parameters: parameters, bindings: bindings)
    }
}

// MARK: - Binder Part 2: Binding
public extension View {
    enum Binding: ViewBinding {
        case inheritedBinding(Preparer.Inherited.Binding)
        
        //    0. Static bindings are applied at construction and are subsequently immutable.
        case layer(Constant<Layer>)
        
        // 1. Value bindings may be applied at construction and may subsequently change.
        case alpha(Dynamic<(CGFloat)>)
        case backgroundColor(Dynamic<(UIColor?)>)
        case clearsContextBeforeDrawing(Dynamic<(Bool)>)
        case clipsToBounds(Dynamic<(Bool)>)
        case contentMode(Dynamic<(UIView.ContentMode)>)
        case gestureRecognizers(Dynamic<[GestureRecognizerConvertible]>)
        case horizontalContentCompressionResistancePriority(Dynamic<UILayoutPriority>)
        case horizontalContentHuggingPriority(Dynamic<UILayoutPriority>)
        case isExclusiveTouch(Dynamic<(Bool)>)
        case isHidden(Dynamic<(Bool)>)
        case isMultipleTouchEnabled(Dynamic<(Bool)>)
        case isOpaque(Dynamic<(Bool)>)
        case isUserInteractionEnabled(Dynamic<(Bool)>)
        case layout(Dynamic<Layout>)
        case layoutMargins(Dynamic<(UIEdgeInsets)>)
        case mask(Dynamic<(ViewConvertible?)>)
        case motionEffects(Dynamic<([UIMotionEffect])>)
        case preservesSuperviewLayoutMargins(Dynamic<(Bool)>)
        case restorationIdentifier(Dynamic<String?>)
        case semanticContentAttribute(Dynamic<(UISemanticContentAttribute)>)
        case tag(Dynamic<Int>)
        case tintAdjustmentMode(Dynamic<(UIView.TintAdjustmentMode)>)
        case tintColor(Dynamic<(UIColor)>)
        case verticalContentCompressionResistancePriority(Dynamic<UILayoutPriority>)
        case verticalContentHuggingPriority(Dynamic<UILayoutPriority>)
        
        // 2. Signal bindings are performed on the object after construction.
        case becomeFirstResponder(Signal<Void>)
        case endEditing(Signal<Bool>)
        
        // 3. Action bindings are triggered by the object after construction.
        
        // 4. Delegate bindings require synchronous evaluation within the object's context.
    }
}

// MARK: - Binder Part 3: Preparer
public extension View {
    struct Preparer: BinderEmbedderConstructor {
        public typealias Binding = View.Binding
        public typealias Inherited = BinderBase
        public typealias Instance = UIView
        
        public var inherited = Inherited()
        public init() {}
        public func constructStorage(instance: Instance) -> Storage { return Storage() }
        public func inheritedBinding(from: Binding) -> Inherited.Binding? {
            if case .inheritedBinding(let b) = from { return b } else { return nil }
        }
    }
}

// MARK: - Binder Part 4: Preparer overrides
public extension View.Preparer {
    func applyBinding(_ binding: Binding, instance: Instance, storage: Storage) -> Lifetime? {
        switch binding {
        case .inheritedBinding(let x): return inherited.applyBinding(x, instance: instance, storage: storage)
            
        //    0. Static bindings are applied at construction and are subsequently immutable.
        case .layer(let x):
            x.value.apply(to: instance.layer)
            return nil
            
        //    1. Value bindings may be applied at construction and may subsequently change.
        case .alpha(let x): return x.apply(instance) { i, v in i.alpha = v }
        case .backgroundColor(let x): return x.apply(instance) { i, v in i.backgroundColor = v }
        case .clearsContextBeforeDrawing(let x): return x.apply(instance) { i, v in i.clearsContextBeforeDrawing = v }
        case .clipsToBounds(let x): return x.apply(instance) { i, v in i.clipsToBounds = v }
        case .contentMode(let x): return x.apply(instance) { i, v in i.contentMode = v }
        case .gestureRecognizers(let x): return x.apply(instance) { i, v in i.gestureRecognizers = v.map { $0.uiGestureRecognizer() } }
        case .horizontalContentCompressionResistancePriority(let x): return x.apply(instance) { i, v in i.setContentCompressionResistancePriority(v, for: NSLayoutConstraint.Axis.horizontal) }
        case .horizontalContentHuggingPriority(let x): return x.apply(instance) { i, v in i.setContentHuggingPriority(v, for: NSLayoutConstraint.Axis.horizontal) }
        case .isExclusiveTouch(let x): return x.apply(instance) { i, v in i.isExclusiveTouch = v }
        case .isHidden(let x): return x.apply(instance) { i, v in i.isHidden = v }
        case .isMultipleTouchEnabled(let x): return x.apply(instance) { i, v in i.isMultipleTouchEnabled = v }
        case .isOpaque(let x): return x.apply(instance) { i, v in i.isOpaque = v }
        case .isUserInteractionEnabled(let x): return x.apply(instance) { i, v in i.isUserInteractionEnabled = v }
        case .layout(let x): return x.apply(instance) { i, v in instance.applyLayout(v) }
        case .layoutMargins(let x): return x.apply(instance) { i, v in i.layoutMargins = v }
        case .mask(let x): return x.apply(instance) { i, v in i.mask = v?.uiView() }
        case .motionEffects(let x): return x.apply(instance) { i, v in i.motionEffects = v }
        case .preservesSuperviewLayoutMargins(let x): return x.apply(instance) { i, v in i.preservesSuperviewLayoutMargins = v }
        case .restorationIdentifier(let x): return x.apply(instance) { i, v in i.restorationIdentifier = v }
        case .semanticContentAttribute(let x): return x.apply(instance) { i, v in i.semanticContentAttribute = v }
        case .tag(let x): return x.apply(instance) { i, v in i.tag = v }
        case .tintAdjustmentMode(let x): return x.apply(instance) { i, v in i.tintAdjustmentMode = v }
        case .tintColor(let x): return x.apply(instance) { i, v in i.tintColor = v }
        case .verticalContentCompressionResistancePriority(let x): return x.apply(instance) { i, v in i.setContentCompressionResistancePriority(v, for: NSLayoutConstraint.Axis.vertical) }
        case .verticalContentHuggingPriority(let x): return x.apply(instance) { i, v in i.setContentHuggingPriority(v, for: NSLayoutConstraint.Axis.vertical) }
            
        // 2. Signal bindings are performed on the object after construction.
        case .becomeFirstResponder(let x): return x.apply(instance) { i, v in i.becomeFirstResponder() }
        case .endEditing(let x): return x.apply(instance) { i, v in i.endEditing(v) }
            
            // 3. Action bindings are triggered by the object after construction.
            
            // 4. Delegate bindings require synchronous evaluation within the object's context.
        }
    }
}

// MARK: - Binder Part 5: Storage and Delegate
extension View.Preparer {
    public typealias Storage = AssociatedBinderStorage
}

// MARK: - Binder Part 6: BindingNames
extension BindingName where Binding: ViewBinding {
    public typealias ViewName<V> = BindingName<V, View.Binding, Binding>
    private static func name<V>(_ source: @escaping (V) -> View.Binding) -> ViewName<V> {
        return ViewName<V>(source: source, downcast: Binding.viewBinding)
    }
}
public extension BindingName where Binding: ViewBinding {
    // You can easily convert the `Binding` cases to `BindingName` using the following Xcode-style regex:
    // Replace: case ([^\(]+)\((.+)\)$
    // With:    static var $1: ViewName<$2> { return .name(View.Binding.$1) }
    
    //    0. Static bindings are applied at construction and are subsequently immutable.
    static var layer: ViewName<Constant<Layer>> { return .name(View.Binding.layer) }
    
    // 1. Value bindings may be applied at construction and may subsequently change.
    static var alpha: ViewName<Dynamic<(CGFloat)>> { return .name(View.Binding.alpha) }
    static var backgroundColor: ViewName<Dynamic<(UIColor?)>> { return .name(View.Binding.backgroundColor) }
    static var clearsContextBeforeDrawing: ViewName<Dynamic<(Bool)>> { return .name(View.Binding.clearsContextBeforeDrawing) }
    static var clipsToBounds: ViewName<Dynamic<(Bool)>> { return .name(View.Binding.clipsToBounds) }
    static var contentMode: ViewName<Dynamic<(UIView.ContentMode)>> { return .name(View.Binding.contentMode) }
    static var gestureRecognizers: ViewName<Dynamic<[GestureRecognizerConvertible]>> { return .name(View.Binding.gestureRecognizers) }
    static var horizontalContentCompressionResistancePriority: ViewName<Dynamic<UILayoutPriority>> { return .name(View.Binding.horizontalContentCompressionResistancePriority) }
    static var horizontalContentHuggingPriority: ViewName<Dynamic<UILayoutPriority>> { return .name(View.Binding.horizontalContentHuggingPriority) }
    static var isExclusiveTouch: ViewName<Dynamic<(Bool)>> { return .name(View.Binding.isExclusiveTouch) }
    static var isHidden: ViewName<Dynamic<(Bool)>> { return .name(View.Binding.isHidden) }
    static var isMultipleTouchEnabled: ViewName<Dynamic<(Bool)>> { return .name(View.Binding.isMultipleTouchEnabled) }
    static var isOpaque: ViewName<Dynamic<(Bool)>> { return .name(View.Binding.isOpaque) }
    static var isUserInteractionEnabled: ViewName<Dynamic<(Bool)>> { return .name(View.Binding.isUserInteractionEnabled) }
    static var layout: ViewName<Dynamic<Layout>> { return .name(View.Binding.layout) }
    static var layoutMargins: ViewName<Dynamic<(UIEdgeInsets)>> { return .name(View.Binding.layoutMargins) }
    static var mask: ViewName<Dynamic<(ViewConvertible?)>> { return .name(View.Binding.mask) }
    static var motionEffects: ViewName<Dynamic<([UIMotionEffect])>> { return .name(View.Binding.motionEffects) }
    static var preservesSuperviewLayoutMargins: ViewName<Dynamic<(Bool)>> { return .name(View.Binding.preservesSuperviewLayoutMargins) }
    static var restorationIdentifier: ViewName<Dynamic<String?>> { return .name(View.Binding.restorationIdentifier) }
    static var semanticContentAttribute: ViewName<Dynamic<(UISemanticContentAttribute)>> { return .name(View.Binding.semanticContentAttribute) }
    static var tag: ViewName<Dynamic<Int>> { return .name(View.Binding.tag) }
    static var tintAdjustmentMode: ViewName<Dynamic<(UIView.TintAdjustmentMode)>> { return .name(View.Binding.tintAdjustmentMode) }
    static var tintColor: ViewName<Dynamic<(UIColor)>> { return .name(View.Binding.tintColor) }
    static var verticalContentCompressionResistancePriority: ViewName<Dynamic<UILayoutPriority>> { return .name(View.Binding.verticalContentCompressionResistancePriority) }
    static var verticalContentHuggingPriority: ViewName<Dynamic<UILayoutPriority>> { return .name(View.Binding.verticalContentHuggingPriority) }
    
    // 2. Signal bindings are performed on the object after construction.
    static var becomeFirstResponder: ViewName<Signal<Void>> { return .name(View.Binding.becomeFirstResponder) }
    static var endEditing: ViewName<Signal<Bool>> { return .name(View.Binding.endEditing) }
    
    // 3. Action bindings are triggered by the object after construction.
    
    // 4. Delegate bindings require synchronous evaluation within the object's context.
}

// MARK: - Binder Part 7: Convertible protocols (if constructible)
extension UIView: DefaultConstructable {}
public extension View {
    func uiView() -> Layout.View { return instance() }
}

// MARK: - Binder Part 8: Downcast protocols
public protocol ViewBinding: BinderBaseBinding {
    static func viewBinding(_ binding: View.Binding) -> Self
    func asViewBinding() -> View.Binding?
}
public extension ViewBinding {
    static func binderBaseBinding(_ binding: BinderBase.Binding) -> Self {
        return viewBinding(.inheritedBinding(binding))
    }
}
public extension ViewBinding where Preparer.Inherited.Binding: ViewBinding {
    func asViewBinding() -> View.Binding? {
        return asInheritedBinding()?.asViewBinding()
    }
}
public extension View.Binding {
    typealias Preparer = View.Preparer
    func asInheritedBinding() -> Preparer.Inherited.Binding? { if case .inheritedBinding(let b) = self { return b } else { return nil } }
    func asViewBinding() -> View.Binding? { return self }
    static func viewBinding(_ binding: View.Binding) -> View.Binding {
        return binding
    }
}

// MARK: - Binder Part 1: Binder
public class Control: Binder, ControlConvertible {
    public var state: BinderState<Preparer>
    public required init(type: Preparer.Instance.Type, parameters: Preparer.Parameters, bindings: [Preparer.Binding]) {
        state = .pending(type: type, parameters: parameters, bindings: bindings)
    }
}

// MARK: - Binder Part 2: Binding
public extension Control {
    enum Binding: ControlBinding {
        case inheritedBinding(Preparer.Inherited.Binding)
        
        //    0. Static bindings are applied at construction and are subsequently immutable.
        
        // 1. Value bindings may be applied at construction and may subsequently change.
        case isEnabled(Dynamic<Bool>)
        case isSelected(Dynamic<Bool>)
        case isHighlighted(Dynamic<Bool>)
        case contentVerticalAlignment(Dynamic<UIControl.ContentVerticalAlignment>)
        case contentHorizontalAlignment(Dynamic<UIControl.ContentHorizontalAlignment>)
        
        // 2. Signal bindings are performed on the object after construction.
        
        // 3. Action bindings are triggered by the object after construction.
        case actions(ControlActions)
        
        // 4. Delegate bindings require synchronous evaluation within the object's context.
    }
}

// MARK: - Binder Part 3: Preparer
public extension Control {
    struct Preparer: BinderEmbedderConstructor {
        public typealias Binding = Control.Binding
        public typealias Inherited = View.Preparer
        public typealias Instance = UIControl
        
        public var inherited = Inherited()
        public init() {}
        public func constructStorage(instance: Instance) -> Storage { return Storage() }
        public func inheritedBinding(from: Binding) -> Inherited.Binding? {
            if case .inheritedBinding(let b) = from { return b } else { return nil }
        }
    }
}

// MARK: - Binder Part 4: Preparer overrides
public extension Control.Preparer {
    func applyBinding(_ binding: Binding, instance: Instance, storage: Storage) -> Lifetime? {
        switch binding {
        case .inheritedBinding(let x): return inherited.applyBinding(x, instance: instance, storage: storage)
            
            //    0. Static bindings are applied at construction and are subsequently immutable.
            
        // 1. Value bindings may be applied at construction and may subsequently change.
        case .contentHorizontalAlignment(let x): return x.apply(instance) { i, v in i.contentHorizontalAlignment = v }
        case .contentVerticalAlignment(let x): return x.apply(instance) { i, v in i.contentVerticalAlignment = v }
        case .isEnabled(let x): return x.apply(instance) { i, v in i.isEnabled = v }
        case .isHighlighted(let x): return x.apply(instance) { i, v in i.isHighlighted = v }
        case .isSelected(let x): return x.apply(instance) { i, v in i.isSelected = v }
            
            // 2. Signal bindings are performed on the object after construction.
            
        // 3. Action bindings are triggered by the object after construction.
        case .actions(let x):
            var lifetimes = [Lifetime]()
            for (scope, value) in x.pairs {
                switch value {
                case .firstResponder(let s):
                    instance.addTarget(nil, action: s, for: scope)
                case .singleTarget(let s):
                    let target = SignalControlEventActionTarget()
                    instance.addTarget(target, action: target.selector, for: scope)
                    lifetimes += target.source.cancellableBind(to: s)
                }
            }
            return lifetimes.isEmpty ? nil : AggregateLifetime(lifetimes: lifetimes)
            
            // 4. Delegate bindings require synchronous evaluation within the object's context.
        }
    }
}

// MARK: - Binder Part 5: Storage and Delegate
extension Control.Preparer {
    public typealias Storage = View.Preparer.Storage
}

// MARK: - Binder Part 6: BindingNames
extension BindingName where Binding: ControlBinding {
    public typealias ControlName<V> = BindingName<V, Control.Binding, Binding>
    private static func name<V>(_ source: @escaping (V) -> Control.Binding) -> ControlName<V> {
        return ControlName<V>(source: source, downcast: Binding.controlBinding)
    }
}
public extension BindingName where Binding: ControlBinding {
    // You can easily convert the `Binding` cases to `BindingName` using the following Xcode-style regex:
    // Replace: case ([^\(]+)\((.+)\)$
    // With:    static var $1: ControlName<$2> { return .name(Control.Binding.$1) }
    
    //    0. Static bindings are applied at construction and are subsequently immutable.
    
    // 1. Value bindings may be applied at construction and may subsequently change.
    static var isEnabled: ControlName<Dynamic<Bool>> { return .name(Control.Binding.isEnabled) }
    static var isSelected: ControlName<Dynamic<Bool>> { return .name(Control.Binding.isSelected) }
    static var isHighlighted: ControlName<Dynamic<Bool>> { return .name(Control.Binding.isHighlighted) }
    static var contentVerticalAlignment: ControlName<Dynamic<UIControl.ContentVerticalAlignment>> { return .name(Control.Binding.contentVerticalAlignment) }
    static var contentHorizontalAlignment: ControlName<Dynamic<UIControl.ContentHorizontalAlignment>> { return .name(Control.Binding.contentHorizontalAlignment) }
    
    // 2. Signal bindings are performed on the object after construction.
    
    // 3. Action bindings are triggered by the object after construction.
    static var actions: ControlName<ControlActions> { return .name(Control.Binding.actions) }
    
    // 4. Delegate bindings require synchronous evaluation within the object's context.
    
    // Composite binding names
    static func action<Value>(_ scope: UIControl.Event, _ keyPath: KeyPath<Binding.Preparer.Instance, Value>) -> ControlName<SignalInput<Value>> {
        return Binding.mappedWrappedInputName(
            map: { tuple in
                (tuple.0 as! Binding.Preparer.Instance)[keyPath: keyPath]
        },
            wrap: { input in ControlActions(scope: scope, value: ControlAction.singleTarget(input)) },
            binding: Control.Binding.actions,
            downcast: Binding.controlBinding
        )
    }
    static func action(_ scope: UIControl.Event) -> ControlName<SignalInput<Void>> {
        return Binding.mappedWrappedInputName(
            map: { tuple in () },
            wrap: { input in ControlActions(scope: scope, value: ControlAction.singleTarget(input)) },
            binding: Control.Binding.actions,
            downcast: Binding.controlBinding
        )
    }
}

// MARK: - Binder Part 7: Convertible protocols (if constructible)
public protocol ControlConvertible: ViewConvertible {
    func uiControl() -> Control.Instance
}
extension ControlConvertible {
    public func uiView() -> View.Instance { return uiControl() }
}
extension UIControl: ControlConvertible {
    public func uiControl() -> Control.Instance { return self }
}
public extension Control {
    func uiControl() -> Control.Instance { return instance() }
}

// MARK: - Binder Part 8: Downcast protocols
public protocol ControlBinding: ViewBinding {
    static func controlBinding(_ binding: Control.Binding) -> Self
    func asControlBinding() -> Control.Binding?
}
public extension ControlBinding {
    static func viewBinding(_ binding: View.Binding) -> Self {
        return controlBinding(.inheritedBinding(binding))
    }
}
public extension ControlBinding where Preparer.Inherited.Binding: ControlBinding {
    func asControlBinding() -> Control.Binding? {
        return asInheritedBinding()?.asControlBinding()
    }
}
public extension Control.Binding {
    typealias Preparer = Control.Preparer
    func asInheritedBinding() -> Preparer.Inherited.Binding? { if case .inheritedBinding(let b) = self { return b } else { return nil } }
    func asControlBinding() -> Control.Binding? { return self }
    static func controlBinding(_ binding: Control.Binding) -> Control.Binding {
        return binding
    }
}

// MARK: - Binder Part 9: Other supporting types
public enum ControlAction {
    case firstResponder(Selector)
    case singleTarget(SignalInput<(control: UIControl, event: UIEvent)>)
}

public typealias ControlActions = ScopedValues<UIControl.Event, ControlAction>

extension ScopedValues where Scope == UIControl.State {
    public static func normal(_ value: Value) -> ScopedValues<Scope, Value> {
        return .value(value, for: .normal)
    }
    public static func highlighted(_ value: Value) -> ScopedValues<Scope, Value> {
        return .value(value, for: .highlighted)
    }
    public static func disabled(_ value: Value) -> ScopedValues<Scope, Value> {
        return .value(value, for: .disabled)
    }
    public static func selected(_ value: Value) -> ScopedValues<Scope, Value> {
        return .value(value, for: .selected)
    }
    public static func focused(_ value: Value) -> ScopedValues<Scope, Value> {
        return .value(value, for: .focused)
    }
    public static func application(_ value: Value) -> ScopedValues<Scope, Value> {
        return .value(value, for: .application)
    }
    public static func reserved(_ value: Value) -> ScopedValues<Scope, Value> {
        return .value(value, for: .reserved)
    }
}

open class SignalControlEventActionTarget: NSObject {
    private var signalInput: SignalInput<(control: UIControl, event: UIEvent)>? = nil
    
    // Ownership note: we are owned by the output signal so we only weakly retain it.
    private weak var signalOutput: SignalMulti<(control: UIControl, event: UIEvent)>? = nil
    
    /// The `signal` emits the actions received
    public var source: SignalMulti<(control: UIControl, event: UIEvent)> {
        // If there's a current signal output, return it
        if let so = signalOutput {
            return so
        }
        
        let s = Signal<(control: UIControl, event: UIEvent)>.generate { i in self.signalInput = i }.continuous()
        self.signalOutput = s
        return s
    }
    
    /// Receiver function for the target-action events
    ///
    /// - Parameter sender: typical target-action "sender" parameter
    @IBAction public func cwlSendAction(_ sender: UIControl, forEvent event: UIEvent) {
        _ = signalInput?.send(value: (sender, event))
    }
    
    /// Convenience accessor for `#selector(SignalActionTarget<Value>.action(_:))`
    public var selector: Selector { return #selector(SignalControlEventActionTarget.cwlSendAction(_:forEvent:)) }
}

// MARK: - Binder Part 1: Binder
public class ExtendedView<Subclass: Layout.View & ViewWithDelegate & HasDelegate>: Binder, ViewConvertible {
    public var state: BinderState<Preparer>
    public required init(type: Preparer.Instance.Type, parameters: Preparer.Parameters, bindings: [Preparer.Binding]) {
        state = .pending(type: type, parameters: parameters, bindings: bindings)
    }
}

extension ExtendedView where Subclass == CwlExtendedView {
    public convenience init(bindings: [Preparer.Binding]) {
        self.init(type: CwlExtendedView.self, parameters: (), bindings: bindings)
    }
    
    public convenience init(_ bindings: Preparer.Binding...) {
        self.init(type: CwlExtendedView.self, parameters: (), bindings: bindings)
    }
}

// MARK: - Binder Part 2: Binding
public extension ExtendedView {
    enum Binding: ExtendedViewBinding {
        case inheritedBinding(Preparer.Inherited.Binding)
        
        // 0. Static bindings are applied at construction and are subsequently immutable.
        
        // 1. Value bindings may be applied at construction and may subsequently change.
        @available(macOS 10.10, *) @available(iOS, unavailable) case backgroundColor(Dynamic<NSColor?>)
        
        // 2. Signal bindings are performed on the object after construction.
        
        // 3. Action bindings are triggered by the object after construction.
        case sizeDidChange(SignalInput<CGSize>)
        
        // 4. Delegate bindings require synchronous evaluation within the object's context.
    }
    
    #if os(macOS)
    typealias NSColor = AppKit.NSColor
    #else
    typealias NSColor = ()
    #endif
}

// MARK: - Binder Part 3: Preparer
public extension ExtendedView {
    struct Preparer: BinderDelegateEmbedderConstructor {
        public typealias Binding = ExtendedView.Binding
        public typealias Inherited = View.Preparer
        public typealias Instance = Subclass
        
        public var inherited = Inherited()
        public var dynamicDelegate: Delegate? = nil
        public let delegateClass: Delegate.Type
        public init(delegateClass: Delegate.Type) {
            self.delegateClass = delegateClass
        }
        
        public func constructStorage(instance: Instance) -> Storage { return Storage() }
        public func inheritedBinding(from: Binding) -> Inherited.Binding? {
            if case .inheritedBinding(let b) = from { return b } else { return nil }
        }
    }
}

// MARK: - Binder Part 4: Preparer overrides
public extension ExtendedView.Preparer {
    mutating func prepareBinding(_ binding: Binding) {
        switch binding {
        case .inheritedBinding(let x): inherited.prepareBinding(x)
        case .sizeDidChange(let x): delegate().addMultiHandler1({ s in x.send(value: s) }, #selector(ViewDelegate.layoutSubviews(view:)))
        default: break
        }
    }
    
    func applyBinding(_ binding: Binding, instance: Instance, storage: Storage) -> Lifetime? {
        switch binding {
        case .inheritedBinding(let x): return inherited.applyBinding(x, instance: instance, storage: storage)
            
        case .backgroundColor(let x):
            return x.apply(instance) { i, v in
                #if os(macOS)
                i.backgroundColor = v
                #endif
            }
        case .sizeDidChange: return nil
        }
    }
}

// MARK: - Binder Part 5: Storage and Delegate
extension ExtendedView.Preparer {
    open class Storage: View.Preparer.Storage, ViewDelegate {}
    
    open class Delegate: DynamicDelegate, ViewDelegate {
        open func layoutSubviews(view: Layout.View) {
            multiHandler(view.bounds.size)
        }
    }
}

// MARK: - Binder Part 6: BindingNames
extension BindingName where Binding: ExtendedViewBinding {
    public typealias ExtendedViewName<V> = BindingName<V, ExtendedView<Binding.SubclassType>.Binding, Binding>
    private static func name<V>(_ source: @escaping (V) -> ExtendedView<Binding.SubclassType>.Binding) -> ExtendedViewName<V> {
        return ExtendedViewName<V>(source: source, downcast: Binding.extendedViewBinding)
    }
}
public extension BindingName where Binding: ExtendedViewBinding {
    // You can easily convert the `Binding` cases to `BindingName` using the following Xcode-style regex:
    // Replace: case ([^\(]+)\((.+)\)$
    // With:    static var $1: ExtendedViewName<$2> { return .name(ExtendedView.Binding.$1) }
    
    // 0. Static bindings are applied at construction and are subsequently immutable.
    
    // 1. Value bindings may be applied at construction and may subsequently change.
    #if os(macOS)
    static var backgroundColor: ExtendedViewName<Dynamic<NSColor?>> { return .name(ExtendedView.Binding.backgroundColor) }
    #endif
    
    // 2. Signal bindings are performed on the object after construction.
    
    // 3. Action bindings are triggered by the object after construction.
    static var sizeDidChange: ExtendedViewName<SignalInput<CGSize>> { return .name(ExtendedView.Binding.sizeDidChange) }
    
    // 4. Delegate bindings require synchronous evaluation within the object's context.
}

// MARK: - Binder Part 7: Convertible protocols (if constructible)
public extension ExtendedView {
    #if os(iOS)
    func uiView() -> View.Instance { return instance() }
    #elseif os(macOS)
    func nsView() -> View.Instance { return instance() }
    #endif
}

// MARK: - Binder Part 8: Downcast protocols
public protocol ExtendedViewBinding: ViewBinding {
    associatedtype SubclassType: Layout.View & ViewWithDelegate & HasDelegate
    static func extendedViewBinding(_ binding: ExtendedView<SubclassType>.Binding) -> Self
    func asExtendedViewBinding() -> ExtendedView<SubclassType>.Binding?
}
public extension ExtendedViewBinding {
    static func viewBinding(_ binding: View.Binding) -> Self {
        return extendedViewBinding(.inheritedBinding(binding))
    }
}
public extension ExtendedViewBinding where Preparer.Inherited.Binding: ExtendedViewBinding, Preparer.Inherited.Binding.SubclassType == SubclassType {
    func asExtendedViewBinding() -> ExtendedView<SubclassType>.Binding? {
        return asInheritedBinding()?.asExtendedViewBinding()
    }
}
public extension ExtendedView.Binding {
    typealias Preparer = ExtendedView.Preparer
    func asInheritedBinding() -> Preparer.Inherited.Binding? { if case .inheritedBinding(let b) = self { return b } else { return nil } }
    func asExtendedViewBinding() -> ExtendedView.Binding? { return self }
    static func extendedViewBinding(_ binding: ExtendedView.Binding) -> ExtendedView.Binding {
        return binding
    }
}

// MARK: - Binder Part 9: Other supporting types
@objc public protocol ViewDelegate: class {
    @objc optional func layoutSubviews(view: Layout.View)
}

public protocol ViewWithDelegate: class {
    var delegate: ViewDelegate? { get set }
    
    #if os(macOS)
    var backgroundColor: NSColor? { get set }
    #endif
}

#if os(macOS)
extension ViewWithDelegate {
    // This default implementation is so that you're not required to implement `backgroundColor` to implement an ExtendedView
    var backgroundColor: NSColor? {
        get {
            return ((self as? NSView)?.layer?.backgroundColor).flatMap { NSColor(cgColor: $0) }
        }
        set {
            if let layer = (self as? NSView)?.layer {
                layer.backgroundColor = newValue?.cgColor 
            }
        }
    }
}
#endif

/// Implementation of ViewWithDelegate on top of the base UIView.
/// You can use this view directly, subclass it or implement `ViewWithDelegate` and `HasDelegate` on top of another `UIView` to use that view with the `ExtendedView` binder.
open class CwlExtendedView: Layout.View, ViewWithDelegate, HasDelegate {
    public unowned var delegate: ViewDelegate?
    
    #if os(macOS)
    open var backgroundColor: NSColor?
    
    open override func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)
        
        if let backgroundColor = backgroundColor {
            backgroundColor.setFill()
            dirtyRect.fill()
        }
    }
    #endif
    
    #if os(iOS)
    open override func layoutSubviews() {
        delegate?.layoutSubviews?(view: self)
        super.layoutSubviews()
    }
    #elseif os(macOS)
    open override func layout() {
        delegate?.layoutSubviews?(view: self)
        super.layout()
    }
    #endif
}

// MARK: - Binder Part 1: Binder
public class GradientLayer: Binder, GradientLayerConvertible {
    public var state: BinderState<Preparer>
    public required init(type: Preparer.Instance.Type, parameters: Preparer.Parameters, bindings: [Preparer.Binding]) {
        state = .pending(type: type, parameters: parameters, bindings: bindings)
    }
}

// MARK: - Binder Part 2: Binding
public extension GradientLayer {
    enum Binding: GradientLayerBinding {
        case inheritedBinding(Preparer.Inherited.Binding)
        
        //    0. Static bindings are applied at construction and are subsequently immutable.
        
        //    1. Value bindings may be applied at construction and may subsequently change.
        case colors(Dynamic<[CGColor]>)
        case locations(Dynamic<[CGFloat]>)
        case endPoint(Dynamic<CGPoint>)
        case startPoint(Dynamic<CGPoint>)
        
        // 2. Signal bindings are performed on the object after construction.
        
        // 3. Action bindings are triggered by the object after construction.
        
        // 4. Delegate bindings require synchronous evaluation within the object's context.
    }
}

// MARK: - Binder Part 3: Preparer
public extension GradientLayer {
    struct Preparer: BinderDelegateDerived {
        public typealias Binding = GradientLayer.Binding
        public typealias Delegate = Inherited.Delegate
        public typealias Inherited = Layer.Preparer
        public typealias Instance = CAGradientLayer
        
        public var inherited: Inherited
        public init(delegateClass: Delegate.Type) {
            inherited = Inherited(delegateClass: delegateClass)
        }
        public func constructStorage(instance: Instance) -> Storage { return Storage() }
        public func inheritedBinding(from: Binding) -> Inherited.Binding? {
            if case .inheritedBinding(let b) = from { return b } else { return nil }
        }
    }
}

// MARK: - Binder Part 4: Preparer overrides
public extension GradientLayer.Preparer {
    func applyBinding(_ binding: Binding, instance: Instance, storage: Storage) -> Lifetime? {
        switch binding {
        case .inheritedBinding(let x): return inherited.applyBinding(x, instance: instance, storage: storage)
            
            //    0. Static bindings are applied at construction and are subsequently immutable.
            
        //    1. Value bindings may be applied at construction and may subsequently change.
        case .colors(let x): return x.apply(instance) { i, v in i.colors = v }
        case .locations(let x): return x.apply(instance) { i, v in i.locations = v.map { NSNumber(value: Double($0)) } }
        case .endPoint(let x): return x.apply(instance) { i, v in i.endPoint = v }
        case .startPoint(let x): return x.apply(instance) { i, v in i.startPoint = v }
            
            // 2. Signal bindings are performed on the object after construction.
            
            // 3. Action bindings are triggered by the object after construction.
            
            // 4. Delegate bindings require synchronous evaluation within the object's context.
        }
    }
}

// MARK: - Binder Part 5: Storage and Delegate
extension GradientLayer.Preparer {
    public typealias Storage = Layer.Preparer.Storage
}

// MARK: - Binder Part 6: BindingNames
extension BindingName where Binding: GradientLayerBinding {
    public typealias GradientLayerName<V> = BindingName<V, GradientLayer.Binding, Binding>
    private static func name<V>(_ source: @escaping (V) -> GradientLayer.Binding) -> GradientLayerName<V> {
        return GradientLayerName<V>(source: source, downcast: Binding.gradientLayerBinding)
    }
}
public extension BindingName where Binding: GradientLayerBinding {
    // You can easily convert the `Binding` cases to `BindingName` using the following Xcode-style regex:
    // Replace: case ([^\(]+)\((.+)\)$
    // With:    static var $1: GradientLayerName<$2> { return .name(GradientLayer.Binding.$1) }
    
    //    0. Static bindings are applied at construction and are subsequently immutable.
    
    //    1. Value bindings may be applied at construction and may subsequently change.
    static var colors: GradientLayerName<Dynamic<[CGColor]>> { return .name(GradientLayer.Binding.colors) }
    static var locations: GradientLayerName<Dynamic<[CGFloat]>> { return .name(GradientLayer.Binding.locations) }
    static var endPoint: GradientLayerName<Dynamic<CGPoint>> { return .name(GradientLayer.Binding.endPoint) }
    static var startPoint: GradientLayerName<Dynamic<CGPoint>> { return .name(GradientLayer.Binding.startPoint) }
    
    // 2. Signal bindings are performed on the object after construction.
    
    // 3. Action bindings are triggered by the object after construction.
    
    // 4. Delegate bindings require synchronous evaluation within the object's context.
}

// MARK: - Binder Part 7: Convertible protocols (if constructible)
public protocol GradientLayerConvertible: LayerConvertible {
    func caGradientLayer() -> GradientLayer.Instance
}
public extension GradientLayerConvertible {
    func caLayer() -> Layer.Instance { return caGradientLayer() }
}
extension CAGradientLayer: GradientLayerConvertible {
    public func caGradientLayer() -> GradientLayer.Instance { return self }
}
public extension GradientLayer {
    func caGradientLayer() -> GradientLayer.Instance { return instance() }
}

// MARK: - Binder Part 8: Downcast protocols
public protocol GradientLayerBinding: LayerBinding {
    static func gradientLayerBinding(_ binding: GradientLayer.Binding) -> Self
    func asGradientLayerBinding() -> GradientLayer.Binding?
}
public extension GradientLayerBinding {
    static func layerBinding(_ binding: Layer.Binding) -> Self {
        return gradientLayerBinding(.inheritedBinding(binding))
    }
}
public extension GradientLayerBinding where Preparer.Inherited.Binding: GradientLayerBinding {
    func asGradientLayerBinding() -> GradientLayer.Binding? {
        return asInheritedBinding()?.asGradientLayerBinding()
    }
}
public extension GradientLayer.Binding {
    typealias Preparer = GradientLayer.Preparer
    func asInheritedBinding() -> Preparer.Inherited.Binding? { if case .inheritedBinding(let b) = self { return b } else { return nil } }
    func asGradientLayerBinding() -> GradientLayer.Binding? { return self }
    static func gradientLayerBinding(_ binding: GradientLayer.Binding) -> GradientLayer.Binding {
        return binding
    }
}

// MARK: - Binder Part 9: Other supporting types

// MARK: - Binder Part 1: Binder
public class StackView: Binder, StackViewConvertible {
    #if os(macOS)
    public typealias NSUIView = NSView
    public typealias NSUIStackView = NSStackView
    public typealias NSUIStackViewDistribution = NSStackView.Distribution
    public typealias NSUIStackViewAlignment = NSLayoutConstraint.Attribute
    public typealias NSUIUserInterfaceLayoutOrientation = NSUserInterfaceLayoutOrientation
    public typealias NSUILayoutPriority = NSLayoutConstraint.Priority
    #else
    public typealias NSUIView = UIView
    public typealias NSUIStackView = UIStackView
    public typealias NSUIStackViewDistribution = UIStackView.Distribution
    public typealias NSUIStackViewAlignment = UIStackView.Alignment
    public typealias NSUIUserInterfaceLayoutOrientation = NSLayoutConstraint.Axis
    public typealias NSUILayoutPriority = UILayoutPriority
    #endif
    
    public var state: BinderState<Preparer>
    public required init(type: Preparer.Instance.Type, parameters: Preparer.Parameters, bindings: [Preparer.Binding]) {
        state = .pending(type: type, parameters: parameters, bindings: bindings)
    }
}

// MARK: - Binder Part 2: Binding
public extension StackView {
    enum Binding: StackViewBinding {
        case inheritedBinding(Preparer.Inherited.Binding)
        
        //    0. Static bindings are applied at construction and are subsequently immutable.
        
        // 1. Value bindings may be applied at construction and may subsequently change.
        case alignment(Dynamic<NSUIStackViewAlignment>)
        case arrangedSubviews(Dynamic<[ViewConvertible]>)
        case axis(Dynamic<NSUIUserInterfaceLayoutOrientation>)
        case distribution(Dynamic<NSUIStackViewDistribution>)
        case spacing(Dynamic<CGFloat>)
        
        @available(macOS 10.13, *) @available(iOS, unavailable) case edgeInsets(Dynamic<NSUIEdgeInsets>)
        @available(macOS 10.13, *) @available(iOS, unavailable) case horizontalClippingResistance(Dynamic<NSUILayoutPriority>)
        @available(macOS 10.13, *) @available(iOS, unavailable) case horizontalHuggingPriority(Dynamic<NSUILayoutPriority>)
        @available(macOS, unavailable) @available(iOS 11, *) case isLayoutMarginsRelativeArrangement(Dynamic<Bool>)
        @available(macOS 10.13, *) @available(iOS, unavailable) case verticalClippingResistance(Dynamic<NSUILayoutPriority>)
        @available(macOS 10.13, *) @available(iOS, unavailable) case verticalHuggingPriority(Dynamic<NSUILayoutPriority>)
        
        // 2. Signal bindings are performed on the object after construction.
        
        // 3. Action bindings are triggered by the object after construction.
        
        // 4. Delegate bindings require synchronous evaluation within the object's context.
    }
    
    #if os(macOS)
    typealias NSUIEdgeInsets = NSEdgeInsets
    #else
    typealias NSUIEdgeInsets = UIEdgeInsets
    #endif
}

// MARK: - Binder Part 3: Preparer
public extension StackView {
    struct Preparer: BinderEmbedderConstructor {
        public typealias Binding = StackView.Binding
        public typealias Inherited = View.Preparer
        public typealias Instance = NSUIStackView
        
        public var inherited = Inherited()
        public init() {}
        public func constructStorage(instance: Instance) -> Storage { return Storage() }
        public func inheritedBinding(from: Binding) -> Inherited.Binding? {
            if case .inheritedBinding(let b) = from { return b } else { return nil }
        }
    }
}

// MARK: - Binder Part 4: Preparer overrides
public extension StackView.Preparer {
    func applyBinding(_ binding: Binding, instance: Instance, storage: Storage) -> Lifetime? {
        switch binding {
        case .inheritedBinding(let x): return inherited.applyBinding(x, instance: instance, storage: storage)
            
            //    0. Static bindings are applied at construction and are subsequently immutable.
            
        // 1. Value bindings may be applied at construction and may subsequently change.
        case .alignment(let x): return x.apply(instance) { i, v in i.alignment = v }
        case .axis(let x):
            return x.apply(instance) { i, v in
                #if os(macOS)
                i.orientation = v
                #else
                i.axis = v
                #endif
            }
        case .arrangedSubviews(let x):
            return x.apply(instance) { i, v in
                i.arrangedSubviews.forEach { $0.removeFromSuperview() }
                #if os(macOS)
                v.forEach { i.addArrangedSubview($0.nsView()) }
                #else
                v.forEach { i.addArrangedSubview($0.uiView()) }
                #endif
            }
        case .distribution(let x): return x.apply(instance) { i, v in i.distribution = v }
        case .spacing(let x): return x.apply(instance) { i, v in i.spacing = v }
            
        case .edgeInsets(let x):
            #if os(macOS)
            return x.apply(instance) { i, v in i.edgeInsets = v }
            #else
            return nil
            #endif
        case .horizontalClippingResistance(let x):
            #if os(macOS)
            return x.apply(instance) { i, v in i.setClippingResistancePriority(v, for: .horizontal) }
            #else
            return nil
            #endif
        case .horizontalHuggingPriority(let x):
            #if os(macOS)
            return x.apply(instance) { i, v in i.setHuggingPriority(v, for: .horizontal) }
            #else
            return nil
            #endif
        case .isLayoutMarginsRelativeArrangement(let x):
            #if os(macOS)
            return nil
            #else
            return x.apply(instance) { i, v in i.isLayoutMarginsRelativeArrangement = v }
            #endif
        case .verticalClippingResistance(let x):
            #if os(macOS)
            return x.apply(instance) { i, v in i.setClippingResistancePriority(v, for: .vertical) }
            #else
            return nil
            #endif
        case .verticalHuggingPriority(let x):
            #if os(macOS)
            return x.apply(instance) { i, v in i.setHuggingPriority(v, for: .vertical) }
            #else
            return nil
            #endif
            
            // 2. Signal bindings are performed on the object after construction.
            
            // 3. Action bindings are triggered by the object after construction.
            
            // 4. Delegate bindings require synchronous evaluation within the object's context.
        }
    }
}

// MARK: - Binder Part 5: Storage and Delegate
extension StackView.Preparer {
    #if os(macOS)
    open class Storage: View.Preparer.Storage {
        open var gravity: NSStackView.Gravity = .center
    }
    #else
    public typealias Storage = View.Preparer.Storage
    #endif
}

// MARK: - Binder Part 6: BindingNames
extension BindingName where Binding: StackViewBinding {
    public typealias StackViewName<V> = BindingName<V, StackView.Binding, Binding>
    private static func name<V>(_ source: @escaping (V) -> StackView.Binding) -> StackViewName<V> {
        return StackViewName<V>(source: source, downcast: Binding.stackViewBinding)
    }
}
public extension BindingName where Binding: StackViewBinding {
    // You can easily convert the `Binding` cases to `BindingName` using the following Xcode-style regex:
    // Replace: case ([^\(]+)\((.+)\)$
    // With:    static var $1: StackViewName<$2> { return .name(StackView.Binding.$1) }
    
    //    0. Static bindings are applied at construction and are subsequently immutable.
    
    // 1. Value bindings may be applied at construction and may subsequently change.
    static var alignment: StackViewName<Dynamic<StackView.NSUIStackViewAlignment>> { return .name(StackView.Binding.alignment) }
    static var arrangedSubviews: StackViewName<Dynamic<[ViewConvertible]>> { return .name(StackView.Binding.arrangedSubviews) }
    static var axis: StackViewName<Dynamic<StackView.NSUIUserInterfaceLayoutOrientation>> { return .name(StackView.Binding.axis) }
    static var distribution: StackViewName<Dynamic<StackView.NSUIStackViewDistribution>> { return .name(StackView.Binding.distribution) }
    static var spacing: StackViewName<Dynamic<CGFloat>> { return .name(StackView.Binding.spacing) }
    
    @available(macOS 10.13, *) @available(iOS, unavailable) static var edgeInsets: StackViewName<Dynamic<StackView.NSUIEdgeInsets>> { return .name(StackView.Binding.edgeInsets) }
    @available(macOS 10.13, *) @available(iOS, unavailable) static var horizontalClippingResistance: StackViewName<Dynamic<StackView.NSUILayoutPriority>> { return .name(StackView.Binding.horizontalClippingResistance) }
    @available(macOS 10.13, *) @available(iOS, unavailable) static var horizontalHuggingPriority: StackViewName<Dynamic<StackView.NSUILayoutPriority>> { return .name(StackView.Binding.horizontalHuggingPriority) }
    @available(macOS, unavailable) @available(iOS 11, *) static var isLayoutMarginsRelativeArrangement: StackViewName<Dynamic<Bool>> { return .name(StackView.Binding.isLayoutMarginsRelativeArrangement) }
    @available(macOS 10.13, *) @available(iOS, unavailable) static var verticalClippingResistance: StackViewName<Dynamic<StackView.NSUILayoutPriority>> { return .name(StackView.Binding.verticalClippingResistance) }
    @available(macOS 10.13, *) @available(iOS, unavailable) static var verticalHuggingPriority: StackViewName<Dynamic<StackView.NSUILayoutPriority>> { return .name(StackView.Binding.verticalHuggingPriority) }
    
    // 2. Signal bindings are performed on the object after construction.
    
    // 3. Action bindings are triggered by the object after construction.
    
    // 4. Delegate bindings require synchronous evaluation within the object's context.
}

// MARK: - Binder Part 7: Convertible protocols (if constructible)
#if os(macOS)
public protocol StackViewConvertible: ViewConvertible {
    func nsStackView() -> StackView.Instance
}
public extension StackViewConvertible {
    func nsView() -> View.Instance { return nsStackView() }
}
extension NSStackView: StackViewConvertible {
    public func nsStackView() -> StackView.Instance { return self }
}
public extension StackView {
    func nsStackView() -> StackView.Instance { return instance() }
}
#else
public protocol StackViewConvertible: ViewConvertible {
    func uiStackView() -> StackView.Instance
}
public extension StackViewConvertible {
    func uiView() -> View.Instance { return uiStackView() }
}
extension UIStackView: StackViewConvertible {
    public func uiStackView() -> StackView.Instance { return self }
}
public extension StackView {
    func uiStackView() -> StackView.Instance { return instance() }
}
#endif

// MARK: - Binder Part 8: Downcast protocols
public protocol StackViewBinding: ViewBinding {
    static func stackViewBinding(_ binding: StackView.Binding) -> Self
    func asStackViewBinding() -> StackView.Binding?
}
public extension StackViewBinding {
    static func viewBinding(_ binding: View.Binding) -> Self {
        return stackViewBinding(.inheritedBinding(binding))
    }
}
public extension StackViewBinding where Preparer.Inherited.Binding: StackViewBinding {
    func asStackViewBinding() -> StackView.Binding? {
        return asInheritedBinding()?.asStackViewBinding()
    }
}
public extension StackView.Binding {
    typealias Preparer = StackView.Preparer
    func asInheritedBinding() -> Preparer.Inherited.Binding? { if case .inheritedBinding(let b) = self { return b } else { return nil } }
    func asStackViewBinding() -> StackView.Binding? { return self }
    static func stackViewBinding(_ binding: StackView.Binding) -> StackView.Binding {
        return binding
    }
}

