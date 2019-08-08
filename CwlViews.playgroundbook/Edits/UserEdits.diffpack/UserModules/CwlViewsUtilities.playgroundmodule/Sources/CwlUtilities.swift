
import CwlCore
import CwlSignals
import CwlViewsCore
import UIKit

/// A value abstraction of the arguments to some AppKit/UIKit methods with a `setValue(_:,animated:)` structure.
public struct Animatable<Value, AnimationType> {
    public let value: Value
    public let animation: AnimationType?
    
    public static func set(_ value: Value) -> Animatable<Value, AnimationType> {
        return Animatable<Value, AnimationType>(value: value, animation: nil)
    }
    public static func animate(_ value: Value, animation: AnimationType) -> Animatable<Value, AnimationType> {
        return Animatable<Value, AnimationType>(value: value, animation: animation)
    }
    
    public var isAnimated: Bool {
        return animation != nil
    }
}

public typealias SetOrAnimate<Value> = Animatable<Value, ()>

extension Animatable where AnimationType == () {
    public static func animate(_ value: Value) -> Animatable<Value, AnimationType> {
        return Animatable<Value, AnimationType>(value: value, animation: ())
    }
}

public extension BindingName {
    static func --<A, AnimationType>(name: BindingName<Value, Source, Binding>, value: A) -> Binding where Dynamic<Animatable<A, AnimationType>> == Value {
        return name.binding(with: Value.constant(.set(value)))
    }
    
}

public enum AnimationChoice {
    case never
    case subsequent
    case always
}

extension SignalInterface {
    public func animate(_ choice: AnimationChoice = .subsequent) -> Signal<Animatable<OutputValue, ()>> {
        return map(initialState: false) { (alreadyReceived: inout Bool, value: OutputValue) in
            if alreadyReceived || choice == .always {
                return .animate(value)
            } else {
                if choice == .subsequent {
                    alreadyReceived = true
                }
                return .set(value)
            }
        }
    }
    
    public func animate(_ choice: AnimationChoice = .subsequent) -> Signal<Animatable<OutputValue?, ()>> {
        return map(initialState: false) { (alreadyReceived: inout Bool, value: OutputValue) in
            if alreadyReceived || choice == .always {
                return .animate(value)
            } else {
                if choice == .subsequent {
                    alreadyReceived = true
                }
                return .set(value)
            }
        }
    }
}

extension Adapter {
    #if os(iOS)
    public func storeToArchive<Value>() -> (UIApplication, NSKeyedArchiver) -> Void where State == VarState<Value> {
        return { _, archiver in archiver.encodeLatest(from: self) }
    }
    #elseif os(macOS)
    public func storeToArchive<Value>() -> (NSApplication, NSCoder) -> Void where State == VarState<Value> {
        return { _, archiver in archiver.encodeLatest(from: self) }
    }
    #endif
}

extension Adapter {
    #if os(iOS)
    public func loadFromArchive<Value>() -> (UIApplication, NSKeyedUnarchiver) -> Void where State == VarState<Value> {
        return { _, unarchiver in unarchiver.decodeSend(to: self.set()) }
    }
    #elseif os(macOS)
    public func loadFromArchive<Value>() -> (NSApplication, NSCoder) -> Void where State == VarState<Value> {
        return { _, unarchiver in unarchiver.decodeSend(to: self.set()) }
    }
    #endif
}

extension NSCoder {
    /// Gets the latest value from the signal and encodes the value as JSON data into self using the provided key
    ///
    /// - Parameters:
    ///   - interface: exposes the signal
    ///   - forKey: key used for encoding (is `String.viewStateKey` by default)
    public func encodeLatest<Interface>(from interface: Interface, forKey: String = .viewStateKey) where Interface: SignalInterface, Interface.OutputValue: Codable {
        if let data = try? JSONEncoder().encode(interface.peek()) {
            _ = self.encode(data, forKey: forKey)
        }
    }
}

extension NSCoder {
    /// Decodes the JSON data in self, associated with the provided key, and sends into the signal input.
    ///
    /// NOTE: this function does not send errors.
    ///
    /// - Parameters:
    ///   - inputInterface: exposes the signal input
    ///   - forKey: key used for decoding (is `String.viewStateKey` by default)
    public func decodeSend<InputInterface>(to inputInterface: InputInterface, forKey: String = .viewStateKey) where InputInterface: SignalInputInterface, InputInterface.InputValue: Codable {
        if let data = self.decodeObject(forKey: forKey) as? Data, let value = try? JSONDecoder().decode(InputInterface.InputValue.self, from: data) {
            inputInterface.input.send(value: value)
        }
    }
}

public extension String {
    static let viewStateKey = "viewStateData"
}

extension UIImage {
    public static func drawn(width: CGFloat, height: CGFloat, _ function: (CGContext, CGRect) -> Void) -> UIImage {
        let size = CGSize(width: width, height: height)
        UIGraphicsBeginImageContextWithOptions(size, false, 0.0)
        if let graphicsContext = UIGraphicsGetCurrentContext() {
            function(graphicsContext, CGRect(origin: .zero, size: size))
        }
        let rectangleImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return rectangleImage ?? UIImage()
    }
}

extension NSKeyValueObservation: Lifetime {
    public func cancel() {
        self.invalidate()
    }
}

#if os(macOS)
import AppKit

public protocol ViewConvertible {
    func nsView() -> Layout.View
}
extension Layout.View: ViewConvertible {
    public func nsView() -> Layout.View {
        return self
    }
}
#else
import UIKit

public protocol ViewConvertible {
    func uiView() -> Layout.View
}
extension Layout.View: ViewConvertible {
    public func uiView() -> Layout.View {
        return self
    }
}
#endif

#if os(iOS)
// This type handles a combination of `layoutMargin` and `safeAreaMargin` inset edges. If a `safeArea` edge is specified, it will be used instead of `layout` edge.
public struct MarginEdges: OptionSet {
    public static var none: MarginEdges { return MarginEdges(rawValue: 0) }
    public static var topLayout: MarginEdges { return MarginEdges(rawValue: 1) }
    public static var leadingLayout: MarginEdges { return MarginEdges(rawValue: 2) }
    public static var bottomLayout: MarginEdges { return MarginEdges(rawValue: 4) }
    public static var trailingLayout: MarginEdges { return MarginEdges(rawValue: 8) }
    public static var topSafeArea: MarginEdges { return MarginEdges(rawValue: 16) }
    public static var leadingSafeArea: MarginEdges { return MarginEdges(rawValue: 32) }
    public static var bottomSafeArea: MarginEdges { return MarginEdges(rawValue: 64) }
    public static var trailingSafeArea: MarginEdges { return MarginEdges(rawValue: 128) }
    public static var allLayout: MarginEdges { return [.topLayout, .leadingLayout, .bottomLayout, .trailingLayout] }
    public static var allSafeArea: MarginEdges { return [.topSafeArea, .leadingSafeArea, .bottomSafeArea, .trailingSafeArea] }
    public let rawValue: UInt
    public init(rawValue: UInt) {
        self.rawValue = rawValue
    }
}
#endif

