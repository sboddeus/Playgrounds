//
//  SubstitutionCipherViewController.swift
//
//  Copyright © 2017,2018 Apple Inc. All rights reserved.
//

import UIKit
import PlaygroundSupport

@objc(SubstitutionCipherViewController)
public class SubstitutionCipherViewController: UIViewController, PlaygroundLiveViewSafeAreaContainer {
    fileprivate typealias Plaintext = (text: String, shift: Int)
    
    // MARK: Properties
    
    @IBOutlet weak var contentContainer: UIView!
    
    @IBOutlet weak var previousButton: UIButton!
    
    @IBOutlet weak var nextButton: UIButton!
    
    @IBOutlet weak var glowingView: GlowingView!
    
    fileprivate var plaintexts: [Plaintext] = [(CipherContent.ciphertext, 0)]

    fileprivate var pageController: UIPageViewController?
    
    private let decryptionPagerEmbedSegue = "decryptionPagerEmbedSegue"
    private var liveViewConnectionOpen = false
    
    // MARK: View Controller LifeCycle
    
    public override func viewDidLoad() {
        super.viewDidLoad()
        
        // Accessibility Labels
        previousButton.accessibilityLabel = NSLocalizedString("Navigate to previous shift value.", comment: "Accessibility label for previous button.")
        nextButton.accessibilityLabel = NSLocalizedString("Navigate to next shift value.", comment: "Accessibility label for next button.")
        
        // Configure the appearance of page controls within a `UIPageViewController`.
        let pageControl = UIPageControl.appearance(whenContainedInInstancesOf: [UIPageViewController.self])
        pageControl.pageIndicatorTintColor = #colorLiteral(red: 0.3411764801, green: 0.6235294342, blue: 0.1686274558, alpha: 1)
        pageControl.currentPageIndicatorTintColor = #colorLiteral(red: 0.2048710883, green: 0.8790110946, blue: 0.205568701, alpha: 1)
        
        previousButton.setTitle(NSLocalizedString("⇦ Previous", comment: "Previous button title and arrow"), for: .normal)
        nextButton.setTitle(NSLocalizedString("Next ⇨", comment: "Next button title and arrow"), for: .normal)
        
        // Constrain the content with in the `liveViewSafeAreaGuide`.
        NSLayoutConstraint.activate([
            contentContainer.topAnchor.constraint(equalTo: liveViewSafeAreaGuide.topAnchor, constant: 0),
            contentContainer.bottomAnchor.constraint(equalTo: liveViewSafeAreaGuide.bottomAnchor, constant: 0),
            contentContainer.leftAnchor.constraint(equalTo: liveViewSafeAreaGuide.leftAnchor, constant: 0),
            contentContainer.rightAnchor.constraint(equalTo: liveViewSafeAreaGuide.rightAnchor, constant: 0),
        ])
        
        glowingView.isHidden = true
    }
    
