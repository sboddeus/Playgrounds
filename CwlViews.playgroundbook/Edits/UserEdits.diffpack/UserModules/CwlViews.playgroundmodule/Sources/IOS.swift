
import CwlSignals
import CwlCore
import CwlViewsCore
import CwlViewsUtilities
import UIKit

// MARK: - Binder Part 1: Binder
public class NavigationItem: Binder, NavigationItemConvertible {
    public var state: BinderState<Preparer>
    public required init(type: Preparer.Instance.Type, parameters: Preparer.Parameters, bindings: [Preparer.Binding]) {
        state = .pending(type: type, parameters: parameters, bindings: bindings)
    }
}

// MARK: - Binder Part 2: Binding
public extension NavigationItem {
    enum Binding: NavigationItemBinding {
        case inheritedBinding(Preparer.Inherited.Binding)
        
        //    0. Static bindings are applied at construction and are subsequently immutable.
        
        // 1. Value bindings may be applied at construction and may subsequently change.
        case backBarButtonItem(Dynamic<BarButtonItemConvertible?>)
        case hidesBackButton(Dynamic<SetOrAnimate<Bool>>)
        case leftBarButtonItems(Dynamic<SetOrAnimate<[BarButtonItemConvertible]>>)
        case leftItemsSupplementBackButton(Dynamic<Bool>)
        case prompt(Dynamic<String?>)
        case rightBarButtonItems(Dynamic<SetOrAnimate<[BarButtonItemConvertible]>>)
        case title(Dynamic<String>)
        case titleView(Dynamic<ViewConvertible?>)
        
        // 2. Signal bindings are performed on the object after construction.
        
        // 3. Action bindings are triggered by the object after construction.
        
        // 4. Delegate bindings require synchronous evaluation within the object's context.
    }
}

// MARK: - Binder Part 3: Preparer
public extension NavigationItem {
    struct Preparer: BinderEmbedderConstructor {
        public typealias Binding = NavigationItem.Binding
        public typealias Inherited = BinderBase
        public typealias Instance = UINavigationItem
        
        public var inherited = Inherited()
        public init() {}
        public func constructStorage(instance: Instance) -> Storage { return Storage() }
        public func inheritedBinding(from: Binding) -> Inherited.Binding? {
            if case .inheritedBinding(let b) = from { return b } else { return nil }
        }
    }
}

// MARK: - Binder Part 4: Preparer overrides
public extension NavigationItem.Preparer {
    func applyBinding(_ binding: Binding, instance: Instance, storage: Storage) -> Lifetime? {
        switch binding {
        case .inheritedBinding(let x): return inherited.applyBinding(x, instance: instance, storage: storage)
            
            //    0. Static bindings are applied at construction and are subsequently immutable.
            
        //    1. Value bindings may be applied at construction and may subsequently change.
        case .backBarButtonItem(let x): return x.apply(instance) { i, v in i.backBarButtonItem = v?.uiBarButtonItem() }
        case .hidesBackButton(let x): return x.apply(instance) { i, v in i.setHidesBackButton(v.value, animated: v.isAnimated) }
        case .leftBarButtonItems(let x): return x.apply(instance) { i, v in i.setLeftBarButtonItems(v.value.map { $0.uiBarButtonItem() }, animated: v.isAnimated) }
        case .leftItemsSupplementBackButton(let x): return x.apply(instance) { i, v in i.leftItemsSupplementBackButton = v }
        case .prompt(let x): return x.apply(instance) { i, v in i.prompt = v }
        case .rightBarButtonItems(let x): return x.apply(instance) { i, v in i.setRightBarButtonItems(v.value.map { $0.uiBarButtonItem() }, animated: v.isAnimated) }
        case .title(let x): return x.apply(instance) { i, v in i.title = v }
        case .titleView(let x): return x.apply(instance) { i, v in i.titleView = v?.uiView() }
            
            //    2. Signal bindings are performed on the object after construction.
            
            //    3. Action bindings are triggered by the object after construction.
            
            //    4. Delegate bindings require synchronous evaluation within the object's context.
        }
    }
}

// MARK: - Binder Part 5: Storage and Delegate
extension NavigationItem.Preparer {
    public typealias Storage = AssociatedBinderStorage
}

// MARK: - Binder Part 6: BindingNames
extension BindingName where Binding: NavigationItemBinding {
    public typealias NavigationItemName<V> = BindingName<V, NavigationItem.Binding, Binding>
    private static func name<V>(_ source: @escaping (V) -> NavigationItem.Binding) -> NavigationItemName<V> {
        return NavigationItemName<V>(source: source, downcast: Binding.navigationItemBinding)
    }
}
public extension BindingName where Binding: NavigationItemBinding {
    // You can easily convert the `Binding` cases to `BindingName` using the following Xcode-style regex:
    // Replace: case ([^\(]+)\((.+)\)$
    // With:    static var $1: NavigationItemName<$2> { return .name(NavigationItem.Binding.$1) }
    
    //    0. Static bindings are applied at construction and are subsequently immutable.
    
    // 1. Value bindings may be applied at construction and may subsequently change.
    static var backBarButtonItem: NavigationItemName<Dynamic<BarButtonItemConvertible?>> { return .name(NavigationItem.Binding.backBarButtonItem) }
    static var hidesBackButton: NavigationItemName<Dynamic<SetOrAnimate<Bool>>> { return .name(NavigationItem.Binding.hidesBackButton) }
    static var leftBarButtonItems: NavigationItemName<Dynamic<SetOrAnimate<[BarButtonItemConvertible]>>> { return .name(NavigationItem.Binding.leftBarButtonItems) }
    static var leftItemsSupplementBackButton: NavigationItemName<Dynamic<Bool>> { return .name(NavigationItem.Binding.leftItemsSupplementBackButton) }
    static var prompt: NavigationItemName<Dynamic<String?>> { return .name(NavigationItem.Binding.prompt) }
    static var rightBarButtonItems: NavigationItemName<Dynamic<SetOrAnimate<[BarButtonItemConvertible]>>> { return .name(NavigationItem.Binding.rightBarButtonItems) }
    static var title: NavigationItemName<Dynamic<String>> { return .name(NavigationItem.Binding.title) }
    static var titleView: NavigationItemName<Dynamic<ViewConvertible?>> { return .name(NavigationItem.Binding.titleView) }
    
    // 2. Signal bindings are performed on the object after construction.
    
    // 3. Action bindings are triggered by the object after construction.
    
    // 4. Delegate bindings require synchronous evaluation within the object's context.
    
    // Composite binding names
    static func leftBarButtonItems(animate: AnimationChoice = .subsequent) -> NavigationItemName<Dynamic<[BarButtonItemConvertible]>> {
        return Binding.compositeName(
            value: { latestArray in 
                switch latestArray {
                case .constant(let b) where animate == .always: return .constant(.animate(b))
                case .constant(let b): return .constant(.set(b))
                case .dynamic(let b): return .dynamic(b.animate(animate))
                }
        },
            binding: NavigationItem.Binding.leftBarButtonItems,
            downcast: Binding.navigationItemBinding
        )
    }
    static func rightBarButtonItems(animate: AnimationChoice = .subsequent) -> NavigationItemName<Dynamic<[BarButtonItemConvertible]>> {
        return Binding.compositeName(
            value: { latestArray in 
                switch latestArray {
                case .constant(let b) where animate == .always: return .constant(.animate(b))
                case .constant(let b): return .constant(.set(b))
                case .dynamic(let b): return .dynamic(b.animate(animate))
                }
        },
            binding: NavigationItem.Binding.rightBarButtonItems,
            downcast: Binding.navigationItemBinding)
    }
}

// MARK: - Binder Part 7: Convertible protocols (if constructible)
public protocol NavigationItemConvertible {
    func uiNavigationItem() -> NavigationItem.Instance
}
extension UINavigationItem: NavigationItemConvertible, DefaultConstructable {
    public func uiNavigationItem() -> NavigationItem.Instance { return self }
}
public extension NavigationItem {
    func uiNavigationItem() -> NavigationItem.Instance { return instance() }
}

// MARK: - Binder Part 8: Downcast protocols
public protocol NavigationItemBinding: BinderBaseBinding {
    static func navigationItemBinding(_ binding: NavigationItem.Binding) -> Self
    func asNavigationItemBinding() -> NavigationItem.Binding?
}
public extension NavigationItemBinding {
    static func binderBaseBinding(_ binding: BinderBase.Binding) -> Self {
        return navigationItemBinding(.inheritedBinding(binding))
    }
}
public extension NavigationItemBinding where Preparer.Inherited.Binding: NavigationItemBinding {
    func asNavigationItemBinding() -> NavigationItem.Binding? {
        return asInheritedBinding()?.asNavigationItemBinding()
    }
}
public extension NavigationItem.Binding {
    typealias Preparer = NavigationItem.Preparer
    func asInheritedBinding() -> Preparer.Inherited.Binding? { if case .inheritedBinding(let b) = self { return b } else { return nil } }
    func asNavigationItemBinding() -> NavigationItem.Binding? { return self }
    static func navigationItemBinding(_ binding: NavigationItem.Binding) -> NavigationItem.Binding {
        return binding
    }
}

// MARK: - Binder Part 9: Other supporting types

// MARK: - Binder Part 1: Binder
public class ViewController: Binder, ViewControllerConvertible {
    public var state: BinderState<Preparer>
    public required init(type: Preparer.Instance.Type, parameters: Preparer.Parameters, bindings: [Preparer.Binding]) {
        state = .pending(type: type, parameters: parameters, bindings: bindings)
    }
}

// MARK: - Binder Part 2: Binding
public extension ViewController {
    enum Binding: ViewControllerBinding {
        case inheritedBinding(Preparer.Inherited.Binding)
        
