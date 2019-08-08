//
//  LiveView.swift
//  
//  Copyright © 2016-2019 Apple Inc. All rights reserved.
//

import PlaygroundSupport
import Book

let liveViewController = DynamicComposerViewController()

liveViewController.backgroundImage = #imageLiteral(resourceName: "underwaterBackground.png")

PlaygroundPage.current.liveView = liveViewController

