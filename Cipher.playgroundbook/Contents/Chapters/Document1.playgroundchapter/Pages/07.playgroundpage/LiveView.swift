//
//  LiveView.swift
//
//  Copyright © 2017,2018 Apple Inc. All rights reserved.
//

import PlaygroundSupport
import UIKit

let page = PlaygroundPage.current
let cryptoProgramViewController: CryptoProgramViewController = CryptoProgramViewController.instantiateFromMainStoryboard()
page.liveView = cryptoProgramViewController
