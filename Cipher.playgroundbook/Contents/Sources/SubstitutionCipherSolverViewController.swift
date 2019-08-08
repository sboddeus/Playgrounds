//
//  SubstitutionCipherSolverViewController.swift
//
//  Copyright © 2017,2018 Apple Inc. All rights reserved.
//

import UIKit
import PlaygroundSupport

public enum SubstitutionCipherSolverMode {
    case keyedAlphabet
    case decryptOnce
    case decryptPermutations
    case decryptPermutationsUseCommonWords
}

private enum SubstitutionCipherSolverCommand {
    case changeKeyword
    case decrypt
    case decryptPermutationsStart
    case decryptPermutation
    case decryptPermutationsComplete
    case wordCountStart
    case wordCount
    case wordCountComplete
    
    init?(_ command: String) {
        switch command {
        case Constants.playgroundMessageKeyChangeKeyword: self = .changeKeyword
        case Constants.playgroundMessageKeyDecrypt: self = .decrypt
        case Constants.playgroundMessageKeyDecryptPermutationsStart: self = .decryptPermutationsStart
        case Constants.playgroundMessageKeyDecryptPermutation: self = .decryptPermutation
        case Constants.playgroundMessageKeyDecryptPermutationsComplete: self = .decryptPermutationsComplete
        case Constants.playgroundMessageKeyResultsWordCountStart: self = .wordCountStart
        case Constants.playgroundMessageKeyResultsWordCount: self = .wordCount
        case Constants.playgroundMessageKeyResultsWordCountComplete: self = .wordCountComplete
        default: return nil
        }
    }
}

@objc(SubstitutionCipherSolverViewController)
public class SubstitutionCipherSolverViewController: UIViewController, PlaygroundLiveViewSafeAreaContainer {
    
    @IBOutlet weak var cipherTextLabel: UILabel!
    @IBOutlet weak var cipherTextView: UITextView!
    @IBOutlet weak var scrollView: UIScrollView!
    @IBOutlet weak var plainTextLabel: UILabel!
    @IBOutlet weak var plainTextView: UITextView!
    @IBOutlet weak var keysStackView: UIStackView!
    @IBOutlet weak var plainAlphabetLabel: UILabel!
    @IBOutlet weak var alphabetStackView: UIStackView!
    @IBOutlet weak var arrowsStackView: UIStackView!
    @IBOutlet weak var keyedAlphabetLabel: UILabel!
    @IBOutlet weak var keyedAlphabetStackView: UIStackView!
    @IBOutlet weak var progressView: UIProgressView!
    @IBOutlet weak var statusLabel: UILabel!
    @IBOutlet weak var resultsContainerView: UIView!
    @IBOutlet weak var keysScrollView: UIScrollView!
    @IBOutlet weak var popupMessageLabel: PopupLabel!
    @IBOutlet weak var progressAndResultsView: UIView!
    
    var resultsTableViewController: UITableViewController?
    
    var resultsContainerViewHeightConstraint = NSLayoutConstraint()
    var savedViewSize = CGSize()
    let resultsContainerViewMinimumHeight = CGFloat(280)

    private var progressTimer: Timer?
    private var popupMessageTimer: Timer?
    
    // Pop-up messages
    var popupMessages = [
        NSLocalizedString("These are the results of decrypting with each possible keyword. You can scroll through them when your code is done.",
                          comment: "Trying All the Possibilities pop-up message #1"),
        NSLocalizedString("Brute force decryption involves checking every possible combination of letters—it can take a while.",
                          comment: "Trying All the Possibilities pop-up message #2"),
        NSLocalizedString("Think this is taking forever?! Well just imagine how long it would have taken to do this by hand!",
                          comment: "Trying All the Possibilities pop-up message #3"),
        NSLocalizedString("If there were 12 letters in the key there would be 479,001,600 possible letter combinations and your code would take several weeks to check them all!",
                          comment: "Trying All the Possibilities pop-up message #4"),
        NSLocalizedString("Cryptographers use faster code and parallel processing. They would `crack` a 7-letter keyword like this in under a second!",
                          comment: "Trying All the Possibilities pop-up message #5")
    ]
    var popupMessageIndex = 0
    let popupMessageDisplayDuration = 10.0
    let popupMessageMinimumInterval = 15.0
    
    private let cellReuseIdentifer = "SubstitutionSolverResultCell"
    
    public var mode: SubstitutionCipherSolverMode = .keyedAlphabet
    