        //    0. Static bindings are applied at construction and are subsequently immutable.
        case navigationItem(Constant<NavigationItem>)
        
        // 1. Value bindings may be applied at construction and may subsequently change.
        case additionalSafeAreaInsets(Dynamic<UIEdgeInsets>)
        case children(Dynamic<[ViewControllerConvertible]>)
        case definesPresentationContext(Dynamic<Bool>)
        case edgesForExtendedLayout(Dynamic<UIRectEdge>)
        case extendedLayoutIncludesOpaqueBars(Dynamic<Bool>)
        case hidesBottomBarWhenPushed(Dynamic<Bool>)
        case isEditing(Signal<SetOrAnimate<Bool>>)
        case isModalInPopover(Dynamic<Bool>)
        case modalPresentationCapturesStatusBarAppearance(Dynamic<Bool>)
        case modalPresentationStyle(Dynamic<UIModalPresentationStyle>)
        case modalTransitionStyle(Dynamic<UIModalTransitionStyle>)
        case preferredContentSize(Dynamic<CGSize>)
        case providesPresentationContextTransitionStyle(Dynamic<Bool>)
        case restorationClass(Dynamic<UIViewControllerRestoration.Type?>)
        case restorationIdentifier(Dynamic<String?>)
        case tabBarItem(Dynamic<TabBarItemConvertible>)
        case title(Dynamic<String>)
        case toolbarItems(Dynamic<SetOrAnimate<[BarButtonItemConvertible]>>)
        case transitioningDelegate(Dynamic<UIViewControllerTransitioningDelegate>)
        case view(Dynamic<ViewConvertible>)
        
        // 2. Signal bindings are performed on the object after construction.
        case present(Signal<Animatable<ModalPresentation?, ()>>)
        
        // 3. Action bindings are triggered by the object after construction.
        
        // 4. Delegate bindings require synchronous evaluation within the object's context.
        case childrenLayout(([UIView]) -> Layout)
    }
}

// MARK: - Binder Part 3: Preparer
public extension ViewController {
    struct Preparer: BinderEmbedderConstructor {
        public typealias Binding = ViewController.Binding
        public typealias Inherited = BinderBase
        public typealias Instance = UIViewController
        
        public var inherited = Inherited()
        public init() {}
        public func constructStorage(instance: Instance) -> Storage { return Storage() }
        public func inheritedBinding(from: Binding) -> Inherited.Binding? {
            if case .inheritedBinding(let b) = from { return b } else { return nil }
        }
        
        public var childrenLayout: (([UIView]) -> Layout)?
        public var view: InitialSubsequent<ViewConvertible>?
    }
}

// MARK: - Binder Part 4: Preparer overrides
public extension ViewController.Preparer {
    mutating func prepareBinding(_ binding: Binding) {
        switch binding {
        case .inheritedBinding(let preceeding): inherited.prepareBinding(preceeding)
            
        case .childrenLayout(let x): childrenLayout = x
        case .view(let x): view = x.initialSubsequent()
        default: break
        }
    }
    
    func prepareInstance(_ instance: Instance, storage: Storage) {
        inheritedPrepareInstance(instance, storage: storage)
        
        // Need to set the embedded storage immediately (instead of waiting for the combine function) in case any of the swizzled methods get called (they rely on being able to access the embedded storage).
        instance.setAssociatedBinderStorage(storage)
        
        // The loadView function needs to be ready in case one of the bindings triggers a view load.
        if let v = view?.initial?.uiView() {
            instance.view = v
        }
        
        // The childrenLayout should be ready for when the children property starts
        storage.childrenLayout = childrenLayout
    }
    
    func applyBinding(_ binding: Binding, instance: Instance, storage: Storage) -> Lifetime? {
        switch binding {
        case .inheritedBinding(let x): return inherited.applyBinding(x, instance: instance, storage: storage)
            
        //    0. Static bindings are applied at construction and are subsequently immutable.
        case .navigationItem(let x):
            x.value.apply(to: instance.navigationItem)
            return nil
            
        // 1. Value bindings may be applied at construction and may subsequently change.
        case .additionalSafeAreaInsets(let x): return x.apply(instance) { i, v in i.additionalSafeAreaInsets = v }
        case .children(let x):
            return x.apply(instance, storage) { i, s, v in
                let existing = i.children
                let next = v.map { $0.uiViewController() }
                
                for e in existing {
                    if !next.contains(e) {
                        e.willMove(toParent: nil)
                    }
                }
                for n in next {
                    if !existing.contains(n) {
                        i.addChild(n)
                    }
                }
                (storage.childrenLayout?(next.map { $0.view })).map(i.view.applyLayout)
                for n in next {
                    if !existing.contains(n) {
                        n.didMove(toParent: i)
                    }
                }
                for e in existing {
                    if !next.contains(e) {
                        e.removeFromParent()
                    }
                }
            }
        case .definesPresentationContext(let x): return x.apply(instance) { i, v in i.definesPresentationContext = v }
        case .edgesForExtendedLayout(let x): return x.apply(instance) { i, v in i.edgesForExtendedLayout = v }
        case .extendedLayoutIncludesOpaqueBars(let x): return x.apply(instance) { i, v in i.extendedLayoutIncludesOpaqueBars = v }
        case .hidesBottomBarWhenPushed(let x): return x.apply(instance) { i, v in i.hidesBottomBarWhenPushed = v }
        case .isEditing(let x): return x.apply(instance) { i, v in i.setEditing(v.value, animated: v.isAnimated) }
        case .isModalInPopover(let x): return x.apply(instance) { i, v in i.isModalInPopover = v }
        case .modalPresentationCapturesStatusBarAppearance(let x): return x.apply(instance) { i, v in i.modalPresentationCapturesStatusBarAppearance = v }
        case .modalPresentationStyle(let x): return x.apply(instance) { i, v in i.modalPresentationStyle = v }
        case .modalTransitionStyle(let x): return x.apply(instance) { i, v in i.modalTransitionStyle = v }
        case .preferredContentSize(let x): return x.apply(instance) { i, v in i.preferredContentSize = v }
        case .providesPresentationContextTransitionStyle(let x): return x.apply(instance) { i, v in i.providesPresentationContextTransitionStyle = v }
        case .restorationClass(let x): return x.apply(instance) { i, v in i.restorationClass = v }
        case .restorationIdentifier(let x): return x.apply(instance) { i, v in i.restorationIdentifier = v }
        case .tabBarItem(let x): return x.apply(instance) { i, v in i.tabBarItem = v.uiTabBarItem() }
        case .title(let x): return x.apply(instance) { i, v in i.title = v }
        case .toolbarItems(let x): return x.apply(instance) { i, v in i.setToolbarItems(v.value.map { $0.uiBarButtonItem() }, animated: v.isAnimated) }
        case .transitioningDelegate(let x): return x.apply(instance) { i, v in i.transitioningDelegate = v }
        case .view:
            return view?.apply(instance, storage) { i, s, v in
                s.view = v
                if i.isViewLoaded {
                    i.view = v.uiView()
                }
            }
            
        // 2. Signal bindings are performed on the object after construction.
        case .present(let x):
            return x.apply(instance, storage) { i, s, v in
                s.queuedModalPresentations.append(v)
                s.processModalPresentations(viewController: i)
            }
            
            // 3. Action bindings are triggered by the object after construction.
            
        // 4. Delegate bindings require synchronous evaluation within the object's context.
        case .childrenLayout: return nil
        }
    }
    
    func finalizeInstance(_ instance: Instance, storage: Storage) -> Lifetime? {
        // We previously set the embedded storage so that any delegate methods triggered during setup would be able to resolve the storage. Now that we're done setting up, we need to *clear* the storage so the embed function doesn't complain that the storage is already set.
        instance.setAssociatedBinderStorage(nil)
        
        return inheritedFinalizedInstance(instance, storage: storage)
    }
}

// MARK: - Binder Part 5: Storage and Delegate
extension ViewController.Preparer {
    private static var presenterKey = NSObject()
    
    open class Storage: AssociatedBinderStorage, UIPopoverPresentationControllerDelegate {
        open var view: ViewConvertible?
        open var childrenLayout: (([UIView]) -> Layout)?
        
        open var presentationAnimationInProgress: Bool = false
        open var currentModalPresentation: ModalPresentation? = nil
        open var queuedModalPresentations: [Animatable<ModalPresentation?, ()>] = []
        
        open override var isInUse: Bool {
            return true
        }
        
        private func presentationDismissed(viewController: UIViewController) {
            currentModalPresentation?.completion?.send(value: ())
            currentModalPresentation = nil
            processModalPresentations(viewController: viewController)
        }
        
        private func presentationAnimationCompleted(viewController: UIViewController, dismissed: Bool) {
            self.queuedModalPresentations.removeFirst()
            self.presentationAnimationInProgress = false
            if dismissed {
                presentationDismissed(viewController: viewController)
            }
        }
        
        open func popoverPresentationControllerDidDismissPopover(_ popoverPresentationController: UIPopoverPresentationController) {
            presentationDismissed(viewController: popoverPresentationController.presentingViewController)
        }
        
        private func present(viewController: UIViewController, modalPresentation: ModalPresentation, animated: Bool) {
            presentationAnimationInProgress = true
            currentModalPresentation = modalPresentation
            let presentation = modalPresentation.viewController.uiViewController()
            if let popover = presentation.popoverPresentationController, let configure = modalPresentation.popoverPositioning {
                configure(viewController, popover)
                popover.delegate = self
            } else if let presenter = presentation.presentationController {
                objc_setAssociatedObject(presenter, &presenterKey, OnDelete {
                    guard presentation === self.currentModalPresentation?.viewController.uiViewController() else { return }
                    self.presentationDismissed(viewController: viewController)
                }, objc_AssociationPolicy.OBJC_ASSOCIATION_RETAIN)
            }
            viewController.present(presentation, animated: animated) {
                self.presentationAnimationCompleted(viewController: viewController, dismissed: false)
            }
        }
        
