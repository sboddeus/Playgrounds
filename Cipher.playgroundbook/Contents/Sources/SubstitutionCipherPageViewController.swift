//
//  SubstitutionCipherPageViewController.swift
//
//  Copyright © 2017,2018 Apple Inc. All rights reserved.
//

import UIKit
import PlaygroundSupport

@objc(SubstitutionCipherPageViewController)
class SubstitutionCipherPageViewController: UIViewController {

    // MARK: Properties
    
    @IBOutlet weak var plaintextLabel: UILabel!
    @IBOutlet weak var shiftLabel: UILabel!
    var plaintext = ""
    var pageIndex = 0
    var shiftUsed = 0
    
    // MARK: View Controller LifeCycle
    
    override func viewDidLoad() {
        super.viewDidLoad()

        plaintextLabel.text = plaintext
        shiftLabel.text = String.localizedStringWithFormat(NSLocalizedString("Shift %d", comment:"Shift amount title on each page"), shiftUsed)
        shiftLabel.accessibilityHint = String.localizedStringWithFormat(NSLocalizedString("The page displays the ciphertext, with all letters shifted by %d. Read the ciphertext character by character to determine if this is the correct shift value.", comment:"Accessibility hint for describing the page from the title."), shiftUsed)
    }

}
