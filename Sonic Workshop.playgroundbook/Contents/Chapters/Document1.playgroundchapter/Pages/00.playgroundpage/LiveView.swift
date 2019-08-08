//
//  LiveView.swift
//  
//  Copyright © 2016-2019 Apple Inc. All rights reserved.
//

import PlaygroundSupport
import Book
import UIKit

let liveViewController = DynamicComposerViewController()

liveViewController.backgroundImage = #imageLiteral(resourceName: "caveBackground.png")

PlaygroundPage.current.liveView = liveViewController

