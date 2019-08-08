//
//  CustomTrailLayoutSettings.swift
//  
//  Copyright © 2016-2019 Apple Inc. All rights reserved.
//

import Foundation
import CoreGraphics

struct CollectionViewTrailLayoutSettings {
    var itemSize: CGSize?
    var sectionsHeaderSize: CGSize?
    
    var minimumLineSpacing: CGFloat
    var minimumInteritemSpacing: CGFloat
    
    init() {
        self.minimumLineSpacing = 0
        self.minimumInteritemSpacing = 0
    }
}
