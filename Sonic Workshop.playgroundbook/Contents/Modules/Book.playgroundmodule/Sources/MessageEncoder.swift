//
//  MessageEncoder.swift
//  
//  Copyright © 2016-2019 Apple Inc. All rights reserved.
//

import Foundation
import UIKit
import PlaygroundSupport
import SpriteKit
import SPCCore


public struct MessageEncoder {
    
    private var encodedInfo =  [MessageKey : PlaygroundValue]()
    
    var playgroundValue: PlaygroundValue {
       
        var returnInfo = [String : PlaygroundValue]()
        
        for (key, value) in encodedInfo {
            returnInfo[key.rawValue] = value
        }
        return .dictionary(returnInfo)
    }
    
    var bounciness: Double? {
        didSet {
            encodedInfo[.bounciness] = bounciness?.playgroundValue
        }
    }
    
    var xScale: Double? {
        didSet {
            encodedInfo[.xScale] = xScale?.playgroundValue
        }
    }
    
    var yScale: Double? {
        didSet {
            encodedInfo[.yScale] = yScale?.playgroundValue
        }
    }
    
    var isAffectedByGravity: Bool? {
        didSet {
            encodedInfo[.gravity] = isAffectedByGravity?.playgroundValue
        }
    }
    
    var isDynamic: Bool? {
        didSet {
            encodedInfo[.isDynamic] = isDynamic?.playgroundValue
        }
    }
    
    var allowsRotation: Bool? {
        didSet {
            encodedInfo[.allowsRotation] = allowsRotation?.playgroundValue
        }
    }
    
    var allowsTouchInteraction: Bool? {
        didSet {
            encodedInfo[.allowsTouchInteraction] = allowsTouchInteraction?.playgroundValue
        }
    }
    
    var allowsBorderPhysics: Bool? {
        didSet {
            encodedInfo[.allowsBorderPhysics] = allowsBorderPhysics?.playgroundValue
        }
    }
    
    var anchor: AnchorPoint? {
        
        didSet {
            encodedInfo[.anchor] = anchor?.playgroundValue
        }
    }

    var isRegistered: Bool? {
        
        didSet {
            encodedInfo[.registered] = isRegistered?.playgroundValue
        }
    }

    var isPrintable: Bool? {
        
        didSet {
            encodedInfo[.isPrintable] = isPrintable?.playgroundValue
        }
    }
    
    var isHidden: Bool? {
       
        didSet {
            encodedInfo[.hidden] = isHidden?.playgroundValue
        }
    }
    
    var isVisible: Bool? {
        
        didSet {
            encodedInfo[.visible] = isVisible?.playgroundValue
        }
    }

    var color: UIColor? {
        
        didSet {
            encodedInfo[.color] = color?.playgroundValue
        }
    }
    
    var tone: Tone? {
        
        didSet {
            encodedInfo[.tone] = tone?.playgroundValue
        }
    }
    
    var path: String? {
       
        didSet {
            encodedInfo[.path] = path?.playgroundValue
        }
    }
    
    var point: CGPoint? {
       
        didSet {
            encodedInfo[.point] = point?.playgroundValue
        }
    }

    var position: CGPoint? {
        
        didSet {
            encodedInfo[.position] = position?.playgroundValue
        }
    }
    
    var positions: [String:CGPoint]? {
        
        didSet {
            encodedInfo[.positions] = positions?.playgroundValue
        }
    }
    
    var sizes: [String:CGSize]? {
        
        didSet {
            encodedInfo[.sizes] = sizes?.playgroundValue
        }
    }
    
    var vector: CGVector? {
        
        didSet {
            
            encodedInfo[.vector] = vector?.playgroundValue
        }
    }
    
    var velocity: CGVector? {
        didSet {
            encodedInfo[.velocity] = velocity?.playgroundValue
        }
    }

    
    var id: String? {
       
        didSet {
            encodedInfo[.id] = id?.playgroundValue
        }
    }
    
    var graphicType: GraphicType? {
        
        didSet {
            encodedInfo[.graphicType] = graphicType?.rawValue.playgroundValue
        }
    }
    
    var animation: String? {
        
        didSet {
            encodedInfo[.animation] = animation?.playgroundValue
        }
    }
    
    var animationSequence: [String]? {
        didSet {
            encodedInfo[.animationSequence] = animationSequence?.playgroundValue
        }
    }
    
    var messageType: MessageName? {
        
        didSet {
            encodedInfo[.messageType] = messageType?.playgroundValue
        }
    }
    
    var name: String? {
       
        didSet {
            encodedInfo[.name] = name?.playgroundValue
        }
    }
    
    var graphicName: String? {
        didSet {
            encodedInfo[.graphicName] = graphicName?.playgroundValue
        }
    }
    
