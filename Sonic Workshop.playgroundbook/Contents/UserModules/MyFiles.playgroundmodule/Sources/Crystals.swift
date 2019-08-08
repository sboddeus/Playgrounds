//  Copyright © 2016-2019 Apple Inc. All rights reserved.

import UIKit

public let scene = Scene()

public func createCrystal(image: Image, sound: Sound) -> Graphic {
    
//#-localizable-zone(crystals01)
    // Create the graphic.
//#-end-localizable-zone
    let graphic = Graphic(image: image)
//#-localizable-zone(crystals02)
    // Add a tap handler.
//#-end-localizable-zone
    
    return graphic
}

//#-localizable-zone(crystals03)
// Write your own function.
//#-end-localizable-zone
