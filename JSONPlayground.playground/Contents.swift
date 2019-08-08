import UIKit
import WebKit

fileprivate let screengraphJSCommand = "window.cs_wvt.push(['serializeWebView'])"

extension WKWebView {
    
    func screengraph(_ completion: @escaping (AnyCodable) -> ()) {
        self.evaluateJavaScript(screengraphJSCommand) { (result, error) in
            print("SCREENGRAPH ERROR: \(error) RESULT: \(result)")
            let stringy = result as! String
            let anyCodable = try? JSONDecoder().decode(AnyCodable.self, from: stringy.data(using: .utf8)!)
            
            completion(anyCodable ?? AnyCodable(nil))
        }
    }
}


struct ViewIteratorProtocol: IteratorProtocol {
    
    public typealias Element = UIView
    private var currentView: UIView?
    
    init(startView: UIView) {
        self.currentView = startView
    }
    
    public mutating func next() -> UIView? {
        let toReturn = currentView?.superview
        defer {
            currentView = toReturn
        }
        return toReturn
    }
}

protocol IterableView {
    
    func superviewsIterator() -> ViewIteratorProtocol
}


extension UIView: IterableView {
    
    func superviewsIterator() -> ViewIteratorProtocol {
        return ViewIteratorProtocol(startView: self)
    }
    
    private var viewToRootPath: String {
        var viewPath: String = "[root]>"
        
        var superviewsIterator: ViewIteratorProtocol = self.superviewsIterator()
        
        var superviewsPath: String = ""
        while let superview = superviewsIterator.next() {
            superviewsPath = "\(superview.className):eq(\(superview.viewLayerIndexInSuperview))>\(superviewsPath)"
        }
        
        viewPath.append(superviewsPath)
        viewPath.append("\(self.className):eq(\(self.viewLayerIndexInSuperview))")
        return viewPath
    }
    
    var viewId: String {
        if let restorationId = self.restorationIdentifier { // swiftlint:disable:this id_instead_of_identifier
            return restorationId
        } else if tag != 0 {
            return "\(self.className)_\(tag)"
        } else {
            return "\(self.className)_\(self.viewToRootPath.hash)"
        }
    }
    
    var viewHierarchyPath: String {
        var viewPath: String = self.viewToRootPath
        
        viewPath.append("#\(self.viewId)")
        return viewPath
    }
    
    var parentViewController: UIViewController? {
        var parentResponder: UIResponder? = self
        while parentResponder != nil {
            parentResponder = parentResponder?.next
            if let viewController = parentResponder as? UIViewController {
                return viewController
            }
        }
        return nil
    }
    
    var viewURL: String {
        var finalString = ""
        if let parent = parentViewController {
            if let grandParent = parentViewController?.parent {
                finalString = "/" + (grandParent.title ?? "\(type(of: grandParent))")
                    + "/" + (parent.title ?? "\(type(of: parent))")
            } else {
                finalString = "/" + (parent.title ?? "\(type(of: parent))")
                    + "/" + "\(type(of: self))"
            }
        } else {
            finalString = "/root" + "/" + "\(type(of: self))"
        }
        
        return finalString.replacingOccurrences(of: " ", with: "_")
    }
    
    var viewLayerIndexInSuperview: Int {
        return self.superview?.subviews.index { $0 == self } ?? 0
    }
    
    var className: String {
        return String(describing: type(of: self))
    }
}

public struct AnyCodable {
    
    // MARK: Initialization
    public init(_ value: Any?) {
        self.value = value
    }
    
    // MARK: Accessing Attributes
    public let value: Any?
}

public extension AnyCodable {
    
    public func assertValue<T>(_ type: T.Type) throws -> T {
        
        switch type {
        case is NSNull.Type where self.value == nil:
            return NSNull() as! T
        default:
            guard let value = self.value as? T else {
                throw Error.typeMismatch(Swift.type(of: self.value))
            }
            
            return value
        }
    }
}

public extension AnyCodable {
    
    public enum Error: Swift.Error {
        case typeMismatch(Any.Type)
    }
}

extension AnyCodable: Codable {
    
