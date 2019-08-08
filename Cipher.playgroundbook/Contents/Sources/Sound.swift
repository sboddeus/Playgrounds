// 
//  Sound.swift
//
//  Copyright © 2017,2018 Apple Inc. All rights reserved.
//

import Foundation

/// An enumeration of all the different sounds that can be played.
///
/// - localizationKey: Sound
public enum Sound {
    
    case dataProcessing, dogBark, dogChew, dogDoubleBark, dogGrowl, dogHappyBark, dogHappyPlayful, pageFlip
    
    var url : URL? {
        
        var fileName: String?
        
        switch self {
        case .dataProcessing:
            fileName = "Computer Data 02"
        case .dogBark:
            fileName = "Bark"
        case .dogChew:
            fileName = "Dog_Chew_v2"
        case .dogDoubleBark:
            fileName = "Dog_Double_Bark"
        case .dogGrowl:
            fileName = "Dog_Growl_v1"
        case .dogHappyBark:
            fileName = "Dog_Happy_Bark"
        case .dogHappyPlayful:
            fileName = "Dog_Happy_Playful"
        case .pageFlip:
            fileName = "Page_flip"
        }
        guard let resourceName = fileName else { return nil }
        
        return Bundle.main.url(forResource: resourceName, withExtension: "wav")
    }
}

