//
//  GrainFilter.swift
//  CPM35
//
//  Created by Oleksandr Fedko on 20.08.2025.
//

import Foundation
import CoreImage

final class GrainFilter: CIFilter {
    var inputImage: CIImage?
    var strenght: Double = 16.0

    private let kernel: CIKernel
    
    override init() {
        guard let url = Bundle.main.url(forResource: "default", withExtension: "metallib") else {
            fatalError("[ERROR] Can't find default.metallib")
        }
        
        do {
            let data = try Data(contentsOf: url)
            self.kernel = try CIKernel(functionName: "grain", fromMetalLibraryData: data)
        } catch {
            fatalError("[ERROR] GrainFilter: \(error)")
        }
        
        super.init()
    }
    
    required init?(coder: NSCoder) {
        fatalError("[ERROR] GrainFilter: init(coder:) has not been implemented")
    }
    
    override var outputImage: CIImage? {
        guard let image = inputImage else { return inputImage }
        
        return kernel.apply(
            extent: image.extent,
            roiCallback: { _, rect in rect },
            arguments: [
                image,
                CFAbsoluteTimeGetCurrent().truncatingRemainder(dividingBy: 1000),
                strenght
            ]
        )
    }
}