        private func dismiss(viewController: UIViewController, animated: Bool) {
            presentationAnimationInProgress = true
            guard let vc = viewController.presentedViewController else {
                self.presentationAnimationCompleted(viewController: viewController, dismissed: true)
                return
            }
            guard !(vc === currentModalPresentation?.viewController.uiViewController()) || vc.isBeingDismissed else {
                assertionFailure("Presentations interleaved with other APIs is not supported.")
                let completionHandlers = queuedModalPresentations.compactMap {
                    $0.value?.completion
                }
                queuedModalPresentations.removeAll()
                presentationAnimationInProgress = false
                currentModalPresentation?.completion?.send(value: ())
                completionHandlers.forEach { $0.send(value: ()) }
                return
            }
            vc.dismiss(animated: animated, completion: { () -> Void in
                self.presentationAnimationCompleted(viewController: viewController, dismissed: true)
            })
        }
        
        open func processModalPresentations(viewController: UIViewController) {
            guard !presentationAnimationInProgress, let first = queuedModalPresentations.first else { return }
            if let modalPresentation = first.value {
                guard viewController.view.window != nil else { return }
                present(viewController: viewController, modalPresentation: modalPresentation, animated: first.isAnimated)
            } else {
                dismiss(viewController: viewController, animated: first.isAnimated)
            }
        }
    }
}

// MARK: - Binder Part 6: BindingNames
extension BindingName where Binding: ViewControllerBinding {
    public typealias ViewControllerName<V> = BindingName<V, ViewController.Binding, Binding>
    private static func name<V>(_ source: @escaping (V) -> ViewController.Binding) -> ViewControllerName<V> {
        return ViewControllerName<V>(source: source, downcast: Binding.viewControllerBinding)
    }
}
public extension BindingName where Binding: ViewControllerBinding {
    // You can easily convert the `Binding` cases to `BindingName` using the following Xcode-style regex:
    // Replace: case ([^\(]+)\((.+)\)$
    // With:    static var $1: ViewControllerName<$2> { return .name(ViewController.Binding.$1) }
    
    //    0. Static bindings are applied at construction and are subsequently immutable.
    static var navigationItem: ViewControllerName<Constant<NavigationItem>> { return .name(ViewController.Binding.navigationItem) }
    
    // 1. Value bindings may be applied at construction and may subsequently change.
    static var additionalSafeAreaInsets: ViewControllerName<Dynamic<UIEdgeInsets>> { return .name(ViewController.Binding.additionalSafeAreaInsets) }
    static var children: ViewControllerName<Dynamic<[ViewControllerConvertible]>> { return .name(ViewController.Binding.children) }
    static var definesPresentationContext: ViewControllerName<Dynamic<Bool>> { return .name(ViewController.Binding.definesPresentationContext) }
    static var edgesForExtendedLayout: ViewControllerName<Dynamic<UIRectEdge>> { return .name(ViewController.Binding.edgesForExtendedLayout) }
    static var extendedLayoutIncludesOpaqueBars: ViewControllerName<Dynamic<Bool>> { return .name(ViewController.Binding.extendedLayoutIncludesOpaqueBars) }
    static var hidesBottomBarWhenPushed: ViewControllerName<Dynamic<Bool>> { return .name(ViewController.Binding.hidesBottomBarWhenPushed) }
    static var isEditing: ViewControllerName<Signal<SetOrAnimate<Bool>>> { return .name(ViewController.Binding.isEditing) }
    static var isModalInPopover: ViewControllerName<Dynamic<Bool>> { return .name(ViewController.Binding.isModalInPopover) }
    static var modalPresentationCapturesStatusBarAppearance: ViewControllerName<Dynamic<Bool>> { return .name(ViewController.Binding.modalPresentationCapturesStatusBarAppearance) }
    static var modalPresentationStyle: ViewControllerName<Dynamic<UIModalPresentationStyle>> { return .name(ViewController.Binding.modalPresentationStyle) }
    static var modalTransitionStyle: ViewControllerName<Dynamic<UIModalTransitionStyle>> { return .name(ViewController.Binding.modalTransitionStyle) }
    static var preferredContentSize: ViewControllerName<Dynamic<CGSize>> { return .name(ViewController.Binding.preferredContentSize) }
    static var providesPresentationContextTransitionStyle: ViewControllerName<Dynamic<Bool>> { return .name(ViewController.Binding.providesPresentationContextTransitionStyle) }
    static var restorationClass: ViewControllerName<Dynamic<UIViewControllerRestoration.Type?>> { return .name(ViewController.Binding.restorationClass) }
    static var restorationIdentifier: ViewControllerName<Dynamic<String?>> { return .name(ViewController.Binding.restorationIdentifier) }
    static var tabBarItem: ViewControllerName<Dynamic<TabBarItemConvertible>> { return .name(ViewController.Binding.tabBarItem) }
    static var title: ViewControllerName<Dynamic<String>> { return .name(ViewController.Binding.title) }
    static var toolbarItems: ViewControllerName<Dynamic<SetOrAnimate<[BarButtonItemConvertible]>>> { return .name(ViewController.Binding.toolbarItems) }
    static var transitioningDelegate: ViewControllerName<Dynamic<UIViewControllerTransitioningDelegate>> { return .name(ViewController.Binding.transitioningDelegate) }
    static var view: ViewControllerName<Dynamic<ViewConvertible>> { return .name(ViewController.Binding.view) }
    
    // 2. Signal bindings are performed on the object after construction.
    static var present: ViewControllerName<Signal<Animatable<ModalPresentation?, ()>>> { return .name(ViewController.Binding.present) }
    
    // 3. Action bindings are triggered by the object after construction.
    
    // 4. Delegate bindings require synchronous evaluation within the object's context.
    static var childrenLayout: ViewControllerName<([UIView]) -> Layout> { return .name(ViewController.Binding.childrenLayout) }
}

// MARK: - Binder Part 7: Convertible protocols (if constructible)
public protocol ViewControllerConvertible {
    func uiViewController() -> ViewController.Instance
}
extension UIViewController: ViewControllerConvertible, DefaultConstructable {
    public func uiViewController() -> ViewController.Instance { return self }
}
public extension ViewController {
    func uiViewController() -> ViewController.Instance { return instance() }
}

// MARK: - Binder Part 8: Downcast protocols
public protocol ViewControllerBinding: BinderBaseBinding {
    static func viewControllerBinding(_ binding: ViewController.Binding) -> Self
    func asViewControllerBinding() -> ViewController.Binding?
}
public extension ViewControllerBinding {
    static func binderBaseBinding(_ binding: BinderBase.Binding) -> Self {
        return viewControllerBinding(.inheritedBinding(binding))
    }
}
public extension ViewControllerBinding where Preparer.Inherited.Binding: ViewControllerBinding {
    func asViewControllerBinding() -> ViewController.Binding? {
        return asInheritedBinding()?.asViewControllerBinding()
    }
}
public extension ViewController.Binding {
    typealias Preparer = ViewController.Preparer
    func asInheritedBinding() -> Preparer.Inherited.Binding? { if case .inheritedBinding(let b) = self { return b } else { return nil } }
    func asViewControllerBinding() -> ViewController.Binding? { return self }
    static func viewControllerBinding(_ binding: ViewController.Binding) -> ViewController.Binding {
        return binding
    }
}

// MARK: - Binder Part 9: Other supporting types
public struct ModalPresentation {
    let viewController: ViewControllerConvertible
    let popoverPositioning: ((_ presenter: UIViewController, _ popover: UIPopoverPresentationController) -> Void)?
    let completion: SignalInput<Void>?
    
    public init(_ viewController: ViewControllerConvertible, popoverPositioning: ((_ presenter: UIViewController, _ popover: UIPopoverPresentationController) -> Void)? = nil, completion: SignalInput<Void>? = nil) {
        self.viewController = viewController
        self.popoverPositioning = popoverPositioning
        self.completion = completion
    }
}

extension SignalInterface {
    public func modalPresentation<T>(_ construct: @escaping (T) -> ViewControllerConvertible) -> Signal<ModalPresentation?> where OutputValue == Optional<T> {
        return transform { result in
            switch result {
            case .success(.some(let t)): return .value(ModalPresentation(construct(t)))
            case .success: return .value(nil)
            case .failure(let e): return .end(e)
            }
        }
    }
}

// MARK: - Binder Part 1: Binder
public class Label: Binder, LabelConvertible {
    public var state: BinderState<Preparer>
    public required init(type: Preparer.Instance.Type, parameters: Preparer.Parameters, bindings: [Preparer.Binding]) {
        state = .pending(type: type, parameters: parameters, bindings: bindings)
    }
}

// MARK: - Binder Part 2: Binding
public extension Label {
    enum Binding: LabelBinding {
        case inheritedBinding(Preparer.Inherited.Binding)
        
        //    0. Static bindings are applied at construction and are subsequently immutable.
        
