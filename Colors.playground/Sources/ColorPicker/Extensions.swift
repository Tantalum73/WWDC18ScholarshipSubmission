import Foundation
import UIKit

public extension UIColor {
    
    
    /// Deconstructs a UIColor object into its components of RGBA values in range from 0 to 255.
    ///
    /// - Returns: A tupel containing the RGBA components of the color using the range from 0 to 255.
    public func components() -> (red: CGFloat, green: CGFloat, blue: CGFloat, alpha: CGFloat) {
        
        var red: CGFloat = 0
        var green: CGFloat = 0
        var blue: CGFloat = 0
        var alpha: CGFloat = 0
        getRed(&red, green: &green, blue: &blue, alpha: &alpha)
        return (red*255, green*255, blue*255, alpha)
    }
    
    /**
     Calculates a UIColor from given hex value.
     
     - parameter hex: the hex value to be converted to uicolor
     
     - parameter alpha: the alpha value of the color
     
     - returns: the UIColor corresponding to the given hex and alpha value
     
     */
    public class func color(from hex: Int, alpha: Double = 1.0) -> UIColor {
        let red = Double((hex & 0xFF0000) >> 16) / 255.0
        let green = Double((hex & 0xFF00) >> 8) / 255.0
        let blue = Double((hex & 0xFF)) / 255.0
        let color: UIColor = UIColor( red: CGFloat(red), green: CGFloat(green), blue: CGFloat(blue), alpha:CGFloat(alpha) )
        return color
    }

    
    convenience init(displayP3Hue hue: CGFloat, saturation: CGFloat, brightness: CGFloat, alpha: CGFloat = 1) {
        /// HSB to RGB conversion doesn’t depend on color space, so we can use default UIColor space.
        let converter = UIColor(hue: hue, saturation: saturation, brightness: brightness, alpha: 1)
        
        var red: CGFloat = 0, green: CGFloat = 0, blue: CGFloat = 0
        converter.getRed(&red, green: &green, blue: &blue, alpha: nil)
        
        self.init(displayP3Red: red, green: green, blue: blue, alpha: alpha)
    }
    
    /**
     Cretaes a UIColor from RGB values.
     
     - parameter red: the r value
     
     - parameter green: the g value
     
     - parameter blue: the b value
     
     - returns: UIColor from rgb value.
     
     */
    public class func colorFromRGB (_ red: Int, green: Int, blue: Int) -> UIColor {
        assert(red >= 0 && red <= 255, "Invalid red component")
        assert(green >= 0 && green <= 255, "Invalid green component")
        assert(blue >= 0 && blue <= 255, "Invalid blue component")
        
        return self.init(red: CGFloat(red) / 255.0, green: CGFloat(green) / 255.0, blue: CGFloat(blue) / 255.0, alpha: 1.0)
    }
    
    
    /// This method gets the components of the color in HSL scheme.
    ///
    /// - returns: Tuple of ```(hue: saturation: blightness:, alpha:)```
    public func hsbComponents() -> (hue: CGFloat, saturation: CGFloat, brightness: CGFloat, alpha: CGFloat) {
        var (hue, saturation, brightness, alpha): (CGFloat, CGFloat, CGFloat, CGFloat) = (0.0, 0.0, 0.0, 0.0)
        getHue(&hue, saturation: &saturation, brightness: &brightness, alpha: &alpha)
        return (hue, saturation, brightness, alpha)
    }
    
    
    /// Computes the hex string of a UIColor in the following format: 0xXXXXXX
    ///
    /// - Returns: Color in hex string as 0xXXXXXX
    public func hexString() -> String {
        var red:CGFloat = 0
        var green:CGFloat = 0
        var blue:CGFloat = 0
        var alpha:CGFloat = 0
        
        getRed(&red, green: &green, blue: &blue, alpha: &alpha)
        
        let rgb: Int = (Int)(red*255)<<16 | (Int)(green*255)<<8 | (Int)(blue*255)<<0
        
        return String(format:"0x%06x", rgb)
    }
    
    
    public func fromsRGBToxyY() -> (x: CGFloat, y: CGFloat, z: CGFloat) {
        let m: [[CGFloat]] = [[0.4124564, 0.3575761, 0.1804375], [0.2126729, 0.7151522, 0.0721750], [0.0193339, 0.1191920, 0.9503041]]//[[0.136*k, 0.067*k, 0*k], [0.008*k, 0.284*k, 0.017*k], [0.002*k, 0.002*k, 0.067*k]]
        let components = self.components()
        let c = [[components.red/255], [components.green/255], [components.blue/255]]
        let resultMatrix = [
            [   m[0][0] * c[0][0] +  m[0][1] * c[1][0] + m[0][2] * c[2][0]  ],
            [   m[1][0] * c[0][0] +  m[1][1] * c[1][0] + m[1][2] * c[2][0]  ],
            [   m[2][0] * c[0][0] +  m[2][1] * c[1][0] + m[2][2] * c[2][0]  ]
        ]
        
        //[X,Y,Z]^T = M * [R,G,B]^T
        
        let X = resultMatrix[0][0]
        let Y = resultMatrix[1][0]
        let Z = resultMatrix[2][0]
        
        let denum = X+Y+Z
        
        let x = X/denum
        let y = Y/denum
        let z = 1 - x - y
        return (x: x, y: y, z: z)
    }
    
