#include "Uniforms.glsl"
#include "Samplers.glsl"
#include "Transform.glsl"
#include "ScreenPos.glsl"
#include "PostProcess.glsl"
#define NUM_TAPS 12
varying vec2 vScreenPos;

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
    vec4 cOut = vec4(0.0f);
    
    float pixelSizeHigh = cGBufferInvSize.x;
    float pixelSizeLow = cGBufferInvSize.x / 4 ; // Blurred frame size is 1/4 of original frame
    float dx = cGBufferInvSize.x;
    float dy = cGBufferInvSize.y;
    
    vec2 poisson[NUM_TAPS];
    poisson[0] = vec2(-0.326212f * dx, -0.40581f * dy);
    poisson[1] = vec2(-0.840144f * dx, -0.07358f * dy);
    poisson[2] = vec2(-0.695914f * dx, 0.457137f * dy);
    poisson[3] = vec2(-0.203345f * dx, 0.620716f * dy);
    poisson[4] = vec2(0.96234f * dx, -0.194983f * dy);
    poisson[5] = vec2(0.473434f * dx, -0.480026f * dy);
    poisson[6] = vec2(0.519456f * dx, 0.767022f * dy);
    poisson[7] = vec2(0.185461f * dx, -0.893124f * dy);
    poisson[8] = vec2(0.507431f * dx, 0.064425f * dy);
    poisson[9] = vec2(0.89642f * dx, 0.412458f * dy);
    poisson[10] = vec2(-0.32194f * dx, -0.932615f * dy);
    poisson[11] = vec2(-0.791559f * dx, -0.59771f * dy);
    
    
    vec2 vMaxCoC = vec2(5.0f, 10.0f);
    float radiusScale = 0.4f;
    
    vec4 depthBlur = texture2D(sSpecMap, vScreenPos); // DepthBlur texture r16
    
    float discRadius;
    float discRadiusLow; 
    float centerDepth;
    float tapContribution = 1f;


    discRadius = abs(cOut.a * vMaxCoC.y - vMaxCoC.x);
    discRadiusLow = discRadius * radiusScale;
    centerDepth = depthBlur.r;
    
    for (int t = 0; t < NUM_TAPS; t++) 
    {        
        vec2 coordLow = vScreenPos + vec2(pixelSizeLow * poisson[t] * discRadiusLow);
        vec2 coordHigh = vScreenPos + vec2(pixelSizeHigh * poisson[t] * discRadius);
        
        vec4 tapLow = texture2D(sNormalMap, coordLow);          // Blurred frame 1/4 size
        vec4 tapHigh = texture2D(sDiffMap , coordHigh);         // Original frame color data full sized
        vec4 tapDepthBlur = texture2D(sSpecMap, coordHigh);     // DepthBlur (actual only depth)
        
        float tapBlur = abs(tapDepthBlur.r * 2.0 - 1.0);
                
        vec4 tap = mix(tapHigh, tapLow, tapBlur);
                
        tapContribution = (tapDepthBlur.r >= centerDepth) ? 1.0f : abs(tapDepthBlur.r * 2.0 - 1.0);
                 
        cOut.rgb += tap.rgb * tapContribution;
        cOut.a += tapContribution;
    }
    
    gl_FragColor = cOut / cOut.a;
}

