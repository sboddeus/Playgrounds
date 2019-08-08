//
//  Graphic.swift
//  
//  Copyright © 2016-2019 Apple Inc. All rights reserved.
//

import Foundation
import UIKit
import PlaygroundSupport
import SpriteKit

/// An enumeration of the types of Graphics, including: graphic, sprite, character, button, and label.
///
/// - localizationKey: GraphicType
public enum GraphicType: String {
    case graphic
    case sprite
    case character
    case button
    case label
}

/// An enumeration of the types of basic shapes, including: circle, rectangle, polygon, and star.
///
/// - localizationKey: BasicShape
public enum BasicShape {
    case circle(radius: Int, color: Color, gradientColor: Color)
    case rectangle(width: Int, height: Int, cornerRadius: Double, color: Color, gradientColor: Color)
    case polygon(radius: Int, sides: Int, color: Color, gradientColor: Color)
    case star(radius: Int, points: Int, sharpness: Double, color: Color, gradientColor: Color)
    
    internal var size: CGSize {
        switch self {
        case .circle(let attr):
            return CGSize(width: attr.radius * 2, height: attr.radius * 2)
        case .rectangle(let attr):
            return CGSize(width: attr.width, height: attr.height)
        case .polygon(let attr):
            return CGSize(width: attr.radius * 2, height: attr.radius * 2)
        case .star(let attr):
            return CGSize(width: attr.radius * 2, height: attr.radius * 2)
        }
    }
    
    private var color: Color {
        switch self {
        case .circle(let attr):
            return attr.color
        case .rectangle(let attr):
            return attr.color
        case .polygon(let attr):
            return attr.color
        case .star(let attr):
            return attr.color
        }
    }
    
    private var gradientColor: Color {
        switch self {
        case .circle(let attr):
            return attr.gradientColor
        case .rectangle(let attr):
            return attr.gradientColor
        case .polygon(let attr):
            return attr.gradientColor
        case .star(let attr):
            return attr.gradientColor
        }
    }
    
    private var path: CGPath {
        let origin = CGPoint(x: 0, y: 0)
        switch self {
        case .circle:
            return UIBezierPath(ovalIn: CGRect(origin: origin, size: size)).cgPath
        case .rectangle(let attr):
            return UIBezierPath(roundedRect: CGRect(origin: origin, size: size), cornerRadius: CGFloat(attr.cornerRadius)).cgPath
        case .polygon(let attr):
            return UIBezierPath(polygonIn: CGRect(origin: origin, size: size), sides: attr.sides).cgPath
        case .star(let attr):
            return UIBezierPath(starIn: CGRect(origin: origin, size: size), points: attr.points, sharpness: CGFloat(attr.sharpness)).cgPath
        }
    }
    
    var image: UIImage {
        UIGraphicsBeginImageContextWithOptions(size, false, 0)
        let ctx = UIGraphicsGetCurrentContext()!
        ctx.saveGState()
        
        ctx.beginPath()
        ctx.addPath(path)
        ctx.clip()
        
        let colorSpace = CGColorSpaceCreateDeviceRGB()
        let colors = [color.cgColor, gradientColor.cgColor] as CFArray
        
        let gradient = CGGradient(colorsSpace: colorSpace, colors: colors, locations: nil)!
        ctx.drawLinearGradient(gradient, start: CGPoint(x: 0, y: 0), end: CGPoint(x: 0, y: size.height), options: [])
        
        ctx.restoreGState()
        let img = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        return img ?? UIImage()
    }
}

/// An enumeration of the types of basic shapes, including: circle, rectangle, polygon and star.
///
/// - localizationKey: Shape
public enum Shape {
    case circle(radius: Int)
    case rectangle(width: Int, height: Int, cornerRadius: Double)
    case polygon(radius: Int, sides: Int)
    case star(radius: Int, points: Int, sharpness: Double)
}

/*
    The Graphic class implements the user process’s implementation of the Graphic protocol.
    It works by sending messages to the live view when appropriate, where the real actions are enacted.
    It is a proxy, that causes its remote counterpart to invoke actions that affect the live view.
 */

