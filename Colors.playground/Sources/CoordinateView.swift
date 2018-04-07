//
//  CoordinateView.swift
//  Colors Playground, WWDC18 scholarship submission
//
//  Created by Andreas Neusüß on 25.03.18.
//  Copyright © 2018 Andreas Neusüß. All rights reserved.
//

import UIKit

/// This class is responsible for drawing the 2D CIE plot.
final class CoordinateView: UIView {
    
    /// The image view that holds the image of the CIE plot.
    private let graphImageView = UIImageView()
    
    /// The x position of the CIE plots coordinate origin, relative to the width of the view. Measured from the lower left corner.
    private let xoffsetOfOriginRelativeToWidth: CGFloat = 0.0493741
    /// The y position of the CIE plots coordinate origin, relative to the height of the view. Measured from the lower left corner.
    private let yoffsetOfOriginRelativeToHeight: CGFloat = 0.0461538
    
    /// The handle that highlights a given color.
    private let handle = UIView(frame: CGRect(x: 0, y: 0, width: 10, height: 10))
    
    /// A view that is used for drawing the handle at the correct position.
    private let coordinatePresenterView = UIView()
    
    override public init(frame: CGRect) {
        super.init(frame: frame)
        setUp()
    }
    required public init?(coder aDecoder: NSCoder) {
        fatalError("Not implemented")
    }
    
    
    /// This method updates the position of the handle according to the provided coordinates.
    ///
    /// - Parameters:
    ///   - x: x component of the color.
    ///   - y: y component of the color.
    ///   - Y: Y component of the color.
    public func updateColor(x: CGFloat, y: CGFloat, Y: CGFloat) {
        let adjustedCoordinates = convertToCoordinateSystem(x: x, y: y)
        
        handle.center = CGPoint(x: adjustedCoordinates.x, y: adjustedCoordinates.y)
    }
    
    /// This method sets up the views and its layout.
    private func setUp() {
        graphImageView.frame = bounds
        graphImageView.image = UIImage(named: "CIE from Mathematica", in: Bundle(for: type(of: self)), compatibleWith: nil)
        graphImageView.contentMode = .scaleAspectFill
        addSubview(graphImageView)
        
        
        handle.backgroundColor = .black
        handle.layer.cornerRadius = 5
        
        coordinatePresenterView.transform = CGAffineTransform.init(scaleX: 1, y: -1)
        
        coordinatePresenterView.backgroundColor = UIColor.clear
        coordinatePresenterView.addSubview(handle)
        
        addSubview(coordinatePresenterView)
    }
    
    public override func layoutSubviews() {
        super.layoutSubviews()
        
        graphImageView.frame = bounds
        let dxOfOrigin = bounds.width * xoffsetOfOriginRelativeToWidth
        
        coordinatePresenterView.frame = CGRect(x: dxOfOrigin, y: 0, width: bounds.width - dxOfOrigin, height: bounds.width - bounds.width * yoffsetOfOriginRelativeToHeight)
        
    }
    
    
    /// This method converts absolute coordinates of a color to the coordinate system used by this view.
    ///
    /// - Parameters:
    ///   - x: The x position of the original coordinates.
    ///   - y: The y position of the original coordinates
    /// - Returns: x and y positions of the transformed coordinates that can be used for centering the handle.
    private func convertToCoordinateSystem(x: CGFloat, y: CGFloat) -> (x: CGFloat, y: CGFloat) {
        
        
        let widthOfImage = coordinatePresenterView.bounds.width
        let heightOfImage = coordinatePresenterView.bounds.height
        
        /*
         [A, B] -> [a, b] where A=0, B=0.8  a=0, b=1
         b - a
         (x - A) * -------- + a
         B - A
         */
        
        // 0.8 and 0.9 are the max values of the CIE plot.
        let newX = x/0.8 * widthOfImage
        let newY = y/0.9 * heightOfImage
        
        return (newX, newY)
    }
    
}

