//
//  String+extensions.swift
//
//  Copyright © 2017,2018 Apple Inc. All rights reserved.
//

import UIKit

public extension String {
    
    // MARK: Public
    
    /// Returns an array of the letters in the string.
    ///
    /// - localizationKey: String.letters
    public var letters: [String] {
        return self.map { String($0) }
    }
    
    /// Returns an array of the words in the string.
    ///
    /// - localizationKey: String.words
    public var words: [String] {
        
        let range = self.startIndex..<self.endIndex
        var words = [String]()
        self.enumerateSubstrings(in: range, options: .byWords) {w,_,_,_ in
            guard let word = w else {return}
            words.append(word)
        }
        return words
    }

    /// Returns an array of the digraphs in the string.
    ///
    /// - localizationKey: String.digraphs
    public var digraphs: [String] {
        
        var digraphs = [String]()
        for word in self.words {
            let letterCount = word.letters.count
            guard letterCount >= 2 else { continue }
            for i in 0..<(letterCount - 1) {
                digraphs.append(word.letters[i...(i + 1)].joined())
            }
        }
        return digraphs
    }
    
    /// Returns the string with its characters randomly shuffled.
    ///
    /// - localizationKey: String.shuffled()
    public func shuffled() -> String {
        let shuffledCharacters = self.map({ String($0) }).shuffled()
        return shuffledCharacters.joined()
    }
    
    /// Returns a keyed alphabet generated with the given key (word).
    ///
    /// - Parameter key: The key with which to generate the keyed alphabet.
    ///
    /// - localizationKey: String.keyed(with:)
    public func keyed(with key: String) -> String {
        return Ciphers.getKeyedAlphabet(from: self, with: key)
    }
    
    /// Returns an array of all the possible combinations of the letters in the string.
    ///
    /// - localizationKey: String.getAllCombinations()
    public func getAllCombinations() -> [String] {
        return self.letterPermutations.shuffled()
    }
    
    // MARK: Internal
        
    /// Returns the string removing all characters in characterSet.
    func removingCharacters(in characterSet: CharacterSet) -> String {
        return components(separatedBy: characterSet).joined()
    }
    
    /// Returns the string with each character separated by a delimiter so that VoiceOver will speak the string letter by letter.
    func letterByLetterForVoiceOver() -> String {
        let delimiter = " "
        return self.map({ String($0) }).joined(separator: delimiter)
    }
    
    /// Returns the string left padded to toLength characters with withPad.
    func leftPadding(toLength: Int, withPad: Character = " ") -> String {
        
        guard toLength > self.count else { return self }
        
        let padding = String(repeating: String(withPad), count: toLength - self.count)
        return padding + self
    }
    
    /// Returns the string as an array of two-character digrams.
    func digrams() -> [[String]] {
        
        let chunkSize = 2
        return stride(from: 0, to: self.letters.count, by: chunkSize).map({ (startIndex) -> [String] in
            let endIndex = (startIndex.advanced(by: chunkSize) > self.letters.count) ? self.letters.count-startIndex : chunkSize
            return Array(self.letters[startIndex..<startIndex.advanced(by: endIndex)])
        })
    }
    
    /// Returns the string with any duplicate letters removed. e.g. APPLE -> APLE
    func removingDuplicateLetters() -> String {
        return self.letters.unique().joined()
    }
    
    /// Returns the string with diacritics removed. e.g. Mÿ nâMe -> My naMe
    func removingDiacritics() -> String {
        return self.folding(options: .diacriticInsensitive, locale: .current)
    }
    
    /// Given a Range within the string, returns an equivalent NSRange.
    func nsRange(from range: Range<String.Index>) -> NSRange {
        guard let from = range.lowerBound.samePosition(in: utf16), let to = range.upperBound.samePosition(in: utf16) else {
            fatalError("Unable to get indices for range")
        }

        return NSRange(location: utf16.distance(from: utf16.startIndex, to: from),
                       length: utf16.distance(from: from, to: to))
    }
    
    /// Given an NSRange within the string, returns an equivalent Range.
    func range(from nsRange: NSRange) -> Range<String.Index>? {
        guard
            let from16 = utf16.index(utf16.startIndex, offsetBy: nsRange.location, limitedBy: utf16.endIndex),
            let to16 = utf16.index(from16, offsetBy: nsRange.length, limitedBy: utf16.endIndex),
            let from = String.Index(from16, within: self),
            let to = String.Index(to16, within: self)
            else { return nil }
        return from ..< to
    }
    
    /// Returns the string with each letter from currentAlphabet substituted with the corresponding letter at the same position in alphabet. Any letters not found in currentAlphabet are passed through unchanged.
    func monoalphabeticallySubstituting(alphabet: [String], for currentAlphabet: [String]) -> String {
        
        var encryptedText = ""
        for letter in self.letters {
            
            var encodedLetter = letter
            
            if let index = currentAlphabet.index(of: letter), index < alphabet.count {
                encodedLetter = alphabet[index]
            }
            
            encryptedText += encodedLetter
        }
        
        return encryptedText
    }
}