/// A Graphic object, made from an image or string, that can be placed on the scene.
///
/// - localizationKey: Graphic
public class Graphic: MessageControl {
    
    fileprivate static var defaultNameCount = 1
    
    /// An id, used to identify a Graphic. Read-only.
    ///
    /// - localizationKey: Graphic.id
    public let id: String
        
    /// The name of the graphic.
    ///
    /// - localizationKey: Graphic.name
    public var name: String
    
    var graphicType: GraphicType = .graphic
    
    let defaultAnimationTime = 0.5
    
    var suppressMessageSending: Bool = false
    
    public var onTapHandler: (() -> Void)?
    
    public var onFingerMovedHandler: ((Touch) -> Void)?
    
    /// The function that gets called when you tap a Graphic.
    ///
    /// - localizationKey: Graphic.setOnTapHandler(_:)
    public func setOnTapHandler(_ handler: @escaping (() -> Void)) {
        onTapHandler = handler
    }
    
    /// The function to be called whenever the touch data is updated over this graphic, i.e. when your finger has moved over the graphic.
    ///
    /// - localizationKey: Graphic.setOnFingerMovedHandler(_:)
    public func setOnFingerMovedHandler(_ handler: @escaping ((Touch) -> Void)) {
        onFingerMovedHandler = handler
    }
    
    var font: Font = .SystemFontRegular {
       
        didSet {
            guard !suppressMessageSending else { return }
            Message.setFontName(id: id, name: font.rawValue).send()
        }
    }
    
    var fontSize: Double = 32  {
       
        didSet {
            guard !suppressMessageSending else { return }
            Message.setFontSize(id: id, size: Int(fontSize)).send()
        }
    }
    
    var text: String = "" {
       
        didSet {
            guard !suppressMessageSending else { return }
            Message.setText(id: id, text: text).send()
        }
    }

    var textColor: Color = .black {
      
        didSet {
            guard !suppressMessageSending else { return }
            let color = textColor
            Message.setTextColor(id: id, color: color).send()
        }
    }
    
    /**
    Controls whether a graphic will respond to touch events.

    If this value is `false`, the graphic will ignore touch events. Handlers such as `onTapHandler` won't be able to run.
     
    This value is `true` by default.

     - localizationKey: Graphic.allowsTouchInteraction
    */
    public var allowsTouchInteraction: Bool = true {
        didSet {
            guard !suppressMessageSending else { return }
            Message.setAllowsTouchInteraction(id: id, allowsTouchInteraction: allowsTouchInteraction).send()
        }
    }
    
    public var accessibilityHints: AccessibilityHints?  {
        
        didSet {
            guard !suppressMessageSending else { return }
            
            if let accessibilityHints = accessibilityHints {
                Message.setAccessibilityHints(id: id, hints: accessibilityHints).send()
            }
        }
    }
    
    init(graphicType: GraphicType = .graphic, name: String = "") {
        self.id = UUID().uuidString
        self.graphicType = graphicType
        self.name = name
        Message.createNode(id: id, graphicName: name, graphicType: graphicType.rawValue).send()
    }
    
    /// Creates a Graphic with the given identifier; for example, reconstructing a graphic.
    ///
    /// - Parameter id: The identifier associated with the Graphic.
    /// - Parameter graphicType: The graphic type associated with the Graphic.
    /// - Parameter name: The name associated with the Graphic.
    ///
    /// - localizationKey: Graphic(id:name:graphicType:)
    public required init(id: String, graphicType: GraphicType = .graphic, name: String = "") {
        self.id = id
        self.name = name
        self.graphicType = graphicType
    }
    
        
    /// Creates a Graphic from a given image and name.
    ///
    /// - Parameter image: The image you choose to create the Graphic.
    /// - Parameter name: The name you give to the Graphic.
    ///
    /// - localizationKey: Graphic(image:name:)
    public convenience init(image: Image, name: String = "") {
        if name == "" {
            self.init(graphicType: .graphic, name: "graphic" + String(Graphic.defaultNameCount))
            Graphic.defaultNameCount += 1
        } else {
            self.init(graphicType: .graphic, name: name)
        }
        
        self.image = image
        
        updateSize()
        
        /*
            Manually sending a message here, as setting a property on a struct
            from within one of its own initializers won’t trigger the didSet property.
        */
        Message.setImage(id: id, image: image).send()
    }
    
