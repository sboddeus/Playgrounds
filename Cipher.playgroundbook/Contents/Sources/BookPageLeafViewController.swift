//
//  BookPageLeafViewController.swift
//
//  Copyright © 2017,2018 Apple Inc. All rights reserved.
//

import UIKit

@objc(BookPageLeafViewController)
public class BookPageLeafViewController: UIViewController {

    @IBOutlet weak var backgroundImageView: UIImageView!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var textView: BookTextView!
    
    var pageNumber = 0
    var pageTitle = ""
    var rtfFileName = ""
    
    let plaintextAlphabet = Ciphers.uppercaseAlphabet
    lazy var ciphertextAlphabet = { return self.plaintextAlphabet.shuffled() }()
    
    var key: String = NSLocalizedString("ORANGE", comment: "Keyword for Book") {
        
        didSet {
            loadText()
        }
    }
    
    var word: String = NSLocalizedString("DOG", comment: "Word for Book") {
        
        didSet {
            loadText()
        }
    }
    
    var lines = [String]()
    var lineRects = [CGRect]()
    
    // MARK: View Controller Lifecycle
    
    public override func viewDidLoad() {
        super.viewDidLoad()
        
        titleLabel.text = pageTitle
        textView.title = pageTitle
        
        loadText()
        
        textView.accessibilityTraits = UIAccessibilityTraits.causesPageTurn
    }
    
    public override func viewDidLayoutSubviews() {
        
        textView.updateAccessibilityReadingInfo()
        
        // Let VoiceOver know the screen has changed
        UIAccessibility.post(notification: .screenChanged, argument: nil)
    }
    
    // MARK: Custom methods
    
