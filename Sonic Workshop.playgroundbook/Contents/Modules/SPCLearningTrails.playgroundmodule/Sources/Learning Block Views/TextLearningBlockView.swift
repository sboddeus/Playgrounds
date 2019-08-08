//
//  TextLearningBlockView.swift
//  
//  Copyright © 2016-2019 Apple Inc. All rights reserved.
//

import UIKit

public class TextLearningBlockView: UITextView {
    public var learningBlock: LearningBlock?
    public var style: LearningBlockStyle?
    public var textStyle: AttributedStringStyle?
    
    public var blockViewDelegate: LearningBlockViewDelegate?
        
    override init(frame: CGRect, textContainer: NSTextContainer?) {
        super.init(frame: frame, textContainer: textContainer)
        backgroundColor = UIColor.white
        directionalLayoutMargins = NSDirectionalEdgeInsets(top: 0, leading: 0, bottom: 0, trailing: 0)
        
        isEditable = false
        isSelectable = true
        isScrollEnabled = false
        dataDetectorTypes = .link
        linkTextAttributes = [:]
        delaysContentTouches = false
        adjustsFontForContentSizeCategory = true
        
        isAccessibilityElement = true
        accessibilityTraits = .staticText

        delegate = self
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override public func addGestureRecognizer(_ gestureRecognizer: UIGestureRecognizer) {
        if gestureRecognizer is UILongPressGestureRecognizer {
            gestureRecognizer.isEnabled = false
        }
        if let tapGestureRecognizer = gestureRecognizer as? UITapGestureRecognizer {
            tapGestureRecognizer.numberOfTapsRequired = 1
        }
        super.addGestureRecognizer(gestureRecognizer)
    }
    
    private func boundingRectForCharacterRange(_ range: NSRange) -> CGRect? {
        var glyphRange = NSRange()
        layoutManager.characterRange(forGlyphRange: range, actualGlyphRange: &glyphRange)
        return layoutManager.boundingRect(forGlyphRange: glyphRange, in: textContainer)
    }
}

extension TextLearningBlockView: UITextViewDelegate {
    
    public func textView(_ textView: UITextView, shouldInteractWith URL: URL, in characterRange: NSRange, interaction: UITextItemInteraction) -> Bool {
        let rangeBounds = boundingRectForCharacterRange(characterRange) ?? CGRect.zero
        let absoluteRect = textView.convert(rangeBounds, to: nil)
        blockViewDelegate?.didTapLink(blockView: self, url: URL, linkRect: absoluteRect)
        return false
    }
}

extension TextLearningBlockView: LearningBlockViewable {
    
    public func load(learningBlock: LearningBlock, style: LearningBlockStyle, textStyle: AttributedStringStyle? = TextAttributedStringStyle.shared) {
        self.learningBlock = learningBlock
        self.style = style
        self.textStyle = textStyle
        
        accessibilityIdentifier = learningBlock.accessibilityIdentifier

        backgroundColor = style.backgroundColor
        directionalLayoutMargins = style.margins
        textContainerInset = layoutMargins
        
        let xmlContent = learningBlock.content.linesLeftTrimmed()
        
        guard let textStyle = textStyle else { return }
        self.attributedText = NSAttributedString(xml: xmlContent, style: textStyle)
        
        self.setNeedsLayout()
    }
}