#if os(macOS)
public extension NSView {
    /// Adds the views contained by `layout` in the arrangment described by the layout to `self`.
    ///
    /// - Parameter layout: a set of views and layout descriptions
    func applyLayout(_ layout: Layout?) {
        applyLayoutToView(view: self, params: layout.map { (layout: $0, bounds: Layout.Bounds(view: self)) })
    }
}
#else
public extension UIView {
    /// Adds the views contained by `layout` in the arrangment described by the layout to `self`.
    ///
    /// - Parameter layout: a set of views and layout descriptions
    func applyLayout(_ layout: Layout?) {
        applyLayoutToView(view: self, params: layout.map { (layout: $0, bounds: Layout.Bounds(view: self, marginEdges: $0.marginEdges)) })
    }
}

public extension UIScrollView {
    /// Adds the views contained by `layout` in the arrangment described by the layout to `self`.
    ///
    /// - Parameter layout: a set of views and layout descriptions
    func applyContentLayout(_ layout: Layout?) {
        applyLayoutToView(view: self, params: layout.map { (layout: $0, bounds: Layout.Bounds(scrollView: self)) })
    }
}
#endif

/// A data structure for describing a layout as a series of nested columns and rows.
public struct Layout {
    /// A rough equivalent to UIStackViewAlignment, minus baseline cases which aren't handled
    public enum Alignment { case leading, trailing, center, fill }
    
    #if os(macOS)
    public typealias Axis = NSUserInterfaceLayoutOrientation
    public typealias View = NSView
    public typealias Guide = NSLayoutGuide
    public typealias EdgeInsets = NSEdgeInsets
    #else
    public typealias Axis = NSLayoutConstraint.Axis
    public typealias View = UIView
    public typealias Guide = UILayoutGuide
    public typealias EdgeInsets = UIEdgeInsets
    #endif
    
    /// When a layout is applied, it can animate one of three ways:
    ///
    /// - none: Do not animate layout transitions
    /// - frames: Animate frame changes for views present both before and after but do not animate added or removed views
    /// - fade: Use a fade transition for all changes
    /// - all: Animate frame changes for views present both before and after and use fade transitions for other viewa
    public struct Animation {
        public enum Style {
            case frames
            case fade
            case both
        }
        public let style: Style
        public let duration: CFTimeInterval
        public init(style: Style, duration: CFTimeInterval) {
            self.style = style
            self.duration = duration
        }
        
        public static func frames(_ duration: CFTimeInterval = 0.2) -> Animation { return Animation(style: .frames, duration: duration) }
        public static func fade(_ duration: CFTimeInterval = 0.2) -> Animation { return Animation(style: .fade, duration: duration) }
        public static func both(_ duration: CFTimeInterval = 0.2) -> Animation { return Animation(style: .both, duration: duration) }
    }
    
    
    /// Layout is either horizontal or vertical (although any element within the layout may be a layout in the perpendicular direction)
    let axis: Axis
    
    /// Within the horizontal row or vertical column, layout entities may fill, center or align-leading or align-trailing
    let align: Alignment
    
    #if os(iOS)
    /// The layout may extend to the view bounds or may be limited by the safeAreaMargins or layoutMargins. The safeArea insets supercede the layoutMargins (prior to iOS 11, safeArea is interpreted as UIViewController top/bottom layout guides when laying out within a UIViewController, otherwise it is treated as a synonym for the layoutMargins). This value has no effect on macOS.    
    let marginEdges: MarginEdges
    #endif
    
    /// When applied to the top level `Layout` passed to 'applyLayout`, then replacing an existing layout on a view, if this variable is true, after applying the new layout, `layoutIfNeeded` will be called inside a `UIView.beginAnimations`/`UIView.endAnimations` block. Has no effect when set on a child `Layout`.
    let animation: Layout.Animation?
    
    /// This is the list of views, spaces and sublayouts that will be layed out.
    var entities: [Entity]
    
    /// The default constructor assigns all values. In general, it's easier to use the `.horizontal` or `.vertical` constructor where possible.
    #if os(iOS)
    init(axis: Axis, align: Alignment = .fill, marginEdges: MarginEdges = .allSafeArea, animation: Layout.Animation? = .frames(), entities: [Entity]) {
        self.axis = axis
        self.align = align
        self.entities = entities
        self.marginEdges = marginEdges
        self.animation = animation
    }
    
    /// A convenience constructor for a horizontal layout
    public static func horizontal(align: Alignment = .fill, marginEdges: MarginEdges = .allSafeArea, animation: Layout.Animation? = .frames(), _ entities: Entity...) -> Layout {
        return .horizontal(align: align, marginEdges: marginEdges, animation: animation, entities: entities)
    }
    public static func horizontal(align: Alignment = .fill, marginEdges: MarginEdges = .allSafeArea, animation: Layout.Animation? = .frames(), entities: [Entity]) -> Layout {
        return Layout(axis: .horizontal, align: align, marginEdges: marginEdges, animation: animation, entities: entities)
    }
    
    /// A convenience constructor for a vertical layout
    public static func vertical(align: Alignment = .fill, marginEdges: MarginEdges = .allSafeArea, animation: Layout.Animation? = .frames(), _ entities: Entity...) -> Layout {
        return .vertical(align: align, marginEdges: marginEdges, animation: animation, entities: entities)
    }
    public static func vertical(align: Alignment = .fill, marginEdges: MarginEdges = .allSafeArea, animation: Layout.Animation? = .frames(), entities: [Entity]) -> Layout {
        return Layout(axis: .vertical, align: align, marginEdges: marginEdges, animation: animation, entities: entities)
    }
    
    /// A convenience constructor for a nested pair of layouts that combine to form a single centered arrangment
    public static func center(axis: Layout.Axis = .vertical, alignment: Alignment = .center, marginEdges: MarginEdges = .allSafeArea, animation: Layout.Animation? = .frames(), length: Dimension? = nil, breadth: Dimension? = .equalTo(ratio: 1.0), relativity: Size.Relativity = .independent, _ entities: Entity...) -> Layout {
        return .center(axis: axis, alignment: alignment, marginEdges: marginEdges, animation: animation, length: length, breadth: breadth, relativity: relativity, entities: entities)
    }
    public static func center(axis: Layout.Axis = .vertical, alignment: Alignment = .center, marginEdges: MarginEdges = .allSafeArea, animation: Layout.Animation? = .frames(), length: Dimension? = nil, breadth: Dimension? = .equalTo(ratio: 1.0), relativity: Size.Relativity = .independent, entities: [Entity]) -> Layout {
        switch axis {
        case .vertical:
            let v = Entity.sublayout(axis: .vertical, align: alignment, length: length, breadth: breadth, relativity: relativity, entities: entities)
            let matched = Entity.pair(
                .space(.fillRemaining),
                .space(.fillRemaining),
                separator: v
            )
            return Layout(axis: .vertical, align: .center, marginEdges: marginEdges, animation: animation, entities: [matched])
        case .horizontal:
            let h = Entity.sublayout(axis: .horizontal, align: alignment, length: length, breadth: breadth, relativity: relativity, entities: entities)
            let matched = Entity.pair(
                .space(.fillRemaining),
                .space(.fillRemaining),
                separator: h
            )
            return Layout(axis: .horizontal, align: .center, marginEdges: marginEdges, animation: animation, entities: [matched])
        @unknown default: fatalError()
        }
    }
    