    var maxCommonWordCount = 0
    var isWordCountComputed = false
    
    // Trials
    var trials = [SubstitutionSolverResult]()
    var trialCount = 0
    let maxTrials = 10100 // The maximum number of trials permitted.
    
    // Permutation processing
    var numberOfPermutations = 0.0
    var updateIntervalCount = 25
    var startDate = Date()
    var lastAnnouncementDate = Date()
    var timeInterval = 0.0
    
    // Alphabet controls
    var alphabetLabels = [LetterLabel]()
    var arrowsLabels = [UILabel]()
    var trialAlphabetLabels = [LetterLabel]()
    var trialKeyLabels = [LetterLabel]()
    var alphabetLockButtons = [UIButton]()
    
    var isRunning = false
    
    // Alphabet used as the basis for encryption and for keyed alphabet.
    let alphabet = Ciphers.uppercaseAlphabet
    
    // Encryption key.
    let key = Ciphers.cipherTwoKey
    let shuffledKey = Ciphers.cipherTwoKeyShuffled
    
    // Trial alphabet is the current keyed alphabet being tried.
    var trialAlphabet: String = "" {
        
        didSet {
            
            for (i, letter) in trialAlphabet.letters.enumerated() {
                
                guard i < trialAlphabetLabels.count else { return }
                guard i < alphabetLabels.count else { return }
                
                // Update colors.
                let label = trialAlphabetLabels[i]
                label.letter = letter
                label.isPartOfKey = (i < trialKey.letters.count)
                label.setNeedsDisplay()
                
                // Update accessibility labels.
                var format = NSLocalizedString("Letter %@ becomes %@)",
                                               comment: "Accessibility label: {letter in keyed alphabet} becomes {letter in plain alphabet")
                if i < trialKey.letters.count {
                    format = NSLocalizedString("Key letter %@ becomes %@)",
                                                   comment: "Accessibility label: {key letter in keyed alphabet} becomes {letter in plain alphabet")
                }
                label.accessibilityLabel = String.localizedStringWithFormat(format, letter, alphabet.letters[i])
                
                let alphabetLabel = alphabetLabels[i]
                format = NSLocalizedString("Letter %@ was %@", comment: "Accessibility label for letter in plain alphabet")
                alphabetLabel.accessibilityLabel = String.localizedStringWithFormat(format, alphabetLabel.letter, letter)
            }
        }
    }
    
    var trialKey: String = ""
    
    // Reduced alphabet is the remainder of the keyed alphabet after the key
    var reducedAlphabet: String {
        let keyedAlphabet = Ciphers.getKeyedAlphabet(from: Ciphers.uppercaseAlphabet, with: trialKey)
        return keyedAlphabet.replacingOccurrences(of: trialKey, with: "")
    }
    
    // Encrypted text
    var cipherText: String = "" {
        
        didSet {
            cipherTextView.text = cipherText
            let format = NSLocalizedString("Cipher text: %@",
                                           comment: "Accessibility label for cipherText: {cipherText}")
            cipherTextView.accessibilityLabel = String.localizedStringWithFormat(format, cipherText.letterByLetterForVoiceOver())
            cipherTextView.accessibilityValue = ""
        }
    }
    
    // Decrypted text
    var plainText: String = "" {
        
        didSet {
            plainTextView.text = plainText
            plainTextView.accessibilityLabel = accessibilityLabelForPlainText
            plainTextView.accessibilityValue = ""
        }
    }
    
    var accessibilityLabelForPlainText: String {
        if isRunning {
            return NSLocalizedString("Plain text changes each time a new keyword is tried",
                                     comment: "Accessibility label for plain text while trying keys")
        } else {
            let format = NSLocalizedString("Plain text: %@", comment: "Accessibility label for plainText: {plainText}")
            return String.localizedStringWithFormat(format, plainText)
        }
    }
    
    // MARK: View Controller Lifecycle
    
