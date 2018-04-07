//
//  ColorPickerView.swift
//  Colors Playground, WWDC18 scholarship submission
//
//  Created by Andreas Neusüß on 23.03.18.
//  Copyright © 2018 Andreas Neusüß. All rights reserved.
//

import UIKit
import QuartzCore


/// This Enunm describes possible positions of the color slider relative to the color wheel.
///
/// - top: Slider is above the wheel.
/// - right: Slider is right of the wheel.
/// - bottom: Slider is below the wheel.
/// - left: Slider is left of the wheel.
public enum SliderPosition {
    case top, right, bottom, left
}


/// This protocol declares method that signal an implementing object that an interaction has started or ended. It can (and is designed to) be used to block a scrollview from scolling while an interaction with control elements inside a subview are going on. In this case, the scrollview should not be scrolled but the interactive elements should be handle teh touch.
public protocol InteractionNotifiable: class {
    /// This method is called when the interaction with a UI element started. Scrolling should be disabled now.
    func interactionStarted()
    /// This method is called when the interaction with a UI element ended. Scrolling should be enabled now.
    func interactionEnded()
}

/// Delegate that sould be implemented by objects interested in changes made by the ColorPickerView.
public protocol ColorPickerViewDelegate: class {
    
    /// This method is called when the user performed a change to the color and thereby the current color is changed, too.
    ///
    /// - parameter color: The new color that was selected by the user.
    func colorDidChange(color: UIColor, causedByUserInteraction: Bool, from picker: ColorPickerView)
}

@IBDesignable
/// This class is responsible for drawing the color wheel as well as the color slider by using ```ColorPicker``` and ```ColorSlider```. It wires its interactions together to create a smooth UX. Additionally, it informs its delegate about changes in the selected color.
public final class ColorPickerView: UIView {
    
    /// The ColorPicker, responsible for drawing the wheel and handling the user interaction on it.
    private let colorPicker: ColorPicker
    
    /// The ColorSlider, responsible for drawing a linear slider to change the saturation of the color and handling the user interaction on it.
    private let colorSlider: ColorSlider
    
    private let selectedColorView: SelectedColorView
    
    /// Stores the color that was picked in the color wheel.
    private var pickedColor: UIColor = .red
    
    /// The composed color is the composition of the color selected in the color wheel and the saturation value adjusted by the slider. It represents the current color and holds the latest value the deleate was informed about.
    public private (set) var composedColor: UIColor = .red
    
    /// The delegate will be informed about changes in the color selection.
    public weak var delegate: ColorPickerViewDelegate?
    
    /// The interaction delegate, useful for preventing scrolling a CollectionView.
    public weak var interactionDelegate: InteractionNotifiable? {
        didSet {
            //pass it along to the UIControls that implement touchesBegan, ...
            colorPicker.interactionDelegate = interactionDelegate
            colorSlider.interactionDelegate = interactionDelegate
        }
    }
    
    /// Position of the slider relative to the color wheel
    public var positionOfSlider: SliderPosition {
        didSet {
            setNeedsLayout()
        }
    }
    
    /// A flag that indicates if the SelectedColorView inside of the color wheel should be visible or not.
    public var selectedColorViewVisible = true {
        didSet {
            selectedColorView.removeFromSuperview()
            
            if selectedColorViewVisible {
                self.addSubview(selectedColorView)
            }
        }
    }
    
    /// The gradient end color for the SelectedColorView. The gradient ends on the outer side.
    public var selectedColorViewGradiendEndColor = UIColor.color(from: 0x3E3E3D) {
        didSet {
            selectedColorView.gradientEndColor = selectedColorViewGradiendEndColor
        }
    }
    
    /// A flag that decides whether the color picker uses the P3 color space or standard sRGB.
    public var usesP3ColorSpace: Bool = false {
        didSet {
            colorPicker.usesP3ColorSpace = usesP3ColorSpace
        }
    }
    
    override init(frame: CGRect) {
        colorPicker = ColorPicker(frame: .zero)
        colorSlider = ColorSlider(frame: .zero)
        selectedColorView = SelectedColorView(frame: .zero)
        positionOfSlider = .bottom
        super.init(frame: frame)
        setUp()
    }
    
    convenience public init(frame: CGRect, position: SliderPosition) {
        self.init(frame: frame)
        positionOfSlider = position
        
    }
    
    required public init?(coder aDecoder: NSCoder) {
        
        // Init the controls with a .zero frame because it will be adjusted in layoutSubviews()
        colorPicker = ColorPicker(frame: .zero)
        colorSlider = ColorSlider(frame: .zero)
        selectedColorView = SelectedColorView(frame: .zero)
        positionOfSlider = .bottom
        super.init(coder: aDecoder)
    }
    
    //    #if TARGET_INTERFACE_BUILDER
    override public func willMove(toSuperview newSuperview: UIView?) {
        super.willMove(toSuperview: newSuperview)
        setUp()
    }
    //    #endif
    public override func prepareForInterfaceBuilder() {
        setUp()
    }
    public override func awakeFromNib() {
        setUp()
    }
    
