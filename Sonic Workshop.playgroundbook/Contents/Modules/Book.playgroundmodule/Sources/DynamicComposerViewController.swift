//
//  DynamicComposerViewController.swift
//  
//  Copyright © 2016-2019 Apple Inc. All rights reserved.
//


import UIKit
import UIKit.UIGestureRecognizerSubclass
import PlaygroundSupport
import Foundation
import SpriteKit
import SPCLearningTrails

public let sceneSize = CGSize(width: 1000, height: 1000)
public let contentInset : CGFloat = 10 // The amount we’ll inset the edge length to pull it away from the edge

let useFullSizeLiveView = true

public class DynamicComposerViewController : UIViewController, PlaygroundLiveViewSafeAreaContainer, UIGestureRecognizerDelegate, LiveViewSceneDelegate {
    
    private let kLearningTrailTopButtonAvoidanceMargin = CGFloat(64)
    private let kMinTopAvoidanceMargin = CGFloat(20)
    private let kMinBottomAvoidanceMargin = CGFloat(-8)
    
    private let buttonSize = CGSize(width: 44, height: 44)
    private let buttonInset: CGFloat = 20.0
    private let learningTrailAnimationDuration = 0.4
    private let interButtonPadding: CGFloat = 10.0
    private let compactLayoutSize = CGSize(width: 507.0, height: 364.0)
    
    var messageProcessingQueue: DispatchQueue? = nil
    let skView = useFullSizeLiveView ? SKView(frame: .zero) : LiveView(frame: .zero)
    let masterStackView = UIStackView(arrangedSubviews: [])
    let liveViewScene = LiveViewScene(size: sceneSize)
    let backgroundView = UIView(frame: .zero)
    let defaultBackgroundView = UIImageView(image: nil)
    let audioBarButton = BarButton()
    var topButtonAvoidanceConstraint: NSLayoutConstraint?
    
    var axButtonTopConstraint: NSLayoutConstraint?
    var axButtonRightConstraint: NSLayoutConstraint?
    var trailTopConstraint: NSLayoutConstraint?
    var trailRightConstraint: NSLayoutConstraint?
    var trailLeftConstraint: NSLayoutConstraint?
    
    private var learningTrailButtonTrailingConstraintVertical: NSLayoutConstraint?
    private var learningTrailButtonTrailingConstraintHorizontal: NSLayoutConstraint?
    private var learningTrailButtonTopConstraintVertical: NSLayoutConstraint?
    private var learningTrailButtonTopConstraintHorizontal: NSLayoutConstraint?
    
    private let higherPriority: UILayoutPriority = .defaultHigh
    private let lowerPriority: UILayoutPriority = .defaultHigh - 1

    private let smallAXButtonTopConstant = CGFloat(20)
    private let largeAXButtonTopConstant = CGFloat(80)
    private let smallAXButtonRightConstant = CGFloat(-20)
    private let largeAXButtonRightConstant = CGFloat(-80)
    
    private let smallTrailTopConstant = CGFloat(0)
    private let largeTrailTopConstant = CGFloat(64)
    private let smallTrailConstant = CGFloat(0)
    private let largeTrailConstant = CGFloat(44)

    private var trailViewController: LearningTrailViewController?
    private var learningTrailButton = BarButton()
    private var learningTrailDataSource = DefaultLearningTrailDataSource()
    private var wasLearningTrailVisibleBeforeRunMyCode = false
    
    private var isLearningTrailAnimationInProgress = false
    
    var sendTouchEvents:Bool = false
    var constraintsAdded = false
    var receivedAXToneMessage = false
    var receivedAXColorMessage = false
    var receivedAXMessageTimer: Timer?

    public var backgroundImage : Image? {
        didSet {
            var image : UIImage?
            if let bgImage = backgroundImage {
                image = UIImage(named: bgImage.path)
            }
            
            defaultBackgroundView.image = image
            defaultBackgroundView.contentMode = useFullSizeLiveView ? .scaleAspectFill : .center
        }
    }
    
    // Indicates whether a Learning Trail should be loaded if present.
    // Should be set before view controller is loaded.
    public var isLearningTrailEnabled = true
    
    // MARK: View Controller Lifecycle
    
