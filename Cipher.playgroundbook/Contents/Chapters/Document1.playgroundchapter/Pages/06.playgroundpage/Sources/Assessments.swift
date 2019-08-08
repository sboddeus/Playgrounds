//
//  Assessments.swift
//
//  Copyright © 2017,2018 Apple Inc. All rights reserved.
//
import PlaygroundSupport
import UIKit

let successString = NSLocalizedString("Mr Nefarian looks at you sharply, first surprised and then impressed. He reaches under the counter, hands you an envelope, and, with a glance over his shoulder as he walks into the back room, murmurs “Good luck . . . ”\n\n[Next Page](@next)", comment:"Solution for Who is N?")
let solutionString = NSLocalizedString("`giveThePassword(\"OPEN SESAME\")`", comment:"Solution for Who is N?.")
let openBookHint = NSLocalizedString("You need to give Mr. Nefarian the correct password. What was the last part of that other clue? Open something?", comment:"Hint for giveThePassword method in Who is N?.")
let wrongPasswordHint = NSLocalizedString("Are you sure that’s the correct password? What did it say at the end of the decrypted message again?", comment: "Wrong password hint")
let localizedPassword = NSLocalizedString("OPEN SESAME", comment:"Localized password user must enter. Represented in ciphertext as ‘OPEN SESAME’")

public func assessmentPoint(password: String) -> PlaygroundPage.AssessmentStatus {
    let checker = ContentsChecker(contents: PlaygroundPage.current.text)
    
    var hints = [String]()
    
    let normalizedPassword = localizedPassword.lowercased().components(separatedBy: CharacterSet.whitespaces).reduce("", +)
    let normalizedEnteredPassword = password.lowercased().components(separatedBy: CharacterSet.whitespaces).reduce("", +)
    if normalizedPassword != normalizedEnteredPassword {
        hints.append(wrongPasswordHint)
    }
    
    if checker.functionCallCount(forName: "giveThePassword") == 0 {
        hints.append(openBookHint)
    }
    
    if !hints.isEmpty {
        // Show hints
        return .fail(hints: hints, solution: solutionString)
    } else {
        return .pass(message: successString)
    }
}