    var rotations: Double? {
        
        didSet {
            encodedInfo[.rotations] = rotations?.playgroundValue
        }
    }
    
    var numberOfAnimations: Int? {
        didSet {
            encodedInfo[.numberOfAnimations] = numberOfAnimations?.playgroundValue
        }
        
    }
    
    var volume: Int? {
        didSet {
            encodedInfo[.volume] = volume?.playgroundValue
        }
        
    }

    var duration: Double? {
       
        didSet {
            encodedInfo[.duration] = duration?.playgroundValue
        }
    }
    
    var disabled: Bool? {
        didSet {
            encodedInfo[.disabled] = disabled?.playgroundValue
        }
    }

    var key: String? {
        
        didSet {
            encodedInfo[.key] = key?.playgroundValue
        }
    }
    
    var limit: Int? {
       
        didSet {
            encodedInfo[.limit] = limit?.playgroundValue
        }
    }

    var icon: UIImage? {
       
        didSet {
            encodedInfo[.icon] = icon?.playgroundValue
        }
    }
    
    var image: Image? {
       
        didSet {
            encodedInfo[.image] = image?.playgroundValue
        }
    }
    
    var shape: BasicShape? {
        didSet {
            encodedInfo[.shape] = shape?.playgroundValue
        }
    }
    
    var text: String? {
        didSet {
            encodedInfo[.text] = text?.playgroundValue
        }
    }
    
    var textColor: UIColor? {
        
        didSet {
            encodedInfo[.textColor] = textColor?.playgroundValue
        }
    }
    
    var fontSize: Int? {
        
        didSet {
            encodedInfo[.fontSize] = fontSize?.playgroundValue
        }
    }
    
    var fontName: String? {
        
        didSet {
            encodedInfo[.fontName] = fontName?.playgroundValue
        }
    }
    
    var array: [PlaygroundValue]? {
       
        didSet {
            if let array = array {
                encodedInfo[.array] = .array(array)
            }
            else {
                encodedInfo[.array] = nil
            }
        }
    }
    
    var dictionary: [String : PlaygroundValue]? {
       
        didSet {
            if let dictionary = dictionary {
                encodedInfo[.dictionary] = .dictionary(dictionary)
            }
            else {
                encodedInfo[.dictionary] = nil
            }
        }
    }
    
    var graphics: [Graphic]? {
        
        didSet {
            encodedInfo[.graphics] = graphics?.playgroundValue
        }
    }
    
    var assessmentStatus: PlaygroundPage.AssessmentStatus? {
      
        didSet {
            encodedInfo[.assessmentStatus] = assessmentStatus?.playgroundValue
        }
    }
    
    var action: SKAction? {
        
        didSet {
            encodedInfo[.action] = action?.playgroundValue
        }
    }
    
    var touch: Touch? {
        
        didSet {
            encodedInfo[.touch] = touch?.playgroundValue
        }
    }
    
    var collision: Collision? {
        
        didSet {
            encodedInfo[.collision] = collision?.playgroundValue
        }
    }
    
    var assessmentTrigger: AssessmentTrigger? {
        
        didSet {
            encodedInfo[.assessmentTrigger] = assessmentTrigger?.rawValue.playgroundValue
        }
    }
    
    var graphic: Graphic? {
        didSet {
            encodedInfo[.graphic] = graphic?.playgroundValue
        }
    }
    
    var overlay: Overlay? {
        didSet {
            encodedInfo[.overlay] = overlay?.playgroundValue
        }
    }
    
    var sound: Sound? {
        didSet {
            encodedInfo[.sound] = sound?.playgroundValue
        }
    }
    
    var instrument: Instrument.Kind? {
        didSet {
            encodedInfo[.instrument] = instrument?.playgroundValue
        }
    }
    
    var note: Double? {
        didSet {
            encodedInfo[.note] = note?.playgroundValue
        }
    }
    
    var columns: Int? {
        didSet {
            encodedInfo[.columns] = columns?.playgroundValue
        }
        
    }
    
    var rows: Int? {
        didSet {
            encodedInfo[.rows] = rows?.playgroundValue
        }
    }
    
    var accessibilityHints: AccessibilityHints? {
        didSet {
            encodedInfo[.accessibilityHints] = accessibilityHints?.playgroundValue
        }
    }
    
    var radius: Double? {
        didSet {
            encodedInfo[.radius] = radius?.playgroundValue
        }
    }
    
    var period: Double? {
        didSet {
            encodedInfo[.period] = period?.playgroundValue
        }
    }
    
    var count: Int? {
        didSet {
            encodedInfo[.count] = count?.playgroundValue
        }
    }
    
    var blend: Double? {
        didSet {
            encodedInfo[.blend] = blend?.playgroundValue
        }
    }
}

