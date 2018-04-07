//
//  GradientButton.swift
//  Colors Playground, WWDC18 scholarship submission
//
//  Created by Andreas Neusüß on 27.03.18.
//  Copyright © 2018 Andreas Neusüß. All rights reserved.
//
import Foundation
import UIKit

/// This class is responsible for drawing a UIButton with rounded corners and a background gradient.
@IBDesignable
final class GradientButton: UIButton {
    /// Tha gradient layer that draws the gradient.
    private var gradientLayer: CAGradientLayer!
    
    @IBInspectable
    /// The start color of the gradient.
    var gradientStartColor: UIColor = .red {
        didSet {
            updateGradient()
        }
    }
    
    @IBInspectable
    /// The end color of the gradient.
    var gradientEndColor: UIColor = .blue {
        didSet {
            updateGradient()
        }
    }
    
    @IBInspectable
    /// Color of the buttons border.
    var borderColor: UIColor = .green {
        didSet {
            updateGradient()
        }
    }
    @IBInspectable
    /// Width of the buttons border.
    var borderWidth: CGFloat = 0 {
        didSet {
            updateGradient()
        }
    }
    
    @IBInspectable
    /// Radius of the buttons corner.
    var cornerRadius: CGFloat = 0 {
        didSet {
            updateGradient()
        }
    }
    
    public override func didMoveToSuperview() {
        super.didMoveToSuperview()
        updateGradient()
    }
    public override func layoutSubviews() {
        super.layoutSubviews()
        gradientLayer.frame = bounds
    }
    
    /// This method updates the gradient with the current bounds and values.
    private func updateGradient() {
        if gradientLayer == nil {
            gradientLayer = CAGradientLayer()
            layer.insertSublayer(gradientLayer, at: 0)
        }
        gradientLayer.frame = bounds
        CATransaction.begin()
        CATransaction.setValue(kCFBooleanTrue, forKey: kCATransactionDisableActions)
        gradientLayer.colors = [gradientStartColor.cgColor, gradientEndColor.cgColor]
        gradientLayer.borderColor = borderColor.cgColor
        gradientLayer.borderWidth = borderWidth
        gradientLayer.cornerRadius = cornerRadius
        CATransaction.commit()
        
    }
}
