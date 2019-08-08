//
//  CryptoProgramViewController.swift
//
//  Copyright © 2017,2018 Apple Inc. All rights reserved.
//

import UIKit
import PlaygroundSupport

@objc(CryptobotViewController)
public class CryptobotViewController: UIViewController, PlaygroundLiveViewSafeAreaContainer {

    // MARK: Properties
    
    @IBOutlet weak var topTextViewLabel: UILabel!
    @IBOutlet weak var topTextView: UITextView!
    @IBOutlet weak var scrollView: UIScrollView!
    
    @IBOutlet weak var shiftLabel: UILabel!
    @IBOutlet weak var keyOrShiftTextField: UITextField!
    @IBOutlet weak var bottomTextViewLabel: UILabel!
    @IBOutlet weak var bottomTextView: UITextView!
    @IBOutlet weak var segmentedControl: UISegmentedControl!

    @IBOutlet weak var cipherTypeLabel: UILabel!
    @IBOutlet weak var cipherTypePicker: UIPickerView!
    
    // Display Strings, for Localization Purposes
    private let encryptString = NSLocalizedString("Encrypt", comment: "Segmented Control string")
    private let decryptString = NSLocalizedString("Decrypt", comment: "Segmented Control string")
    private let plaintextString = NSLocalizedString("Plaintext", comment:"Plaintext textView title label string")
    private let ciphertextString = NSLocalizedString("Ciphertext", comment:"Ciphertext textView title label string")
    private let shiftString = NSLocalizedString("Shift", comment:"Shift label title")
    private let cipherTypeString = NSLocalizedString("Choose a cipher type", comment:"Cipher type picker title")
    private let keyString = NSLocalizedString("Keyword", comment:"Keyword label title")
    private let randomKeyString = NSLocalizedString("Random keyword", comment: "Random keyword label title")
    
    // Default key
    private let defaultKey = NSLocalizedString("ORANGE", comment: "Default keyword")
    // Default shift (Caesar)
    private let defaultShift = "4"
    
    // Constraints
    @IBOutlet weak var segmentedControlTopConstraint: NSLayoutConstraint!
    @IBOutlet weak var bottomTextViewLabelToKeyConstraint: NSLayoutConstraint!
    @IBOutlet weak var keyTextFieldWidthConstraint: NSLayoutConstraint!
    @IBOutlet weak var bottomTextViewLabelToPickerConstraint: NSLayoutConstraint!
    
    private var isEncrypting = true
    private var currentlySelectedCipher = Ciphers.CipherType.none
    private let ciphers = Ciphers.allCiphers()
    
    private var currentKey: String = "" {
        didSet {
            updateText()
        }
    }
    
    private var currentShift: String = "" {
        didSet {
            updateText()
        }
    }
    
    var axHintForKeyOrShiftTextField: String {
        switch currentlySelectedCipher {
        case .caesar:
            return NSLocalizedString("Enter the shift value you want to use to encrypt or decrypt.",
                                     comment: "Accessibility hint for the shift text field where someone chooses a shift value.")
        default:
            return NSLocalizedString("Enter the key you want to use to encrypt or decrypt.",
                                     comment: "Accessibility hint for the key text field where someone chooses a key.")
        }
    }
    
    var axHintForTopTextView: String {
        if isEncrypting {
            return NSLocalizedString("Enter the text you want to encrypt.",
                                     comment: "Accessibility hint for the top text view in which plaintext is entered to be encrypted.")
        } else {
            return NSLocalizedString("Enter the text you want to decrypt.",
                                     comment: "Accessibility hint for the top text view in which ciphertext is entered to be decrypted.")
        }
    }
    
    var axHintForBottomTextView: String {
        if isEncrypting {
            return NSLocalizedString("Displays your encrypted plaintext as ciphertext.",
                                     comment: "Accessibility hint for the bottom text view in which encrypted ciphertext is displayed.")
        } else {
            return NSLocalizedString("Displays your decrypted ciphertext as plaintext.",
                                     comment: "Accessibility hint for the bottom text view in which decrypted plaintext is displayed.")
        }
    }
    
    // MARK: View Controller Lifecycle
    