    override public func viewDidLoad() {
        super.viewDidLoad()
        
        isRunning = false
        
        cipherTextLabel.accessibilityLabel = NSLocalizedString("Cipher text below",
                                                               comment: "Accessibility label for cipher text label")
        
        keyedAlphabetLabel.accessibilityLabel = NSLocalizedString("Keyed alphabet below",
                                                                  comment: "Accessibility label for keyed alphabet label")
        keyedAlphabetStackView.isAccessibilityElement = false
        
        arrowsStackView.isAccessibilityElement = true
        arrowsStackView.accessibilityLabel = NSLocalizedString("Each letter in the keyed alphabet above is joined to a letter in the plaintext alphabet below.",
                          comment: "Accessibility label for arrows between keyed and plaintext alphabets.")
        
        alphabetStackView.isAccessibilityElement = false
        let plainAlphabetFormat = NSLocalizedString("Plain alphabet: %@",
                                                    comment: "Accessibility label for plain alphabet: {plain alphabet}")
        alphabetStackView.accessibilityLabel = String.localizedStringWithFormat(plainAlphabetFormat, alphabet.letterByLetterForVoiceOver())
        
        plainAlphabetLabel.accessibilityLabel = NSLocalizedString("Plain alphabet above",
                                                                  comment: "Accessibility label for plain alphabet label")
        
        plainTextLabel.accessibilityLabel = NSLocalizedString("Plain text below",
                                                              comment: "Accessibility label for plain text label")
        
        resultsTableViewController?.tableView.accessibilityLabel = NSLocalizedString("Results of decrypting each letter combination",
            comment: "Accessibility label for results table view")
        
        cipherTextView.backgroundColor = view.backgroundColor
        cipherTextView.layer.borderColor = UIColor.textViewBorderColor.cgColor
        cipherTextView.layer.borderWidth = 2
        plainTextView.backgroundColor = view.backgroundColor
        plainTextView.layer.borderColor = UIColor.textViewBorderColor.cgColor
        plainTextView.layer.borderWidth = 2
        
        // Hide results table initially.
        resultsContainerView.isHidden = true
        
        cipherText = Ciphers.cipherTwoCiphertext
        
        let trialAlphabet = Ciphers.getKeyedAlphabet(from: alphabet, with: shuffledKey)

        for (i, letter) in alphabet.letters.enumerated() {
            let label = LetterLabel()
            label.index = i
            label.letter = letter
            label.isPlaintext = true
            label.isAccessibilityElement = true
            alphabetStackView.addArrangedSubview(label)
            alphabetStackView.distribution = .fillEqually
            alphabetLabels.append(label)
        }
        
        for _ in alphabet.letters.enumerated() {
            let label = UILabel()
            label.text = "↓"
            label.textColor = .downArrowsColor
            label.font = .downArrowsFont
            label.textAlignment = .center
            label.isAccessibilityElement = false
            arrowsStackView.addArrangedSubview(label)
            arrowsLabels.append(label)
        }
        
        for (i, letter) in trialAlphabet.letters.enumerated() {
            let label = LetterLabel()
            label.index = i
            label.letter = letter
            label.isAccessibilityElement = true
            if i < key.letters.count {
                label.isPartOfKey = true
                trialKeyLabels.append(label)
            }
            keyedAlphabetStackView.addArrangedSubview(label)
            keyedAlphabetStackView.distribution = .fillEqually
            trialAlphabetLabels.append(label)
        }
        
        // Force initial update of accessibility labels.
        tryKey(key: shuffledKey, on: cipherText)
        
        switch mode {
            
        case .keyedAlphabet:
            plainTextView.isHidden = true
            plainTextLabel.isHidden = true
            statusLabel.isHidden = true
            resultsContainerView.isHidden = true
            
        case .decryptOnce:
            plainTextView.text = ""
            statusLabel.isHidden = true
            resultsContainerView.isHidden = true
            
        case .decryptPermutations, .decryptPermutationsUseCommonWords:
            
            if trials.restoreFromKeyValueStore() {
                
                trials.sortByIndex()
                
                resultsContainerView.isHidden = false
                
                selectFirstResultInTable(reload: true)
            }
        }

        // Allow margin between scroll view and live view buttons.
        let insets = UIEdgeInsets(top: 0, left: 0, bottom: 10, right: 0)
        scrollView.contentInset = insets

        // Constrain the content within the `liveViewSafeAreaGuide`.
        NSLayoutConstraint.activate( [
            scrollView.topAnchor.constraint(equalTo: liveViewSafeAreaGuide.topAnchor, constant: 0),
            scrollView.bottomAnchor.constraint(equalTo: liveViewSafeAreaGuide.bottomAnchor, constant: 0),
            scrollView.leftAnchor.constraint(equalTo: liveViewSafeAreaGuide.leftAnchor, constant: 0),
            scrollView.rightAnchor.constraint(equalTo: liveViewSafeAreaGuide.rightAnchor, constant: 0)
            ] )
        
        // Set up constraint to control height of results table.
        resultsContainerViewHeightConstraint = resultsContainerView.heightAnchor.constraint(equalToConstant: 0)
        NSLayoutConstraint.activate( [resultsContainerViewHeightConstraint] )
    }
    
