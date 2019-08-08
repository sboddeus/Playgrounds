//
//  LiveView.swift
//
//  Copyright © 2017,2018 Apple Inc. All rights reserved.
//

import PlaygroundSupport
import UIKit

let page = PlaygroundPage.current
let bookViewController: BookViewController = BookViewController.instantiateFromMainStoryboard()
page.liveView = bookViewController
    
