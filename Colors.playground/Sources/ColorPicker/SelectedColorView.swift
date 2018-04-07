//
//  SelectedColorView.swift
//  Colors Playground, WWDC18 scholarship submission
//
//  Created by Andreas Neusüß on 24.03.18.
//  Copyright © 2018 Andreas Neusüß. All rights reserved.
//

import UIKit

/// This class is responsible for drawing a gradient inside of the color picker. It presents the currently selected color to the user.
internal final class SelectedColorView: UIView {
    
    /// The color that the view should present. it marks the start of the gradient in the middle of the view.
    var color = UIColor.red {
        didSet {
            setNeedsDisplay()
            updateColor()
        }
    }
    
    /// The end color of the gradient meaning the outer edges.
    var gradientEndColor = UIColor.color(from: 0x3E3E3D) {
        didSet {
            setNeedsDisplay()
        }
    }
    
    /// The center layer to draw a circle.
    fileprivate let centerCircleLayer: CALayer = CALayer()
    /// The second, larger center layer to draw another circle.
    fileprivate let secondCircleLayer: CALayer = CALayer()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = UIColor.clear
        
        layer.addSublayer(centerCircleLayer)
        layer.addSublayer(secondCircleLayer)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        let radiusOfCenterLayer: CGFloat = 30.0
        let radiusOfSecondLayer: CGFloat = 40.0
        
        secondCircleLayer.backgroundColor = color.withAlphaComponent(0.4).cgColor
        //        secondCircleLayer.opacity = 0.4
        centerCircleLayer.backgroundColor = color.cgColor
        
        let center = CGPoint(x: bounds.midX, y: bounds.midY)
        secondCircleLayer.frame = CGRect(x: center.x - radiusOfSecondLayer, y: center.y - radiusOfSecondLayer, width: 2*radiusOfSecondLayer, height: 2*radiusOfSecondLayer)
        
        centerCircleLayer.frame = CGRect(x: center.x - radiusOfCenterLayer, y: center.y - radiusOfCenterLayer, width: 2*radiusOfCenterLayer, height: 2*radiusOfCenterLayer)
        
        centerCircleLayer.cornerRadius = radiusOfCenterLayer
        secondCircleLayer.cornerRadius = radiusOfSecondLayer
    }
    
    /// When this method is called, the color of the gradient and the circles are updated.
    fileprivate func updateColor() {
        CATransaction.begin()
        
        
        CATransaction.disableActions()
        CATransaction.setDisableActions(true)
        
        
        secondCircleLayer.backgroundColor = color.withAlphaComponent(0.4).cgColor
        centerCircleLayer.backgroundColor = color.cgColor
        
        CATransaction.commit()
    }
    
    // Only override draw() if you perform custom drawing.
    // An empty implementation adversely affects performance during animation.
    override func draw(_ rect: CGRect) {
        // Drawing code
        
        let context = UIGraphicsGetCurrentContext()
        
        let colorSpace = CGColorSpaceCreateDeviceRGB()
        let locations: [CGFloat] = [0, 1]
        
        let endColor = gradientEndColor.withAlphaComponent(0)
        let colors = [color.cgColor, endColor.cgColor] as CFArray
        
        let gradient = CGGradient(colorsSpace: colorSpace, colors: colors, locations: locations)
        
        let center = CGPoint(x: bounds.midX, y: bounds.midY)
        let radius = min(bounds.width / 2.0, bounds.height / 2.0)
        
        context?.drawRadialGradient(gradient!, startCenter: center, startRadius: 0, endCenter: center, endRadius: radius, options: .drawsAfterEndLocation)
        
    }
    
    
}