    override public func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        if !resultsContainerView.isHidden {
            selectFirstResultInTable(reload: false)
        }
    }
    
    public override func viewWillLayoutSubviews() {
        super.viewWillLayoutSubviews()
        
        if view.frame.size != savedViewSize {
            // Update the height constraint for the results container if the view size has changed.
            // The liveViewSafeAreaGuide height changes when the shortcut bar or keyboard appears. In this case the view
            // does not change size and the results container should remain the same height, allowing the view to scroll.
            let progressViewFrame = view.convert(progressView.frame, from: progressView)
            let availableHeight = max(liveViewSafeAreaGuide.layoutFrame.maxY - progressViewFrame.maxY, resultsContainerViewMinimumHeight)
            resultsContainerViewHeightConstraint.constant = availableHeight
            view.setNeedsUpdateConstraints()
            savedViewSize = view.frame.size
        }
    }
    
    override public func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if (segue.identifier == "ResultsViewControllerSegue")
        {
            if let viewController = segue.destination as? UITableViewController {
                resultsTableViewController = viewController
                resultsTableViewController?.tableView.register(SubstitutionSolverResultTableViewCell.self, forCellReuseIdentifier: cellReuseIdentifer)
                resultsTableViewController?.tableView.delegate = self
                resultsTableViewController?.tableView.dataSource = self
                resultsTableViewController?.tableView.estimatedRowHeight = 80
                resultsTableViewController?.tableView.rowHeight = UITableView.automaticDimension
            }
        }
    }
    
    // MARK: Custom Methods
    
    private func tryKey(key: String, on cipherText: String) {
        
        trialKey = key
        let trialKeyedAlphabet = Ciphers.getKeyedAlphabet(from: Ciphers.uppercaseAlphabet, with: trialKey)
        let alphabetLetters = Ciphers.uppercaseAlphabet.letters
        
        let trialDecrypytedText = cipherText.monoalphabeticallySubstituting(alphabet: alphabetLetters, for: trialKeyedAlphabet.letters)
        
        trialAlphabet = trialKeyedAlphabet
        plainText = trialDecrypytedText
    }
    
    private func displayKeyPermutation(index: Int, key: String, decrypytedText: String, commonWordCount: Int = 0) {
        
        let keyedAlphabet = key + reducedAlphabet
        
        // Keep trials from getting too big
        if trials.count >= maxTrials {
            trials.removeFirst(100)
        }
        
        let trial = SubstitutionSolverResult(index: index, keyword: key, text: decrypytedText, count: commonWordCount)
        
        trials.append(trial)
        
        DispatchQueue.main.async {
            self.trialAlphabet = keyedAlphabet
            self.plainText = decrypytedText
        }
    }
    
    private func showProgressBar() {
        progressView.alpha = 0.6
    }
    
    private func hideProgressBar() {
        progressView.alpha = 0.0
    }
    
    private func estimatedProcessingTimeRemaining() -> TimeInterval {
        timeInterval = Date().timeIntervalSince(startDate)
        return (numberOfPermutations - Double(trialCount)) * timeInterval/Double(trialCount)
    }
    
    // Set up permutation processing
    private func startPermutations() {
        
        statusLabel.text = ""
        
        trials = []
        trialCount = 0
        popupMessageIndex = 0
        
        startDate = Date()
        lastAnnouncementDate = Date()
        timeInterval = 0.0
        
        isRunning = true
        showProgressBar()
        
        if UIAccessibility.isVoiceOverRunning {
            UIAccessibility.post(notification: .announcement, argument:
                                            NSLocalizedString("Trying keywords.",
                                                              comment: "Accessibility label starting to try decrypting keywords"))
        }
        
        // Change accessibility labels while running.
        keyedAlphabetStackView.isAccessibilityElement = true
        keyedAlphabetStackView.accessibilityLabel = NSLocalizedString("Keyed alphabet changes each time a new keyword is tried",
                                                               comment: "Accessibility label for keyed alphabet while trying keywords")
        plainTextView.accessibilityLabel = accessibilityLabelForPlainText
    }
    
    // Update permutation processing progress.
    private func updatePermutationsProgress() {
        
        guard (trialCount > 0) && (trialCount % updateIntervalCount == 0) else { return }
        
        DispatchQueue.main.async {
            
            UIView.performWithoutAnimation {
                let format = "%d of %d keywords tried"
                self.statusLabel.text = String.localizedStringWithFormat(format, self.trialCount, Int(self.numberOfPermutations))
                self.statusLabel.layoutIfNeeded()
            }
            
            if UIAccessibility.isVoiceOverRunning {
                if Date().timeIntervalSince(self.lastAnnouncementDate) > 5.0 {
                    UIAccessibility.post(notification: .announcement, argument: self.statusLabel.text)
                    self.lastAnnouncementDate = Date()
                }
            }
            
            self.progressView.progress = Float(Double(self.trialCount) / self.numberOfPermutations)
            
            // Reveal results if they were hidden.
            if self.resultsContainerView.isHidden {
                self.resultsContainerView.alpha = 0
                self.resultsContainerView.isHidden = false
                UIView.animate(withDuration: 0.25,
                               animations: {
                                self.resultsContainerView.alpha = 1
                                })
            }
            
            self.resultsTableViewController?.tableView.reloadData()
        }
    }
    
    // Complete permutation processing and display results
    private func completePermutations(sorted: Bool = false) {
        
        isRunning = false
        
        // Reset accessibility labels after running
        keyedAlphabetStackView.isAccessibilityElement = false
        plainTextView.accessibilityLabel = accessibilityLabelForPlainText
        
        hideProgressBar()
        
        let timeFormatter = DateComponentsFormatter()
        timeFormatter.unitsStyle = .full
        
        let timeInterval = Date().timeIntervalSince(startDate)
        if let timeIntervalString = timeFormatter.string(from: timeInterval) {
            
            let format = NSLocalizedString("%d keywords tried in %@", comment: "{n} keywords tried in {time period}")
            statusLabel.text = String.localizedStringWithFormat(format, trialCount, timeIntervalString)
            
            if UIAccessibility.isVoiceOverRunning {
                UIAccessibility.post(notification: .announcement, argument: statusLabel.text)
            }
        }
        
        if sorted {
            trials.sortByCount()
        }
        
        DispatchQueue.global().async {
            self.trials.saveToKeyValueStore()
        }
        
        selectFirstResultInTable(reload: true)
    }
    
    private func selectFirstResultInTable(reload: Bool = false, animated: Bool = false) {
        
        DispatchQueue.main.async {
            
            guard let tableView = self.resultsTableViewController?.tableView else { return }
            
            tableView.reloadData()
            
            let indexpath = IndexPath(row: 0, section: 0)
            tableView.selectRow(at: indexpath, animated: animated, scrollPosition: .top)
            self.tableView(tableView, didSelectRowAt: indexpath)
        }
    }

    // MARK: Pop-up messages
    
    private func startPopupMessages() {
        stopPopupMessages()
        
        guard isRunning else { return }
        
        // Work out how often we should show a pop-up message based on estimated processing time.
        var popupMessageInterval = popupMessageMinimumInterval
        let estimatedTime = estimatedProcessingTimeRemaining()
        if estimatedTime > (popupMessageMinimumInterval * Double(popupMessages.count)) {
            popupMessageInterval = (estimatedTime * 0.9) / Double(popupMessages.count)
        }
        
        // Show the first pop-up message.
        updatePopupMessage()
        
        // Kick off a timer for subsequent pop-up messages.
        popupMessageTimer = Timer.scheduledTimer(withTimeInterval: popupMessageInterval, repeats: true, block: { _ in
            self.updatePopupMessage()
        })
    }
    
    private func stopPopupMessages() {
        popupMessageTimer?.invalidate()
        popupMessageTimer = nil
    }
    
    private func updatePopupMessage() {
        guard popupMessageIndex < popupMessages.count else { return }
        
        let message = popupMessages[popupMessageIndex]
        popupMessageIndex += 1
        
        DispatchQueue.main.async {
            self.showPopupMessage(text: message)
        }
    }
    
    private func showPopupMessage(text: String) {
        popupMessageLabel.text = text
        popupMessageLabel.preferredMaxLayoutWidth = min(400, view.frame.width * 0.7)
        popupMessageLabel.isHidden = false
        popupMessageLabel.alpha = 0.0
        popupMessageLabel.transform = CGAffineTransform(scaleX: 0.01, y: 0.01)

        UIView.animate(withDuration: 0.75, delay: 0,
                       usingSpringWithDamping: 0.5,
                       initialSpringVelocity: 0.2,
                       options: [.curveEaseInOut, .allowUserInteraction],
                       animations: {

            self.popupMessageLabel.alpha = 1.0
            self.popupMessageLabel.transform = CGAffineTransform(scaleX: 1.0, y: 1.0)

        }, completion: { _ in
            if UIAccessibility.isVoiceOverRunning {
                UIAccessibility.post(notification: .screenChanged, argument: self.popupMessageLabel)
            }
            
            DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + self.popupMessageDisplayDuration, execute: {
                self.hidePopupMessage()
            })
        })
        
        playSound(.pageFlip)
    }
    
    private func hidePopupMessage() {
        UIView.animate(withDuration: 0.75, delay: 0,
                       usingSpringWithDamping: 0.75,
                       initialSpringVelocity: 0.2,
                       options: [.curveEaseInOut, .allowUserInteraction],
                       animations: {

                        self.popupMessageLabel.alpha = 0.0
                        self.popupMessageLabel.transform = CGAffineTransform(scaleX: 0.01, y: 0.01)

        }, completion: { _ in
            self.popupMessageLabel.isHidden = true
            self.popupMessageLabel.transform = CGAffineTransform(scaleX: 1.0, y: 1.0)
            
            if UIAccessibility.isVoiceOverRunning {
                UIAccessibility.post(notification: .screenChanged, argument: self.statusLabel)
            }
        })
    }
    
    @IBAction func onPopupMessageTapped(_ sender: UITapGestureRecognizer) {
        hidePopupMessage()
    }

    // MARK: Page command handling
    
    private func startingInvestigationHandleCommand(_ command: SubstitutionCipherSolverCommand, withParameters parameters: [String: PlaygroundValue]) {
        
        guard command == .changeKeyword else { return }
        
        guard case let .string(keyword)? = parameters[Constants.playgroundMessageKeyKeyword] else { return }
        
        let cleanKeyword = Ciphers.cleanedText(text: keyword, maxLength: Ciphers.maxLettersInKey, allowableLetters: Ciphers.cipherTwoKey, removeDuplicates: true)
        if cleanKeyword.count < Ciphers.cipherTwoKey.count {
            send(.dictionary([
                Constants.playgroundMessageKeyError : PlaygroundValue.boolean(true),
                Constants.playgroundMessageKeyKeyword : PlaygroundValue.string(cleanKeyword)
                ]))
            return
        }
        
        tryKey(key: cleanKeyword, on: cipherText)
        
        playSound(.dataProcessing)
        
        // Notify the page that we’re done.
        send(.dictionary([
            Constants.playgroundMessageKeyCompleted : PlaygroundValue.boolean(true),
            Constants.playgroundMessageKeyKeyword : PlaygroundValue.string(cleanKeyword)
            ]))

    }
    
    private func decryptingCiphertextHandleCommand(_ command: SubstitutionCipherSolverCommand, withParameters parameters: [String: PlaygroundValue]) {
        
        guard command == .decrypt else { return }
        
        guard case let .string(keyword)? = parameters[Constants.playgroundMessageKeyKeyword],
            case let .string(plaintext)? = parameters[Constants.playgroundMessageKeyPlaintext]
            else { return }
        
        let cleanKeyword = Ciphers.cleanedText(text: keyword, maxLength: Ciphers.maxLettersInKey, removeDuplicates: true)
        if cleanKeyword.isEmpty {
            send(.dictionary([
                Constants.playgroundMessageKeyError : PlaygroundValue.boolean(true),
                Constants.playgroundMessageKeyKeyword : PlaygroundValue.string(cleanKeyword)
                ]))
            return
        }
        
        tryKey(key: keyword, on: cipherText)
        plainTextView.text = plaintext
        
        playSound(.dataProcessing)
        
        // Notify the page that we’re done.
        send(.dictionary([
            Constants.playgroundMessageKeyCompleted : PlaygroundValue.boolean(true),
            Constants.playgroundMessageKeyKeyword : PlaygroundValue.string(cleanKeyword),
            Constants.playgroundMessageKeyPlaintext : PlaygroundValue.string(plaintext)
            ]))
        
    }
    
    private func tryingAllPossibilitiesHandleCommand(_ command: SubstitutionCipherSolverCommand, withParameters parameters: [String: PlaygroundValue]) {
        
        switch command {
        
        case .decryptPermutationsStart:
            
            if case let .string(keyword)? = parameters[Constants.playgroundMessageKeyKeyword] {
                startPermutations()
                numberOfPermutations = Double.factorial(n: keyword.letters.count)
            }
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 5.0) {
                self.startPopupMessages()
            }
        
        case .decryptPermutation:
            
            guard
                case let .string(keyword)? = parameters[Constants.playgroundMessageKeyKeyword],
                case let .string(plaintext)? = parameters[Constants.playgroundMessageKeyPlaintext]
                else { return }
            
            if plaintext.isEmpty || plaintext.hasPrefix("*") {
                
                isRunning = false
                hideProgressBar()
                
                hidePopupMessage()
                stopPopupMessages()
                
                send(.dictionary([
                    Constants.playgroundMessageKeyError : PlaygroundValue.boolean(true),
                    Constants.playgroundMessageKeyPlaintext : PlaygroundValue.string(plaintext)
                    ]))
                return
            }
            
            var commonWordCount = 0
            if case let .integer(count)? = parameters[Constants.playgroundMessageKeyCount] {
                commonWordCount = count
            }
            
            displayKeyPermutation(index: trialCount, key: keyword, decrypytedText: plaintext, commonWordCount: commonWordCount)
            updatePermutationsProgress()
            trialCount += 1
        
        case .decryptPermutationsComplete:
            
            var isSorted = false
            if case let .boolean(sorted)? = parameters[Constants.playgroundMessageKeySorted] {
                isSorted = sorted
            }
            completePermutations(sorted: isSorted)
            
            hidePopupMessage()
            stopPopupMessages()
            
            send(.dictionary([
                Constants.playgroundMessageKeyCompleted : PlaygroundValue.boolean(true)
                ]))
            
            DispatchQueue.main.async {
                playSound(.dataProcessing)
            }
            
        default:
            return
        }
    }
    
    private func sortingResultsHandleCommand(_ command: SubstitutionCipherSolverCommand, withParameters parameters: [String: PlaygroundValue]) {
        
        switch command {
        
        case .wordCountStart:
            
            guard trials.count > 0 else {
                send(.dictionary([
                    Constants.playgroundMessageKeyError : PlaygroundValue.boolean(true),
                    Constants.playgroundMessageKeyCount : PlaygroundValue.integer(trials.count)
                    ]))
                return
            }
            
            // Reset in case it’s already been sorted by Count.
            trials.sortByIndex()
            self.selectFirstResultInTable(reload: true, animated: true)
            
            statusLabel.text = NSLocalizedString("Counting common words in results...",
                                                 comment: "Progress message for counting common words in results.")
            showProgressBar()
            statusLabel.text = ""
            progressView.progress = 0
            
            if UIAccessibility.isVoiceOverRunning {
                UIAccessibility.post(notification: .announcement, argument: self.statusLabel.text)
            }
            
            isWordCountComputed = false
        
        case .wordCount:
            
            if case let .integer(index)? = parameters[Constants.playgroundMessageKeyIndex],
                case let .integer(count)? = parameters[Constants.playgroundMessageKeyCount],
                index < trials.count
            {
                let progressFormat = NSLocalizedString("Counting common words for result %@",
                                                       comment: "Progress message for counting {n} words.")
                
                statusLabel.text = String.localizedStringWithFormat(progressFormat, String(index + 1))
                statusLabel.layoutIfNeeded()
                
                progressView.progress = Float(index) / Float(trials.count)
                
                trials[index].count = count
            }
        
        case .wordCountComplete:
            
            guard trials.count > 0 else { return }
            
            hideProgressBar()
            statusLabel.text = ""
            
            guard
                case let .integer(resultsCount)? = parameters[Constants.playgroundMessageKeyCount],
                case let .integer(totalWordCount)? = parameters[Constants.playgroundMessageKeyTotalWordCount],
                resultsCount > 0,
                totalWordCount > 0
                else {
                    send(.dictionary([
                        Constants.playgroundMessageKeyError : PlaygroundValue.boolean(true),
                        Constants.playgroundMessageKeyResultsWordCountComplete : PlaygroundValue.boolean(false)
                        ]))
                    return
            }
            
            isWordCountComputed = true
            self.selectFirstResultInTable(reload: true, animated: true)
            
            statusLabel.text = NSLocalizedString("Counting words complete.",
                                                 comment: "Completion message for counting words.")
            
            if UIAccessibility.isVoiceOverRunning {
                UIAccessibility.post(notification: .announcement, argument: self.statusLabel.text)
            }
            
            guard
                case let .boolean(sortComplete)? = parameters[Constants.playgroundMessageKeyResultsSortComplete],
                sortComplete
                else {
                    send(.dictionary([
                        Constants.playgroundMessageKeyError : PlaygroundValue.boolean(true),
                        Constants.playgroundMessageKeyResultsSortComplete : PlaygroundValue.boolean(false)
                        ]))
                    return
            }
            
            // Simulate sorting progress.
            self.statusLabel.text = NSLocalizedString("Sorting results by word count...",
                                                      comment: "Progress message for sorting results by word count.")
            self.statusLabel.setNeedsDisplay()
            
            if UIAccessibility.isVoiceOverRunning {
                UIAccessibility.post(notification: .announcement, argument: self.statusLabel.text)
            }
            
            progressView.progress = 0.0
            showProgressBar()
            
            DispatchQueue.main.async {
                
                // Simulate progress bar completion.
                self.progressView.layoutIfNeeded()
                
                self.progressView.progress = 1.0
                UIView.animate(withDuration: 2.5,
                               delay: 0.0,
                               options: UIView.AnimationOptions.curveLinear,
                               animations: {
                                self.progressView.layoutIfNeeded()
                }, completion: { _ in
                    
                    self.hideProgressBar()
                    
                    self.statusLabel.text = NSLocalizedString("Sorting results complete.",
                                                              comment: "Completion message for sorting results.")
                    
                    if UIAccessibility.isVoiceOverRunning {
                        UIAccessibility.post(notification: .announcement, argument: self.statusLabel.text)
                    }
                    
                    self.trials.sortByCount()
                    self.selectFirstResultInTable(reload: true, animated: true)
                    
                    DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + 0.5, execute: {
                        
                        self.send(.dictionary([
                            Constants.playgroundMessageKeyCompleted : PlaygroundValue.boolean(true)
                            ]))
                        
                        playSound(.dataProcessing)
                    })
                })
            }
            
        default:
            return
        }
    }
    
}

