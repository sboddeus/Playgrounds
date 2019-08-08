//
//  LiveView.swift
//
//  Copyright © 2016-2018 Apple Inc. All rights reserved.
//

import PlaygroundSupport

let page = PlaygroundPage.current

page.liveView = SpiralViewController(initialRoulette: Roulette.hypocycloid())