    public override func viewDidLoad() {
        Process.setIsLive()
        // The scene needs to inform us of some events
        liveViewScene.sceneDelegate = self
        // Because the background image is *not* part of the scene itself, transparency is needed for the view and scene
        skView.allowsTransparency = true
        
        view.translatesAutoresizingMaskIntoConstraints = false
        backgroundView.translatesAutoresizingMaskIntoConstraints = false
        skView.translatesAutoresizingMaskIntoConstraints = false
        masterStackView.translatesAutoresizingMaskIntoConstraints = false
        
        view.addSubview(backgroundView)
        view.addSubview(masterStackView)
        
        topButtonAvoidanceConstraint = masterStackView.topAnchor.constraint(greaterThanOrEqualTo: liveViewSafeAreaGuide.topAnchor, constant: kMinTopAvoidanceMargin)
        
        let masterStackViewConstraints = [
            masterStackView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            masterStackView.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            masterStackView.leftAnchor.constraint(greaterThanOrEqualTo: liveViewSafeAreaGuide.leftAnchor, constant: contentInset),
            masterStackView.bottomAnchor.constraint(lessThanOrEqualTo: liveViewSafeAreaGuide.bottomAnchor),
            masterStackView.rightAnchor.constraint(lessThanOrEqualTo: liveViewSafeAreaGuide.rightAnchor, constant: -contentInset),
            topButtonAvoidanceConstraint!
        ]
        
        // allow masterStackView centering constraints to be broken
        masterStackViewConstraints[0].priority = .defaultLow
        masterStackViewConstraints[1].priority = .defaultLow
        
        NSLayoutConstraint.activate(masterStackViewConstraints)
        
        if !useFullSizeLiveView {
            masterStackView.addArrangedSubview(skView)
        }
        
        skView.presentScene(liveViewScene)

        func _constrainCenterAndSize(parent: UIView, child: UIView) {
            child.translatesAutoresizingMaskIntoConstraints = false
            NSLayoutConstraint.activate([
                child.centerXAnchor.constraint(equalTo: parent.centerXAnchor),
                child.centerYAnchor.constraint(equalTo: parent.centerYAnchor),
                child.widthAnchor.constraint(equalTo: parent.widthAnchor),
                child.heightAnchor.constraint(equalTo: parent.heightAnchor)
                ])
        }

        if !useFullSizeLiveView {
            let borderColorView = AddressableContentBorderView(frame: .zero)
            skView.addSubview(borderColorView)
            _constrainCenterAndSize(parent: skView, child: borderColorView)
        }
        
        // Create a blue background image if none exists
        if backgroundImage == nil {
            let image : UIImage? = {
                UIGraphicsBeginImageContextWithOptions(CGSize(width:2500, height:2500), false, 2.0)
                #colorLiteral(red: 0.1911527216, green: 0.3274578452, blue: 0.4287572503, alpha: 1).set()
                UIRectFill(CGRect(x: 0, y: 0, width: 2500, height: 2500))
                let image = UIGraphicsGetImageFromCurrentImageContext()
                UIGraphicsEndImageContext()
                return image
            }()
            
            defaultBackgroundView.image = image
        }
        
        defaultBackgroundView.contentMode = useFullSizeLiveView ? .scaleAspectFill : .center
        defaultBackgroundView.translatesAutoresizingMaskIntoConstraints = false
        backgroundView.addSubview(defaultBackgroundView)
        
        audioBarButton.translatesAutoresizingMaskIntoConstraints = false
        audioBarButton.addTarget(self, action: #selector(didTapAudioBarButton(_:)), for: .touchUpInside)
        view.addSubview(audioBarButton)
        
        _constrainCenterAndSize(parent: view, child: backgroundView)
        _constrainCenterAndSize(parent: backgroundView, child: defaultBackgroundView)
        
        if useFullSizeLiveView {
            backgroundView.addSubview(skView)
            
            let lowPriorityWidthConstraint = skView.widthAnchor.constraint(equalTo: backgroundView.widthAnchor)
            let lowPriorityHeightConstraint = skView.heightAnchor.constraint(equalTo: backgroundView.heightAnchor)
            
            lowPriorityWidthConstraint.priority = .defaultLow
            lowPriorityHeightConstraint.priority = .defaultLow
            
            NSLayoutConstraint.activate([
                skView.centerXAnchor.constraint(equalTo: backgroundView.centerXAnchor),
                skView.centerYAnchor.constraint(equalTo: backgroundView.centerYAnchor),
                skView.widthAnchor.constraint(greaterThanOrEqualTo: backgroundView.widthAnchor),
                skView.heightAnchor.constraint(greaterThanOrEqualTo: backgroundView.heightAnchor),
                lowPriorityWidthConstraint,
                lowPriorityHeightConstraint
            ])
        }
        
        updateAudioButton()
        updateStackViews()
        registerForTapGesture()
        
        learningTrailButton.translatesAutoresizingMaskIntoConstraints = false
        let trailButtonImage = UIImage(named: "LearningTrailMaximize")?.withRenderingMode(.alwaysTemplate)
        let trailButtonSelectedImage = UIImage(named: "LearningTrailMinimize")?.withRenderingMode(.alwaysTemplate)
        learningTrailButton.setImage(trailButtonImage, for: .normal)
        learningTrailButton.setImage(trailButtonSelectedImage, for: .selected)
        learningTrailButton.addTarget(self, action: #selector(onTrailButton), for: .touchUpInside)
        learningTrailButton.isHidden = true
        view.addSubview(learningTrailButton)
        
        // Learning trail button below audio button (vertical button layout).
        let learningTrailButtonTrailingConstraintVertical = learningTrailButton.trailingAnchor.constraint(equalTo: liveViewSafeAreaGuide.trailingAnchor, constant: -buttonInset)
        let learningTrailButtonTopConstraintVertical = isLearningTrailEnabled ?
            learningTrailButton.topAnchor.constraint(equalTo: audioBarButton.bottomAnchor, constant: interButtonPadding) :
            learningTrailButton.topAnchor.constraint(equalTo: liveViewSafeAreaGuide.topAnchor, constant: buttonInset)
        learningTrailButtonTrailingConstraintVertical.priority = higherPriority
        learningTrailButtonTopConstraintVertical.priority = higherPriority
        
        // Learning trail button to the left of audio button (horizontal button layout).
        let learningTrailButtonTrailingConstraintHorizontal = isLearningTrailEnabled ?
            learningTrailButton.trailingAnchor.constraint(equalTo: audioBarButton.leadingAnchor, constant: -interButtonPadding) :
            learningTrailButton.trailingAnchor.constraint(equalTo: liveViewSafeAreaGuide.trailingAnchor, constant: -buttonInset)
        let learningTrailButtonTopConstraintHorizontal = learningTrailButton.topAnchor.constraint(equalTo: liveViewSafeAreaGuide.topAnchor, constant: buttonInset)
        learningTrailButtonTrailingConstraintHorizontal.priority = lowerPriority
        learningTrailButtonTopConstraintHorizontal.priority = lowerPriority
        
        NSLayoutConstraint.activate([
            learningTrailButton.widthAnchor.constraint(equalToConstant: buttonSize.width),
            learningTrailButton.heightAnchor.constraint(equalToConstant: buttonSize.height),
            learningTrailButtonTrailingConstraintVertical,
            learningTrailButtonTopConstraintVertical,
            learningTrailButtonTrailingConstraintHorizontal,
            learningTrailButtonTopConstraintHorizontal
            ])

        NSLayoutConstraint.activate([
            skView.widthAnchor.constraint(equalTo: skView.heightAnchor),
            audioBarButton.widthAnchor.constraint(equalToConstant: buttonSize.width),
            audioBarButton.heightAnchor.constraint(equalToConstant: buttonSize.height),
            audioBarButton.topAnchor.constraint(equalTo: liveViewSafeAreaGuide.topAnchor, constant: buttonInset),
            audioBarButton.trailingAnchor.constraint(equalTo: liveViewSafeAreaGuide.trailingAnchor, constant: -buttonInset)
            ])
        
        self.learningTrailButtonTrailingConstraintVertical = learningTrailButtonTrailingConstraintVertical
        self.learningTrailButtonTopConstraintVertical = learningTrailButtonTopConstraintVertical
        self.learningTrailButtonTrailingConstraintHorizontal = learningTrailButtonTrailingConstraintHorizontal
        self.learningTrailButtonTopConstraintHorizontal = learningTrailButtonTopConstraintHorizontal
        
        updateLearningTrailAX()
        
        // Load the learning trail if there is one.
        guard isLearningTrailEnabled else { return }
        learningTrailDataSource.trail.load(completion: { success in
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                self.onLearningTrailLoaded(success)
            }
        })
    }

    public override func viewWillAppear(_ animated: Bool) {
        guard constraintsAdded == false else { return }
        if let parentView = self.view.superview {
            NSLayoutConstraint.activate([
                view.centerXAnchor.constraint(equalTo: parentView.centerXAnchor),
                view.centerYAnchor.constraint(equalTo: parentView.centerYAnchor),
                view.widthAnchor.constraint(equalTo: parentView.widthAnchor),
                view.heightAnchor.constraint(equalTo: parentView.heightAnchor)])
        }
        constraintsAdded = true
    }
    
    // MARK: Layout
    
    public override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)
        
