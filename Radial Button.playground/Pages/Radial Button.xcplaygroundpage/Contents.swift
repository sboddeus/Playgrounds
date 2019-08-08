// Radial Button fun

import UIKit
import PlaygroundSupport

var colors = [UIColor(red: 39/255, green: 183/255, blue: 255/255, alpha: 1.0),
              UIColor(red: 255/255, green: 197/255, blue: 51/255, alpha: 1.0),
              UIColor(red: 255/255, green: 77/255, blue: 77/255, alpha: 1.0),
              UIColor(red: 62/255, green: 255/255, blue: 45/255, alpha: 1.0),
              UIColor(red: 255/255, green: 0/255, blue: 138/255, alpha: 1.0),
              UIColor(red: 91/255, green: 69/255, blue: 202/255, alpha: 1.0),
              UIColor(red: 63/255, green: 69/255, blue: 75/255, alpha: 1.0),
              UIColor(red: 246/255, green: 246/255, blue: 246/255, alpha: 1.0)]


let containerView = UIView(frame: CGRect(x: 0, y: 0, width: 375, height: 667))
containerView.backgroundColor = .black

let page = PlaygroundPage.current
page.needsIndefiniteExecution = true
PlaygroundPage.current.liveView = containerView

// View classes
protocol ButtonDelegate {
    func onClick(sender: Button)
    func onLongPress(sender: Button)
    func wasDragged(sender: Button)
}