// MARK: UITableViewDataSource
extension SubstitutionCipherSolverViewController: UITableViewDataSource {
    
    public func numberOfSections(in tableView: UITableView) -> Int {
        
        return 1
    }
    
    public func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return trials.count
    }
    
    public func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let cell = tableView.dequeueReusableCell(withIdentifier: cellReuseIdentifer, for: indexPath) as! SubstitutionSolverResultTableViewCell
        
        guard indexPath.row < trials.count else { return cell }
        
        cell.result = trials[trials.count - indexPath.row - 1]
        cell.isWordCountEnabled = (mode == .decryptPermutationsUseCommonWords) && isWordCountComputed
        
        return cell
    }
}

// MARK: UITableViewDelegate
extension SubstitutionCipherSolverViewController: UITableViewDelegate {
    
    public func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        guard indexPath.row < trials.count else { return }
        
        let index = trials.count - indexPath.row - 1
        let keyedAlphabet = Ciphers.getKeyedAlphabet(from: Ciphers.uppercaseAlphabet, with: trials[index].keyword)
        trialAlphabet = keyedAlphabet
        plainText = trials[index].text
    }
    
}

// MARK: PlaygroundLiveViewMessageHandler
extension SubstitutionCipherSolverViewController: PlaygroundLiveViewMessageHandler {
    
    public func liveViewMessageConnectionClosed() {
        stopPopupMessages()
    }
    
    public func receive(_ message: PlaygroundValue) {
        
        guard
            case let .dictionary(dict) = message,
            case let .string(commandValue)? = dict[Constants.playgroundMessageKeyCommand],
            let command = SubstitutionCipherSolverCommand(commandValue)
            else { return }
        
        // Direct command to appropriate page handler.
        switch command {
            
        case .changeKeyword:
            
            startingInvestigationHandleCommand(command, withParameters: dict)
            
        case .decrypt:
            
            decryptingCiphertextHandleCommand(command, withParameters: dict)
            
        case .decryptPermutationsStart,
             .decryptPermutation,
             .decryptPermutationsComplete:
            
            tryingAllPossibilitiesHandleCommand(command, withParameters: dict)
            
        case .wordCountStart,
             .wordCount,
             .wordCountComplete:
            
            sortingResultsHandleCommand(command, withParameters: dict)
        }
    }
}