    public init(from decoder: Decoder) throws {
        
        let container = try decoder.singleValueContainer()
        
        if let value = try? container.decode(String.self) {
            self.value = value
        } else if let value = try? container.decode(Bool.self) {
            self.value = value
        } else if container.decodeNil() {
            self.value = nil
        } else if let value = try? container.decode([String: AnyCodable].self) {
            self.value = value.mapValues { $0.value }
        } else if let value = try? container.decode([AnyCodable].self) {
            self.value = value.map { $0.value }
        } else if let value = try? container.decode(Double.self) {
            switch value {
            case value.rounded():
                self.value = Int(value)
            default:
                self.value = value
            }
        } else {
            throw DecodingError.dataCorruptedError(
                in: container,
                debugDescription: "Invalid value cannot be decoded"
            )
        }
    }
    
    public func encode(to encoder: Encoder) throws {
        
        var container = encoder.singleValueContainer()
        
        guard let value = self.value else {
            try container.encodeNil()
            return
        }
        
        switch value {
        case let value as String:
            try container.encode(value)
        case let value as Bool:
            try container.encode(value)
        case let value as Int:
            try container.encode(value)
        case let value as Int8:
            try container.encode(value)
        case let value as Int16:
            try container.encode(value)
        case let value as Int32:
            try container.encode(value)
        case let value as Int64:
            try container.encode(value)
        case let value as UInt:
            try container.encode(value)
        case let value as UInt8:
            try container.encode(value)
        case let value as UInt16:
            try container.encode(value)
        case let value as UInt32:
            try container.encode(value)
        case let value as UInt64:
            try container.encode(value)
        case let value as Array<Any?>:
            try container.encode(value.map { AnyCodable($0) })
        case let value as Dictionary<String, Any?>:
            try container.encode(value.mapValues { AnyCodable($0) })
        case let value as Float:
            try container.encode(value)
        case let value as Double:
            try container.encode(value)
        case let value as Decimal:
            try container.encode(value)
        case let value as NSDecimalNumber:
            try container.encode(value.decimalValue)
        case is NSNull:
            try container.encodeNil()
        case let value as NSNumber:
            try container.encode(value.doubleValue)
        default:
            throw EncodingError.invalidValue(
                value,
                EncodingError.Context(
                    codingPath: container.codingPath,
                    debugDescription: "Invalid value cannot be encoded"
                )
            )
        }
    }
}

extension AnyCodable: Equatable {
    
    public static func == (lhs: AnyCodable, rhs: AnyCodable) -> Bool {
        
        switch (lhs.value, rhs.value) {
        case (let lhs as String, let rhs as String):
            return lhs == rhs
        case (let lhs as Bool, let rhs as Bool):
            return lhs == rhs
        case (let lhs as Int, let rhs as Int):
            return lhs == rhs
        case (let lhs as Int8, let rhs as Int8):
            return lhs == rhs
        case (let lhs as Int16, let rhs as Int16):
            return lhs == rhs
        case (let lhs as Int32, let rhs as Int32):
            return lhs == rhs
        case (let lhs as Int64, let rhs as Int64):
            return lhs == rhs
        case (let lhs as UInt, let rhs as UInt):
            return lhs == rhs
        case (let lhs as UInt8, let rhs as UInt8):
            return lhs == rhs
        case (let lhs as UInt16, let rhs as UInt16):
            return lhs == rhs
        case (let lhs as UInt32, let rhs as UInt32):
            return lhs == rhs
        case (let lhs as UInt64, let rhs as UInt64):
            return lhs == rhs
        case (let lhs as Float, let rhs as Float):
            return lhs == rhs
        case (let lhs as Double, let rhs as Double):
            return lhs == rhs
        case (let lhs as [String: AnyCodable], let rhs as [String: AnyCodable]):
            return lhs == rhs
        case (let lhs as [AnyCodable], let rhs as [AnyCodable]):
            return lhs == rhs
        case (is NSNull, is NSNull):
            return true
        default:
            return false
        }
    }
}

extension AnyCodable: CustomStringConvertible {
    
    public var description: String {
        
        switch self.value {
        case let value as CustomStringConvertible:
            return value.description
        default:
            return String(describing: self.value)
        }
    }
}

extension AnyCodable: CustomDebugStringConvertible {
    
