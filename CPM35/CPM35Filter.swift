//
//  CPM35Filter.swift
//  CPM35
//
//  Created by Oleksandr Fedko on 18.08.2025.
//

import Foundation
import CoreImage
import CoreImage.CIFilterBuiltins

class CPM35Filter: CIFilter {
    private let image: CIImage
    
    init(image: CIImage) {
        self.image = image
        super.init()
    }
    
    required init?(coder: NSCoder) {
        fatalError("[ERROR] CPM35Filter: init(coder:) has not been implemented")
    }
    
    override var outputImage: CIImage? {
        var img = image
        img = vintageColorGrading(image: img)
        img = filmGrain(image: img)
        return img
        
    }
    
    private func vintageColorGrading(image: CIImage) -> CIImage {
        var output = image
        
        let temperature = CIFilter.temperatureAndTint()
        temperature.inputImage = output
        temperature.neutral = CIVector(x: 6000, y: -10)
        output = temperature.outputImage ?? image
        
        let colorControls = CIFilter.colorControls()
        colorControls.inputImage = output
        colorControls.saturation = 0.85
        colorControls.contrast = 1.01
        colorControls.brightness = 0.01
        output = colorControls.outputImage ?? image
        
        let hs = CIFilter.highlightShadowAdjust()
        hs.inputImage = output
        hs.shadowAmount = 0.05
        hs.highlightAmount = 1.02
        output = hs.outputImage ?? image
        
        let vibrance = CIFilter.vibrance()
        vibrance.inputImage = output
        vibrance.amount = -0.02
        output = vibrance.outputImage ?? image
        
        let gammaAdjust = CIFilter.gammaAdjust()
        gammaAdjust.inputImage = output
        gammaAdjust.power = 0.99
        output = gammaAdjust.outputImage ?? image
        
        return output
    }
    
    private func filmGrain(image: CIImage) -> CIImage {
        let grain = GrainFilter()
        grain.inputImage = image
        
        return grain.outputImage ?? image
    }
}
