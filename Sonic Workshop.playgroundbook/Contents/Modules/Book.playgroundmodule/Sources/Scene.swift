//
//  Scene.swift
//  
//  Copyright © 2016-2019 Apple Inc. All rights reserved.
//

import Foundation
import UIKit
import PlaygroundSupport

/// The Scene is the container for all nodes and graphics created.
///
/// - localizationKey: Scene
public class Scene: PlaygroundRemoteLiveViewProxyDelegate {
    
    let size = CGSize(width: 1024, height: 1024)
    
    private var isTouchHandlerRegistered: Bool = false
    
    var runLoopRunning = false {
        didSet {
            if runLoopRunning {
                CFRunLoopRun()
            }
            else {
                CFRunLoopStop(CFRunLoopGetMain())
            }
        }
    }
    
    /// A dictionary of the graphics that have been placed on the Scene, using each graphic’s id property as keys.
    ///
    /// - localizationKey: Scene.placedGraphics
    public var placedGraphics = [String: Graphic]()
    
    private var backingGraphics: [Graphic] = []
    
    /// The collection of graphics on the Scene.
    ///
    /// - localizationKey: Scene.graphics
    public var graphics: [Graphic] {
        get {
            Message.getGraphics.send()
            runLoopRunning = true
            defer {
                backingGraphics.removeAll()
            }
            return backingGraphics
        }
    }
    
    
    /// Determines whether a graphic on the scene, if touched first, will capture all subsequent touches delivered to the scene. If set to `true`, a first touch delivered to a graphic or the scene will only activate the fingerMoved handlers for that graphic or the scene. Set to `false` by default.
    ///
    /// - localizationKey: Scene.capturesTouches
    public var capturesTouches = false
    
    /// Returns the graphics on the Scene with the specified name.
    ///
    /// - Parameter name: A name you have given to a graphic or set of graphics.
    ///
    /// - localizationKey: Scene.getGraphics(named:)
    public func getGraphics(named name: String) ->  [Graphic] {
        return graphics.filter( { $0.name == name })
    }
    
    /// Returns the graphics on the Scene with a name containing the specified text.
    ///
    /// - Parameter text: The name you have given to a graphic or set of graphics.
    ///
    /// - localizationKey: Scene.getGraphicsWithName(containing:)
    public func getGraphicsWithName(containing text: String) -> [Graphic] {
        return graphics.filter( { $0.name.contains(text) })
    }
    
    /// Removes all of the graphics with a certain name from the Scene.
    ///
    /// - Parameter name: The name you have given to a graphic or set of graphics.
    ///
    /// - localizationKey: Scene.removeGraphics(named:)
    public func removeGraphics(named name: String) {
        for graphic in graphics.filter( { $0.name == name }) {
            graphic.remove()
        }
    }
    
    /// Removes all of the graphics on the Scene.
    ///
    /// - Parameter graphic: Type in the graphic you want to remove here.
    ///
    /// - localizationKey: Scene.remove(_:)
    public func remove(_ graphic: Graphic) {
        graphic.remove()
    }
    
    /// Gets all of the graphics in a certain area of the Scene.
    ///
    /// - Parameter point: The center point of the boundary you want to target.
    /// - Parameter bounds: The width and height of the area.
    ///
    /// - localizationKey: Scene.getGraphics(at:in:)
    public func getGraphics(at point: Point, in bounds: Size) -> [Graphic] {
        var graphicsInArea = [Graphic]()
        let bottomLeft = Point(x: point.x - bounds.width / 2, y: point.y - bounds.height / 2)
        let area = CGRect(origin: CGPoint(bottomLeft), size: CGSize(width: bounds.width, height: bounds.height))
        
        for graphic in graphics {
            if area.contains(CGPoint(graphic.position)) {
                graphicsInArea.append(graphic)
            }
        }
        return graphicsInArea
    }
    
    private var lastPlacePosition: Point = Point(x: Double.greatestFiniteMagnitude, y: Double.greatestFiniteMagnitude)
    private var graphicsPlacedDuringCurrentInteraction = Set<Graphic>()
    
    /// Initialize a Scene.
    ///
    /// - localizationKey: Scene()
    public init() {
        //  The user process must remain alive to receive touch event messages from the live view process.
        let page = PlaygroundPage.current
        page.needsIndefiniteExecution = true
        let proxy = page.liveView as? PlaygroundRemoteLiveViewProxy
        
        proxy?.delegate = self
        
        clear()
    }
    
    public func remoteLiveViewProxyConnectionClosed(_ remoteLiveViewProxy: PlaygroundRemoteLiveViewProxy) {
        clearInteractionState()
    }
    