        // 1. Value bindings may be applied at construction and may subsequently change.
        case adjustsFontSizeToFitWidth(Dynamic<Bool>)
        case allowsDefaultTighteningForTruncation(Dynamic<Bool>)
        case attributedText(Dynamic<NSAttributedString?>)
        case baselineAdjustment(Dynamic<UIBaselineAdjustment>)
        case font(Dynamic<UIFont>)
        case highlightedTextColor(Dynamic<UIColor?>)
        case isEnabled(Dynamic<Bool>)
        case isHighlighted(Dynamic<Bool>)
        case lineBreakMode(Dynamic<NSLineBreakMode>)
        case minimumScaleFactor(Dynamic<CGFloat>)
        case numberOfLines(Dynamic<Int>)
        case preferredMaxLayoutWidth(Dynamic<CGFloat>)
        case shadowColor(Dynamic<UIColor?>)
        case shadowOffset(Dynamic<CGSize>)
        case text(Dynamic<String>)
        case textAlignment(Dynamic<NSTextAlignment>)
        case textColor(Dynamic<UIColor>)
        
        // 2. Signal bindings are performed on the object after construction.
        
        // 3. Action bindings are triggered by the object after construction.
        
        // 4. Delegate bindings require synchronous evaluation within the object's context.
    }
}

// MARK: - Binder Part 3: Preparer
public extension Label {
    struct Preparer: BinderEmbedderConstructor {
        public typealias Binding = Label.Binding
        public typealias Inherited = View.Preparer
        public typealias Instance = UILabel
        
        public var inherited = Inherited()
        public init() {}
        public func constructStorage(instance: Instance) -> Storage { return Storage() }
        public func inheritedBinding(from: Binding) -> Inherited.Binding? {
            if case .inheritedBinding(let b) = from { return b } else { return nil }
        }
    }
}

// MARK: - Binder Part 4: Preparer overrides
public extension Label.Preparer {
    func applyBinding(_ binding: Binding, instance: Instance, storage: Storage) -> Lifetime? {
        switch binding {
        case .inheritedBinding(let x): return inherited.applyBinding(x, instance: instance, storage: storage)
            
            //    0. Static bindings are applied at construction and are subsequently immutable.
            
        // 1. Value bindings may be applied at construction and may subsequently change.
        case .adjustsFontSizeToFitWidth(let x): return x.apply(instance) { i, v in i.adjustsFontSizeToFitWidth = v }
        case .allowsDefaultTighteningForTruncation(let x): return x.apply(instance) { i, v in i.allowsDefaultTighteningForTruncation = v }
        case .attributedText(let x): return x.apply(instance) { i, v in i.attributedText = v }
        case .baselineAdjustment(let x): return x.apply(instance) { i, v in i.baselineAdjustment = v }
        case .font(let x): return x.apply(instance) { i, v in i.font = v }
        case .highlightedTextColor(let x): return x.apply(instance) { i, v in i.highlightedTextColor = v }
        case .isEnabled(let x): return x.apply(instance) { i, v in i.isEnabled = v }
        case .isHighlighted(let x): return x.apply(instance) { i, v in i.isHighlighted = v }
        case .lineBreakMode(let x): return x.apply(instance) { i, v in i.lineBreakMode = v }
        case .minimumScaleFactor(let x): return x.apply(instance) { i, v in i.minimumScaleFactor = v }
        case .numberOfLines(let x): return x.apply(instance) { i, v in i.numberOfLines = v }
        case .preferredMaxLayoutWidth(let x): return x.apply(instance) { i, v in i.preferredMaxLayoutWidth = v }
        case .shadowColor(let x): return x.apply(instance) { i, v in i.shadowColor = v }
        case .shadowOffset(let x): return x.apply(instance) { i, v in i.shadowOffset = v }
        case .text(let x): return x.apply(instance) { i, v in i.text = v }
        case .textAlignment(let x): return x.apply(instance) { i, v in i.textAlignment = v }
        case .textColor(let x): return x.apply(instance) { i, v in i.textColor = v }
            
            // 2. Signal bindings are performed on the object after construction.
            
            // 3. Action bindings are triggered by the object after construction.
            
            // 4. Delegate bindings require synchronous evaluation within the object's context.
        }
    }
}

// MARK: - Binder Part 5: Storage and Delegate
extension Label.Preparer {
    public typealias Storage = View.Preparer.Storage
}

// MARK: - Binder Part 6: BindingNames
extension BindingName where Binding: LabelBinding {
    public typealias LabelName<V> = BindingName<V, Label.Binding, Binding>
    private static func name<V>(_ source: @escaping (V) -> Label.Binding) -> LabelName<V> {
        return LabelName<V>(source: source, downcast: Binding.windowBinding)
    }
}
public extension BindingName where Binding: LabelBinding {
    // You can easily convert the `Binding` cases to `BindingName` using the following Xcode-style regex:
    // Replace: case ([^\(]+)\((.+)\)$
    // With:    static var $1: LabelName<$2> { return .name(Label.Binding.$1) }
    
    //    0. Static bindings are applied at construction and are subsequently immutable.
    
    // 1. Value bindings may be applied at construction and may subsequently change.
    static var adjustsFontSizeToFitWidth: LabelName<Dynamic<Bool>> { return .name(Label.Binding.adjustsFontSizeToFitWidth) }
    static var allowsDefaultTighteningForTruncation: LabelName<Dynamic<Bool>> { return .name(Label.Binding.allowsDefaultTighteningForTruncation) }
    static var attributedText: LabelName<Dynamic<NSAttributedString?>> { return .name(Label.Binding.attributedText) }
    static var baselineAdjustment: LabelName<Dynamic<UIBaselineAdjustment>> { return .name(Label.Binding.baselineAdjustment) }
    static var font: LabelName<Dynamic<UIFont>> { return .name(Label.Binding.font) }
    static var highlightedTextColor: LabelName<Dynamic<UIColor?>> { return .name(Label.Binding.highlightedTextColor) }
    static var isEnabled: LabelName<Dynamic<Bool>> { return .name(Label.Binding.isEnabled) }
    static var isHighlighted: LabelName<Dynamic<Bool>> { return .name(Label.Binding.isHighlighted) }
    static var lineBreakMode: LabelName<Dynamic<NSLineBreakMode>> { return .name(Label.Binding.lineBreakMode) }
    static var minimumScaleFactor: LabelName<Dynamic<CGFloat>> { return .name(Label.Binding.minimumScaleFactor) }
    static var numberOfLines: LabelName<Dynamic<Int>> { return .name(Label.Binding.numberOfLines) }
    static var preferredMaxLayoutWidth: LabelName<Dynamic<CGFloat>> { return .name(Label.Binding.preferredMaxLayoutWidth) }
    static var shadowColor: LabelName<Dynamic<UIColor?>> { return .name(Label.Binding.shadowColor) }
    static var shadowOffset: LabelName<Dynamic<CGSize>> { return .name(Label.Binding.shadowOffset) }
    static var text: LabelName<Dynamic<String>> { return .name(Label.Binding.text) }
    static var textAlignment: LabelName<Dynamic<NSTextAlignment>> { return .name(Label.Binding.textAlignment) }
    static var textColor: LabelName<Dynamic<UIColor>> { return .name(Label.Binding.textColor) }
    
    // 2. Signal bindings are performed on the object after construction.
    
    // 3. Action bindings are triggered by the object after construction.
    
    // 4. Delegate bindings require synchronous evaluation within the object's context.
}

// MARK: - Binder Part 7: Convertible protocols (if constructible)
public protocol LabelConvertible: ViewConvertible {
    func uiLabel() -> Label.Instance
}
extension LabelConvertible {
    public func uiView() -> View.Instance { return uiLabel() }
}
extension UILabel: LabelConvertible {
    public func uiLabel() -> Label.Instance { return self }
}
public extension Label {
    func uiLabel() -> Label.Instance { return instance() }
}

// MARK: - Binder Part 8: Downcast protocols
public protocol LabelBinding: ViewBinding {
    static func windowBinding(_ binding: Label.Binding) -> Self
    func asLabelBinding() -> Label.Binding?
}
public extension LabelBinding {
    static func viewBinding(_ binding: View.Binding) -> Self {
        return windowBinding(.inheritedBinding(binding))
    }
}
public extension LabelBinding where Preparer.Inherited.Binding: LabelBinding {
    func asLabelBinding() -> Label.Binding? {
        return asInheritedBinding()?.asLabelBinding()
    }
}
public extension Label.Binding {
    typealias Preparer = Label.Preparer
    func asInheritedBinding() -> Preparer.Inherited.Binding? { if case .inheritedBinding(let b) = self { return b } else { return nil } }
    func asLabelBinding() -> Label.Binding? { return self }
    static func windowBinding(_ binding: Label.Binding) -> Label.Binding {
        return binding
    }
}

public struct TextInputTraits {
    let bindings: [Binding]
    public init(bindings: [Binding]) {
        self.bindings = bindings
    }
    public init(_ bindings: Binding...) {
        self.init(bindings: bindings)
    }
    
    public enum Binding {
        case autocapitalizationType(Dynamic<UITextAutocapitalizationType>)
        case autocorrectionType(Dynamic<UITextAutocorrectionType>)
        case enablesReturnKeyAutomatically(Dynamic<Bool>)
        case isSecureTextEntry(Dynamic<Bool>)
        case keyboardAppearance(Dynamic<UIKeyboardAppearance>)
        case keyboardType(Dynamic<UIKeyboardType>)
        case returnKeyType(Dynamic<UIReturnKeyType>)
        case smartDashesType(Dynamic<UITextSmartDashesType>)
        case smartInsertDeleteType(Dynamic<UITextSmartInsertDeleteType>)
        case smartQuotesType(Dynamic<UITextSmartQuotesType>)
        case spellCheckingType(Dynamic<UITextSpellCheckingType>)
        case textContentType(Dynamic<UITextContentType>)
    }
    
