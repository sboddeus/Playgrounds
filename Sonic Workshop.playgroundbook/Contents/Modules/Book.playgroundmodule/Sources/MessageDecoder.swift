//
//  MessageDecoder.swift
//  
//  Copyright © 2016-2019 Apple Inc. All rights reserved.
//

import Foundation
import UIKit
import PlaygroundSupport
import SpriteKit


public struct MessageDecoder {
    
    var info: [MessageKey : PlaygroundValue]
    
    public init(from: [String : PlaygroundValue]) {
        info = [MessageKey : PlaygroundValue]()
        
        for (key, playgroundValue) in from {
            if let messageKey = MessageKey(rawValue: key) {
                info[messageKey] = playgroundValue
            }
        }
    }
    
    func value<T>(forKey key: MessageKey) -> T? {
        guard let value = info[key] else { return nil }
        return key.decoded(playgroundValue: value) as? T
    }
    
    var isRegistered: Bool? {
        return value(forKey: .registered)
    }
    
    var gravity: Bool? {
        return value(forKey: .gravity)
    }
    
    var xScale: Double? {
        return value(forKey: .xScale)
    }
    
    var yScale: Double? {
        return value(forKey: .yScale)
    }
    
    var numberOfAnimations: Int? {
        return value(forKey: .numberOfAnimations)
    }
    
    var volume: Int? {
        return value(forKey: .volume)
    }
    
    var bounciness: Double? {
        return value(forKey: .bounciness)
    }
    
    var isDynamic: Bool? {
        return value(forKey: .isDynamic)
    }
    
    var allowsRotation: Bool? {
        return value(forKey: .allowsRotation)
    }
    
    var allowsTouchInteraction: Bool? {
        return value(forKey: .allowsTouchInteraction)
    }
    
    var allowsBorderPhysics: Bool? {
        return value(forKey: .allowsBorderPhysics)
    }
    
    var isHidden: Bool? {
        return value(forKey: .hidden)
    }
    
    var isVisible: Bool? {
        return value(forKey: .visible)
    }
    
    var isPrintable: Bool? {
        return value(forKey: .isPrintable)
    }
    
    var color: UIColor? {
        return value(forKey: .color)
    }
    
    var tone: Tone? {
        return value(forKey: .tone)
    }
    
    var path: String? {
        return value(forKey: .path)
    }
    
    var point: CGPoint? {
        return value(forKey: .point)
    }
    
    var anchor: AnchorPoint? {
        return value(forKey: .anchor)
    }

    var position: CGPoint? {
        return value(forKey: .position)
    }
    
    var positions: [String:CGPoint]? {
        guard
            let playgroundDictionary: PlaygroundValue = info[.positions],
            case .dictionary(let dictionary) = playgroundDictionary else {  return nil }
        
        var returnPositions = [String:CGPoint]()
        for id in dictionary.keys {
            if case .array(let position)? = dictionary[id] {
                if case .floatingPoint(let x) = position[0], case .floatingPoint(let y) = position[1] {
                    returnPositions[id] = CGPoint(x: x, y: y)
                }
            }
        }
        return returnPositions.count > 0 ? returnPositions : [String:CGPoint]()
    }
    
    var sizes: [String:CGSize]? {
        guard
            let playgroundDictionary: PlaygroundValue = info[.sizes],
            case .dictionary(let dictionary) = playgroundDictionary else { return nil }
        
        var returnSizes = [String:CGSize]()
        for id in dictionary.keys {
            if case .array(let size)? = dictionary[id] {
                if case .floatingPoint(let width) = size[0], case .floatingPoint(let height) = size[1] {
                    returnSizes[id] = CGSize(width: width, height: height)
                }
            }
        }
        return returnSizes.count > 0 ? returnSizes : [String:CGSize]()
    }

    var vector: CGVector? {
        return value(forKey: .vector)
    }
    