    public func remoteLiveViewProxy(_ remoteLiveViewProxy: PlaygroundRemoteLiveViewProxy, received message: PlaygroundValue) {
        guard let message = Message(rawValue: message) else { return }
        switch message {
        case .sceneTouchEvent(let touch):
            handleSceneTouchEvent(touch: touch)
            
        // Scene collision event.
        case .sceneCollisionEvent(let collision):
            handleSceneCollisionEvent(collision: collision)
        
        case .setAssessment(let status):
            PlaygroundPage.current.assessmentStatus = status
            
        case .trigger(let assessmentTrigger):
            handleAssessmentTrigger(assessmentTrigger)
            
        case .getGraphicsReply(let graphicsReply):
            backingGraphics = graphicsReply
            runLoopRunning = false
        
        case .updateGraphicAttributes(let positions, let sizes):
            for id in positions.keys {
                if let graphic = placedGraphics[id],
                   let position = positions[id] {
                    
                    graphic.suppressMessageSending = true
                    graphic.position = Point(position)
                    graphic.suppressMessageSending = false
                }
            }
            
            for id in sizes.keys {
                if let graphic = placedGraphics[id],
                   let size = sizes[id] {
                    
                    graphic.suppressMessageSending = true
                    graphic.size = Size(size)
                    graphic.suppressMessageSending = false
                }
            }
            
        case .removedGraphic(let id):
            placedGraphics.removeValue(forKey: id)
            
        default:
            ()
        }
    }
    
    // Handles all logic for touches that are passed through from LiveViewScene
    func handleSceneTouchEvent(touch: Touch) {
        var touch = touch
        var tapHandler: (() -> Void)?
        var fingerMovedHandler: ((Touch) -> Void)?
        
        touch.previousPlaceDistance = lastPlacePosition.distance(from: touch.position)
        
        // If the scene allows touches to be captured, then all touch events will go to the first graphic that has been touched in the scene (the capturedGraphic).
        if capturesTouches {
            if let graphic = placedGraphics[touch.capturedGraphicID] {
                if touch.firstTouch {
                    tapHandler = graphic.onTapHandler
                }
                fingerMovedHandler = graphic.onFingerMovedHandler
                // If no capturedGraphic exists, give the touches to the scene
            } else {
                onFingerMovedHandler?(touch)
            }
        } else {
            // Look to see if there was a touched graphic and if there are any tapHandlers or fingerMovedHandlers assigned for that graphic. Assign those to a handler that will be called once all graphics have been examined.
            // Prevents graphics from intercepting touches if they do not have any handlers assigned to them.
            if let touchedGraphic = touch.touchedGraphic, let graphic = placedGraphics[touchedGraphic.id] {
                if touch.firstTouch {
                    tapHandler = graphic.onTapHandler
                    if let button = graphic as? Button {
                        switch button.buttonType {
                        case .green:
                            Message.runAnimation(id: button.id, animation: "greenButton", duration: 0.1, numberOfTimes: 1).send()
                        case .red:
                            Message.runAnimation(id: button.id, animation: "redButton", duration: 0.1, numberOfTimes: 1).send()
                        }
                    }
                }
                fingerMovedHandler = graphic.onFingerMovedHandler
            }
            // Call the onFingerMovedHandler for the scene if there is one
            onFingerMovedHandler?(touch)
        }
        
        // Call the tapHandler if there is one
        tapHandler?()
        
        // Call the fingerMovedHandler that was assigned
        fingerMovedHandler?(touch)
    

        Message.touchEventAcknowledgement.send()
    }
    
    func handleSceneCollisionEvent(collision: Collision) {
        onCollisionHandler?(collision)
    }
    
    
    func clearInteractionState() {
        graphicsPlacedDuringCurrentInteraction.removeAll()
        lastPlacePosition = Point(x: Double.greatestFiniteMagnitude, y: Double.greatestFiniteMagnitude)
    }
    
    func handleAssessmentTrigger(_ assessmentTrigger: AssessmentTrigger) {
        guard assessmentController?.style == .continuous else { return }
        
        switch assessmentTrigger {
            
        case .start(let context):
            assessmentController?.removeAllAssessmentEvents()
            assessmentController?.allowAssessmentUpdates = true
            assessmentController?.context = context
            
        case .stop:
            assessmentController?.allowAssessmentUpdates = false
            clearInteractionState()
            
        case .evaluate:
            assessmentController?.setAssessmentStatus()
        }

    }
    
    
    /// The Scene’s background image.
    ///
    /// - localizationKey: Scene.backgroundImage
    public var backgroundImage: Image? = nil {
        didSet {
            Message.setSceneBackgroundImage(backgroundImage).send()
            assessmentController?.append(.setSceneBackgroundImage(backgroundImage))
        }
    }
    
