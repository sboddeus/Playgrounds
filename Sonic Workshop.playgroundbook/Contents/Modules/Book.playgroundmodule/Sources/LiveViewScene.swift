//
//  LiveViewScene.swift
//  
//  Copyright © 2016-2019 Apple Inc. All rights reserved.
//

import Foundation
import UIKit
import SpriteKit
import Dispatch
import PlaygroundSupport
import AVFoundation

internal let controlsMargin : CGFloat = 20

public protocol LiveViewSceneDelegate {
    var backgroundImage : Image? { get set }
}

private class BackgroundContainerNode : SKSpriteNode {
    var transparencyNode : SKTileMapNode?
    var gridNode : SKSpriteNode?
    var userBackgroundNode : SKSpriteNode?
    var overlayNode = SKSpriteNode()
    
    private let axisLabelSize = CGSize(width: 100, height: 25)
    
    var backgroundColor : UIColor? {
        didSet {
            if let color = backgroundColor {
                self.color = color
                transparencyNode?.isHidden = true
            }
            else {
                self.color = UIColor.clear
                transparencyNode?.isHidden = (backgroundImage == nil)
            }
            update()
        }
    }
    
    var backgroundImage : Image? {
        didSet {
            if let image = backgroundImage {
                if transparencyNode == nil {
                    transparencyNode = self.transparentTileNode()
                    insertChild(transparencyNode!, at: 0)
                }

                if userBackgroundNode == nil  {
                    userBackgroundNode = SKSpriteNode()
                    insertChild(userBackgroundNode!, at: 1)
                }
                
                guard let texture = LiveViewGraphic.texture(for: image, type: .background) else { return }
                // When changing the texture on an SKSpriteNode, one must always reset the scale back to 1.0 first. Otherwise, strange additive scaling effects can occur.
                userBackgroundNode?.xScale = 1.0
                userBackgroundNode?.yScale = 1.0
                userBackgroundNode?.texture = texture
                userBackgroundNode?.size = texture.size()
                
                let wRatio = sceneSize.width / texture.size().width
                let hRatio = sceneSize.height / texture.size().height
                
                // Aspect fit the image if needed
                if (wRatio < 1.0 || hRatio < 1.0) {
                    let ratio = min(wRatio, hRatio)
                    userBackgroundNode?.xScale = ratio
                    userBackgroundNode?.yScale = ratio
                }

                transparencyNode?.isHidden = (backgroundColor != nil)
                userBackgroundNode?.isHidden = false
            }
            else {
                // Cleared the image
                userBackgroundNode?.isHidden = true
                transparencyNode?.isHidden = true
            }
            update()
        }
    }
    
    var overlayImage : Image? {
        didSet {
            if let image = overlayImage {
                guard let texture = LiveViewGraphic.texture(for: image, type: .background) else { return }
                overlayNode.texture = texture
                overlayNode.size = texture.size()
            }
            update()
        }
    }
    
    var isGridOverlayVisible: Bool = false {
        didSet {
            gridNode?.removeFromParent()
            if isGridOverlayVisible {
                if gridNode == nil  {
                    gridNode = SKSpriteNode(texture: SKTexture(imageNamed: "gridLayout"), color: Color.clear, size: sceneSize)
                    
                }
                addChild(gridNode!)
            } else {
                if let gridNode = gridNode {
                    removeChildren(in: [gridNode])
                    
                    self.gridNode = nil
                }
            }
            update()
        }
    }

    func update() {
        self.isHidden = (backgroundColor == nil && backgroundImage == nil && overlayImage == nil && isGridOverlayVisible == false)
    }
    
    init() {
        super.init(texture: nil, color: Color.clear, size: sceneSize)
        addChild(overlayNode)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func transparentTileNode() -> SKTileMapNode {
        let texture = SKTexture(imageNamed: "transparent_background")
        let tileDefinition = SKTileDefinition(texture: texture)
        let tileGroup = SKTileGroup(tileDefinition: tileDefinition)
        let tileSet = SKTileSet(tileGroups: [tileGroup], tileSetType: .grid)
        let tileMapNode = SKTileMapNode(tileSet: tileSet, columns: Int(CGFloat(sceneSize.width) / tileDefinition.size.width) + 1,
                                        rows: Int(CGFloat(sceneSize.height) / tileDefinition.size.height) + 1, tileSize: texture.size(), fillWith: tileGroup)
        tileMapNode.name = "transparentBackgroundNode"
        
        return tileMapNode
    }
}

public class LiveViewScene: SKScene, UIGestureRecognizerDelegate, SKPhysicsContactDelegate, GraphicAccessibilityElementDelegate, BackgroundAccessibilityElementDelegate {
    static let initialPrintPosition = CGPoint(x: 0, y: 400)
    static var printPosition = initialPrintPosition

    let containerNode = SKNode()
    var capturedGraphic: Graphic? = nil
    
    var messagesAwaitingSend = [Message]()
    var waitingForTouchAcknowledegment: Bool = false
    var shouldWaitForTouchAcknowledgement: Bool = false
    
    let nc = NotificationCenter.default
    var enterBackgroundObserver: Any!
    var willEnterForegroundObserver: Any!
    
    private var graphicAccessibilityElementGroupsByID = Dictionary<String, GraphicAccessibilityElement>()
    
    var executionMode: PlaygroundPage.ExecutionMode? = nil {
        didSet {
            updateState(forExecutionMode: executionMode)
        }
    }
    private var steppingEnabled : Bool {
        get {
            return executionMode == .step || executionMode == .stepSlowly
        }
    }
    
    private let backgroundNode = BackgroundContainerNode()
    internal var sceneDelegate : LiveViewSceneDelegate?
    private var connectedToUserProcess : Bool = false {
        didSet {
            // Only do this if we’re turning it off, not just initializing it
            if !connectedToUserProcess && oldValue == true {
                accessibilityAllowsDirectInteraction = false
                
                setNeedsUpdateAccessibility(notify: false)
            }
        }
    }
    
    // To track when we’ve received the last touch we sent to the user process
    private var lastSentTouch : Touch?

    private var shouldHandleTouches: Bool {
        return connectedToUserProcess /* && selectedTool != nil */
    }
    
    private var graphicsPositionUpdateTimer:Timer? = nil
    
    var graphicsInfo = [String : LiveViewGraphic]() { // keyed by id
        didSet {
            setNeedsUpdateAccessibility(notify: false)
        }
    }
    
    var axElements = [UIAccessibilityElement]()
    
    private var instruments = [Instrument.Kind: Instrument]()
    private var instrumentsEngine: AudioPlayerEngine = {
        let audioPlayerEngine = AudioPlayerEngine()
        audioPlayerEngine.start()
        return audioPlayerEngine
    }()
        
    func updateState(forExecutionMode: PlaygroundPage.ExecutionMode?) {
        guard let executionMode = executionMode else { return }
        switch executionMode {
        case .step, .stepSlowly:
            shouldWaitForTouchAcknowledgement = true
            
        default:
            shouldWaitForTouchAcknowledgement = false
        }
    }
    
    public var backgroundImage: Image? {
        didSet {
            // If the image is not exactly our expected edge-to-edge size, assume the learner has placed an image of their own.
            
            if let bgImage = backgroundImage {
                if let uiImage = UIImage(named: bgImage.path) {
                    if uiImage.size.width == TextureType.backgroundMaxSize.width && uiImage.size.height == TextureType.backgroundMaxSize.height {
                        backgroundNode.backgroundImage = nil
                        sceneDelegate?.backgroundImage = bgImage
                    }
                    else {
                        // Learner image
                        backgroundNode.backgroundImage = bgImage
                        sceneDelegate?.backgroundImage = nil
                    }
                }
            }
            else {
                // Background image cleared
                backgroundNode.backgroundImage = nil
                sceneDelegate?.backgroundImage = nil
            }
        }
    }
    
