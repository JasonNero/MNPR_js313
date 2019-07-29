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

	// Sampling renderTex and Z
	float4 renderTex = gColorTex.Load(loc);
	float renderZ = gZBuffer.Load(loc).r;

	// calculating offset for pixel shift
	// ToDo: Elevate 10 as depth offset slider
	float strength = 10;
	int exponent = 1;
	int3 off = trunc(float3(strength * renderZ, 0, 0));
	//int3 off = int3(strength, 0, 0);
	int3 posOffLoc = loc + off;
	int3 negOffLoc = loc - off;

	// clamping offset locations to screen size
	posOffLoc = clamp(posOffLoc, int3(0, 0, 0), int3(gScreenSize.x - 1, gScreenSize.y - 1, 0));
	negOffLoc = clamp(negOffLoc, int3(0, 0, 0), int3(gScreenSize.x - 1, gScreenSize.y - 1, 0));

	// Sampling 
	// ToDo: Elevate depth bias slider
	float bias = 0.001;
	// ToDo: Elevate method as enum "slider"?
	// positive offset
	float4 posOffTex = gColorTex.Load(posOffLoc);
	float posOffZ = gZBuffer.Load(negOffLoc).r + bias;
	//float posOffZ = gZBuffer.Load(posOffLoc).r + bias;

	// negative offset
	float4 negOffTex = gColorTex.Load(negOffLoc);
	float negOffZ = gZBuffer.Load(posOffLoc).r + bias;
	//float negOffZ = gZBuffer.Load(negOffLoc).r + bias;

	// shifting color channels
	// ToDo: Elevate controls which channels to offset

	// posOffTex = float4(cmyk2rgb(float4(rgb2cmyk(posOffTex).x, 0.0, 0.0, 0.0)), posOffTex.a);
	// negOffTex = float4(cmyk2rgb(float4(0.0, rgb2cmyk(negOffTex).y, 0.0, 0.0)), negOffTex.a);
	// float4 shiftedTex = posOffTex * float4(1.0, 0.0, 0.0, 1.0) + negOffTex * float4(0.0, 1.0, 0.0, 1.0);	// in CMYK!
	// float4 shiftedTex = (posOffTex + negOffTex);
	// shiftedTex = float4(cmyk2rgb(shiftedTex), 1.0);
	
	//float4 shiftedTex = float4(negOffTex.r, renderTex.g, posOffTex.b, 0.0);
	float4 shiftedTex = Screen(negOffTex * float4(1.0, 1.0, 0.0, 1.0), posOffTex * float4(0.0, 1.0, 1.0, 1.0));
	float shiftedZ = min(posOffZ, negOffZ);

	// z-Merge shitedTex and renderTex
	// ToDo: process image from back to front?
	float4 empty = float4(0.0, 0.0, 0.0, 0.0);
	float4 outTex = renderZ < shiftedZ ? renderTex : shiftedTex;
	// outTex = float4(outTex.r, outTex.g, outTex.b, outTex.a);

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
