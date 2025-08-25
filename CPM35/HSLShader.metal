//
//  HSLShader.metal
//  HSLFilter
//
//  Created by Oleksandr Fedko on 23.01.2024.
//

#include <metal_stdlib>
#include <CoreImage/CoreImage.h>
using namespace metal;

extern "C" {
    namespace coreimage {
        float3 rgbToHSL(float3 rgb) {
            float minVal = min3(rgb.r, rgb.g, rgb.b);
            float maxVal = max3(rgb.r, rgb.g, rgb.b);
            float delta = max(0.0001, maxVal - minVal);

            float hue;
            if (maxVal == rgb.r) {
                hue = (rgb.g - rgb.b) / delta;
            } else if (maxVal == rgb.g) {
                hue = 2.0 + (rgb.b - rgb.r) / delta;
            } else {
                hue = 4.0 + (rgb.r - rgb.g) / delta;
            }

            hue = fmod(hue + 6.0, 6.0);
            return float3(hue, minVal, maxVal);
        }
        
        float3 hslToRGB(float3 hsl) {
            float h = hsl.x;
            float minVal = hsl.y;
            float maxVal = hsl.z;
            float chroma = maxVal - minVal;

            float h_prime = fmod(h, 6.0);
            float x = chroma * (1.0 - abs(fmod(h_prime, 2.0) - 1.0));

            float3 rgb;
            if (h_prime < 1.0) {
                rgb = float3(chroma, x, 0);
            } else if (h_prime < 2.0) {
                rgb = float3(x, chroma, 0);
            } else if (h_prime < 3.0) {
                rgb = float3(0, chroma, x);
            } else if (h_prime < 4.0) {
                rgb = float3(0, x, chroma);
            } else if (h_prime < 5.0) {
                rgb = float3(x, 0, chroma);
            } else {
                rgb = float3(chroma, 0, x);
            }

            return rgb + float3(minVal);
        }
        
        float3 getHSLForHue(float hue, constant float3 hslValues[9]) {
            const float4 tapSlopesA = float4(2.0, 2.3999998, 1.5, 0.923077);
            const float4 tapAddsA   = float4(0.0, -1.2, -1.375, -1.4615385);
            const float4 tapSlopesB = float4(0.8571428, 1.3333334, 1.0909091, 2.0);
            const float4 tapAddsB   = float4(-2.2857142, -5.1111116, -5.0, -11.0);

            float3 outVals = float3(0.0);
            
            float4 tA = hue * tapSlopesA + tapAddsA;
            if (tA.x >= 0.0 && tA.x <= 1.0) outVals += mix(hslValues[0], hslValues[1], tA.x);
            if (tA.y >= 0.0 && tA.y <= 1.0) outVals += mix(hslValues[1], hslValues[2], tA.y);
            if (tA.z >= 0.0 && tA.z <= 1.0) outVals += mix(hslValues[2], hslValues[3], tA.z);
            if (tA.w >= 0.0 && tA.w <= 1.0) outVals += mix(hslValues[3], hslValues[4], tA.w);

            float4 tB = hue * tapSlopesB + tapAddsB;
            if (tB.x >= 0.0 && tB.x <= 1.0) outVals += mix(hslValues[4], hslValues[5], tB.x);
            if (tB.y >= 0.0 && tB.y <= 1.0) outVals += mix(hslValues[5], hslValues[6], tB.y);
            if (tB.z >= 0.0 && tB.z <= 1.0) outVals += mix(hslValues[6], hslValues[7], tB.z);
            if (tB.w >= 0.0 && tB.w <= 1.0) outVals += mix(hslValues[7], hslValues[8], tB.w);

            outVals.x = fmod(outVals.x + 6.0, 6.0);
            return outVals;
        }
        
        float3 applyLumSat(float3 hsl, float satShift, float lumShift, float grayMix) {
            float3 outVal = hsl;

            float initialGap = hsl.z - hsl.y;
            float lumFactor = lumShift * (1.0 - pow(1.0 - initialGap, 8.0));

            float2 yz = outVal.yz;
            yz += lumFactor * yz * (1.0 - yz);
            yz += lumFactor * yz * (1.0 - yz);
            outVal.yz = yz;

            float L = 0.5 * (outVal.z + outVal.y);
            outVal.y += satShift * (outVal.y - L);
            outVal.z += satShift * (outVal.z - L);
            
            if (grayMix > 0.0) {
                float gray = hsl.y + lumShift * (hsl.z - hsl.y);
                gray = clamp(gray, 0.0, 1.0);
                outVal.y = mix(outVal.y, gray, grayMix);
                outVal.z = mix(outVal.z, gray, grayMix);
            }

            return outVal;
        }
        
        float4 hslAdjust(sampler source, constant float3 hslValues[9], float grayMix) {
            float2 coord = source.coord();
            float4 src = source.sample(coord);
            float3 rgb = src.rgb;
            
            float3 hsl = rgbToHSL(rgb);
            float3 hslAdjustments = getHSLForHue(hsl.x, hslValues);
            hsl.x = hslAdjustments.x;
            hsl = applyLumSat(hsl, hslAdjustments.y, hslAdjustments.z, grayMix);
            rgb = hslToRGB(hsl);
            return float4(clamp(rgb, 0.0, 1.0), src.a);
        }
    }
}


