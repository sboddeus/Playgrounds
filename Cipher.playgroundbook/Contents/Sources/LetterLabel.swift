//
//  LetterLabel.swift
//
//  Copyright © 2017,2018 Apple Inc. All rights reserved.
//

import UIKit

class LetterLabel: UILabel {
    
    var index: Int = -1
    
    var letter: String = "" {
        didSet {
            text = letter
        }
    }
    
    var isPartOfKey: Bool = false {
        didSet {
            update()
        }
    }
    
    var isPlaintext: Bool = false {
        didSet {
            update()
        }
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        font = .letterLabelFont
        update()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func update() {
        
        layer.borderWidth = 0.0
        layer.cornerRadius = 0.0
        
        textColor = .ciphertextBrightGreen
        if isPlaintext {
            textColor = .plaintextBlueGreen
        }
        if isPartOfKey {
            textColor = .keywordOrange
        }
    }
}