    public override func viewDidLoad() {
        super.viewDidLoad()
        
        // Accessibility Labels
        let pickerLabelAxFormat = NSLocalizedString("Choose a cipher type from %lu options below.",
                                                    comment: "Accessibility hint for label above cipher type picker with {n} options to choose from.")
        cipherTypeLabel.accessibilityLabel = String.localizedStringWithFormat(pickerLabelAxFormat, ciphers.count)
        cipherTypePicker.accessibilityLabel = NSLocalizedString("Pick a cipher type.",
                                                              comment: "Accessibility hint for cipher type picker.")
        
        currentKey = defaultKey
        currentShift = defaultShift

        scrollView.indicatorStyle = .white
        
        segmentedControl.setTitle(encryptString, forSegmentAt: 0)
        segmentedControl.setTitle(decryptString, forSegmentAt: 1)
        
        topTextView.delegate = self
        keyOrShiftTextField.delegate = self
        cipherTypePicker.delegate = self
        
        topTextView.layer.borderColor = UIColor.textViewBorderColor.cgColor
        topTextView.layer.borderWidth = 2
        topTextView.tintColor = .textViewCursorColor
        topTextViewLabel.text = plaintextString
        
        bottomTextView.layer.borderColor = UIColor.textViewBorderColor.cgColor
        bottomTextView.layer.borderWidth = 2
        bottomTextView.tintColor = .textViewCursorColor
        bottomTextViewLabel.text = ciphertextString
        
        keyOrShiftTextField.layer.borderColor = UIColor.textViewBorderColor.cgColor
        keyOrShiftTextField.layer.borderWidth = 2
        keyOrShiftTextField.tintColor = .textViewCursorColor
        
        cipherTypeLabel.text = cipherTypeString
        
        // Initial state
        selectMode(isEncrypting: true)
        
        // Start with keyed substituion cipher.
        cipherTypePicker.selectRow(1, inComponent: 0, animated: false)
        selectCipher(cipher: Ciphers.CipherType.substitution)
        
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
    
    // MARK: Actions
    
    // 0 = Encrypt
    // 1 = Decrypt
    @IBAction func encrypterToggled(_ sender: UISegmentedControl) {
        
        selectMode(isEncrypting: sender.selectedSegmentIndex == 0)
    }
    
    // MARK: Custom Methods
    
    private func resetConstraintsForViewSize() {
        segmentedControlTopConstraint.constant = liveViewSafeAreaGuide.layoutFrame.minY + 12
        view.setNeedsUpdateConstraints()
    }
    
    private func updateText() {
        
        var key = currentKey
        if currentlySelectedCipher == .caesar {
            key = currentShift
        }
        
        let text = topTextView.text.removingDiacritics()
        
        if isEncrypting {
            bottomTextView.text = Ciphers.encrypt(cipher: currentlySelectedCipher, plaintext: text, key: key)
        } else {
            bottomTextView.text = Ciphers.decrypt(cipher: currentlySelectedCipher, ciphertext: text, key: key)
        }
    }
    
    // MARK: UI Settings
    
    // No special user config
    // Bacon, Anagram, Nomenclator, none
    private func setNoUserConfigUI() {
        // Hide user-editable fields
        keyOrShiftTextField.isHidden = true
        shiftLabel.isHidden = true
        
        // Reset constraint to pull Ciphertext label up
        //bottomTextViewLabelToKeyConstraint.isActive = false
        //bottomTextViewLabelToPickerConstraint.isActive = true
        bottomTextViewLabelToPickerConstraint.constant = 8
    }    
    // Generate random key
    // Polybius, Playfair
    private func setKeyUserConfigUI() {
        // Show and configure user-editable fields
        keyOrShiftTextField.isHidden = false
        keyOrShiftTextField.text = currentKey
        keyOrShiftTextField.isUserInteractionEnabled = true
        keyOrShiftTextField.keyboardType = .default
        keyOrShiftTextField.autocapitalizationType = .allCharacters
        keyOrShiftTextField.accessibilityHint = axHintForKeyOrShiftTextField
        shiftLabel.isHidden = false
        shiftLabel.text = keyString
        
        // Reset constraint to push Ciphertext label down
        //bottomTextViewLabelToKeyConstraint.isActive = true
        bottomTextViewLabelToPickerConstraint.constant = 83
    }
    
    // Key & Shift
    // Vigenère, Caesar
    private func setShiftUserConfigUI() {
        // Show and configure user-editable fields
        keyOrShiftTextField.isHidden = false
        keyOrShiftTextField.text = String(currentShift)
        keyOrShiftTextField.isUserInteractionEnabled = true
        keyOrShiftTextField.keyboardType = .numberPad
        keyOrShiftTextField.accessibilityHint = axHintForKeyOrShiftTextField
        shiftLabel.isHidden = false
        shiftLabel.text = shiftString
        
        // Reset constraint to push Ciphertext label down
//        bottomTextViewLabelToKeyConstraint.isActive = true
//        bottomTextViewLabelToPickerConstraint.isActive = false
        bottomTextViewLabelToPickerConstraint.constant = 83
    }
    
    private func selectCipher(cipher: Ciphers.CipherType) {
        
        currentlySelectedCipher = cipher
        
        switch currentlySelectedCipher {
        case .bacon, .none:
            setNoUserConfigUI()
        case .substitution, .polybius, .playfair, .vigenere:
            setKeyUserConfigUI()
        case .caesar:
            setShiftUserConfigUI()
        }
        
        updateText()
    }
    
    private func selectMode(isEncrypting: Bool) {
        
        self.isEncrypting = isEncrypting
        
        // Switch over the text
        let topText = topTextView.text
        let bottomText = bottomTextView.text
        topTextView.text = bottomText
        bottomTextView.text = topText
        
        // Switch over the labels
        if isEncrypting {
            topTextViewLabel.text = plaintextString
            bottomTextViewLabel.text = ciphertextString
        } else {
            topTextViewLabel.text = ciphertextString
            bottomTextViewLabel.text = plaintextString
        }
        
        topTextView.accessibilityHint = axHintForTopTextView
        bottomTextView.accessibilityHint = axHintForBottomTextView
        
        // Let VoiceOver know the screen has changed
        UIAccessibility.post(notification: .screenChanged, argument: nil)
    }
}

// MARK: UITextFieldDelegate
extension CryptobotViewController: UITextFieldDelegate {
    
