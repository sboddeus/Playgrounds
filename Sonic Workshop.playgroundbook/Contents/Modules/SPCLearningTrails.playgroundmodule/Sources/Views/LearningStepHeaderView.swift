//
//  LearningStepHeaderView.swift
//  
//  Copyright © 2016-2019 Apple Inc. All rights reserved.
//

import UIKit
import SPCCore

// Implement this protocol to receive updates from a LearningStepHeaderView.
protocol LearningStepHeaderViewDelegate {
    func stepHeaderView(_ stepHeaderView: LearningStepHeaderView, didSelectStep step: LearningStep)
}

class LearningStepHeaderView: UIView {
    let typeLabel = UILabel()
    var badgeViews = [LearningStepBadgeView]()
    var axElement: UIAccessibilityElement?
    
    private let badgeSize = DefaultLearningStepStyle.headerButtonSize
    private let interBadgePadding: CGFloat = 4
    private var typeLabelLeadingConstraint: NSLayoutConstraint?
    
    var step: LearningStep?
    var style: LearningStepStyle?
    
    var delegate: LearningStepHeaderViewDelegate?
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        layoutMargins = UIEdgeInsets(top: 5, left: 0, bottom: 5, right: 10)
        
        addSubview(typeLabel)
        
        typeLabel.adjustsFontForContentSizeCategory = true
        typeLabel.translatesAutoresizingMaskIntoConstraints = false
        
        axElement = UIAccessibilityElement(accessibilityContainer: self)
        axElement?.isAccessibilityElement = true
        isAccessibilityElement = false // Accessibility container
        
        let leadingConstraint = typeLabel.leadingAnchor.constraint(equalTo: leadingAnchor)
        NSLayoutConstraint.activate([
            leadingConstraint,
            typeLabel.centerYAnchor.constraint(equalTo: centerYAnchor)
        ])
        
        typeLabelLeadingConstraint = leadingConstraint
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func load(step: LearningStep, style: LearningStepStyle, assessableSteps: [LearningStep]? = nil) {
        self.step = step
        self.style = style
                
        typeLabel.attributedText = NSAttributedString(xml: "<type>\(step.type.localizedName)</type>", style: style.typeTextStyle)
        typeLabel.sizeToFit()
        axElement?.accessibilityLabel = String(format: NSLocalizedString("%@ step", comment: "AX step type"), step.type.localizedName)
        axElement?.accessibilityIdentifier = "\(step.identifier).steptype"

        if let assessableSteps = assessableSteps, !assessableSteps.isEmpty {
            let badgeSpacing = badgeSize.width + interBadgePadding
            var xOffset: CGFloat = layoutMargins.right + (badgeSize.width / 2) + 45 // Center of right-most badge.
            xOffset += badgeSpacing * CGFloat(assessableSteps.count - 1)
            for step in assessableSteps {
                let badgeView = LearningStepBadgeView(step: step)
                addSubview(badgeView)
                badgeViews.append(badgeView)
                badgeView.translatesAutoresizingMaskIntoConstraints = false
                
                badgeView.widthConstraint = badgeView.widthAnchor.constraint(equalToConstant: badgeSize.width)
                let aspectRatioConstraint = NSLayoutConstraint(item: badgeView,
                                                               attribute: NSLayoutConstraint.Attribute.height,
                                                               relatedBy: NSLayoutConstraint.Relation.equal,
                                                               toItem: badgeView,
                                                               attribute: NSLayoutConstraint.Attribute.width,
                                                               multiplier: 1.0,
                                                               constant: 0)

                NSLayoutConstraint.activate([
                    badgeView.centerXAnchor.constraint(equalTo: trailingAnchor, constant: -xOffset),
                    badgeView.centerYAnchor.constraint(equalTo: centerYAnchor),
                    badgeView.widthConstraint,
                    aspectRatioConstraint
                    ])
                xOffset -= badgeSpacing
                
                let gestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(self.onTapBadge(recognizer:)))
                badgeView.addGestureRecognizer(gestureRecognizer)
                badgeView.isUserInteractionEnabled = true
            }
        }
        
        if let axElement = axElement {
            accessibilityElements = [axElement] + badgeViews
        }
        
        setNeedsDisplay()
        setNeedsLayout()
    }
    
    override public func layoutSubviews() {
        super.layoutSubviews()
        axElement?.accessibilityFrameInContainerSpace = typeLabel.frame
        var typeLabelLeading = bounds.width * (1 - LearningBlockTableViewCell.contentWidthMultiplier) / 2.0
        typeLabelLeading += UITextView().textContainer.lineFragmentPadding
        typeLabelLeadingConstraint?.constant = typeLabelLeading
    }
    
    @objc
    func onTapBadge(recognizer: UITapGestureRecognizer) {
        guard let badgeView = recognizer.view as? LearningStepBadgeView else { return }
        delegate?.stepHeaderView(self, didSelectStep: badgeView.step)
    }
    
    func refresh() {
        badgeViews.forEach({ $0.update() })
    }
    
    func celebrate() {
        var delay = 0.0
        badgeViews.forEach({
            $0.roll(after: delay)
            delay += 0.25
        })
    }
    
    func setActiveStep(_ step: LearningStep?) {
        for badgeView in badgeViews {
            badgeView.isActive = badgeView.step == step
        }
    }
    
    override func draw(_ rect: CGRect)
    {
        guard let style = style else { return }
        
        let colors = style.gradientColors.map({ $0.cgColor })
        let locations = style.gradientColorLocations
        
        let colorspace = CGColorSpaceCreateDeviceRGB()
        
        guard
            let context = UIGraphicsGetCurrentContext(),
            let gradient = CGGradient(colorsSpace: colorspace, colors: colors as CFArray, locations: locations)
            else { return }
        
        let startPoint = CGPoint(x: bounds.size.width * style.gradientStartPoint.x,
                             y: bounds.size.height * style.gradientStartPoint.y)
        let endPoint = CGPoint(x: bounds.size.width * style.gradientEndPoint.x,
                           y: bounds.size.height * style.gradientEndPoint.y)
        
        context.drawLinearGradient(gradient, start: startPoint, end: endPoint,
                                    options: [.drawsBeforeStartLocation, .drawsAfterEndLocation])
    }
}