    override init() {
        super.init()
        commonInit()
    }
    
    public required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        commonInit()
    }
    
    func commonInit() {
        // The SKView hosting this scene is always sized appropriately so fit/fill really doesn’t matter here.
        scaleMode = .aspectFit
        isUserInteractionEnabled = true
        backgroundColor = UIColor.clear
        updateState(forExecutionMode: PlaygroundPage.current.executionMode)
        NotificationCenter.default.addObserver(forName: Notification.Name(rawValue:"PlaygroundPageExecutionModeDidChange"), object: nil, queue: OperationQueue.main) { (notification) in
            self.executionMode = PlaygroundPage.current.executionMode
        }
    }
    
    override init(size: CGSize) {
        super.init(size: size)
        commonInit()
    }
    
    public override func didMove(to view: SKView) {
        super.didMove(to: view)
        physicsWorld.contactDelegate = self
        physicsWorld.gravity = CGVector(dx: 0, dy: -9.8)
        
        AudioSession.current.delegate = self
        AudioSession.current.configureEnvironment()

        addChild(backgroundNode)
        addChild(containerNode)
        containerNode.name = "container"
        backgroundNode.name = "background"
    }
    
    public override func didChangeSize(_ oldSize: CGSize) {
        backgroundNode.position = center
        containerNode.position = center
    }
    
    public func didBegin(_ contact: SKPhysicsContact) {
        guard let nodeA = contact.bodyA.node, let nodeB = contact.bodyB.node else { return }
        guard let idA = nodeA.name, let idB = nodeB.name else { return }
        
        guard let liveGraphicA = graphicsInfo[idA] else { return }
        guard let liveGraphicB = graphicsInfo[idB] else { return }
        
        let sortedGraphics = [liveGraphicA, liveGraphicB].sorted()
        
        let collidedSpriteA = Sprite(id: sortedGraphics[0].id, graphicType: .sprite, name: sortedGraphics[0].name)
        let collidedSpriteB = Sprite(id: sortedGraphics[1].id, graphicType: .sprite, name: sortedGraphics[1].name)
        
        var normalizedDirection: CGVector = CGVector()
        if liveGraphicA.name == sortedGraphics[0].name {
            normalizedDirection = contact.contactNormal
        } else {
            normalizedDirection = CGVector(dx: -contact.contactNormal.dx, dy: -contact.contactNormal.dy)
        }

        handleCollision(spriteA: collidedSpriteA, spriteB: collidedSpriteB, angle: normalizedDirection, force: Double(contact.collisionImpulse))
    }

    public override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesBegan(touches, with: event)
        guard shouldHandleTouches else { return }
        
        // reenable direct interaction
        if accessibilityAllowsDirectInteraction, let firstTouch = touches.first, firstTouch.tapCount == 2 {
            accessibilityAllowsDirectInteraction = false
            
            return
        }
        
        enqueue(.trigger(.start(context: .tool)))
        
        let skTouchPosition = touches[touches.startIndex].location(in: containerNode)
        // Get all visible nodes at the touch position.
        let intersectingNodes = containerNode.nodes(at: skTouchPosition)
        // Search visible nodes for the topmost graphic that allows touch interaction.
        for node in intersectingNodes {
            if let id = node.name, let liveGraphic = graphicsInfo[id], liveGraphic.allowsTouchInteraction {
                capturedGraphic = liveGraphic.graphic
                break
            }
        }
        
        let doubleTap = touches.first?.tapCount == 2
        
        handleTouch(at: skTouchPosition, firstTouch: true, doubleTap: doubleTap)

