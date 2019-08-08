//#-hidden-code
//
//  Contents.swift
//
//  Copyright © 2017,2018 Apple Inc. All rights reserved.
//
//#-end-hidden-code
/*:#localized(key: "FirstProseBlock")
 What kind of code is it? Well, you found it in the Substitution Ciphers chapter, so maybe that’s what it is. But how will you [decrypt](glossary://decryption) the message if you don’t know the shift value?
 
 You open your backpack. You just remembered—your teacher gave you a list of cryptology websites. Maybe one of those will help!
 
 You head over to one of the library computers and enter the address for the first website. It takes you to a page with a few cryptographic functions for you to practice with.
 
 Before you tackle decrypting the entire [ciphertext](glossary://ciphertext), try some basic shifting to get used to how it works.
 
 **Try this:**
 
 1. Choose a word to [encrypt](glossary://encryption)—try your name!
 2. Choose a shift count.
 3. Repeat a few times with different words and shift counts until you understand how it works.
 */
//#-hidden-code
import PlaygroundSupport
import UIKit

let page = PlaygroundPage.current
page.needsIndefiniteExecution = true
let proxy = page.liveView as? PlaygroundRemoteLiveViewProxy
var finishedProcessing = false

func shift(_ word: String, by shift: Int) {
    proxy?.send(.dictionary([Constants.playgroundMessageKeyWord:PlaygroundValue.string(word),
                             Constants.playgroundMessageKeyShift:.integer(shift)]))
}
//#-code-completion(everything, hide)
//#-code-completion(currentmodule, show)
//#-code-completion(identifier, hide, page, proxy, finishedProcessing, word)
//#-end-hidden-code
let word: String = /*#-editable-code*/""/*#-end-editable-code*/
let shiftCount: Int = /*#-editable-code*/<#T##0##Int#>/*#-end-editable-code*/

shift(word, by: shiftCount)

//#-hidden-code
class FinishedProcessingListener: PlaygroundRemoteLiveViewProxyDelegate {
    func remoteLiveViewProxy(_ remoteLiveViewProxy: PlaygroundRemoteLiveViewProxy,
                             received message: PlaygroundValue) {
        if case let .string(text) = message {
            if text == Constants.playgroundMessageKeySuccess {
                finishedProcessing = true
                page.assessmentStatus = assessmentPoint(word: word, shift: shiftCount)
            }
        }
    }
    
    func remoteLiveViewProxyConnectionClosed(_ remoteLiveViewProxy: PlaygroundRemoteLiveViewProxy) { }
}

let listener = FinishedProcessingListener()
proxy?.delegate = listener
//#-end-hidden-code
