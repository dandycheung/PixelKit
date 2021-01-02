//
//  EffectMergerCrossPIX.metal
//  PixelKit Shaders
//
//  Created by Anton Heestand on 2017-11-12.
//  Copyright © 2017 Anton Heestand. All rights reserved.
//

#include <metal_stdlib>
using namespace metal;

struct VertexOut{
    float4 position [[position]];
    float2 texCoord;
};

struct Uniforms{
    float cross;
    float place;
};

fragment float4 effectMergerCrossPIX(VertexOut out [[stage_in]],
                                     texture2d<float>  inTexA [[ texture(0) ]],
                                     texture2d<float>  inTexB [[ texture(1) ]],
                                     const device Uniforms& in [[ buffer(0) ]],
                                     sampler s [[ sampler(0) ]]) {
    
    float u = out.texCoord[0];
    float v = out.texCoord[1];
    float2 uv = float2(u, v);
    
    float4 ca = inTexA.sample(s, uv);

    // Place
    uint aw = inTexA.get_width();
    uint ah = inTexA.get_height();
    float aspect_a = float(aw) / float(ah);
    uint bw = inTexB.get_width();
    uint bh = inTexB.get_height();
    float aspect_b = float(bw) / float(bh);
    float bu = u;
    float bv = v;
    switch (int(in.place)) {
        case 1: // Aspect Fit
            if (aspect_b > aspect_a) {
                bv /= aspect_a;
                bv *= aspect_b;
                bv += ((aspect_a - aspect_b) / 2) / aspect_a;
            } else if (aspect_b < aspect_a) {
                bu /= aspect_b;
                bu *= aspect_a;
                bu += ((aspect_b - aspect_a) / 2) / aspect_b;
            }
            break;
        case 2: // Aspect Fill
            if (aspect_b > aspect_a) {
                bu *= aspect_a;
                bu /= aspect_b;
                bu += ((1.0 / aspect_a - 1.0 / aspect_b) / 2) * aspect_a;
            } else if (aspect_b < aspect_a) {
                bv *= aspect_b;
                bv /= aspect_a;
                bv += ((1.0 / aspect_b - 1.0 / aspect_a) / 2) * aspect_b;
            }
            break;
        case 3: // Center
            bu = 0.5 + ((u - 0.5) * aw) / bw;
            bv = 0.5 + ((v - 0.5) * ah) / bh;
            break;
    }
    float4 cb = inTexB.sample(s, float2(bu, bv));
    
    float4 mc = mix(ca, cb, in.cross);
    
    return mc;
}


