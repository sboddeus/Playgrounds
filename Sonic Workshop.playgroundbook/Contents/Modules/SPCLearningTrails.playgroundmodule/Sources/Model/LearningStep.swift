//
//  LearningStep.swift
//  
//  Copyright © 2016-2019 Apple Inc. All rights reserved.
//

import Foundation
import SPCCore

// Title optional
// Code types: there alreadyt
// Image/Animation/Video
// Assessment types: checkboxes, multiple choice

public class LearningStep {
    
    public enum StepType: String {
        case unknown
        case check
        case code
        case context
        case experiment
        case find
        
        public var localizedName: String {
            switch self {
            case .unknown: return NSLocalizedString("UNKNOWN", comment: "Learning step type: unknown")
            case .check: return NSLocalizedString("CHECK", comment: "Learning step type: check")
            case .code: return NSLocalizedString("CODE", comment: "Learning step type: code")
            case .context: return NSLocalizedString("CONTEXT", comment: "Learning step type: context")
            case .experiment: return NSLocalizedString("EXPERIMENT", comment: "Learning step type: experiment")
            case .find: return NSLocalizedString("FIND", comment: "Learning step type: find")
            }
        }
    }
    
    public var identifier: String
    public var index: Int = 0
    public var type: StepType = .unknown
    public weak var parentTrail: LearningTrail?
    public var title: String?
    public var rootBlock = LearningBlock.createRootBlock()
    
    public var blocks: [LearningBlock] {
        return flattenendBlocks(rootBlock.childBlocks)
    }

    private func flattenendBlocks(_ blocks: [LearningBlock]) -> [LearningBlock] {
        return blocks.flatMap { (myBlock) -> [LearningBlock] in
            var result = [myBlock]
            result += flattenendBlocks(myBlock.childBlocks)
            return result
        }
    }
    
    /// True if the step is assessable.
    public var isAssessable: Bool = false
    
    /// The current state of assessment for this step.
    public var assessmentState: LearningAssessment.State = .unknown
    
    private var stateHasBeenLoaded = false
    
    public init(in trail: LearningTrail, identifier: String, index: Int) {
        self.parentTrail = trail
        self.identifier = identifier
        self.index = index
    }
    
    func initializeState() {
        rootBlock.initializeVisibleState(visible: true)
        rootBlock.initializeGroupState(level: 0)
    }
    
    // Loads any previously saved state.
    func loadState(isValid: Bool) {
        guard !stateHasBeenLoaded else { return }
        stateHasBeenLoaded = true
        guard let responseBlock = blocks.filter({ $0.type == .response }).first else { return }
        
        // Currently only response blocks need state loaded.
        // One response block per step max.
        let xmlContent = responseBlock.xmlPackagedContent(.linesLeftTrimmed)
        if let learningResponse = LearningResponse(identifier: responseBlock.accessibilityIdentifier, xml: xmlContent, attributes: responseBlock.attributes) {
            
            if !isValid {
                learningResponse.clearState()
                assessmentState = .unknown
            }
            
            _ = learningResponse.loadState()
            if isAssessable && learningResponse.isAnsweredCorrectly {
                assessmentState = .completedSuccessfully
            }
        }
        
    }
}

extension LearningStep: Equatable {
    public static func == (lhs: LearningStep, rhs: LearningStep) -> Bool {
        return lhs.identifier == rhs.identifier
    }
}