    /// A convenience constructor for a vertical layout
    public static func fill(axis: Layout.Axis = .vertical, align: Alignment = .fill, marginEdges: MarginEdges = .allSafeArea, animation: Layout.Animation? = .frames(), length: Dimension? = nil, breadth: Dimension? = nil, relativity: Size.Relativity = .independent, _ view: ViewConvertible) -> Layout {
        switch axis {
        case .horizontal: return .horizontal(align: align, marginEdges: marginEdges, animation: animation, .view(length: length, breadth: breadth, relativity: relativity, view))
        case .vertical: return .vertical(align: align, marginEdges: marginEdges, animation: animation, .view(length: length, breadth: breadth, relativity: relativity, view))
        @unknown default: fatalError()
        }
    }
    #else
    init(axis: Axis, align: Alignment = .fill, animation: Layout.Animation? = .frames(), entities: [Entity]) {
        self.axis = axis
        self.align = align
        self.entities = entities
        self.animation = animation
    }
    
    /// A convenience constructor for a horizontal layout
    public static func horizontal(align: Alignment = .fill, animation: Layout.Animation? = .frames(), _ entities: Entity...) -> Layout {
        return .horizontal(align: align, animation: animation, entities: entities)
    }
    public static func horizontal(align: Alignment = .fill, animation: Layout.Animation? = .frames(), entities: [Entity]) -> Layout {
        return Layout(axis: .horizontal, align: align, animation: animation, entities: entities)
    }
    
    /// A convenience constructor for a vertical layout
    public static func vertical(align: Alignment = .fill, animation: Layout.Animation? = .frames(), _ entities: Entity...) -> Layout {
        return .vertical(align: align, animation: animation, entities: entities)
    }
    public static func vertical(align: Alignment = .fill, animation: Layout.Animation? = .frames(), entities: [Entity]) -> Layout {
        return Layout(axis: .vertical, align: align, animation: animation, entities: entities)
    }
    
    /// A convenience constructor for a nested pair of layouts that combine to form a single centered arrangment
    public static func center(axis: Layout.Axis = .vertical, alignment: Alignment = .center, animation: Layout.Animation? = .frames(), length: Dimension? = nil, breadth: Dimension? = .equalTo(ratio: 1.0), relativity: Size.Relativity = .independent, _ entities: Entity...) -> Layout {
        return .center(axis: axis, alignment: alignment, animation: animation, length: length, breadth: breadth, relativity: relativity, entities: entities)
    }
    public static func center(axis: Layout.Axis = .vertical, alignment: Alignment = .center, animation: Layout.Animation? = .frames(), length: Dimension? = nil, breadth: Dimension? = .equalTo(ratio: 1.0), relativity: Size.Relativity = .independent, entities: [Entity]) -> Layout {
        switch axis {
        case .vertical:
            let v = Entity.sublayout(axis: .vertical, align: alignment, length: length, breadth: breadth, relativity: relativity, entities: entities)
            let matched = Entity.pair(
                .space(.fillRemaining),
                .space(.fillRemaining),
                separator: v
            )
            return Layout(axis: .vertical, align: .center, animation: animation, entities: [matched])
        case .horizontal:
            let h = Entity.sublayout(axis: .horizontal, align: alignment, length: length, breadth: breadth, relativity: relativity, entities: entities)
            let matched = Entity.pair(
                .space(.fillRemaining),
                .space(.fillRemaining),
                separator: h
            )
            return Layout(axis: .horizontal, align: .center, animation: animation, entities: [matched])
        @unknown default: fatalError()
        }
    }
    
    /// A convenience constructor for a vertical layout
    public static func fill(axis: Layout.Axis = .vertical, align: Alignment = .fill, animation: Layout.Animation? = .frames(), length: Dimension? = nil, breadth: Dimension? = nil, relativity: Size.Relativity = .independent, _ view: ViewConvertible) -> Layout {
        switch axis {
        case .horizontal: return .horizontal(align: align, animation: animation, .view(length: length, breadth: breadth, relativity: relativity, view))
        case .vertical: return .vertical(align: align, animation: animation, .view(length: length, breadth: breadth, relativity: relativity, view))
        @unknown default: fatalError()
        }
    }
    
    /// A convenience constructor for a vertical layout 
    public static func inset(margins: EdgeInsets, animation: Layout.Animation? = .frames(), _ entity: Entity) -> Layout {
        return .horizontal(.space(.equalTo(constant: margins.left)), .vertical(.space(.equalTo(constant: margins.top)), entity, .space(.equalTo(constant: margins.bottom))), .space(.equalTo(constant: margins.right)))
    }
    #endif
    
    // Used for removing all views from their superviews
    func forEachView(_ visit: (View) -> Void) {
        entities.forEach { $0.forEachView(visit) }
    }
    
    // Used for finding the n-th subview, depth-first search order
    func traverse(over remaining: inout Int) -> ViewConvertible? {
        for e in entities {
            if let match = e.traverse(over: &remaining) {
                return match
            }
        }
        return nil
    }
    
    /// A linear time search for the view at a given index. Current state is intended for testing-only.
    ///
    /// - Parameter at: the view returned will be the `at`-th view encountered in a depth-first walk.
    /// - Returns: the `at`-th view encountered or `nil` if never enountered
    public func view(at: Int) -> ViewConvertible? {
        if at < 0 {
            return nil
        }
        var remaining = at
        return traverse(over: &remaining)
    }
    
    /// The `Layout` describes a series of these `Entity`s which may be a space, a view or a sublayout. There is also a special `matched` layout which allows a series of "same length" entities.
    ///
    /// - interViewSpace: AppKit and UIKit use an 8 screen unit space as the "standard" space between adjacent views.
    /// - space: an arbitrary space between views
    /// - view: a view with optional width and height (if not specified, the view will use its "intrinsic" size or will fill the available layout space)
    /// - layout: a nested layout which may be parallel or perpedicular to its container and whose size may be specified (like view)
    /// - matched: a sequence of alternating "same size" and independent entities (you can use `.space(0)` if you don't want independent entities).
    public struct Entity {
        enum Content {
            case space(Dimension)
            case sizedView(ViewConvertible, Size?)
            indirect case layout(Layout, size: Size?)
            indirect case matched(Matched)
        }
        let content: Content
        init(_ content: Content) {
            self.content = content
        }
        
        func forEachView(_ visit: (Layout.View) -> Void) {
            switch content {
            case .sizedView(let v, _):
                #if os(macOS)
                visit(v.nsView())
                #else
                visit(v.uiView())
                #endif
            case .layout(let l, _): l.forEachView(visit)
            case .matched(let matched):
                matched.first.forEachView(visit)
                matched.subsequent.forEach { element in
                    switch element {
                    case .free(let entity): entity.forEachView(visit)
                    case .dependent(let dependent): dependent.entity.forEachView(visit)
                    }
                }
            case .space: break
            }
        }
        
        func traverse(over remaining: inout Int) -> ViewConvertible? {
            switch content {
            case .sizedView(let v, _):
                if remaining == 0 {
                    return v
                } else {
                    remaining -= 1
                }
                return nil
            case .layout(let l, _):
                return l.traverse(over: &remaining)
            case .matched(let matched):
                if let v = matched.first.traverse(over: &remaining) {
                    return v
                }
                for s in matched.subsequent {
                    switch s {
                    case .free(let entity):
                        if let v = entity.traverse(over: &remaining) {
                            return v
                        }
                    case .dependent(let dependent):
                        if let v = dependent.entity.traverse(over: &remaining) {
                            return v
                        }
                    }
                }
                return nil
            case .space:
                return nil
            }
        }
        