    /// The vertical gravity; the default is `-9.8`.
    ///
    /// - localizationKey: Scene.verticalGravity
    public var verticalGravity: Double = -9.8 {
        didSet {
            Message.setSceneGravity(vector: CGVector(dx: horizontalGravity, dy: verticalGravity)).send()
        }
    }
    
    /// The horizontal gravity; the default is `0`.
    ///
    /// - localizationKey: Scene.horizontalGravity
    public var horizontalGravity: Double = 0 {
        didSet {
            Message.setSceneGravity(vector: CGVector(dx: horizontalGravity, dy: verticalGravity)).send()
        }
    }
    
    /// Set to `true` to show a 50 x 50 pixel grid over the background. This can be helpful when deciding where to place things on the Scene.
    ///
    /// - localizationKey: Scene.isGridVisible
    public var isGridVisible: Bool = false {
        didSet {
            Message.setSceneGridVisible(isGridVisible).send()
        }
    }
    
    /// Set to `true` to have graphics bounce back into the Scene when they hit a border.
    ///
    /// - localizationKey: Scene.hasCollisionBorder
    public var hasCollisionBorder: Bool = true {
        didSet {
            Message.setBorderPhysics(hasCollisionBorder).send()
        }
    }
    
    /// The Scene’s background color.
    ///
    /// - localizationKey: Scene.backgroundColor
    public var backgroundColor: Color  = .white {
        didSet {
            Message.setSceneBackgroundColor(backgroundColor).send()
        }
    }
    
    /// The function that’s called when you touch the Scene.
    ///
    /// - localizationKey: Scene.touchHandler
    public var touchHandler: ((Touch)-> Void)? = nil {
        didSet {
            guard (touchHandler == nil && isTouchHandlerRegistered) || ( touchHandler != nil && !isTouchHandlerRegistered) else { return }
            Message.registerTouchHandler(touchHandler == nil).send()
        }
    }
    
    // MARK: Public Event Handlers
    
    /// The function that’s called when your finger moves across the scene.
    ///
    /// - localizationKey: Scene.onFingerMovedHandler
    public var onFingerMovedHandler: ((Touch) -> Void)?
    
    // Favoring setting an onTapped handler for individual graphics instead of this more generalized method - no longer exposing to learner.
    var onGraphicTouchedHandler: ((Graphic) -> Void)?
    
    /// The function that’s called when two things collide onscreen.
    ///
    /// - localizationKey: Scene.onCollisionHandler
    public var onCollisionHandler: ((Collision) -> Void)?
    
    /// Sets the function that’s called when graphics collide in a Scene.
    /// - parameter handler: The function to be called whenever a collision occurs.
    ///
    /// - localizationKey: Scene.setOnCollisionHandler(_:)
    public func setOnCollisionHandler(_ handler: @escaping ((Collision) -> Void)) {
        onCollisionHandler = handler
    }
    
    /// Sets the function that’s called when your finger moves across the Scene.
    ///
    /// - Parameter handler: The function to be called whenever the touch data is updated i.e. when your finger has moved.
    ///
    /// - localizationKey: Scene.setOnFingerMovedHandler(_:)
    public func setOnFingerMovedHandler(_ handler: ((Touch) -> Void)?) {
        onFingerMovedHandler = handler
    }
    
    // Favoring setting an onTapped handler for individual graphics instead of this more generalized method - no longer exposing to learner.
    func setOnGraphicTouchedHandler(_ handler: ((Graphic) -> Void)?) {
        onGraphicTouchedHandler = handler
    }
    
    // MARK: Public Methods
    
    /// Removes all of the graphics from the Scene.
    ///
    /// - localizationKey: Scene.clear()
    public func clear() {
        placedGraphics.removeAll()
        Message.clearScene.send()
    }
    
    /// Creates a Sprite with an image and a name.
    ///
    /// - Parameter from: An image you choose to use as the Sprite.
    /// - Parameter named: A name you give the Sprite.
    ///
    /// - localizationKey: Scene.createSprites(from:named:)
    public func createSprites(from images: [Image], named: String) -> [Sprite] {
        var groupOfSprites = [Sprite]()
        
        for image in images {
            let sprite = Sprite(image: image, name: named)
            groupOfSprites.append(sprite)
        }
        return groupOfSprites
    }
    