    // No, you're not seeing things, this is one method, copy and pasted three times with a different instance parameter type.
    // Unfortunately, Objective-C protocols with optional, settable vars – as used in the UITextInputTraits protocol – don't work in Swift 5, so everything must be done manually, instead.
    public func apply(to instance: UISearchBar) -> Lifetime? {
        return bindings.isEmpty ? nil : AggregateLifetime(lifetimes: bindings.compactMap { trait in
            switch trait {
            case .autocapitalizationType(let x): return x.apply(instance) { i, v in i.autocapitalizationType = v }
            case .autocorrectionType(let x): return x.apply(instance) { i, v in i.autocorrectionType = v }
            case .enablesReturnKeyAutomatically(let x): return x.apply(instance) { i, v in i.enablesReturnKeyAutomatically = v }
            case .isSecureTextEntry(let x): return x.apply(instance) { i, v in i.isSecureTextEntry = v }
            case .keyboardAppearance(let x): return x.apply(instance) { i, v in i.keyboardAppearance = v }
            case .keyboardType(let x): return x.apply(instance) { i, v in i.keyboardType = v }
            case .returnKeyType(let x): return x.apply(instance) { i, v in i.returnKeyType = v }
            case .smartDashesType(let x): return x.apply(instance) { i, v in i.smartDashesType = v }
            case .smartInsertDeleteType(let x): return x.apply(instance) { i, v in i.smartInsertDeleteType = v }
            case .smartQuotesType(let x): return x.apply(instance) { i, v in i.smartQuotesType = v }
            case .spellCheckingType(let x): return x.apply(instance) { i, v in i.spellCheckingType = v }
            case .textContentType(let x): return x.apply(instance) { i, v in i.textContentType = v }
            }
        })
    }
    
    // No, you're not seeing things, this is one method, copy and pasted three times with a different instance parameter type.
    // Unfortunately, Objective-C protocols with optional, settable vars – as used in the UITextInputTraits protocol – don't work in Swift 5, so everything must be done manually, instead.
    public func apply(to instance: UITextField) -> Lifetime? {
        return bindings.isEmpty ? nil : AggregateLifetime(lifetimes: bindings.compactMap { trait in
            switch trait {
            case .autocapitalizationType(let x): return x.apply(instance) { i, v in i.autocapitalizationType = v }
            case .autocorrectionType(let x): return x.apply(instance) { i, v in i.autocorrectionType = v }
            case .enablesReturnKeyAutomatically(let x): return x.apply(instance) { i, v in i.enablesReturnKeyAutomatically = v }
            case .isSecureTextEntry(let x): return x.apply(instance) { i, v in i.isSecureTextEntry = v }
            case .keyboardAppearance(let x): return x.apply(instance) { i, v in i.keyboardAppearance = v }
            case .keyboardType(let x): return x.apply(instance) { i, v in i.keyboardType = v }
            case .returnKeyType(let x): return x.apply(instance) { i, v in i.returnKeyType = v }
            case .smartDashesType(let x): return x.apply(instance) { i, v in i.smartDashesType = v }
            case .smartInsertDeleteType(let x): return x.apply(instance) { i, v in i.smartInsertDeleteType = v }
            case .smartQuotesType(let x): return x.apply(instance) { i, v in i.smartQuotesType = v }
            case .spellCheckingType(let x): return x.apply(instance) { i, v in i.spellCheckingType = v }
            case .textContentType(let x): return x.apply(instance) { i, v in i.textContentType = v }
            }
        })
    }
    
    // No, you're not seeing things, this is one method, copy and pasted three times with a different instance parameter type.
    // Unfortunately, Objective-C protocols with optional, settable vars – as used in the UITextInputTraits protocol – don't work in Swift 5, so everything must be done manually, instead.
    public func apply(to instance: UITextView) -> Lifetime? {
        return bindings.isEmpty ? nil : AggregateLifetime(lifetimes: bindings.compactMap { trait in
            switch trait {
            case .autocapitalizationType(let x): return x.apply(instance) { i, v in i.autocapitalizationType = v }
            case .autocorrectionType(let x): return x.apply(instance) { i, v in i.autocorrectionType = v }
            case .enablesReturnKeyAutomatically(let x): return x.apply(instance) { i, v in i.enablesReturnKeyAutomatically = v }
            case .isSecureTextEntry(let x): return x.apply(instance) { i, v in i.isSecureTextEntry = v }
            case .keyboardAppearance(let x): return x.apply(instance) { i, v in i.keyboardAppearance = v }
            case .keyboardType(let x): return x.apply(instance) { i, v in i.keyboardType = v }
            case .returnKeyType(let x): return x.apply(instance) { i, v in i.returnKeyType = v }
            case .smartDashesType(let x): return x.apply(instance) { i, v in i.smartDashesType = v }
            case .smartInsertDeleteType(let x): return x.apply(instance) { i, v in i.smartInsertDeleteType = v }
            case .smartQuotesType(let x): return x.apply(instance) { i, v in i.smartQuotesType = v }
            case .spellCheckingType(let x): return x.apply(instance) { i, v in i.spellCheckingType = v }
            case .textContentType(let x): return x.apply(instance) { i, v in i.textContentType = v }
            }
        })
    }
}

extension BindingName where Source == Binding, Binding == TextInputTraits.Binding {
    // NOTE: for some reason, any attempt at a TextInputTraitsName typealias led to a compiler crash so the explicit BindingName<V, TextInputTraits.Binding, TextInputTraits.Binding> must be used instead.
    private static func name<V>(_ source: @escaping (V) -> TextInputTraits.Binding) -> BindingName<V, TextInputTraits.Binding, TextInputTraits.Binding> {
        return BindingName<V, TextInputTraits.Binding, TextInputTraits.Binding>(source: source, downcast: { b in b})
    }
}
public extension BindingName where Source == Binding, Binding == TextInputTraits.Binding {
    // You can easily convert the `Binding` cases to `BindingName` using the following Xcode-style regex:
    // Replace: case ([^\(]+)\((.+)\)$
    // With:    static var $1: BindingName<$2> { return .name(TextInputTraits.Binding.$1) }
    static var autocapitalizationType: BindingName<Dynamic<UITextAutocapitalizationType>, TextInputTraits.Binding, TextInputTraits.Binding> { return .name(TextInputTraits.Binding.autocapitalizationType) }
    static var autocorrectionType: BindingName<Dynamic<UITextAutocorrectionType>, TextInputTraits.Binding, TextInputTraits.Binding> { return .name(TextInputTraits.Binding.autocorrectionType) }
    static var enablesReturnKeyAutomatically: BindingName<Dynamic<Bool>, TextInputTraits.Binding, TextInputTraits.Binding> { return .name(TextInputTraits.Binding.enablesReturnKeyAutomatically) }
    static var isSecureTextEntry: BindingName<Dynamic<Bool>, TextInputTraits.Binding, TextInputTraits.Binding> { return .name(TextInputTraits.Binding.isSecureTextEntry) }
    static var keyboardAppearance: BindingName<Dynamic<UIKeyboardAppearance>, TextInputTraits.Binding, TextInputTraits.Binding> { return .name(TextInputTraits.Binding.keyboardAppearance) }
    static var keyboardType: BindingName<Dynamic<UIKeyboardType>, TextInputTraits.Binding, TextInputTraits.Binding> { return .name(TextInputTraits.Binding.keyboardType) }
    static var returnKeyType: BindingName<Dynamic<UIReturnKeyType>, TextInputTraits.Binding, TextInputTraits.Binding> { return .name(TextInputTraits.Binding.returnKeyType) }
    static var smartDashesType: BindingName<Dynamic<UITextSmartDashesType>, TextInputTraits.Binding, TextInputTraits.Binding> { return .name(TextInputTraits.Binding.smartDashesType) }
    static var smartInsertDeleteType: BindingName<Dynamic<UITextSmartInsertDeleteType>, TextInputTraits.Binding, TextInputTraits.Binding> { return .name(TextInputTraits.Binding.smartInsertDeleteType) }
    static var smartQuotesType: BindingName<Dynamic<UITextSmartQuotesType>, TextInputTraits.Binding, TextInputTraits.Binding> { return .name(TextInputTraits.Binding.smartQuotesType) }
    static var spellCheckingType: BindingName<Dynamic<UITextSpellCheckingType>, TextInputTraits.Binding, TextInputTraits.Binding> { return .name(TextInputTraits.Binding.spellCheckingType) }
    static var textContentType: BindingName<Dynamic<UITextContentType>, TextInputTraits.Binding, TextInputTraits.Binding> { return .name(TextInputTraits.Binding.textContentType) }
}


// MARK: - Binder Part 1: Binder
public class TextField: Binder, TextFieldConvertible {
    public var state: BinderState<Preparer>
    public required init(type: Preparer.Instance.Type, parameters: Preparer.Parameters, bindings: [Preparer.Binding]) {
        state = .pending(type: type, parameters: parameters, bindings: bindings)
    }
}

// MARK: - Binder Part 2: Binding
public extension TextField {
    enum Binding: TextFieldBinding {
        case inheritedBinding(Preparer.Inherited.Binding)
        
        //    0. Static bindings are applied at construction and are subsequently immutable.
        case textInputTraits(Constant<TextInputTraits>)
        
