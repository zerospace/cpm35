//
//  SplitToningFilter.swift
//  CPM35
//
//  Created by Oleksandr Fedko on 24.08.2025.
//

import Foundation
import CoreImage
import simd

final class SplitToningFilter: CIFilter {
    var inputImage: CIImage?
    var shadowTint = simd_float3(0, 0, 0)
    var highlightTint = simd_float3(0, 0, 0)
    var balance: Float = 0.0

    private let kernel: CIKernel
    
    override init() {
        guard let url = Bundle.main.url(forResource: "default", withExtension: "metallib") else {
            fatalError("[ERROR] Can't find default.metallib")
        }
        
        do {
            let data = try Data(contentsOf: url)
            self.kernel = try CIKernel(functionName: "splitToning", fromMetalLibraryData: data)
        } catch {
            fatalError("[ERROR] SplitToningFilter: \(error)")
        }
        
        super.init()
    }
    
    required init?(coder: NSCoder) {
        fatalError("[ERROR] SplitToningFilter: init(coder:) has not been implemented")
    }
    
    override var outputImage: CIImage? {
        guard let image = inputImage else { return inputImage }
        
        let shadowDelta = highlightTint - shadowTint
        
        return kernel.apply(
            extent: image.extent,
            roiCallback: { _, rect in rect },
            arguments: [
                image,
                CIVector(x: CGFloat(shadowTint.x), y: CGFloat(shadowTint.y), z: CGFloat(shadowTint.z)),
                CIVector(x: CGFloat(shadowDelta.x), y: CGFloat(shadowDelta.y), z: CGFloat(shadowDelta.z)),
                balance
            ]
        )
    }
    
    func calculateTint(hue: Float, saturation: Float, isShadow: Bool) -> simd_float3 {
        let satNorm = saturation / 100.0
        let f12: Float = isShadow ? -1.0 : 1.0
        let f13: Float = isShadow ? 0.2 : 0.05
        let f14: Float = 2.5

        var h = hue
        if h < 0 { h += 360 }
        if h >= 360 { h -= 360 }
        
        var f15: Float
        var c12: Int = 0, c13: Int = 0, c14: Int = 0
        
        // --- CORRECTED LOGIC IS HERE ---
        if h < 60 {
            f15 = h / 60.0; c12 = 0; c13 = 2; c14 = 1
        } else if h < 120 {
            f15 = (120.0 - h) / 60.0; c12 = 2; c13 = 0; c14 = 1
        } else if h < 180 {
            f15 = (h - 120.0) / 60.0; c12 = 2; c13 = 1; c14 = 0
        } else if h < 240 {
            f15 = (240.0 - h) / 60.0; c12 = 1; c13 = 2; c14 = 0
        } else if h < 300 {
            f15 = (h - 240.0) / 60.0; c12 = 1; c13 = 0; c14 = 2
        } else {
            f15 = (360.0 - h) / 60.0; c12 = 0; c13 = 1; c14 = 2
        }

        let fArr2: [Float] = [0.28808594, 0.71191406, 0.0]
        let f17 = (f14 - f13) * f12 * satNorm
        let fMin = min(max(f13 - f17, min(max(f13, 1.0 - ((fArr2[c12] + (fArr2[c13] * f15)) * f17)), f14)), f14 - f17)
        
        var result = simd_float3.zero
        result[c12] = fMin + f17
        result[c13] = (f17 * f15) + fMin
        result[c14] = fMin
        
        if isShadow {
            return simd_float3(repeating: 3.0) - result
        } else {
            return result
        }
    }
}
