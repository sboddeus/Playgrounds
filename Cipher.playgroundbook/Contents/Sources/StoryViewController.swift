//
//  StoryViewController.swift
//
//  Copyright © 2017,2018 Apple Inc. All rights reserved.
//

import UIKit
import PlaygroundSupport

@objc(StoryViewController)
public class StoryViewController: UIViewController, PlaygroundLiveViewSafeAreaContainer {
    
    // MARK: Properties
    
    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var messageLabel: UILabel!
    
    // Constraints
    @IBOutlet weak var messageLabelTopConstraint: NSLayoutConstraint!
    @IBOutlet weak var messageLabelBottomConstraint: NSLayoutConstraint!
    @IBOutlet weak var messageLabelLeadingConstraint: NSLayoutConstraint!
    @IBOutlet weak var messageLabelTrailingConstraint: NSLayoutConstraint!
    
    // MARK: View Controller Lifecycle
    
    public override func updateViewConstraints() {
        resetConstraintsForViewSize()
        super.updateViewConstraints()
    }
    
    public override func viewDidLayoutSubviews() {
        resetConstraintsForViewSize()
    }
    
    // MARK: Custom Methods
    
    private func resetConstraintsForViewSize() {
        let currentWidth = liveViewSafeAreaGuide.layoutFrame.width
        let currentHeight = liveViewSafeAreaGuide.layoutFrame.height
        let originalMessageTop: CGFloat = 100
        let originalMessageBottom: CGFloat = 100
        var originalMessageLeading: CGFloat = 0
        var originalMessageTrailing: CGFloat = 0
        var widthScaleFactor: CGFloat = 1
        var heightScaleFactor: CGFloat = 1
        var originalWidth: CGFloat = 0
        var originalHeight: CGFloat = 0
        
        // Portrait
        if currentHeight > currentWidth {
            originalWidth = 1024
            originalHeight = 1366
            originalMessageLeading = 40
            originalMessageTrailing = 40
        } else {
            // Landscape
            originalWidth = 1366
            originalHeight = 1024
            originalMessageLeading = 200
            originalMessageTrailing = 200
        }
        
        heightScaleFactor = currentHeight / originalHeight
        widthScaleFactor = currentWidth / originalWidth
        
        messageLabelTopConstraint.constant = originalMessageTop * heightScaleFactor
        messageLabelBottomConstraint.constant = originalMessageBottom * heightScaleFactor
        messageLabelLeadingConstraint.constant = originalMessageLeading * widthScaleFactor
        messageLabelTrailingConstraint.constant = originalMessageTrailing * widthScaleFactor
        
        view.setNeedsUpdateConstraints()
    }
    
    private func resetImageView() {
        imageView.isHidden = false
        messageLabel.isHidden = true
        view.backgroundColor = #colorLiteral(red: 1, green: 0.9817538857, blue: 0.8981644511, alpha: 1)
    }
    
    public func displayDecryptedMessage() {
        imageView.isHidden = true
        messageLabel.isHidden = false
        messageLabel.text = CipherContent.plaintext
    }
    
    fileprivate func displayEnvelope() {
        resetImageView()
        imageView.image = UIImage(named: "handing_note.png")
        imageView.accessibilityLabel = NSLocalizedString("The librarian’s hand giving you an envelope.", comment: "Accessibility label for image of handing over the clue.")
        // Let VoiceOver know the screen has changed
        UIAccessibility.post(notification: .screenChanged, argument: nil)
    }
    
    fileprivate func investigateNewspapers() {
        resetImageView()
        imageView.image = UIImage(named: "newspaper_pile.png")
        imageView.accessibilityLabel = NSLocalizedString("A messy pile of newspapers.", comment: "Accessibility label for image of newspapers.")
        // Let VoiceOver know the screen has changed
        UIAccessibility.post(notification: .screenChanged, argument: nil)
    }
    
    fileprivate func investigateNovels() {
        resetImageView()
        imageView.image = UIImage(named: "library.png")
        imageView.accessibilityLabel = NSLocalizedString("Many bookshelves showing the novels section of the library.", comment: "Accessibility label for image of novels.")
        // Let VoiceOver know the screen has changed
        UIAccessibility.post(notification: .screenChanged, argument: nil)
    }
    
    public func investigateLibrarian() {
        resetImageView()
        imageView.image = UIImage(named: "librarian.png")
        imageView.accessibilityLabel = NSLocalizedString("The librarian, Mr Nefarian, sitting at his desk, looking at you questioningly over his glasses.", comment: "Accessibility label for image of librarian")
        // Let VoiceOver know the screen has changed
        UIAccessibility.post(notification: .screenChanged, argument: nil)
    }
}

extension StoryViewController: PlaygroundLiveViewMessageHandler {
    public func receive(_ message: PlaygroundValue) {
        switch message {
        case .string(let messageString):
            if messageString == Constants.playgroundMessageKeyCorrectPassword {
                displayEnvelope()
            } else if messageString == Constants.playgroundMessageKeyNewspapers {
                investigateNewspapers()
            } else if messageString == Constants.playgroundMessageKeyNovels {
                investigateNovels()
            } else if messageString == Constants.playgroundMessageKeyLibrarian {
                investigateLibrarian()
            }
        default:
            return
        }
    }
}