        if UIAccessibility.isVoiceOverRunning {
            graphicsPlacedCount = 0
        }
    }

    public override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesMoved(touches, with: event)
        guard shouldHandleTouches else { return }

        let skTouchPosition = touches[touches.startIndex].location(in: containerNode)
        handleTouch(at: skTouchPosition)
    }

    public override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard shouldHandleTouches else { return }
        
        if UIAccessibility.isVoiceOverRunning && graphicsPlacedCount > 0 {
            UIAccessibility.post(notification: .announcement, argument: String(format: NSLocalizedString("%d graphics placed in scene", comment: "AX description of graphics placed on screen"), graphicsPlacedCount))
            graphicsPlacedCount = 0
        }
        commonTouchEndingCleanup()
        
        let skTouchPosition = touches[touches.startIndex].location(in: containerNode)
        handleTouch(at: skTouchPosition, lastTouch: true)
    }

    public override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard shouldHandleTouches else { return }
        commonTouchEndingCleanup()
        
        let skTouchPosition = touches[touches.startIndex].location(in: containerNode)
        handleTouch(at: skTouchPosition, lastTouch: true)
    }
    
    func commonTouchEndingCleanup() {
        capturedGraphic = nil
        enqueue(.trigger(.stop))
        enqueue(.trigger(.evaluate))
    }
    
    func handleTouch(at: CGPoint, firstTouch: Bool = false, ignoreNode: Bool = false, doubleTap: Bool = false, lastTouch: Bool = false) {
        var touch = Touch(position: Point(at), previousPlaceDistance: 0, firstTouch: firstTouch, touchedGraphic: nil, capturedGraphicID: capturedGraphic?.id ?? "")
        
        if !ignoreNode {
            var node: SKNode?
            // Get all visible nodes at the touch position.
            let hitNodes = containerNode.nodes(at: at)
            // Search visible nodes for the topmost graphic that allows touch interaction.
            for hitNode in hitNodes {
                if let id = hitNode.name, let graphic = graphicsInfo[id], graphic.allowsTouchInteraction {
                    node = graphic.backingNode
                    break
                }
            }
            
            if let node = node, node.name != containerNode.name,
                node.name != backgroundNode.name,
                let id = node.name,
                let liveGraphic = graphicsInfo[id] {
                
                if node is SKTileMapNode {
                    // Touched a tile map node directly.
                    touch.touchedGraphic = liveGraphic.graphic
                    
                } else {
                    if let nodeName = node.name, node.childNode(withName: nodeName) is SKTileMapNode {
                        // Touched a node that contains a tile map node, but outside the tile map node itself.
                        // This can occur when the tile map node is rotated within the backing node.
                        // => Ignore touch.
                    } else {
                        // Touched a node.
                        touch.touchedGraphic = liveGraphic.graphic
                    }
                }
            }
        }
        
        touch.doubleTap = doubleTap
        touch.lastTouchInGraphic = lastTouch
        touch.firstTouchInGraphic = firstTouch
        
        if !firstTouch, let lastSentTouch = lastSentTouch, lastSentTouch.touchedGraphic != touch.touchedGraphic {
            var bonusTouch = Touch(position: lastSentTouch.position, previousPlaceDistance: 0, firstTouch: false, touchedGraphic: lastSentTouch.touchedGraphic, capturedGraphicID: lastSentTouch.capturedGraphicID)
            
            bonusTouch.lastTouchInGraphic = true
            
            enqueue(.sceneTouchEvent(bonusTouch))
        }
        
        if let touchedGraphic = touch.touchedGraphic, let lastSentTouch = lastSentTouch, let lastTouchedGraphic = lastSentTouch.touchedGraphic {
            touch.firstTouchInGraphic = touch.firstTouchInGraphic || (touchedGraphic.id != lastTouchedGraphic.id)
        }
        
        enqueue(.sceneTouchEvent(touch))
        lastSentTouch = touch
    }
    
    func handleCollision(spriteA: Sprite, spriteB: Sprite, angle: CGVector, force: Double) {
        let collision = Collision(spriteA: spriteA, spriteB: spriteB, angle: Vector(dx: Double(angle.dx), dy: Double(angle.dy)), force: force)
        
        enqueue(.sceneCollisionEvent(collision))
    }
    
    func handleMessage(message: Message) {
        switch message {
            
        case .setDisablesOnDisconnect(let id, let disablesOnDisconnect):
            setDisablesOnDisconnect(id: id, disablesOnDisconnect: disablesOnDisconnect)
            
        case .createNode(let id, let graphicName, let graphicType):
            createNode(id: id, graphicName: graphicName, graphicType: GraphicType(rawValue: graphicType)!)
            
        case .placeGraphic(let id, let position, let anchor, let isPrintable):
            placeGraphic(id: id, position: position, anchor: anchor, isPrintable: isPrintable)
            
        case .removeGraphic(let id):
            removeGraphic(id: id)
            
        case .setBorderPhysics(let allowsBorderPhysics):
            setBorderPhysics(allowsBorderPhysics)
            
        case .setSceneBackgroundImage(let image):
            setSceneBackgroundImage(image: image)
            
        case .setSceneBackgroundColor(let color):
            setSceneBackgroundColor(color: color)
            
        case .setSceneGridVisible(let isVisible):
            setGridOverlay(isVisible)
            
        case .setImage(let id, let image):
            setImage(id: id, image: image)
            
        case .setShape(let id, let shape):
            setShape(id: id, shape: shape)

        case .setTiledImage(let id, let image, let columns, let rows, let isDynamic):
            setImage(id: id, image: image, columns: columns, rows: rows, isDynamic: isDynamic)
            
        case .setAffectedByGravity(let id, let gravity):
            setAffectedByGravity(id: id, gravity: gravity)
            
        case .setIsDynamic(let id, let isDynamic):
            setIsDynamic(id: id, isDynamic: isDynamic)
            
        case .setAllowsRotation(let id, let allowsRotation):
            setAllowsRotation(id: id, allowsRotation: allowsRotation)
            
        case .setAllowsTouchInteraction(let id, let allowsTouchInteraction):
            setAllowsTouchInteraction(id: id, allowsTouchInteraction: allowsTouchInteraction)
            
        case .setBounciness(let id, let bounciness):
            setBounciness(id: id, bounciness: bounciness)
            
        case .setXScale(let id, let xScale):
            setXScale(id: id, xScale: xScale)
            
        case .setYScale(let id, let yScale):
            setYScale(id: id, yScale: yScale)
            
        case .setSceneGravity(let vector):
            setSceneGravity(vector: vector)
        
        case .glow(let id, let radius, let period, let count):
            glow(id: id, radius: radius, period: period, count: count)
        
        case .setTintColor(let id, let color, let blend):
            setTintColor(id: id, color: color, blend: blend)
            
        case .setVelocity(let id, let velocity):
            setVelocity(id: id, velocity: velocity)

        case .clearScene:
            clearScene()
            
        case .playSound(let name, let volume):
            playLiveViewSound(name, volume: volume)
            
        case .playMusic(let name, let volume):
            playMusic(name, volume: volume)
            
        case .playInstrument(let kind, let note, let volume):
            playInstrument(kind: kind, note: note, volume: volume)
            
        case .runAction(let id, action: let action, let key):
           runAction(id: id, action: action, key: key)
            
        case .removeAction(let id, let key):
            removeAction(id: id, key: key)
            
        case .removeAllActions(let id):
            removeAllActions(id: id)
            
        case .runAnimation(let id, let animation, let duration, let numberOfTimes):
            runAnimation(id: id, animation: animation, duration: duration, numberOfTimes: numberOfTimes)
            
        case .runCustomAnimation(let id, let animationSequence, let duration, let numberOfTimes):
            runCustomAnimation(id: id, animationSequence: animationSequence, duration: duration, numberOfTimes: numberOfTimes)
            
        case .applyImpulse(let id, let vector):
            applyImpulse(id: id, vector: vector)
            
        case .applyForce(let id, let vector, let duration):
            applyForce(id: id, vector: vector, duration: duration)
            
        case .setText(let id, let text):
            setText(id: id, text: text)
       
        case .setTextColor(let id, let color):
            setTextColor(id: id, color: color)
            
        case .setFontName(let id, let fontName):
            setFontName(id: id, name: fontName)
            
        case .setFontSize(let id, let size):
            setFontSize(id: id, size: size)
            
        case .getGraphics:
            sendGraphics()
            
        case .touchEventAcknowledgement:
            handleTouchEventAck()
            
        case .useOverlay(let overlay):
            useOverlay(overlay)
        
        case .setAccessibilityHints(let id, let hints):
            setAccessibilityHints(id: id, hints: hints)
            
        default:
            ()
        }
    }
    
    func enqueue(_ message: Message) {
        DispatchQueue.global().async {
            guard self.shouldWaitForTouchAcknowledgement else {
                message.send(to: .user)
                return
            }
            if self.waitingForTouchAcknowledegment {
                self.messagesAwaitingSend.insert(message, at: 0)
                return
            }
            if case .sceneTouchEvent(_) = message {
                self.waitingForTouchAcknowledegment = true
            }
            message.send(to: .user)
        }
    }
    
    func useOverlay(_ overlay: Overlay) {
        backgroundNode.overlayImage = overlay.image()
    }
    
    func setAccessibilityHints(id: String, hints: AccessibilityHints?) {
        DispatchQueue.main.async {
            guard let graphic = self.graphicsInfo[id] else { return }
            graphic.accessibilityHints = hints
            
            guard let hints = hints, hints.selectImmediately == true else { return }
            guard let accessibleElements = self.accessibilityElements else { return }
            
            for elem in accessibleElements {
                if let graphicAXElement = elem as? GraphicAccessibilityElement {
                    if id == graphicAXElement.identifier {
                        UIAccessibility.post(notification: .screenChanged, argument: graphicAXElement)
                        break
                    }
                }
            }
        }
    }
    
    func handleTouchEventAck() {
        DispatchQueue.main.async {
            guard self.waitingForTouchAcknowledegment else { return }
            self.waitingForTouchAcknowledegment = false
            var keepIterating = true
            repeat {
                if let message = self.messagesAwaitingSend.popLast() {
                    if case .sceneTouchEvent(_) = message {
                        self.waitingForTouchAcknowledegment = true
                        if self.shouldWaitForTouchAcknowledgement {
                            keepIterating = false
                        }
                        message.send(to: .user)
                        continue
                    }
                    message.send(to: .user)
                }
            } while keepIterating && self.messagesAwaitingSend.count > 0
            
        }
    }
    
    private func disableGraphics() {
        for graphic in graphicsInfo.values.filter({ $0.disablesOnDisconnect }) {
            graphic.setDisabledAppearance(true)
        }
    }
    
    func sendGraphics() {
        var returnGraphics = [Graphic]()
        
        for liveViewGraphic in graphicsInfo.values {
            returnGraphics.append(liveViewGraphic.graphic)
        }
        
        enqueue(.getGraphicsReply(graphics: returnGraphics))
    }
    

    func createNode(id: String, graphicName: String, graphicType: GraphicType) {
        DispatchQueue.main.async {
            let graphic = LiveViewGraphic(id: id, name: graphicName, graphicType: graphicType)
            self.graphicsInfo[id] = graphic
            graphic.backingNode.name = id
        }
    }
    
    private var characterMap: [String:String] = ["alien":"Character3","codeMachine":"Character1","giraffe":"animal3","elephant":"animal1","piranha":"animal2"]
    
    func runAnimation(id: String, animation: String, duration: Double, numberOfTimes: Int) {
        DispatchQueue.main.async {
            guard let graphic = self.graphicsInfo[id] else { return }
            var resourceNames: [String] = []
            var animationCycle: SKAction = SKAction()
            
            if animation == "springExtend" {
                resourceNames.append("springUnloaded@2x")
                resourceNames.append("springLoaded@2x")
                animationCycle = SKAction.createAnimation(fromResourceURLs: resourceNames, timePerFrame: duration)
            } else if animation == "balloon1Pop" {
                for i in 0...5 {
                    resourceNames.append("balloonPOP/balloonPOP.0000" + String(i))
                }
                animationCycle = SKAction.createAnimation(fromResourceURLs: resourceNames, timePerFrame: duration)
            } else if animation == "balloon2Pop" {
                for i in 1...6 {
                    resourceNames.append("balloonPOP2/balloonPOP2.0000" + String(i))
                }
                animationCycle = SKAction.createAnimation(fromResourceURLs: resourceNames, timePerFrame: duration)
            } else if animation == "bombExplode" {
                for i in 0...8 {
                    resourceNames.append("bombEXPLODE/bombEXPLODE.0000" + String(i))
                }
                animationCycle = SKAction.createAnimation(fromResourceURLs: resourceNames, timePerFrame: duration)
                
            } else if animation == "bombIdle" {
                for i in 0...9 {
                    resourceNames.append("bombIDLE/bombIDLE.0000" + String(i))
                }
                resourceNames.append("bombIDLE/bombIDLE.00010")
                resourceNames.append("bombIDLE/bombIDLE.00011")
                animationCycle = SKAction.createAnimation(fromResourceURLs: resourceNames, timePerFrame: duration)
            } else if animation == "throwSwitchLeft" {
                resourceNames.append("switchMid@2x")
                resourceNames.append("switchLeft@2x")
                animationCycle = SKAction.createAnimation(fromResourceURLs: resourceNames, timePerFrame: duration)
            } else if animation == "throwSwitchRight" {
                resourceNames.append("switchMid@2x")
                resourceNames.append("switchRight@2x")
                animationCycle = SKAction.createAnimation(fromResourceURLs: resourceNames, timePerFrame: duration)
            } else if animation == "tree1Idle" {
                for i in 0...6 {
                    resourceNames.append("tree1WALK/tree1WALK.0000" + String(i))
                }
                resourceNames.append("tree1@2x")
                animationCycle = SKAction.createAnimation(fromResourceURLs: resourceNames, timePerFrame: duration)
            } else if animation == "tree2Idle" {
                for i in 0...6 {
                    resourceNames.append("tree2WALK/tree2WALK.0000" + String(i))
                }
                resourceNames.append("tree2@2x")
                animationCycle = SKAction.createAnimation(fromResourceURLs: resourceNames, timePerFrame: duration)
            } else if animation == "greenButton" {
                if let originalTexture = graphic.backingNode.texture,
                    let highlightTexture = graphic.buttonHighlightTexture {
                    let textures = [highlightTexture, originalTexture]
                    animationCycle = SKAction.animate(with: textures, timePerFrame: duration)
                }
            } else if animation == "redButton" {
                if let originalTexture = graphic.backingNode.texture,
                    let highlightTexture = graphic.buttonHighlightTexture {
                    let textures = [highlightTexture, originalTexture]
                    animationCycle = SKAction.animate(with: textures, timePerFrame: duration)
                }
            } else if animation.containsSubstring(".idle") {
                let characterName = animation.replacingOccurrences(of: ".idle", with: "", options: .literal, range: nil)
                let resourceName = self.characterMap[characterName]! + "IDLE"
                for i in 0...9 {
                    resourceNames.append("\(resourceName)/\(resourceName).0000" + String(i))
                }
                resourceNames.append("\(resourceName)/\(resourceName).00010")
                resourceNames.append("\(resourceName)/\(resourceName).00011")
                animationCycle = SKAction.createAnimation(fromResourceURLs: resourceNames, timePerFrame: duration)
            } else if animation.containsSubstring(".walk") {
                let characterName = animation.replacingOccurrences(of: ".walk", with: "", options: .literal, range: nil)
                let resourceName = self.characterMap[characterName]! + "WALK"
                for i in 0...5 {
                    resourceNames.append("\(resourceName)/\(resourceName).0000" + String(i))
                }
                animationCycle = SKAction.createAnimation(fromResourceURLs: resourceNames, timePerFrame: duration)
            } else if animation.containsSubstring(".jump") {
                let characterName = animation.replacingOccurrences(of: ".jump", with: "", options: .literal, range: nil)
                let resourceName = self.characterMap[characterName]! + "JUMP"
                let staticResourceName = self.characterMap[characterName]! + "STATIC"
                for i in 0...5 {
                    resourceNames.append("\(resourceName)/\(resourceName).0000" + String(i))
                }
                resourceNames.append("\(staticResourceName).00000@2x")
                animationCycle = SKAction.createAnimation(fromResourceURLs: resourceNames, timePerFrame: duration)
            } else if animation.containsSubstring(".duck") {
                let characterName = animation.replacingOccurrences(of: ".duck", with: "", options: .literal, range: nil)
                let resourceName = self.characterMap[characterName]! + "DUCK"
                let staticResourceName = self.characterMap[characterName]! + "STATIC"
                resourceNames.append("\(resourceName).00000")
                resourceNames.append("\(staticResourceName).00000")
                animationCycle = SKAction.createAnimation(fromResourceURLs: resourceNames, timePerFrame: duration)
            }
            
            var animationAction: SKAction?
            
            if numberOfTimes == 1 {
                animationAction = animationCycle
            } else if numberOfTimes == -1 {
                animationAction = SKAction.repeatForever(animationCycle)
            } else if numberOfTimes > 1 {
                animationAction = SKAction.repeat(animationCycle, count: numberOfTimes)
            }
            
            if let animationAction = animationAction {
                graphic.backingNode.run(animationAction)
            }
        }
    }
    
    func runCustomAnimation(id: String, animationSequence: [String], duration: Double, numberOfTimes: Int) {
        DispatchQueue.main.async {
            guard let graphic = self.graphicsInfo[id] else { return }
            let animation = SKAction.createAnimation(fromResourceURLs: animationSequence, timePerFrame: duration)
            if numberOfTimes == 0 {
                return
            } else if numberOfTimes == 1 {
                graphic.backingNode.run(animation)
            } else if numberOfTimes == -1 {
                let runForever = SKAction.repeatForever(animation)
                graphic.backingNode.run(runForever)
            } else if numberOfTimes > 1 {
                let runMultiple = SKAction.repeat(animation, count: numberOfTimes)
                graphic.backingNode.run(runMultiple)
            } else {
                return
            }
        
        }
        
    }

    func placeGraphic(id: String, position: CGPoint, anchor: AnchorPoint, isPrintable: Bool) {
        DispatchQueue.main.async {
            if let graphic = self.graphicsInfo[id] {
                if graphic.backingNode.parent == nil {
                    self.containerNode.addChild(graphic.backingNode)
                }
                
                // Compute center position from anchor point and size.
                // NOTE: anchor point is ignored after initial placement.
                var centerPosition = CGPoint.zero
                switch anchor {
                case .center:
                    centerPosition = position
                case .left:
                    centerPosition = CGPoint(x: position.x + (graphic.backingNode.size.width / 2), y: position.y)
                case .top:
                    centerPosition = CGPoint(x: position.x, y: position.y - (graphic.backingNode.size.height / 2))
                case .right:
                    centerPosition = CGPoint(x: position.x - (graphic.backingNode.size.width / 2), y: position.y)
                case .bottom:
                    centerPosition = CGPoint(x: position.x, y: position.y + (graphic.backingNode.size.height / 2))
                }
                
                graphic.backingNode.position = isPrintable ? LiveViewScene.printPosition : centerPosition
                
                if isPrintable {
                    LiveViewScene.printPosition.y -= graphic.backingNode.size.height
                }
                
                self.setupPositionTimer()
                
                self.addAccessibleGraphic(graphic)
            }
        }
    }
    
    internal func setupPositionTimer() {
        if self.graphicsPositionUpdateTimer == nil {
            self.graphicsPositionUpdateTimer = Timer.scheduledTimer(withTimeInterval:1.0/20.0, repeats: true, block: { (t : Timer) in
                var positions = [String:CGPoint]()
                var sizes = [String:CGSize]()
                
                for id in self.graphicsInfo.keys {
                    if let graphic = self.graphicsInfo[id] {
                        let backingNode = graphic.backingNode
                        
                        if let physicsBody = backingNode.physicsBody {
                            if physicsBody.isDynamic {
                                positions[id] = backingNode.position
                            }
                        }
                        
                        sizes[id] = backingNode.size
                    }
                }
                
                if positions.count > 0 || sizes.count > 0 {
                    self.enqueue(.updateGraphicAttributes(positions: positions, sizes: sizes))
                }
            })
        }
    }
    


    func addSceneObservers() {
        enterBackgroundObserver = nc.addObserver(forName: .NSExtensionHostDidEnterBackground, object: nil, queue: .main) { _ in
            self.graphicsPositionUpdateTimer?.invalidate()
            self.graphicsPositionUpdateTimer = nil
        }
        
        
        willEnterForegroundObserver = nc.addObserver(forName: .NSExtensionHostWillEnterForeground, object: nil, queue: .main) { _ in
            self.setupPositionTimer()
        }
    }
    
    func removeSceneObservers() {
        self.nc.removeObserver(self.enterBackgroundObserver as Any)
        self.nc.removeObserver(self.willEnterForegroundObserver as Any)
    }
    
    func removeGraphic(id: String) {
        DispatchQueue.main.async {
            if let spriteNode = self.containerNode.childNode(withName: id) as? SKSpriteNode {
                spriteNode.removeFromParent()
                if self.graphicsInfo[id] != nil {
                    self.graphicsInfo.removeValue(forKey: id)
                    self.enqueue(.removedGraphic(id: id))
                }
                
                self.setNeedsUpdateAccessibility(notify: false)
                
                if self.graphicsInfo.count == 0 {
                    self.graphicsPositionUpdateTimer?.invalidate()
                    self.graphicsPositionUpdateTimer = nil
                }
            }
        }
    }
    
    func playLiveViewSound(_ sound: String, volume: Int = 40) {
        if connectedToUserProcess, let soundType = Sound(rawValue: sound) {
            if let url = soundType.url {
                do {
                    let audioPlayer = try AVAudioPlayer(contentsOf: url)
                    audioPlayer.volume = Float(max(min(volume, 100), 0)) / 100.0
                    audioController.register(audioPlayer)
                    audioPlayer.play()
                    playSound(soundType, volume: volume)
                } catch {}

            }
        }
    }
    
    func playMusic(_ sound: String, volume: Int = 40) {
        if let musicType = Music(rawValue: sound) {
            if !audioController.isBackgroundAudioLoopPlaying {
                audioController.playBackgroundAudioLoop(musicType, volume: volume)
            } else if musicType != audioController.backgroundAudioMusic {
                audioController.playBackgroundAudioLoop(musicType, volume: volume)
            } else {
                audioController.adjustBackgroundAudioLoop(volume: volume)
            }
        }
    }
    
    func playInstrument(kind: Instrument.Kind, note: Double, volume: Int) {
        DispatchQueue.main.async {
            if self.instruments[kind] == nil {
                self.instruments[kind] = self.createInstrument(kind)
            }
            guard let instrument = self.instruments[kind] else { return }
            
            // Get corresponding MIDI note value.
            let noteIndex = min(max(Int(note), 0), instrument.availableNotes.count - 1)
            
            let velocity = Double(max(min(Int(volume), 100), 0)) / 100.0 * 127.0
            
            instrument.startPlaying(noteValue: instrument.availableNotes[noteIndex], withVelocity: UInt8(velocity), onChannel: 0)
        }
    }
    
    private func createInstrument(_ kind: Instrument.Kind) -> Instrument {
        let instrument = Instrument(kind: kind)
        instrument.connect(instrumentsEngine)
        instrument.defaultVelocity = 64
        return instrument
    }
    
    func setBorderPhysics(_ enabled: Bool) {
        DispatchQueue.main.async {
            if enabled {
                let borderBody = SKPhysicsBody(edgeLoopFrom: self.frame)
                self.physicsBody = borderBody
                
            } else {
                self.physicsBody = nil
            }
            
        }
    }
    
    func setSceneBackgroundImage(image: Image?) {
        DispatchQueue.main.async {
            self.backgroundImage = image
            
            self.setNeedsUpdateAccessibility(notify: true)
        }
    }
    
    func setSceneBackgroundColor(color: UIColor) {
        DispatchQueue.main.async { [unowned self] in
            self.backgroundNode.backgroundColor = color
            
            self.setNeedsUpdateAccessibility(notify: true)
        }
    }
    
    func setGridOverlay(_ visible: Bool) {
        DispatchQueue.main.async {
            self.backgroundNode.isGridOverlayVisible = visible
        }
    }
    
    func setImage(id: String, image: Image?, columns: Int? = nil, rows: Int? = nil, isDynamic: Bool? = nil) {
        DispatchQueue.main.async { [unowned self] in
            guard let graphic = self.graphicsInfo[id] else { return }
            graphic.columns = columns ?? 1
            graphic.rows = rows ?? 1
            graphic.image = image
            if let isDynamic = isDynamic {
                graphic.isDynamic = isDynamic
            }
        }
    }
    
    func setDisablesOnDisconnect(id: String, disablesOnDisconnect: Bool) {
        DispatchQueue.main.async { [unowned self] in
            guard let graphic = self.graphicsInfo[id] else { return }
            graphic.disablesOnDisconnect = disablesOnDisconnect
        }
    }
    
    func setShape(id: String, shape: BasicShape?) {
        DispatchQueue.main.async { [unowned self] in
            guard let graphic = self.graphicsInfo[id] else { return }
            graphic.shape = shape
        }
    }
    
    func setBounciness(id: String, bounciness: Double?) {
        DispatchQueue.main.async { [unowned self] in
            guard let graphic = self.graphicsInfo[id], let bounciness = bounciness else { return }
            graphic.bounciness = CGFloat(bounciness)
        }
    }
    
    func setAffectedByGravity(id: String, gravity: Bool?) {
        DispatchQueue.main.async { [unowned self] in
            guard let graphic = self.graphicsInfo[id], let gravity = gravity else { return }
            graphic.isAffectedByGravity = gravity
        }
    }
    
    func setIsDynamic(id: String, isDynamic: Bool?) {
        DispatchQueue.main.async { [unowned self] in
            guard let graphic = self.graphicsInfo[id], let isDynamic = isDynamic else { return }
            graphic.isDynamic = isDynamic
        }
    }
    
    func setAllowsRotation(id: String, allowsRotation: Bool?) {
        DispatchQueue.main.async { [unowned self] in
            guard let graphic = self.graphicsInfo[id], let allowsRotation = allowsRotation else { return }
            graphic.allowsRotation = allowsRotation
        }
    }
    
    func setAllowsTouchInteraction(id: String, allowsTouchInteraction: Bool?) {
        DispatchQueue.main.async { [unowned self] in
            guard let graphic = self.graphicsInfo[id], let allowsTouchInteraction = allowsTouchInteraction else { return }
            graphic.allowsTouchInteraction = allowsTouchInteraction
        }
    }
    
    func setXScale(id: String, xScale: Double) {
        DispatchQueue.main.async { [unowned self] in
            guard let graphic = self.graphicsInfo[id] else { return }
            graphic.backingNode.xScale = CGFloat(xScale)
        }
    }
    
    func setYScale(id: String, yScale: Double) {
        DispatchQueue.main.async { [unowned self] in
            guard let graphic = self.graphicsInfo[id] else { return }
            graphic.backingNode.yScale = CGFloat(yScale)
        }
    }
    
    func setSceneGravity(vector: CGVector) {
        DispatchQueue.main.async {
            self.physicsWorld.gravity = vector
        }
    }
    
    func glow(id: String, radius: Double = 30.0, period: Double = 0.5, count: Int = 1) {
        DispatchQueue.main.async { [unowned self] in
            guard let graphic = self.graphicsInfo[id] else { return }
            
            graphic.glowRadius = radius
            
            if let glowNode = graphic.glowNode {
                let glowIn = SKAction.fadeIn(withDuration: period / 2.0)
                let glowOut = SKAction.fadeOut(withDuration: period / 2.0)
                
                glowIn.timingMode = SKActionTimingMode.easeOut
                glowOut.timingMode = SKActionTimingMode.easeOut
                
                let sequence = SKAction.sequence([glowIn, glowOut])
                
                if count == -1 {
                    glowNode.run(.repeatForever(sequence))
                }
                else {
                    glowNode.run(.repeat(sequence, count: count))
                }
            }
        }
    }

    func setTintColor(id: String, color: UIColor?, blend: Double) {
        DispatchQueue.main.async { [unowned self] in
            guard let graphic = self.graphicsInfo[id] else { return }
            
            graphic.setTintColor(color, blend: blend)
        }
    }
    
    func setVelocity(id: String, velocity: CGVector) {
        DispatchQueue.main.async { [unowned self] in
            guard let graphic = self.graphicsInfo[id] else { return }
            guard let physicsBody = graphic.backingNode.physicsBody  else { return }
            physicsBody.velocity = velocity
        }
    }
    
    func clearScene() {
        DispatchQueue.main.async {
            self.graphicsPositionUpdateTimer?.invalidate()
            self.graphicsPositionUpdateTimer = nil
            self.containerNode.removeAllChildren()
            self.graphicsInfo.removeAll()
            type(of: self).printPosition = type(of:self).initialPrintPosition
            
            self.setNeedsUpdateAccessibility(notify: false)
        }
    }
    
    func runAction(id: String, action: SKAction, key: String?) {
        DispatchQueue.main.async {
            guard let graphic = self.graphicsInfo[id] else { return }
            if let key = key {
                graphic.backingNode.run(action, withKey: key)
            }
            else {
                graphic.backingNode.run(action)
            }
        }
    }
    
    func removeAction(id: String, key: String) {
        DispatchQueue.main.async {
            guard let graphic = self.graphicsInfo[id] else { return }
            graphic.backingNode.removeAction(forKey: key)
        }
    }
    
    func removeAllActions(id: String) {
        DispatchQueue.main.async {
            guard let graphic = self.graphicsInfo[id] else { return }
            graphic.backingNode.removeAllActions()
        }
    }
    
    func applyImpulse(id: String, vector: CGVector) {
        DispatchQueue.main.async {
            guard let graphic = self.graphicsInfo[id] else { return }

            if let physicsBody = graphic.backingNode.physicsBody {
                physicsBody.velocity = CGVector(dx: 0, dy: 0)
                physicsBody.applyImpulse(CGVector(dx: (vector.dx) / 3, dy: (vector.dy) / 3))
            } else {
                return
            }
            
        }
    }
    
    func applyForce(id: String, vector: CGVector, duration: Double) {
        DispatchQueue.main.async {
            guard let graphic = self.graphicsInfo[id] else { return }
            
            if let _ = graphic.backingNode.physicsBody {
                let forceAction = SKAction.applyForce(CGVector(dx: vector.dx, dy: vector.dy), duration: duration)
                graphic.backingNode.run(forceAction)
            } else {
                return
            }
        }
    }
    
    func setText(id: String, text: String?) {
        DispatchQueue.main.async {
            guard let graphic = self.graphicsInfo[id] else { return }
            graphic.text = text
        }
    }
    
    func setTextColor(id: String, color: UIColor) {
        DispatchQueue.main.async {
            guard let graphic = self.graphicsInfo[id] else { return }
            graphic.textColor = color
        }
    }
    
    func setFontName(id: String, name: String) {
        DispatchQueue.main.async {
            guard let graphic = self.graphicsInfo[id] else { return }
            graphic.fontName = name
        }
    }

    func setFontSize(id: String, size: Int) {
        DispatchQueue.main.async {
            guard let graphic = self.graphicsInfo[id] else { return }
            graphic.fontSize = size
        }
    }
    
    func disconnectedFromUserCode() {
        DispatchQueue.main.async {
            self.connectedToUserProcess = false
            self.messagesAwaitingSend.removeAll()
            self.waitingForTouchAcknowledegment = false
            
            self.removeSceneObservers()
            
            self.graphicsPositionUpdateTimer?.invalidate()
            self.graphicsPositionUpdateTimer = nil
            
            self.disableGraphics()
        }
    }
    
    func connectedToUserCode() {
        DispatchQueue.main.async {
            self.connectedToUserProcess = true
            self.backgroundNode.backgroundColor = nil
            self.messagesAwaitingSend.removeAll()
            self.waitingForTouchAcknowledegment = false
            
            self.addSceneObservers()
        }
    }
    
    // MARK: Accessibility
    
    private var graphicsPlacedCount = 0
    
    private var accessibilityAllowsDirectInteraction: Bool = false {
        didSet {
            let note : String
            
            if accessibilityAllowsDirectInteraction {
                note = NSLocalizedString("Direct interaction enabled", comment: "AX description when direct interaction is enabled")
            }
            else {
                note = NSLocalizedString("Direct interaction disabled", comment: "AX description when direct interaction is disabled")
            }
            
            UIAccessibility.post(notification: .layoutChanged, argument: note)
        }
    }
    
    public override var isAccessibilityElement: Bool {
        set { }
        get {
            return accessibilityAllowsDirectInteraction
        }
    }
    
    public override var accessibilityLabel: String? {
        set { }
        get {
            let label : String
            
            if accessibilityAllowsDirectInteraction {
                label = NSLocalizedString("Scene, direct interaction enabled", comment: "AX description describing the scene itself when direct interaction is enabled")
            }
            else {
                label = NSLocalizedString("Scene, direct interaction disabled", comment: "AX description describing the scene itself when direct interaction is disabled")
            }
            
            return label
        }
    }
    
    public override var accessibilityTraits: UIAccessibilityTraits {
        set { }
        get {
            if accessibilityAllowsDirectInteraction {
                return .allowsDirectInteraction
            }
            
            return .none
        }
    }
    
    private func findGraphics() -> [(String, LiveViewGraphic)] {
        // Sort the graphics vertically.
        let orderedGraphicsInfo = graphicsInfo.tupleContents.sorted { lhs, rhs in
            return lhs.1.position.y > rhs.1.position.y
        }
        
        return orderedGraphicsInfo.filter { element in
            let graphic = element.1
            guard graphic.backingNode.parent == containerNode else { return false }
            return true
        }
    }
    
    public override var accessibilityElements: [Any]? {
        set { /* Should not need to set */ }
        get {
            guard !accessibilityAllowsDirectInteraction else { return nil }
            
            // VO will ask for accessible elements pretty frequently. We should only update our list of items when the number of graphics we’re tracking changes.
            guard axElements.isEmpty else { return axElements }
            
            // Add accessibility elements
            var sceneLabel = NSLocalizedString("Scene, ", comment: "AX label")
            if let backgroundImage = backgroundImage {
                sceneLabel += String(format: NSLocalizedString("background image: %@, ", comment: "AX label: background image description."), backgroundImage.description)
            }
            
            // Describe the color even if there is an image (it’s possible the image does not cover the entire scene).
            if let backgroundColor = backgroundNode.backgroundColor {
                sceneLabel += String(format: NSLocalizedString("background color: %@.", comment: "AX label: scene background color description."), backgroundColor.accessibleDescription)
            }
            
            _addBGElement(frame: view!.bounds, label: sceneLabel, elementCount: findGraphics().count)
            
            let graphics = findGraphics()
            
            graphicAccessibilityElementGroupsByID.removeAll()
            
            // Add the individual graphics in order based on the quadrant.
            for (id, graphic) in graphics {
                if let hints = graphic.accessibilityHints {
                    if hints.makeAccessibilityElement {
                        if let groupID = hints.groupID {
                            var element: GraphicAccessibilityElement? = graphicAccessibilityElementGroupsByID[groupID]
                            
                            if element == nil {
                                element = GraphicAccessibilityElement(delegate: self, identifier: groupID, accessibilityHints: hints)
                                
                                axElements.append(element!)
                                
                                graphicAccessibilityElementGroupsByID[groupID] = element
                            }
                            
                            if let element = element {
                                element.graphics.append(graphic.graphic)
                            }
                        } else {
                            let element = GraphicAccessibilityElement(delegate: self, identifier: id, accessibilityHints: hints)
                            
                            element.graphics = [graphic.graphic]
                            
                            axElements.append(element)
                        }
                    }
                }
            }
            
            return axElements
        }
    }
    
    private func _addBGElement(frame: CGRect, label: String, elementCount: Int) {
        let element = BackgroundAccessibilityElement(delegate: self)
        element.accessibilityFrame = UIAccessibility.convertToScreenCoordinates(frame, in: view!)
        
        var label = label
        if elementCount > 0 {
            if (elementCount == 1) {
                label = String(format: NSLocalizedString("%@, %d graphic found.", comment: "AX label: count of graphics (singular)."), label, elementCount)
            }
            else {
                label = String(format: NSLocalizedString("%@, %d graphics found.", comment: "AX label: count of graphics (plural)."), label, elementCount)
            }
        }
        
        element.accessibilityLabel = label
        if connectedToUserProcess {
            element.accessibilityHint = NSLocalizedString("Double tap to toggle direct interaction", comment: "AX label")
        }
        axElements.append(element)
    }
    
    // MARK: GraphicAccessibilityElementDelegate
    
    private func graphicDescription(for graphic: LiveViewGraphic) -> String {
        let label: String
        let imageDescription: String
        let graphicRole: String
        var updatedValueDescription: String? = nil

        if let accLabel = graphic.accessibilityHints?.accessibilityLabel {
            imageDescription = accLabel
        } else if let text = graphic.text {
            imageDescription = text
        } else if !graphic.name.isEmpty {
            imageDescription = graphic.name
        } else if let image = graphic.image {
            imageDescription = image.description
        } else {
            imageDescription = ""
        }
        
        if graphic.accessibilityHints?.needsUpdatedValue == true {
            switch graphic.graphicType {
            case .label:
                updatedValueDescription = graphic.text
            default:
                break
            }
        }
        
        switch graphic.graphicType {
        case .button:
            graphicRole = NSLocalizedString("button", comment: "graphic type")
        case .character:
            graphicRole = NSLocalizedString("character", comment: "graphic type")
        case .graphic:
            graphicRole = NSLocalizedString("graphic", comment: "graphic type")
        case .label:
            graphicRole = NSLocalizedString("label", comment: "graphic type")
        case .sprite:
            graphicRole = NSLocalizedString("sprite", comment: "graphic type")
        }
        
        if let updatedValueDescription = updatedValueDescription {
            label = String(format: NSLocalizedString("%@, %@, %@, at x %d, y %d", comment: "AX label: description of an image, its value, and its position in the scene."), imageDescription, updatedValueDescription, graphicRole, Int(graphic.position.x), Int(graphic.position.y))
        } else {
            label = String(format: NSLocalizedString("%@, %@, at x %d, y %d", comment: "AX label: description of an image and its position in the scene."), imageDescription, graphicRole, Int(graphic.position.x), Int(graphic.position.y))
        }
        
        
        return label
    }
    
    fileprivate func accessibilityLabel(element: GraphicAccessibilityElement) -> String {
        var label = ""
        if let liveViewGraphic = graphicsInfo[element.identifier] {
            label = graphicDescription(for: liveViewGraphic)
        }
        return label
    }
    
    fileprivate func accessibilityFrame(element: GraphicAccessibilityElement) -> CGRect {
        var frame = CGRect.zero
        
        if let liveViewGraphic = graphicsInfo[element.identifier], let hints = liveViewGraphic.accessibilityHints {
            if let groupID = hints.groupID, let element = graphicAccessibilityElementGroupsByID[groupID] {
                for graphic in element.graphics {
                    if let graphic = graphicsInfo[graphic.id] {
                        if frame == CGRect.zero {
                            frame = graphic.backingNode.accessibilityFrame
                        } else {
                            frame = frame.union(graphic.backingNode.accessibilityFrame)
                        }
                    }
                }
            } else {
                frame = liveViewGraphic.backingNode.accessibilityFrame
            }
            
            frame = frame.insetBy(dx: -10, dy: -10)
        }
        return frame
    }
    
    fileprivate func accessibilityTraits(element: GraphicAccessibilityElement) -> UIAccessibilityTraits {
        if let liveViewGraphic = graphicsInfo[element.identifier] {
            switch liveViewGraphic.graphicType {
            case .sprite:
                return .image
            case .button:
                return .button
            case .label:
                return .staticText
            default:
                return .none
            }
        }
        
        return .none
    }
    
    fileprivate func accessibilitySimulateTouch(at point: CGPoint, firstTouch: Bool = false, lastTouch: Bool = false) {
        let viewTouchPosition = UIScreen.main.coordinateSpace.convert(point, to: view!)
        var skTouchPosition = convertPoint(fromView: viewTouchPosition)
        
        skTouchPosition.x += 500.0
        skTouchPosition.y -= 500.0
        
        handleTouch(at: skTouchPosition, firstTouch: firstTouch, lastTouch: lastTouch)
    }
    
    fileprivate func accessibilityActivate(element: BackgroundAccessibilityElement) -> Bool {
        if (connectedToUserProcess) {
            accessibilityAllowsDirectInteraction = !accessibilityAllowsDirectInteraction
        }
        return true
    }
    
    public override var accessibilityCustomActions : [UIAccessibilityCustomAction]? {
        set { }
        get {
            let summary = UIAccessibilityCustomAction(name: NSLocalizedString("Scene summary.", comment: "AX action name"), target: self, selector: #selector(sceneSummaryAXAction))
            let sceneDetails = UIAccessibilityCustomAction(name: NSLocalizedString("Image details for scene.", comment: "AX action name"), target: self, selector: #selector(imageDetailsForScene))

            
            return [summary, sceneDetails]
        }
    }
    
    @objc func sceneSummaryAXAction() {
        var imageListDescription = ""
        
        let count = findGraphics().count
        if count > 0 {
            if (count == 1) {
                imageListDescription += String(format: NSLocalizedString("%d graphic found.", comment: "AX label: count of graphics (singular)."), count)
            }
            else {
                imageListDescription += String(format: NSLocalizedString("%d graphics found.", comment: "AX label: count of graphics (plural)."), count)
            }
        }
        
        UIAccessibility.post(notification: .announcement, argument: imageListDescription)
    }
    
    @objc func imageDetailsForScene() {
        let graphics = findGraphics()
        var imageListDescription = ""
        switch graphics.count {
        case 0:
            imageListDescription += NSLocalizedString("Zero graphics found in scene.", comment: "AX label, count of graphics (none found)")
        case 1:
            imageListDescription += String(format: NSLocalizedString("%d graphic found.", comment: "AX label: count of graphics (singular)."), graphics.count)
        default:
            imageListDescription += String(format: NSLocalizedString("%d graphics found.", comment: "AX label: count of graphics (plural)."), graphics.count)
        }
        
        for (_, liveViewGraphic) in graphics {
            imageListDescription += graphicDescription(for: liveViewGraphic)
            imageListDescription += ", "
        }
        
        UIAccessibility.post(notification: .announcement, argument: imageListDescription)
    }
    
    func addAccessibleGraphic(_ graphic: LiveViewGraphic) {
        if UIAccessibility.isVoiceOverRunning {
            self.graphicPlacedAudioPlayer.play()
            self.graphicsPlacedCount += 1
        }
    }
    
    func setNeedsUpdateAccessibility(notify: Bool) {
        self.axElements.removeAll(keepingCapacity: true)
        
        if notify {
            UIAccessibility.post(notification: .screenChanged, argument: self.accessibilityElements?.first)
        }
    }
    
    private lazy var graphicPlacedAudioPlayer : AVAudioPlayer = {
        let url = Bundle.main.url(forResource: "GraphicPlaced", withExtension: "aifc")
        let p = try! AVAudioPlayer(contentsOf: url!)
        p.volume = 0.5
        
        return p
    }()
}

private protocol GraphicAccessibilityElementDelegate {
    func accessibilityLabel(element: GraphicAccessibilityElement) -> String
    func accessibilityFrame(element: GraphicAccessibilityElement) -> CGRect
    func accessibilityTraits(element: GraphicAccessibilityElement) -> UIAccessibilityTraits
    
    func accessibilitySimulateTouch(at point: CGPoint, firstTouch: Bool, lastTouch: Bool)
}

private class GraphicAccessibilityElement : UIAccessibilityElement {
    let identifier: String
    let delegate: GraphicAccessibilityElementDelegate
    let accessibilityHints: AccessibilityHints
    
    public var graphics = [Graphic]()
    
    init(delegate: GraphicAccessibilityElementDelegate, identifier: String, accessibilityHints: AccessibilityHints) {
        self.identifier = identifier
        self.delegate = delegate
        self.accessibilityHints = accessibilityHints
        
        super.init(accessibilityContainer: delegate)
        
        accessibilityIdentifier = identifier
    }
    
    public override var accessibilityLabel: String? {
        set {
            // no-op
        }
        get {
            return delegate.accessibilityLabel(element: self)
        }
    }
    
    public override var accessibilityFrame: CGRect {
        set {
            // no-op
        }
        get {
            return delegate.accessibilityFrame(element: self)
        }
    }
    
    public override var accessibilityTraits: UIAccessibilityTraits {
        set { }
        get {
            return delegate.accessibilityTraits(element: self)
        }
    }
    
    public override var accessibilityCustomActions : [UIAccessibilityCustomAction]? {
        set { }
        get {
            var actions: [UIAccessibilityCustomAction]? = nil
            
            if accessibilityHints.actions.contains(.swipe) {
                actions = [UIAccessibilityCustomAction(name: NSLocalizedString("Graphic swipe.", comment: "AX action name"), target: self, selector: #selector(graphicSwipeAXAction))]
            }
            
            return actions
        }
    }
    
    @objc func graphicSwipeAXAction() {
        if graphics.count > 0 {
            let total = 50
            var count = 0
            let frame = accessibilityFrame
            
            _ = Timer.scheduledTimer(withTimeInterval: 0.05, repeats: true) { timer in
                if count == total {
                    timer.invalidate()
                }

                
                let x = Double(frame.origin.x) + Double(frame.size.width) * (Double(count) / Double(total))
                let y = Double(frame.origin.y + frame.size.height) - Double(frame.size.height) * (Double(count) / Double(total))
                
                self.delegate.accessibilitySimulateTouch(at: CGPoint(x: x, y: y), firstTouch: count == 0, lastTouch: count == total)
                
                count += 1
            }
        }
    }
}

private protocol BackgroundAccessibilityElementDelegate {
    func accessibilityActivate(element: BackgroundAccessibilityElement) -> Bool
}

private class BackgroundAccessibilityElement : UIAccessibilityElement {
    let delegate: BackgroundAccessibilityElementDelegate
    init(delegate: BackgroundAccessibilityElementDelegate) {
        self.delegate = delegate
        super.init(accessibilityContainer: delegate)
    }
    public override func accessibilityActivate() -> Bool {
        return delegate.accessibilityActivate(element: self)
    }
}

extension Dictionary {
    fileprivate var tupleContents: [(Key, Value)] {
        return self.map { ($0.key, $0.value) }
    }
}

// MARK: AudioPlaybackDelegate
extension LiveViewScene: AudioPlaybackDelegate {
    
    func audioSession(_ session: AudioSession, isPlaybackBlocked: Bool) {
        
        if isPlaybackBlocked {
            // Pause background audio if the audio session is blocked, for example, by the app going into the background.
            audioController.pauseBackgroundAudioLoop()
            audioController.stopAllPlayersExceptBackgroundAudio()
        } else {
            // Resume if audio session is unblocked, assuming audio is enabled.
            if audioController.isBackgroundAudioEnabled {
                audioController.resumeBackgroundAudioLoop()
            }
        }
    }
}