    var velocity: CGVector? {
        return value(forKey: .velocity)
    }
    
    var id: String? {
        return value(forKey: .id)
    }
    
    var graphicType: String? {
        return value(forKey: .graphicType)
    }
    
    var animation: String? {
        return value(forKey: .animation)
    }
    
    var animationSequence: [String]? {
        guard
            let playgroundArray: PlaygroundValue = info[.animationSequence],
            case .array(let array) = playgroundArray else { return nil }

        var returnAnimationSequence = [String]()
        for animationValue in array {
            if case .string(let s) = animationValue {
                returnAnimationSequence.append(s)
            }
        }
        return returnAnimationSequence.count > 0 ? returnAnimationSequence : nil
    }
    
    var messageType: MessageName? {
        return value(forKey: .messageType)
    }
    
    var name: String? {
        return value(forKey: .name)
    }
    
    var graphicName: String? {
        return value(forKey: .graphicName)
    }
    
    var rotations: Double? {
        return value(forKey: .rotations)
    }

    var duration: Double? {
        return value(forKey: .duration)
    }

    var key: String? {
        return value(forKey: .key)
    }
    
    var limit: Int? {
        return value(forKey: .limit)
    }
    
    var icon: UIImage? {
        return value(forKey: .icon)
    }
    
    var image: Image? {
        return value(forKey: .image)
    }
    
    var shape: BasicShape? {
        return value(forKey: .shape)
    }
    
    var text: String? {
        return value(forKey: .text)
    }
    
    var textColor: UIColor? {
        let returnColor: UIColor? = value(forKey: .textColor) //Direct the type inferencing
        return returnColor
    }
    
    var fontSize: Int? {
        return value(forKey: .fontSize)
    }
    
    var fontName: String? {
        return value(forKey: .fontName)
    }
    
    var array: [PlaygroundValue]? {
        return value(forKey: .array)
    }
    
    var dictionary: [String : PlaygroundValue]? {
        return value(forKey: .dictionary)
    }
    
    var graphics: [Graphic]? {
        
        guard
            let playgroundArray: PlaygroundValue = info[.graphics],
            case .array(let array) = playgroundArray else { return nil }
        
        var returnGraphics = [Graphic]()
        
        for graphicValue in array {
            if let graphic: Graphic = Graphic.from(graphicValue) {
                returnGraphics.append(graphic)
            }
        }
        
        return returnGraphics.count > 0 ? returnGraphics : nil
    }
    
    var assessmentStatus: PlaygroundPage.AssessmentStatus? {
        return value(forKey: .assessmentStatus)
    }

    var action: SKAction? {
        return value(forKey: .action)
    }
    
    var touch: Touch? {
        return value(forKey: .touch)
    }
    
    var collision: Collision? {
        return value(forKey: .collision)
    }
    
    var assessmentTrigger: AssessmentTrigger? {
        return value(forKey: MessageKey.assessmentTrigger)
    }
    
    var graphic: Graphic? {
        return value(forKey: .graphic)
    }
    
    var overlay: Overlay? {
        return value(forKey: .overlay)
    }
    
    var sound: Sound? {
        return value(forKey: .sound)
    }
    
    var instrument: Instrument.Kind? {
        return value(forKey: .instrument)
    }
    
    var note: Double? {
        return value(forKey: .note)
    }
    
    var columns: Int? {
        return value(forKey: .columns)
    }

    var rows: Int? {
        return value(forKey: .rows)
    }
    
    var hints: AccessibilityHints? {
        return value(forKey: .accessibilityHints)
    }
    
    var disabled: Bool? {
        return value(forKey: .disabled)
    }
    
    var radius: Double? {
        return value(forKey: .radius)
    }
    
    var period: Double? {
        return value(forKey: .period)
    }
    
    var count: Int? {
        return value(forKey: .count)
    }
    
    var blend: Double? {
        return value(forKey: .blend)
    }
}


