//
//  FoldedNoteViewController.swift
//
//  Copyright © 2017,2018 Apple Inc. All rights reserved.
//

import UIKit
import PlaygroundSupport

@objc(FoldedNoteViewController)
public class FoldedNoteViewController: UIViewController, PlaygroundLiveViewMessageHandler, PlaygroundLiveViewSafeAreaContainer {
    
    // MARK: Properties
    
    @IBOutlet weak var unfoldedNoteView: UIView!
    @IBOutlet weak var textView: UITextView!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var unfoldedNoteCiphertextLabel: UILabel!
    @IBOutlet weak var substitutionCipherDiagram: UIImageView!
    @IBOutlet weak var noteButton: UIButton!
    @IBOutlet weak var openBookPageView: UIView!
    @IBOutlet weak var unfoldedNoteButton: UIButton!
    
    // MARK: Constraints
    
    // Substitution Page Constraints
    @IBOutlet weak var textViewLeadingConstraint: NSLayoutConstraint!
    @IBOutlet weak var textViewTrailingConstraint: NSLayoutConstraint!
    @IBOutlet weak var noteBottomConstraint: NSLayoutConstraint!
    @IBOutlet weak var noteHeightConstraint: NSLayoutConstraint!
    @IBOutlet weak var diagramHeightConstraint: NSLayoutConstraint!
    @IBOutlet weak var titleTopConstraint: NSLayoutConstraint!
    @IBOutlet weak var diagramToTitleConstraint: NSLayoutConstraint!
    @IBOutlet weak var textViewToDiagramConstraint: NSLayoutConstraint!
    // Note Constraints
    @IBOutlet weak var noteLeadingConstraint: NSLayoutConstraint!
    @IBOutlet weak var noteTrailingConstraint: NSLayoutConstraint!
    
    // MARK: View Controller Lifecycle
    
    public override func viewDidLoad() {
        super.viewDidLoad()
        
        // Accessibility labels and hints
        substitutionCipherDiagram.accessibilityLabel = NSLocalizedString("A diagram showing how letters in the alphabet are shifted down by some value to create the new substitution alphabet. For example, with a shift of 3, A becomes D, B becomes E, C becomes F.", comment: "Accessibility label for substitution cipher diagram")
        noteButton.accessibilityLabel = NSLocalizedString("A folded piece of paper lying on the page of the book.", comment: "Accessibility label for the note-shaped button.")
        noteButton.accessibilityHint = NSLocalizedString("Double tap to open the note.", comment: "Accessibility hint for the folded note button action.")
        unfoldedNoteButton.accessibilityLabel = NSLocalizedString("The note is a page of jumbled letters. You see spaces and punctuation between what might be words, but it is unintelligible.", comment: "Accessibility label describing the ciphertext on the note view.")
        unfoldedNoteButton.accessibilityHint = NSLocalizedString("Double tap to close the note and return to the open book.", comment: "Accessibility hint for the unfolded note button action.")
        unfoldedNoteCiphertextLabel.accessibilityLabel = String.localizedStringWithFormat(NSLocalizedString("The note text, %@", comment:"Accessibility label for the actual label with jumbled letters in it."), CipherContent.ciphertext)
        
        if let rtfUrl = Bundle.main.url(forResource: "SubstitutionCipherText", withExtension: "rtf") {
            do {
                textView.attributedText = try NSAttributedString(url: rtfUrl, options: [:], documentAttributes: nil)
            } catch {
                fatalError("Could not load rtf file into UITextView in FoldedNoteViewController")
            }
        }
        else {
            fatalError("Could not find rtf file in bundle for FoldedNoteViewController")
        }
        
        titleLabel.text = NSLocalizedString("Substitution Ciphers", comment: "Title label")
        unfoldedNoteCiphertextLabel.text = CipherContent.ciphertext
    }
    
    public override func updateViewConstraints() {
        resetConstraintsForViewSize()
        super.updateViewConstraints()
    }
    
    public override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        resetConstraintsForViewSize()
        view.layoutIfNeeded()
        textView.contentOffset.y = 0
    }
    
    // MARK: Custom Methods

    private func resetConstraintsForViewSize() {
        let currentWidth = liveViewSafeAreaGuide.layoutFrame.width
        let currentHeight = liveViewSafeAreaGuide.layoutFrame.height
        // Substitution Page
        let originalNoteHeight: CGFloat = 225
        let originalDiagramHeight: CGFloat = 162
        var originalLeading: CGFloat = 0
        var originalTrailing: CGFloat = 0
        var originalHeight: CGFloat = 0
        var originalWidth: CGFloat = 0
        var originalBottom: CGFloat = 0
        var heightScaleFactor: CGFloat = 1
        var widthScaleFactor: CGFloat = 1
        let originalDiagramToTitle: CGFloat = 12
        let originalTextToDiagram: CGFloat = 12
        // Note 
        var originalNoteLeading: CGFloat = 0
        var originalNoteTrailing: CGFloat = 0
        
        // Portrait
        if currentHeight > currentWidth {
            originalHeight = 1366
            originalWidth = 1024
            originalBottom = 230
            originalLeading = 150
            originalTrailing = 135
            originalNoteLeading = 125
            originalNoteTrailing = 125
        } else {
        // Landscape
            originalHeight = 1024
            originalWidth = 1366
            originalBottom = 158
            originalLeading = 175
            originalTrailing = 175
            originalNoteLeading = 150
            originalNoteTrailing = 150
        }
        
        heightScaleFactor = currentHeight / originalHeight
        widthScaleFactor = currentWidth / originalWidth
        
        textViewLeadingConstraint.constant = originalLeading * widthScaleFactor
        textViewTrailingConstraint.constant = originalTrailing * widthScaleFactor
        noteHeightConstraint.constant = originalNoteHeight * heightScaleFactor
        noteBottomConstraint.constant = originalBottom * heightScaleFactor
        diagramHeightConstraint.constant = originalDiagramHeight * heightScaleFactor
        titleTopConstraint.constant = liveViewSafeAreaGuide.layoutFrame.minY == 0 ? 70 : liveViewSafeAreaGuide.layoutFrame.minY
        diagramToTitleConstraint.constant = originalDiagramToTitle * heightScaleFactor
        textViewToDiagramConstraint.constant = originalTextToDiagram * heightScaleFactor
        noteLeadingConstraint.constant = originalNoteLeading * widthScaleFactor
        noteTrailingConstraint.constant = originalNoteTrailing * widthScaleFactor
        
        view.setNeedsUpdateConstraints()
    }
    
    // MARK: IBAction Methods

    @IBAction func openNote() {
        unfoldedNoteView.isHidden = false
        openBookPageView.isHidden = true
        
        // Let VoiceOver know the screen has changed
        UIAccessibility.post(notification: .screenChanged, argument: nil)
        
        // Send it back to the Contents.swift class so it can correctly register assessment
        send(.string(Constants.playgroundMessageKeyOpenNote))
    }
    
    @IBAction func backToBook(_ sender: UIButton) {
        unfoldedNoteView.isHidden = true
        openBookPageView.isHidden = false
        
        // Let VoiceOver know the screen has changed
        UIAccessibility.post(notification: .screenChanged, argument: nil)
    }
}