        public static func space(_ dimension: Dimension = .standardSpace) -> Entity {
            return Entity(.space(dimension))
        }
        
        public static func view(length: Dimension? = nil, breadth: Dimension? = nil, relativity: Size.Relativity = .independent, _ view: ViewConvertible) -> Entity {
            let size = Size(length: length, breadth: breadth, relativity: relativity)
            return Entity(.sizedView(view, size))
        }
        
        public static func sublayout(axis: Axis, align: Alignment = .fill, length: Dimension? = nil, breadth: Dimension? = nil, relativity: Size.Relativity = .independent, _ entities: Entity...) -> Entity {
            let size = Size(length: length, breadth: breadth, relativity: relativity)
            #if os(iOS)
            return Entity(.layout(Layout(axis: axis, align: align, marginEdges: .none, entities: entities), size: size))
            #else
            return Entity(.layout(Layout(axis: axis, align: align, entities: entities), size: size))
            #endif
        }
        
        public static func sublayout(axis: Axis, align: Alignment = .fill, length: Dimension? = nil, breadth: Dimension? = nil, relativity: Size.Relativity = .independent, entities: [Entity]) -> Entity {
            let size = Size(length: length, breadth: breadth, relativity: relativity)
            #if os(iOS)
            return Entity(.layout(Layout(axis: axis, align: align, marginEdges: .none, entities: entities), size: size))
            #else
            return Entity(.layout(Layout(axis: axis, align: align, entities: entities), size: size))
            #endif
        }
        
        public static func horizontal(align: Alignment = .fill, length: Dimension? = nil, breadth: Dimension? = nil, relativity: Size.Relativity = .independent, _ entities: Entity...) -> Entity {
            let size = Size(length: length, breadth: breadth, relativity: relativity)
            #if os(iOS)
            return Entity(.layout(Layout(axis: .horizontal, align: align, marginEdges: .none, entities: entities), size: size))
            #else
            return Entity(.layout(Layout(axis: .horizontal, align: align, entities: entities), size: size))
            #endif
        }
        
        public static func horizontal(align: Alignment = .fill, length: Dimension? = nil, breadth: Dimension? = nil, relativity: Size.Relativity = .independent, _ entities: [Entity]) -> Entity {
            let size = Size(length: length, breadth: breadth, relativity: relativity)
            #if os(iOS)
            return Entity(.layout(Layout(axis: .horizontal, align: align, marginEdges: .none, entities: entities), size: size))
            #else
            return Entity(.layout(Layout(axis: .horizontal, align: align, entities: entities), size: size))
            #endif
        }
        
        public static func vertical(align: Alignment = .fill, length: Dimension? = nil, breadth: Dimension? = nil, relativity: Size.Relativity = .independent, _ entities: Entity...) -> Entity {
            let size = Size(length: length, breadth: breadth, relativity: relativity)
            #if os(iOS)
            return Entity(.layout(Layout(axis: .vertical, align: align, marginEdges: .none, entities: entities), size: size))
            #else
            return Entity(.layout(Layout(axis: .vertical, align: align, entities: entities), size: size))
            #endif
        }
        
        public static func vertical(align: Alignment = .fill, length: Dimension? = nil, breadth: Dimension? = nil, relativity: Size.Relativity = .independent, entities: [Entity]) -> Entity {
            let size = Size(length: length, breadth: breadth, relativity: relativity)
            #if os(iOS)
            return Entity(.layout(Layout(axis: .vertical, align: align, marginEdges: .none, entities: entities), size: size))
            #else
            return Entity(.layout(Layout(axis: .vertical, align: align, entities: entities), size: size))
            #endif
        }
        
        public static func center(axis: Layout.Axis = .vertical, alignment: Alignment = .center, animation: Layout.Animation? = .frames(), length: Dimension? = nil, breadth: Dimension? = .equalTo(ratio: 1.0), relativity: Size.Relativity = .independent, _ entities: Entity...) -> Entity {
            let size = Size(length: length, breadth: breadth, relativity: relativity)
            #if os(iOS)
            return Entity(.layout(.center(axis: axis, alignment: alignment, animation: animation, entities: entities), size: size))
            #else
            return Entity(.layout(.center(axis: axis, alignment: alignment, animation: animation, entities: entities), size: size))
            #endif
        }
        
        public static func center(axis: Layout.Axis = .vertical, alignment: Alignment = .center, animation: Layout.Animation? = .frames(), length: Dimension? = nil, breadth: Dimension? = .equalTo(ratio: 1.0), relativity: Size.Relativity = .independent, entities: [Entity]) -> Entity {
            let size = Size(length: length, breadth: breadth, relativity: relativity)
            #if os(iOS)
            return Entity(.layout(.center(axis: axis, alignment: alignment, animation: animation, entities: entities), size: size))
            #else
            return Entity(.layout(.center(axis: axis, alignment: alignment, animation: animation, entities: entities), size: size))
            #endif
        }
        
        public static func pair(_ left: Entity, _ right: Entity, separator: Entity = .space(), priority: Dimension.Priority = .required) -> Entity {
            return Entity(.matched(Matched(
                first: left,
                subsequent: [
                    .free(separator),
                    .dependent(.init(dimension: .equalTo(ratio: 1.0, priority: priority), right))
                ]
            )))
        }
        
        public static func matched(_ first: Entity, _ subsequent: Matched.Element...) -> Entity {
            return Entity(.matched(.init(first: first, subsequent: subsequent)))
        }
        
        public static func matched(_ first: Entity, subsequent: [Matched.Element]) -> Entity {
            return Entity(.matched(.init(first: first, subsequent: subsequent)))
        }
        
        public static func same(priority: Dimension.Priority = .required, _ entities: Entity...) -> Entity {
            return same(entities: entities)
        }
        
        public static func same(priority: Dimension.Priority = .required, entities: [Entity]) -> Entity {
            guard let first = entities.first else { return .space(0) }
            return Entity(.matched(.init(first: first, subsequent: entities.dropFirst().map { .same(priority: priority, $0) })))
        }
        
        public static func inset(margins: EdgeInsets, _ entity: Entity) -> Entity {
            return .horizontal(.space(.equalTo(constant: margins.left)), .vertical(.space(.equalTo(constant: margins.top)), entity, .space(.equalTo(constant: margins.bottom))), .space(.equalTo(constant: margins.right)))
        }
    }
    
    /// A `Matched` element in a layout is a first element, followed by an array of free and dependent elements. The dependent elements all have a dimension  relationship to the first element (e.g. same size).
    public struct Matched {
        public struct Dependent {
            public let dimension: Dimension
            public let entity: Entity
            public init(dimension: Dimension, _ entity: Entity) {
                self.entity = entity
                self.dimension = dimension
            }
        }
        public enum Element {
            case dependent(Dependent)
            case free(Entity)
            
            public static func same(priority: Dimension.Priority = .required, _ entity: Entity) -> Element {
                return .dependent(.init(dimension: Dimension.equalTo(ratio: 1, priority: priority), entity))
            }
        }
        public let first: Entity
        public let subsequent: [Element]
        public init(first: Entity, subsequent: [Element]) {
            self.first = first
            self.subsequent = subsequent
        }
    }
    
    /// A `Size` is the combination of both length (size of a layout object in the direction of layout) or breadth (size of a layout object perpendicular to the layout direction). If the length includes a ratio, it is relative to the parent container but the breadth can be relative to the length, allowing for specifying an aspect ratio.
    public struct Size {
        public enum Relativity {
            case independent
            case lengthRelativeToBreadth
            case breadthRelativeToLength
            
