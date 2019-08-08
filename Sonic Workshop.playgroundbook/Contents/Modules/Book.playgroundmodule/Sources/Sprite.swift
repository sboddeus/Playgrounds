//
//  Sprite.swift
//  
//  Copyright © 2016-2019 Apple Inc. All rights reserved.
//

import Foundation
import SpriteKit

/// A Sprite is a type of graphic object, made from an image or string, that can be placed onscreen.
///
/// - localizationKey: Sprite
public class Sprite: Graphic {
    
    fileprivate static var defaultNameCount: Int = 1
    
    /// Indicates whether gravity affects the phyics body.
    ///
    /// - localizationKey: Sprite.isAffectedByGravity
    public var isAffectedByGravity: Bool = false {
        didSet {
            guard !suppressMessageSending else { return }
            Message.setAffectedByGravity(id: id, gravity: isAffectedByGravity).send()
        }
    }
    
    /// A Boolean value used to indicate if the Sprite should move in response to the physics simulation. The default is `true`: the sprite moves.
    ///
    /// - localizationKey: Sprite.isDynamic
    public var isDynamic: Bool = true {
        didSet {
            guard !suppressMessageSending else { return }
            Message.setIsDynamic(id: id, isDynamic: isDynamic).send()
        }
    }
    
    /// Indicates whether angular forces and impulses affect the physics body.
    ///
    /// - localizationKey: Sprite.allowsRotation
    public var allowsRotation: Bool = false {
        didSet {
            guard !suppressMessageSending else { return }
            Message.setAllowsRotation(id: id, allowsRotation: allowsRotation).send()
        }
    }
    
    /// Determines how much energy the sprite loses when it bounces off another object.
    ///
    /// - localizationKey: Sprite.bounciness
    public var bounciness: Double = 0.2 {
        didSet {
            guard !suppressMessageSending else { return }
            Message.setBounciness(id: id, bounciness: bounciness).send()
        }
    }
    
    /// The physics body’s velocity vector, measured in meters per second.
    ///
    /// - Parameter x: Sets the velocities *x* direction.
    /// - Parameter y: Sets the velocities *y* direction.
    ///
    /// - localizationKey: Sprite.setVelocity(x:y:)
    public func setVelocity(x: Double, y: Double) {
        guard !suppressMessageSending else { return }
        let velocity = CGVector(dx: x, dy: y)
        Message.setVelocity(id: id, velocity: velocity).send()
    }
    
    /// Applies an impulse to a Sprite.
    ///
    /// - Parameter x: Applies an impulse in the *x* direction.
    /// - Parameter y: Applies an impulse in the *y* direction.
    ///
    /// - localizationKey: Sprite.applyImpulse(x:y:)
    public func applyImpulse(x: Double, y: Double) {
        let vector = CGVector(dx: CGFloat(x), dy: CGFloat(y))
        Message.applyImpulse(id: id, vector: vector).send()
    }
    
    /// Applies a constant force to a Sprite over a duration of seconds.
    ///
    /// - Parameter x: Applies force in the *x* direction.
    /// - Parameter y: Applies force in the *y* direction.
    /// - Parameter duration: How long the force is applied, in seconds.
    ///
    /// - localizationKey: Sprite.applyForce(x:y:duration:)
    public func applyForce(x: Double, y: Double, duration: Double) {
        let vector = CGVector(dx: CGFloat(x), dy: CGFloat(y))
        Message.applyForce(id: id, vector: vector, duration: duration).send()
    }
    
    /// Creates a Sprite with a specified image and name.
    /// Example usage:
    /// ```
    /// let cupcake = Sprite(image: #imageLiteral(resourceName: \"gem2.png\"), name: \"cupcake\")
    /// ```
    ///
    /// - Parameter image: Image
    /// - Parameter name: String
    ///
    /// - localizationKey: Sprite(image:name:)
    public convenience init(image: Image, name: String = "") {
        if name == "" {
            self.init(graphicType: .sprite, name: "sprite" + String(Sprite.defaultNameCount))
            Sprite.defaultNameCount += 1
        } else {
            self.init(graphicType: .sprite, name: name)
        }
        self.image = image
        /*
         Manually sending a message here, as setting a property on a struct
         from within one of its own initializers won’t trigger the didSet property.
         */
        Message.setImage(id: id, image: image).send()
    }
    
    /// Creates a Sprite with a specified shape, color, gradient, and name.
    /// Example usage:
    /// ````
    /// let pentagon = Sprite(shape: .polygon(radius: 50, sides: 5), color: .red, gradientColor: .yellow, name: \"pentagon\")
    /// ````
    /// - Parameter shape: The shape of the Sprite.
    /// - Parameter color: The fill color.
    /// - Parameter gradientColor: A secondary gradient color.
    /// - Parameter name: An optional name you can give the Sprite; you may also leave this blank.
    ///
    /// - localizationKey: Sprite(shape:color:gradientColor:name:)
    public convenience init(shape: Shape, color: Color, gradientColor: Color? = nil, name: String = "") {
        if name == "" {
            self.init(graphicType: .sprite, name: "sprite" + String(Sprite.defaultNameCount))
            Sprite.defaultNameCount += 1
        } else {
            self.init(graphicType: .sprite, name: name)
        }
        updateShape(shape: shape, color: color, gradientColor: gradientColor ?? color)
    }
    
    /// Creates a tiled Sprite with a specified image, name, and number of columns and rows.
    /// Example usage:
    /// ````
    /// let wall = Sprite(image: #imageLiteral(resourceName: \"wall1.png\"), name: \"wall\", columns: \"12\", rows: \"1\")
    /// ````
    /// - Parameter image: An image you choose for the Sprite.
    /// - Parameter name: A name you give to the Sprite.
    /// - Parameter columns: How many columns of sprites you want.
    /// - Parameter rows: How many rows of sprites you want.
    /// - Parameter isDynamic: An optional Boolean value that indicates if the Sprite should move in response to the physics simulation. The default is `false` (the sprite won’t move).
    ///
    /// - localizationKey: Sprite(image:name:columns:rows:isDynamic:)
    public convenience init(image: Image, columns: Int, rows: Int, isDynamic: Bool = false, name: String = "") {
        if name == "" {
            self.init(graphicType: .sprite, name: "surface" + String(Sprite.defaultNameCount))
            Sprite.defaultNameCount += 1
        } else {
            self.init(graphicType: .sprite, name: name)
        }

        suppressMessageSending = true
        self.image = image
        suppressMessageSending = false

        Message.setTiledImage(id: id, image: image, columns: columns, rows: rows, isDynamic: isDynamic).send()
    }
    
    static func ==(lhs: Sprite, rhs: Sprite) -> Bool {
        return lhs.id == rhs.id
    }

}
