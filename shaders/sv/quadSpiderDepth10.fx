////////////////////////////////////////////////////////////////////////////////////////////////////
// quadSpiderDepth.fx (HLSL)
// Brief: Depth of Field via Color Offset
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
float gDepthEffectMix = 0.5;
float gColorSepMix = 0.5;

float4 gColorSepA = float4(1.0, 1.0, 0.0, 1.0);
float4 gColorSepB = float4(0.0, 1.0, 1.0, 1.0);

////////////////////////////////////////////////////////////////////////////////////////////////////
//        _               _
//    ___| |__   __ _  __| | ___ _ __ ___
//   / __| '_ \ / _` |/ _` |/ _ \ '__/ __|
//   \__ \ | | | (_| | (_| |  __/ |  \__ \
//   |___/_| |_|\__,_|\__,_|\___|_|  |___/
//

/*
calculate the strength based on depth and focuspoint
then calculate the resulting offset locations
and return them together with the strength
this will write the output into the gOffsetTex Buffer for later use
*/

float4 spiderCocFrag(vertexOutputSampler i) : SV_Target{
	// current pixel location
	int3 loc = int3(i.pos.xy, 0);

	// restrained to x-Axis for now
	float2 axis = float2(1.0, 0.0);

	// Sampling Z
	float renderZ = gDepthTex.Load(loc).r;

	// calculating offset depending on depth, focus and userinput gOffsetStrength.
    float strength = abs(gOffsetStrength * renderZ - gZFocus);

	// calculating resulting positions 
	float4 result = float4(loc.x + strength, loc.x - strength, strength, 1.0);

	// clamping the location values to screensize
    result = float4(clamp(result.xy, 0, gScreenSize.x - 1), result.zw);

	// Output Layout: (Pos Offset Loc, Neg Offset Loc, Offset Strength, unused alpha 1.0)
    return result;
}


/*
check every pixel within gOffsetStrength range if the vector (x only for now) 
in the offsetTex results in	the current pixel and if so take color from there.

If multiple results are found:
choose the one with the shortest distance/lowest strength
*/

float4 spiderDepthFrag(vertexOutputSampler i) : SV_Target {
	// fetch current position
	int3 loc = int3(i.pos.xy, 0);

	// initializing variables
    int3 resultLocA = int3(0, 0, 0);
    int3 resultLocB = int3(0, 0, 0);
    int resultLenA = gOffsetStrength * 2;
    int resultLenB = gOffsetStrength * 2;

    // iterating through the row with a lookup distance of gOffsetStrength
	// only along x-Axis for now
    for (int u = -int(gOffsetStrength); u <= int(gOffsetStrength); u++)
    {
		// get the current work coordinate
        int3 workLoc = loc + int3(u, 0, 0);

		// reading the resulting locations from gOffsetTex Buffer
		int3 workLocPos = int3(gOffsetTex.Load(workLoc).x, workLoc.y, 0);
		int3 workLocNeg = int3(gOffsetTex.Load(workLoc).y, workLoc.y, 0);

        // if the positions match
        if (workLocPos.x == loc.x)
        {
            // the strength or length of the offset vector at workLoc position
            int workLocPosLen = gOffsetTex.Load(workLoc).z;

            // if the strength or vector length is smaller than what is currently 
            // in the result variable overwrite it and process next pixel
            if (workLocPosLen < resultLenA)
            {
                resultLocA = workLoc;
                resultLenA = workLocPosLen;
            }
        } 
		else if (workLocNeg.x == loc.x)
        {
            // the strength or length of the offset vector at workLoc position
            int workLocNegLen = gOffsetTex.Load(workLoc).z;

            // if the strength or vector length is smaller than what is currently 
            // in the result variable overwrite it and process next pixel
            if (workLocNegLen < resultLenB)
            {
                resultLocB = workLoc;
                resultLenB = workLocNegLen;
            }
        }
    }

    // fetch colors at different positions
    float4 renderTex = gColorTex.Load(loc);
    float4 offsetTexA = gColorTex.Load(resultLocA);
    float4 offsetTexB = gColorTex.Load(resultLocB);

    // merge offsets (averageOffsetTex is the untinted variant)
    float4 averageOffsetTex = (offsetTexA + offsetTexB) / 2;
    float4 coloredOffsetTex = (offsetTexA * gColorSepA) + (offsetTexB * gColorSepB);

	// merge colors
    float4 resultTex = lerp(averageOffsetTex, coloredOffsetTex, gColorSepMix);

	// fade effect in or out and return
    return lerp(renderTex, resultTex, gDepthEffectMix);
}

////////////////////////////////////////////////////////////////////////////////////////////////////
//    _            _           _
//   | |_ ___  ___| |__  _ __ (_) __ _ _   _  ___  ___
//   | __/ _ \/ __| '_ \| '_ \| |/ _` | | | |/ _ \/ __|
//   | ||  __/ (__| | | | | | | | (_| | |_| |  __/\__ \
//    \__\___|\___|_| |_|_| |_|_|\__, |\__,_|\___||___/
//                                  |_|

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