//
//  SliderView.swift
//  Colors Playground, WWDC18 scholarship submission
//
//  Created by Andreas Neusüß on 24.03.18.
//  Copyright © 2018 Andreas Neusüß. All rights reserved.
//

import UIKit

/// This protocol is used by the SliderView to inform subscribers about user interactions with the contained slider.
public protocol SliderViewDelegate: class {
    
    /// This method is called when the slider was changed either by the user ot by an programmatical update. The flag causedByUserInteraction indicates if the user caused the update.
    ///
    /// - Parameters:
    ///   - newValue: The new progress of the slider, between 0 and 1.
    ///   - causedByUserInteraction: A flag that indiciates if the slider was moved by the user.
    ///   - slider: The SliderView that called the method, maybe usefull to distinguish multiple sliders.
    func sliderValueChaged(newValue: CGFloat, causedByUserInteraction: Bool, from slider: SliderView)
}

@IBDesignable
/// This class is responsible for capturing a ColorSlider in a UIView. It manages its layout, images around it as well as interactions with the user. A ViewController can be registered as delegate to get informed about changes and to perform network operations accordings.
public final class SliderView: UIView {
    
    /// The color of the slider, marks the start color of its gradient.
    @IBInspectable public var color: UIColor = UIColor.red {
        didSet {
            setNeedsDisplay()
        }
    }
    
    /// The end color of the gradient that fills the slider.
    @IBInspectable public var gradientEndColor: UIColor = UIColor.white {
        didSet {
            setNeedsDisplay()
        }
    }
    
    /// The color of the handle.
    @IBInspectable public var handleColor: UIColor = UIColor.red {
        didSet {
            setNeedsDisplay()
        }
    }
    
    /// Tint color of the images left and right of the slider.
    @IBInspectable public var sunColor: UIColor = UIColor.red {
        didSet {
            setNeedsLayout()
            layoutIfNeeded()
        }
    }
    
    /// Color of the sliders border.
    @IBInspectable public var borderColor: UIColor = UIColor.color(from: 0xA7A219) {
        didSet {
            slider.borderColor = borderColor
        }
    }
    
    /// Interaction delegates
    public weak var interactionDelegate: InteractionNotifiable? {
        didSet {
            //pass it along to the UIControls that implement touchesBegan, ...
            slider.interactionDelegate = interactionDelegate
        }
    }
    
    /// The actual slider.
    fileprivate let slider: ColorSlider
    /// Image view that sits left of the slider.
    fileprivate var leftImageView = UIImageView()
    /// Image view that sits right of the slider.
    fileprivate var rightImageView = UIImageView()
    
    /// A Tao Gesturerecognizer that registeres taps on image view on the sliders left. Used to update the slider without touching it but tapping on the image besides it.
    fileprivate var leftGestureRecognizer: UITapGestureRecognizer!
    /// A Tao Gesturerecognizer that registeres taps on image view on the sliders right. Used to update the slider without touching it but tapping on the image besides it.
    fileprivate var rightGestureRecognizer: UITapGestureRecognizer!
    
    /// The delegate that is informed when the slider changes its value. That may be caused by the user or by an programmatical update to its value. A flag in the delegate method clarifies it.
    public weak var delegate: SliderViewDelegate?
    
    override init(frame: CGRect) {
        slider = ColorSlider(frame: frame)
        
        super.init(frame: frame)
        setUp()
    }
    
    required public init?(coder aDecoder: NSCoder) {
        slider = ColorSlider(frame: .zero)
        
        super.init(coder: aDecoder)
    }
    
    #if TARGET_INTERFACE_BUILDER
    override public func willMove(toSuperview newSuperview: UIView?) {
    super.willMove(toSuperview: newSuperview)
    setUp()
    
    }
    #endif
    public override func prepareForInterfaceBuilder() {
        setUp()
    }
    public override func awakeFromNib() {
        setUp()
    }
    