            var isLengthRelativeToBreadth: Bool {
                if case .lengthRelativeToBreadth = self { return true } else { return false }
            }
            var isBreadthRelativeToLength: Bool {
                if case .breadthRelativeToLength = self { return true } else { return false }
            }
        }
        public let length: Dimension?
        public let breadth: Dimension?
        public let relativity: Relativity
        
        public init(length: Dimension? = nil, breadth: Dimension?, relativity: Relativity = .independent) {
            self.length = length
            self.breadth = breadth
            self.relativity = relativity
        }
    }
    
    /// When length (size of a layout object in the direction of layout) or breadth (size of a layout object perpendicular to the layout direction) is specified, it can be specified:
    ///    * relative to the parent container (ratio)
    ///    * in raw screen units (constant)
    /// The greater/less than and priority can also be specified.
    public struct Dimension: ExpressibleByFloatLiteral, ExpressibleByIntegerLiteral {
        public typealias FloatLiteralType = Double
        public typealias IntegerLiteralType = Int
        
        #if os(macOS)
        public typealias Relation = NSLayoutConstraint.Relation
        public typealias Priority = NSLayoutConstraint.Priority
        #else
        public typealias Relation = NSLayoutConstraint.Relation
        public typealias Priority = UILayoutPriority
        #endif
        
        public let ratio: CGFloat
        public let constant: CGFloat
        public let relationship: Relation
        public let priority: Dimension.Priority
        public init(ratio: CGFloat = 0, constant: CGFloat = 0, relationship: Dimension.Relation = .equal, priority: Dimension.Priority = .required) {
            self.ratio = ratio
            self.constant = constant
            self.relationship = relationship
            self.priority = priority
        }
        
        public init(floatLiteral value: Double) {
            self.init(constant: CGFloat(value))
        }
        
        public init(integerLiteral value: Int) {
            self.init(constant: CGFloat(value))
        }
        
        public static func constant(_ value: CGFloat) -> Dimension {
            return Dimension(constant: value)
        }
        
        public static func ratio(_ value: CGFloat, constant: CGFloat = 0) -> Dimension {
            return Dimension(ratio: value, constant: constant)
        }
        
        public static var standardSpace = Dimension(ratio: 0, constant: 8, relationship: .equal, priority: .layoutHigh) 
        
        public static func lessThanOrEqualTo(ratio: CGFloat = 0, constant: CGFloat = 0, priority: Dimension.Priority = .required) -> Dimension {
            return Dimension(ratio: ratio, constant: constant, relationship: .lessThanOrEqual, priority: priority)
        }
        
        public static func greaterThanOrEqualTo(ratio: CGFloat = 0, constant: CGFloat = 0, priority: Dimension.Priority = .required) -> Dimension {
            return Dimension(ratio: ratio, constant: constant, relationship: .greaterThanOrEqual, priority: priority)
        }
        
        public static func equalTo(ratio: CGFloat = 0, constant: CGFloat = 0, priority: Dimension.Priority = .required) -> Dimension {
            return Dimension(ratio: ratio, constant: constant, relationship: .equal, priority: priority)
        }
        
        public static var fillRemaining: Dimension {
            return equalTo(ratio: 1, priority: .layoutMid)
        }
        
        func scaledConstraintBetween(first: NSLayoutDimension, second: NSLayoutDimension, priorityAdjustment: Int) -> NSLayoutConstraint {
            let constraint: NSLayoutConstraint
            switch relationship {
            case .equal: constraint = first.constraint(equalTo: second, multiplier: ratio, constant: constant)
            case .lessThanOrEqual: constraint = first.constraint(lessThanOrEqualTo: second, multiplier: ratio, constant: constant)
            case .greaterThanOrEqual: constraint = first.constraint(greaterThanOrEqualTo: second, multiplier: ratio, constant: constant)
            @unknown default: fatalError()
            }
            constraint.priority = adjustedPriority(priority, count: priorityAdjustment)
            constraint.isActive = true
            return constraint
        }
        
        public func scaledConstraintBetween(first: NSLayoutDimension, second: NSLayoutDimension) -> NSLayoutConstraint {
            return scaledConstraintBetween(first: first, second: second, priorityAdjustment: 0)
        }
        
        func scaledConstraintBetween(first: NSLayoutDimension, second: NSLayoutDimension, constraints: inout [NSLayoutConstraint]) {
            constraints.append(scaledConstraintBetween(first: first, second: second, priorityAdjustment: constraints.count))
        }
        
        func unscaledConstraintBetween<AnchorType>(first: NSLayoutAnchor<AnchorType>, second: NSLayoutAnchor<AnchorType>, constraints: inout [NSLayoutConstraint], reverse: Bool = false) {
            let constraint: NSLayoutConstraint
            switch (relationship, reverse) {
            case (.equal, _): constraint = first.constraint(equalTo: second, constant: reverse ? -constant: constant)
            case (.lessThanOrEqual, false), (.greaterThanOrEqual, true): constraint = first.constraint(lessThanOrEqualTo: second, constant: reverse ? -constant: constant)
            case (.greaterThanOrEqual, false), (.lessThanOrEqual, true): constraint = first.constraint(greaterThanOrEqualTo: second, constant: reverse ? -constant: constant)
            @unknown default: fatalError()
            }
            constraint.priority = adjustedPriority(priority, count: constraints.count)
            constraint.isActive = true
            constraints.append(constraint)
        }
    }
    