    /// Creates a Graphic with a specified shape, color, gradient, and name.
    /// Example usage:
    /// ````
    /// let pentagon = Graphic(shape: .polygon(radius: 50, sides: 5), color: .red, gradientColor: .yellow, name: \"pentagon\")
    /// ````
    /// - Parameter shape: One of the Graphic shapes.
    /// - Parameter color: A fill color for the Graphic.
    /// - Parameter gradientColor: A secondary color for the gradient.
    /// - Parameter name: An optional name you can give to the shape. You can choose to leave the name blank.
    ///
    /// - localizationKey: Graphic(shape:color:gradientColor:name:)
    public convenience init(shape: Shape, color: Color, gradientColor: Color? = nil, name: String = "") {
        if name == "" {
            self.init(graphicType: .graphic, name: "graphic" + String(Graphic.defaultNameCount))
            Graphic.defaultNameCount += 1
        } else {
            self.init(graphicType: .graphic, name: name)
        }
        
        updateShape(shape: shape, color: color, gradientColor: gradientColor ?? color)
        
        updateSize()
    }
    
    func updateShape(shape: Shape, color: Color, gradientColor: Color) {
        let basicShape: BasicShape
        switch shape {
        case .circle(let radius):
            basicShape = .circle(radius: radius, color: color, gradientColor: gradientColor)
        case .rectangle(let width, let height, let cornerRadius):
            basicShape = .rectangle(width: width, height: height, cornerRadius: cornerRadius, color: color, gradientColor: gradientColor)
        case .polygon(let radius, let sides):
            basicShape = .polygon(radius: radius, sides: sides, color: color, gradientColor: gradientColor)
        case .star(let radius, let points, let sharpness):
            basicShape = .star(radius: radius, points: points, sharpness: sharpness, color: color, gradientColor: gradientColor)
        }
        
        self.shape = basicShape
        /*
         Manually sending a message here, as setting a property on a struct
         from within one of its own initializers won’t trigger the didSet property.
         */
        Message.setShape(id: id, shape: basicShape).send()
    }
    
    func updateSize() {
        var baseSize = CGSize.zero
        
        if let image = image {
            baseSize = image.size
        } else if let shape = shape {
            baseSize = shape.size
        }
        
        size = Size(width: Double(baseSize.width) * xScale, height: Double(baseSize.height) * yScale)
    }
    
    convenience init(named: String) {
        self.init(image: Image(imageLiteralResourceName: named), name: "graphic") // We  need an id generated
    }
    
       
    func send(_ action: SKAction, withKey: String? = nil) {
       
        guard !suppressMessageSending else { return }
        Message.runAction(id: id, action: action, key: withKey).send()
    }
    
    public var isHidden: Bool = false {
      
        didSet {
            
            guard !suppressMessageSending else { return }
            if isHidden {
                send(.hide(), withKey: "hide")
            }
            else {
                send(.unhide(), withKey: "unhide")
            }
        }
    }
    
    public var disablesOnDisconnect: Bool = false {
        didSet {
            guard !suppressMessageSending else { return }
            Message.setDisablesOnDisconnect(id: id, disablesOnDisconnect: disablesOnDisconnect).send()
        }
        
    }
    
