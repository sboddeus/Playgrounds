//
//  BookViewControllerCipherTwo.swift
//
//  Copyright © 2017,2018 Apple Inc. All rights reserved.
//

import UIKit
import PlaygroundSupport

@objc(BookViewControllerCipherTwo)
public class BookViewControllerCipherTwo: UIViewController, PlaygroundLiveViewSafeAreaContainer {
    
    // MARK: Properties
    
    @IBOutlet weak var pageContainerView: UIView!
    @IBOutlet weak var bookImageView: UIImageView!
    
    fileprivate var pageViewController: UIPageViewController?
    private let bookPagesEmbedSegue = "bookPagesEmbedSegue"
    
    private(set) lazy var bookPagesViewControllers: [BookPageLeafViewController] = {
        
        let pageViewController1 = self.newBookPageLeafViewController(
            pageNumber: 0,
            title: NSLocalizedString("Simple Substitution Cipher",
                                     comment: "Simple Substitution Cipher title"),
            rtfFileName: "SimpleSubstitutionCipherText")
        
        let pageViewController2 = self.newBookPageLeafViewController(
            pageNumber: 1,
            title: NSLocalizedString("Keyed Substitution Cipher",
                                     comment: "Keyed Substitution Cipher title"),
            rtfFileName: "KeyedSubstitutionCipherText")

        return [pageViewController1, pageViewController2]
    }()
    
    public var isGestureBasedNavigationEnabled = false
    
    public var initialPageIndex = 0
    
    internal var pageIndex = 0
    
    // MARK: View Controller Lifecycle
    
    public override func viewDidLoad() {
        super.viewDidLoad()
        
        if isGestureBasedNavigationEnabled {
            let openGesture = UITapGestureRecognizer(target: self, action: #selector(togglePages(tapGesture:)))
            pageContainerView.addGestureRecognizer(openGesture)
        }
        
        // Constrain the content with in the `liveViewSafeAreaGuide`.
        NSLayoutConstraint.activate([
            view.topAnchor.constraint(equalTo: liveViewSafeAreaGuide.topAnchor),
            view.bottomAnchor.constraint(equalTo: liveViewSafeAreaGuide.bottomAnchor),
            view.leftAnchor.constraint(equalTo: liveViewSafeAreaGuide.leftAnchor),
            view.rightAnchor.constraint(equalTo: liveViewSafeAreaGuide.rightAnchor),
            ])
    }
    
    override public func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        
        if segue.identifier == bookPagesEmbedSegue {
            
            // This is the segue that is embedding the `UIPageViewController`.
            
            pageViewController = segue.destination as? UIPageViewController
            if isGestureBasedNavigationEnabled {
                pageViewController?.dataSource = self
            }
            pageViewController?.delegate = self
            
            resetPageViewController()
            
            goToPage(pageIndex: initialPageIndex)
        }
    }
    
    // MARK: Convenience methods
    
    private func newBookPageLeafViewController(pageNumber: Int, title: String, rtfFileName: String) -> BookPageLeafViewController {
        
        let viewController: BookPageLeafViewController = BookPageLeafViewController.instantiateFromStoryboard(storyboardName: "Cipher2")
        viewController.pageNumber = pageNumber
        viewController.pageTitle = title
        viewController.rtfFileName = rtfFileName
        return viewController
    }
    
    private func resetPageViewController() {
        
        guard let firstPageLeafViewController = bookPagesViewControllers.first else { return }
        pageViewController?.setViewControllers([firstPageLeafViewController], direction: .forward, animated: false, completion: { _ in
            self.pageIndex = 0
        })
    }
    
    private func currentPageViewController() -> BookPageLeafViewController? {
        
        guard pageIndex < bookPagesViewControllers.count else { return nil }
        
        return bookPagesViewControllers[pageIndex]
    }
    
    private func setKey(key: String) {
        
        guard let bookPageViewController = currentPageViewController() else { return }
        
        bookPageViewController.key = key
    }
    
    private func setWord(word: String) {
        
        guard let bookPageViewController = currentPageViewController() else { return }
        
        bookPageViewController.word = word
    }
    
    private func goToPage(pageIndex: Int, animated: Bool = false) {
        
        guard pageIndex < bookPagesViewControllers.count else { return }
        
            pageViewController?.setViewControllers([bookPagesViewControllers[pageIndex]], direction: .forward, animated: animated, completion: { _ in
                self.pageIndex = pageIndex
            })
    }
    
