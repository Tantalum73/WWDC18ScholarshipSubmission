//: [Previous](@previous)

import Foundation
import UIKit
import PlaygroundSupport
/*:
 ## HSB-Color-Space
 The HSB abstraction makes it easier for humans to interact with a color space. Colors are defined by three numbers: hue, saturation and brightness *(or intensity, they are used synonym)*.
 
 The hue value is defined as angle inside of a circle. The position of primary colors are defined on the circles circumference.
 
 The saturation value determines how much white the particular color contains. Brightness controls how dark the color appears. When set to zero, the color results in black.
 
 A given color can be transformed into (r, g, b) values or plotted into the CIE xyY diagram, as one can do in the interactive side of the playground. The brightness component is omitted because it is not relevant for the xyY representation of the color.
 
  *[Image taken from [here](https://2020spiritualvision.wordpress.com/2017/02/27/new-earth/hsl-cone-graphic/)]*

*/
let hsbImage = UIImage(named: "HSB")

PlaygroundPage.current.liveView = ContainerViewController()

PlaygroundPage.current.needsIndefiniteExecution = true
//: [Back](@previous)
