//
//  Point.swift
//  
//  Copyright © 2016-2019 Apple Inc. All rights reserved.
//

import CoreGraphics

/// Specifies a Point in the scene on the *x* and *y* axis.
///
/// - localizationKey: Point
public struct Point {
    
    /// The Point’s *x* coordinate.
    ///
    /// - localizationKey: Point.x
    public var x: Double
    
    /// The Point’s *y* coordinate.
    ///
    /// - localizationKey: Point.y
    public var y: Double
    
    /// Creates a Point with an *x* and *y* coordinate.
    ///
    /// - Parameter x: The position of the point along the x-axis.
    /// - Parameter y: The position of the point along the y-axis.
    ///
    /// - localizationKey: Point(x{Double}:y{Double}:)
    public init(x: Double, y: Double) {
        self.x = x
        self.y = y
    }
}

extension Point {
    /// Creates a Point with *x* and *y* coordinates.
    ///
    /// - Parameter x: The position of the point along the x-axis.
    /// - Parameter y: The position of the point along the y-axis.
    ///
    /// - localizationKey: Point(x{Int}:y{Int}:)
    public init(x: Int, y: Int) {
        self.x = Double(x)
        self.y = Double(y)
    }

    public init(_ point: CGPoint) {
        self.x = Double(point.x)
        self.y = Double(point.y)
    }
}

extension Point: Hashable, Equatable {
    
    public func hash(into hasher: inout Hasher) {
        hasher.combine(self.x)
        hasher.combine(self.y)
    }
    
    public static func ==(lhs: Point, rhs: Point) -> Bool {
        return lhs.x == rhs.x && lhs.y == rhs.y
    }
}


extension CGPoint {
    public init(_ point: Point) {
        self.init()
        self.x = CGFloat(point.x)
        self.y = CGFloat(point.y)
    }
}
