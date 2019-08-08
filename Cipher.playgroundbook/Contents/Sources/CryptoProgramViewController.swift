//
//  CryptoProgramViewController.swift
//
//  Copyright © 2017,2018 Apple Inc. All rights reserved.
//

import UIKit
import PlaygroundSupport

@objc(CryptoProgramViewController)
public class CryptoProgramViewController: UIViewController, PlaygroundLiveViewSafeAreaContainer {

    // MARK: Properties
    
    @IBOutlet weak var topTextViewLabel: UILabel!
    @IBOutlet weak var topTextView: UITextView!
    @IBOutlet weak var scrollView: UIScrollView!
    
    @IBOutlet weak var shiftLabel: UILabel!
    @IBOutlet weak var shiftTextField: UITextField!
    @IBOutlet weak var bottomTextViewLabel: UILabel!
    @IBOutlet weak var bottomTextView: UITextView!
    @IBOutlet weak var segmentedControl: UISegmentedControl!
    
    fileprivate var currentShift: Int = 0 {
        didSet {
            bottomTextView.text = shiftText(inputText: topTextView.text, by: currentShift)
        }
    }
    private var encrypting = true
    
    // MARK: Localized Strings
    private let plaintextString = NSLocalizedString("Plaintext", comment:"Plaintext textView title label string")
    private let ciphertextString = NSLocalizedString("Ciphertext", comment:"Ciphertext textView title label string")
    
    // Constraints
    @IBOutlet weak var segmentedControlTopConstraint: NSLayoutConstraint!
    
    // MARK: View Controller Lifecycle
    
    public override func viewDidLoad() {
        super.viewDidLoad()
        
        // Accessibility Labels
        topTextView.accessibilityHint = NSLocalizedString("Enter some text you want to encrypt.", comment: "Accessibility hint for the top text view where someone would enter plaintext.")
        shiftTextField.accessibilityHint = NSLocalizedString("Choose the shift value you want to encrypt your text by.", comment: "Accessibility hint for the shift text view where someone choose how much to shift their plaintext by.")
        bottomTextView.accessibilityHint = NSLocalizedString("This view will display your encrypted plaintext as ciphertext.", comment: "Accessibility hint for the bottom text view where someone view their encrypted ciphertext.")

        scrollView.indicatorStyle = .white
        
        topTextView.delegate = self
        shiftTextField.delegate = self
        
        topTextView.layer.borderColor = UIColor.textViewBorderColor.cgColor
        topTextView.layer.borderWidth = 2
        topTextViewLabel.text = plaintextString
        bottomTextViewLabel.text = ciphertextString
        bottomTextView.layer.borderColor = UIColor.textViewBorderColor.cgColor
        bottomTextView.layer.borderWidth = 2
        shiftLabel.text = NSLocalizedString("Shift", comment: "Shift textview title label string")
        
        segmentedControl.setTitle(NSLocalizedString("Encrypt", comment: "Segmented control first label"), forSegmentAt: 0)
        segmentedControl.setTitle(NSLocalizedString("Decrypt", comment: "Segmented control second label"), forSegmentAt: 1)
        
        // Take bottom layoutGuide into account
        NSLayoutConstraint.activate([
            scrollView.bottomAnchor.constraint(equalTo: liveViewSafeAreaGuide.bottomAnchor),
        ])
    }
    
    public override func updateViewConstraints() {
        resetConstraintsForViewSize()
        super.updateViewConstraints()
    }
    
    public override func viewDidLayoutSubviews() {
        resetConstraintsForViewSize()
        scrollView.flashScrollIndicators()
    }
    
    // MARK: IBAction Methods
    
    // 0 = Encrypt
    // 1 = Decrypt
    @IBAction func encrypterToggled(_ sender: UISegmentedControl) {
        // Switch the text in each box
        let topText = topTextView.text
        let bottomText = bottomTextView.text
        topTextView.text = bottomText
        bottomTextView.text = topText
        
        switch sender.selectedSegmentIndex {
        case 0:
            encrypting = true
            // Switch the box labels
            topTextViewLabel.text = plaintextString
            bottomTextViewLabel.text = ciphertextString
            // Switch the entered text
        case 1:
            encrypting = false
            // Switch the box labels
            topTextViewLabel.text = ciphertextString
            bottomTextViewLabel.text = plaintextString
        default:
            break
        }
        
        // Let VoiceOver know the screen has changed
        UIAccessibility.post(notification: .screenChanged, argument: nil)
    }
    
    // MARK: Custom Methods
    
    private func resetConstraintsForViewSize() {
        segmentedControlTopConstraint.constant = liveViewSafeAreaGuide.layoutFrame.minY + 12
        
        view.setNeedsUpdateConstraints()
    }
    
    fileprivate func shiftText(inputText: String, by: Int) -> String {
        if encrypting {
            return CipherContent.shift(inputText: inputText, by: currentShift)
        } else {
            return CipherContent.shift(inputText: inputText, by: -currentShift)
        }
    }
}

extension CryptoProgramViewController: UITextFieldDelegate {
    public func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        guard textField == shiftTextField else { return true }
        let currentText = textField.text ?? ""
        let newText = (currentText as NSString).replacingCharacters(in: range, with: string)
        // Let VoiceOver know the screen is about to change
        UIAccessibility.post(notification: .screenChanged, argument: nil)
        
        if let shift = Int(newText) {
            currentShift = shift
            return true
        } else if newText.count == 0 || (newText.count == 1 && newText.contains("-")) {
            currentShift = 0
            return true
        } else {
            return false
        }
    }
}

extension CryptoProgramViewController: UITextViewDelegate {
    public func textViewDidChange(_ textView: UITextView) {
        if textView == topTextView {
            bottomTextView.text = shiftText(inputText: topTextView.text, by: currentShift)
        }
    }
}

extension CryptoProgramViewController: PlaygroundLiveViewMessageHandler {
    
    public func liveViewMessageConnectionOpened() {
        // Force the keyboard down so it doesn’t cover the text views
        view.endEditing(true)
    }
}
