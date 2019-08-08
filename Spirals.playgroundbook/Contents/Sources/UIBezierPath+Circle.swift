//
//  UIBezierPath+Circle.swift
//
//  Copyright © 2016-2018 Apple Inc. All rights reserved.
//

import UIKit

extension UIBezierPath {
    convenience init(circleWithCenter center: CGPoint, radius: CGFloat) {
        self.init(arcCenter: center,
                     radius: radius,
                 startAngle: 0,
                   endAngle: .pi * 2.0,
                  clockwise: true)
    }
}
