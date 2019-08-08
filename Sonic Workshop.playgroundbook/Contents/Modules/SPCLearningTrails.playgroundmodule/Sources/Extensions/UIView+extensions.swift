//
//  UIView+extensions.swift
//  
//  Copyright © 2016-2019 Apple Inc. All rights reserved.
//

import UIKit

extension UIView {
    var ancestorViewController: UIViewController? {
        var parentResponder: UIResponder? = self
        while parentResponder != nil {
            parentResponder = parentResponder!.next
            if let viewController = parentResponder as? UIViewController {
                return viewController
            }
        }
        return nil
    }
}
