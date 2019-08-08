//
//  NibblerPlusPaperScrapsViewController.swift
//
//  Copyright © 2017,2018 Apple Inc. All rights reserved.
//

import UIKit
import PlaygroundSupport

@objc(NibblerPlusPaperScrapsViewController)
public class NibblerPlusPaperScrapsViewController: UIViewController {
    
    
    @IBOutlet weak var nibblerImageView: UIImageView!
    @IBOutlet weak var bubbleImageView: UIImageView!
    
    @IBOutlet weak var letterButton1: UIButton!
    @IBOutlet weak var letterButton2: UIButton!
    @IBOutlet weak var letterButton3: UIButton!
    @IBOutlet weak var letterButton4: UIButton!
    @IBOutlet weak var letterButton5: UIButton!
    @IBOutlet weak var letterButton6: UIButton!
    @IBOutlet weak var letterButton7: UIButton!
    
    private var letterButtons = [UIButton]()
    
    private var finalConstraints = [NSLayoutConstraint]()
    private var finalButtonMultipliers = [CGPoint]()

    private var scrapsHaveBeenRemovedFromNibbler = false

    private var originalLetterPointSize : CGFloat = 24.0
    private let originalDesignWidth : CGFloat = 768.0
    private let originalDesignHeight : CGFloat = 1024.0
    
    // MARK: View Controller Lifecycle
    
    override public func viewDidLoad() {
        super.viewDidLoad()
        
        nibblerImageView.accessibilityLabel = NSLocalizedString("Nibbler the dog", comment: "Accessibility label for Nibbler the dog.")
        
        hideQuestionMarkBubble()
        
        if let titleLabel = letterButton1.titleLabel {
            originalLetterPointSize = titleLabel.font.pointSize
        }
        
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
            letterButtons[i].isUserInteractionEnabled = true
            let panGestureRecognizer = UIPanGestureRecognizer(target: self, action: #selector(self.onLetterDrag(recognizer:)))
            letterButtons[i].addGestureRecognizer(panGestureRecognizer)
        }
        
        // Save final positions of the letter buttons in the form of x and y multipliers from their centerX and centerY constraints.
        // For example, the x position of a button is the center of the view x position * the X multiplier.
        for letterButton in letterButtons {
            
            var multiplier = CGPoint.zero
            
            for constraint in view.constraints {
                guard
                let button = constraint.firstItem as? UIButton,
                    button == letterButton else { continue }
                
                if constraint.firstAttribute == .centerX {
                    multiplier.x = constraint.multiplier
                    finalConstraints.append(constraint)
                } else if constraint.firstAttribute == .centerY {
                    multiplier.y = constraint.multiplier
                    finalConstraints.append(constraint)
                }
            }
            
            finalButtonMultipliers.append(multiplier)
        }
        
        // Deactivate the constraints: they’re reactivated later when the letters are animated out.
        NSLayoutConstraint.deactivate(finalConstraints)
    }
    
    override public func viewWillLayoutSubviews() {
        super.viewWillLayoutSubviews()
        
        // Scale letter labels font.
        let scaledPointSizeW = originalLetterPointSize * view.frame.width / originalDesignWidth
        let scaledPointSizeH = originalLetterPointSize * view.frame.height / originalDesignHeight
        let scaledPointSize = min(scaledPointSizeW, scaledPointSizeH)
        letterButtons.forEach { letterButton in
            if let titleLabel = letterButton.titleLabel {
                titleLabel.font = titleLabel.font.withSize(scaledPointSize)
            }
        }
    }
    
    override public func viewDidLayoutSubviews() {
        
        // Set the letter to initially be hidden under Nibbler’s mouth.
        if !scrapsHaveBeenRemovedFromNibbler {
            placeScrapsInsideNibbler()
        }
     }
    
    // MARK: Actions
    
    @objc private func onLetterDrag(recognizer: UIPanGestureRecognizer) {
        
        guard let letterButton = recognizer.view else { return }
        letterButton.center = recognizer.location(in: letterButton.superview)
    }
    
