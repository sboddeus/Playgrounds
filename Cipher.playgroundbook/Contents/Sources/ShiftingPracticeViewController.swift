//
//  ShiftingPracticeViewController.swift
//
//  Copyright © 2017,2018 Apple Inc. All rights reserved.
//

import UIKit
import PlaygroundSupport

@objc(ShiftingPracticeViewController)
public class ShiftingPracticeViewController: UIViewController, PlaygroundLiveViewSafeAreaContainer {
    
    // MARK: Properties
    
    @IBOutlet weak var inputTitleLabel: UILabel!
    @IBOutlet weak var inputLabel: UILabel!
    @IBOutlet weak var shiftTitleLabel: UILabel!
    @IBOutlet weak var shiftLabel: UILabel!
    @IBOutlet weak var outputTitleLabel: UILabel!
    @IBOutlet weak var outputLabel: UILabel!
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var noteView: UIView!
    @IBOutlet weak var noteCiphertextLabel: UILabel!
    @IBOutlet weak var scrollView: UIScrollView!
    @IBOutlet weak var noteImage: UIImageView!
    @IBOutlet var titleLabels: [UILabel]!
    
    fileprivate let cellId = "basicCell"
    fileprivate var currentShift = 0
    fileprivate var currentWord = ""
    fileprivate let tableHeaderHeight: CGFloat = 32
    fileprivate let processingShiftsString = NSLocalizedString("Processing shifts…", comment: "Shifting table header text.")
    fileprivate var liveViewConnectionOpen = false
    
    // MARK: View Controller Lifecycle
    
    public override func viewDidLoad() {
        super.viewDidLoad()
        
        // Accessibility labels
        noteImage.accessibilityLabel = NSLocalizedString("The note is a page of jumbled letters. You see spaces and punctuation between what might be words, but it is unintelligible.", comment: "Accessibility label describing the ciphertext on the note view.")
        
        // Removes lines in empty cells at the bottom of the tableView
        tableView.tableFooterView = UIView()
        
        //Set localized strings
        inputTitleLabel.text = NSLocalizedString("Input:", comment: "Title label for input section")
        outputTitleLabel.text = NSLocalizedString("Output:", comment: "Title label for output section")
        shiftTitleLabel.text = NSLocalizedString("Shift:", comment: "Title label for shift section")
        noteCiphertextLabel.text = CipherContent.ciphertext
        
        // Take layoutGuides into account
        NSLayoutConstraint.activate([
            scrollView.bottomAnchor.constraint(equalTo: liveViewSafeAreaGuide.bottomAnchor, constant: 0),
            scrollView.topAnchor.constraint(equalTo: liveViewSafeAreaGuide.topAnchor, constant: 20)
        ])
    }
    
    // MARK: Custom Methods

    fileprivate func updateUI() {
        // Hide the noteView now that they’ve started shifting
        noteView.isHidden = true
        // And unhide the rest of the elements!
        // These are individually hidden in IB and show again here so they flatten
        // properly in VoiceOver mode
        for label in titleLabels {
            label.isHidden = false
        }
        
        inputLabel.isHidden = false
        inputLabel.text = currentWord
        shiftLabel.isHidden = false
        shiftLabel.text = String(currentShift)
        outputLabel.isHidden = false
        outputLabel.text = CipherContent.shift(inputText: currentWord, by: currentShift)
        // Forces a reload so if the user chooses a larger number after running, 
        // They visually see the screen update where they otherwise wouldn’t
        tableView.isHidden = false
        tableView.reloadData()
        tableView.reloadSections(IndexSet(integer: 0) as IndexSet, with: UITableView.RowAnimation.fade)
    }
}

extension ShiftingPracticeViewController: PlaygroundLiveViewMessageHandler {
    public func liveViewMessageConnectionOpened() {
        liveViewConnectionOpen = true
    }
    
    public func liveViewMessageConnectionClosed() {
        liveViewConnectionOpen = false
    }
    
    public func receive(_ message: PlaygroundValue) {
        switch message {
        case .dictionary(let shiftDict):
            guard case let .integer(shift)? = shiftDict[Constants.playgroundMessageKeyShift], case let .string(word)? = shiftDict[Constants.playgroundMessageKeyWord] else { return }
            currentWord = word
            currentShift = shift
            updateUI()
        default:
            return
        }
    }
}

