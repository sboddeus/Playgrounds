import UIKit
import PlaygroundSupport

let page = PlaygroundPage.current
page.needsIndefiniteExecution = true

let containerView = UIView(frame: CGRect(x: 0, y: 0, width: 375, height: 667))
containerView.backgroundColor = .blue
let otherView = UIView(frame: CGRect(x: 0, y: 0, width: 10, height: 40))
otherView.backgroundColor = .green
containerView.addSubview(otherView)

PlaygroundPage.current.liveView = containerView

let t = MemoryLayout<Double>.size


