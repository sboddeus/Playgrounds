//
//  SolverTrialTableViewCell.swift
//
//  Copyright © 2017,2018 Apple Inc. All rights reserved.
//

import UIKit

class SubstitutionSolverResultTableViewCell: UITableViewCell {
        
    var result: SubstitutionSolverResult? {
        didSet { update() }
    }
    
    var isWordCountEnabled = false {
        didSet { update() }
    }
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private let resultTitleAttributes = [
        NSAttributedString.Key.font: UIFont.solverResultTitleFont,
        NSAttributedString.Key.foregroundColor: UIColor.solverResultTitleColor
    ]
    private let resultTextAttributes = [
        NSAttributedString.Key.font: UIFont.solverResultTextFont,
        NSAttributedString.Key.foregroundColor: UIColor.solverResultTextColor
    ]
        
    private func update() {
        
        guard let result = self.result else { return }
        
        let keyword = result.keyword
        
        let trialIndex = String(result.index + 1)   // Convert to string here because we’d rather not have thousands separator.
        
        var titleFormat = NSLocalizedString("Result %@ with keyword '%@'",
                                            comment: "Result {number} with {keyword}")
        var title = String.localizedStringWithFormat(titleFormat, trialIndex, keyword)
        var accessibilityTitle = String.localizedStringWithFormat(titleFormat, trialIndex, keyword.letterByLetterForVoiceOver())
        
        if isWordCountEnabled {
            titleFormat += NSLocalizedString(" has %d common words.",
                                             comment: "has {count} common words.")
            title = String.localizedStringWithFormat(titleFormat, trialIndex, keyword, result.count)
            accessibilityTitle = String.localizedStringWithFormat(titleFormat, trialIndex, keyword.letterByLetterForVoiceOver(), result.count)
        }
        
        let attributedString = NSMutableAttributedString()
        attributedString.append(NSAttributedString(string: title, attributes: resultTitleAttributes))
        attributedString.append(NSAttributedString(string: "\n"))
        attributedString.append(NSAttributedString(string: result.text, attributes: resultTextAttributes))
        
        textLabel?.attributedText = attributedString
        textLabel?.numberOfLines = 0
        
        let accessibilityLabelFormat = NSLocalizedString("%@. Plain text: %@",
                                                         comment: "{result title}. Plain text: {plain text}")
        textLabel?.accessibilityLabel = String.localizedStringWithFormat(accessibilityLabelFormat, accessibilityTitle, result.text)
    }

}
