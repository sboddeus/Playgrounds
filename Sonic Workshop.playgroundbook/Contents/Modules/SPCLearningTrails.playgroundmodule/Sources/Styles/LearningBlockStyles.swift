//
//  LearningBlockStyles.swift
//  
//  Copyright © 2016-2019 Apple Inc. All rights reserved.
//

import Foundation
import UIKit

public protocol LearningBlockStyle {
    var margins: NSDirectionalEdgeInsets { get set }
    var backgroundAlpha: CGFloat { get }
    var backgroundColor: UIColor { get }
    var cornerBadge: UIImage? { get }
}

// Default implmementation.
extension LearningBlockStyle {
    public var backgroundAlpha: CGFloat { return 1.0 }
    public var backgroundColor: UIColor { return .clear }
    public var cornerBadge: UIImage? { return nil }
}

// Default block style.
public struct DefaultLearningBlockStyle: LearningBlockStyle {
    public var margins = NSDirectionalEdgeInsets(top: 0, leading: 0, bottom: 10, trailing: 0)
}

// Style for code block.
public struct CodeLearningBlockStyle: LearningBlockStyle {
    public var margins = NSDirectionalEdgeInsets(top: 0, leading: 0, bottom: 18, trailing: 0)
    public var backgroundColor = UIColor.black.withAlphaComponent(0.05)
}

// Style for text block.
public struct TextLearningBlockStyle: LearningBlockStyle {
    public var margins = NSDirectionalEdgeInsets(top: 0, leading: 0, bottom: 18, trailing: 0)
}

// Style for group block.
public struct GroupLearningBlockStyle: LearningBlockStyle {
    public var margins = NSDirectionalEdgeInsets(top: 22, leading: 0, bottom: 22, trailing: 5)
    public var backgroundColor = UIColor.white
}

extension GroupLearningBlockStyle {
    static var groupLevelIndent: CGFloat = 12
    static var separatorColor = UIColor(red: 0xA7, green: 0xAA, blue: 0xA9).withAlphaComponent(0.5)
    static var separatorHeight: CGFloat = 0.5
    static var separatorBottomMargin: CGFloat = 18
}

// Style for response block.
public struct ResponseLearningBlockStyle: LearningBlockStyle {
    public var margins = NSDirectionalEdgeInsets(top: 0, leading: 0, bottom: 18, trailing: 0)
    static var confirmButtonBackgroundColor = #colorLiteral(red: 0.2521180511, green: 0.4725756049, blue: 0.4759181142, alpha: 1)
    static var confirmButtonDisabledBackgroundColor = #colorLiteral(red: 0.2521180511, green: 0.4725756049, blue: 0.4759181142, alpha: 1).withAlphaComponent(0.5)
    static var confirmButtonTitleColor = #colorLiteral(red: 1, green: 1, blue: 1, alpha: 1)
    static var confirmButtonTitleColorCorrect = #colorLiteral(red: 0.1294117719, green: 0.2156862766, blue: 0.06666667014, alpha: 1).withAlphaComponent(0.5)
    static var confirmButtonTitleColorWrong = #colorLiteral(red: 0.9372549057, green: 0.3490196168, blue: 0.1921568662, alpha: 1)
}

// Style for image block.
public struct ImageLearningBlockStyle: LearningBlockStyle {
    public var margins = NSDirectionalEdgeInsets(top: 0, leading: 0, bottom: 18, trailing: 0)
}

// Style for video block.
public struct VideoLearningBlockStyle: LearningBlockStyle {
    public var margins = NSDirectionalEdgeInsets(top: 10, leading: 10, bottom: 18, trailing: 10)
}
