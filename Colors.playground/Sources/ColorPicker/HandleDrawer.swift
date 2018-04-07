//
//  ColorWheelDrawer.swift
//  Colors Playground, WWDC18 scholarship submission
//
//  Created by Andreas Neusüß on 24.03.18.
//  Copyright © 2018 Andreas Neusüß. All rights reserved.
//

import UIKit


/// HandleDrawer is used to draw a handle at a given point.
public final class HandleDrawer: UIView {
    /// Current color that is selected.
    fileprivate var currentColor: UIColor = .red {
        didSet {
            //            setNeedsDisplay()
        }
    }
    
    /// Center of the handle.
    fileprivate var handleCenter: CGPoint = .zero
    
    /// Width of the handle that the user can drag.
    var widthOfHandle: CGFloat = 20
    
    
    convenience init() {
        self.init(frame: .zero)
    }
    
    override public init(frame: CGRect) {
        
        super.init(frame: frame)
        backgroundColor = .clear
        isUserInteractionEnabled = false
        clipsToBounds = false
    }
    
    required public init?(coder aDecoder: NSCoder) {
        fatalError("This class shold not be embedded inside a storyboard.")
    }
    
    
    /// This method updates the handle by applying a given color and moving it to a given center.
    ///
    /// - Parameters:
    ///   - center: The center around which the handle should be drawn.
    ///   - color: The color of the handles center.
    public func update(handleCenter center: CGPoint, color: UIColor) {
        currentColor = color
        handleCenter = center
        setNeedsDisplay()
    }
    
    // Only override draw() if you perform custom drawing.
    // An empty implementation adversely affects performance during animation.
    override public func draw(_ rect: CGRect) {
        super.draw(rect)
        //let center = CGPoint(x: bounds.midX, y: bounds.midY)
        
        let context = UIGraphicsGetCurrentContext()
        
        //Draw the handle
        drawHandle(in: context!)
    }
    
    /// This function is responsible for drawing the handle that the user can drag.
    ///
    /// - parameter context: Context in which the handle should be drawn into.
    fileprivate func drawHandle(in context: CGContext) {
        context.saveGState()
        let borderWidthOfHandle: CGFloat = 3
        
        let rectOfHandle = CGRect(x: handleCenter.x - (widthOfHandle/2.0), y: handleCenter.y - widthOfHandle/2.0, width: widthOfHandle, height: widthOfHandle)
        
        
        //a decent shadow
        context.setShadow(offset: CGSize(width: 0, height: 0), blur: 3, color: UIColor.black.cgColor)
        
        UIColor.white.set()
        
        context.fillEllipse(in: rectOfHandle.insetBy(dx: -borderWidthOfHandle, dy: -borderWidthOfHandle))
        
        currentColor.set()
        
        context.setShadow(offset: .zero, blur: 0)
        context.fillEllipse(in: rectOfHandle)
        
        context.restoreGState()
        
    }
    
    
}

