//
//  LearningTrailDataSource.swift
//  
//  Copyright © 2016-2019 Apple Inc. All rights reserved.
//

import UIKit

public protocol LearningTrailDataSource {
    var trail: LearningTrail { get }
    var stepCount: Int  { get }
    var dataSourceProviderForStep: ((LearningStep) -> LearningStepDataSource) { get set }
    init(trail: LearningTrail)
    func viewControllerForStep(at index: Int) -> UIViewController?
    func index(of stepViewController: UIViewController) -> Int?
    func index(of step: LearningStep) -> Int?
    func refreshSteps()
}

open class DefaultLearningTrailDataSource: LearningTrailDataSource {
    private lazy var stepViewControllers: [LearningStepViewController] = {
        var viewControllers = [LearningStepViewController]()
        for step in trail.steps {
            let stepViewController = LearningStepViewController()
            stepViewController.learningStepDataSource = dataSourceProviderForStep(step)
            viewControllers.append(stepViewController)
        }
        return viewControllers
    }()
    
    public var trail: LearningTrail
    
    open var dataSourceProviderForStep: ((LearningStep) -> LearningStepDataSource) = { step in
        return DefaultLearningStepDataSource(step: step)
    }

    public convenience init() {
        self.init(trail: LearningTrail())
    }
    
    public required init(trail: LearningTrail) {
        self.trail = trail
    }
    
    public var stepCount: Int {
        return trail.steps.count
    }
    
    open func viewControllerForStep(at index: Int) -> UIViewController? {
        guard index >= 0, index < trail.steps.count else { return nil }
        return stepViewControllers[index]
    }
    
    open func index(of stepViewController: UIViewController) -> Int? {
        guard let stepViewController = stepViewController as? LearningStepViewController else { return nil }
        return stepViewControllers.firstIndex(of: stepViewController)
    }
    
    open func index(of step: LearningStep) -> Int? {
        return trail.steps.firstIndex(where: {$0 === step})
    }
    
    open func refreshSteps() {
        stepViewControllers.forEach( { $0.refreshStep() } )
    }
}
