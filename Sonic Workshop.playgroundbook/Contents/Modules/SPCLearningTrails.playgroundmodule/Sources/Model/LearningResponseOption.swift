//
//  LearningResponseOption.swift
//  
//  Copyright © 2016-2019 Apple Inc. All rights reserved.
//

import Foundation

public struct LearningResponseOption {
    
    public enum OptionType: String {
        case unspecified
        case correct
        case wrong
    }
    
    public private(set) var textXML: String
    public private(set) var feedbackXML: String?
    public var type: OptionType
    
    public var isSelected = false
    
    public var isSelectedAndCorrect: Bool {
        return (type == .correct) && isSelected
    }
    
    public var isSelectedAndWrong: Bool {
        return (type == .wrong) && isSelected
    }
    
    init(textXML: String, feedbackXML: String?, type: String?) {
        self.textXML = textXML
        self.feedbackXML = feedbackXML
        self.type = .unspecified
        if let type = type, let optionType = OptionType(rawValue: type) {
            self.type = optionType
        }
    }
}
