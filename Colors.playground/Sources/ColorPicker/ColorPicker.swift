//
//  ColorPicker.swift
//  Colors Playground, WWDC18 scholarship submission
//
//  Created by Andreas Neusüß on 23.03.18.
//  Copyright © 2018 Andreas Neusüß. All rights reserved.
//

import UIKit
import QuartzCore

@IBDesignable
/// This class draws a circular color picker. The user can interact with it by dragging the handle. Events gets reported using the target/action mechanism (didChangeValue).
final class ColorPicker: UIControl {
    
    
    /// Current color that is selected.
    public var currentColor: UIColor = .red {
        didSet {
            //no need to re display as the handle is drawn somewhere else.
            //            setNeedsDisplay()
        }
    }
    
    /// Border color around the color wheel.
    @IBInspectable
    public var borderColor: UIColor = UIColor.color(from: 0xA7A219) {
        didSet {
            setNeedsDisplay()
        }
    }
    
    var usesP3ColorSpace: Bool = false {
        didSet {
            moveHandle(to: currentAngle)
            // Set the animationInProgress to true to mimic an automatic change in the current color. It will be sent to the ColorViewDelegate as not caused by user interaction.
            animationInProgress = true
            sendActions(for: .valueChanged)
            animationInProgress = false
        }
    }
    
    /// The interaction delegate, useful for preventing scrolling a CollectionView.
    weak var interactionDelegate: InteractionNotifiable?
    
    /// Radius of the color wheel.
    fileprivate var radius: CGFloat = 0
    
    /// Width of the wheel, think about it as line width.
    fileprivate let widthOfColorWheel: CGFloat = 10
    
    /// Width of the handle that the user can drag.
    fileprivate let widthOfHandle: CGFloat = 30
    
    /// Current angle that the user has set. Usually, 0° is on 3 o'clock. From there, it counts conterclockwise as the angle gets bigger. To start at 12 o'clock, the initial value must be set to 90°.
    fileprivate var currentAngle: CGFloat = 0
    
    /// Rectangle for the color wheel. Depends on ```radius``` and ```widthOfColorWheel``` and ```self.bounds```.
    fileprivate var rectForWheelImage: CGRect {
        
        var space = min(self.bounds.width, self.bounds.height) / 2 - self.radius - self.widthOfColorWheel / 2
        space -= 2
        return self.bounds.insetBy(dx: space, dy: space)
    }
    
    /// ImageView that draws an image of the color wheel offside of the screen. It is used to get the currently selected color and is drawn out off sight because the handle would intersect with the color picking.
    /// In layoutSubviews the frame is moved out off sight because we need to wait for the layout process to finish first.
    //    private lazy var invisibleImageview : UIImageView = {
    //        let frame = self.rectForWheelImage
    //
    //
    //        let imageView = UIImageView(frame: frame)
    //
    //        imageView.image = UIImage(named: "Color Wheel", in: Bundle(for: type(of: self)), compatibleWith: nil)
    //
    //        return imageView
    //    }()
    
    /// ImageView that is used to draw the image of the color wheel. It gets masked during layoutSubviews() to a circular shape.
    private lazy var colorWheelImageView : UIImageView = {
        let frame = self.rectForWheelImage
        
        let imageView = UIImageView(frame: frame)
        
        imageView.image = UIImage(named: "Color Wheel", in: Bundle(for: type(of: self)), compatibleWith: nil)
        
        
        imageView.layer.isOpaque = false
        
        return imageView
    }()
    
    /// CAShapeLayer that is used for masking the colorWheelImageView into a circular shape.
    private lazy var circularShapeForImageView = CAShapeLayer()
    
    /// A seperate view is used to draw the handle as the drawing code can not draw above a subview (the colorWheelImageView).
    private lazy var handleDrawer = HandleDrawer()
    
    /// Used to perform an animation of the handle.
    var displayLink : CADisplayLink?
    
    /// Final angle of the animation, where the final color is located.
    var finalAngle: CGFloat = 0
    
    /// Bool that indicates if an animaton is ongoing.
    var animationInProgress = false
    