    /// How transparent the graphic is—from 0.0 (totally transparent) to 1.0 (totally opaque).
    ///
    /// - localizationKey: Graphic.alpha
    public var alpha: Double = 1.0 {
       
        didSet {
            guard !suppressMessageSending else { return }
            send(.fadeAlpha(to: CGFloat(alpha), duration: 0), withKey: "fadeAlpha")
            assessmentController?.append(.setAlpha(graphic: self, alpha: alpha))
        }
    }
    
    
    /// The angle, in degrees, to rotate the graphic. Changing the angle rotates the graphic counterclockwise around its center. A value of `0.0` (the default) means no rotation. A value of `180.0` rotates the object 180 degrees.
    ///
    /// - localizationKey: Graphic.rotation
    public var rotation: Double {
        get {
            return Double(rotationRadians / CGFloat.pi) * 180.0
        }
        set(newRotation) {
            rotationRadians = (CGFloat(newRotation) / 180.0) * CGFloat.pi
        }
    }
    
    // Internal only representation of the rotation in radians.
    var rotationRadians: CGFloat = 0 {
       
        didSet {
            
            guard !suppressMessageSending else { return }
            send(.rotate(toAngle: rotationRadians, duration: 0, shortestUnitArc: false), withKey: "rotateTo")
        }
    }
    
    /// Position is the *x* and *y* coordinate of the center of a graphic.
    ///
    /// - localizationKey: Graphic.position
    public var position: Point = Point(x: 0, y: 0) {
        
        didSet {
            
            guard !suppressMessageSending else { return }
            send(.move(to: CGPoint(position), duration: 0), withKey: "moveTo")
        }
    }
    
    /// Placing the center of the Graphic at a certain point.
    ///
    /// - Parameter at: a point on the scene, Point(x:y:)
    ///
    /// - localizationKey: Graphic.place(at:)
    public func place(at: Point) {
        Message.placeGraphic(id: id, position: CGPoint(at), anchor: AnchorPoint.center, isPrintable: false).send()
    }
    
    /// Size of the Graphic, respecting scale.
    ///
    /// - localizationKey: Graphic.size
    public internal(set) var size: Size = Size(width: 0.0, height: 0.0)
    
    /// The scale of the Graphic’s size, where `1.0` is normal, `0.5` is half the normal size, and `2.0` is twice the normal size.
    ///
    /// - localizationKey: Graphic.scale
    public var scale: Double  = 1.0 {
        
        didSet {
            xScale = scale
            yScale = scale
            
            updateSize()
            
            guard !suppressMessageSending else { return }
            send(SKAction.scale(to: CGFloat(scale), duration: 0))
        }
    }
    
    /// A value for scaling only the *x* value of a Graphic. The default is `1.0`.
    ///
    /// - localizationKey: Graphic.xScale
    public var xScale: Double = 1.0 {
        didSet {
            updateSize()
            
            guard !suppressMessageSending else { return }
            Message.setXScale(id: id, xScale: xScale).send()
            
        }
    }
    
    /// A value for scaling only the *y* value of a Graphic. The default is `1.0`.
    ///
    /// - localizationKey: Graphic.yScale
    public var yScale: Double = 1.0 {
        didSet {
            updateSize()
            
            guard !suppressMessageSending else { return }
            Message.setYScale(id: id, yScale: yScale).send()
        }
    }
    
    /// The image displayed by the Graphic.
    ///
    /// - localizationKey: Graphic.image
    public var image: Image? = nil {
        didSet {
            updateSize()
            
            guard !suppressMessageSending else { return }
            Message.setImage(id: id, image: image).send()
        }
    }
    
    var shape: BasicShape? = nil {
        didSet {
            updateSize()
            
            guard !suppressMessageSending else { return }
            Message.setShape(id: id, shape: shape).send()
        }
    }
    
    /// Sets the Graphic tint color.
    ///
    /// - Parameter color: The color with which the Graphic is tinted.
    /// - Parameter blend: The degree to which the color is blended with the Graphic image from 0.0 to 1.0. The default is '0.8'.
    ///
    /// - localizationKey: Graphic.setTintColor(color:blend:)
    public func setTintColor(_ color: UIColor?, blend: Double = 0.8) {
        Message.setTintColor(id: id, color: color, blend: blend).send()
    }
    
    /// The Graphic’s distance from the given point.
    ///
    /// - Parameter from: The point from which to measure distance.
    ///
    /// - localizationKey: Graphic.distance(from:)
    public func distance(from: Point) -> Double {
        
        return position.distance(from: from)
        
    }
    
