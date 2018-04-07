# WWDC18ScholarshipSubmission
The Swift Playground I submitted for 2018 WWDC Scholarship: Explaining Colors

#About this Playground
[![Screenshot.png](Screenshot)]
This playground is designed to teach developers the basics of digital color representation. It starts with human biology and uses math to bridge its characteristics to the computational, digital space.
The user can interact with a custom color picker. By tuning a color, one can experience the relationships between theory and practice in a straightforward way.
In addition to that, the user can open a camera view that makes it tangible what it means to have a wider color space displayed.

My code makes heavy use of UIKit and CoreAnimation. I created a completely custom HSB-Color picker by subclassing UIControl. By using its functionality, the user is able to interact with the color space in a direct way. The tuned color is then presented in a 2D diagram which contains every perceptible color.
The theoretical aspect of this work is contained in the non-interactive part of the playground, accompanied by graphic illustrations.

After the user has familiarized themselves with the digital representation of a color and what a color space really means, one opens a live feed from the devices camera.
There, AVFoundation is used to capture the video data. Then, a CIFilter is used to manipulate the pictures. A CIKernel has been written by using the CIKernel-language, that highlights every color which is exclusively contained by the P3, but not by the sRGB color space.
When the user wanders around with the playground open, one can discover which colors of the surrounding need a P3-display to be captured accurately.

In summary, the project at hand gives the user the theoretical background to understand what a color space is, where its limitations are and why there is a need for a wider color space.