class Button: UIView {
    var delegate: ButtonDelegate?
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        let click = UITapGestureRecognizer(target: self, action: #selector(Button.onClick))
        self.addGestureRecognizer(click)
        
        let longPress = UILongPressGestureRecognizer(target: self, action: #selector(Button.longPress))
        self.addGestureRecognizer(longPress)
        
        let pan = UIPanGestureRecognizer(target: self, action: #selector(Button.handlePan))
        self.addGestureRecognizer(pan)
        
        // set roundedness
        layer.cornerRadius = frame.width/2
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    @objc func onClick() {
        delegate?.onClick(sender: self)
    }
    
    @objc func longPress(sender: UILongPressGestureRecognizer) {
        if sender.state == UIGestureRecognizer.State.began {
            delegate?.onLongPress(sender: self)
        }
    }
    
    @objc func handlePan(recognizer: UIPanGestureRecognizer) {
        delegate?.wasDragged(sender: self)
        let margin = CGFloat(10.0)
        let translation = recognizer.translation(in: self)
        if let superview = self.superview {
            
            let halfViewWidth = self.frame.width / 2
            let halfViewHeight = self.frame.height / 2
            let superviewWidth = superview.frame.width
            let superviewHeight = superview.frame.height
            
            let minX = halfViewWidth + margin
            let maxX = superviewWidth - (halfViewWidth + margin)
            
            let minY = halfViewHeight + margin
            let maxY = superviewHeight - (halfViewHeight + margin)
            
            if recognizer.state == .ended {
                
                let velocity = recognizer.velocity(in: self)
                let endingX: CGFloat
                
                if velocity.x > 1_000 {
                    // Push to the right hand side
                    endingX = superviewWidth - (halfViewWidth + margin)
                } else if velocity.x < -1_000 {
                    // Push to the left hand side
                    endingX = halfViewWidth + margin
                } else {
                    // Pick the nearest side
                    endingX = self.center.x < superviewWidth / 2
                        ? halfViewWidth + margin
                        : superviewWidth - (halfViewWidth + margin)
                }
                
                let endingY: CGFloat
                let velY = recognizer.velocity(in: self).y / 25
                if velY < 0 {
                    endingY = max(self.center.y + velY, 20)
                } else {
                    endingY = max(self.center.y + velY, self.frame.height - 20)
                }
                
                let inBoundsX = min(max(minX, endingX), maxX)
                let inBoundsY = min(max(minY, endingY), maxY)
                
                UIView.animate(withDuration: 0.5,
                               delay: 0,
                               usingSpringWithDamping: 0.5,
                               initialSpringVelocity: 1.0,
                               options: [],
                               animations: {
                                self.center = CGPoint(x: inBoundsX,
                                                      y: inBoundsY)
                                self.alpha = 1.0
                }, completion: nil)
            } else {
                let calculatedX = self.center.x + translation.x
                let inBoundsX = min(max(minX, calculatedX), maxX)
                
                let calculatedY = self.center.y + translation.y
                let inBoundsY = min(max(minY, calculatedY), maxY)
                
                self.center = CGPoint(x: inBoundsX, y: inBoundsY)
            }
        }
        recognizer.setTranslation(CGPoint.zero, in: self)
    }
}

let radialButtonRect = CGRect(x: 0, y: 0, width: 50, height: 50)
let radialButton = Button(frame: radialButtonRect)
radialButton.backgroundColor = .red

containerView.addSubview(radialButton)

class ButtonMultiplier: ButtonDelegate {
    func onClick(sender: Button) {
        if sender != coreButton {
            coreButton.backgroundColor = sender.backgroundColor
        }
        hideRadials()
    }

    func onLongPress(sender: Button) {
        hideRadials()
        makeButtons(inView: containerView, aroundView: sender, count: 5)
    }
    
    func wasDragged(sender: Button) {
        if !radialButtons.isEmpty {
            hideRadials()
        }
    }

    let margin = CGFloat(100.0)
    let coreButton: Button
    let containerView: UIView
    
    private var radialButtons: [Button]
    
    init(view: UIView, button: Button) {
        radialButtons = []
        coreButton = button
        containerView = view
        button.delegate
        = self
    }
    
    private func point(withDegrees: CGFloat, fromPoint: CGPoint, origin: CGPoint) -> CGPoint {
        
        let fromCorrectedPoint = CGPoint(x: fromPoint.x - origin.x, y: fromPoint.y - origin.y)
        let radian = withDegrees * CGFloat(Double.pi/180)
        
        let newX = fromCorrectedPoint.x * cos(radian) - fromCorrectedPoint.y * sin(radian) + origin.x
        let newY = fromCorrectedPoint.x * sin(radian) - fromCorrectedPoint.y * cos(radian) + origin.y
        
        return CGPoint(x: newX, y: newY)
    }
    
    func makeButtons(inView: UIView, aroundView: UIView, count: Int) {
        enum LeftRight { case left; case right }
        let buttonPosition = aroundView.center.x < inView.frame.width/2 ? LeftRight.left : LeftRight.right
        
        if aroundView.center.y < margin {
            UIView.animate(withDuration: 0.1) {
                aroundView.center.y = self.margin + aroundView.frame.height
            }
        } else if aroundView.center.y > inView.frame.height - margin {
            UIView.animate(withDuration: 0.1) {
                aroundView.center.y = inView.frame.height - self.margin - aroundView.frame.height
            }
        }
        
        let seperation = 180 / (count - 1)
        let firstPoint = CGPoint(x: aroundView.center.x, y: aroundView.center.y + self.margin)
        let newPoints = [firstPoint] + Array(1...count).map { point(withDegrees: CGFloat( (buttonPosition == .left ? seperation : -seperation) * $0) - 180, fromPoint: firstPoint, origin: aroundView.center) }
        
        radialButtons = Array(0..<count).map {_ in 
            let button = Button(frame: CGRect(x: aroundView.frame.origin.x, y: aroundView.frame.origin.y, width: radialButtonRect.width, height: radialButtonRect.height))
            button.backgroundColor = .clear
            button.delegate = self
            return button
        }
            
        for pairs in zip(radialButtons, newPoints) {
            inView.addSubview(pairs.0)
            UIView.animate(withDuration: 0.1) {
                pairs.0.center = pairs.1
                pairs.0.backgroundColor = colors.randomElement()
            }
        }
    }
    
    private func hideRadials() {
        guard !radialButtons.isEmpty else { return }
        
        for button in radialButtons {
            UIView.animate(withDuration: 0.3, animations: { 
                button.center = self.coreButton.center
                button.backgroundColor = .clear
            }, completion:  { fin in
                button.removeFromSuperview()
            })
        }
        
        radialButtons = []
    }
}

ButtonMultiplier(view: containerView, button: radialButton)


