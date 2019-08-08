//
//  Assessments.swift
//
//  Copyright © 2017,2018 Apple Inc. All rights reserved.
//
import PlaygroundSupport
import UIKit

private let successString = NSLocalizedString("Whoa! It’s a note, and it looks like it’s written in code! Who left it? Were you *supposed* to find it? If you can decrypt it, maybe you can find out!\n\n[Next Page](@next)", comment: "Success for opening note.")

public func assessmentPoint() -> PlaygroundPage.AssessmentStatus {

    return .pass(message: successString)
}