    private func loadText() {
        
        let keyedAlphabet = Ciphers.getKeyedAlphabet(from: plaintextAlphabet, with: key)
        let reducedAlphabet = keyedAlphabet.replacingOccurrences(of: key, with: "")
        let cipherWord = word.monoalphabeticallySubstituting(alphabet: ciphertextAlphabet.letters, for: plaintextAlphabet.letters)

        if !rtfFileName.isEmpty, let rtfUrl = Bundle.main.url(forResource: rtfFileName, withExtension: "rtf") {
            do {
                
                let attributedText = try NSAttributedString(url: rtfUrl, options: [:], documentAttributes: nil)
                
                if let mutableAttributedText = attributedText.mutableCopy() as? NSMutableAttributedString {
                    
                    mutableAttributedText.replaceOccurrences(of: "<**PLAIN_ALPHABET**>", with: plaintextAlphabet)
                    mutableAttributedText.replaceOccurrences(of: "<**CIPHERTEXT_ALPHABET**>", with: ciphertextAlphabet)
                    let arrows = String(repeating: "↓", count: plaintextAlphabet.letters.count)
                    mutableAttributedText.replaceOccurrences(of: "<**↓↓**>", with: arrows)
                    mutableAttributedText.replaceOccurrences(of: "<**KEY**>", with: key)
                    mutableAttributedText.replaceOccurrences(of: "<**WORD**>", with: word)
                    mutableAttributedText.replaceOccurrences(of: "<**CIPHERWORD**>", with: cipherWord)
                    mutableAttributedText.replaceOccurrences(of: "<**REDUCED_ALPHABET**>", with: reducedAlphabet)
                    
                    // Highlight letters in word in plaintext alphabet.
                    let plainAlphabetWordHighlighted = "<**PLAIN_ALPHABET_WORD_HIGHLIGHTED**>"
                    if let mutableAttributedSubstring = mutableAttributedText.attributedSubstring(matching: plainAlphabetWordHighlighted) as? NSMutableAttributedString {
                        mutableAttributedSubstring.replaceOccurrences(of: plainAlphabetWordHighlighted, with: plaintextAlphabet)
                        for character in word {
                            mutableAttributedSubstring.highlightOccurences(of: String(character), with: Ciphers.plainTextColor)
                        }
                        mutableAttributedText.replaceOccurrences(of: plainAlphabetWordHighlighted, with: mutableAttributedSubstring)
                    }
                    
                    // Highlight equyivalent letters in ciphertext alphabet.
                    let cipherTextAlphabetCipherwordHighlighted = "<**CIPHERTEXT_ALPHABET_CIPHERWORD_HIGHLIGHTED**>"
                    if let mutableAttributedSubstring = mutableAttributedText.attributedSubstring(matching: cipherTextAlphabetCipherwordHighlighted) as? NSMutableAttributedString {
                        mutableAttributedSubstring.replaceOccurrences(of: cipherTextAlphabetCipherwordHighlighted, with: ciphertextAlphabet)
                        for character in cipherWord {
                            mutableAttributedSubstring.highlightOccurences(of: String(character), with: Ciphers.cipherTextColor)
                        }
                        mutableAttributedText.replaceOccurrences(of: cipherTextAlphabetCipherwordHighlighted, with: mutableAttributedSubstring)
                    }
                    
                    textView.attributedText = mutableAttributedText
                }
                
            } catch {
                fatalError("Could not load rtf file '\(rtfFileName)' in \(String(describing: self)).")
            }
        }
        else {
            fatalError("Could not find rtf file '\(rtfFileName)' in bundle for \(String(describing: self)).")
        }
        
        textView.updateAccessibilityReadingInfo()
        
        let plaintextAlphabetFormat = NSLocalizedString("Plaintext alphabet with letters %@",
                                                   comment: "Accessibility label for plaintext alphabet.")
        
        let ciphertextAlphabetFormat = NSLocalizedString("Ciphertext alphabet with letters %@",
                                                         comment: "Accessibility label for ciphertext alphabet.")
        
        let constructionFormat = NSLocalizedString("Keyword %@, followed by letters %@",
                                                         comment: "Accessibility label for constructing ciphertext alphabet.")
        
        
        let keyedCiphertextAlphabetFormat = NSLocalizedString("Keyed ciphertext alphabet with keyword %@, followed by letters %@",
                                                   comment: "Accessibility label for keyed ciphertext alphabet.")
        
        let arrowsLabel = NSLocalizedString("Each letter in the plaintext alphabet above is joined to a letter in the ciphertext alphabet below.",
                                            comment: "Accessibility label for arrows between plaintext and ciphertext alphabets.")
        
        if pageNumber == 0 {
            
            let ciphertextParagraphNumber = 5
            let ciphertextAlphabet = textView.getText(forParagraph: ciphertextParagraphNumber) ?? ""
            
            
            textView.addAccessibilityReadingSection(startParagraph: 2, endParagraph: 3,
                                           text: String.localizedStringWithFormat(plaintextAlphabetFormat, plaintextAlphabet.letterByLetterForVoiceOver()))
            
            textView.addAccessibilityReadingSection(startParagraph: 4, endParagraph: 4,
                                                    text: arrowsLabel)
            
            textView.addAccessibilityReadingSection(startParagraph: 5, endParagraph: 6,
                                           text: String.localizedStringWithFormat(ciphertextAlphabetFormat, ciphertextAlphabet.letterByLetterForVoiceOver()))
            
        } else if pageNumber == 1 {
            
            textView.addAccessibilityReadingSection(startParagraph: 3, endParagraph: 3,
                                                    text: plaintextAlphabet.letterByLetterForVoiceOver())
            
            textView.addAccessibilityReadingSection(startParagraph: 6, endParagraph: 6,
                                                    text: String.localizedStringWithFormat(constructionFormat, key.letterByLetterForVoiceOver(), plaintextAlphabet.letterByLetterForVoiceOver()))
            
            textView.addAccessibilityReadingSection(startParagraph: 9, endParagraph: 9,
                                                    text: String.localizedStringWithFormat(constructionFormat, key.letterByLetterForVoiceOver(), reducedAlphabet.letterByLetterForVoiceOver()))
            
            textView.addAccessibilityReadingSection(startParagraph: 13, endParagraph: 14,
                                           text: String.localizedStringWithFormat(plaintextAlphabetFormat, plaintextAlphabet.letterByLetterForVoiceOver()))
            
            textView.addAccessibilityReadingSection(startParagraph: 15, endParagraph: 15,
                                                    text: arrowsLabel)
            
            textView.addAccessibilityReadingSection(startParagraph: 16, endParagraph: 17,
                                           text: String.localizedStringWithFormat(keyedCiphertextAlphabetFormat, key, reducedAlphabet.letterByLetterForVoiceOver()))
        }
        
        view.setNeedsLayout()
    }
}