    /// Bool that indicates if the animation should run clockwise or counterclockwise.
    var animatingHandleClockwise = true
    
    override init(frame: CGRect) {
        
        super.init(frame: frame)
        
        isOpaque = false
        //                layer.borderColor = UIColor.lightGray.cgColor
        //                layer.borderWidth = 1
        
        //        addSubview(invisibleImageview)
        addSubview(handleDrawer)
        insertSubview(colorWheelImageView, at: 0)
        backgroundColor = .clear
        contentMode = .redraw
    }
    
    override func layoutSubviews() {
        radius = min(frame.size.width, frame.size.height) / 2 - (2*widthOfColorWheel + widthOfHandle / 5.0)
        var frameForImageView = rectForWheelImage
        frameForImageView.origin.y -= 2500
        //        invisibleImageview.frame = frameForImageView
        
        handleDrawer.frame = rectForWheelImage.insetBy(dx: -(widthOfHandle / 2.0 + 2), dy: -(widthOfHandle / 2.0 + 2))
        
        handleDrawer.widthOfHandle = widthOfHandle
        
        let handleCenterForDrawer = convert(pointOnCircle(for: currentAngle), to: handleDrawer)
        handleDrawer.update(handleCenter: handleCenterForDrawer, color: currentColor)
        
        colorWheelImageView.frame = rectForWheelImage
        
        
        //Masking the imageview using a CAShapeLayer
        circularShapeForImageView.frame = colorWheelImageView.bounds
        let path = UIBezierPath(arcCenter: CGPoint(x:circularShapeForImageView.bounds.midX, y:circularShapeForImageView.bounds.midY), radius: radius, startAngle: 0, endAngle: 2*CGFloat.pi, clockwise: false)
        
        circularShapeForImageView.path = path.cgPath
        circularShapeForImageView.fillColor = UIColor.clear.cgColor
        circularShapeForImageView.strokeColor = UIColor.black.cgColor
        circularShapeForImageView.lineWidth = widthOfColorWheel
        
        colorWheelImageView.layer.mask = circularShapeForImageView
        
        
        //        printColorDictionary()
        
        //        let aView = UIView(frame: bounds)
        //        aView.backgroundColor = UIColor.red
        //        addSubview(aView)
        super.layoutSubviews()
    }
    
    
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func beginTracking(_ touch: UITouch, with event: UIEvent?) -> Bool {
        super.beginTracking(touch, with: event)
        interactionDelegate?.interactionStarted()
        
        let interactionPoint = touch.location(in: self)
        
        moveHandle(to: interactionPoint)
        sendActions(for: .valueChanged)
        
        //Stop the animation because the user interacted with the control
        displayLink?.invalidate()
        animationInProgress = false
        
        UIView.animate(withDuration: 0.15, delay: 0, options: .curveEaseIn, animations: { () -> Void in
            self.handleDrawer.transform = self.handleDrawer.transform.scaledBy(x: 1.2, y: 1.2)
        }, completion: nil)
        
        return true
    }
    
    override func continueTracking(_ touch: UITouch, with event: UIEvent?) -> Bool {
        super.continueTracking(touch, with: event)
        
        let interactionPoint = touch.location(in: self)
        moveHandle(to: interactionPoint)
        sendActions(for: .valueChanged)
        
        return true
    }
    
    override func endTracking(_ touch: UITouch?, with event: UIEvent?) {
        super.endTracking(touch, with: event)
        interactionDelegate?.interactionEnded()
        
        if handleDrawer.transform.d > 1 {
            //If the scale is larger than 1, the view is already animated.
            UIView.animate(withDuration: 0.15, delay: 0, options: [.curveEaseOut, .beginFromCurrentState], animations: { () -> Void in
                self.handleDrawer.transform = .identity
            }, completion: nil)
        }
    }
    