    override public func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == decryptionPagerEmbedSegue {
            // This is the segue that is embedding the `UIPageViewController`.
            pageController = segue.destination as? UIPageViewController
            pageController?.dataSource = self
            pageController?.delegate = self
            
            resetPageController()
        }
    }
    
    // MARK: IBAction Methods
    
    @IBAction func nextButtonTapped(_ sender: UIButton) {
        // Guard that there is a next page to go to.
        guard let currentPageIndex = currentPageIndex, let controller = createViewController(forPlaintextIndex: currentPageIndex + 1) else { return }
        
        // Navigate to the next page.
        pageController?.setViewControllers([controller], direction: .forward, animated: true, completion: { completed in
            guard completed else { return }
            // Let VoiceOver know the screen has changed
            UIAccessibility.post(notification: .screenChanged, argument: controller.shiftLabel)
            
            self.updatePageButtons()
            self.checkCurrentPageForSuccess()
        })
    }
    
    @IBAction func previousButtonTapped(_ sender: UIButton) {
        // Guard that there is a previous page to go to.
        guard let currentPageIndex = currentPageIndex, let controller = createViewController(forPlaintextIndex: currentPageIndex - 1) else { return }
        
        // Navigate to the previous page.
        pageController?.setViewControllers([controller], direction: .reverse, animated: true, completion: { completed in
            guard completed else { return }
            // Let VoiceOver know the screen has changed
            UIAccessibility.post(notification: .screenChanged, argument: controller.shiftLabel)
            
            self.updatePageButtons()
            self.checkCurrentPageForSuccess()
            // Let VoiceOver know the screen has changed
        })
    }
    
    // MARK: Convenience methods
    
    fileprivate func resetPageController() {
        guard let startingViewController = createViewController(forPlaintextIndex: 0) else {
            contentContainer.isHidden = true
            return
        }
        contentContainer.isHidden = false
        
        // Show a view controller for the plaintext if there is one, or nothing if not.
        pageController?.setViewControllers([startingViewController], direction: .forward, animated: false, completion: nil)
        
        if liveViewConnectionOpen {
            UIAccessibility.post(notification: .screenChanged, argument: startingViewController.shiftLabel)
        }
        // Update the state of the next/previous buttons.
        updatePageButtons()
        if self.nextButton.isEnabled {
            self.startNextButtonGlowing()
        }
        checkCurrentPageForSuccess()
    }
    
    fileprivate func updatePageButtons() {
        // Disable the buttons if there is no current page index.
        guard let currentPageIndex = currentPageIndex else {
            nextButton.isEnabled = false
            previousButton.isEnabled = false
            return
        }
        
        // Update the button states based on the current page index.
        previousButton.isEnabled = currentPageIndex > 0
        nextButton.isEnabled = currentPageIndex < plaintexts.count - 1
        
        stopNextButtonGlowing()
    }
    
    fileprivate func createViewController(forPlaintextIndex index: Int) -> SubstitutionCipherPageViewController? {
        // Return nil if the index is invalid.
        guard !plaintexts.isEmpty && index < plaintexts.count && index >= 0 else {
            return nil
        }
        
        // Create a new controller.
        let controller: SubstitutionCipherPageViewController = SubstitutionCipherPageViewController.instantiateFromStoryboard(storyboardName: "Cipher1")
        
        // Configure the controller with the specified plaintext.
        let plaintext = plaintexts[index]
        controller.pageIndex = index
        controller.plaintext = plaintext.text
        controller.shiftUsed = plaintext.shift
        
        return controller
    }
    
    fileprivate func checkCurrentPageForSuccess() {
        guard let currentPage = pageController?.viewControllers?.first as? SubstitutionCipherPageViewController else { return }
        
        if currentPage.shiftUsed == 5 && currentPage.plaintext == CipherContent.plaintext {
            send(.string(Constants.playgroundMessageKeySuccess))
        }
    }
    
    fileprivate var currentPageIndex: Int? {
        guard let currentPage = pageController?.viewControllers?.first as? SubstitutionCipherPageViewController else { return nil }
        return currentPage.pageIndex
    }
    
    fileprivate func startNextButtonGlowing() {
        glowingView.start()
        glowingView.isHidden = false
    }
    
    fileprivate func stopNextButtonGlowing() {
        glowingView.stop()
        glowingView.isHidden = true
    }
}

extension SubstitutionCipherViewController: UIPageViewControllerDataSource {
    public func pageViewController(_ pageViewController: UIPageViewController, viewControllerBefore viewController: UIViewController) -> UIViewController? {
        guard let currentPageIndex = currentPageIndex, currentPageIndex > 0 else { return nil }
        return createViewController(forPlaintextIndex: currentPageIndex - 1)
    }
    
    public func pageViewController(_ pageViewController: UIPageViewController, viewControllerAfter viewController: UIViewController) -> UIViewController? {
        guard let currentPageIndex = currentPageIndex, currentPageIndex < plaintexts.count - 1 else { return nil }
        return createViewController(forPlaintextIndex: currentPageIndex + 1)
    }
}

extension SubstitutionCipherViewController: UIPageViewControllerDelegate {
    public func pageViewController(_ pageViewController: UIPageViewController, didFinishAnimating finished: Bool, previousViewControllers: [UIViewController], transitionCompleted completed: Bool) {
        guard completed else { return }
        
        updatePageButtons()
        checkCurrentPageForSuccess()
    }
}

extension SubstitutionCipherViewController: PlaygroundLiveViewMessageHandler {
    public func liveViewMessageConnectionOpened() {
        // Reset the plaintexts array.
        plaintexts = []
        liveViewConnectionOpen = true
    }
    
    public func liveViewMessageConnectionClosed() {
        liveViewConnectionOpen = false
    }
    
    public func receive(_ message: PlaygroundValue) {
        switch message {
        case .dictionary(let shiftText):
            guard case let .integer(shift)? = shiftText[Constants.playgroundMessageKeyShift], case let .string(text)? = shiftText[Constants.playgroundMessageKeyWord] else { return }
            
            let shiftedText = CipherContent.shift(inputText: text, by: -shift)
            plaintexts.append((text: shiftedText, shift: shift))
            
            resetPageController()
            
        default:
            return
        }
    }
}