    /// Runs an Action with an associated key on a Graphic.
    ///
    /// - Parameter action: The Action for the Graphic to run.
    /// - Parameter key: A String used to identify the Action.
    ///
    /// - localizationKey: Graphic.run(_:key:)
    public func run(_ action: SKAction, key: String? = nil) {
        Message.runAction(id: id, action: action, key: key).send()
    }
    
    /// Removes an Action from the Graphic.
    ///
    /// - Parameter key: A String used to identify the Action.
    ///
    /// - localizationKey: Graphic.removeAction(forKey:)
    public func removeAction(forKey key: String) {
        Message.removeAction(id: id, key: key).send()
    }
    
    /// Removes all Actions from the Graphic.
    ///
    /// - localizationKey: Graphic.removeAllActions()
    public func removeAllActions() {
        Message.removeAllActions(id: id).send()
    }

    /// Removes the Graphic from the scene.
    ///
    /// - localizationKey: Graphic.remove()
    func remove() {
        Message.removeGraphic(id: id).send()
        assessmentController?.append(.remove(graphic: self))
    }
    
    /// Moves the Graphic by *x* and/or *y*, animated over a duration in seconds.
    ///
    /// - Parameter x: The distance to move along the x-axis.
    /// - Parameter y: The distance to move along the y-axis.
    /// - Parameter duration: The time over which the Graphic moves.
    ///
    /// - localizationKey: Graphic.moveBy(x:y:duration:)
    public func moveBy(x: Double, y: Double, duration: Double) {
        
        let vector = CGVector(dx: CGFloat(x), dy: CGFloat(y))
        let moveAction = SKAction.move(by: vector, duration: duration)
        moveAction.timingMode = .linear
        send(moveAction, withKey: "moveBy")
    }
    
    /// Moves the Graphic to a position, animated over a duration in seconds.
    ///
    /// - Parameter to: The point on the *x* and *y* axis where the Graphic moves to.
    /// - Parameter duration: The time over which the Graphic moves.
    ///
    /// - localizationKey: Graphic.move(to:duration:)
    public func move(to: Point, duration: Double) {
        
        let moveAction = SKAction.move(to: CGPoint(to), duration: duration)
        moveAction.timingMode = .linear
        send(moveAction, withKey: "moveTo")
        assessmentController?.append(.moveTo(graphic: self, position: to))
    }
    
    /// Rotates the Graphic by a specified angle over a duration in seconds.
    ///
    /// - Parameter angle: The angle in which to rotate.
    /// - Parameter duration: The time over which to rotate.
    ///
    /// - localizationKey: Graphic.rotate(byAngle:duration:)
    public func rotate(byAngle angle: Double, duration: Double) {
        let rotateAction = SKAction.rotate(byAngle: CGFloat(angle * Double.pi / 180), duration: duration)
        send(rotateAction, withKey: "rotateBy")
    }
    
    /// Rotates the Graphic to a specified angle over a duration in seconds.
    ///
    /// - Parameter angle: The angle in which to rotate.
    /// - Parameter duration: The time over which to rotate.
    ///
    /// - localizationKey: Graphic.rotate(toAngle:duration:)
    public func rotate(toAngle angle: Double, duration: Double) {
        let rotateAction = SKAction.rotate(toAngle: CGFloat(angle * Double.pi / 180), duration: duration)
        send(rotateAction)
    }
    
    /// Scales the Graphic to a specified value over a given number of seconds.
    ///
    /// - Parameter to: The scale that the Graphic changes to.
    /// - Parameter duration: The time over which the Graphic scales.
    ///
    /// - localizationKey: Graphic.scale(to:duration:)
    public func scale(to: Double, duration: Double) {
        
        guard !suppressMessageSending else { return }
        let scaleAction = SKAction.scale(to: CGFloat(to), duration: duration)
        scaleAction.timingMode = .easeInEaseOut
        send(scaleAction, withKey: "scaleTo")
    }
    
