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
	float renderZ = myDepth.Load(loc).r;
	//renderZ = renderZ < 1.0 ? renderZ : 0.0; // Remove infinity depth

	// calculating offset depending on depth, focus and userinput gOffsetStrength. Also truncate those to fit as integer
    float strength = abs(gOffsetStrength * renderZ - gZFocus);

	// calculating resulting positions
	float3 result = int3(loc.x + strength, loc.x - strength, strength);

	// clamping the location values to screensize
    result = float3(clamp(result.xy, 0, gScreenSize.x - 1), result.z);

    float3 resultColorPreview = float3(result.rg, result.b);

    return float4(resultColorPreview.rgb, 1.0);
}


/*
check every pixel within gOffsetStrength range if the vector (x only for now) 
in the offsetTex results in	the current pixel and if so take color from there.

If multiple results are found:
choose the one with the shortest distance/lowest strength

WARNING:
    -   This still only takes 1 pixel into consideration for the offset,
        the second one is missing
*/

float4 spiderDepthFrag(vertexOutputSampler i) : SV_Target {
	int3 loc = int3(i.pos.xy, 0);

	Texture2D myDepth = gDepthTex;

	// using only x/u axis for now
	bool resultDiscard = false;
    int3 resultLoc = int3(0, 0, 0);
    int resultLen = gOffsetStrength * 2;

    for (int u = -int(gOffsetStrength); u <= int(gOffsetStrength); u++)
    {
		// get the work coordinate
        int3 workLoc = loc + int3(u, 0, 0);

		// reading the resulting locations
		int3 resultingLocPos = int3(gOffsetTex.Load(workLoc).x, workLoc.y, 0);
		int3 resultingLocNeg = int3(gOffsetTex.Load(workLoc).y, workLoc.y, 0);

        // if the positions match
        if (resultingLocPos.x - loc.x == 0 || resultingLocNeg.x - loc.x == 0)
        //if (resultingLocPos.x - loc.x == 0)
        {
            // the strength or length of the offset vector at workLoc position
            // better naming may be appropriate
            int resultingLocLen = gOffsetTex.Load(workLoc).z;

            // if the strength or vector length is smaller than what is currently 
            // in the result variable overwrite it and process next pixel
            if (resultingLocLen < resultLen)
            {
                resultLoc = workLoc;
                resultLen = resultingLocLen;
            }
            
        }
    }

    
   
    // fetch colors
    float4 renderTex = gColorTex.Load(loc);
    float4 offsetTex = gColorTex.Load(resultLoc);

    // fetch Z
    float renderZ = myDepth.Load(loc);
    float offsetZ = myDepth.Load(resultLoc) - gDepthBias;

	// merge colors
    float4 empty = float4(0.0, 0.0, 0.0, 0.0);
    float4 resultTex = abs(renderZ) < abs(offsetZ) ? renderTex : (renderTex + offsetTex) * 0.5;

    // interpolate effect strength
    // outTex = lerp(renderTex, outTex, gDepthEffectMix);

    return resultTex;
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
