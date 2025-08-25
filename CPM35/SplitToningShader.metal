//
//  SplitToningShader.metal
//  CPM35
//
//  Created by Oleksandr Fedko on 24.08.2025.
//

#include <metal_stdlib>
#include <CoreImage/CoreImage.h>
using namespace metal;

extern "C" {
    namespace coreimage {
        float3 divMap(float3 color, float alpha) {
            float3 scaled = alpha * color;
            return scaled / (float3(1.0) + scaled - color);
        }

        float3 divMapInverse(float3 color, float alpha) {
            float3 scaled = color / alpha;
            return scaled / (float3(1.0) + scaled - color);
        }
        
        float4 splitToning(sampler source, simd_float3 shadowTint, simd_float3 shadowDelta, float balance) {
            float4 src = source.sample(source.coord());
            float3 rgb = src.rgb;

            float d0 = 0.5 - (balance / 100.0 * 0.4);
            float fd0 = (d0 <= 0.04045) ? d0 / 12.92 : pow((d0 + 0.055) / 1.055, 2.4);
            float alpha = ((1.0 - fd0) * 0.5) / (fd0 * 0.5);

            // Apply the non-linear mapping
            rgb = divMap(rgb, alpha);

            // Apply the shadow and highlight tints using the pre-calculated delta
            rgb = rgb * ((float3(1.0) - rgb) * (shadowTint + shadowDelta * rgb) + rgb * rgb);

            // Apply the inverse mapping to return to the normal color space
            rgb = divMapInverse(rgb, alpha);

            return float4(clamp(rgb, 0.0, 1.0), src.a);
        }
    }
}


