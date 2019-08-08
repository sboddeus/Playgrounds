//
//  CipherCrackerToolkit.swift
//
//  Copyright © 2017,2018 Apple Inc. All rights reserved.
//

import Foundation

class CipherCracker {
    
    static var mostCommonWordsDictionary: [String: Int] = {
        
        let fileName = "CommonWords"
        
        if let url = Bundle.main.url(forResource: fileName, withExtension: "txt") {
            do {
                
                let contents = try String(contentsOf: url)
                let words = contents.split(separator: "\n")
                
                var dict = [String: Int]()
                for (index, element) in words.enumerated() {
                    dict[String(element).uppercased()] = index
                }
                return dict
                
            } catch {
                fatalError("Could not load txt file '\(fileName)' in CipherCracker.")
            }
        }
        else {
            fatalError("Could not find txt file '\(fileName)' in bundle for CipherCracker.")
        }
    }()
}

public extension String {
    
    /// Returns the number of most commonly used words found in the string.
    ///
    /// - localizationKey: String.countOfCommonWords()
    public func countOfCommonWords() -> Int {
        
        var count = 0
        for word in self.words {
            if let _ = CipherCracker.mostCommonWordsDictionary[word] {
                count += 1
            }
        }
        
        return count
    }
}
