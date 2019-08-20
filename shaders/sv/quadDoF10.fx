////////////////////////////////////////////////////////////////////////////////////////////////////
// quadDoF.fx (HLSL)
// Brief: Depth of Field via CMYK Offset
// Contributors: Jason Schuehlein
////////////////////////////////////////////////////////////////////////////////////////////////////
//    ____             _   _               __    _____ _      _     _ 
//   |  _ \  ___ _ __ | |_| |__      ___  / _|  |  ___(_) ___| | __| |
//   | | | |/ _ \ '_ \| __| '_ \    / _ \| |_   | |_  | |/ _ \ |/ _` |
//   | |_| |  __/ |_) | |_| | | |  | (_) |  _|  |  _| | |  __/ | (_| |
//   |____/ \___| .__/ \__|_| |_|   \___/|_|    |_|   |_|\___|_|\__,_|
//              |_|                                                   
//
////////////////////////////////////////////////////////////////////////////////////////////////////
// This shader tries to imitate the depth of field effect of 'Spider-Man into the Spider-Verse'
////////////////////////////////////////////////////////////////////////////////////////////////////
#include "..\\include\\quadCommon.fxh"
#include "..\\include\\quadColorTransform.fxh"

// COMMON MAYA VARIABLES
//float2 gScreenSize : ViewportPixelSize;  // screen size, in pixels
//float gNCP : NearClipPlane;  // near clip plane distance

// TEXTURES
// Texture2D gSubstrateTex;
// Texture2D gControlTex;
Texture2D gDepthTex;
Texture2D gZBuffer;
Texture2D gControlTex;

// VARIABLES
float gZClipNear = 10.0;
float gZClipFar = 90.0;
float gZFocus = 0.0;
float gOffsetStrength = 10.0;
float gDepthBias = 1.0;
float gColorSepMix = 1.0;
float gDepthEffectMix = 1.0;

float4 gColorSepA = float4(1.0, 1.0, 0.0, 1.0);
float4 gColorSepB = float4(0.0, 1.0, 1.0, 1.0);

// FUNCTIONS
float4 Screen(float4 cBase, float4 cBlend)
{
	return (1 - (1 - cBase) * (1 - cBlend));
}

float4 Overlay(float4 cBase, float4 cBlend)
{
	float isLessOrEq = step(cBase, .5);
	float4 cNew = lerp(2 * cBlend * cBase, 1 - (1 - 2 * (cBase - .5)) * (1 - cBlend), isLessOrEq);
	cNew.a = 1.0;
	return cNew;
}

//    ____   ____ ____       ____       ____ __  ____   ___  __
//   |  _ \ / ___| __ )     / /\ \     / ___|  \/  \ \ / / |/ /
//   | |_) | |  _|  _ \    / /  \ \   | |   | |\/| |\ V /| ' / 
//   |  _ <| |_| | |_) |   \ \  / /   | |___| |  | | | | | . \ 
//   |_| \_\\____|____/     \_\/_/     \____|_|  |_| |_| |_|\_\
//                                                             
float4 rgb2cmyk(float4 color) {
	float k = 1 - max(max(color.r, color.g), color.b);		

	float c = (1 - color.r - k) / (1 - k);	
	float m = (1 - color.g - k) / (1 - k);	
	float y = (1 - color.b - k) / (1 - k);	
	
	// alternative formula for a rough transformation
	// float3 cmy = 1 - color
	// cmyk.w = min(cmyk.x, min(cmyk.y, cmyk.z)); // Create K

	return float4(c, m, y, k);
}

float3 cmyk2rgb(float4 cmyk) {
	float r = (1 - cmyk.x) * (1 - cmyk.w);
	float g = (1 - cmyk.y) * (1 - cmyk.w);
	float b = (1 - cmyk.z) * (1 - cmyk.w);

	return float3(r, g, b);
}