        //    1. Value bindings may be applied at construction and may subsequently change.
        case adjustsFontSizeToFitWidth(Dynamic<Bool>)
        case allowsEditingTextAttributes(Dynamic<Bool>)
        case attributedPlaceholder(Dynamic<NSAttributedString?>)
        case attributedText(Dynamic<NSAttributedString?>)
        case background(Dynamic<UIImage?>)
        case borderStyle(Dynamic<UITextField.BorderStyle>)
        case clearButtonMode(Dynamic<UITextField.ViewMode>)
        case clearsOnBeginEditing(Dynamic<Bool>)
        case clearsOnInsertion(Dynamic<Bool>)
        case defaultTextAttributes(Dynamic<[NSAttributedString.Key: Any]>)
        case disabledBackground(Dynamic<UIImage?>)
        case font(Dynamic<UIFont?>)
        case inputAccessoryView(Dynamic<ViewConvertible?>)
        case inputView(Dynamic<ViewConvertible?>)
        case leftView(Dynamic<ViewConvertible?>)
        case leftViewMode(Dynamic<UITextField.ViewMode>)
        case minimumFontSize(Dynamic<CGFloat>)
        case placeholder(Dynamic<String?>)
        case rightView(Dynamic<ViewConvertible?>)
        case rightViewMode(Dynamic<UITextField.ViewMode>)
        case text(Dynamic<String>)
        case textAlignment(Dynamic<NSTextAlignment>)
        case textColor(Dynamic<UIColor?>)
        case typingAttributes(Dynamic<[NSAttributedString.Key: Any]?>)
        
        //    2. Signal bindings are performed on the object after construction.
        case resignFirstResponder(Signal<Void>)
        
        //    3. Action bindings are triggered by the object after construction.
        
        //    4. Delegate bindings require synchronous evaluation within the object's context.
        case didBeginEditing((_ textField: UITextField) -> Void)
        case didChange((_ textField: UITextField) -> Void)
        case didEndEditing((_ textField: UITextField) -> Void)
        case didEndEditingWithReason((_ textField: UITextField, _ reason: UITextField.DidEndEditingReason) -> Void)
        case shouldBeginEditing((_ textField: UITextField) -> Bool)
        case shouldChangeCharacters((_ textField: UITextField, _ range: NSRange, _ replacementString: String) -> Bool)
        case shouldClear((_ textField: UITextField) -> Bool)
        case shouldEndEditing((_ textField: UITextField) -> Bool)
        case shouldReturn((_ textField: UITextField) -> Bool)
    }
}

