//
//  Assessments.swift
//
//  Copyright © 2017,2018 Apple Inc. All rights reserved.
//
import PlaygroundSupport
import UIKit

// These are all “success” messages (instead of 1 success and several hints) so that they automatically pop up when the user
// Attempts to “investigate” them
let librarianSuccess = NSLocalizedString("Ahh . . . that librarian *does* seem suspicious! What kind of name is “Mr. Nefarian” anyway? It sounds like it came from a video game. It *must* be him! You walk to the reference desk.\n\n[Next Page](@next)", comment:"Solution for Look to N")
let novelsSuccess = NSLocalizedString("Hmm . . . nothing looks unusual here—there are just a lot of glossy covers and expensive-looking magazines. Better try somewhere else.", comment:"Novels message")
let newspapersSuccess = NSLocalizedString("You don’t find anything mysterious in the pile of newspapers on the table—just a sticky candy wrapper. Better try somewhere else.", comment:"Newspapers message")
let unknownInvestigationSelectionSuccess = NSLocalizedString("Hmm, that doesn’t seem right. Try investigating something else.", comment:"Unknown String investigation message")

public func assessmentPoint(investigationSelection: String) -> PlaygroundPage.AssessmentStatus {
    
    var successMessage = ""
    
    switch investigationSelection {
    case InvestigationType.nefarian:
        successMessage = librarianSuccess
    case InvestigationType.novels:
        successMessage = novelsSuccess
    case InvestigationType.newspapers:
        successMessage = newspapersSuccess
    default:
        successMessage = unknownInvestigationSelectionSuccess
    }
    
    return .pass(message: successMessage)
}