    // MARK: Actions
    
    @objc private func togglePages(tapGesture: UITapGestureRecognizer) {
        
        playSound(.pageFlip)
        
        if pageIndex == 0 {
            goToPage(pageIndex: 1, animated: true)
        } else if pageIndex == 1 {
            goToPage(pageIndex: 0, animated: true)
        }
    }
}

// MARK: UIPageViewControllerDataSource
extension BookViewControllerCipherTwo: UIPageViewControllerDataSource {
    
    public func pageViewController(_ pageViewController: UIPageViewController, viewControllerBefore viewController: UIViewController) -> UIViewController? {
        
        guard
            let bookPageLeafViewController = viewController as? BookPageLeafViewController,
            let viewControllerIndex = bookPagesViewControllers.index(of: bookPageLeafViewController)
            else { return nil }
        
        let previousIndex = viewControllerIndex - 1
        
        guard
            previousIndex >= 0,
            previousIndex < bookPagesViewControllers.count
            else { return nil }
        
        pageIndex = previousIndex
        
        return bookPagesViewControllers[previousIndex]
    }
    
    public func pageViewController(_ pageViewController: UIPageViewController, viewControllerAfter viewController: UIViewController) -> UIViewController? {
        
        guard
            let bookPageLeafViewController = viewController as? BookPageLeafViewController,
            let viewControllerIndex = bookPagesViewControllers.index(of: bookPageLeafViewController)
            else { return nil }
        
        let nextIndex = viewControllerIndex + 1
        
        guard
            nextIndex < bookPagesViewControllers.count
            else { return nil }
        
        pageIndex = nextIndex
        
        return bookPagesViewControllers[nextIndex]
    }
}

// MARK: UIPageViewControllerDelegate
extension BookViewControllerCipherTwo: UIPageViewControllerDelegate {
    public func pageViewController(_ pageViewController: UIPageViewController, didFinishAnimating finished: Bool, previousViewControllers: [UIViewController], transitionCompleted completed: Bool) {
        guard completed else { return }
        
        playSound(.pageFlip)
        
    }
}

// MARK: PlaygroundLiveViewMessageHandler
extension BookViewControllerCipherTwo: PlaygroundLiveViewMessageHandler {
    
    public func receive(_ message: PlaygroundValue) {
        
        guard
            case let .dictionary(dict) = message,
            case let .string(command)? = dict[Constants.playgroundMessageKeyCommand]
            else { return }
        
        if command == Constants.playgroundMessageKeyDoIt {
        
            if case let .string(word)? = dict[Constants.playgroundMessageKeyWord] {
                
                let cleanWord = Ciphers.cleanedText(text: word, maxLength: Ciphers.maxLettersInWord, allowableLetters: Ciphers.uppercaseAlphabet)
                if cleanWord.count < 3 {
                    send(.dictionary([
                        Constants.playgroundMessageKeyError : PlaygroundValue.boolean(true),
                        Constants.playgroundMessageKeyKeyword : PlaygroundValue.string(cleanWord)
                        ]))
                    return
                }
                
                setWord(word: cleanWord)
                
                send(.dictionary([
                    Constants.playgroundMessageKeyCompleted : PlaygroundValue.boolean(true),
                    Constants.playgroundMessageKeyWord : PlaygroundValue.string(cleanWord)
                    ]))
                return
            }

            if case let .string(keyword)? = dict[Constants.playgroundMessageKeyKeyword] {
                
                let cleanKeyword = Ciphers.cleanedText(text: keyword, maxLength: Ciphers.maxLettersInKey, allowableLetters: Ciphers.uppercaseAlphabet, removeDuplicates: true)
                if cleanKeyword.count < Ciphers.minLettersInKey {
                    send(.dictionary([
                        Constants.playgroundMessageKeyError : PlaygroundValue.boolean(true),
                        Constants.playgroundMessageKeyKeyword : PlaygroundValue.string(cleanKeyword)
                        ]))
                    return
                }
                
                setKey(key: cleanKeyword)
                
                send(.dictionary([
                    Constants.playgroundMessageKeyCompleted : PlaygroundValue.boolean(true),
                    Constants.playgroundMessageKeyKeyword : PlaygroundValue.string(cleanKeyword)
                    ]))
                return
            }
            
            send(.dictionary([
                Constants.playgroundMessageKeyCompleted : PlaygroundValue.boolean(true)
                ]))
        }
        
    }
}


