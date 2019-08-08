//
//  BookTextView.swift
//
//  Copyright © 2017,2018 Apple Inc. All rights reserved.
//

import UIKit

struct BookTextAccessibilityReadingSection {
    var startParagraph: Int
    var endParagraph: Int
    var text: String
}

@objc(BookTextView)
public class BookTextView: UITextView {
    
    private var paragraphs = [(paragraphNumber: Int, text: String, rect: CGRect)]()
    
    private var accessibilityReadingSections = [BookTextAccessibilityReadingSection]()
    
    var title = ""
    
    private let accessibilityReadingSectionLineOffset = 1000
    
    func addAccessibilityReadingSection(startParagraph: Int, endParagraph: Int, text: String) {
        
        let newSection = BookTextAccessibilityReadingSection(startParagraph: startParagraph, endParagraph: endParagraph, text: text)
        accessibilityReadingSections.append(newSection)
    }
    
    func updateAccessibilityReadingInfo() {
        
        paragraphs.removeAll()
        
        let length = text.endIndex
        var paragraphStart = text.startIndex
        var paragraphEnd = text.startIndex
        var contentsEnd = text.startIndex
        
        var paragraphNumber = 0
        
        while paragraphEnd < length {
            
            text.getParagraphStart(&paragraphStart, end: &paragraphEnd, contentsEnd: &contentsEnd, for: paragraphEnd..<paragraphEnd)
            
            let paragraphRange = paragraphStart..<contentsEnd
            let paragraphText = String(text[paragraphRange])
            let paragraphNSRange = text.nsRange(from: paragraphRange)
            
            var actualCharacterRange = NSRange()
            let glyphRange = layoutManager.glyphRange(forCharacterRange: paragraphNSRange, actualCharacterRange: &actualCharacterRange)
            let paragraphRect = layoutManager.boundingRect(forGlyphRange: glyphRange, in: textContainer)
            let paragraphRectInView = paragraphRect.offsetBy(dx: self.textContainerInset.left, dy: self.textContainerInset.top)
            
            self.paragraphs.append((paragraphNumber, paragraphText, paragraphRectInView))
            
            paragraphNumber += 1
        }
    }
    
    func getText(forParagraph: Int) -> String? {
        
        guard forParagraph < paragraphs.count else { return nil }
        return paragraphs[forParagraph].text
    }
    
    private func rectForAccessibilityReadingSection(section: BookTextAccessibilityReadingSection) -> CGRect? {
        
        guard section.startParagraph < paragraphs.count,
            section.endParagraph < paragraphs.count else { return nil }
        
        var paragraphRect = paragraphs[section.startParagraph].rect
        for index in section.startParagraph...section.endParagraph {
            paragraphRect = paragraphRect.union(paragraphs[index].rect)
        }
        return paragraphRect
    }
}

// MARK: UIAccessibilityReadingContent
extension BookTextView: UIAccessibilityReadingContent {
    
    // Returns the line number given a point in the view’s coordinate space.
    public func accessibilityLineNumber(for point: CGPoint) -> Int {
        
        var lineNumber = NSNotFound
        
        for (index, section) in accessibilityReadingSections.enumerated() {
            if let sectionRect = rectForAccessibilityReadingSection(section: section), sectionRect.contains(point) {
                lineNumber = index + accessibilityReadingSectionLineOffset
            }
        }
        
        if lineNumber == NSNotFound {
            for (index, paragraph) in paragraphs.enumerated() {
                if paragraph.rect.contains(point) {
                    return index
                }
            }
        }
        
        return lineNumber
    }
    
    
    // Returns the content associated with a line number as a string.
    public func accessibilityContent(forLineNumber lineNumber: Int) -> String? {
        
        var content: String?
        
        if lineNumber >= accessibilityReadingSectionLineOffset {
            let sectionNumber = lineNumber - accessibilityReadingSectionLineOffset
            guard sectionNumber < accessibilityReadingSections.count else { return nil }
            content = accessibilityReadingSections[sectionNumber].text
        } else {
            guard lineNumber < paragraphs.count else { return nil }
            content = paragraphs[lineNumber].text
        }
        
        return content
    }
    
    // Returns the on-screen rectangle for a line number.
    public func accessibilityFrame(forLineNumber lineNumber: Int) -> CGRect {
        
        var frame = CGRect.zero
        
        if lineNumber >= accessibilityReadingSectionLineOffset {
            let sectionNumber = lineNumber - accessibilityReadingSectionLineOffset
            guard sectionNumber < accessibilityReadingSections.count else { return CGRect.zero }
            let section = accessibilityReadingSections[sectionNumber]
            if let sectionRect = rectForAccessibilityReadingSection(section: section) {
                frame = self.convert(sectionRect, to: nil)
            }
        } else {
            guard lineNumber < paragraphs.count else { return CGRect.zero }
            frame = self.convert(paragraphs[lineNumber].rect, to: nil)
        }
        
        return frame
    }
    
    // Returns a string representing the text displayed on the current page.
    public func accessibilityPageContent() -> String? {
        return title
    }
}
