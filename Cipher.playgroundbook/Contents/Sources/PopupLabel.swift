//
//  PopupLabel.swift
//
//  Copyright © 2017,2018 Apple Inc. All rights reserved.
//

import UIKit

@objc(PopupLabel)
public class PopupLabel: UILabel {
        
    var insets = UIEdgeInsets(top: 15, left: 15, bottom: 15, right: 15)
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        initialize()
    }
    
    required public init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        initialize()
    }
    
    private func initialize() {
        layer.cornerRadius = 8.0
        layer.borderColor = UIColor.darkGray.cgColor
        layer.borderWidth = 2.0
        layer.masksToBounds = true
    }
    
    override public func drawText(in rect: CGRect) {
        super.drawText(in: rect.inset(by: insets))
    }
    
    override public var intrinsicContentSize: CGSize {
        get {
            var contentSize = super.intrinsicContentSize
            contentSize.height += insets.top + insets.bottom
            contentSize.width += insets.left + insets.right
            return contentSize
        }
    }
}
