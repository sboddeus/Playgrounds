//
//  SubstitutionSolverResult.swift
//
//  Copyright © 2017,2018 Apple Inc. All rights reserved.
//

import Foundation
import PlaygroundSupport

/// Structure in which the result of a keyword decryption can be kept.
///
/// - localizationKey: SubstitutionSolverResult
public struct SubstitutionSolverResult {
    public var index: Int
    public var keyword: String
    public var text: String
    public var count: Int
    
    /// Creates an instance to hold the result of a decryption.
    ///
    /// - Parameter index: The index number of the decryption result.
    /// - Parameter keyword: The keyword used in the decryption.
    /// - Parameter text: The decrypted plaintext.
    /// - Parameter count: The number of common words in the decrypted plaintext.
    ///
    /// - localizationKey: SubstitutionSolverResult(index{Int}:keyword{String}:text{String}:count{Int}:)
    public init(index: Int = 0, keyword: String, text: String, count: Int = 0) {
        self.index = index
        self.keyword = keyword
        self.text = text
        self.count = count
    }
}

private let substitutionSolverResultIndexes = "SubstitutionSolverResultIndexes"
private let substitutionSolverResultKeys = "SubstitutionSolverResultKeys"
private let substitutionSolverResultPlaintexts = "SubstitutionSolverResultPlaintexts"

public extension Array where Element == SubstitutionSolverResult {
    
    mutating func sortByIndex() {
        sort { $0.index < $1.index }
    }
    
    mutating func sortByCount() {
        sort { $0.count < $1.count }
    }
    
    func saveToKeyValueStore() {
        PlaygroundKeyValueStore.current[substitutionSolverResultIndexes] = .array(self.map { PlaygroundValue.integer($0.index) } )
        PlaygroundKeyValueStore.current[substitutionSolverResultKeys] = .array(self.map { PlaygroundValue.string($0.keyword) } )
        PlaygroundKeyValueStore.current[substitutionSolverResultPlaintexts] = .array(self.map { PlaygroundValue.string($0.text) } )
    }
    
    mutating func restoreFromKeyValueStore() -> Bool {
        
        if case let .array(indexes)? = PlaygroundKeyValueStore.current[substitutionSolverResultIndexes],
            case let .array(keys)? = PlaygroundKeyValueStore.current[substitutionSolverResultKeys],
            case let .array(plaintexts)? = PlaygroundKeyValueStore.current[substitutionSolverResultPlaintexts],
            keys.count == indexes.count,
            plaintexts.count == indexes.count
        {
            removeAll()
            
            for (i, indexPlaygroundValue) in indexes.enumerated() {
                if case let .integer(index) = indexPlaygroundValue,
                    case let .string(key) = keys[i],
                    case let .string(plaintext) = plaintexts[i]
                {
                    append(SubstitutionSolverResult(index: index, keyword: key, text: plaintext))
                }
            }
            
            sortByIndex()
            
            return true
        }
        
        return false
    }
}

