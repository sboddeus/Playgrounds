// A heat map based analytics overlay
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
containerView.backgroundColor = .white

let page = PlaygroundPage.current
page.needsIndefiniteExecution = true
PlaygroundPage.current.liveView = containerView

class Colors {
    var gl:CAGradientLayer!
    
    init(frame: CGRect, color: UIColor) {
        let colorTop = color.cgColor
        //UIColor(red: 192.0 / 255.0, green: 38.0 / 255.0, blue: 42.0 / 255.0, alpha: 1.0).cgColor
        let butColor = color.withAlphaComponent(0.5)
        let colorBottom = butColor.cgColor //UIColor(red: 35.0 / 255.0, green: 2.0 / 255.0, blue: 2.0 / 255.0, alpha: 1.0).cgColor
        
        gl = CAGradientLayer()
        gl.frame = frame
        gl.colors = [colorTop, colorBottom]
        //gl.startPoint = CGPoint(x: 0.2, y: 0)
        //gl.endPoint = CGPoint(x: 0.8, y:1.0)
        //gl.locations = [CGPoint(x: 0, y: 0), CGPoint(x: 1.0, y:1.0)]
    }
}

extension CAGradientLayer
{
    func animateChanges(to colors: [UIColor],
                        duration: TimeInterval)
    {
        CATransaction.begin()
        CATransaction.setCompletionBlock({
            // Set to final colors when animation ends
            self.colors = colors.map{ $0.cgColor }
        })
        let animation = CABasicAnimation(keyPath: "colors")
        animation.duration = duration
        animation.toValue = colors.map{ $0.cgColor }
        animation.fillMode = CAMediaTimingFillMode.forwards
        animation.isRemovedOnCompletion = false
        add(animation, forKey: "changeColors")
        CATransaction.commit()
    }
}

struct ColorPoint {
    let color: UIColor
    let value: CGFloat
}

class HeatMapColor {
    var colorPoints: [ColorPoint]
    
    init(colorPoints: [ColorPoint]) {
        self.colorPoints = colorPoints
    }
    
    func colorAt(value: CGFloat) -> UIColor {
        if(colorPoints.isEmpty) { return UIColor.black }
        
        let colorsPointsToUse = colorPoints.sorted { (colorPointA, colorPointB) -> Bool in
            return colorPointA.value <= colorPointB.value
        }
        
        for (index, colorPoint) in colorsPointsToUse.enumerated() where value < colorPoint.value {
            let previousColorPoint = colorsPointsToUse[max(0, index - 1)]
            let valueDiff = previousColorPoint.value - colorPoint.value
            let fraction = valueDiff == 0 ? 0 : (value - colorPoint.value) / valueDiff
            
            guard
                let prevComp = previousColorPoint.color.cgColor.components,
                let currComp = colorPoint.color.cgColor.components else { continue }
            
            let red = (prevComp[0] - currComp[0]) * fraction + currComp[0]
            let green = (prevComp[1] - currComp[1]) * fraction + currComp[1]
            let blue = (prevComp[2] - currComp[2]) * fraction + currComp[2]
            
            return UIColor(red: red, green: green, blue: blue, alpha: 1.0)
        }
        
        return colorsPointsToUse.last!.color
    }
}

class OverlayView: UIView {
    var heatColors = HeatMapColor(colorPoints: [ColorPoint(color: colors[2], value: 0), ColorPoint(color: colors[5], value: 1)])
    var label: UILabel
    var gradientLayer: CAGradientLayer! = nil
    override init(frame: CGRect) {
        label = UILabel()
        super.init(frame: frame)
        gradientLayer = Colors(frame: bounds, color: heatColors.colorAt(value: 0.8)).gl
        backgroundColor = .white
        layer.insertSublayer(gradientLayer, at: 0)
        
        // label
        label.translatesAutoresizingMaskIntoConstraints = false
        addSubview(label)
        label.trailingAnchor.constraint(equalTo: self.trailingAnchor).isActive = true
        label.leadingAnchor.constraint(equalTo: self.leadingAnchor).isActive = true
        label.topAnchor.constraint(equalTo: self.topAnchor).isActive = true
        label.bottomAnchor.constraint(equalTo: self.bottomAnchor).isActive = true
        label.textAlignment = .center
        let strokeTextAttributes: [NSAttributedString.Key : Any] = [
            .strokeColor : UIColor.black,
            .foregroundColor : UIColor.white,
            .strokeWidth : -2.0,
            ]
        
        label.attributedText = NSAttributedString(string: "TESTING", attributes: strokeTextAttributes)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    var percentage: Float = 0 {
        didSet {
            let topCol = heatColors.colorAt(value: CGFloat(percentage))
            let botCol = topCol.withAlphaComponent(0.5)
            gradientLayer.animateChanges(to: [topCol, botCol], duration: 0.3)
            
            // Label
            let strokeTextAttributes: [NSAttributedString.Key : Any] = [
                .strokeColor : UIColor.black,
                .foregroundColor : UIColor.white,
                .strokeWidth : -2.0,
                ]
            
            label.attributedText = NSAttributedString(string: "\(percentage * 100)", attributes: strokeTextAttributes)
        }
    }
}

class SliderHandler {
    let callBack: (Float) -> ()
    let slider: UISlider
    init(slider: UISlider, callBack: @escaping (Float) -> ()) {
        self.slider = slider
        self.callBack = callBack
        
        slider.addTarget(self, action: #selector(SliderHandler.handleCall), for: .valueChanged)
    }
    
    @objc func handleCall() {
        callBack(slider.value)
    }
}

let overlay = OverlayView(frame: CGRect(origin: CGPoint(x: containerView.frame.width/2, y: containerView.frame.height/2), size: CGSize(width: 200, height: 100)))

let slider = UISlider(frame: CGRect(origin: CGPoint(x: 0, y: 0), size: CGSize(width: 200, height: 100)))

slider.minimumValue = 0.0
slider.maximumValue = 1.0

let handler = SliderHandler(slider: slider, callBack: {value in overlay.percentage = value })

containerView.addSubview(slider)
containerView.addSubview(overlay)