    public var debugDescription: String {
        
        switch self.value {
        case let value as CustomDebugStringConvertible:
            return value.debugDescription
        default:
            return self.description
        }
    }
}

import Foundation
import WebKit

enum GraphFormat: Int, Codable {
    case webElement = 0
    case mobileView = 1
    case webViewContainer = 2
}

// swiftlint:disable all

protocol GraphView: Codable {
    
    var format: GraphFormat { get }
}

final class NativeGraphview: GraphView {
    
    let format = GraphFormat.mobileView
    
    enum CodingKeys: String, CodingKey {
        
        case format
        case id
        case width
        case height
        case xPos = "x"
        case yPos = "y"
        case background = "bg"
        case bitmap = "bmp"
        case metadata
        case visibility
        case alpha
        case subViews = "children"
    }
    
    let id: String
    let width: Int
    let height: Int
    let xPos: Int
    let yPos: Int
    let background: String?
    let bitmap: String?
    let metadata: Metadata
    let visibility: Bool
    let alpha: Float
    var subViews: [AnyGraphView]
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(width, forKey: .width)
        try container.encode(height, forKey: .height)
        try container.encode(xPos, forKey: .xPos)
        try container.encode(yPos, forKey: .yPos)
        if let background = background {
            try container.encode(background, forKey: .background)
        }
        
        if let bitmap = bitmap {
            try container.encode(bitmap, forKey: .bitmap)
        }
        try container.encode(metadata, forKey: .metadata)
        try container.encode(visibility, forKey: .visibility)
        try container.encode(alpha, forKey: .alpha)
        try container.encode(subViews, forKey: .subViews)
    }
    
    required init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        id = try values.decode(String.self, forKey: .id)
        width = try values.decode(Int.self, forKey: .width)
        height = try values.decode(Int.self, forKey: .height)
        xPos = try values.decode(Int.self, forKey: .xPos)
        yPos = try values.decode(Int.self, forKey: .yPos)
        background = try? values.decode(String.self, forKey: .background)
        bitmap = try? values.decode(String.self, forKey: .bitmap)
        metadata = try values.decode(Metadata.self, forKey: .metadata)
        visibility = try values.decode(Bool.self, forKey: .visibility)
        alpha = try values.decode(Float.self, forKey: .alpha)
        subViews = try values.decode([AnyGraphView].self, forKey: .subViews)
    }
    
    init(id: String,
         width: Int,
         height: Int,
         xPos: Int,
         yPos: Int,
         background: String?,
         bitmap: String?,
         metadata: Metadata,
         visibility: Bool,
         alpha: Float,
         subViews: [AnyGraphView]) {
        
        self.id = id
        self.width = width
        self.height = height
        self.xPos = xPos
        self.yPos = yPos
        self.background = background
        self.bitmap = bitmap
        self.metadata = metadata
        self.visibility = visibility
        self.alpha = alpha
        self.subViews = subViews
    }
    
    struct Metadata: Codable {
        
        enum CodingKeys: String, CodingKey {
            
            case className = "class_name"
            case fullpath
            case childOrder = "child_order"
        }
        
        let className: String?
        let fullpath: String?
        let childOrder: String?
        
        func encode(to encoder: Encoder) throws {
            var container = encoder.container(keyedBy: CodingKeys.self)
            try container.encode(className, forKey: .className)
            try container.encode(fullpath, forKey: .fullpath)
            try container.encode(childOrder, forKey: .childOrder)
        }
        
        init(from decoder: Decoder) throws {
            let values = try decoder.container(keyedBy: CodingKeys.self)
            className = try values.decode(String.self, forKey: .className)
            fullpath = try values.decode(String.self, forKey: .fullpath)
            childOrder = try values.decode(String.self, forKey: .childOrder)
        }
        
        init(view: UIView) {
            className = view.className
            fullpath = view.viewHierarchyPath
            childOrder = "\(view.viewLayerIndexInSuperview)"
        }
    }
}

final class WebContainerGraphView: GraphView {
    
    let format = GraphFormat.webViewContainer
    let value: AnyCodable
    
    required init(value: AnyCodable) {
        self.value = value
    }
    
    // Codable
    func encode(to encoder: Encoder) throws {
        try value.encode(to: encoder)
    }
    