// MARK: - Binder Part 3: Preparer
public extension TextField {
    struct Preparer: BinderDelegateEmbedderConstructor {
        public typealias Binding = TextField.Binding
        public typealias Inherited = Control.Preparer
        public typealias Instance = UITextField
        
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
public extension TextField.Preparer {
    mutating func prepareBinding(_ binding: Binding) {
        switch binding {
        case .inheritedBinding(let x): inherited.prepareBinding(x)
            
        case .didEndEditingWithReason(let x): delegate().addMultiHandler2(x, #selector(UITextFieldDelegate.textFieldDidEndEditing(_:reason:)))
        case .shouldBeginEditing(let x): delegate().addSingleHandler1(x, #selector(UITextFieldDelegate.textFieldShouldBeginEditing(_:)))
        case .shouldEndEditing(let x): delegate().addSingleHandler1(x, #selector(UITextFieldDelegate.textFieldShouldEndEditing(_:)))
        case .shouldChangeCharacters(let x): delegate().addSingleHandler3(x, #selector(UITextFieldDelegate.textField(_:shouldChangeCharactersIn:replacementString:)))
        case .shouldClear(let x): delegate().addSingleHandler1(x, #selector(UITextFieldDelegate.textFieldShouldClear(_:)))
        case .shouldReturn(let x): delegate().addSingleHandler1(x, #selector(UITextFieldDelegate.textFieldShouldReturn(_:)))
        default: break
        }
    }
    
    func applyBinding(_ binding: Binding, instance: Instance, storage: Storage) -> Lifetime? {
        switch binding {
        case .inheritedBinding(let x): return inherited.applyBinding(x, instance: instance, storage: storage)
            
        //    0. Static bindings are applied at construction and are subsequently immutable.
        case .textInputTraits(let x): return x.value.apply(to: instance)
            
        //    1. Value bindings may be applied at construction and may subsequently change.
        case .adjustsFontSizeToFitWidth(let x): return x.apply(instance) { i, v in i.adjustsFontSizeToFitWidth = v }
        case .allowsEditingTextAttributes(let x): return x.apply(instance) { i, v in i.allowsEditingTextAttributes = v }
        case .attributedPlaceholder(let x): return x.apply(instance) { i, v in i.attributedPlaceholder = v }
        case .attributedText(let x): return x.apply(instance) { i, v in i.attributedText = v }
        case .background(let x): return x.apply(instance) { i, v in i.background = v }
        case .borderStyle(let x): return x.apply(instance) { i, v in i.borderStyle = v }
        case .clearButtonMode(let x): return x.apply(instance) { i, v in i.clearButtonMode = v }
        case .clearsOnBeginEditing(let x): return x.apply(instance) { i, v in i.clearsOnBeginEditing = v }
        case .clearsOnInsertion(let x): return x.apply(instance) { i, v in i.clearsOnInsertion = v }
        case .defaultTextAttributes(let x): return x.apply(instance) { i, v in i.defaultTextAttributes = v }
        case .disabledBackground(let x): return x.apply(instance) { i, v in i.disabledBackground = v }
        case .font(let x): return x.apply(instance) { i, v in i.font = v }
        case .inputAccessoryView(let x): return x.apply(instance) { i, v in i.inputAccessoryView = v?.uiView() }
        case .inputView(let x): return x.apply(instance) { i, v in i.inputView = v?.uiView() }
        case .leftView(let x): return x.apply(instance) { i, v in i.leftView = v?.uiView() }
        case .leftViewMode(let x): return x.apply(instance) { i, v in i.leftViewMode = v }
        case .minimumFontSize(let x): return x.apply(instance) { i, v in i.minimumFontSize = v }
        case .placeholder(let x): return x.apply(instance) { i, v in i.placeholder = v }
        case .rightView(let x): return x.apply(instance) { i, v in i.rightView = v?.uiView() }
        case .rightViewMode(let x): return x.apply(instance) { i, v in i.rightViewMode = v }
        case .text(let x): return x.apply(instance) { i, v in i.text = v }
        case .textAlignment(let x): return x.apply(instance) { i, v in i.textAlignment = v }
        case .textColor(let x): return x.apply(instance) { i, v in i.textColor = v }
        case .typingAttributes(let x): return x.apply(instance) { i, v in i.typingAttributes = v }
            
        //    2. Signal bindings are performed on the object after construction.
        case .resignFirstResponder(let x): return x.apply(instance) { i, v in i.resignFirstResponder() }
            
            //    3. Action bindings are triggered by the object after construction.
            
        //    4. Delegate bindings require synchronous evaluation within the object's context.
        case .didBeginEditing(let x): return Signal.notifications(name: UITextField.textDidBeginEditingNotification, object: instance).compactMap { notification in return notification.object as? UITextField }.subscribeValues { field in x(field) }
        case .didChange(let x): return Signal.notifications(name: UITextField.textDidChangeNotification, object: instance).compactMap { notification in return notification.object as? UITextField }.subscribeValues { field in x(field) }
        case .didEndEditing(let x): return Signal.notifications(name: UITextField.textDidEndEditingNotification, object: instance).compactMap { notification in return notification.object as? UITextField }.subscribeValues { field in x(field) }
        case .shouldBeginEditing: return nil
        case .shouldChangeCharacters: return nil
        case .shouldClear: return nil
        case .shouldEndEditing: return nil
        case .shouldReturn: return nil
            
        case .didEndEditingWithReason: return nil
        }
    }
}

// MARK: - Binder Part 5: Storage and Delegate
extension TextField.Preparer {
    open class Storage: Control.Preparer.Storage, UITextFieldDelegate {}
    
    open class Delegate: DynamicDelegate, UITextFieldDelegate {
        open func textFieldShouldBeginEditing(_ textField: UITextField) -> Bool {
            return singleHandler(textField)
        }
        
        open func textFieldShouldEndEditing(_ textField: UITextField) -> Bool {
            return singleHandler(textField)
        }
        
        open func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
            return singleHandler(textField, range, string)
        }
        
        open func textFieldShouldClear(_ textField: UITextField) -> Bool {
            return singleHandler(textField)
        }
        
        open func textFieldShouldReturn(_ textField: UITextField) -> Bool {
            return singleHandler(textField)
        }
        
        open func textFieldDidEndEditing(_ textField: UITextField, reason: UITextField.DidEndEditingReason) {
            multiHandler(textField, reason)
        }
    }
}

// MARK: - Binder Part 6: BindingNames
extension BindingName where Binding: TextFieldBinding {
    public typealias TextFieldName<V> = BindingName<V, TextField.Binding, Binding>
    private static func name<V>(_ source: @escaping (V) -> TextField.Binding) -> TextFieldName<V> {
        return TextFieldName<V>(source: source, downcast: Binding.textFieldBinding)
    }
}
public extension BindingName where Binding: TextFieldBinding {
    // You can easily convert the `Binding` cases to `BindingName` using the following Xcode-style regex:
    // Replace: case ([^\(]+)\((.+)\)$
    // With:    static var $1: TextFieldName<$2> { return .name(TextField.Binding.$1) }
    
    //    0. Static bindings are applied at construction and are subsequently immutable.
    static var textInputTraits: TextFieldName<Constant<TextInputTraits>> { return .name(TextField.Binding.textInputTraits) }
    
    //    1. Value bindings may be applied at construction and may subsequently change.
    static var adjustsFontSizeToFitWidth: TextFieldName<Dynamic<Bool>> { return .name(TextField.Binding.adjustsFontSizeToFitWidth) }
    static var allowsEditingTextAttributes: TextFieldName<Dynamic<Bool>> { return .name(TextField.Binding.allowsEditingTextAttributes) }
    static var attributedPlaceholder: TextFieldName<Dynamic<NSAttributedString?>> { return .name(TextField.Binding.attributedPlaceholder) }
    static var attributedText: TextFieldName<Dynamic<NSAttributedString?>> { return .name(TextField.Binding.attributedText) }
    static var background: TextFieldName<Dynamic<UIImage?>> { return .name(TextField.Binding.background) }
    static var borderStyle: TextFieldName<Dynamic<UITextField.BorderStyle>> { return .name(TextField.Binding.borderStyle) }
    static var clearButtonMode: TextFieldName<Dynamic<UITextField.ViewMode>> { return .name(TextField.Binding.clearButtonMode) }
    static var clearsOnBeginEditing: TextFieldName<Dynamic<Bool>> { return .name(TextField.Binding.clearsOnBeginEditing) }
    static var clearsOnInsertion: TextFieldName<Dynamic<Bool>> { return .name(TextField.Binding.clearsOnInsertion) }
    static var defaultTextAttributes: TextFieldName<Dynamic<[NSAttributedString.Key: Any]>> { return .name(TextField.Binding.defaultTextAttributes) }
    static var disabledBackground: TextFieldName<Dynamic<UIImage?>> { return .name(TextField.Binding.disabledBackground) }
    static var font: TextFieldName<Dynamic<UIFont?>> { return .name(TextField.Binding.font) }
    static var inputAccessoryView: TextFieldName<Dynamic<ViewConvertible?>> { return .name(TextField.Binding.inputAccessoryView) }
    static var inputView: TextFieldName<Dynamic<ViewConvertible?>> { return .name(TextField.Binding.inputView) }
    static var leftView: TextFieldName<Dynamic<ViewConvertible?>> { return .name(TextField.Binding.leftView) }
    static var leftViewMode: TextFieldName<Dynamic<UITextField.ViewMode>> { return .name(TextField.Binding.leftViewMode) }
    static var minimumFontSize: TextFieldName<Dynamic<CGFloat>> { return .name(TextField.Binding.minimumFontSize) }
    static var placeholder: TextFieldName<Dynamic<String?>> { return .name(TextField.Binding.placeholder) }
    static var rightView: TextFieldName<Dynamic<ViewConvertible?>> { return .name(TextField.Binding.rightView) }
    static var rightViewMode: TextFieldName<Dynamic<UITextField.ViewMode>> { return .name(TextField.Binding.rightViewMode) }
    static var text: TextFieldName<Dynamic<String>> { return .name(TextField.Binding.text) }
    static var textAlignment: TextFieldName<Dynamic<NSTextAlignment>> { return .name(TextField.Binding.textAlignment) }
    static var textColor: TextFieldName<Dynamic<UIColor?>> { return .name(TextField.Binding.textColor) }
    static var typingAttributes: TextFieldName<Dynamic<[NSAttributedString.Key: Any]?>> { return .name(TextField.Binding.typingAttributes) }
    
    //    2. Signal bindings are performed on the object after construction.
    static var resignFirstResponder: TextFieldName<Signal<Void>> { return .name(TextField.Binding.resignFirstResponder) }
    
    //    3. Action bindings are triggered by the object after construction.
    
    //    4. Delegate bindings require synchronous evaluation within the object's context.
    static var didBeginEditing: TextFieldName<(_ textField: UITextField) -> Void> { return .name(TextField.Binding.didBeginEditing) }
    static var didChange: TextFieldName<(_ textField: UITextField) -> Void> { return .name(TextField.Binding.didChange) }
    static var didEndEditing: TextFieldName<(_ textField: UITextField) -> Void> { return .name(TextField.Binding.didEndEditing) }
    static var didEndEditingWithReason: TextFieldName<(_ textField: UITextField, _ reason: UITextField.DidEndEditingReason) -> Void> { return .name(TextField.Binding.didEndEditingWithReason) }
    static var shouldBeginEditing: TextFieldName<(_ textField: UITextField) -> Bool> { return .name(TextField.Binding.shouldBeginEditing) }
    static var shouldChangeCharacters: TextFieldName<(_ textField: UITextField, _ range: NSRange, _ replacementString: String) -> Bool> { return .name(TextField.Binding.shouldChangeCharacters) }
    static var shouldClear: TextFieldName<(_ textField: UITextField) -> Bool> { return .name(TextField.Binding.shouldClear) }
    static var shouldEndEditing: TextFieldName<(_ textField: UITextField) -> Bool> { return .name(TextField.Binding.shouldEndEditing) }
    static var shouldReturn: TextFieldName<(_ textField: UITextField) -> Bool> { return .name(TextField.Binding.shouldReturn) }
    
    // Composite binding names
    static func textChanged(_ void: Void = ()) -> TextFieldName<SignalInput<String>> {
        return Binding.compositeName(
            value: { input in { textField in textField.text.map { _ = input.send(value: $0) } } },
            binding: TextField.Binding.didChange,
            downcast: Binding.textFieldBinding
        )
    }
    static func attributedTextChanged(_ void: Void = ()) -> TextFieldName<SignalInput<NSAttributedString>> {
        return Binding.compositeName(
            value: { input in { textField in textField.attributedText.map { _ = input.send(value: $0) } } },
            binding: TextField.Binding.didChange,
            downcast: Binding.textFieldBinding
        )
    }
}

// MARK: - Binder Part 7: Convertible protocols (if constructible)
public protocol TextFieldConvertible: ControlConvertible {
    func uiTextField() -> TextField.Instance
}
extension TextFieldConvertible {
    public func uiControl() -> Control.Instance { return uiTextField() }
}
extension UITextField: TextFieldConvertible, HasDelegate {
    public func uiTextField() -> TextField.Instance { return self }
}
public extension TextField {
    func uiTextField() -> TextField.Instance { return instance() }
}

// MARK: - Binder Part 8: Downcast protocols
public protocol TextFieldBinding: ControlBinding {
    static func textFieldBinding(_ binding: TextField.Binding) -> Self
    func asTextFieldBinding() -> TextField.Binding?
}
public extension TextFieldBinding {
    static func controlBinding(_ binding: Control.Binding) -> Self {
        return textFieldBinding(.inheritedBinding(binding))
    }
}
public extension TextFieldBinding where Preparer.Inherited.Binding: TextFieldBinding {
    func asTextFieldBinding() -> TextField.Binding? {
        return asInheritedBinding()?.asTextFieldBinding()
    }
}
public extension TextField.Binding {
    typealias Preparer = TextField.Preparer
    func asInheritedBinding() -> Preparer.Inherited.Binding? { if case .inheritedBinding(let b) = self { return b } else { return nil } }
    func asTextFieldBinding() -> TextField.Binding? { return self }
    static func textFieldBinding(_ binding: TextField.Binding) -> TextField.Binding {
        return binding
    }
}

// MARK: - Binder Part 9: Other supporting types
public func textFieldResignOnReturn(condition: @escaping (UITextField) -> Bool = { _ in return true }) -> (UITextField) -> Bool {
    return { tf in
        if condition(tf) {
            tf.resignFirstResponder()
            return false
        }
        return true
    }
}

// MARK: - Binder Part 1: Binder
public class PanGestureRecognizer: Binder, PanGestureRecognizerConvertible {
    public var state: BinderState<Preparer>
    public required init(type: Preparer.Instance.Type, parameters: Preparer.Parameters, bindings: [Preparer.Binding]) {
        state = .pending(type: type, parameters: parameters, bindings: bindings)
    }
}

// MARK: - Binder Part 2: Binding
public extension PanGestureRecognizer {
    enum Binding: PanGestureRecognizerBinding {
        case inheritedBinding(Preparer.Inherited.Binding)
        
        //    0. Static bindings are applied at construction and are subsequently immutable.
        
        // 1. Value bindings may be applied at construction and may subsequently change.
        case maximumNumberOfTouches(Dynamic<Int>)
        case minimumNumberOfTouches(Dynamic<Int>)
        case translation(Dynamic<CGPoint>)
        
        // 2. Signal bindings are performed on the object after construction.
        
        // 3. Action bindings are triggered by the object after construction.
        
        // 4. Delegate bindings require synchronous evaluation within the object's context.
    }
}

// MARK: - Binder Part 3: Preparer
public extension PanGestureRecognizer {
    struct Preparer: BinderEmbedderConstructor {
        public typealias Binding = PanGestureRecognizer.Binding
        public typealias Inherited = GestureRecognizer.Preparer
        public typealias Instance = UIPanGestureRecognizer
        
        public var inherited = Inherited()
        public init() {}
        public func constructStorage(instance: Instance) -> Storage { return Storage() }
        public func inheritedBinding(from: Binding) -> Inherited.Binding? {
            if case .inheritedBinding(let b) = from { return b } else { return nil }
        }
    }
}

// MARK: - Binder Part 4: Preparer overrides
public extension PanGestureRecognizer.Preparer {
    func applyBinding(_ binding: Binding, instance: Instance, storage: Storage) -> Lifetime? {
        switch binding {
        case .inheritedBinding(let x): return inherited.applyBinding(x, instance: instance, storage: storage)
            
            //    0. Static bindings are applied at construction and are subsequently immutable.
            
        // 1. Value bindings may be applied at construction and may subsequently change.
        case .maximumNumberOfTouches(let x): return x.apply(instance) { i, v in i.maximumNumberOfTouches = v }
        case .minimumNumberOfTouches(let x): return x.apply(instance) { i, v in i.minimumNumberOfTouches = v }
        case .translation(let x): return x.apply(instance) { i, v in i.setTranslation(v, in: nil) }
            
            // 2. Signal bindings are performed on the object after construction.
            
            // 3. Action bindings are triggered by the object after construction.
            
            // 4. Delegate bindings require synchronous evaluation within the object's context.
        }
    }
}

// MARK: - Binder Part 5: Storage and Delegate
extension PanGestureRecognizer.Preparer {
    public typealias Storage = GestureRecognizer.Preparer.Storage
}

// MARK: - Binder Part 6: BindingNames
extension BindingName where Binding: PanGestureRecognizerBinding {
    public typealias PanGestureRecognizerName<V> = BindingName<V, PanGestureRecognizer.Binding, Binding>
    private static func name<V>(_ source: @escaping (V) -> PanGestureRecognizer.Binding) -> PanGestureRecognizerName<V> {
        return PanGestureRecognizerName<V>(source: source, downcast: Binding.panGestureRecognizerBinding)
    }
}
public extension BindingName where Binding: PanGestureRecognizerBinding {
    // You can easily convert the `Binding` cases to `BindingName` using the following Xcode-style regex:
    // Replace: case ([^\(]+)\((.+)\)$
    // With:    static var $1: PanGestureRecognizerName<$2> { return .name(PanGestureRecognizer.Binding.$1) }
    
    //    0. Static bindings are applied at construction and are subsequently immutable.
    
    // 1. Value bindings may be applied at construction and may subsequently change.
    static var maximumNumberOfTouches: PanGestureRecognizerName<Dynamic<Int>> { return .name(PanGestureRecognizer.Binding.maximumNumberOfTouches) }
    static var minimumNumberOfTouches: PanGestureRecognizerName<Dynamic<Int>> { return .name(PanGestureRecognizer.Binding.minimumNumberOfTouches) }
    static var translation: PanGestureRecognizerName<Dynamic<CGPoint>> { return .name(PanGestureRecognizer.Binding.translation) }
    
    // 2. Signal bindings are performed on the object after construction.
    
    // 3. Action bindings are triggered by the object after construction.
    
    // 4. Delegate bindings require synchronous evaluation within the object's context.
}

// MARK: - Binder Part 7: Convertible protocols (if constructible)
public protocol PanGestureRecognizerConvertible: GestureRecognizerConvertible {
    func uiPanGestureRecognizer() -> PanGestureRecognizer.Instance
}
extension PanGestureRecognizerConvertible {
    public func uiGestureRecognizer() -> GestureRecognizer.Instance { return uiPanGestureRecognizer() }
}
extension UIPanGestureRecognizer: PanGestureRecognizerConvertible {
    public func uiPanGestureRecognizer() -> PanGestureRecognizer.Instance { return self }
}
public extension PanGestureRecognizer {
    func uiPanGestureRecognizer() -> PanGestureRecognizer.Instance { return instance() }
}

// MARK: - Binder Part 8: Downcast protocols
public protocol PanGestureRecognizerBinding: GestureRecognizerBinding {
    static func panGestureRecognizerBinding(_ binding: PanGestureRecognizer.Binding) -> Self
    func asPanGestureRecognizerBinding() -> PanGestureRecognizer.Binding?
}
public extension PanGestureRecognizerBinding {
    static func gestureRecognizerBinding(_ binding: GestureRecognizer.Binding) -> Self {
        return panGestureRecognizerBinding(.inheritedBinding(binding))
    }
}
public extension PanGestureRecognizerBinding where Preparer.Inherited.Binding: PanGestureRecognizerBinding {
    func asPanGestureRecognizerBinding() -> PanGestureRecognizer.Binding? {
        return asInheritedBinding()?.asPanGestureRecognizerBinding()
    }
}
public extension PanGestureRecognizer.Binding {
    typealias Preparer = PanGestureRecognizer.Preparer
    func asInheritedBinding() -> Preparer.Inherited.Binding? { if case .inheritedBinding(let b) = self { return b } else { return nil } }
    func asPanGestureRecognizerBinding() -> PanGestureRecognizer.Binding? { return self }
    static func panGestureRecognizerBinding(_ binding: PanGestureRecognizer.Binding) -> PanGestureRecognizer.Binding {
        return binding
    }
}

// MARK: - Binder Part 9: Other supporting types

// MARK: - Binder Part 1: Binder
public class PinchGestureRecognizer: Binder, PinchGestureRecognizerConvertible {
    public var state: BinderState<Preparer>
    public required init(type: Preparer.Instance.Type, parameters: Preparer.Parameters, bindings: [Preparer.Binding]) {
        state = .pending(type: type, parameters: parameters, bindings: bindings)
    }
}

// MARK: - Binder Part 2: Binding
public extension PinchGestureRecognizer {
    enum Binding: PinchGestureRecognizerBinding {
        case inheritedBinding(Preparer.Inherited.Binding)
        
        //    0. Static bindings are applied at construction and are subsequently immutable.
        
        // 1. Value bindings may be applied at construction and may subsequently change.
        case scale(Dynamic<CGFloat>)
        
        // 2. Signal bindings are performed on the object after construction.
        
        // 3. Action bindings are triggered by the object after construction.
        
        // 4. Delegate bindings require synchronous evaluation within the object's context.
    }
}

// MARK: - Binder Part 3: Preparer
public extension PinchGestureRecognizer {
    struct Preparer: BinderEmbedderConstructor {
        public typealias Binding = PinchGestureRecognizer.Binding
        public typealias Inherited = GestureRecognizer.Preparer
        public typealias Instance = UIPinchGestureRecognizer
        
        public var inherited = Inherited()
        public init() {}
        public func constructStorage(instance: Instance) -> Storage { return Storage() }
        public func inheritedBinding(from: Binding) -> Inherited.Binding? {
            if case .inheritedBinding(let b) = from { return b } else { return nil }
        }
    }
}

// MARK: - Binder Part 4: Preparer overrides
public extension PinchGestureRecognizer.Preparer {
    func applyBinding(_ binding: Binding, instance: Instance, storage: Storage) -> Lifetime? {
        switch binding {
        case .inheritedBinding(let x): return inherited.applyBinding(x, instance: instance, storage: storage)
            
            //    0. Static bindings are applied at construction and are subsequently immutable.
            
        // 1. Value bindings may be applied at construction and may subsequently change.
        case .scale(let x): return x.apply(instance) { i, v in i.scale = v }
            
            // 2. Signal bindings are performed on the object after construction.
            
            // 3. Action bindings are triggered by the object after construction.
            
            // 4. Delegate bindings require synchronous evaluation within the object's context.
        }
    }
}

// MARK: - Binder Part 5: Storage and Delegate
extension PinchGestureRecognizer.Preparer {
    public typealias Storage = GestureRecognizer.Preparer.Storage
}

// MARK: - Binder Part 6: BindingNames
extension BindingName where Binding: PinchGestureRecognizerBinding {
    public typealias PinchGestureRecognizerName<V> = BindingName<V, PinchGestureRecognizer.Binding, Binding>
    private static func name<V>(_ source: @escaping (V) -> PinchGestureRecognizer.Binding) -> PinchGestureRecognizerName<V> {
        return PinchGestureRecognizerName<V>(source: source, downcast: Binding.pinchGestureRecognizerBinding)
    }
}
public extension BindingName where Binding: PinchGestureRecognizerBinding {
    // You can easily convert the `Binding` cases to `BindingName` using the following Xcode-style regex:
    // Replace: case ([^\(]+)\((.+)\)$
    // With:    static var $1: PinchGestureRecognizerName<$2> { return .name(PinchGestureRecognizer.Binding.$1) }
    
    //    0. Static bindings are applied at construction and are subsequently immutable.
    
    // 1. Value bindings may be applied at construction and may subsequently change.
    static var scale: PinchGestureRecognizerName<Dynamic<CGFloat>> { return .name(PinchGestureRecognizer.Binding.scale) }
    
    // 2. Signal bindings are performed on the object after construction.
    
    // 3. Action bindings are triggered by the object after construction.
    
    // 4. Delegate bindings require synchronous evaluation within the object's context.
}

// MARK: - Binder Part 7: Convertible protocols (if constructible)
public protocol PinchGestureRecognizerConvertible: GestureRecognizerConvertible {
    func uiPinchGestureRecognizer() -> PinchGestureRecognizer.Instance
}
extension PinchGestureRecognizerConvertible {
    public func uiGestureRecognizer() -> GestureRecognizer.Instance { return uiPinchGestureRecognizer() }
}
extension UIPinchGestureRecognizer: PinchGestureRecognizerConvertible {
    public func uiPinchGestureRecognizer() -> PinchGestureRecognizer.Instance { return self }
}
public extension PinchGestureRecognizer {
    func uiPinchGestureRecognizer() -> PinchGestureRecognizer.Instance { return instance() }
}

// MARK: - Binder Part 8: Downcast protocols
public protocol PinchGestureRecognizerBinding: GestureRecognizerBinding {
    static func pinchGestureRecognizerBinding(_ binding: PinchGestureRecognizer.Binding) -> Self
    func asPinchGestureRecognizerBinding() -> PinchGestureRecognizer.Binding?
}
public extension PinchGestureRecognizerBinding {
    static func gestureRecognizerBinding(_ binding: GestureRecognizer.Binding) -> Self {
        return pinchGestureRecognizerBinding(.inheritedBinding(binding))
    }
}
public extension PinchGestureRecognizerBinding where Preparer.Inherited.Binding: PinchGestureRecognizerBinding {
    func asPinchGestureRecognizerBinding() -> PinchGestureRecognizer.Binding? {
        return asInheritedBinding()?.asPinchGestureRecognizerBinding()
    }
}
public extension PinchGestureRecognizer.Binding {
    typealias Preparer = PinchGestureRecognizer.Preparer
    func asInheritedBinding() -> Preparer.Inherited.Binding? { if case .inheritedBinding(let b) = self { return b } else { return nil } }
    func asPinchGestureRecognizerBinding() -> PinchGestureRecognizer.Binding? { return self }
    static func pinchGestureRecognizerBinding(_ binding: PinchGestureRecognizer.Binding) -> PinchGestureRecognizer.Binding {
        return binding
    }
}

// MARK: - Binder Part 9: Other supporting types
