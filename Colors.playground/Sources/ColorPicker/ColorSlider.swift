//
//  ColorSlider.swift
//  Colors Playground, WWDC18 scholarship submission
//
//  Created by Andreas Neusüß on 24.03.18.
//  Copyright © 2018 Andreas Neusüß. All rights reserved.
//

import UIKit
import QuartzCore

enum SliderOrientation {
    case horizontal
    case vertical
}
/// This class draws a linear slider in which the user can set a component of a color by dragging a handle.
public final class ColorSlider: UIControl {
    
    ///Current value of the slider
    fileprivate var currentValue: CGFloat = 0.85
    ///Height of the sliders gradient
    fileprivate var heightOfSlider: CGFloat = 0
    ///Gap that limits the height of the slider.
    private let heightGap: CGFloat = 15
    ///Width of the handle that the user can drag.
    private var widthOfHandle: CGFloat = 0
    ///The handle has a small bright border around the colored center. This variable defines its thickness.
    private let borderWidthOfHandle: CGFloat = 3
    ///Gap between the handle and the cornders if the view.
    private let handleGap: CGFloat = 2
    ///Max value to which the slider can be set to. Needed to limit the interaction and prevent cutting edges off because of clipping.
    fileprivate var maxValue: CGFloat = 0
    ///Min value to which the slider can be set to. Needed to limit the interaction and prevent cutting edges off because of clipping.
    fileprivate var minValue: CGFloat = 0
    
    ///The color of the colored center of the handle. It sould be the currently selected color, including the sliders value.
    public var colorOfHandle: UIColor = .red {
        didSet {
            updateHandle()
            setNeedsDisplay()
        }
    }
    
    /// Border color around the slider.
    @IBInspectable
    public var borderColor: UIColor = UIColor.color(from: 0xA7A219) {
        didSet {
            setNeedsDisplay()
        }
    }
    
    /// Border width around the slider.
    @IBInspectable
    public var borderWidth: CGFloat = 1 {
        didSet {
            setNeedsDisplay()
        }
    }
    
    ///Color from which the linear gradient starts. It should only changed if the primary color is changed and will not be updated by any interaction with the slider.
    public var colorForGradient: UIColor = .red {
        didSet {
            setNeedsDisplay()
        }
    }
    
    ///Color where the linear gradient ends.
    public var endColorForGradient: UIColor = .white {
        didSet {
            setNeedsDisplay()
        }
    }
    
    ///The progress that the slider represents between 0 and 1.
    public var progress: CGFloat{
        //transform the internal currentValue (limited to [minValue, maxValue]) to the intercal [0, 1]
        /*
         .  x - min                                   max - min
         f(x) = ---------   ===>   f(min) = 0;  f(max) =  --------- = 1
         .  max - min                                 max - min
         */
        let value = (currentValue - minValue) / (maxValue - minValue)
        
        if orientation == .horizontal {
            //horizontal
            return value
        }
        else {
            //vertical
            return value //1-value
        }
        
    }
    
    /// The interaction delegate, useful for preventing scrolling a CollectionView.
    weak var interactionDelegate: InteractionNotifiable?
    
    /// HandleDrawer that draws the handle as a subview.
    fileprivate let handleDrawer = HandleDrawer()
    
    /// DisplayLink used for animating a handle movement.
    fileprivate var displayLink: CADisplayLink?
    
    /// Final value for the animation.
    fileprivate var finalValue: CGFloat = 0
    
    /// Bool that indicates if an animaton is ongoing.
    var animationInProgress = false
    
    /// Orientation of the slider relative to the color wheel.
    var orientation: SliderOrientation = .horizontal
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        isOpaque = true
        //                layer.borderColor = UIColor.green.cgColor
        //                layer.borderWidth = 1
        
