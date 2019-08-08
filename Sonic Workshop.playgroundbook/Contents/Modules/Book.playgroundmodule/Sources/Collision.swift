//
//  Collision.swift
//  
//  Copyright © 2016-2019 Apple Inc. All rights reserved.
//
import SpriteKit

/// A Collision holds information about when two sprites collide in the scene.
///
/// - localizationKey: Collision
public struct Collision: Equatable {
    
    /// One of the sprites in the collision.
    ///
    /// - localizationKey: Collision.spriteA
    public var spriteA: Sprite
    
    /// One of the sprites in the collision.
    ///
    /// - localizationKey: Collision.spriteB
    public var spriteB: Sprite
    
    /// The angle of a collision between two sprites.
    ///
    /// - localizationKey: Collision.angle
    public var angle: Vector
    
    /// The force of a collision between two sprites.
    ///
    /// - localizationKey: Collision.force
    public var force: Double
    
}