    /// Bounds are used internally to capture a set of guides and anchors. On the Mac, these are merely copied from a single NSLayoutGuide or an NSView. On iOS, these may be copied from a blend of UIViewController top/bottomLayoutGuides, safeAreaLayoutGuides, layoutMarginsGuides or a UIView.
    fileprivate struct Bounds {
        var leading: NSLayoutXAxisAnchor
        var top: NSLayoutYAxisAnchor
        var trailing: NSLayoutXAxisAnchor
        var bottom: NSLayoutYAxisAnchor
        var width: NSLayoutDimension
        var height: NSLayoutDimension
        var centerX: NSLayoutXAxisAnchor
        var centerY: NSLayoutYAxisAnchor
        
        init(box: Layout.Box) {
            leading = box.leadingAnchor
            top = box.topAnchor
            trailing = box.trailingAnchor
            bottom = box.bottomAnchor
            width = box.widthAnchor
            height = box.heightAnchor
            centerX = box.centerXAnchor
            centerY = box.centerYAnchor
        }
        
        #if os(iOS)
        init(scrollView: UIScrollView) {
            leading = scrollView.contentLayoutGuide.leadingAnchor
            top = scrollView.contentLayoutGuide.topAnchor
            trailing = scrollView.contentLayoutGuide.trailingAnchor
            bottom = scrollView.contentLayoutGuide.bottomAnchor
            width = scrollView.contentLayoutGuide.widthAnchor
            height = scrollView.contentLayoutGuide.heightAnchor
            centerX = scrollView.contentLayoutGuide.centerXAnchor
            centerY = scrollView.contentLayoutGuide.centerYAnchor
        }
        
        init(view: Layout.View, marginEdges: MarginEdges) {
            leading = marginEdges.contains(.leadingSafeArea) ? view.safeAreaLayoutGuide.leadingAnchor : (marginEdges.contains(.leadingLayout) ? view.layoutMarginsGuide.leadingAnchor : view.leadingAnchor)
            top = marginEdges.contains(.topSafeArea) ? view.safeAreaLayoutGuide.topAnchor : (marginEdges.contains(.topLayout) ? view.layoutMarginsGuide.topAnchor : view.topAnchor)
            trailing = marginEdges.contains(.trailingSafeArea) ? view.safeAreaLayoutGuide.trailingAnchor : (marginEdges.contains(.trailingLayout) ? view.layoutMarginsGuide.trailingAnchor : view.trailingAnchor)
            bottom = marginEdges.contains(.bottomSafeArea) ? view.safeAreaLayoutGuide.bottomAnchor : (marginEdges.contains(.bottomLayout) ? view.layoutMarginsGuide.bottomAnchor : view.bottomAnchor)
            width = (marginEdges.contains(.leadingSafeArea) && marginEdges.contains(.trailingSafeArea)) ? view.safeAreaLayoutGuide.widthAnchor : (marginEdges.contains(.leadingLayout) && marginEdges.contains(.trailingLayout) ? view.layoutMarginsGuide.widthAnchor : view.widthAnchor)
            height = (marginEdges.contains(.leadingSafeArea) && marginEdges.contains(.trailingSafeArea)) ? view.safeAreaLayoutGuide.heightAnchor : (marginEdges.contains(.leadingLayout) && marginEdges.contains(.trailingLayout) ? view.layoutMarginsGuide.heightAnchor : view.heightAnchor)
            centerX = (marginEdges.contains(.leadingSafeArea) && marginEdges.contains(.trailingSafeArea)) ? view.safeAreaLayoutGuide.centerXAnchor : (marginEdges.contains(.leadingLayout) && marginEdges.contains(.trailingLayout) ? view.layoutMarginsGuide.centerXAnchor : view.centerXAnchor)
            centerY = (marginEdges.contains(.leadingSafeArea) && marginEdges.contains(.trailingSafeArea)) ? view.safeAreaLayoutGuide.centerYAnchor : (marginEdges.contains(.leadingLayout) && marginEdges.contains(.trailingLayout) ? view.layoutMarginsGuide.centerYAnchor : view.centerYAnchor)
        }
        #else
        init(view: Layout.View) {
            leading = view.leadingAnchor
            top = view.topAnchor
            trailing = view.trailingAnchor
            bottom = view.bottomAnchor
            width = view.widthAnchor
            height = view.heightAnchor
            centerX = view.centerXAnchor
            centerY = view.centerYAnchor
        }
        #endif
    }
    
    private struct State {
        let view: View
        let storage: Storage
        
        var dimension: Dimension? = nil
        var previousEntityBounds: Bounds? = nil
        var containerBounds: Bounds
        
        init(containerBounds: Bounds, in view: View, storage: Storage) {
            self.containerBounds = containerBounds
            self.view = view
            self.storage = storage
        }
    }
    
    fileprivate class Storage: NSObject {
        let layout: Layout
        var constraints: [NSLayoutConstraint] = []
        var boxes: [Layout.Box] = []
        
        init(layout: Layout) {
            self.layout = layout
        }
    }
    
    private func twoPointConstraint<First, Second>(firstSource: NSLayoutAnchor<First>, firstTarget: NSLayoutAnchor<First>, secondSource: NSLayoutAnchor<Second>, secondTarget: NSLayoutAnchor<Second>, secondRelationLessThan: Bool? = nil, constraints: inout [NSLayoutConstraint]) {
        let first = firstSource.constraint(equalTo: firstTarget)
        first.priority = .required
        first.isActive = true
        constraints.append(first)
        
        let secondLow = secondSource.constraint(equalTo: secondTarget)
        
        var secondHigh: NSLayoutConstraint? = nil
        if secondRelationLessThan == true {
            secondHigh = secondSource.constraint(lessThanOrEqualTo: secondTarget)
        } else if secondRelationLessThan == false {
            secondHigh = secondSource.constraint(greaterThanOrEqualTo: secondTarget)
        }
        if let high = secondHigh {
            secondLow.priority = adjustedPriority(.layoutLow, count: constraints.count)
            high.priority = adjustedPriority(.layoutHigh, count: constraints.count + 1)
            high.isActive = true
            constraints.append(high)
        } else {
            secondLow.priority = adjustedPriority(.layoutHigh, count: constraints.count)
        }
        secondLow.isActive = true
        constraints.append(secondLow)
    }
    
    private func constrain(bounds: Bounds, leading: Dimension, length: Dimension?, breadth: Dimension?, relativity: Size.Relativity, state: inout State) {
        switch axis {
        case .horizontal:
            leading.unscaledConstraintBetween(first: bounds.leading, second: state.containerBounds.leading, constraints: &state.storage.constraints)
            
            if let l = length {
                l.scaledConstraintBetween(first: bounds.width, second: relativity.isLengthRelativeToBreadth ? bounds.height : state.containerBounds.width, constraints: &state.storage.constraints)
            }
            if let b = breadth {
                b.scaledConstraintBetween(first: bounds.height, second: relativity.isBreadthRelativeToLength ? bounds.width : state.containerBounds.height, constraints: &state.storage.constraints)
            }
            
            switch self.align {
            case .leading:
                twoPointConstraint(firstSource: bounds.top, firstTarget: state.containerBounds.top, secondSource: bounds.bottom, secondTarget: state.containerBounds.bottom, secondRelationLessThan: true, constraints: &state.storage.constraints)
            case .trailing:
                twoPointConstraint(firstSource: bounds.bottom, firstTarget: state.containerBounds.bottom, secondSource: bounds.top, secondTarget: state.containerBounds.top, secondRelationLessThan: false, constraints: &state.storage.constraints)
            case .center:
                twoPointConstraint(firstSource: bounds.centerY, firstTarget: state.containerBounds.centerY, secondSource: bounds.height, secondTarget: state.containerBounds.height, secondRelationLessThan: true, constraints: &state.storage.constraints)
            case .fill:
                twoPointConstraint(firstSource: bounds.top, firstTarget: state.containerBounds.top, secondSource: bounds.bottom, secondTarget: state.containerBounds.bottom, secondRelationLessThan: nil, constraints: &state.storage.constraints)
            }
            
            state.containerBounds.leading = bounds.trailing
        case .vertical:
            leading.unscaledConstraintBetween(first: bounds.top, second: state.containerBounds.top, constraints: &state.storage.constraints)
            
            if let l = length {
                l.scaledConstraintBetween(first: bounds.height, second: relativity.isLengthRelativeToBreadth ? bounds.width : state.containerBounds.height, constraints: &state.storage.constraints)
            }
            
            if let b = breadth {
                b.scaledConstraintBetween(first: bounds.width, second: relativity.isBreadthRelativeToLength ? bounds.height : state.containerBounds.width, constraints: &state.storage.constraints)
            }
            
            switch self.align {
            case .leading:
                twoPointConstraint(firstSource: bounds.leading, firstTarget: state.containerBounds.leading, secondSource: bounds.trailing, secondTarget: state.containerBounds.trailing, secondRelationLessThan: true, constraints: &state.storage.constraints)
            case .trailing:
                twoPointConstraint(firstSource: bounds.trailing, firstTarget: state.containerBounds.trailing, secondSource: bounds.leading, secondTarget: state.containerBounds.leading, secondRelationLessThan: false, constraints: &state.storage.constraints)
            case .center:
                twoPointConstraint(firstSource: bounds.centerX, firstTarget: state.containerBounds.centerX, secondSource: bounds.width, secondTarget: state.containerBounds.width, secondRelationLessThan: true, constraints: &state.storage.constraints)
            case .fill:
                twoPointConstraint(firstSource: bounds.leading, firstTarget: state.containerBounds.leading, secondSource: bounds.trailing, secondTarget: state.containerBounds.trailing, secondRelationLessThan: nil, constraints: &state.storage.constraints)
            }
            
            state.containerBounds.top = bounds.bottom
        @unknown default:    fatalError()
        }
    }
    
