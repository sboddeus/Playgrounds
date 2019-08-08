//
//  Vector.swift
//  
//  Copyright © 2016-2019 Apple Inc. All rights reserved.
//

import Foundation

/// A structure that contains a two-dimensional vector.
///
/// - localizationKey: Vector
public struct Vector: Equatable {
    public var dx: Double
    
    public var dy: Double
    
    /// Creates a vector with a `dx` and `dy`.
    ///
    /// - Parameter dx: Dimentional *x* value.
    /// - Parameter dy: Dimentional *y* value.
    ///
    /// - localizationKey: Vector(dx:dy:)
    public init(dx: Double, dy: Double) {
        self.dx = dx
        self.dy = dy
    }
}
