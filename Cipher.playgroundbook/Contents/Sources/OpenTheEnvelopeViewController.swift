//
//  OpenTheEnvelopeViewController.swift
//
//  Copyright © 2017,2018 Apple Inc. All rights reserved.
//

import UIKit
import PlaygroundSupport

public enum OpenTheEnvelopeState {
    case closed
    case open
    case messageVisible
}

@objc(OpenTheEnvelopeViewController)
public class OpenTheEnvelopeViewController: UIViewController, PlaygroundLiveViewSafeAreaContainer {
    
    @IBOutlet weak var backgroundImageView: UIImageView!
    @IBOutlet weak var armWithClosedEnvelopeImageView: UIImageView!
    @IBOutlet weak var envelopeOpenImageView: UIImageView!
    @IBOutlet weak var noteBackgroundImageView: UIImageView!
    @IBOutlet weak var noteView: UIView!
    @IBOutlet weak var noteLabel: UILabel!
    @IBOutlet weak var envelopeOverlayImageView: UIImageView!
    
    @IBOutlet weak var noteViewWidthConstraint: NSLayoutConstraint!
    @IBOutlet weak var noteViewHeightConstraint: NSLayoutConstraint!
    @IBOutlet weak var noteViewCenterYConstraint: NSLayoutConstraint!
    @IBOutlet weak var envelopeOverlayImageViewYConstraint: NSLayoutConstraint!
    @IBOutlet weak var envelopeOpenImageViewYConstraint: NSLayoutConstraint!
    
    var state: OpenTheEnvelopeState = .closed
    
    // MARK: View Controller Lifecycle
    
    override public func viewDidLoad() {
        super.viewDidLoad()
        
        backgroundImageView.accessibilityLabel = NSLocalizedString("Library showing shelves of books", comment: "Accessibility label for library.")
        
        armWithClosedEnvelopeImageView.accessibilityLabel = NSLocalizedString("Closed envelope being handed to you by the librarian",
                                                                              comment: "Accessibility label for arm holding envelope.")
        let format = NSLocalizedString("Piece of paper that was in the envelope. It reads: %@",
                                       comment: "Accessibility label for piece of paper that was in the envelope.")
        noteView.accessibilityLabel = String.localizedStringWithFormat(format, Ciphers.cipherTwoCiphertext.letterByLetterForVoiceOver())
        
        noteLabel.text = Ciphers.cipherTwoCiphertext
        
        envelopeOpenImageView.isHidden = true
        noteView.isHidden = true
        envelopeOverlayImageView.isHidden = true
        
        // Hide bottom of note while it’s in the envelope.
        noteView.clipsToBounds = true
    }
    
    // MARK: Custom methods
    
    private func openTheEnvelope() {
        
        envelopeOpenImageView.isHidden = false
        noteView.isHidden = false
        envelopeOverlayImageView.isHidden = false
        
        UIView.animate(withDuration: 0.5, animations: {
            
            // Remove the arm.
            self.armWithClosedEnvelopeImageView.alpha = 0.0
            
        }, completion: { _ in
            
            self.takeOutPaper()
            
            DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + 1, execute: {
                
                playSound(.dogChew)
                
                // Tell page we’re done.
                self.send(.dictionary([
                    Constants.playgroundMessageKeyCompleted : PlaygroundValue.boolean(true)
                    ]))
            })
        })
    }
    
    private func takeOutPaper() {
        
        // Progressively reveal lower half of the note.
        noteViewHeightConstraint = noteViewHeightConstraint.copy(withMultiplier: 1.0)
        UIView.animate(withDuration: 1.0, animations: {
            self.view.layoutIfNeeded()
        }, completion: nil )
        
        // Create rotation animation.
        let rotationAngle = 0.15
        let rotationDuration = 1.0
        let rotateDurationVariability = 0.05
        let rotationAnimation = CAKeyframeAnimation(keyPath: "transform.rotation.z")
        rotationAnimation.values = [-rotationAngle, rotationAngle]
        rotationAnimation.autoreverses = true
        let randomDuration = rotationDuration + (rotateDurationVariability * Double.randomNormalized())
        rotationAnimation.duration = randomDuration
        rotationAnimation.repeatCount = HUGE
        
        // Move note up and slide envelope down while rotating it.
        noteViewCenterYConstraint = noteViewCenterYConstraint.copy(withMultiplier: 0.7)
        envelopeOpenImageViewYConstraint = envelopeOpenImageViewYConstraint.copy(withMultiplier: 2.8)
        envelopeOverlayImageViewYConstraint = envelopeOverlayImageViewYConstraint.copy(withMultiplier: 2.8)
        UIView.animate(withDuration: 8.0, delay: 0,
                       usingSpringWithDamping: 1.0,
                       initialSpringVelocity: 0.2,
                       options: .allowAnimatedContent,
                       animations: {
                        
                        // Rotate envelope as it falls.
                        self.envelopeOpenImageView.layer.add(rotationAnimation, forKey: "rotation")
                        self.envelopeOverlayImageView.layer.add(rotationAnimation, forKey: "rotation")
                        
                        self.backgroundImageView.alpha = 0.5
                        self.noteView.transform = CGAffineTransform(scaleX: 1.25, y: 1.25)
                        
                        self.view.layoutIfNeeded()
                        
        }, completion: { _ in
            
            self.envelopeOpenImageView.layer.removeAnimation(forKey: "rotation")
            self.envelopeOverlayImageView.layer.removeAnimation(forKey: "rotation")
            self.envelopeOpenImageView.isHidden = true
            self.envelopeOverlayImageView.isHidden = true
        })
    }
}

// MARK: PlaygroundLiveViewMessageHandler
extension OpenTheEnvelopeViewController: PlaygroundLiveViewMessageHandler {
    
    public func receive(_ message: PlaygroundValue) {
        
        guard
            case let .dictionary(dict) = message,
            case let .string(command)? = dict[Constants.playgroundMessageKeyCommand]
            else { return }
        
        if command == Constants.playgroundMessageKeyOpenTheEnvelope {
            openTheEnvelope()
        }
    }
}
