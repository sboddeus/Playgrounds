//
//  Size.swift
//  
//  Copyright © 2016-2019 Apple Inc. All rights reserved.
//

import Foundation
import SpriteKit

/// Size is a struct for specifying the width and height of a graphic.
///
/// - localizationKey: Size
public struct Size {
    
    /// Width is an attribute of Size.
    ///
    /// - localizationKey: Size.width
    public var width: Double
    
    /// Height is an attribute of Size.
    ///
    /// - localizationKey: Size.height
    public var height: Double
    
    /// Creates a Size with a width and a height.
    ///
    /// - Parameter width: The Size width.
    /// - Parameter height: The Size height.
    ///
    /// - localizationKey: Size(width{double}:height{double}:)
    public init(width: Double, height: Double) {
        self.width = width
        self.height = height
    }
    
    init(vector: CGVector) {
        self.width = Double(vector.dx)
        self.height = Double(vector.dy)
    }
}

extension Size {
    /// Creates a Size with a CGSize.
    ///
    /// - Parameter point: The CGSize to make a Size.
    ///
    /// - localizationKey: Size(_:)
    public init(_ size: CGSize) {
        self.width = Double(size.width)
        self.height = Double(size.height)
    }
}

extension CGSize {
    public init(_ size: Size) {
        self.init()
        self.width = CGFloat(size.width)
        self.height = CGFloat(size.height)
    }
}