    /// In this function, frames and colors are set up.
    private func setUp() {
        slider.removeFromSuperview()
        leftImageView.removeFromSuperview()
        rightImageView.removeFromSuperview()
        
        addSubview(slider)
        addSubview(leftImageView)
        addSubview(rightImageView)
        
        leftImageView.contentMode = .center
        rightImageView.contentMode = .center
        
        
        //        leftImageView.image = UIImage(named: "Small Sun", in: Bundle(for: type(of: self)), compatibleWith: nil)
        //        rightImageView.image = UIImage(named: "Large Sun", in: Bundle(for: type(of: self)), compatibleWith: nil)
        
        slider.addTarget(self, action: #selector(self.sliderValueChanged(sender:)), for: .valueChanged)
        
        rightGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(leftOrRightGestureRecognizerFired(gestureRecognizer:)))
        leftGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(leftOrRightGestureRecognizerFired(gestureRecognizer:)))
        
        leftImageView.addGestureRecognizer(leftGestureRecognizer)
        rightImageView.addGestureRecognizer(rightGestureRecognizer)
        
        leftImageView.isUserInteractionEnabled = true
        rightImageView.isUserInteractionEnabled = true
    }
    
    
    override public func layoutSubviews() {
        super.layoutSubviews()
        
        let widthOfImageView: CGFloat = bounds.height
        
        let frameForSlider = bounds.insetBy(dx: widthOfImageView, dy: 0)
        //        frameForSlider.origin.x += widthOfImageView
        
        slider.frame = frameForSlider
        slider.colorForGradient = color
        slider.endColorForGradient = gradientEndColor
        slider.colorOfHandle = handleColor
        
        leftImageView.frame = CGRect(x: 0, y: 0, width: widthOfImageView, height: widthOfImageView)
        rightImageView.frame = CGRect(x: bounds.width - widthOfImageView, y: 0, width: widthOfImageView, height: widthOfImageView)
        
        leftImageView.tintColor = sunColor
        rightImageView.tintColor = sunColor
    }
    
    
    /// This method is called when the sliders value changed an a 'ValueChanged' event is triggered. I forewards it to the delegate by calling its ```sliderValueChaged(newValue:causedByUserInteraction:from:)``` method.
    ///
    /// - Parameter sender: The slider that caused the ValueChanged event.
    @objc fileprivate func sliderValueChanged(sender: ColorSlider) {
        print("Changed To: \(sender.progress)")
        delegate?.sliderValueChaged(newValue: sender.progress, causedByUserInteraction:!slider.animationInProgress, from: self)
    }
    
    
    /// This function moves the slider to a given progress. The progress should be between 0 and 1, otherwise it will be set to these boundaries.
    ///
    /// - Parameters:
    ///   - progress: The progress to which the slider should be moved to. Between 0 and 1.
    ///   - animated: If true, the movement is animated, otherwise the slider will jump immediately.
    public func move(to progress: Double, animated: Bool) {
        
        var progress = CGFloat(progress)
        //lower bound
        progress = fmax(0, progress)
        //upper bounds
        progress = fmin (1, progress)
        
        slider.move(to: progress, animated: animated)
    }
    
    
    /// This method is called when a gesture recognizer fired. A check, whether it is the left or right one is done inside.
    ///
    /// - Parameter gestureRecognizer: The gestureRecognizer that fired.
    @objc fileprivate func leftOrRightGestureRecognizerFired(gestureRecognizer: UITapGestureRecognizer) {
        guard gestureRecognizer.state == .ended else {
            return
        }
        
        var newProgress = slider.progress
        if gestureRecognizer === leftGestureRecognizer {
            //decrease the slider
            newProgress -= 0.1
        }
        else if gestureRecognizer === rightGestureRecognizer {
            //increase the slider
            newProgress += 0.1
        }
        guard newProgress >= 0 && newProgress <= 1 else {
            //do not update UI or send a call to delegate if we produced unreasonable values.
            return
        }
        
        slider.move(to: newProgress, animated: true)
        
        delegate?.sliderValueChaged(newValue: newProgress, causedByUserInteraction: true, from: self)
    }
    
}