    public override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
        if self.point(inside: point, with: event) {
            return self
        }
        return nil
    }
    
    
    override func draw(_ rect: CGRect) {
        //drawing a border
        let center = CGPoint(x: rect.midX, y: rect.midY)
        
        let context = UIGraphicsGetCurrentContext()
        context?.addArc(center: center, radius: radius, startAngle: 0, endAngle: CGFloat.pi * 2, clockwise: false)
        borderColor.set()
        
        
        context?.setLineWidth(widthOfColorWheel+2)
        context?.setLineCap(.butt)
        context?.drawPath(using: .stroke)
        
        
        //        let path = UIBezierPath()
        //        path.move(to: pointOnCircle(for: 0))
        //
        //        for i in 1..<360 {
        //            path.addLine(to: pointOnCircle(for: CGFloat(i)))
        //        }
        //        UIColor.black.set()
        //        path.stroke()
    }
    
    
    /// This Method moved the handle to a given angle, animated if so desired.
    ///
    /// - Parameters:
    ///   - angle: The destination angle to which the handle sould be moved to.
    ///   - animated: True if the handle should be moved using an animation.
    func move(to angle: Float, animated: Bool = false) {
        let difference = fabs((CGFloat(angle) - currentAngle))
        guard difference > 1.5 && difference < 358 else {
            //Smaller than 2 or to catch the 360° == 0° error
            //            print("Difference not big enough for moving picker: \((CGFloat(angle) - currentAngle))")
            return
        }
        print("Moving to angle: \(angle), current: \(currentAngle)")
        var angle = angle
        
        //        if angle  <= 1.5 {
        //            return
        //        }
        //set upper and lower bounds.
        if angle < 0 {
            angle = 0
        }
        if angle >= 360 {
            angle -= 360
        }
        if animated {
            //invalidate a already started DisplayLink
            displayLink?.invalidate()
            
            finalAngle = CGFloat(angle)
            
            
            //set up and schedule a new DisplayLink
            displayLink = CADisplayLink(target: self, selector: #selector(displayLinkFired))
            displayLink?.add(to: .current, forMode: .defaultRunLoopMode)
            animationInProgress = true
            var clockwiseCalculationResult = (finalAngle - currentAngle)
            if clockwiseCalculationResult > 180 {
                clockwiseCalculationResult -= 180
            }
            animatingHandleClockwise = clockwiseCalculationResult < 0
            //            print("Animating clockwise: \(animatingHandleClockwise)")
        }
        else {
            let finalPointForAngle = pointOnCircle(for: CGFloat(angle))
            moveHandle(to: finalPointForAngle)
        }
    }
    
    /// This method is called if the DisplayLink fired. It is responsible for peforming a step of the animation that moves the handle to a given position.
    @objc fileprivate func displayLinkFired() {
        
        let stepSize: CGFloat = 8
        
        currentAngle = animatingHandleClockwise ? currentAngle - stepSize : currentAngle + stepSize
        
        //Set upper and lower bounds for the angle
        if currentAngle < 0 {
            currentAngle = 360
        }
        else if currentAngle >= 360 {
            currentAngle = 0
        }
        
        let finalAngleCouldHaveBeenSkipped = false//fabs(finalAngle - 360) < stepSize
        
        
        //inform the containing view of changes in the current angle. It should use this information to update the color clider underneath the color wheel.
        sendActions(for: .valueChanged)
        
        //Move the handle to the new calculated angle.
        moveHandle(to: currentAngle)
        
        
        //Stop the animation if the current angle is close enough to the final angle.
        if fabs(currentAngle - finalAngle) <= (stepSize) || finalAngleCouldHaveBeenSkipped
        {
            currentAngle = finalAngle
            moveHandle(to: currentAngle)
            sendActions(for: .valueChanged)
            
            displayLink?.invalidate()
            animationInProgress = false
        }
        else {
            //            print("Not reached final angle: \(finalAngle), current: \(currentAngle), difference: \(fabs(currentAngle - finalAngle))")
        }
    }
    
    
    /// This method should be called when the user dragged the handle to a new position, coded in a CGPoint. It converts the point to an angle and asks the method ```moveHandle(to:)``` to perform changes.
    ///
    /// - parameter location: Location to which the handle should be moved to.
    fileprivate func  moveHandle(to location: CGPoint, animated: Bool = false) {
        let center = CGPoint(x: bounds.midX, y: bounds.midY)
        
        var angle = floor(center.angle(to: location))
        angle = (360.0 - angle)
        
        if animated {
            move(to: Float(angle), animated: true)
        }
        else {
            moveHandle(to: angle)
        }
    }
    
    
    /// This method moves the handle to a given angle. It updates the current color by picking the pixel from the invisible imageView. After updating the ```currentColor```, the ```handleDrawer``` is asked to update the handle position based on the angle provided as an argument here.
    ///
    /// - Parameter angle: Angle to which the handle should be moved to.
    fileprivate func moveHandle(to angle: CGFloat) {
        self.currentAngle = angle
        
        let handleCenter = pointOnCircle(for: currentAngle)
        let handleDrawerForDrawer = convert(handleCenter, to: handleDrawer)
        
        let color: UIColor
        color = UIColor.init(hue: currentAngle/360.0, saturation: 1, brightness: 1, alpha: 1)
        //        if usesP3ColorSpace {
        //            color = UIColor.init(displayP3Hue: currentAngle/360.0, saturation: 1, brightness: 1, alpha: 1)
        //
        //        }
        //        else {
        //            color = UIColor.init(hue: currentAngle/360.0, saturation: 1, brightness: 1, alpha: 1)
        //        }
        currentColor = color
        
        handleDrawer.update(handleCenter: handleDrawerForDrawer, color: currentColor)
        
        
    }
    
    
    
    /// This method calculates a point on the color wheel circle for a given angle. Therefore it converts a angle into a point on the line in a cartesian coordinate system.
    ///
    /// - parameter angle: The angle for which the point should be calculated for.
    fileprivate func pointOnCircle(for angle: CGFloat) -> CGPoint {
        //        let center = CGPoint(x: bounds.midX, y: bounds.midY )
        let center = CGPoint(x: bounds.size.width/2.0 - widthOfColorWheel/2.0, y: bounds.size.height/2.0 - widthOfColorWheel/2.0);
        
        //        let y = round((radius + widthOfColorWheel/2 - 2) * sin(-angle.toRadians())) + center.y
        //        let x = round((radius + widthOfColorWheel/2 - 2) * cos(-angle.toRadians())) + center.x
        
        let y = round(radius * sin(-angle.toRadians())) + center.y
        let x = round(radius * cos(-angle.toRadians())) + center.x
        
        let result = CGPoint(x: x + (widthOfColorWheel / 2.0), y: y + (widthOfColorWheel / 2.0))
        return result
    }
    
}
extension CGPoint {
    
