//
//  HotspotViewController.swift
//  
//  Copyright © 2016-2019 Apple Inc. All rights reserved.
//

import UIKit

class HotspotViewController: UIViewController {
    let textView = UITextView()
    private let widthLimit: CGFloat = 420
    private var maximumWidth: CGFloat = 200
    private let margins = NSDirectionalEdgeInsets(top: 8, leading: 8, bottom: 8, trailing: 8)
    
    var attributedString: NSAttributedString = NSAttributedString() {
        didSet {
            textView.attributedText = attributedString
        }
    }
    
    // A closure to be called when the view controller is dismissed.
    var onDismissed : (() -> Void)?
    
    override var preferredContentSize: CGSize {
        get {
            let textViewSize = textView.sizeThatFits(CGSize(width: maximumWidth, height: CGFloat.greatestFiniteMagnitude))
            return textViewSize
        }
        set { super.preferredContentSize = newValue }
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.directionalLayoutMargins = margins
        textView.textContainerInset = view.layoutMargins
        textView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        textView.isEditable = false
        textView.isSelectable = true
        textView.isScrollEnabled = false
        textView.isAccessibilityElement = true
        textView.accessibilityTraits = .staticText
        textView.frame = view.bounds
        view.addSubview(textView)
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        onDismissed?()
    }
    
    static func present(attributedString: NSAttributedString, from viewController: UIViewController, sourceRect: CGRect, sourceView: UIView) {
        let hotspotViewController = HotspotViewController()
        hotspotViewController.modalPresentationStyle = UIModalPresentationStyle.popover
        hotspotViewController.attributedString = attributedString
        
        hotspotViewController.maximumWidth = min(viewController.view.frame.width * 0.6, hotspotViewController.widthLimit)
        
        let arrowGapInset: CGFloat = -4 // Gap between arrow and sourceRect.
        
        // Specify the location and arrow direction of the popover.
        let popoverPresentationController = hotspotViewController.popoverPresentationController
        popoverPresentationController?.backgroundColor = hotspotViewController.view.backgroundColor
        popoverPresentationController?.sourceView = sourceView
        let permittedArrowDirections: UIPopoverArrowDirection = [.any]
        popoverPresentationController?.permittedArrowDirections = permittedArrowDirections
        popoverPresentationController?.sourceRect = sourceRect.insetBy(dx: arrowGapInset, dy: arrowGapInset)
        
        hotspotViewController.onDismissed = {
            // On dismissal set the AX focus back to the image block.
            UIAccessibility.post(notification: .layoutChanged, argument: sourceView)
        }
        
        if let viewController = viewController as? UIPopoverPresentationControllerDelegate {
            hotspotViewController.popoverPresentationController?.delegate = viewController
        }
        
        viewController.present(hotspotViewController, animated: true) {
            UIAccessibility.post(notification: .layoutChanged, argument: hotspotViewController.textView)
        }
    }
}
