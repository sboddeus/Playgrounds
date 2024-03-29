//
//  UIColor+extensions.swift
//  
//  Copyright © 2016-2019 Apple Inc. All rights reserved.
//

import UIKit

private enum HueMax {
    static let red: CGFloat          = 0.028
    static let redOrange: CGFloat    = 0.056
    static let orange: CGFloat       = 0.111
    static let orangeYellow: CGFloat = 0.129
    static let yellow: CGFloat       = 0.167
    static let yellowGreen: CGFloat  = 0.222
    static let green: CGFloat        = 0.389
    static let greenCyan: CGFloat    = 0.469
    static let cyan: CGFloat         = 0.540
    static let cyanBlue: CGFloat     = 0.611
    static let blue: CGFloat         = 0.667
    static let blueMagenta: CGFloat  = 0.800
    static let magenta: CGFloat      = 0.889
    static let magentaPink: CGFloat  = 0.917
    static let pink: CGFloat         = 0.958
    static let pinkRed: CGFloat      = 0.986
    
    static var orderedValues: [(CGFloat, String)] {
        return [
            (HueMax.red,          NSLocalizedString("red", comment: "AX Label: color")),
            (HueMax.redOrange,    NSLocalizedString("red orange", comment: "AX Label: color")),
            (HueMax.orange,       NSLocalizedString("orange", comment: "AX Label: color")),
            (HueMax.orangeYellow, NSLocalizedString("yellow orange", comment: "AX Label: color")),
            (HueMax.yellow,       NSLocalizedString("yellow", comment: "AX Label: color")),
            (HueMax.yellowGreen,  NSLocalizedString("yellow green", comment: "AX Label: color")),
            (HueMax.green,        NSLocalizedString("green", comment: "AX Label: color")),
            (HueMax.greenCyan,    NSLocalizedString("blue green", comment: "AX Label: color")),
            (HueMax.cyan,         NSLocalizedString("cyan", comment: "AX Label: color")),
            (HueMax.cyanBlue,     NSLocalizedString("cyan blue", comment: "AX Label: color")),
            (HueMax.blue,         NSLocalizedString("blue", comment: "AX Label: color")),
            (HueMax.blueMagenta,  NSLocalizedString("purple", comment: "AX Label: color")),
            (HueMax.magenta,      NSLocalizedString("magenta", comment: "AX Label: color")),
            (HueMax.magentaPink,  NSLocalizedString("magenta pink", comment: "AX Label: color")),
            (HueMax.pink,         NSLocalizedString("pink", comment: "AX Label: color")),
            (HueMax.pinkRed,      NSLocalizedString("pink red", comment: "AX Label: color")),
        ]
    }
}

public extension UIColor {
    /// Red is one of the color components you can access from the camera data. You can also access the data for green and blue. The color information is a double between 0 and 1.
    ///
    /// - localizationKey: redComponent
    var redComponent: Double {
        var cgRed: CGFloat = 0.0
        
        _ = self.getRed(&cgRed, green: nil, blue: nil, alpha: nil)
        
        return Double(cgRed)
    }
    /// Green is one of the color components you can access from the camera data. You can also access the data for red and blue. The color information is a double between 0 and 1.
    ///
    /// - localizationKey: greenComponent
    var greenComponent: Double {
        var cgGreen: CGFloat = 0.0
        
        _ = self.getRed(nil, green: &cgGreen, blue: nil, alpha: nil)
        
        return Double(cgGreen)
    }
    
    /// Blue is one of the color components you can access from the camera data. You can also access the data for red and green. The color information is a double between 0 and 1.
    ///
    /// - localizationKey: blueComponent
    var blueComponent: Double {
        var cgBlue: CGFloat = 0.0
        
        _ = self.getRed(nil, green: nil, blue: &cgBlue, alpha: nil)
        
        return Double(cgBlue)
    }
    
    /// Hue is one of the values you can access from the camera data. You can also access the data for saturation, brightness, and alpha. The hue data is a double between 0 and 1.
    ///
    /// - localizationKey: hue
    var hue: Double {
        var cgHue: CGFloat = 0.0
        
        _ = self.getHue(&cgHue, saturation: nil, brightness: nil, alpha: nil)
        
        return Double(cgHue)
    }
    
    /// Saturation is one of the values you can access from the camera data. You can also access the data for hue, brightness, and alpha. The saturation data is a double between 0 and 1.
    ///
    /// - localizationKey: saturation
    var saturation: Double {
        var cgSaturation: CGFloat = 0.0
        
        _ = self.getHue(nil, saturation: &cgSaturation, brightness: nil, alpha: nil)
        
        return Double(cgSaturation)
    }
    
    /// Brightness is one of the values you can access from the camera data. You can also access the data for hue, saturation, and alpha. The brightness data is a double between 0 and 1.
    ///
    /// - localizationKey: brightness
    var brightness: Double {
        var cgBrightness: CGFloat = 0.0
        
        _ = self.getHue(nil, saturation: nil, brightness: &cgBrightness, alpha: nil)
        
        return Double(cgBrightness)
    }
    