        backgroundColor = .clear
        addSubview(handleDrawer)
        contentMode = .redraw
    }
    
    public override func layoutSubviews() {
        let widthOrHeight: CGFloat
        let minCanidateDevisor: CGFloat
        
        if orientation == .horizontal {
            //horizontal
            widthOrHeight = frame.height
            minCanidateDevisor = frame.width
        }
        else {
            //vertical
            widthOrHeight = frame.width
            minCanidateDevisor = frame.height
        }
        heightOfSlider = min(widthOrHeight, 25) - heightGap
        widthOfHandle = max(widthOrHeight, 35) - 2.0 * borderWidthOfHandle - 2 * handleGap
        
        let paddingToSide = (borderWidthOfHandle + handleGap + widthOfHandle) / 2.0 + 1
        let minCanidate = paddingToSide / minCanidateDevisor
        
        maxValue = 1-(minCanidate)
        minValue = minCanidate
        
        if orientation == .horizontal {
            //horizontal
            currentValue = maxValue
        }
        else {
            //vertical
            currentValue = minValue
        }
        
        handleDrawer.widthOfHandle = widthOfHandle
        handleDrawer.frame = bounds.insetBy(dx: -(widthOfHandle / 2.0 + 2), dy: -(widthOfHandle / 2.0 + 2))
        
        updateHandle()
        
    }
    
    required public init?(coder aDecoder: NSCoder) {
        fatalError("Should not be used directly but embedded in a SliderView or ColorPickerView.")
    }
    
    
    
    override public func beginTracking(_ touch: UITouch, with event: UIEvent?) -> Bool {
        super.beginTracking(touch, with: event)
        interactionDelegate?.interactionStarted()
        
        let interactionPoint = touch.location(in: self)
        moveHandle(to: interactionPoint)
        sendActions(for: .valueChanged)
        
        return true
    }
    
    override public func continueTracking(_ touch: UITouch, with event: UIEvent?) -> Bool {
        super.continueTracking(touch, with: event)
        
        let interactionPoint = touch.location(in: self)
        moveHandle(to: interactionPoint)
        sendActions(for: .valueChanged)
        
        //Stop the animation because the user interacted with the control
        displayLink?.invalidate()
        animationInProgress = false
        
        return true
    }
    
    override public func endTracking(_ touch: UITouch?, with event: UIEvent?) {
        super.endTracking(touch, with: event)
        interactionDelegate?.interactionEnded()
    }
    
    public override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
        if self.point(inside: point, with: event) {
            return self
        }
        return nil
    }
    
    
    /// This function moves the handle to a given progress.
    /// The provided progress must be in [0, 1] and will be converted to internally used min and max values.
    ///
    /// - Parameters:
    ///   - progress: Progress to which the handle should be moved to.
    ///   - animated: True if the handle should be moved using an animation.
    func move(to progress: CGFloat, animated: Bool = false) {
        guard progress >= 0 && progress <= 1 else {
            return
        }
        guard fabs((CGFloat(progress) - self.progress)) > 0.01 else {
            
            //            print("Difference not big enough for moving slider: \(fabs((CGFloat(progress) - self.progress)))")
            return
        }
        
        let internalProgress = convertProgressToInternalMinMax(progress: progress)
        
        if animated {
            //invalidate a already started DisplayLink
            displayLink?.invalidate()
            
            finalValue = internalProgress
            
            //check if the new value is woth the animation
            if fabs((CGFloat(finalValue) - currentValue)) > 0.01 {
                
                //set up and schedule a new DisplayLink
                displayLink = CADisplayLink(target: self, selector: #selector(displayLinkFired))
                displayLink?.add(to: .current, forMode: .defaultRunLoopMode)
                animationInProgress = true
            }
            else {
                //                print("Difference not big enough for moving slider: \(fabs((CGFloat(finalValue) - currentValue)))")
            }
            
            
            
        }
        else {
            currentValue = internalProgress
            updateHandle()
        }
        
    }
    
    /// This method is called if the DisplayLink fired. It is responsible for peforming a step of the animation that moves the handle to a given position.
    @objc fileprivate func displayLinkFired() {
        let stepSize: CGFloat = 0.04
        
        if finalValue > currentValue {
            currentValue += stepSize
        }
        else {
            currentValue -= stepSize
        }
        
        if currentValue > maxValue {
            currentValue = maxValue
        }
        if currentValue < minValue {
            currentValue = minValue
        }
        
        sendActions(for: .valueChanged)
        
        updateHandle()
        
        if fabs(currentValue - finalValue) <= (stepSize / 2.0) {
            currentValue = finalValue
            displayLink?.invalidate()
            animationInProgress = false
        }
        
    }
    
    
    /// This method converts a given progress between 0 and 1 to the internal maximal and minimal values, that are below 1 and above 0 to leave space for the handle.
    ///
    /// - Parameter progress: The progress that should be converted.
    /// - Returns: The internal progress between minValue and maxValue.
    fileprivate func convertProgressToInternalMinMax(progress: CGFloat) -> CGFloat {
        /*
         [A, B] -> [a, b] where A=0, B=1  a=minValue, b=maxValue
         b - a
         (x - A) * -------- + a
         B - A
         */
        return progress * (maxValue - minValue) + minValue
    }
    
    public override func draw(_ rect: CGRect) {
        let context = UIGraphicsGetCurrentContext()
        
        let rectForMask: CGRect
        
        if orientation == .horizontal {
            //horizontal
            rectForMask = CGRect(x: borderWidth, y: (bounds.height - heightOfSlider) / 2.0, width: bounds.width - 2*borderWidth, height: heightOfSlider)
        }
        else {
            //vertical
            rectForMask = CGRect(x: (bounds.width - heightOfSlider) / 2.0, y: borderWidth, width: heightOfSlider, height: bounds.height - 2*borderWidth)
        }
        //        rectForMask.origin.y -= heightOfSlider / 2.0
        
        let maskPath = UIBezierPath(roundedRect: rectForMask, byRoundingCorners: .allCorners, cornerRadii: CGSize(width: heightOfSlider / 2.0, height: heightOfSlider / 2.0))
        
        //Safe the state to be able to access it again after the clipping is done. If we do not save the context here, the mask will also be applied to the handle, which is clearly not what we wanted.
        context?.saveGState()
        
        //Begin a new image context to draw the mask into
        UIGraphicsBeginImageContext(CGSize(width: self.bounds.size.width,height: self.bounds.size.height))
        
        let imageContext = UIGraphicsGetCurrentContext()
        UIColor.blue.set()
        
        imageContext?.setLineWidth(20)
        imageContext?.addPath(maskPath.cgPath)
        imageContext?.drawPath(using: .fill)
        
        //create a CGImage of a UIBezierPath and use this image as a mask.
        let mask = imageContext?.makeImage()
        UIGraphicsEndImageContext()
        
        //save the state before clipping, then use the mask as clipping mask.
        context?.saveGState()
        context?.clip(to: bounds, mask: mask!)
        
        
        //draw a gradient from the ```colorForGradient``` to ```endColorForGradient```
        let gradient = CGGradient(colorsSpace: CGColorSpaceCreateDeviceRGB(), colors: [endColorForGradient.cgColor, colorForGradient.cgColor] as CFArray, locations: [0.0, 1.0])
        
        let startPoint: CGPoint
        let endPoint: CGPoint
        
        if orientation == .horizontal {
            //horizontal
            startPoint = CGPoint(x: rect.minX, y: rect.midY)
            endPoint = CGPoint(x: rect.maxX, y: rect.midY)
        }
        else {
            //vertical
            startPoint = CGPoint(x: rect.midX, y: rect.maxY)
            endPoint = CGPoint(x: rect.midX, y: rect.minY)
        }
        
        
        
        context?.drawLinearGradient(gradient!, start: startPoint, end: endPoint, options: .drawsAfterEndLocation)
        context?.restoreGState()
        
        
        //Border around element
        context?.addPath(maskPath.cgPath)
        context?.setLineWidth(borderWidth)
        context?.setStrokeColor(borderColor.cgColor)
        context?.strokePath()
        
        context?.restoreGState()
        
        //draw the handle
        //        drawHandle(in: context!)
    }
    
    
    
    /// This method should be called when the user dragged the handle to a new position. It updates the current progress, triggers a ```setNeedsDisplay()``` and everything will be redrawn in the new location.
    ///
    /// - parameter location: Location to which the handle should be moved to.
    private func moveHandle(to location: CGPoint) {
        
        currentValue = progress(for: location)
        updateHandle()
    }
    
    
    /// This method updates the handle to the a point that depends on the current progress.
    fileprivate func updateHandle() {
        let handleCenterForDrawer = convert(pointOnLine(for: currentValue), to: handleDrawer)
        
        handleDrawer.update(handleCenter: handleCenterForDrawer, color: colorOfHandle)
    }
    
    /// Convertrs a point of interaction into progress between ```minValue``` and ```maxValue```
    ///
    /// - parameter point: Point of interaction
    ///
    /// - returns: The new progress in the interval from ```minValue``` to ```maxValue```.
    fileprivate func progress(for point: CGPoint) -> CGFloat {
        
        let progressCanidate: CGFloat
        if orientation == .horizontal {
            //horizontal
            let width = bounds.width
            let x = point.x
            progressCanidate = x/width
        }
        else {
            //vertical
            let height = bounds.height
            let y = point.y
            progressCanidate = y/height
        }
        
        
        let progress = max(minValue, min(maxValue, progressCanidate))
        return progress
    }
    
    
    /// Calculates a point on the slider for a given progress. Limits the value to ```minValue``` and ```maxValue```.
    ///
    /// - parameter value: Progress for which the point is requested.
    ///
    /// - returns: A point where the handle should be centered given the current progress.
    fileprivate func pointOnLine(for value: CGFloat) -> CGPoint {
        var value = value
        if value <= 0 {
            value = minValue
        }
        if value > 1 {
            value = maxValue
        }
        
        if orientation == .horizontal {
            //horizontal
            let x = bounds.width * value
            return CGPoint(x: x, y: bounds.midY)
        }
        else {
            //vertical
            let y = bounds.height * value
            return CGPoint(x: bounds.midX, y: y)
        }
        
        
        //        return CGPoint(x: x, y: bounds.midY)
        
    }
}

