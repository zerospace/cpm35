//
//  GrainShader.metal
//  CPM35
//
//  Created by Oleksandr Fedko on 20.08.2025.
//

#include <metal_stdlib>
#include <CoreImage/CoreImage.h>
using namespace metal;

extern "C" {
    namespace coreimage {
        float4 grain(sampler source, float time, float strenght) {
            float2 coord = source.coord();
            float4 color = source.sample(coord);
            
            float x = (coord.x + 4.0) * (coord.y + 4.0) * (time * 10.0);
            float4 grain = (fmod((fmod(x, 13.0) + 1.0) * (fmod(x, 123.0) + 1.0), 0.01) - 0.005) * strenght;
            
            return color + grain;
        }
    }
}
