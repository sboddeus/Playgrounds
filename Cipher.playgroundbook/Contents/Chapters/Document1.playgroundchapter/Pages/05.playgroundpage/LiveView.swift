//
//  LiveView.swift
//
//  Copyright © 2017,2018 Apple Inc. All rights reserved.
//

import PlaygroundSupport
import UIKit

let page = PlaygroundPage.current
let storyViewController: StoryViewController = StoryViewController.instantiateFromMainStoryboard()
page.liveView = storyViewController
storyViewController.displayDecryptedMessage()
