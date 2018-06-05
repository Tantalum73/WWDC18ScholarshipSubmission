import UIKit
import PlaygroundSupport
/*:
 Colors
 =========================
 *How is it possible to define colors with three numbers, known as (r, g, b)? What is a color space, what does it mean and why should I, as a developer, know about it?*

 
## Biology
 The human eyes retina is made of cone and rod cells, which act as photoreceptors. Rod cells are mainly responsible for detecting edges and brightness, cone cells can be divided into three groups.
 
 The cells of each of these groups are stimulated by light of different wave lengths. The wavelength of the maximum stimulation varies between the three groups.
 
 The sensitivity of the cone cells were recorded in experiments by CIE (an association), which started as early as 1931. An important result of the experiment was the numerical representation of wavelength sensitivity of the human eye.
 *Tap on the image to see its content*
 
 *[Image taken from [here](https://cdn-images-1.medium.com/max/1600/0*ZBmRv_J2IapWPfPZ.)]*
*/
let sensitivityOfRetina = UIImage(named: "Sensitivity Diagram.png")

/*:
 Now it becomes possible to define a 3D space that contains every visible color.
 
 
## Mathematics
 The mentioned space is defined by the area below the graphs, mathematically expressed as integration.
 */
let fomulaToGenerateCIEPlot = UIImage(named: "XYZ integrated")

/*:Plotted in a 3D coordinate system, the following image is produced:
 */
let ThreeDimensionalColorSpace = UIImage(named: "CIE 3D from Mathematica")

/*:*Can I have it better illustrated than a 3D space, please?*
 To transform it into a 2D area, we scale X, Y and Z to x, y and Y:
*/
let normalization = UIImage(named: "xyz normalized")


/*:
 This ’trick’ enables us to draw a point 3D by using only two coordinates: x and y. The third component, Y, can be computed from the other two.
 
 Now, it is possible to plot x and y into a 2D coordinate system. As the values are derived from the human eyes capability to distinguish colors, it displays every color that we can perceive *(at full luminosity, as the Y component is omitted)*.

 */
let CIEWithEveryPerceivableColors = UIImage(named: "CIE from Mathematica")
/*:
 ## Color Spaces and Presentations
 One probably notices the gray line inside of the diagram. It defines the sRGB color space. The triangle contains every color devices like iPhone 6s or older can display *(with regards to full luminosity, as well)*.
 
 Using the in interactive HSB-color picker on the upper right, you can play around with colors and see their representation in the absolute xy space. *Noticed, that one can not create a color that is outside of the gray triangle?*

 For more detailed information about the HSB-representation of a color, please visit [next page](@next).
 
 Newer devices can display display colors of the DCI-P3 color space, which includes more colors than the sRGB. Flipping the switch tells the software to interpret the tuned color in relation to the P3 space. *Observed, that it is now possible to move the color outside of the sRGB triangle?*
 
 Having more displayable colors makes it possible to picture reality more accurate because in nature, every perceivable color occurs.
 */

/*:
 One can experience the widened color space by pressing the „open camera“ button. A view will open up, which displays every color that is contained in the sRGB space as gray. Colors, that are exclusive to the P3 color space are highlighted. *Go ahead and try to find objects, whose colors need the P3 color space to be displayed on a technical device.*
*/
PlaygroundPage.current.liveView = ContainerViewController()
PlaygroundPage.current.needsIndefiniteExecution = true

