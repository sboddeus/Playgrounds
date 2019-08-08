//
//  UIViewController+StoryboardInit.swift
//
//  Copyright © 2017,2018 Apple Inc. All rights reserved.
//

import UIKit

extension UIViewController {
    
    public static func instantiateFromStoryboard<T>(storyboardName: String) -> T {
        let bundle = Bundle(for: T.self as! AnyClass)
        let storyboard = UIStoryboard(name: storyboardName, bundle: bundle)
        let identifier = String(describing: self)
        
        return storyboard.instantiateViewController(withIdentifier: identifier) as! T
    }
    
    public static func instantiateFromMainStoryboard<T>() -> T {
        let bundle = Bundle(for: T.self as! AnyClass)
        let storyboard = UIStoryboard(name: "Cipher1", bundle: bundle)
        let identifier = String(describing: self)
        
        return storyboard.instantiateViewController(withIdentifier: identifier) as! T
    }
    
}
