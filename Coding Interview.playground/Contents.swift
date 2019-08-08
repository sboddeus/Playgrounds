// To produce screen graphs and in support of some of our future features we need to scan the view hierarchy in different ways. One algorithm we recently needed for a proof of concept was to get all views of a certain depth. How would you design this algortihm? What is the efficieny of your solution?

import UIKit
import PlaygroundSupport

let containerView = UIView(frame: CGRect(x: 0, y: 0, width: 375, height: 667))
containerView.backgroundColor = .black

let page = PlaygroundPage.current
page.needsIndefiniteExecution = true
PlaygroundPage.current.liveView = containerView

let view1 = UIView(frame: CGRect(x: 0, y: 0, width: 400, height: 500))
view1.backgroundColor = .blue
let view2 = UIView(frame: CGRect(x: 10, y: 10, width: 350, height: 490))
view2.backgroundColor = .yellow
let view3 = UIView(frame: CGRect(x: 10, y: 10, width: 300, height: 450))
view3.backgroundColor = .red
let view4 = UIView(frame: CGRect(x: 10, y: 10, width: 130, height: 400))
view4.backgroundColor = .green
let view5 = UIView(frame: CGRect(x: 150, y: 10, width: 130, height: 400))
view5.backgroundColor = .purple
let view6 = UIView(frame: CGRect(x: 10, y: 10, width: 100, height: 300))
view6.backgroundColor = .black
let view7 = UIView(frame: CGRect(x: 10, y: 10, width: 25, height: 200))
view7.backgroundColor = .white
let view8 = UIView(frame: CGRect(x: 10, y: 10, width: 100, height: 300))
view8.backgroundColor = .cyan

containerView.addSubview(view1)
view1.addSubview(view2)
view2.addSubview(view3)
view3.addSubview(view4)
view4.addSubview(view8)
view3.addSubview(view5)
view5.addSubview(view6)
view6.addSubview(view7)
// For Depth 0 we should get view1
// For depth 1 we should get view2
// For depth 2 we should get view3
// For depth 3 we should get view4 and view5
// For depth 4 we should get view6 and view8
// For depth 5 we should get view7

// Complete the function below and run the for statement with different depths below to test your solution
// Can you make your solution print the number of required iterations?


func views(ofDepth depth: Int, withRootView rootView: UIView) -> [UIView] {
    guard depth != 0 else { return [rootView] }
    return rootView.subviews.flatMap({ subview in views(ofDepth: depth - 1, withRootView: subview) })
}


for view in views(ofDepth: 10, withRootView: view1) {
    view.layer.borderColor = UIColor.gray.cgColor
    view.layer.borderWidth = 5
}
