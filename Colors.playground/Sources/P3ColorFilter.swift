//
//  P3ColorFilter.swift
//  Colors Playground, WWDC18 scholarship submission
//
//  Created by Andreas Neusüß on 24.03.18.
//  Copyright © 2018 Andreas Neusüß. All rights reserved.
//

import UIKit
import QuartzCore

final class P3ColorFilter: CIFilter {
    
    /// The name of the filter
    static let name = "P3ColorFilter"
    @objc var inputImage: CIImage?
    
    override init() {
        super.init()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    /// This function registeres the filter in the CIFilter name table. To use the filter by passing its name to the CIFilter initializer, this function must be called prior.
    public static func register() {
        CIFilter.registerName(P3ColorFilter.name, constructor: FilterConstructor(), classAttributes: [kCIAttributeFilterName: P3ColorFilter.name])
    }
    
    override var outputImage: CIImage? {
        guard let kernel = kernel, let input = inputImage else {
            // If the kernel is not present an no input image was set, abort.
            return nil
        }
        
        let roiCallback: CIKernelROICallback = {(number, rect) in
            return rect
        }
        
        return kernel.apply(extent: input.extent, roiCallback: roiCallback, arguments: [CISampler(image: input)])
    }
    
    /// The kernel used for filtering.
    private let kernel = CIKernel(source:
        """
kernel vec4 p3_color_kernel(sampler source_image)
            {
            vec2 d = destCoord();
            vec4 pixelValue = sample(source_image, samplerCoord(source_image));
            unpremultiply(pixelValue);

    if(pixelValue.r > 1.0 || pixelValue.r < 0.0 || pixelValue.g > 1.0 || pixelValue.g < 0.0 || pixelValue.b > 1.0 || pixelValue.b < 0.0) {
        return pixelValue;
    }
    else {
    vec3 gray = vec3(0.3, 0.69, 0.11);
float lum = dot(gray, pixelValue.rgb);
        return vec4(vec3(lum), 1.0);
        
        return pixelValue;
    }
        }
"""
    )
    
}
/// Implementation of a general interface for objects that produce CIFilter instances.
fileprivate class FilterConstructor: NSObject, CIFilterConstructor {
    func filter(withName name: String) -> CIFilter? {
        if name == P3ColorFilter.name {
            return P3ColorFilter()
        }
        
        return nil
    }
}