    /// Scales the graphic by a relative value over a given number of seconds.
    ///
    /// - Parameter value: The amount to add to the Graphic’s *x* and *y* scale values.
    /// - Parameter duration: The time over which the Graphic scales.
    ///
    /// - localizationKey: Graphic.scale(by:duration:)
    public func scale(by value: Double, duration: Double) {
        guard !suppressMessageSending else { return }
        let scaleAction = SKAction.scale(by: CGFloat(value), duration: duration)
        send(scaleAction, withKey: "scaleBy")
    }
    
    /// Creates an action that adds relative values to the *x* and *y* scale values of a Graphic.
    ///
    /// - Parameter xScale: The amount to add to the Graphic’s *x* scale value.
    /// - Parameter yScale: The amount to add to the Graphic’s *y* scale value.
    /// - Parameter duration: The time over which the Graphic scales.
    ///
    /// - localizationKey: Graphic.scaleX(by:y:duration:)
    public func scaleX(by xScale: Double, y yScale: Double, duration: Double) {
        guard !suppressMessageSending else { return }
        let scaleAction = SKAction.scaleX(by: CGFloat(xScale), y: CGFloat(yScale), duration: duration)
        send(scaleAction)
    }
    
    /// Creates an action that changes the *x* and *y* scale values of a Graphic.
    ///
    /// - Parameter xScale: The new value for the Graphic’s *x* scale value.
    /// - Parameter yScale: The new value for the Graphic’s *y* scale value.
    /// - Parameter duration: The time over which the Graphic scales.
    ///
    /// - localizationKey: Graphic.scaleX(to:y:duration:)
    public func scaleX(to xScale: Double, y yScale: Double, duration: Double) {
        let scaleAction = SKAction.scaleX(to: CGFloat(xScale), y: CGFloat(yScale), duration: duration)
        send(scaleAction)
    }
    
    /// Animates the Graphic to fade out after a given number of seconds.
    ///
    /// - Parameter after: The time in seconds to fade out the Graphic.
    ///
    /// - localizationKey: Graphic.fadeOut(after:)
    public func fadeOut(after seconds: Double) {
        Message.runAction(id: id, action: .fadeOut(withDuration: seconds), key: "fadeOut").send()
        
    }
    
    /// Animates the Graphic to fade in over the given number of seconds.
    ///
    /// - Parameter after: The time in seconds to fade in the Graphic.
    ///
    /// - localizationKey: Graphic.fadeIn(after:)
    public func fadeIn(after seconds: Double) {
        Message.runAction(id: id, action: .fadeIn(withDuration: seconds), key: "fadeIn").send()
        
    }
    
    /// Creates an action that adjusts the alpha value of a Graphic to a new value.
    ///
    /// - Parameter value: The new value of the Graphic’s alpha.
    /// - Parameter duration: The duration of the animation.
    ///
    /// - localizationKey: Graphic.fadeAlpha(to:duration:)
    public func fadeAlpha(to value: Double, duration: Double) {
        let fadeAlphaAction = SKAction.fadeAlpha(to: CGFloat(value), duration: duration)
        Message.runAction(id: id, action: fadeAlphaAction, key: "fadeTo").send()
    }
    
    /// Creates an action that adjusts the alpha value of a Graphic by a certain value.
    ///
    /// - Parameter value: The new value of the Graphic’s alpha.
    /// - Parameter duration: The duration of the animation.
    ///
    /// - localizationKey: Graphic.fadeAlpha(by:duration:)
    public func fadeAlpha(by value: Double, duration: Double) {
        let fadeAlphaAction = SKAction.fadeAlpha(by: CGFloat(value) ,duration: duration)
        Message.runAction(id: id, action: fadeAlphaAction, key: "fadeTo").send()
    }
    