    public func fromP3ToxyY() -> (x: CGFloat, y: CGFloat, z: CGFloat) {
        let m: [[CGFloat]] = [[0.48657095, 0.26566769, 0.19821729], [0.22897457, 0.69173852, 0.07928691], [0, 0.04511338, 1.04394437]]//[[0.136*k, 0.067*k, 0*k], [0.008*k, 0.284*k, 0.017*k], [0.002*k, 0.002*k, 0.067*k]]
        let components = self.components()
        let c = [[components.red/255], [components.green/255], [components.blue/255]]
        let resultMatrix = [
            [   m[0][0] * c[0][0] +  m[0][1] * c[1][0] + m[0][2] * c[2][0]  ],
            [   m[1][0] * c[0][0] +  m[1][1] * c[1][0] + m[1][2] * c[2][0]  ],
            [   m[2][0] * c[0][0] +  m[2][1] * c[1][0] + m[2][2] * c[2][0]  ]
        ]
        
        //[X,Y,Z]^T = M * [R,G,B]^T
        
        let X = resultMatrix[0][0]
        let Y = resultMatrix[1][0]
        let Z = resultMatrix[2][0]
        
        let denum = X+Y+Z
        
        let x = X/denum
        let y = Y/denum
        let z = 1 - x - y
        return (x: x, y: y, z: z)
    }
    /// This method compares two colors and decides if they are considered equal based on a given tolerance.
    ///
    /// - Parameters:
    ///   - color: The color to which self is compared to.
    ///   - tolerance: The tolerance by which the colors can differ and are still considered equal. The colors RGBA values are compared and checked against the tolerance.
    /// - Returns: True if the colors can be considered equal.
    public func isEqual(to color: UIColor, withTolerance tolerance: CGFloat = 0.0) -> Bool{
        
        let componentsSelf = hsbComponents()
        let componentsOther = color.hsbComponents()
        
        //ignore brightness
        
        return fabs(componentsSelf.hue - componentsOther.hue) <= tolerance && fabs(componentsSelf.saturation - componentsOther.saturation) <= tolerance
        
        //        var r1 : CGFloat = 0
        //        var g1 : CGFloat = 0
        //        var b1 : CGFloat = 0
        //        var a1 : CGFloat = 0
        //        var r2 : CGFloat = 0
        //        var g2 : CGFloat = 0
        //        var b2 : CGFloat = 0
        //        var a2 : CGFloat = 0
        //
        //        self.getRed(&r1, green: &g1, blue: &b1, alpha: &a1)
        //        color.getRed(&r2, green: &g2, blue: &b2, alpha: &a2)
        //
        //        return
        //            fabs(r1 - r2) <= tolerance &&
        //                fabs(g1 - g2) <= tolerance &&
        //                fabs(b1 - b2) <= tolerance &&
        //                fabs(a1 - a2) <= tolerance
}
}