    /// Alpha is one of the values you can access from the camera data. You can also access the data for hue, saturation, and brightness. The alpha data is a double between 0 and 1.
    ///
    /// - localizationKey: alpha
    var alpha: Double {
        var cgAlpha: CGFloat = 0.0
        
        _ = self.getHue(nil, saturation: nil, brightness: nil, alpha: &cgAlpha)
        
        return Double(cgAlpha)
    }
    
    @nonobjc convenience init(hue: Double, saturation: Double, brightness: Double, alpha: Double) {
        self.init(hue: CGFloat(hue), saturation: CGFloat(saturation), brightness: CGFloat(brightness), alpha: CGFloat(alpha))
    }
    
    @nonobjc convenience init(red: Double, green: Double, blue: Double, alpha: Double) {
        self.init(red: CGFloat(red), green: CGFloat(green), blue: CGFloat(blue), alpha: CGFloat(alpha))
    }
    
    var rgbaComponents: (red: CGFloat, green: CGFloat, blue: CGFloat, alpha: CGFloat) {
        var red: CGFloat = 0
        var green: CGFloat = 0
        var blue: CGFloat = 0
        var alpha: CGFloat = 0
        getRed(&red, green: &green, blue: &blue, alpha: &alpha)
        return (red, green, blue, alpha)
    }
    
    var hueComonents: (hue: CGFloat, saturation: CGFloat, brightness: CGFloat, alpha: CGFloat)? {
        let (r, g, b, a) = rgbaComponents
        let correctColor = UIColor(red: r, green: g, blue: b, alpha: a)
        
        var hue: CGFloat = 0
        var saturation: CGFloat = 0
        var brightness: CGFloat = 0
        var alpha: CGFloat = 0
        let converted = correctColor.getHue(&hue, saturation: &saturation, brightness: &brightness, alpha: &alpha)
        
        if converted {
            return (hue, saturation, brightness, alpha)
        }
        return nil
    }
    
    var luma: CGFloat {
        let (red, green, blue, alpha) = rgbaComponents
        
        // The coefficients here are the luma coefficients from Rec. 709
        let r = 0.2126 * red
        let g = 0.7152 * green
        let b = 0.0722 * blue
        
        let total = (r + g + b) * alpha
        
        return min(1, max(0, total))
    }
    
    var accessibleDescription: String {
        guard let (hue, saturation, _, _) = hueComonents else { return "" }
        
        // First we need to handle all the colors that aren't well-defined by their hue as special cases (e.g. white, black, grays, brown)
        
        // White
        if luma > 0.99 {
            return NSLocalizedString("white", comment: "AX Label: color")
        }
        
        // Black
        if luma < 0.01 {
            return NSLocalizedString("black", comment: "AX Label: color")
        }
        
        // Grays
        let lightnessDesc = lightnessDescription(luma)
        if saturation < 0.05 {
            return String(format: NSLocalizedString("%@ gray", comment: "AX Label: color"), lightnessDesc)
        }
        
        // Brown
        let saturationDesc = saturationDescription(saturation, luma: luma)
        if HueMax.redOrange < hue && hue < HueMax.orange && luma < 0.43 {
            return String(format: NSLocalizedString("%@ %@ brown", comment: "AX Label: color"), lightnessDesc, saturationDesc)
        }
        
        // Otherwise use the hue value to describe the color.
        let hueDesc = hueDescription(hue)
        return String(format: NSLocalizedString("%@ %@ %@", comment: "AX Label: lightness, saturation, hue"), lightnessDesc, saturationDesc, hueDesc)
    }
    
    func lightnessDescription(_ lightness: CGFloat) -> String {
        if lightness < 0.35 {
            return NSLocalizedString("dark", comment: "AX Label: lightness")
        }
        else if lightness > 0.85 {
            return NSLocalizedString("light", comment: "AX Label: lightness")
        }
        return ""
    }
    
    func saturationDescription(_ saturation: CGFloat, luma: CGFloat) -> String {
        if saturation < 0.2 {
            return NSLocalizedString("grayish", comment: "AX Label: saturation")
        }
        else if saturation > 0.9 && luma > 0.7 {
            return NSLocalizedString("vibrant", comment: "AX Label: saturation")
        }
        return ""
    }
    
    func hueDescription(_ hue: CGFloat) -> String {
        guard hue >= 0.0 && hue <= 1.0 else { fatalError("Hue value should be in range [0..1f], got \(hue)") }
        
        for (maxHueValue, colorName) in HueMax.orderedValues {
            if hue < maxHueValue {
                return colorName
            }
        }
        
        return HueMax.orderedValues.last!.1
    }
    
}

extension UIColor {
    override open var accessibilityLabel: String? {
        get {
            return accessibleDescription
        }
        set {}
    }
}