extension ShiftingPracticeViewController: UITableViewDelegate {
    public func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return tableHeaderHeight
    }
    
    public func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let headerView = UIView(frame: CGRect(origin: CGPoint(x: 0, y: 0), size:  CGSize(width: tableView.frame.width, height: tableHeaderHeight)))
        headerView.backgroundColor = #colorLiteral(red: 0.156701833, green: 0.1675018072, blue: 0.2093972862, alpha: 1)
        
        let headerLabel = UILabel()
        headerLabel.text = processingShiftsString
        headerLabel.textColor = #colorLiteral(red: 0.2048710883, green: 0.8790110946, blue: 0.205568701, alpha: 1)
        headerLabel.translatesAutoresizingMaskIntoConstraints = false
        
        DispatchQueue.main.async {
            UIView.animate(withDuration: 0.7, delay: 0, options: [.curveEaseInOut, .repeat, .autoreverse], animations: {
                UIView.setAnimationRepeatCount(3.0)
                headerLabel.alpha = 0.0
            }, completion:  { [weak self] completed in
                guard let weakself = self else { return }
                // Only read this aloud if they’ve hit “Run My Code”, otherwise they’re still on the initial page
                if completed && weakself.liveViewConnectionOpen {
                    headerLabel.alpha = 1.0
                    let finishedProcessingString = NSLocalizedString("Finished Processing", comment: "Shifting table header text.")
                    headerLabel.text = finishedProcessingString
                    // Let VoiceOver know the screen has changed, and describe what transpired in the live view
                    let accessibilityIntermediaryText = NSLocalizedString("The live view has processed what you entered, and is now displaying a list of outputs, each one shifted down by one more space, up to the shift count you entered.", comment: "Intermediary text for VoiceOver while the screen is processing.")
                    UIAccessibility.post(notification: .screenChanged, argument: accessibilityIntermediaryText)
                    weakself.send(.string(Constants.playgroundMessageKeySuccess))
                }
            })
        }
        
        let views: [String: AnyObject] = ["header":headerLabel]
        let metrics: [String: AnyObject] = [:]
        headerView.addSubview(headerLabel)
        
        headerView.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "V:|[header]|", options: [], metrics: metrics, views: views))
        headerView.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "H:|-12-[header]|", options: [], metrics: metrics, views: views))
        
        return headerView
    }
}

extension ShiftingPracticeViewController: UITableViewDataSource {
    public func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return abs(currentShift) + 1 //to acount for 0 shift
    }
    
    public func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    public func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: cellId, for: indexPath)
        
        cell.selectionStyle = .none
        var displayShift = 0
        if currentShift >= 0 {
            displayShift = indexPath.row
        } else {
            displayShift = -indexPath.row
        }
        
        let shiftAttributes = [
            NSAttributedString.Key.font: UIFont(name: "Courier", size: 18.0)!,
            NSAttributedString.Key.foregroundColor: UIColor.ciphertextBrightGreen
        ]
        let shiftedWordAttributes = [
            NSAttributedString.Key.font: UIFont(name: "Courier-Bold", size: 18.0)!,
            NSAttributedString.Key.foregroundColor: UIColor.ciphertextBrightGreen
        ]

        let shift = String.localizedStringWithFormat(NSLocalizedString("Shift %d:", comment: "Shift label for each table cell"), displayShift)
        let shiftedWord = CipherContent.shift(inputText: currentWord, by: displayShift)

        let attributedString = NSMutableAttributedString(string: "\(shift) ", attributes: shiftAttributes)
        attributedString.append(NSAttributedString(string: shiftedWord, attributes: shiftedWordAttributes))
        
        cell.textLabel?.attributedText = attributedString
        
        // We want Voice Over to read the shifted words character by character instead of as an unintelligible clump
        // To achieve this, we create a string with commas between each letter
        let shiftedArray = shiftedWord.map { String($0) }
        let axShiftedWord = shiftedArray.joined(separator: ",")
        
        cell.detailTextLabel?.accessibilityLabel = String.localizedStringWithFormat(NSLocalizedString("%@", comment: "Accessibility version of shifted word, with commas between letters."), axShiftedWord)
        
        return cell
    }
}