    public override func layoutSubviews() {
        let heightOfSlider: CGFloat = 40
        
        let frameForPicker: CGRect
        let frameForSlider: CGRect
        
        if positionOfSlider == .top || positionOfSlider == .bottom {
            colorSlider.orientation = .horizontal
        }
        else {
            colorSlider.orientation = .vertical
        }
        
        let minBorder = min(frame.width, frame.height)
        
        switch positionOfSlider {
        case .top:
            frameForPicker = CGRect(x: 0, y: heightOfSlider, width: minBorder, height: minBorder - heightOfSlider)
            frameForSlider = CGRect(x: frameForPicker.origin.x, y: 0, width: frameForPicker.width, height: heightOfSlider)
            
        case .right:
            frameForPicker = CGRect(x: 0, y: 0, width: minBorder, height: minBorder)
            frameForSlider = CGRect(x: minBorder, y: frameForPicker.origin.y, width: heightOfSlider, height: frameForPicker.height)
            
        case .bottom:
            frameForPicker = CGRect(x: 0, y: 0, width: minBorder, height: minBorder - heightOfSlider)
            frameForSlider = CGRect(x: frameForPicker.origin.x, y: minBorder - heightOfSlider, width: frameForPicker.width, height: heightOfSlider)
            
        case .left:
            frameForPicker = CGRect(x: heightOfSlider, y: 0, width: minBorder, height: minBorder)
            frameForSlider = CGRect(x: 0, y: frameForPicker.origin.y, width: heightOfSlider, height: frameForPicker.height)
        }
        colorPicker.frame = frameForPicker
        colorSlider.frame = frameForSlider
        
        selectedColorView.frame = colorPicker.frame.insetBy(dx: 20, dy: 20)
        
        
        super.layoutSubviews()
    }
    
    public override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
        if !isUserInteractionEnabled || isHidden || alpha <= 0.01 {
            return nil
        }
        
        //Test if the point was inside our boundaries
        if self.point(inside: point, with: event) {
            for subview in subviews.reversed() {
                let convertedPoint = convert(point, to: subview)
                let hitSubview = subview.hitTest(convertedPoint, with: event)
                if (hitSubview != nil) {
                    interactionDelegate?.interactionStarted()
                    
                    //Point was contained in subview!
                    return hitSubview
                }
            }
            //point was not contained in subview but in self
            return self
        }
        
        //point was not contained
        return nil
    }
    
    
    /// Sets up the view by adding the controls and targetting their .valueChanged event to self.
    private func setUp() {
        //                layer.borderColor = UIColor.red.cgColor
        //                layer.borderWidth = 1
        
        colorPicker.removeFromSuperview()
        colorSlider.removeFromSuperview()
        selectedColorView.removeFromSuperview()
        
        if selectedColorViewVisible {
            addSubview(selectedColorView)
        }
        addSubview(colorPicker)
        addSubview(colorSlider)
        
        colorPicker.addTarget(self, action: #selector(self.primaryColorChanged(sender:)), for: .valueChanged)
        colorSlider.addTarget(self, action: #selector(self.colorSliderChanged(sender:)), for: .valueChanged)
    }
    
    
    /// This method moved the contained ColorPicker and Slider to the components of the passed in color. It uses its HSB values to determine the positions.
    ///
    /// - Parameter color: The color to which the UI element should be moved
    public func move(to color: UIColor) {
        
        
        let components = color.hsbComponents()
        let angle = components.hue * 360
        let saturation = components.saturation
        
        colorPicker.move(to: Float(angle), animated: true)
        colorSlider.move(to: 1-saturation, animated: true)
        
    }
    
    
    
    /// This method is called when the user has picked a new color in the color wheel. It updates local variables and the gradient in the color slider as well as its handle.
    ///
    /// The delegate will be informed aboud a change in the current color.
    ///
    /// - parameter sender: The ColorPicker that fired the event.
    @objc fileprivate func primaryColorChanged(sender: ColorPicker) {
        pickedColor = sender.currentColor
        
        composedColor = computeColorForSliderHandle(progress: colorSlider.progress, gradientColor: pickedColor)
        colorSlider.colorForGradient = pickedColor
        
        colorSlider.colorOfHandle = composedColor
        selectedColorView.color = composedColor
        
        //        print("caused by user interaction: \(!colorPicker.animationInProgress)")
        delegate?.colorDidChange(color: composedColor, causedByUserInteraction: !colorPicker.animationInProgress, from: self)
    }
    
    
    /// This method is called when the user changed the saturation value using the linear slider. It updates local variables and the color if the color sliders handle.
    ///
    /// The delegate will be informed aboud a change in the current color.
    ///
    /// - parameter sender: The ColorSlider that fired the event.
    @objc fileprivate func colorSliderChanged(sender: ColorSlider) {
        let selectedProgress = sender.progress
        
        let colorForSlider = computeColorForSliderHandle(progress: selectedProgress, gradientColor: pickedColor)
        
        composedColor = colorForSlider
        colorSlider.colorOfHandle = composedColor
        
        selectedColorView.color = composedColor
        
        delegate?.colorDidChange(color: composedColor, causedByUserInteraction: !sender.animationInProgress, from: self)
    }
    
    
    /// This method creates a new color based on an old one by applying a given progress to the saturation value. The result shall be used to update the handle of the linear slider and to inform the delegate about a new color.
    ///
    /// - parameter progress:      Progress to which the slider is moved to. Between [0, 1].
    /// - parameter gradientColor: Color whose components should be adjusted according to the current progress.
    ///
    /// - returns: A new UIColor based on the gradientColor by applying the progress as the saturation component.
    fileprivate func computeColorForSliderHandle(progress: CGFloat, gradientColor: UIColor) -> UIColor {
        
        var componentsOfCurrentColor = gradientColor.hsbComponents()
        componentsOfCurrentColor.saturation = progress
        
        return UIColor(hue: componentsOfCurrentColor.hue, saturation: componentsOfCurrentColor.saturation, brightness: componentsOfCurrentColor.brightness, alpha: componentsOfCurrentColor.alpha)
    }
    
}

