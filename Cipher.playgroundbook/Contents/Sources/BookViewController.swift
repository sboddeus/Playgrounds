//
//  BookViewController.swift
//
//  Copyright © 2017,2018 Apple Inc. All rights reserved.
//

import UIKit
import PlaygroundSupport

@objc(BookViewController)
public class BookViewController: UIViewController, PlaygroundLiveViewSafeAreaContainer {
    
    // MARK: Properties
    
    @IBOutlet weak var libraryImageView: UIImageView!
    @IBOutlet weak var textView: UITextView!
    @IBOutlet weak var textContainerView: UIView!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var bookImageView: UIImageView!
    
    // MARK: Constraints

    private var containerTopConstraint: NSLayoutConstraint?
    private var containerLeftConstraint: NSLayoutConstraint?
    private var containerBottomConstraint: NSLayoutConstraint?
    private var containerRightConstraint: NSLayoutConstraint?

    // MARK: View Controller Lifecycle
    
    public override func viewDidLoad() {
        super.viewDidLoad()
        
        libraryImageView.accessibilityLabel = NSLocalizedString("The inside of a library with many bookshelves.", comment: "Accessibility label for image of library.")
        
        titleLabel.text = NSLocalizedString("Introduction to Cryptography", comment: "Intro title")
        
        if let rtfUrl = Bundle.main.url(forResource: "IntroText", withExtension: "rtf") {
            do {
                textView.attributedText = try NSAttributedString(url: rtfUrl, options: [:], documentAttributes: nil)
            } catch {
                fatalError("Could not load rtf file into UITextView in BookViewController")
            }
        }
        else {
            fatalError("Could not find rtf file in bundle for BookViewController")
        }

        // Add a content inset to the bottom of the text view so its content doesn’t
        // overlap the hint that appears. There’s no way to know the size of the
        // hint, so we add a generous amount of space.
        textView.textContainerInset.bottom = 160.0

        // Constrain the content within the `liveViewSafeAreaGuide`.
        containerTopConstraint = textContainerView.topAnchor.constraint(equalTo: liveViewSafeAreaGuide.topAnchor)
        containerBottomConstraint = textContainerView.bottomAnchor.constraint(equalTo: liveViewSafeAreaGuide.bottomAnchor)
        containerLeftConstraint = textContainerView.leftAnchor.constraint(equalTo: liveViewSafeAreaGuide.leftAnchor)
        containerRightConstraint = textContainerView.rightAnchor.constraint(equalTo: liveViewSafeAreaGuide.rightAnchor)
        NSLayoutConstraint.activate([containerTopConstraint!, containerLeftConstraint!, containerRightConstraint!, containerBottomConstraint!])
    }

    public override func viewWillLayoutSubviews() {
        super.viewWillLayoutSubviews()
        updateContainerConstraints()
    }

    public override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()

        // Scroll the text view back to the top.
        textView.contentOffset.y = 0
        
        // Alert the user all is loaded and the LiveView is ready and waiting for them
        let libraryString = NSLocalizedString("The Live View shows the interior of a library. Read the story to find out more!", comment: "Accessibility notification for displaying initial liveView")
        UIAccessibility.post(notification: .screenChanged, argument: libraryString)
    }

    // MARK: Custom Methods
    
    fileprivate func showOpenBook() {
        // Switch the views!
        libraryImageView.isHidden = true
        textContainerView.isHidden = false
        textView.contentOffset = CGPoint.zero
    }
    
    private func updateContainerConstraints() {
        // Determine the amount of inset that would be required to make the content
        // appear to be contained on the page of the book. These numbers give us
        // the propotions of the page taken up by the spine etc. We then mutliply
        // the size of the view by these proportions.
        let viewSize = view.bounds.size
        let bookInsets = UIEdgeInsets(top: ceil(viewSize.height * (85.0 / 1366.0)),
                                      left: ceil(viewSize.width * (145.0 / 1121.0)),
                                      bottom: ceil(viewSize.height * (260.0 / 1366.0)),
                                      right: ceil(viewSize.width * (132.0 / 1121.0)))

        // Determine the insets that the safe area guide define.
        let safeAreaFrame = liveViewSafeAreaGuide.layoutFrame
        let safeAreaInsets = UIEdgeInsets(top: safeAreaFrame.origin.y,
                                          left: safeAreaFrame.origin.x,
                                          bottom: viewSize.height - safeAreaFrame.maxY,
                                          right: viewSize.width - safeAreaFrame.maxX)

        // Update the contain view’s constraints so it appears within the book image’s
        // safe area and the live view safe area.
        containerTopConstraint?.constant = max(0, bookInsets.top - safeAreaInsets.top)
        containerBottomConstraint?.constant = -max(0, bookInsets.bottom - safeAreaInsets.bottom)
        containerLeftConstraint?.constant = bookInsets.left
        containerRightConstraint?.constant = -bookInsets.right
    }
}

extension BookViewController: PlaygroundLiveViewMessageHandler {
    public func receive(_ message: PlaygroundValue) {
        switch message {
        case .string(let messageString):
            if messageString == Constants.playgroundMessageKeyOpenBook {
                showOpenBook()
            }
        default:
            return
        }
    }
}
