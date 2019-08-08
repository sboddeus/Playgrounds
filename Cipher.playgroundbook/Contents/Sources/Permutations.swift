//
//  Permutations.swift
//
//  Copyright © 2017,2018 Apple Inc. All rights reserved.
//

import Foundation

extension Collection {
    
    /// Returns an array of all the permutations of the elements in the collection.
    var permutations: [[Iterator.Element]] {
        
        var result: [[Iterator.Element]] = []

        // Start with an array of all the elements in the collection.
        var permutationsArray = Array(self)
        
        // Implement Heap’s algorithm.
        func generate(n: Int) {
            
            if n == 1 {
                result.append(permutationsArray)
                return
            }
            
            for i in 0..<(n - 1) {
                
                generate(n: n - 1)
                
                if (n % 2 == 0) {
                    // n is even => swap element i with the last.
                    permutationsArray.swapAt(i, n - 1)
                } else {
                    // n is odd => swap the first element with the last.
                    permutationsArray.swapAt(0, n - 1)
                }
            }
            
            generate(n: n - 1)
        }

        generate(n: permutationsArray.count)
        
        return result
    }
}

extension String {
    
    /// Returns an array of every permutation of the letters in the string.
    var letterPermutations: [String] {
        return self.letters.permutations.map { $0.joined() }
    }
    
    /// Returns an array of every permutation of the letters in the string, 
    /// but ignoring any of the letters in ignoreString.
    func letterPermutations(ignoringAnyLettersIn ignoreString: String) -> [String] {
        
        var results = [String]()
        
        let remainingLetters = self.letters.filter( { !ignoreString.letters.contains($0) } ).map { String($0) }.joined()
        
        for permutation in remainingLetters.letterPermutations {
            
            var result = ""
            var i = 0
            
            for letter in self.letters {
                
                if ignoreString.letters.contains(letter) {
                    result += String(letter)
                } else {
                    
                    let index = permutation.letters.index(permutation.letters.startIndex, offsetBy: i)
                    result += String(permutation.letters[index])
                    i += 1
                }
            }
            
            results.append(result)
        }

        return results
    }
}