    /// Moves the Graphic around the center point in an elliptical orbit. The direction of rotation is chosen at random.
    ///
    /// - Parameter x: The distance of the orbital path from the center along the x-axis.
    /// - Parameter y: The distance of the orbital path from the center along the y-axis.
    /// - Parameter period: The period of the orbit in seconds.
    ///
    /// - localizationKey: Graphic.orbit(x:y:period:)
    public func orbit(x: Double, y: Double, period: Double = 4.0) {
        let orbitAction = SKAction.orbit(x: CGFloat(x), y: CGFloat(y), period: period)
        send(orbitAction, withKey: "orbit")
        assessmentController?.append(.orbit(graphic: self, x: x, y: y, period: period))

    }
    
    /// Rotates the Graphic continuously, with a given period of rotation.
    ///
    /// - Parameter period: The period of each rotation in seconds.
    ///
    /// - localizationKey: Graphic.spin(period:)
    public func spin(period: Double = 2.0) {
        
        Message.runAction(id: id, action: .spin(period: period), key: "spin").send()
        assessmentController?.append(.spin(graphic: self, period: period))
    }
    
    /// Pulsates the Graphic by increasing and decreasing its scale a given number of times, or indefinitely.
    ///
    /// - Parameter period: The period of each pulsation in seconds.
    /// - Parameter count: The number of pulsations; the default (`-1`) is to pulsate indefinitely.
    ///
    /// - localizationKey: Graphic.pulsate(period:count:)
    public func pulsate(period: Double = 5.0, count: Int = -1) {
        send(.pulsate(period: period, count: count), withKey: "pulsate")
        assessmentController?.append(.pulsate(graphic: self, period: period, count: count))
    }
    
    /// Animates the Graphic by shaking it for the given number of seconds.
    ///
    /// - Parameter duration: The time in seconds to shake the Graphic.
    ///
    /// - localizationKey: Graphic.shake(duration:)
    public func shake(duration: Double = 2.0) {

        Message.runAction(id: id, action: .shake(duration: duration), key: "shake").send()
    }
    
    
    /// Runs an animation on the given sprite, which consists of an array of images, and the animation’s time per frame.
    ///
    /// - Parameter images: An array of images that composes the animation sequence.
    /// - Parameter timePerFrame: The amount of time between images in the animation sequence.
    /// - Parameter numberOfTimes: The number of times to repeat the animation. Setting this value to `-1` repeats the animation indefinitely.
    ///
    /// - localizationKey: Graphic.runAnimation(images:timePerFrame:numberOfTimes:)
    func runAnimation(fromImages images: [Image], timePerFrame: Double, numberOfTimes: Int = 1) {
        var names: [String] = []
        for image in images {
            names.append(image.path)
        }
        Message.runCustomAnimation(id: id, animationSequence: names, duration: timePerFrame, numberOfTimes: numberOfTimes).send()
    }
    
    /// Runs an animation on the given graphic.
    ///
    /// - Parameter animation: An enum specifying the animation to run.
    /// - Parameter timePerFrame: The amount of time between images in the animation sequence.
    /// - Parameter numberOfTimes: The number of times to repeat the animation. Setting this value to `-1` will repeat the animation indefinitely.
    ///
    ///- localizationKey: Graphic.runAnimation(_:timePerFrame:numberOfTimes:)
    public func runAnimation(_ animation: Animation, timePerFrame: Double, numberOfTimes: Int = 1) {
        Message.runAnimation(id: id, animation: animation.rawValue, duration: timePerFrame, numberOfTimes: numberOfTimes).send()
    }
    
    // MARK: Unavailable
    
    @available(*, unavailable, message: "You need to add the ‘text:’ label when creating a graphic with a string. For example:\n\nlet graphic = Graphic(text: \"My string\")")
    public convenience init(_ text: String) { self.init() }
    
    @available(*, unavailable, message: "You need to add the ‘image:’ label when creating a graphic with an image. For example:\n\nlet graphic = Graphic(image: myImage)")
    public convenience init(_ image: Image) { self.init() }
}


extension Graphic: Hashable, Equatable {
    
    public func hash(into hasher: inout Hasher) {
        hasher.combine(self.id)
    }

    public static func ==(lhs: Graphic, rhs: Graphic) -> Bool {
        
        return lhs.id == rhs.id
    }
    
}