    @discardableResult
    private func layout(entity: Entity, state: inout State, needDimensionAnchor: Bool = false) -> NSLayoutDimension? {
        switch entity.content {
        case .space(let dimension):
            if let d = state.dimension, (d.ratio != 0 || d.constant != 0) {
                let box = Layout.Box()
                state.view.addLayoutBox(box)
                state.storage.boxes.append(box)
                constrain(bounds: Bounds(box: box), leading: Dimension(), length: d, breadth: nil, relativity: .independent, state: &state)
                state.previousEntityBounds = nil
            }
            if dimension.ratio != 0 || needDimensionAnchor {
                let box = Layout.Box()
                state.view.addLayoutBox(box)
                state.storage.boxes.append(box)
                constrain(bounds: Bounds(box: box), leading: Dimension(), length: dimension, breadth: nil, relativity: .independent, state: &state)
                state.previousEntityBounds = Bounds(box: box)
                return axis == .horizontal ? box.widthAnchor : box.heightAnchor
            }
            state.dimension = dimension
            return nil
        case .layout(let l, let size):
            let box = Layout.Box()
            state.view.addLayoutBox(box)
            state.storage.boxes.append(box)
            let bounds = Bounds(box: box)
            l.add(to: state.view, containerBounds: bounds, storage: state.storage)
            constrain(bounds: bounds, leading: state.dimension ?? Dimension(), length: size?.length, breadth: size?.breadth, relativity: size?.relativity ?? .independent, state: &state)
            state.dimension = nil
            state.previousEntityBounds = bounds
            return needDimensionAnchor ? (axis == .horizontal ? box.widthAnchor : box.heightAnchor) : nil
        case .matched(let matched):
            if needDimensionAnchor {
                let box = Layout.Box()
                state.view.addLayoutBox(box)
                state.storage.boxes.append(box)
                var subState = State(containerBounds: state.containerBounds, in: state.view, storage: state.storage)
                layout(entity: entity, state: &subState)
                state.dimension = nil
                state.previousEntityBounds = Bounds(box: box)
                return axis == .horizontal ? box.widthAnchor : box.heightAnchor
            } else {
                let first = layout(entity: matched.first, state: &state, needDimensionAnchor: true)!
                for element in matched.subsequent {
                    switch element {
                    case .free(let free):
                        layout(entity: free, state: &state)
                    case .dependent(let dependent):
                        let match = layout(entity: dependent.entity, state: &state, needDimensionAnchor: true)!
                        dependent.dimension.scaledConstraintBetween(first: match, second: first, constraints: &state.storage.constraints)
                    }
                }
                return nil
            }
        case .sizedView(let v, let size):
            #if os(macOS)
            let view = v.nsView()
            view.translatesAutoresizingMaskIntoConstraints = false
            state.view.addSubview(view)
            constrain(bounds: Bounds(view: view), leading: state.dimension ?? Dimension(), length: size?.length, breadth: size?.breadth, relativity: size?.relativity ?? .independent, state: &state)
            state.dimension = nil
            state.previousEntityBounds = Bounds(view: view)
            #else
            let view = v.uiView()
            view.translatesAutoresizingMaskIntoConstraints = false
            state.view.addSubview(view)
            constrain(bounds: Bounds(view: view, marginEdges: .none), leading: state.dimension ?? Dimension(), length: size?.length, breadth: size?.breadth, relativity: size?.relativity ?? .independent, state: &state)
            state.dimension = nil
            state.previousEntityBounds = Bounds(view: view, marginEdges: .none)
            #endif
            return needDimensionAnchor ? (axis == .horizontal ? view.widthAnchor : view.heightAnchor) : nil
        }
    }
    
    fileprivate func add(to view: Layout.View, containerBounds: Bounds, storage: Storage) {
        var state = State(containerBounds: containerBounds, in: view, storage: storage)
        for entity in entities {
            layout(entity: entity, state: &state)
        }
        if let previous = state.previousEntityBounds {
            switch axis {
            case .horizontal:
                (state.dimension ?? Dimension()).unscaledConstraintBetween(first: previous.trailing, second: state.containerBounds.trailing, constraints: &state.storage.constraints, reverse: true)
            case .vertical:
                (state.dimension ?? Dimension()).unscaledConstraintBetween(first: previous.bottom, second: state.containerBounds.bottom, constraints: &state.storage.constraints, reverse: true)
            @unknown default: fatalError()
            }
        }
    }
}

// DEBUGGING TIP:
// As of Xcode 8, the "Debug View Hierarchy" option does not show layout guides, making debugging of constraints involving layout guides tricky. To aid debugging in these cases, set the following condition to `true && DEBUG` and CwlLayout will create views instead of layout guides.
// Otherwise, you can set this to `false && DEBUG`.
#if true && DEBUG
private extension Layout {
    typealias Box = Layout.View
}
private extension Layout.View {
    func addLayoutBox(_ layoutBox: Layout.Box) {
        layoutBox.translatesAutoresizingMaskIntoConstraints = false
        self.addSubview(layoutBox)
    }
    func removeLayoutBox(_ layoutBox: Layout.Box) {
        layoutBox.removeFromSuperview()
    }
}
#else
private extension Layout {
    typealias Box = Layout.Guide
}
private extension Layout.View {
    func addLayoutBox(_ layoutBox: Layout.Box) {
        self.addLayoutGuide(layoutBox)
    }
    func removeLayoutBox(_ layoutBox: Layout.Box) {
        self.removeLayoutGuide(layoutBox)
    }
}
#endif

// NOTE:
//
// Views often have their own intrinsic size, and they maintain this size at
// either the `.defaultLow` or `.defaultHigh` priority. Unfortunately, layout
// doesn't work well if this intrinsic priority is perfectly balanced with the
// user-applied layout priority.
//
// For this reason, CwlLayout defaults to using the following layout priorities
// which are scaled to be slightly different to the default priorities. This
// allows you to easily set layout priorities above, between or below the
// intrinisic priorities without always resorting to `.required`.
//
public extension Layout.Dimension.Priority {
    #if os(macOS)
    // .fittingSizeLevel = .fittingSizeCompression = 50
    static let fittingSizeLevel = NSLayoutConstraint.Priority.fittingSizeCompression
    // .layoutLow = 156.25
    static let layoutLow = NSLayoutConstraint.Priority(rawValue: (5 / 32) * NSLayoutConstraint.Priority.required.rawValue)
    // .defaultLow = 250
    // .layoutMid = 437.5
    static let layoutMid = NSLayoutConstraint.Priority(rawValue: (14 / 32) * NSLayoutConstraint.Priority.required.rawValue)
    // .dragThatCannotResizeWindow = 490
    // .windowSizeStayPut = 500
    // .dragThatCanResizeWindow = 510
    // .defaultHigh = 750
    // .layoutHigh = 843.75
    static let layoutHigh = NSLayoutConstraint.Priority(rawValue: (27 / 32) * NSLayoutConstraint.Priority.required.rawValue)
    // .required = 1000
    #else
    // .fittingSizeLevel = 50
    // .layoutLow = 156.25
    static let layoutLow = UILayoutPriority(rawValue: (5 / 32) * UILayoutPriority.required.rawValue)
    // .defaultLow = 250
    // .layoutMid = 437.5
    static let layoutMid = UILayoutPriority(rawValue: (14 / 32) * UILayoutPriority.required.rawValue)
    // .layoutHigh = 843.75
    static let layoutHigh = UILayoutPriority(rawValue: (27 / 32) * UILayoutPriority.required.rawValue)
    // .required = 1000
    #endif
}

