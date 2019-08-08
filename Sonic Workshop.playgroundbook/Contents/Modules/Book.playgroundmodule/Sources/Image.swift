//
//  Image.swift
//  
//  Copyright © 2016-2019 Apple Inc. All rights reserved.
//

import Foundation
import UIKit

internal let ImageUIImageResourceName: String = "UIImage"

/// Represents an image that can be displayed in the scene.
///
/// - localizationKey: Image
public class Image: _ExpressibleByImageLiteral, Equatable, Hashable {
    
    let path: String
    let description: String
    
    public required init(imageLiteralResourceName path: String) {
        self.path = path
        self.description = Image.parseDescription(from: path)
    }    
    
    /// Initialize an Image from a UIImage
    ///
    /// - Parameter with: the UIImage to use
    ///
    /// - localizationKey: Image(with:)
    public convenience init(with image: UIImage) {
        self.init(imageLiteralResourceName: ImageUIImageResourceName)
        _uiimage = image
    }
    
    public static func ==(lhs: Image, rhs: Image) -> Bool {
        if let leftImg = lhs._uiimage, let rightImg = rhs._uiimage {
            return leftImg.isEqual(rightImg)
        }
        else {
            return lhs.path == rhs.path
        }
    }
    
    private var _uiimage: UIImage?
    /// Returns an instance of UIImage.
    ///
    /// - localizationKey: Image.uiImage
    lazy public var uiImage: UIImage = {
        if let img = _uiimage {
            return img
        }
        else {
            return UIImage(imageLiteralResourceName: path)
        }
    }()
    
    /// Size of the image in points.
    ///
    /// - localizationKey: Image.size
    lazy public var size: CGSize = { [unowned self] in
        if let img = _uiimage {
            return img.size
        }
        else {
            let image = UIImage(imageLiteralResourceName: path)
            return image.size
        }
    }()
    
    public func hash(into hasher: inout Hasher) {
        if let img = _uiimage {
            hasher.combine(img)
        }
        else {
            hasher.combine(path)
        }
    }
    
    /// An empty image has no reference to any image data.
    ///
    /// - localizationKey: Image.isEmpty
    public var isEmpty: Bool {
        return path.count == 0 && _uiimage == nil
    }

    static private func parseDescription(from path: String) -> String {
        var name = URL(fileURLWithPath: path).deletingPathExtension().lastPathComponent
        if let atCharRange = name.range(of: "@") {
            name = String(name[..<atCharRange.lowerBound])
        }

        return name
    }
}

// MARK: Background image overlays

public enum Overlay : Int {
    case gridWithCoordinates
    case cosmicBus
    
    func image() -> Image {
        switch self {
        case .gridWithCoordinates:
            return Image(imageLiteralResourceName: "GridCoordinates")
        case .cosmicBus:
            return Image(imageLiteralResourceName: "CosmicBus")
        }
    }
}
