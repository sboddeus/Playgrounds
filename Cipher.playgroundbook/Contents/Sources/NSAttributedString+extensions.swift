//
//  NSAttributedString+extensions.swift
//
//  Copyright © 2017,2018 Apple Inc. All rights reserved.
//

import Foundation
import UIKit

extension NSMutableAttributedString {
    
    func attributedSubstring(matching substring: String) -> NSAttributedString? {
        
        if let rangeOfStringToBeReplaced = self.string.range(of: substring) {
            let nsRange = self.string.nsRange(from: rangeOfStringToBeReplaced)
            return attributedSubstring(from: nsRange)
        }
        
        return nil
    }
    
    func replaceOccurrences(of substring: String, with new: String) {
        
        while let rangeOfStringToBeReplaced = self.string.range(of: substring) {
            let nsRange = self.string.nsRange(from: rangeOfStringToBeReplaced)
            self.replaceCharacters(in: nsRange, with: new)
        }
    }
    
    func replaceOccurrences(of substring: String, with new: NSAttributedString) {
        
        while let rangeOfStringToBeReplaced = self.string.range(of: substring) {
            let nsRange = self.string.nsRange(from: rangeOfStringToBeReplaced)
            self.replaceCharacters(in: nsRange, with: new)
        }
    }
    
    public func highlightOccurences(of substring: String, with color: UIColor) {
        
        let length = self.string.count
        let searchLength = substring.count
        var range = NSRange(location: 0, length: self.length)
        
        while (range.location != NSNotFound) {
            range = (self.string as NSString).range(of: substring, options: [], range: range)
            if (range.location != NSNotFound) {
                self.addAttribute(.foregroundColor, value: color, range: NSRange(location: range.location, length: searchLength))
                range = NSRange(location: range.location + range.length, length: length - (range.location + range.length))
            }
        }
    }
}