    private func jiggledPoint(for point: CGPoint) -> CGPoint {
        let dx = CGFloat((Double.randomNormalized() - 0.5)) * 0.1 * point.x
        let dy = CGFloat((Double.randomNormalized() - 0.5)) * 0.1 * point.y
        return CGPoint(x: point.x + dx, y: point.y + dy)
    }
    
    // MARK: Custom Methods
    
    private func hideQuestionMarkBubble() {
        bubbleImageView.isHidden = true
    }
    
    private func showQuestionMarkBubble() {
        
        bubbleImageView.transform = CGAffineTransform(scaleX: 0.01, y: 0.01);
        bubbleImageView.isHidden = false
        
        playSound(.dogDoubleBark)
        
        UIView.animate(withDuration: 0.5,
                       delay: 0.0,
                       usingSpringWithDamping: 0.5,
                       initialSpringVelocity: 0.2,
                       options: .allowAnimatedContent,
                       animations: {
            self.bubbleImageView.transform = CGAffineTransform.identity
        }, completion: nil)
    }
    
    private func placeScrapsInsideNibbler() {
        
        let startingPosition = CGPoint(x: self.view.bounds.width * 0.425, y: view.bounds.height * 0.8)
        for letterButton in letterButtons {
            letterButton.center = startingPosition
        }
    }
    
    private func removeScrapsFromNibbler() {
        
        let intermediatePoint1 = CGPoint(x: self.view.bounds.width * 0.3, y: self.view.bounds.height * 0.85)
        let intermediatePoint2 = CGPoint(x: self.view.bounds.width * 0.15, y: self.view.bounds.height * 0.8)
        let intermediatePoint3 = CGPoint(x: self.view.bounds.width * 0.25, y: self.view.bounds.height * 0.7)
        
        var finalButtonPositions = [CGPoint]()
        for multiplier in finalButtonMultipliers {
            finalButtonPositions.append( CGPoint(x: multiplier.x * self.view.center.x, y: multiplier.y * self.view.center.y) )
        }
        
        scrapsHaveBeenRemovedFromNibbler = true
        
        playSound(.dogGrowl)
        
        UIView.animateKeyframes(withDuration: 5.0, delay: 0, options: .calculationModeCubic, animations: {
            
            var startTime = 0.0
            
            for (index, letterButton) in self.letterButtons.enumerated() {
                
                UIView.addKeyframe(withRelativeStartTime: startTime + 0.0, relativeDuration: 0.25) {
                    letterButton.center = self.jiggledPoint(for: intermediatePoint1)
                }
                
                UIView.addKeyframe(withRelativeStartTime: startTime + 0.1, relativeDuration: 0.25) {
                    letterButton.center = self.jiggledPoint(for: intermediatePoint2)
                }
                
                UIView.addKeyframe(withRelativeStartTime: startTime + 0.4, relativeDuration: 0.25) {
                    letterButton.center = self.jiggledPoint(for: intermediatePoint3)
                }
                
                UIView.addKeyframe(withRelativeStartTime: startTime + 0.6, relativeDuration: 0.25) {
                    letterButton.center = finalButtonPositions[index]
                }
                
                startTime += 0.05
            }
            
        }, completion: { _ in
            
            NSLayoutConstraint.activate(self.finalConstraints)
            self.view.setNeedsUpdateConstraints()
            
            self.send(.dictionary([
                Constants.playgroundMessageKeyCompleted : PlaygroundValue.boolean(true)
                ]))

        })
    }
}

// MARK: PlaygroundLiveViewMessageHandler
extension NibblerPlusPaperScrapsViewController: PlaygroundLiveViewMessageHandler {
    
    public func receive(_ message: PlaygroundValue) {
        
        guard
            case let .dictionary(dict) = message,
            case let .string(command)? = dict[Constants.playgroundMessageKeyCommand]
            else { return }
        
        hideQuestionMarkBubble()
        
        if command == Constants.playgroundMessageKeyDropThePaperScraps {
            if case let .boolean(correct)? = dict[Constants.playgroundMessageKeySuccess] {

                if correct {
                    removeScrapsFromNibbler()
                    return
                }
            }
        }
        
        placeScrapsInsideNibbler()
        showQuestionMarkBubble()
        
        send(.dictionary([
            Constants.playgroundMessageKeyError : PlaygroundValue.boolean(true)
            ]))
    }
}
