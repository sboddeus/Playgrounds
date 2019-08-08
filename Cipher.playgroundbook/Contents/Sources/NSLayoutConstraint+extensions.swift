//
//  NSLayoutConstraint+extensions.swift
//
//  Copyright © 2017,2018 Apple Inc. All rights reserved.
//

import UIKit

extension NSLayoutConstraint {
    
    /// Returns a copy of the constraint with a different multiplier value.
    func copy(withMultiplier multiplier: CGFloat) -> NSLayoutConstraint {
        
        NSLayoutConstraint.deactivate([self])
        
        let newConstraint = NSLayoutConstraint(
            item: firstItem as Any,
            attribute: firstAttribute,
            relatedBy: relation,
            toItem: secondItem,
            attribute: secondAttribute,
            multiplier: multiplier,
            constant: constant)
        
        newConstraint.priority = priority
        newConstraint.shouldBeArchived = self.shouldBeArchived
        newConstraint.identifier = self.identifier
        
        NSLayoutConstraint.activate([newConstraint])
        return newConstraint
    }
}
