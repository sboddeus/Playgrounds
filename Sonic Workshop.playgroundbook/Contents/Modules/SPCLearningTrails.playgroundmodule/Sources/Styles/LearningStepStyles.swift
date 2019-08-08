//
//  LearningStepStyles.swift
//  
//  Copyright © 2016-2019 Apple Inc. All rights reserved.
//

import Foundation
import UIKit

public protocol GradientStyle {
    /// Gradient colors.
    var gradientColors: [UIColor] { get }
    /// Gradient color locations (normalized).
    var gradientColorLocations: [CGFloat] { get }
    /// Gradient start point (normalized).
    var gradientStartPoint: CGPoint { get }
    /// Gradient end point (normalized).
    var gradientEndPoint: CGPoint { get }
}

public protocol LearningStepStyle: GradientStyle {
    /// Header step type title style.
    var typeTextStyle: AttributedStringStyle { get }
}

public struct LearningStepTypeAttributedStringStyle: AttributedStringStyle {
    private var typeAttributes: [NSAttributedString.Key: Any] {
        let descriptor = UIFontDescriptor.preferredFontDescriptor(withTextStyle: .title3)
        let boldDescriptor = descriptor.withSymbolicTraits(.traitBold)!
        let sizeDescriptor = boldDescriptor.withSize(16)
        let font = UIFont(descriptor: sizeDescriptor, size: 0.0)
        return [
            .font : UIFontMetrics.default.scaledFont(for: font),
            .foregroundColor : UIColor.white
        ]
    }
    
    // MARK: Public
    
    public static var shared: AttributedStringStyle = LearningStepTypeAttributedStringStyle()
    
    public var fontSize: CGFloat = TextAttributedStringStyle.defaultSize
    
    public var tintColor: UIColor = UIColor.red

    public var attributes: [String : [NSAttributedString.Key: Any]] {
        return [
            "type" : typeAttributes
        ]
    }
}

// Default implmementation.

extension LearningStepStyle {
    public var typeTextStyle: AttributedStringStyle {
        return LearningStepTypeAttributedStringStyle.shared
    }
    public var gradientColors: [UIColor] { return [ #colorLiteral(red: 0.501960814, green: 0.501960814, blue: 0.501960814, alpha: 1), #colorLiteral(red: 0.6000000238, green: 0.6000000238, blue: 0.6000000238, alpha: 1), #colorLiteral(red: 0.8039215803, green: 0.8039215803, blue: 0.8039215803, alpha: 1) ] }
    public var gradientColorLocations: [CGFloat] { return [ 0.0, 0.5, 1.0 ] }
    public var gradientStartPoint: CGPoint { return CGPoint(x: 0.0, y: 0.0) }
    public var gradientEndPoint: CGPoint { return CGPoint(x: 1.0, y: 1.0) }
}

// Default step style.
public struct DefaultLearningStepStyle: LearningStepStyle {
    public static let headerHeight: CGFloat = 50
    public static let headerButtonSize = CGSize(width: 35, height: 35)
}

// Style for check step.
public struct CheckLearningStepStyle: LearningStepStyle {
    public var gradientColors: [UIColor] { return [ #colorLiteral(red: 0.2521180511, green: 0.4725756049, blue: 0.4759181142, alpha: 1), #colorLiteral(red: 0.2388094664, green: 0.659204483, blue: 0.664686501, alpha: 1), #colorLiteral(red: 0.4620226622, green: 0.8382837176, blue: 1, alpha: 1) ] }
    public var gradientColorLocations: [CGFloat] { return [ 0.0, 0.5, 1.0 ] }
    public var gradientStartPoint: CGPoint { return CGPoint(x: 0.1, y: -1.5) }
    public var gradientEndPoint: CGPoint { return CGPoint(x: 0.9, y: 1.5) }
}

// Style for code step.
public struct CodeLearningStepStyle: LearningStepStyle {
    public var gradientColors: [UIColor] { return [#colorLiteral(red: 0.8459790349, green: 0.2873021364, blue: 0.2579272389, alpha: 1), #colorLiteral(red: 0.8442266583, green: 0.493614614, blue: 0.6640961766, alpha: 1), #colorLiteral(red: 1, green: 0.6794118285, blue: 0.8373190165, alpha: 1) ] }
    public var gradientColorLocations: [CGFloat] { return [ 0.0, 0.65, 1.0 ] }
    public var gradientStartPoint: CGPoint { return CGPoint(x: 0.45, y: -2.5) }
    public var gradientEndPoint: CGPoint { return CGPoint(x: 0.9, y: 1.5) }
}

// Style for context step.
public struct ContextLearningStepStyle: LearningStepStyle {
    public var gradientColors: [UIColor] { return [ #colorLiteral(red: 0.843980968, green: 0.4811213613, blue: 0.2574525177, alpha: 1), #colorLiteral(red: 1, green: 0.6729367971, blue: 0.6634342074, alpha: 1), #colorLiteral(red: 1, green: 0.8298398852, blue: 0.2543682456, alpha: 1)] }
    public var gradientColorLocations: [CGFloat] { return [ 0.0, 0.65, 1.0 ] }
    public var gradientStartPoint: CGPoint { return CGPoint(x: 0.45, y: -2.5) }
    public var gradientEndPoint: CGPoint { return CGPoint(x: 0.9, y: 1.5) }
}

// Style for experiment step.
public struct ExperimentLearningStepStyle: LearningStepStyle {
    public var gradientColors: [UIColor] { return [ #colorLiteral(red: 0.8459790349, green: 0.2873021364, blue: 0.2579272389, alpha: 1), #colorLiteral(red: 0.843980968, green: 0.4811213613, blue: 0.2574525177, alpha: 1), #colorLiteral(red: 1, green: 0.6729367971, blue: 0.6634342074, alpha: 1) ] }
    public var gradientColorLocations: [CGFloat] { return [ 0.0, 0.45, 1.0 ] }
    public var gradientStartPoint: CGPoint { return CGPoint(x: 0.1, y: -1.5) }
    public var gradientEndPoint: CGPoint { return CGPoint(x: 0.9, y: 1.5) }
}

// Style for find step.
public struct FindLearningStepStyle: LearningStepStyle {
    public var gradientColors: [UIColor] { return [ #colorLiteral(red: 0.4695840478, green: 0.6612184644, blue: 0.6645051241, alpha: 1), #colorLiteral(red: 0.4620226622, green: 0.8382837176, blue: 1, alpha: 1), #colorLiteral(red: 1, green: 0.8298398852, blue: 0.2543682456, alpha: 1) ] }
    public var gradientColorLocations: [CGFloat] { return [ 0.0, 0.3, 1.0 ] }
    public var gradientStartPoint: CGPoint { return CGPoint(x: 0.1, y: -1.5) }
    public var gradientEndPoint: CGPoint { return CGPoint(x: 0.9, y: 1.5) }
}
