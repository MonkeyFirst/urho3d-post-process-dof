#include "Uniforms.glsl"
#include "Samplers.glsl"
#include "Transform.glsl"
#include "ScreenPos.glsl"

varying vec2 vScreenPos;

#ifdef COMPILEPS
uniform float cSmoothFocus;
uniform bool cSmoothFocusEnabled;
uniform float cFocal;
uniform float cFocalNear;
uniform float cFocalFar;
#endif

void VS()
{
    mat4 modelMatrix = iModelMatrix;
    vec3 worldPos = GetWorldPos(modelMatrix);
    gl_Position = GetClipPos(worldPos);
    vScreenPos = GetScreenPosPreDiv(gl_Position);
}

#ifdef COMPILEPS
float Linearize(float depth)
{
	return -cFarClipPS * cNearClipPS / (depth * (cFarClipPS - cNearClipPS) - cFarClipPS);
}

float DepthToAlpha(float depth, float centerDepth) 
{
    float f;
    vec4 vDofParams;
    
    //cNearClipPS 0.1 
    //cFarClipPS 1000
    
    float invFullField = 1.0f / (cFarClipPS - cNearClipPS); // 0.001 
    float focal = invFullField * cFocal;        
        
    // x = near blur depth    
    vDofParams.x = centerDepth - (invFullField * cFocalNear);
    
    // y = focal plane depth 
    vDofParams.y = centerDepth;
    
    // z = far blur depth
    vDofParams.z = centerDepth + (invFullField * cFocalFar); 
    
    // w = blurriness cutoff constant for objects behind the focal plane
    vDofParams.w = 1;
    
    
    if (depth < vDofParams.y)
    {
        //[-1, 0] range
        f = (depth - vDofParams.y) / (vDofParams.y - vDofParams.x);
    }
    else 
    {
        f = (depth - vDofParams.y) / (vDofParams.z - vDofParams.x);
        f = clamp(f, 0, vDofParams.w);
    }
         
    return f * 0.5f + 0.5f;
}

void PS()
{
    float depth = ReconstructDepth(texture2D(sNormalMap, vScreenPos).r);
    float focusDepth = 0;
    
    if (cSmoothFocusEnabled) // based on interpolated rays by octree
    {
        float invFullField = 1.0f / (cFarClipPS - cNearClipPS);
        focusDepth = invFullField * cSmoothFocus;
    }
    else // crappy fast auto focus based on center pixel from depth 
    {    
        focusDepth = ReconstructDepth(texture2D(sNormalMap, vec2(0.5, 0.5)).r);
    }
    
    float a = DepthToAlpha(depth, focusDepth);
    //float blur = clamp(1.0, 0.0, 1.0); 
    //gl_FragColor = vec4(a, blur, 0, 0);
    gl_FragColor = vec4(a, 0, 0, 0);
}
#endif
