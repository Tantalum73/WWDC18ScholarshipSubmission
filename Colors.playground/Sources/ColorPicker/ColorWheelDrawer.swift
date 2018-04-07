//
//  ColorWheelDrawer.swift
//  Colors Playground, WWDC18 scholarship submission
//
//  Created by Andreas Neusüß on 24.03.18.
//  Copyright © 2018 Andreas Neusüß. All rights reserved.
//

import UIKit

@IBDesignable
/// This class is responsible for drawing a color wheel inside of the entire view. It can be used to save the image to disk for later preparation and usage in a color picker. The function ```saveImageToDisk()``` will be called if the view is represented in the view hirachy and if an image is already saved, it will be overwritten.
public final class ColorWheelDrawer: UIView {
    
    override public func didMoveToSuperview() {
        super.didMoveToSuperview()
        backgroundColor = .clear
        #if TARGET_INTERFACE_BUILDER
            //Do not try so safe the image if the view is drawn in interface builder.
        #else
            saveImageToDisk()
        #endif
        
    }
    
    // Only override draw() if you perform custom drawing.
    // An empty implementation adversely affects performance during animation.
    override public func draw(_ rect: CGRect) {
        // Drawing code
        super.draw(rect)
        
        let context = UIGraphicsGetCurrentContext()
        
        drawColorWheel(in: context, outerRadius: rect.width/2-10, innerRadius: 0, resolution: 1)
    }
    
    
    /// This method draws a color wheel with a given radius. The resolution should be between 0 and 1.
    ///
    /// - Parameters:
    ///   - context: The CGContext to draw the color wheel in.
    ///   - outerRadius: The outer radius of the wheel.
    ///   - innerRadius: The inner radius of the wheel, producing a hole.
    ///   - resolution: The resolution of which the gradient shall be drawn. Should be between 0 and 1.
    func drawColorWheel(in context: CGContext?, outerRadius: CGFloat, innerRadius: CGFloat, resolution: Float){
        context?.saveGState()
        context?.translateBy(x: self.bounds.midX, y: self.bounds.midY) //Move context to center
        
        let subdivisions:CGFloat = CGFloat(resolution * 512) //Max subdivisions of 512
        
        let innerHeight = (CGFloat.pi*innerRadius)/subdivisions //height of the inner wall for each segment
        let outterHeight = (CGFloat.pi*outerRadius)/subdivisions
        
        let segment = UIBezierPath()
        segment.move(to: CGPoint(x: innerRadius, y: -innerHeight/2))
        segment.addLine(to: CGPoint(x: innerRadius, y: innerHeight/2))
        segment.addLine(to: CGPoint(x: outerRadius, y: outterHeight/2))
        segment.addLine(to: CGPoint(x: outerRadius, y: -outterHeight/2))
        segment.close()
        
        
        //Draw each segment and rotate around the center
        for i in 0 ..< Int(ceil(subdivisions)) {
            UIColor(hue: CGFloat(i)/subdivisions, saturation: 1, brightness: 1, alpha: 1).set()
            segment.fill()
            let lineTailSpace = CGFloat.pi * 2 * outerRadius/subdivisions  //The amount of space between the tails of each segment
            segment.lineWidth = lineTailSpace //allows for seemless scaling
            segment.stroke()
            
            //Rotate to correct location
            let rotate = CGAffineTransform(rotationAngle: -CGFloat.pi * 2/subdivisions) //rotates each segment
            segment.apply(rotate)
        }
        
        context?.translateBy(x: -self.bounds.midX, y: -self.bounds.midY) //Move context back to original position
        context?.restoreGState()
    }
    
    /// The path to the persistent application data directory where data can be stored.
    static let privateApplicationDataDirectory : URL = {
        var fileManager = FileManager.default
        let possi = fileManager.urls(for: FileManager.SearchPathDirectory.documentDirectory, in: FileManager.SearchPathDomainMask.userDomainMask) //.urlsForDirectory(FileManager.SearchPathDirectory.documentDirectory, inDomains: FileManager.SearchPathDomainMask.userDomainMask)
        let appSupportDir = possi.last!
        let applicationBundleId = Bundle.main.bundleIdentifier
        
        let tmp = appSupportDir.appendingPathComponent(applicationBundleId!)
        
        return tmp
    }()
    
    /// This function creates a PNG from the color wheel and saves it do disk.
    func saveImageToDisk() {
        
        let dataDirectory = ColorWheelDrawer.privateApplicationDataDirectory
        let fileManager = FileManager.default
        
        
        let filePath = dataDirectory.appendingPathComponent("Color Wheel.png")
        try? fileManager.removeItem(at: filePath)
        
        UIGraphicsBeginImageContext(bounds.size)
        let context = UIGraphicsGetCurrentContext()
        layer.render(in: context!)
        let image = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        let data = UIImagePNGRepresentation(image!)
        try? data?.write(to: filePath)
        print("Did write to \(filePath)")
    }
}