    init(from decoder: Decoder) throws {
        value = try AnyCodable(from: decoder)
    }
}

class GraphViewGenerator {
    var dispatchCount = 0
    
    func encode(fromView view: UIView, completion: @escaping (AnyGraphView) -> ()) {
        
        if let webView = view as? WKWebView {
            webView.screengraph { (anyCodable) in
                completion(AnyGraphView(graph: WebContainerGraphView(value: anyCodable)))
            }
            return
        }
        
        // This initializes all the screengraph view parameters
        let id = "\(view.hash)"
        let width = Int(view.frame.width)
        let height = Int(view.frame.height)
        
        // Convert the origin of the given view to the window coordinate system
        var relativeOrigin = view.frame.origin
        if let superView = view.superview {
            relativeOrigin = superView.convert(view.frame.origin, to: nil)
        }
        
        let xPos = Int(relativeOrigin.x)
        let yPos = Int(relativeOrigin.y)
        
        let metadata = NativeGraphview.Metadata(view: view)
        
        // The next few sections contain code in aid of
        // dealing with background color alpha
        // Our front end can not cope with both a view layer alpha and a
        // background color alpha.
        // So instead, we override the view layer alpha with the background color alpha
        // in certain situations.
        // Similarly we will use white instead of black for 'clear' colors, which overrides iOS 'clear' color
        // which is a black with alpha 0
        
        // A UIControl or UIImageView should be considered final
        let isFinal = (view is UIControl && !(view is UISegmentedControl)) || view is UIImageView || view is UITextView
        // Encode as bitmap if I have no subviews or if I am a control
        let bitmap: String?
        let background: String?
        if view.subviews.isEmpty || isFinal {
            bitmap = "this would be a bitmap"
            background = bitmap != nil ? nil : "White"
        } else {
            bitmap = nil
            background = "White"
        }
        let visibility = !view.isHidden
        
        let alpha: Float
        if background != nil {
            let viewAlpha = view.alpha
            if viewAlpha == 1 {
                alpha = Float(view.backgroundColor?.cgColor.alpha ?? 1)
            } else {
                alpha = Float(viewAlpha)
            }
        } else {
            alpha = Float(view.alpha)
        }
        
        // Only encode subviews if I am NOT final
        let subViews = [AnyGraphView]()
        
        let newNativeGraph = NativeGraphview(id: id,
                                             width: width,
                                             height: height,
                                             xPos: xPos,
                                             yPos: yPos,
                                             background: background,
                                             bitmap: bitmap,
                                             metadata: metadata,
                                             visibility: visibility,
                                             alpha: alpha,
                                             subViews: subViews)
        
        if isFinal || view.subviews.isEmpty {
            completion(AnyGraphView(graph: newNativeGraph))
        } else {
            self.dispatchCount = view.subviews.count
            for view in view.subviews {
                GraphViewGenerator().encode(fromView: view, completion: { (graphView) in
                    newNativeGraph.subViews.append(graphView)
                    self.dispatchCount -= 1
                    if self.dispatchCount == 1 {
                        print(view.hash)
                        completion(AnyGraphView(graph: newNativeGraph))
                    }
                })
            }
        }
    }
}

struct AnyGraphView: Codable {
    var format: GraphFormat
    var screengraph: GraphView
    
    enum CodingKeys: String, CodingKey {
        case format
    }
    
    func encode(to encoder: Encoder) throws {
        try screengraph.encode(to: encoder)
    }
    
    enum CodingError: Error {
        case badCoding
    }
    
    init(graph: GraphView) {
        format = graph.format
        screengraph = graph
    }
    
    init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        format = try values.decode(GraphFormat.self, forKey: .format)
        
        switch format {
        case .mobileView:
            screengraph = try NativeGraphview(from: decoder)
        case .webViewContainer:
            screengraph = try WebContainerGraphView(from: decoder)
        default:
            throw CodingError.badCoding
        }
    }
}


let viewOne = UIView()
let viewTwo = UIView()
let viewThree = UIView()
let webViewOne = WKWebView()

viewTwo.addSubview(viewThree)
viewTwo.addSubview(webViewOne)
viewOne.addSubview(viewTwo)

GraphViewGenerator().encode(fromView: viewOne) { (graphView) in
    print(graphView)
}
