//
//  GlowingView.swift
//
//  Copyright © 2018 Apple Inc. All rights reserved.
//

import UIKit

@objc(GlowingView)
class GlowingView: UIView {
    
    private let maskLayer = CAGradientLayer()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        initialize()
    }
    
    required public init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        initialize()
    }
    
    private func initialize() {
        backgroundColor = UIColor.orange
        
        layer.cornerRadius = 10
        layer.shadowColor = UIColor.orange.cgColor
        layer.shadowOffset = CGSize.zero
        layer.shadowRadius = 10
        layer.shadowOpacity = 1.0
        layer.borderColor = UIColor.orange.cgColor
        layer.borderWidth = 4
        
        maskLayer.frame = bounds
        maskLayer.shadowRadius = 5
        maskLayer.shadowOpacity = 1
        maskLayer.shadowOffset = CGSize.zero
        maskLayer.shadowColor = UIColor.yellow.cgColor
        
        layer.mask = maskLayer
        setNeedsLayout()
    }

    func start() {
        alpha = 0
        
        let animation = CABasicAnimation(keyPath: "opacity")
        animation.fromValue = 0.05
        animation.toValue = 0.5
        animation.repeatCount = .infinity
        animation.duration = 0.75
        animation.autoreverses = true
        animation.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
        layer.add(animation, forKey: "glowing")
    }
    
    func stop() {
        layer.removeAllAnimations()
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        maskLayer.shadowPath = CGPath(roundedRect: bounds.insetBy(dx: 5, dy: 5), cornerWidth: 10, cornerHeight: 10, transform: nil)
    }
}
