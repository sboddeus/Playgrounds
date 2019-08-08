//
//  HelperExtensions.swift
//  
//  Copyright © 2016-2019 Apple Inc. All rights reserved.
//

import Foundation
import UIKit
import SpriteKit
import GameplayKit

public typealias Action = SKAction

public extension String {

    /// Splits the string into its component characters and returns them as an array.
    ///
    /// - localizationKey: String.componentsByCharacter()
    func componentsByCharacter() -> [String] {
        /*
         Note: This cannot simply be implemented as self.characters.map { String($0) } since some emojis are sequences of characters (for example, a face with a skin tone modifer); meaning, composed character sequences.
         */
        var sequences = [String]()
        let range = self.startIndex ..< self.endIndex
        self.enumerateSubstrings(in: range, options: .byComposedCharacterSequences) {sequence,_,_,_ in
            if let sequence = sequence {
                sequences.append(sequence)
            }
        }
        return sequences
    }
    
    /// Returns a random composed character sequence as a String.
    ///
    /// - localizationKey: String.randomCharacter
    var randomCharacter: String {
        
        var randomString = ""
        let characterStrings = self.componentsByCharacter()
        
        if characterStrings.count > 0 {
            let index = Int(arc4random_uniform(UInt32(characterStrings.count)))
            randomString = characterStrings[index]
        }
        return randomString
    }
    
    /// Returns the number of characters in the string.
    ///
    /// - localizationKey: String.numberOfCharacters
    var numberOfCharacters: Int {
        return self.componentsByCharacter().count
    }
    
    /// Returns the string with any whitespace characters removed.
    ///
    /// - localizationKey: String.withoutWhitespace
    var withoutWhitespace: String {
        let separatedComponents = self.components(separatedBy: .whitespaces)
        return separatedComponents.joined()
    }
    
    /// Returns the string with the characters reversed.
    ///
    /// - localizationKey: String.reversed()
    func reversed() -> String {
        
        let reversedCharacters = self.componentsByCharacter().reversed()
        return reversedCharacters.joined()
    }
    
    /// Returns the string with the characters randomly shuffled.
    ///
    /// - localizationKey: String.shuffled()
    func shuffled() -> String {
        
        let shuffledCharacters = self.componentsByCharacter().shuffled()
        return shuffledCharacters.joined()
    }
    
    func containsSubstring(_ text: String) -> Bool{
        return self.range(of: text) != nil
    }
}

public extension Comparable {
    func clamped(to range: ClosedRange<Self>) -> Self {
        return clamped(from: range.lowerBound, to: range.upperBound)
    }
    
    func clamped(from lowerBound: Self, to upperBound: Self) -> Self {
        return max(lowerBound, min(upperBound, self))
    }
}

extension CGVector {
    public init(fromVector vector: Vector) {
        self.init()
        self.dx = CGFloat(vector.dx)
        self.dy = CGFloat(vector.dy)
    }
}


extension Point {
    
    /// Returns the distance from another point.
    ///
    /// - Parameter from: The point from which to measure distance.
    ///
    /// - localizationKey: Point.distance(from:)
    public func distance(from: Point) -> Double {
        
        let distanceVector = Point(x: from.x - self.x, y: from.y - self.y)
        return Double(sqrt(Double(distanceVector.x * distanceVector.x) + Double(distanceVector.y * distanceVector.y)))
    }
}

extension Double {
    // Rounding function used for noisy Core Motion data.
    public func roundToTwoDecimalPlaces() -> Double {
        return Darwin.round(self * 100) / 100
    }
    
    public func string(fractionDigits:Int) -> String {
        let formatter = NumberFormatter()
        formatter.minimumFractionDigits = fractionDigits
        formatter.maximumFractionDigits = fractionDigits
        return formatter.string(for: self)!
    }
}

// In this app, we are clamping the values the user can enter to a defined range to be more approachable. This extension is used to apply it consistently across the app.
extension ClampedInteger {
    init(clampedUserValueWithDefaultOf integer: Int) {
        self.init(integer, in: Constants.userValueRange)
    }
}

public extension Array {

    /// A randomly chosen index into the array.
    ///
    /// - localizationKey: Array.randomIndex
    var randomIndex: Int {
        return Int(arc4random_uniform(UInt32(self.count)))
    }
    
    /// A randomly chosen item from the array.
    ///
    /// - localizationKey: Array.randomItem
    var randomItem: Element {
        return self[self.randomIndex]
    }
    
    /// Shuffles the items of the array in place.
    ///
    /// - localizationKey: Array.shuffle()
    mutating func shuffle() {
        self = shuffled()
    }
    
    /// Returns a copy of the array with its items shuffled.
    ///
    /// - localizationKey: Array.shuffled()
    func shuffled() -> [Element] {
        return GKRandomSource.sharedRandom().arrayByShufflingObjects(in: self) as! [Element]
    }
}

struct Constants {
    static let userValueRange: ClosedRange<Int> = 0...100
    
    static var maxUserValue: Int {
        return userValueRange.upperBound
    }
}


public extension UIImage {

    func resized(to size: CGSize) -> UIImage {
        let rendererFormat = UIGraphicsImageRendererFormat()
        rendererFormat.scale = UIScreen.main.scale
        
        let scaledImageRect = CGRect(origin: .zero, size: size)
        
        let renderer = UIGraphicsImageRenderer(size: scaledImageRect.size)
        let scaledImage = renderer.image { _ in
            self.draw(in: scaledImageRect)
        }
        return scaledImage
    }
}


extension CGSize {
    
    /// Returns a size that that fits within the given size, while preserving this size’s aspect ratio.
    ///
    /// - Parameter within: The size (width and height) within which the size must fit.
    ///
    /// - localizationKey: CGSize.fit(within:)
    public func fit(within: CGSize) -> CGSize  {
        
        let ratio = width > height ?  (height / width) : (width / height)
        
        if width >= height {
            return CGSize(width: within.width, height: within.width * ratio)
        }
        else {
            return CGSize(width: within.height * ratio, height: within.height)
        }
    }
}

extension SKScene {
    var center: CGPoint { return CGPoint(x: size.width / 2, y: size.height / 2) }
}
