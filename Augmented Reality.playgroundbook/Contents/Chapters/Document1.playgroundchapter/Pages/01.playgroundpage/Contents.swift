//#-hidden-code
//
//  Contents.swift
//
//  Copyright © 2017,2018 Apple Inc. All rights reserved.
//
//#-end-hidden-code
/*:#localized(key: "FirstProseBlock")
 Welcome, coder! A new adventure awaits you—it’s time to [augment](glossary://augment) your reality! 😯
 
 Today is an exciting day, because you’re going to bring your pals from Learn to Code into your world! But before Byte & Friends can make the leap into your dimension, you’ll have to get set up. So put on your coding cap and get ready!
 
 Before you write any code, think for a minute about the meaning of *augmented reality*. You look *through* your device and into the world, which is enhanced and augmented with digital objects.
 
 1. You look at your iPad screen.
 2. Your iPad looks at the world through its camera.
 3. The iPad uses data from its camera to get the location of surrounding objects.
 4. The iPad puts new, digital objects into the world.
 5. The iPad displays the fully formed augmented scene to you on its screen!
 
 **Try this:**
 
 Use the `enableCameraVision()` method below to see the world as your iPad’s camera sees it.
 */
//#-hidden-code
import PlaygroundSupport
import UIKit

let page = PlaygroundPage.current
page.needsIndefiniteExecution = true
let proxy = page.liveView as? PlaygroundRemoteLiveViewProxy

func enableCameraVision() {
    proxy?.send(
        PlaygroundMessageToLiveView.enableCameraVision.playgroundValue
    )
}

class Listener: PlaygroundRemoteLiveViewProxyDelegate {
    func remoteLiveViewProxy(_ remoteLiveViewProxy: PlaygroundRemoteLiveViewProxy,
                             received message: PlaygroundValue) {
        guard let liveViewMessage = PlaygroundMessageFromLiveView(playgroundValue: message) else { return }
        switch liveViewMessage {
        case .succeeded:
            page.assessmentStatus = assessmentPoint()
        default:
            break
        }
    }
    func remoteLiveViewProxyConnectionClosed(_ remoteLiveViewProxy: PlaygroundRemoteLiveViewProxy) { }
}

let listener = Listener()
proxy?.delegate = listener
//#-code-completion(everything, hide)
//#-code-completion(identifier, show, enableCameraVision())
//#-end-hidden-code
//#-editable-code

//#-end-editable-code
//#-hidden-code
let checker = ContentsChecker(contents: PlaygroundPage.current.text)
if checker.functionCallCount(forName: "enableCameraVision") == 0 {
    page.assessmentStatus = assessmentPoint()
}
//#-end-hidden-code
