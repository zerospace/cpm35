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
        var output: CIImage? = image
        
        let whiteBallanceFilter = CIFilter.temperatureAndTint()
        whiteBallanceFilter.inputImage = output
        whiteBallanceFilter.neutral = CIVector(x: 6520, y: -4)
        output = whiteBallanceFilter.outputImage
        
        let toneCurveFilter = CIFilter.toneCurve()
        toneCurveFilter.inputImage = output
        toneCurveFilter.point0 = CGPoint(x: 0.0, y: 36.0 / 255.0)
        toneCurveFilter.point1 = CGPoint(x: 60.0 / 255.0, y: 69.0 / 255.0)
        toneCurveFilter.point2 = CGPoint(x: 1.0, y: 236.0 / 255.0)
        output = toneCurveFilter.outputImage
        
        let exposureFilter = CIFilter.exposureAdjust()
        exposureFilter.inputImage = output
        exposureFilter.ev = 0.004
        output = exposureFilter.outputImage
        
        let toneFilter = CIFilter.highlightShadowAdjust()
        toneFilter.inputImage = output
        toneFilter.highlightAmount = 0.3
        toneFilter.shadowAmount = -0.1
        output = toneFilter.outputImage
        
        let vibranceFilter = CIFilter.vibrance()
        vibranceFilter.inputImage = output
        vibranceFilter.amount = -0.04
        output = vibranceFilter.outputImage
        
        let saturationFilter = CIFilter.colorControls()
        saturationFilter.inputImage = output
        saturationFilter.saturation = 0.85
        output = saturationFilter.outputImage
        
        let hslParams: [FilterParameter: Float] = [
            .hueAdjustmentRed: 6.0, .hueAdjustmentOrange: 2.0, .hueAdjustmentYellow: -16.0,
            .hueAdjustmentGreen: 14.0, .hueAdjustmentAqua: 0.0, .hueAdjustmentBlue: -10.0,
            .hueAdjustmentPurple: 0.0, .hueAdjustmentMagenta: 0.0,
            .saturationAdjustmentRed: 16.0, .saturationAdjustmentOrange: 14.0, .saturationAdjustmentYellow: -26.0,
            .saturationAdjustmentGreen: -30.0, .saturationAdjustmentAqua: -20.0, .saturationAdjustmentBlue: 12.0,
            .saturationAdjustmentPurple: 0.0, .saturationAdjustmentMagenta: 0.0,
            .luminanceAdjustmentRed: -10.0, .luminanceAdjustmentOrange: -10.0, .luminanceAdjustmentYellow: -8.0,
            .luminanceAdjustmentGreen: -14.0, .luminanceAdjustmentAqua: 0.0, .luminanceAdjustmentBlue: 20.0,
            .luminanceAdjustmentPurple: 0.0, .luminanceAdjustmentMagenta: 0.0,
            .graySwitch: 0.0
        ]
        let hslFilter = HSLFilter()
        hslFilter.inputImage = output
        hslFilter.updateHSLValues(from: hslParams)
        output = hslFilter.outputImage
        
        let splitToningFilter = SplitToningFilter()
        splitToningFilter.inputImage = output
        splitToningFilter.shadowTint = splitToningFilter.calculateTint(hue: 202.0, saturation: 16.0, isShadow: true)
        splitToningFilter.highlightTint = splitToningFilter.calculateTint(hue: 50.0, saturation: 12.0, isShadow: false)
        splitToningFilter.balance = 0.0
        output = splitToningFilter.outputImage
        
        let grainFilter = GrainFilter()
        grainFilter.inputImage = output
        output = grainFilter.outputImage
        
        return output
    }
}