//        _               _
//    ___| |__   __ _  __| | ___ _ __ ___
//   / __| '_ \ / _` |/ _` |/ _ \ '__/ __|
//   \__ \ | | | (_| | (_| |  __/ |  \__ \
//   |___/_| |_|\__,_|\__,_|\___|_|  |___/
//
// Fragment/pixel shaders are functions that runs at each pixels. These can write
// on up to 8 render targets at the same time. Check the quadAdjustLoad10.fx
// shader for an example of multiple render target (MRT) shaders
float4 offsetDoFFrag(vertexOutputSampler i) : SV_Target {
	// current pixel location
	int3 loc = int3(i.pos.xy, 0);

	// ToDo:
	//	- Implement Near and Far Clipping
	//	- weird behavior of zfocus
	//		-> gZBuffer seems to be always 1.0 - normalization??
	//	- weird blending of offset colors
	//		-> improve z merging of offset colors
	//	- thresholding input
	//		-> external shader?
	//	- where is the nuke prototype?
	//	- offset at an angle
	//	- more than two offsets?
	//	- figure out what to do with the alpha channel
    //  - effect disapperaring at depth 100
    //      -> when changing camera near clip 0.1 to 1.0 it works again
    //      -> understand relationship between maya clip planes and resulting z depth
    //  - use linear depth instead?
    //      -> has the depth of two following frames in it!
    //  - Use Principles of a Deformation Shader
	//	- Shader currently only comparing Z depth between fore and background pixel
	//		-> should be consistently around object
	//		-> Spread texture instead of taking it in

    // debug switch between depths
    //Texture2D myDepth = gZBuffer;
    Texture2D myDepth = gDepthTex;

    float4 empty = float4(0.0, 0.0, 0.0, 0.0);

	// Sampling renderTex and Z
	float4 renderTex = gColorTex.Load(loc);
    float renderZ = myDepth.Load(loc);
	renderZ = renderZ < 1.0 ? renderZ : 0.0; // Remove infinity depth

	// calculating offset for pixel shift
    //int3 off = int3(trunc(gOffsetStrength * pow(renderZ - gZFocus, 2)), 0, 0);	// this may be more physically accurate
    float strength = gOffsetStrength * (renderZ - gZFocus);
    int3 off = int3(strength, 0, 0);
	int3 posOffLoc = loc + off;
	int3 negOffLoc = loc - off;

	// clamping offset locations to screen size
	posOffLoc = clamp(posOffLoc, int3(0, 0, 0), int3(gScreenSize.x - 1, gScreenSize.y - 1, 0));
	negOffLoc = clamp(negOffLoc, int3(0, 0, 0), int3(gScreenSize.x - 1, gScreenSize.y - 1, 0));

	// positive offset
    float posOffZ = myDepth.Load(posOffLoc).r + gDepthBias;
    //float4 posOffTex = renderZ < posOffZ ? empty : gColorTex.Load(posOffLoc);
	float4 posOffTex = gColorTex.Load(posOffLoc);

	// positive offset
    float negOffZ = myDepth.Load(negOffLoc).r + gDepthBias;
    //float4 negOffTex = renderZ < negOffZ ? empty : gColorTex.Load(negOffLoc);
	float4 negOffTex = gColorTex.Load(loc);

	// shifting color channels
    float4 shiftedTexAdd = renderTex + 0.5 * (negOffTex + posOffTex);

	// z-Merge offset textures
    float4 outTex = float4(0.0, 0.0, 0.0, 0.0);
    
    outTex = renderZ < posOffZ ? renderTex : float4(luminance(posOffTex.rgb) * gColorSepB.rgb, 1.0);
    outTex += renderZ < negOffZ ? renderTex : float4(luminance(negOffTex.rgb) * gColorSepA.rgb, 1.0);
    outTex *= .5;

    // interpolate color and effect strength
    outTex = lerp(shiftedTexAdd, outTex, gColorSepMix);
	outTex = lerp(renderTex, outTex, gDepthEffectMix);

    return outTex;
}


//    _            _           _
//   | |_ ___  ___| |__  _ __ (_) __ _ _   _  ___  ___
//   | __/ _ \/ __| '_ \| '_ \| |/ _` | | | |/ _ \/ __|
//   | ||  __/ (__| | | | | | | | (_| | |_| |  __/\__ \
//    \__\___|\___|_| |_|_| |_|_|\__, |\__,_|\___||___/
//                                  |_|
// A technique defines the combination of Vertex, Geometry and Fragment/Pixel
// shader that runs to draw whatever is assigned with the shader.
technique11 offsetDoF {
	pass p0 {
		SetVertexShader(CompileShader(vs_5_0, quadVertSampler()));
		SetGeometryShader(NULL);
		SetPixelShader(CompileShader(ps_5_0, offsetDoFFrag()));
	}
}
