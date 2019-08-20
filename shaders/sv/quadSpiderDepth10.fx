////////////////////////////////////////////////////////////////////////////////////////////////////
// quadSpiderDepth.fx (HLSL)
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

// TEXTURES
Texture2D gDepthTex;
Texture2D gZBuffer;
Texture2D gControlTex;
Texture2D gOffsetTex;

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


//        _               _
//    ___| |__   __ _  __| | ___ _ __ ___
//   / __| '_ \ / _` |/ _` |/ _ \ '__/ __|
//   \__ \ | | | (_| | (_| |  __/ |  \__ \
//   |___/_| |_|\__,_|\__,_|\___|_|  |___/
//
// Fragment/pixel shaders are functions that runs at each pixels. These can write
// on up to 8 render targets at the same time. Check the quadAdjustLoad10.fx
// shader for an example of multiple render target (MRT) shaders

float4 spiderCocFrag(vertexOutputSampler i) : SV_Target{
	// current pixel location
	int3 loc = int3(i.pos.xy, 0);
	float2 axis = float2(1.0, 0.0);

	Texture2D myDepth = gDepthTex;

	// Sampling Z
	float renderZ = myDepth.Load(loc);
	//renderZ = renderZ < 1.0 ? renderZ : 0.0; // Remove infinity depth

	// calculating offset vector
	float2 strength = (gOffsetStrength * (renderZ - gZFocus)) * axis;

	return strength.xyxy;
}

float4 spiderDepthFrag(vertexOutputSampler i) : SV_Target {
	int3 loc = int3(i.pos.xy, 0);

	Texture2D myDepth = gDepthTex;

    float4 renderTex = gColorTex.Load(loc);
    float4 offsetTex = gOffsetTex.Load(loc);
	float renderZ = myDepth.Load(loc);

	/*
	check every pixel within gOffsetStrength range if the vector in the offsetTex results in
	the current pixel and if so take color from there.
	If multiple results are found choose the nearest one in zDepth.
	*/

	// using only x/u axis for now
    int3 result = int3(0, 0, 0);
    float resultZ = 1;

    for (int u = -gOffsetStrength; u <= gOffsetStrength; u++)
    {
        int3 currentLoc = loc + int3(u, 0, 0);
        int offsetLoc = trunc(gOffsetTex.Load(currentLoc));
		int3 resultingLoc = currentLoc + offsetLoc;
        if (resultingLoc == loc)
        {
			/////////////////////
			// TODO GO ON HERE //
			/////////////////////

            result = gDepthTex.Load(resultingLoc) < resultZ ? 

        }
    }

	// clamping 

	// positive offset

	// positive offset

	// merge offset textures

    // interpolate effect strength
    // outTex = lerp(renderTex, outTex, gDepthEffectMix);

    return renderZ.xxxx;
}


//    _            _           _
//   | |_ ___  ___| |__  _ __ (_) __ _ _   _  ___  ___
//   | __/ _ \/ __| '_ \| '_ \| |/ _` | | | |/ _ \/ __|
//   | ||  __/ (__| | | | | | | | (_| | |_| |  __/\__ \
//    \__\___|\___|_| |_|_| |_|_|\__, |\__,_|\___||___/
//                                  |_|
// A technique defines the combination of Vertex, Geometry and Fragment/Pixel
// shader that runs to draw whatever is assigned with the shader.
technique11 spiderCoc {
	pass p0 {
		SetVertexShader(CompileShader(vs_5_0, quadVertSampler()));
		SetGeometryShader(NULL);
		SetPixelShader(CompileShader(ps_5_0, spiderCocFrag()));
	}
}

technique11 spiderDepth {
	pass p0 {
		SetVertexShader(CompileShader(vs_5_0, quadVertSampler()));
		SetGeometryShader(NULL);
		SetPixelShader(CompileShader(ps_5_0, spiderDepthFrag()));
	}
}