    public func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        
        guard textField == keyOrShiftTextField else { return true }
        
        let currentText = textField.text ?? ""
        let newText = (currentText as NSString).replacingCharacters(in: range, with: string)
        
        // Maximum length
        guard newText.letters.count <= 8 else { return false }
        
        if currentlySelectedCipher == .caesar {
            
            // Digits only
            let allowedCharacterSet = CharacterSet.decimalDigits
            let characterSet = CharacterSet(charactersIn: string)
            guard allowedCharacterSet.isSuperset(of: characterSet) else { return false }
            
            currentShift = newText
            
        } else {
            
            currentKey = newText
        }
        
        updateText()
        
        return true
    }
}

// MARK: UITextViewDelegate
extension CryptobotViewController: UITextViewDelegate {
    
    public func textViewDidChange(_ textView: UITextView) {
        if textView == topTextView {
            updateText()
        }
    }
    
    public func textView(_ textView: UITextView, shouldChangeTextIn range: NSRange, replacementText text: String) -> Bool {
        
        guard textView == topTextView else { return true }
        
        // Ensure that any text that is entered or pasted is uppercase.
        if let lowercaseRange = text.rangeOfCharacter(from: CharacterSet.lowercaseLetters),
            !lowercaseRange.isEmpty {
                textView.text = (textView.text ?? "") + text.uppercased()
                updateText()
                return false
        }
        
        return true
    }
}

// MARK: UIPickerViewDataSource
extension CryptobotViewController: UIPickerViewDataSource {
    
    public func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 1
    }
    
    public func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        return ciphers.count
    }
}

// MARK: UIPickerViewDelegate
extension CryptobotViewController: UIPickerViewDelegate {
    
    public func pickerView(_ pickerView: UIPickerView, attributedTitleForRow row: Int, forComponent component: Int) -> NSAttributedString? {
        
        let title = ciphers[row].name
        return NSAttributedString(string: title, attributes: [.foregroundColor: UIColor.ciphertextBrightGreen])
    }
    
    public func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        
        guard row < ciphers.count else { return }
        
        selectCipher(cipher: ciphers[row])
    }
}
