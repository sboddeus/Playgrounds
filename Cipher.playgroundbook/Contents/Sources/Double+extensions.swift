//
//  Double+extensions.swift
//
//  Copyright © 2017,2018 Apple Inc. All rights reserved.
//

import Foundation

extension Double {
    
    /// Returns n! (n factorial), the result of multipying n and all the integers below it down to 1.
    /// i.e. n * (n-1) * (n-2) ... * 1
    static func factorial(n: Int) -> Double {
        if n >= 0 {
            return (n == 0) ? 1 : Double(n) * factorial(n: n - 1)
        } else {
            return 0 / 0
        }
    }
    
    /// Returns a random number between 0.0 and 1.0.
    static func randomNormalized() -> Double {
        return Double(arc4random()) / Double(UInt32.max)
    }
}
