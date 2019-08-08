//
//  Player.swift
//  
//  Copyright © 2016-2019 Apple Inc. All rights reserved.
//

import Foundation
import SpriteKit

/// An enumeration of types of players, including: alien, codeMachine, giraffe, elephant, and piranha.
///
/// - localizationKey: PlayerType
public enum PlayerType: String {
    case alien
    case codeMachine
    case giraffe
    case elephant
    case piranha
}

/// An enumeration of the available animations, a few examples are: greenButton, redButton, and springExtend.
///
/// - localizationKey: Animation
public enum Animation: String {
    case greenButton
    case redButton
    case springExtend
    case throwSwitchLeft
    case throwSwitchRight
    case balloon1Pop
    case balloon2Pop
    case bombIdle
    case bombExplode
    case tree1Idle
    case tree2Idle
}

/// Player (a graphic object) is made from an image or string, and can be placed in a scene.
///
/// - localizationKey: Player
public class Player: Sprite {
    
    /// Some Player animations include: walk, duck, jump, and idle.
    ///
    /// - localizationKey: Player.PlayerAnimation
    public enum PlayerAnimation: String {
        case walk
        case duck
        case jump
        case idle
    }
    
    fileprivate static var defaultNameCount: Int = 1
    
    var facingForward = true
    
    /// An attribute of the Player that identifies its character type, including: alien, codeMachine, giraffe, elephant, or piranha.
    ///
    /// - localizationKey: Player.characterType
    var characterType: PlayerType = .alien
    
    /// Runs an animation on the given Player.
    ///
    /// - Parameter animation: An enumeration specifying the animation to run.
    /// - Parameter timePerFrame: The amount of time between images in the animation sequence.
    /// - Parameter numberOfTimes: The number of times to repeat the animation. Setting this value to `-1` repeats the animation indefinitely.
    ///
    ///- localizationKey: Player.runAnimation(_:timePerFrame:numberOfTimes:)
    public func runAnimation(_ animation: PlayerAnimation, timePerFrame: Double = 0.05, numberOfTimes: Int = 1) {
        let characterAnimation = characterType.rawValue + "." + animation.rawValue
        Message.runAnimation(id: id, animation: characterAnimation, duration: timePerFrame, numberOfTimes: numberOfTimes).send()
    }
    
    @available(*, unavailable, message: "Player uses it’s own implementation of `runAnimation` and does not use the base class implementation.")
    override public func runAnimation(_ animation: Animation, timePerFrame: Double, numberOfTimes: Int) {
        // Use player-specific run animation instead.
    }
    
    /// Creates a Player with a specified type and name.
    ///
    /// - Parameter type: The type of Player you want.
    /// - Parameter name: A name you give to your Player.
    ///
    /// - localizationKey: Player(type:name:)
    public convenience init(type: PlayerType, name: String = "") {
        if name == "" {
            self.init(graphicType: .character, name: "character" + String(Player.defaultNameCount))
            Player.defaultNameCount += 1
        } else {
            self.init(graphicType: .character, name: name)
        }
        switch type {
        case .alien:
            self.image = Image(imageLiteralResourceName: "Character3STATIC.00000@2x.png")
        case .codeMachine:
            self.image = Image(imageLiteralResourceName: "Character1STATIC.00000@2x.png")
        case .giraffe:
            self.image = Image(imageLiteralResourceName: "animal3STATIC.00000@2x.png")
        case .elephant:
            self.image = Image(imageLiteralResourceName:
                "animal1STATIC.00000@2x.png")
        case .piranha:
            self.image = Image(imageLiteralResourceName: "animal2STATIC.00000@2x.png")
        }
        self.characterType = type
        
        /*
         Manually sending a message here, as setting a property on a struct
         from within one of its own initializers won’t trigger the didSet property.
         */
        Message.setImage(id: id, image: image).send()
    }
    
    /// `jump` makes a Player do a front flip.
    ///
    /// - Parameter x: How far a Player jumps on the x-axis.
    /// - Parameter y: How far a Player jumps on the y-axis.
    ///
    /// - localizationKey: Player.jump(x:y:)
    public func jump(x: Double, y: Double) {
        let vector = CGVector(dx: CGFloat(x), dy: CGFloat(y))
        let jumpLength = 0.09
        runAnimation(.jump, timePerFrame: jumpLength, numberOfTimes: 1)
        let rotate = SKAction.rotate(byAngle: CGFloat(-360 * pi / 180), duration: 0.4)
        Message.runAction(id: id, action: rotate, key: "rotate").send()
        Message.applyImpulse(id: id, vector: vector).send()
        self.rotation = 0
    }
    
    /// `dash` makes a Player move on the x-axis at the speed you determine.
    ///
    /// - Parameter speed: How fast the Player dashes.
    ///
    /// - localizationKey: Player.dash(speed:)
    public func dash(speed: Double) {
        if speed >= 0 {
            Message.setXScale(id: id, xScale: self.scale).send()
            facingForward = true
        } else {
            Message.setXScale(id: id, xScale: -self.scale).send()
            facingForward = false
        }

        runAnimation(.walk, timePerFrame: 0.05, numberOfTimes: 1)
        Message.applyImpulse(id: id, vector: CGVector(dx: speed, dy: 0)).send()
    }
        
    /// `duck` makes a Player duck down.
    ///
    /// - Parameter duration: How long the Player ducks down.
    ///
    /// - localizationKey: Player.duck(duration:)
    public func duck(duration: Double) {
        runAnimation(.duck, timePerFrame: duration, numberOfTimes: 1)
        let scaleTo = Action.scaleX(by: 1, y: 0.5, duration: duration)
        let scaleBack = Action.scaleX(by: 1, y: 2, duration: duration)
        let sequence = Action.sequence([scaleTo,scaleBack])
        self.run(sequence)
    }
    
    // Make certain initializers unavailable
    

    
    @available(*, unavailable, message: "Players may not be initialized with the `shape:color:gradientColor:name:` initializer.") public convenience init(shape: Shape, color: Color, gradientColor: Color? = nil, name: String = "") {
        // Do nothing
        self.init(graphicType: .graphic, name: name)
    }
    
    @available(*, unavailable, message: "Players may not be initialized with the `image:name:` initializer.") public convenience init(image: Image, name: String = "") {
        // Do nothing
        self.init(graphicType: .graphic, name: name)
    }
    
    @available(*, unavailable, message: "Players may not be initialized with the `image:columns:rows:isDynamic:name:` initializer.") public convenience init(image: Image, columns: Int, rows: Int, isDynamic: Bool = false, name: String = "") {
        // Do nothing
        self.init(graphicType: .graphic, name: name)
    }
}

