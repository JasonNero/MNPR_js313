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

// TEXTURES
// Texture2D gSubstrateTex;
// Texture2D gControlTex;
Texture2D gDepthTex;

// VARIABLES
float gZClipNear = 10.0;
float gZClipFar = 90.0;


// FUNCTIONS

//    ____   ____ ____       ____       ____ __  ____   ___  __
//   |  _ \ / ___| __ )     / /\ \     / ___|  \/  \ \ / / |/ /
//   | |_) | |  _|  _ \    / /  \ \   | |   | |\/| |\ V /| ' / 
//   |  _ <| |_| | |_) |   \ \  / /   | |___| |  | | | | | . \ 
//   |_| \_\\____|____/     \_\/_/     \____|_|  |_| |_| |_|\_\
//                                                             
float4 rgb2cmyk(float3 color) {
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

	// offset for pixel shift
	// ToDo: Elevate 10 as depth offset slider
	int3 off = int3(10, 0, 0);
	int3 posOffLoc = loc + off;
	int3 negOffLoc = loc - off;

	// clamping offset locations to screen size
	posOffLoc = clamp(posOffLoc, int3(0, 0, 0), int3(gScreenSize.x - 1, gScreenSize.y - 1, 0));
	negOffLoc = clamp(negOffLoc, int3(0, 0, 0), int3(gScreenSize.x - 1, gScreenSize.y - 1, 0));

	// Sampling 
	// ToDo: Elevate 0.01 as depth bias slider
	float4 inputTexZ = float4(gColorTex.Load(loc).rgb, gDepthTex.Load(loc).r);
	float4 posOffTexZ = float4(gColorTex.Load(posOffLoc).rgb, gDepthTex.Load(posOffLoc).r + 0.01);
	float4 negOffTexZ = float4(gColorTex.Load(negOffLoc).rgb, gDepthTex.Load(negOffLoc).r + 0.01);

	// shifting color channels
	// ToDo: Elevate controls which channels to offset
	float4 shiftedTexZ = float4(renderTex.r, posOffTex.g, negOffTex.b, min(posOffTex.w, negOffTex.w));

	// z-Merge shitedTex and renderTex
	// ToDo: process image from back to front?
	float4 outTex = renderTex.w < shiftedTex.w ? renderTex : shiftedTex;
	outTex = float4(outTex.r, outTex.g, outTex.b, 0.0);

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
