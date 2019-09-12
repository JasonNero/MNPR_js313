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
Texture2D gOffsetTex;

// VARIABLES
float gZFocus = 0.0;
float gOffsetStrength = 10.0;
float gDepthBias = 1.0;
float gDepthEffectMix = 0.5;
float gColorSepMix = 0.5;

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

    return float4(result, 1.0);
}


/*
check every pixel within gOffsetStrength range if the vector (x only for now) 
in the offsetTex results in	the current pixel and if so take color from there.

If multiple results are found:
choose the one with the shortest distance/lowest strength
*/

float4 spiderDepthFrag(vertexOutputSampler i) : SV_Target {
	int3 loc = int3(i.pos.xy, 0);

	Texture2D myDepth = gDepthTex;

	// using only x/u axis for now
	bool resultDiscard = false;

    int3 resultLocA = int3(0, 0, 0);
    int3 resultLocB = int3(0, 0, 0);
    int resultLenA = gOffsetStrength * 2;
    int resultLenB = gOffsetStrength * 2;

    // iterating through the row
    for (int u = -int(gOffsetStrength); u <= int(gOffsetStrength); u++)
    {
		// get the work coordinate
        int3 workLoc = loc + int3(u, 0, 0);

		// reading the resulting locations
		int3 resultingLocPos = int3(gOffsetTex.Load(workLoc).x, workLoc.y, 0);
		int3 resultingLocNeg = int3(gOffsetTex.Load(workLoc).y, workLoc.y, 0);

        // if the positions match
        if (resultingLocPos.x - loc.x == 0)
        {
            // the strength or length of the offset vector at workLoc position
            // better naming may be appropriate
            int resultingLocLenA = gOffsetTex.Load(workLoc).z;

            // if the strength or vector length is smaller than what is currently 
            // in the result variable overwrite it and process next pixel
            if (resultingLocLenA < resultLenA)
            {
                resultLocA = workLoc;
                resultLenA = resultingLocLenA;
            }
        }
        
        if (resultingLocNeg.x - loc.x == 0)
        {
            // the strength or length of the offset vector at workLoc position
            // better naming may be appropriate
            int resultingLocLenB = gOffsetTex.Load(workLoc).z;

            // if the strength or vector length is smaller than what is currently 
            // in the result variable overwrite it and process next pixel
            if (resultingLocLenB < resultLenB)
            {
                resultLocB = workLoc;
                resultLenB = resultingLocLenB;
            }
        }
    }

    // fetch colors
    float4 renderTex = gColorTex.Load(loc);
    float4 offsetTexA = gColorTex.Load(resultLocA);
    float4 offsetTexB = gColorTex.Load(resultLocB);

    // fetch Z
    float renderZ = myDepth.Load(loc);
    float offsetZA = myDepth.Load(resultLocA) + gDepthBias;
    float offsetZB = myDepth.Load(resultLocB) + gDepthBias;

    // merge offsets
    float4 addedOffsetTex = (offsetTexA + offsetTexB) / 2;
    float4 coloredOffsetTex = (offsetTexA * gColorSepA) + (offsetTexB * gColorSepB);
    float4 mergedOffsetZ = min(offsetZA, offsetZB);

	// merge colors
    float4 empty = float4(0.0, 0.0, 0.0, 0.0);
    //float4 resultTex = abs(renderZ) < abs(mergedOffsetZ) ? renderTex : lerp(addedOffsetTex, coloredOffsetTex, gColorSepMix);
    float4 resultTex = lerp(addedOffsetTex, coloredOffsetTex, gColorSepMix);

    // interpolate effect strength
    // outTex = lerp(renderTex, outTex, gDepthEffectMix);

    return lerp(renderTex, resultTex, gDepthEffectMix);
}

/////////////////////////////////////////////////////////////////////////////

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