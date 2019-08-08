//#-hidden-code
//
//  Contents.swift
//
//  Copyright © 2017,2018 Apple Inc. All rights reserved.
//
//#-end-hidden-code
/*:#localized(key: "FirstProseBlock")
 Approaching the reference desk, you clear your throat, and Mr. Nefarian eyes you suspiciously.
 
 “Yes? Can I help you?”
 
 “Please, do you have the answer?” you ask.
 
 Mr. Nefarian looks at you blankly. “The answer to what?” he replies.
 
 You’re not sure what to do now—he *must* be “N,” but he doesn’t seem to know anything!
 
 Maybe you’re forgetting something from the message…
 */
//#-hidden-code
import PlaygroundSupport
import UIKit

let page = PlaygroundPage.current
let proxy = page.liveView as? PlaygroundRemoteLiveViewProxy
let localizedPassword = NSLocalizedString("OPEN SESAME", comment:"Localized password user must enter. Represented in ciphertext as ‘OPEN SESAME’")

func giveThePassword(password: String) {
    let normalizedPassword = localizedPassword.lowercased().components(separatedBy: CharacterSet.whitespaces).reduce("", +)
    let normalizedEnteredPassword = password.lowercased().components(separatedBy: CharacterSet.whitespaces).reduce("", +)
    if normalizedPassword == normalizedEnteredPassword {
         proxy?.send(.string(Constants.playgroundMessageKeyCorrectPassword))
    }
}
//#-code-completion(everything, hide)
//#-end-hidden-code
// Give the password
let password: String = /*#-editable-code*/""/*#-end-editable-code*/
giveThePassword(password: password)
//#-hidden-code
page.assessmentStatus = assessmentPoint(password: password)
//#-end-hidden-code