    /// This method calculates the angle between a line connecting two points and 12 o'clock (or North).
    /// If you call this method on one point, you pass another point to which a (imaginary) line will be drawn to. The calculated angle is between that line and a line from the point towars 12 o'clock (or North).
    ///
    /// - parameter point: The second point to which a imaginary line will be drawn to in order to calculate the angle between this line and 12 o'clock (or North).
    ///
    /// - returns: Angle between both points form 12 o'clock (or North).
    func angle(to point: CGPoint) -> CGFloat {
        //formula: ⍺ = arcTan((x2 - x1)/(y1 - y2))
        
        
        let delta = CGPoint(x: point.x - x, y: point.y - y)
        //        let vmag = (delta.x.squared() + delta.y.squared()).squared()
        //        delta.x /= vmag
        //        delta.y /= vmag
        
        let radians = atan2(delta.y, delta.x)
        let result = radians.toDegree()
        return (result >= 0) ? result : result + 360.0
    }
}

extension CGFloat {
    
    /// The number squared.
    ///
    /// - returns: ```self``` squared.
    func squared() -> CGFloat {
        return self * self
    }
    
    /// Converts the number to degrees.
    ///
    /// - returns: The number in degrees (°).
    func toDegree() -> CGFloat {
        return self * 180.0 / CGFloat.pi
    }
    
    /// Converts the number to radians.
    ///
    /// - returns: The number in radians.
    func toRadians() -> CGFloat {
        return self * CGFloat.pi / 180.0
    }
}

