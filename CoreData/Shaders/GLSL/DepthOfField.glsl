#include "Uniforms.glsl"
#include "Samplers.glsl"
#include "Transform.glsl"
#include "ScreenPos.glsl"
#include "PostProcess.glsl"

#define NUM_TAPS 8

varying vec2 vScreenPos;

#ifdef COMPILEPS
uniform vec2 cHBlurInvSize;
#endif

void VS()
{
    mat4 modelMatrix = iModelMatrix;
    vec3 worldPos = GetWorldPos(modelMatrix);
    gl_Position = GetClipPos(worldPos);
    vScreenPos = GetScreenPosPreDiv(gl_Position);
}



void PS()
{
#line 0
    float pixelSizeHigh = cHBlurInvSize.y;
    float pixelSizeLow = cHBlurInvSize.y / 8.0;
    
    //float m = pixelSizeHigh;
    //vec2 poisson[NUM_TAPS];
        
    vec2 vMaxCoC = vec2(5f, 10f);
    float radiusScale = 0.3f;
    
    vec4 cOut = texture2D(sNormalMap, vScreenPos); // original
    //vec4 cOut = texture2D(sDiffMap, vScreenPos); // blurred
    
    float discRadius; 
    float discRadiusLow; 
    float centerDepth;
    
    centerDepth = cOut.a;
    
    discRadius = abs(cOut.a * vMaxCoC.y - vMaxCoC.x);
    discRadiusLow = discRadius * radiusScale;
    cOut = vec4(0.0f);
    
    for (int t = 0; t < NUM_TAPS; t++) 
    {
        //poisson 
        // [-4 4]
        //float px = (-NUM_TAPS / 2.0f + t);
        //float py = (-NUM_TAPS / 2.0f + t);
        //float px = (-4 + t);
        //float py = (-4 + t);
        //random [-1,1] * 8 -> [-8, 8]
        
        vec2 p = noise2(vScreenPos.xy) * NUM_TAPS;
                
        vec2 coordLow = vScreenPos + vec2(pixelSizeHigh * p.x * discRadiusLow);
        vec2 coordHigh = vScreenPos + vec2(pixelSizeHigh * p.y * discRadius);
        
        //vec2 coordLow = vScreenPos + vec2(px * discRadiusLow);
        //vec2 coordHigh = vScreenPos + vec2(py * discRadius);
        
        //vec2 coordLow = vScreenPos + vec2(pixelSizeLow * discRadiusLow);
        //vec2 coordHigh = vScreenPos + vec2(pixelSizeHigh * discRadius);
        
        vec4 tapLow = texture2D(sDiffMap, coordLow);
        vec4 tapHigh = texture2D(sNormalMap, coordHigh);
        
        float tapBlur = abs(tapHigh.a * 2.0 - 1.0);
                
        vec4 tap = mix(tapHigh, tapLow, tapBlur);
                
        tap.a = (tap.a >= centerDepth) ? 1.0f : abs(tap.a * 2.0 - 1.0);
                 
        cOut.rgb += tap.rgb * tap.a;
        cOut.a += tap.a;
    }
    
    gl_FragColor = cOut / cOut.a;
    
    //vec4 lowres = texture2D(sNormalMap, vScreenPos);
    //gl_FragColor = vec4(lowres.a);
    //vec4 hires = texture2D(sNormalMap, vScreenPos);
    //float depth = ReconstructDepth(texture2D(sDepthBuffer, vScreenPos).r);
    //gl_FragColor = vec4(lowres.a);
}

