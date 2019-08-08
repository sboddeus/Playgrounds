//
//  Sequence+extensions.swift
//
//  Copyright © 2017,2018 Apple Inc. All rights reserved.
//

import Foundation

public extension Sequence where Iterator.Element: Hashable {
    
    /// Returns a sequence containing only the unique elements in the sequence.
    ///
    /// - localizationKey: Sequence.unique()
    func unique() -> [Iterator.Element] {
        var found: [Iterator.Element: Bool] = [:]
        return self.filter { found.updateValue(true, forKey: $0) == nil }
    }
}
