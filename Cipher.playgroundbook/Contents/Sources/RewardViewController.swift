//
//  RewardViewController.swift
//
//  Copyright © 2017,2018 Apple Inc. All rights reserved.
//

import UIKit
import PlaygroundSupport

@objc(RewardViewController)
public class RewardViewController: UIViewController, PlaygroundLiveViewSafeAreaContainer {
    
    @IBOutlet weak var noteView: UIView!
    @IBOutlet weak var noteBackgroundImageView: UIImageView!
    @IBOutlet weak var noteLabel: UILabel!
    
    @IBOutlet weak var letterButton1: UIButton!
    @IBOutlet weak var letterButton2: UIButton!
    @IBOutlet weak var letterButton3: UIButton!
    @IBOutlet weak var letterButton4: UIButton!
    @IBOutlet weak var letterButton5: UIButton!
    @IBOutlet weak var letterButton6: UIButton!
    @IBOutlet weak var letterButton7: UIButton!
    @IBOutlet weak var nibblerImageView: UIImageView!
    
    private var letterButtons = [UIButton]()
    
    private var originalLetterPointSize : CGFloat = 24.0
    private let originalDesignSize = CGSize(width: 768, height: 1024)
    
    private var successfullyCompleted = false
    
    // MARK: View Controller Lifecycle
    
    override public func viewDidLoad() {
        super.viewDidLoad()
        
        if let titleLabel = letterButton1.titleLabel {
            originalLetterPointSize = titleLabel.font.pointSize
        }
        
        nibblerImageView.accessibilityLabel = NSLocalizedString("Nibbler, the dog, asleep", comment: "Accessibility label for Nibbler the dog waiting.")
        
        // Populate letter buttons.
        letterButtons = [letterButton1, letterButton2, letterButton3, letterButton4, letterButton5, letterButton6, letterButton7]
        
        let keyLetters = Ciphers.cipherTwoKeyShuffled.letters
        
        guard letterButtons.count >= keyLetters.count else {
            fatalError("Insufficient letter buttons for number of letters (\(keyLetters.count)) in key in \(String(describing: self))")
        }
        
        for (i, letter) in keyLetters.enumerated() {
            letterButtons[i].setTitle(letter, for: .normal)
            letterButtons[i].isAccessibilityElement = false
            letterButtons[i].titleLabel?.isAccessibilityElement = true
            let format = NSLocalizedString("Letter '%@' on scrap of paper",
                                           comment: "Accessibility label for scrap of paper with a {letter} on it.")
            letterButtons[i].titleLabel?.accessibilityLabel = String.localizedStringWithFormat(format, letter)
        }
        
        let format = NSLocalizedString("Piece of paper with cryptic message on it. It reads: %@",
                                       comment: "Accessibility label for piece of paper with message.")
        noteView.accessibilityLabel = String.localizedStringWithFormat(format, Ciphers.cipherTwoCiphertext.letterByLetterForVoiceOver())
        
        noteLabel.text = Ciphers.cipherTwoCiphertext
    }
    
    override public func viewWillLayoutSubviews() {
        super.viewWillLayoutSubviews()
        
        // Scale letter labels font.
        let scaledPointSize = originalLetterPointSize * view.frame.height / originalDesignSize.height
        letterButtons.forEach { letterButton in
            if let titleLabel = letterButton.titleLabel {
                titleLabel.font = titleLabel.font.withSize(scaledPointSize)
            }
        }
    }
    
    public override func viewDidLayoutSubviews() {
        
        if successfullyCompleted {
            arrangeLetters(animated: false)
        }
    }
    
    // MARK: Custom methods
    
    private func crossFadeView(view: UIView, duration: CFTimeInterval) {
        let animation = CATransition()
        animation.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
        animation.type = .fade
        animation.duration = duration
        view.layer.add(animation, forKey: CATransitionType.fade.rawValue)
    }
    
    private func arrangeLetters(animated: Bool, completion: (() -> Void)? = nil) {
        
        let margin = view.frame.width * 0.05
        let letterSpacing = (view.frame.width - (margin * 2)) / CGFloat(letterButtons.count)
        var x = margin + (letterSpacing / 2)
        let y = view.frame.height * 0.625
        var delay = 0.0
        let delayIncrement = 0.25
        
        var orderedLetterButtons = [UIButton]()
        for letter in Ciphers.cipherTwoKey.letters {
            for letterButton in letterButtons {
                if let title = letterButton.title(for: .normal), title == letter {
                    orderedLetterButtons.append(letterButton)
                    continue
                }
            }
        }
        
        for (index, letterButton) in orderedLetterButtons.enumerated() {
            
            let shrinkScale = self.view.frame.width / originalDesignSize.width
            
            UIView.animate(withDuration: animated ? 2.0 : 0.0,
                           delay: animated ? delay: 0.0,
                           usingSpringWithDamping: 0.5,
                           initialSpringVelocity: 0.2,
                           options: .allowAnimatedContent,
                           animations: {
                            
                            letterButton.center = CGPoint(x: x, y: y)
                            let rotationTransform = CATransform3DMakeRotation(0, 0, 0, 1)
                            letterButton.layer.transform = CATransform3DScale(rotationTransform, shrinkScale, shrinkScale, shrinkScale)
                            
            }, completion: { _ in
                
                // Final step is triggered when the 3rd from last button moves into place.
                if index == (orderedLetterButtons.count - 4) {
                    
                    let format = NSLocalizedString("Decrypted message. It reads: %@",
                                                   comment: "Accessibility label for decrypted message.")
                    self.noteView.accessibilityLabel = String.localizedStringWithFormat(format, Ciphers.cipherTwoPlaintext)
                    
                    if animated {
                        self.crossFadeView(view: self.noteLabel, duration: 1.0)
                    }
                    self.noteLabel.text = Ciphers.cipherTwoPlaintext
                    
                    completion?()
                }
            })
        
            delay += delayIncrement
            x += letterSpacing
        }
    }
}

// MARK: PlaygroundLiveViewMessageHandler
extension RewardViewController: PlaygroundLiveViewMessageHandler {
    
    public func receive(_ message: PlaygroundValue) {
        
        guard
            case let .dictionary(dict) = message,
            case let .string(command)? = dict[Constants.playgroundMessageKeyCommand]
            else { return }
        
        if command == Constants.playgroundMessageKeyFoundCorrectKeyword {
            
            arrangeLetters(animated: true, completion: {
                
                self.successfullyCompleted = true
                
                // Tell page we’re done.
                DispatchQueue.main.asyncAfter(deadline: DispatchTime.now(), execute: {
                    playSound(.dogHappyPlayful)
                })
            })
        }
    }
}
