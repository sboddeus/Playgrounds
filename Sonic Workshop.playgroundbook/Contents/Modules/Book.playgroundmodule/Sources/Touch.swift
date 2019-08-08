//
//  Touch.swift
//  
//  Copyright © 2016-2019 Apple Inc. All rights reserved.
//

import UIKit

/// Touch holds information about when your finger moves across the scene.
///
/// - localizationKey: Touch
public struct Touch {
    
    /// The position of your Touch on the scene.
    ///
    /// - localizationKey: Touch.position
    public var position: Point
    
    /// The distance of your Touch from the previous graphic placed on the scene.
    ///
    /// - localizationKey: Touch.previousPlaceDistance
    public var previousPlaceDistance: Double
    
    /// A Boolean value to determine placement of the first Touch.
    ///
    /// - localizationKey: Touch.firstTouch
    public var firstTouch: Bool
    
    /// A Boolean value to determine when touches enter a new graphic.
    ///
    /// - localizationKey: Touch.firstTouchInGraphic
    public var firstTouchInGraphic: Bool = false
    
    /// A Boolean value to determine when touches leave the current graphic.
    ///
    /// - localizationKey: Touch.lastTouchInGraphic
    public var lastTouchInGraphic: Bool = false
    
    /// A Boolean value to determine whether the Touch represents a double-tap.
    ///
    /// - localizationKey: Touch.doubleTap
    public var doubleTap: Bool = false
    
    public init(position: Point, previousPlaceDistance: Double, firstTouch: Bool) {
        self.position = position
        self.previousPlaceDistance = previousPlaceDistance
        self.firstTouch = firstTouch
    }
    
    init(position: Point, previousPlaceDistance: Double, firstTouch: Bool, touchedGraphic: Graphic?, capturedGraphicID: String) {
            self.position = position
            self.previousPlaceDistance = previousPlaceDistance
            self.firstTouch = firstTouch
            self.touchedGraphic = touchedGraphic
            self.capturedGraphicID = capturedGraphicID
    }
    
    /**
    A `Graphic` in the scene at the position of the touch event.
 
    A `touchedGraphic` to compare for equality with other graphics:
     
    `if touch.touchedGraphic == otherGraphic { return }`
     
    - localizationKey: Touch.touchedGraphic
     */
    public var touchedGraphic: Graphic?
    
    public var capturedGraphicID: String = ""
    
    public static func ==(lhs: Touch, rhs: Touch) -> Bool {
        return lhs.position == rhs.position &&
                lhs.previousPlaceDistance == rhs.previousPlaceDistance
    }

}