private var associatedLayoutKey = NSObject()
private extension Layout.View {
    var associatedLayoutStorage: Layout.Storage? {
        get { return objc_getAssociatedObject(self, &associatedLayoutKey) as? Layout.Storage }
        set { return objc_setAssociatedObject(self, &associatedLayoutKey, newValue, objc_AssociationPolicy.OBJC_ASSOCIATION_RETAIN) }
    }
}

private extension Layout.View {
    func remove(constraintsAndBoxes previousLayout: Layout.Storage?, subviews: Set<Layout.View>) {
        guard let previous = previousLayout else { return }
        for constraint in previous.constraints {
            constraint.isActive = false
        }
        for box in previous.boxes {
            self.removeLayoutBox(box)
        }
        subviews.forEach { $0.removeFromSuperview() }
    }
}

// Applying a rolloing set of priorities reduces the chance of ambiguity. Later constraints will always take precedence.
// NOTE: this does not eliminate ambiguity due to conflicting `.required` contraints or views with equal hugging or compression resistance.
private func adjustedPriority(_ priority: Layout.Dimension.Priority, count: Int) -> Layout.Dimension.Priority {
    if priority == .required {
        return priority
    }
    
    let fitting = Layout.Dimension.Priority.fittingSizeLevel.rawValue + (1 / 128)
    return Layout.Dimension.Priority(rawValue: max(fitting, priority.rawValue - Float(count) / 128))
}

private func applyLayoutToView(view: Layout.View, params: (layout: Layout, bounds: Layout.Bounds)?) {
    var removedViews = Set<Layout.View>()
    
    // Check for a previous layout and get the old views
    let previous = view.associatedLayoutStorage
    previous?.layout.forEachView { view in removedViews.insert(view) }
    
    guard let (layout, bounds) = params else {
        // If there's no new layout, remove the old layout and we're done
        view.remove(constraintsAndBoxes: previous, subviews: removedViews)
        return
    }
    
    // Check if this will be animated
    let shouldAnimate = layout.animation?.style != .none && previous != nil
    
    // Exclude views in the new layout from the removed set. If we're animating, we'll need animated and added sets too.
    var animatedViews = Set<Layout.View>()
    var addedViews = Set<Layout.View>()
    layout.forEachView { v in
        if let animated = removedViews.remove(v), shouldAnimate {
            animatedViews.insert(animated)
        } else if shouldAnimate {
            addedViews.insert(v)
        }
    }
    
    // Now that we know the precise removed set, remove them.
    let removalChange = { view.remove(constraintsAndBoxes: previous, subviews: removedViews) }
    if shouldAnimate && layout.animation?.style != .frames && addedViews.count == 0 && removedViews.count > 0 {
        // If we're animating the removal of views but not the insertion of views, animate this removal
        fadeTransition(view: view, duration: layout.animation?.duration ?? 0, removalChange)
    } else {
        removalChange()
    }
    
    // Apply the new layout
    let storage = Layout.Storage(layout: layout)
    layout.add(to: view, containerBounds: bounds, storage: storage)
    
    // If we're not animating, store the layout and we're done.
    if !shouldAnimate {
        view.associatedLayoutStorage = storage
        return
    }
    
    // NOTE: the case where `removedViews.count > 0` but `addedViews.count == 0` is handled above
    if addedViews.count > 0 {
        // Apply the layout, so new views have a precise size
        view.relayout()
        
        // Remove the new views and revert to the old layout
        view.remove(constraintsAndBoxes: storage, subviews: addedViews)
        if let p = previous {
            let oldStorage = Layout.Storage(layout: layout)
            p.layout.add(to: view, containerBounds: bounds, storage: oldStorage)
            
            // Immediately remove the old constraints but keep the old views
            view.remove(constraintsAndBoxes: oldStorage, subviews: [])
        }
        
        removedViews.forEach { $0.removeFromSuperview() }
        addedViews.forEach { view.addSubview($0) }
        
        // Reapply the new layout. Since the new views are already in-place
        let reapplyStorage = Layout.Storage(layout: layout)
        layout.add(to: view, containerBounds: bounds, storage: reapplyStorage)
        view.associatedLayoutStorage = reapplyStorage
    } else {
        view.associatedLayoutStorage = storage
    }
    
    // Animate the frames of the new layout
    let shouldFade: Bool
    switch layout.animation?.style {
    case .both?, .fade?: shouldFade = true
    case .frames?, nil: shouldFade = false
    }
    let frameChanges = {
        if shouldFade {
            fadeTransition(view: view, duration: layout.animation?.duration ?? 0, { view.relayout() })
        } else {
            view.relayout()
        }
    }
    if layout.animation?.style == .fade {
        frameChanges()
    } else {
        frameAnimation(view: view, duration: layout.animation?.duration ?? 0, frameChanges)
    }
}

private extension Layout.View {
    func relayout() {
        #if os(macOS)
        layoutSubtreeIfNeeded()
        #else
        layoutIfNeeded()
        #endif
    }
}

private func fadeTransition(view: Layout.View, duration: CFTimeInterval, _ changes: @escaping () -> ()) {
    #if os(macOS)
    let transition = CATransition()
    transition.duration = duration
    transition.type = .fade
    view.layer?.add(transition, forKey: nil)
    changes()
    #else
    UIView.transition(with: view, duration: duration, options: [.transitionCrossDissolve, .allowUserInteraction], animations: changes)
    #endif
}

private func frameAnimation(view: Layout.View, duration: CFTimeInterval, _ changes: @escaping () -> ()) {
    #if os(macOS)
    NSAnimationContext.beginGrouping()
    NSAnimationContext.current.duration = duration
    NSAnimationContext.current.allowsImplicitAnimation = true
    changes()
    NSAnimationContext.endGrouping()
    #else
    UIView.transition(with: view, duration: duration, options: [.transitionCrossDissolve, .allowUserInteraction], animations: changes)
    #endif
}

public extension UIFont {
    static func preferredFont(forTextStyle style: UIFont.TextStyle, weight: UIFont.Weight = .regular, slant: Float = 0) -> UIFont {
        let base = UIFontDescriptor.preferredFontDescriptor(withTextStyle: style)
        let traits: [UIFontDescriptor.TraitKey: Any] = [.weight: weight, .slant: slant]
        let modified = base.addingAttributes([.traits: traits])
        return UIFont(descriptor: modified, size: 0)
    }
}

public func preferredFontSize(forTextStyle style: UIFont.TextStyle) -> CGFloat {
    return UIFontDescriptor.preferredFontDescriptor(withTextStyle: style).pointSize
}