        coordinator.animate(alongsideTransition: { (_) in
        }, completion: { completed in
            self.updateStackViews()
            self.updateLayoutConstraints()
        })
    }
    
    public override func viewDidLayoutSubviews() {
        updateStackViews()
        updateLayoutConstraints()
    }
    
    private func updateLayoutConstraints() {
        let horizontalLayout = (liveViewSafeAreaGuide.layoutFrame.size.width > liveViewSafeAreaGuide.layoutFrame.size.height)
        var horizontalButtons = !horizontalLayout
        let isCompactLayout = (liveViewSafeAreaGuide.layoutFrame.width <= compactLayoutSize.width) && (liveViewSafeAreaGuide.layoutFrame.height <= compactLayoutSize.height)
                
        learningTrailButton.isHidden = !isLearningTrailEnabled || isLearningTrailVisible // Hidden if no learning trail.
        
        updateAudioButtonVisibility(trailVisible: isLearningTrailVisible)
        
        axButtonTopConstraint?.constant = horizontalButtons ? smallAXButtonTopConstant : largeAXButtonTopConstant
        axButtonRightConstraint?.constant = horizontalButtons ? largeAXButtonRightConstant : smallAXButtonRightConstant
        
        trailTopConstraint?.constant = horizontalButtons && !isCompactLayout ? largeTrailTopConstant : smallTrailTopConstant
        trailRightConstraint?.constant = horizontalButtons || isCompactLayout ? smallTrailConstant : largeTrailConstant * -1
        trailLeftConstraint?.constant = horizontalButtons || isCompactLayout ? smallTrailConstant : largeTrailConstant
        
        // Vertical and horizontal button layouts are determined by switching constraint priorities.
        learningTrailButtonTrailingConstraintVertical?.priority = horizontalButtons ? lowerPriority : higherPriority
        learningTrailButtonTopConstraintVertical?.priority = horizontalButtons ? lowerPriority : higherPriority
        learningTrailButtonTrailingConstraintHorizontal?.priority = horizontalButtons ? higherPriority : lowerPriority
        learningTrailButtonTopConstraintHorizontal?.priority = horizontalButtons ? higherPriority : lowerPriority
    }
    
    // MARK: Audio
    
    private func updateAudioButton() {
        audioBarButton.setTitle(nil, for: .normal)
        let allAudioEnabled = audioController.isAllAudioEnabled
        let iconImage = allAudioEnabled ? UIImage(named: "AudioOn") : UIImage(named: "AudioOff")
        audioBarButton.accessibilityLabel = allAudioEnabled ?
            NSLocalizedString("Sound On", comment: "AX hint for Sound On button") :
            NSLocalizedString("Sound Off", comment: "AX hint for Sound Off button")
        audioBarButton.setImage(iconImage?.withRenderingMode(.alwaysTemplate), for: .normal)
    }
    
    private func updateAudioButtonVisibility(trailVisible: Bool) {
        let isCompactLayout = (liveViewSafeAreaGuide.layoutFrame.width <= compactLayoutSize.width) && (liveViewSafeAreaGuide.layoutFrame.height <= compactLayoutSize.height)
        audioBarButton.alpha = isCompactLayout && isLearningTrailEnabled && trailVisible ? 0.0 : 1.0 // Always visible if no learning trail.
    }
    
    private func updateStackViews() {
        let horizontalLayout = liveViewSafeAreaGuide.layoutFrame.size.width > liveViewSafeAreaGuide.layoutFrame.size.height
        
        masterStackView.axis = horizontalLayout ? .horizontal : .vertical
        masterStackView.distribution = .fill
        masterStackView.alignment = .center
        masterStackView.spacing = 5.0
    }
    
    // MARK: Actions

    @objc
    func didTapAudioBarButton(_ button: UIButton) {
        audioController.isBackgroundAudioEnabled = !audioController.isBackgroundAudioEnabled
        updateAudioButton()
        
        // Resume (actually restart) background audio if it had been playing.
        if audioController.isBackgroundAudioEnabled, let backgroundMusic = audioController.backgroundAudioMusic {
            audioController.playBackgroundAudioLoop(backgroundMusic)
        }
    }
    
    @objc
    func onTrailButton(_ button: UIButton) {
        if let vc = presentedViewController, vc.modalPresentationStyle == .popover {
            vc.dismiss(animated: true, completion: nil)
        }
        
        showLearningTrail()
    }
    
    // MARK: Tap Gesture
    
    func registerForTapGesture() {
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(tapAction(_:)))
        view.addGestureRecognizer(tapGesture)
    }
    
    @objc func tapAction(_ recognizer: UITapGestureRecognizer) {
        if let vc = presentedViewController, vc.modalPresentationStyle == .popover {
            vc.dismiss(animated: true, completion: nil)
        }
    }
    
    override public func didReceiveMemoryWarning() {
        LiveViewGraphic.didReceiveMemoryWarning()
    }
    
    // MARK: AX
    
    func updateLearningTrailAX() {
        learningTrailButton.accessibilityIdentifier = "\(String(describing: type(of: self))).learningTrailButton"
        learningTrailButton.accessibilityLabel = NSLocalizedString("Show Learning Trail", comment: "AX label for learning trail button when it’s hidden.")
    }

    // MARK: Learning Trail Overlay
    
    private var learningTrailButtonShrunkenScale: CGFloat {
        return DefaultLearningStepStyle.headerButtonSize.width / buttonSize.width
    }

    var isLearningTrailVisible: Bool {
        return learningTrailButton.isSelected
    }
    
    func onLearningTrailLoaded(_ success: Bool) {
        // Display the Learning Trail.
        learningTrailButton.isHidden = false
        view.bringSubviewToFront(learningTrailButton)
        
        showLearningTrail()
        
        // Display a message if there was a problem parsing the Learning Trail XML document.
        if !success {
            var message = NSLocalizedString("⚠️ Error loading Learning Trail:", comment: "Error Message: Learning Trail loading")
            message += "\n\n"
            message += learningTrailDataSource.trail.errorMessage
            trailViewController?.showMessage(message)
        }
    }
    
    func loadTrailViewController() {
        guard trailViewController == nil else { return }
        
        let trailViewController = LearningTrailViewController()
        trailViewController.learningTrailDataSource = learningTrailDataSource
        trailViewController.delegate = self
        trailViewController.view.translatesAutoresizingMaskIntoConstraints = false
        trailViewController.view.isHidden = true
        addChild(trailViewController)
        view.insertSubview(trailViewController.view, belowSubview: audioBarButton)
        
        let lowPriorityButtonAvoidanceConstraint = trailViewController.view.topAnchor.constraint(equalTo: liveViewSafeAreaGuide.topAnchor)
        self.trailTopConstraint = lowPriorityButtonAvoidanceConstraint
        
        let lowPriorityKeyboardAvoidanceConstraint = trailViewController.view.bottomAnchor.constraint(equalTo: liveViewSafeAreaGuide.bottomAnchor, constant: kMinBottomAvoidanceMargin)
        
        let rightButtonAvoidanceConstraint = trailViewController.view.rightAnchor.constraint(equalTo: liveViewSafeAreaGuide.rightAnchor)
        let trailLeftConstraint = trailViewController.view.leftAnchor.constraint(equalTo: liveViewSafeAreaGuide.leftAnchor)
        self.trailRightConstraint = rightButtonAvoidanceConstraint
        self.trailLeftConstraint = trailLeftConstraint
        
        NSLayoutConstraint.activate([
            lowPriorityButtonAvoidanceConstraint,
            trailLeftConstraint,
            lowPriorityKeyboardAvoidanceConstraint,
            rightButtonAvoidanceConstraint
            ])
        
        self.trailViewController = trailViewController
    }
    
    func showTrailViewController() {
        guard !isLearningTrailAnimationInProgress else { return }
        guard let trailViewController = self.trailViewController else { return }
        
        isLearningTrailAnimationInProgress = true
        
        // Show the learning trail.
        let duration = learningTrailAnimationDuration
        let startPoint = view.convert(learningTrailButton.center, to: nil)
        trailViewController.show(from: startPoint, duration: duration, delay: 0.0)
        
        // Animate the learning trail button in parallel so that it lands just where the trail close button will be.
        let startPosition = view.convert(learningTrailButton.center, to: nil)
        let endPosition = trailViewController.closeButtonPosition
        let dx = endPosition.x - startPosition.x
        let dy = endPosition.y - startPosition.y
        
        self.updateAudioButtonVisibility(trailVisible: true)
        UIView.animate(withDuration: duration, delay: 0.0,
                       options: [ .curveEaseOut, .beginFromCurrentState ],
                       animations: {
                        let transform = CGAffineTransform(translationX: dx, y: dy)
                        self.learningTrailButton.transform = transform
                        self.learningTrailButton.backgroundScale = self.learningTrailButtonShrunkenScale
                        self.learningTrailButton.setSelected(true, delay: duration * 0.125, duration: duration * 0.4)
        }, completion: { _ in
            self.learningTrailButton.isHidden = true
            self.learningTrailButton.transform = CGAffineTransform.identity
            self.isLearningTrailAnimationInProgress = false
            self.learningTrailButton.isSelected = true
            // Announce new state of learning trail.
            let message = NSLocalizedString("Learning Trail shown", comment: "Describes state of learning trail when it’s shown.")
            UIAccessibility.post(notification: .announcement, argument: message)
        })
    }
    
    func hideTrailViewController() {
        guard !isLearningTrailAnimationInProgress else { return }
        guard let trailViewController = self.trailViewController else { return }
        
        isLearningTrailAnimationInProgress = true
        
        // Position the learning trail button over the trail close button.
        let trailButtonPosition = view.convert(learningTrailButton.center, to: nil)
        let closeButtonPosition = trailViewController.closeButtonPosition
        let dx = closeButtonPosition.x - trailButtonPosition.x
        let dy = closeButtonPosition.y - trailButtonPosition.y
        let transform = CGAffineTransform(translationX: dx, y: dy)
        learningTrailButton.transform = transform
        learningTrailButton.backgroundScale = learningTrailButtonShrunkenScale
        learningTrailButton.isHidden = false
        
        // Hide the learning trail.
        let duration = learningTrailAnimationDuration
        let endPoint = view.convert(learningTrailButton.center, to: nil)
        trailViewController.hide(to: endPoint, duration: duration, delay: 0.0)
        
        // Animate the learning trail button in parallel back to its original position.
        UIView.animate(withDuration: duration, delay: 0.0,
                       options: [ .curveEaseOut, .beginFromCurrentState ],
                       animations: {
                        self.learningTrailButton.transform = CGAffineTransform.identity
                        self.learningTrailButton.backgroundScale = 1.0
                        self.learningTrailButton.setSelected(false, delay: duration * 0.125, duration: duration * 0.4)
                        self.updateAudioButtonVisibility(trailVisible: false)
        }, completion: { _ in
            self.isLearningTrailAnimationInProgress = false
            self.learningTrailButton.isSelected = false
            // Announce new state of learning trail.
            let message = NSLocalizedString("Learning Trail hidden", comment: "Describes state of learning trail when it’s hidden.")
            UIAccessibility.post(notification: .announcement, argument: message)
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                UIAccessibility.post(notification: .layoutChanged, argument: self.learningTrailButton)
            }
        })
    }
    
    func showLearningTrail() {
        guard isLearningTrailEnabled, !isLearningTrailVisible else { return }
        
        var waitTime = 0.0
        
        if trailViewController == nil {
            loadTrailViewController()
            waitTime = 0.25 // First time: wait for trail view controller constraints to take effect visually.
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + waitTime) {
            self.showTrailViewController()
            self.updateLearningTrailAX()
        }
    }
    
    func hideLearningTrail() {
        guard isLearningTrailEnabled, isLearningTrailVisible else { return }
        
        hideTrailViewController()
        updateLearningTrailAX()
    }
    
    func dismissLearningTrailPopovers() {
        // If there's one or more popovers that are presented from a trail (or its steps), dismiss them.
        trailViewController?.dismiss(animated: false, completion: nil)
    }
}