    /// Places a graphic at a point on the Scene.
    ///
    /// - Parameter graphic: The graphic to be placed on the Scene.
    /// - Parameter at: The point at which the graphic is placed.
    /// - Parameter anchoredTo: The anchor point within the graphic from which the graphic is initially placed. Defaults to the center.
    ///
    /// - localizationKey: Scene.place(_:at:)
    public func place(_ graphic: Graphic, at: Point, anchoredTo: AnchorPoint = .center) {
        Message.placeGraphic(id: graphic.id, position: CGPoint(at), anchor: anchoredTo, isPrintable: false).send()
        assessmentController?.append(.placeAt(graphic: graphic, position: at))
        graphicsPlacedDuringCurrentInteraction.insert(graphic)
        placedGraphics[graphic.id] = graphic
        lastPlacePosition = at
        
        graphic.suppressMessageSending = true
        graphic.position = at
        graphic.suppressMessageSending = false
    }
    
    /// Returns an array of count points on a circle around the center point.
    ///
    /// - Parameter radius: The radius of the circle.
    /// - Parameter count: The number of points to return.
    ///
    /// - localizationKey: Scene.circlePoints(radius:count:)
    public func circlePoints(radius: Double, count: Int) -> [Point] {
        
        var points = [Point]()
        
        let slice = 2 * Double.pi / Double(count)
        
        let center = Point(x: 0, y: 0)
        
        for i in 0..<count {
            let angle = slice * Double(i)
            let x = center.x + (radius * cos(angle))
            let y = center.y + (radius * sin(angle))
            points.append(Point(x: x, y: y))
        }
        
        return points
    }
    
    /// Returns an array of count points in a square box around the center point.
    ///
    /// - Parameter width: The width of each side of the box.
    /// - Parameter count: The number of points to return.
    ///
    /// - localizationKey: Scene.squarePoints(width:count:)
    public func squarePoints(width: Double, count: Int) -> [Point] {
        
        var points = [Point]()
        
        guard count > 4 else { return points }
        
        let n = count / 4
        
        let sparePoints = count - (n * 4)
        
        let delta = width / Double(n)
        
        var point = Point(x: -width/2, y: -width/2)
        points.append(point)
        for _ in 0..<(n - 1) {
            point.y += delta
            points.append(point)
        }
        point = Point(x: -width/2, y: width/2)
        points.append(point)
        for _ in 0..<(n - 1) {
            point.x += delta
            points.append(point)
        }
        point = Point(x: width/2, y: width/2)
        points.append(point)
        for _ in 0..<(n - 1) {
            point.y -= delta
            points.append(point)
        }
        point = Point(x: width/2, y: -width/2)
        points.append(point)
        for _ in 0..<(n - 1) {
            point.x -= delta
            points.append(point)
        }
        
        // Duplicate remainder points at the end
        for _ in 0..<sparePoints {
            points.append(point)
        }
        
        return points
    }
    
    func rotatePoints(points: [Point], angle: Double) -> [Point] {
        
        var rotatedPoints = [Point]()
        
        let angleRadians = (angle / 360.0) * (2.0 * Double.pi)
        
        for point in points {
            let x = point.x * cos(angleRadians) - point.y * sin(angleRadians)
            let y = point.y * cos(angleRadians) + point.x * sin(angleRadians)
            rotatedPoints.append(Point(x: x, y: y))
        }
        return rotatedPoints
    }
    
    /// Returns an array of count points in a square grid of the given size, rotated by angle (in degrees).
    ///
    /// - Parameter size: The size of each side of the grid.
    /// - Parameter count: The number of points to return.
    /// - Parameter angle: The angle of rotation in degrees.
    ///
    /// - localizationKey: Scene.gridPoints(size:count:angle:)
    public func gridPoints(size: Double, count: Int, angle: Double = 0) -> [Point] {
        
        var points = [Point]()
        
        // Get closest value for n that fits an n * n grid inside count.
        let n = Int(floor(sqrt(Double(count))))
        
        if n <= 1 {
            return [Point(x: 0, y: 0)]
        }
        
        let surplusPoints = count - (n * n)
        
        let delta = size / Double(n - 1)
        
        let startX = -(size / 2.0)
        let startY = -(size / 2.0)
        
        var x = startX
        var y = startY
        
        for _ in 0..<n {
            for _ in 0..<n {
                points.append(Point(x: x, y: y))
                x += delta
            }
            y += delta
            x = startX
        }
        
        // Duplicate and overlay any surplus points after the n * n grid has been added.
        for i in 0..<surplusPoints {
            points.append(points[i])
        }
        
        if angle != 0 {
            points = rotatePoints(points: points, angle: angle)
        }
        
        return points
    }
    
    public func useOverlay(overlay: Overlay) {
        Message.useOverlay(overlay).send()
    }
}
