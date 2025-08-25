//
//  HSLShader.metal
//  HSLFilter
//
//  Created by Oleksandr Fedko on 23.01.2024.
//

import Foundation
import CoreImage
import simd

enum FilterParameter: Int {
    case hueAdjustmentRed = 17
    case hueAdjustmentOrange
    case hueAdjustmentYellow
    case hueAdjustmentGreen
    case hueAdjustmentAqua
    case hueAdjustmentBlue
    case hueAdjustmentPurple
    case hueAdjustmentMagenta
    
    case saturationAdjustmentRed = 25
    case saturationAdjustmentOrange
    case saturationAdjustmentYellow
    case saturationAdjustmentGreen
    case saturationAdjustmentAqua
    case saturationAdjustmentBlue
    case saturationAdjustmentPurple
    case saturationAdjustmentMagenta
    
    case luminanceAdjustmentRed = 33
    case luminanceAdjustmentOrange
    case luminanceAdjustmentYellow
    case luminanceAdjustmentGreen
    case luminanceAdjustmentAqua
    case luminanceAdjustmentBlue
    case luminanceAdjustmentPurple
    case luminanceAdjustmentMagenta
    
    case grayMixerRed = 41
    case grayMixerOrange
    case grayMixerYellow
    case grayMixerGreen
    case grayMixerAqua
    case grayMixerBlue
    case grayMixerPurple
    case grayMixerMagenta
    
    case graySwitch = 240 // A custom value for the grayscale switch
}

final class HSLFilter: CIFilter {
    var inputImage: CIImage?
    var inputHSLValues: [simd_float3] = Array(repeating: .zero, count: 9)
    var inputGrayMix: Float = 0.0
    
    private let kernel: CIKernel
    
    override init() {
        guard let url = Bundle.main.url(forResource: "default", withExtension: "metallib") else {
            fatalError("[ERROR] Can't find default.metallib")
        }
        
        do {
            let data = try Data(contentsOf: url)
            self.kernel = try CIKernel(functionName: "hslAdjust", fromMetalLibraryData: data)
        } catch {
            fatalError("[ERROR] HSLFilter: \(error)")
        }
        
        super.init()
    }
    
    required init?(coder: NSCoder) {
        fatalError("[ERROR] HSLFilter: init(coder:) has not been implemented")
    }
    
    override var outputImage: CIImage? {
        guard let image = inputImage else { return inputImage }
        
        let hslData = Data(bytes: inputHSLValues, count: MemoryLayout<simd_float3>.stride * inputHSLValues.count)
        
        return kernel.apply(
            extent: image.extent,
            roiCallback: { _, rect in rect },
            arguments: [
                image,
                hslData,
                inputGrayMix
            ]
        )
    }
    
    public func updateHSLValues(from rawParams: [FilterParameter: Float]) {
        let baseHues: [Float] = [-0.5, 0.0, 0.5, 0.916667, 1.5833334, 2.6666667, 3.8333335, 4.5833335, 5.5, 6.0]
        var processedValues: [simd_float3] = []

        for i in 0..<8 {
            let hueParam = FilterParameter(rawValue: FilterParameter.hueAdjustmentRed.rawValue + i)!
            let satParam = FilterParameter(rawValue: FilterParameter.saturationAdjustmentRed.rawValue + i)!
            let lumParam = FilterParameter(rawValue: FilterParameter.luminanceAdjustmentRed.rawValue + i)!
            let grayParam = FilterParameter(rawValue: FilterParameter.grayMixerRed.rawValue + i)!

            let rawHue = rawParams[hueParam] ?? 0.0
            let rawSat = rawParams[satParam] ?? 0.0
            let rawLum = rawParams[lumParam] ?? 0.0
            let rawGray = rawParams[grayParam] ?? 0.0
            
            let finalHue: Float
            if rawHue >= 0 {
                let hueShift = rawHue / 100.0
                finalHue = mix(baseHues[i + 1], baseHues[i + 2], hueShift)
            } else {
                let hueShift = -rawHue / 100.0
                finalHue = mix(baseHues[i + 1], baseHues[i], hueShift)
            }

            let finalSat = rawSat / 100.0
            let finalLum = rawLum / 100.0
            
            processedValues.append(simd_float3(finalHue, finalSat, finalLum))
        }

        var lastValue = processedValues[0]
        lastValue.x += 6.0
        processedValues.append(lastValue)

        self.inputHSLValues = processedValues
        self.inputGrayMix = rawParams[.graySwitch] ?? 0.0
    }
    
    func mix(_ x: Float, _ y: Float, _ a: Float) -> Float {
        return x * (1.0 - a) + y * a
    }
}