public class LiveView : SKView, PlaygroundLiveViewSafeAreaContainer {
    let contentEdgeLength : CGFloat = max(UIScreen.main.bounds.size.height, UIScreen.main.bounds.width) / 2.0
    
    override public var intrinsicContentSize: CGSize {
        get {
            return CGSize(width: contentEdgeLength, height: contentEdgeLength)
        }
    }

    override public func contentCompressionResistancePriority(for axis: NSLayoutConstraint.Axis) -> UILayoutPriority {
        return .defaultLow
    }
}

public class SelfIgnoringView : UIView {
    override public func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
        let view = super.hitTest(point, with: event)
        if (view == self) {
            return nil
        }
        return view
    }
}

public class AddressableContentBorderView : SelfIgnoringView {
    override public var isOpaque: Bool {
        set {}
        get { return false }
    }
    override public func draw(_ rect: CGRect) {
        UIColor.clear.set()
        let path = UIBezierPath(rect: self.bounds)
        path.fill()

        let pattern = Array<CGFloat>(arrayLiteral: 3.0, 3.0)
        path.setLineDash(pattern, count: 2, phase: 0.0)
        path.lineJoinStyle = .round
        UIColor.white.set()
        path.stroke()
    }
}

extension DynamicComposerViewController : PlaygroundLiveViewMessageHandler {
    
