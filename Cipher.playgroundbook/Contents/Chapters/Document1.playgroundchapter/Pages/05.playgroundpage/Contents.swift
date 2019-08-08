//#-hidden-code
//
//  Contents.swift
//
//  Copyright © 2017,2018 Apple Inc. All rights reserved.
//
//#-end-hidden-code
/*:#localized(key: "FirstProseBlock")
 The message says to look to “N”. Who or what is “N”?!
 
 You glance around the library and see all sorts of things that might be “N”: novels; notebooks; newspapers; Mr. Nefarian, the librarian; new releases; Nibbler, Ms. Chin’s seeing eye dog . . .
 
 One of these things must hold the next piece of the puzzle! Try investigating a few different areas in the library and see what you can turn up. Good luck!
 */
//#-hidden-code
import PlaygroundSupport
let page = PlaygroundPage.current
let proxy = page.liveView as? PlaygroundRemoteLiveViewProxy
let novels = InvestigationType.novels
let nefarian = InvestigationType.nefarian
let newspapers = InvestigationType.newspapers
var investigationSelection = novels

func investigate(_ type: String) {
    switch type {
    case nefarian:
        investigationSelection = nefarian
        proxy?.send(.string(Constants.playgroundMessageKeyLibrarian))
    case newspapers:
        investigationSelection = newspapers
        proxy?.send(.string(Constants.playgroundMessageKeyNewspapers))
    case novels:
        investigationSelection = novels
        proxy?.send(.string(Constants.playgroundMessageKeyNovels))
    default:
        // Will trigger the switch statement in assessments to show the “Other” assessment. Not a user-facing string.
        investigationSelection = "other"
    }
}
//#-code-completion(everything, hide)
//#-code-completion(identifier, show, novels, newspapers, nefarian)
//#-end-hidden-code
investigate(/*#-editable-code*/<#T##Choose what to investigate!##String#>/*#-end-editable-code*/)
//#-hidden-code
page.assessmentStatus = assessmentPoint(investigationSelection: investigationSelection)
//#-end-hidden-code
