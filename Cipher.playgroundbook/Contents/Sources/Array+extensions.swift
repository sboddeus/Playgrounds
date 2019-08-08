//
//  Array+extensions.swift
//
//  Copyright © 2017,2018 Apple Inc. All rights reserved.
//

import Foundation
import GameplayKit

public extension Array {
    
    /// Returns a copy of the array in which its elements are shuffled.
    ///
    /// - localizationKey: Array.shuffled()
    func shuffled() -> [Element] {
        return GKRandomSource.sharedRandom().arrayByShufflingObjects(in: self) as! [Element]
    }
    
    /// Returns a copy of the array in which the elements are shifted right by `n` places.
    /// Elements shifted beyond the end of the array are wrapped back to the start.
    ///
    /// - Parameter n: The number of places to shift the elements by.
    ///
    /// - localizationKey: shiftedRight(by:)
    func shiftedRight(by n: Int) -> [Element] {
        guard n >= 0 else { return self }
        var shiftedArray = self
        for (i, element) in self.enumerated() {
            
            let index = (i + n) % self.count
            shiftedArray[index] = element
        }
        return shiftedArray
    }
}