    public func liveViewMessageConnectionOpened() {
        PBLog()
        messageProcessingQueue = DispatchQueue(label: "Message Processing Queue")
        liveViewScene.connectedToUserCode()
        
        wasLearningTrailVisibleBeforeRunMyCode = isLearningTrailVisible
        
        hideLearningTrail()
        dismissLearningTrailPopovers()
        
        enableFullScreenLiveViewIfNeeded()
    }
    
    public func liveViewMessageConnectionClosed() {
        PBLog()
        liveViewScene.disconnectedFromUserCode()
        disableFullScreenLiveViewIfNeeded()
        
        // Show the learning trail again if it was visible before.
        if wasLearningTrailVisibleBeforeRunMyCode {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
                self.showLearningTrail()
            }
        }
        
        audioController.duckAllPlayers()
    }
    
    public func receive(_ message: PlaygroundValue) {
        messageProcessingQueue?.async { [unowned self] in
            self.processMessage(message)
        }
    }
    
    private func processMessage(_ message: PlaygroundValue) {
        guard let unpackedMessage = Message(rawValue: message) else {
            return
        }

        switch unpackedMessage {
   
        case .registerTouchHandler(let registered):
            DispatchQueue.main.async { [unowned self] in
                self.sendTouchEvents = registered
            }
            
        case .setSceneBackgroundColor(let color):
            DispatchQueue.main.async { [unowned self] in
                self.backgroundView.backgroundColor = color
            }
            self.liveViewScene.handleMessage(message: unpackedMessage)
            
        default:
            self.liveViewScene.handleMessage(message: unpackedMessage)
        }
    }
    
    func enableFullScreenLiveViewIfNeeded() {
        if traitCollection.horizontalSizeClass == .compact {
//            PlaygroundPage.current.wantsFullScreenLiveView = true
        }
    }
    
    func disableFullScreenLiveViewIfNeeded() {
//        PlaygroundPage.current.wantsFullScreenLiveView = false
    }
    
}

extension DynamicComposerViewController: UIPopoverPresentationControllerDelegate {
    public func adaptivePresentationStyle(for controller: UIPresentationController) -> UIModalPresentationStyle {
        return .none
    }
}

extension DynamicComposerViewController: LearningTrailViewControllerDelegate {
    public func trailViewControllerDidRequestClose(_ trailViewController: LearningTrailViewController) {
        hideLearningTrail()
    }
}
