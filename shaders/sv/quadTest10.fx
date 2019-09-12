////////////////////////////////////////////////////////////////////////////////////////////////////
// quadTest.fx (HLSL)
// Brief: Just a playground for testing
// Contributors: Jason Schuehlein
////////////////////////////////////////////////////////////////////////////////////////////////////
//    _____         _   
//   |_   _|__  ___| |_ 
//     | |/ _ \/ __| __|
//     | |  __/\__ \ |_ 
//     |_|\___||___/\__|
//                      
////////////////////////////////////////////////////////////////////////////////////////////////////
#include "..\\include\\quadCommon.fxh"

// TEXTURES
Texture2D gDepthTex;
Texture2D gZBuffer;

/////////////////////////////////////////////////////////////////////////////
////////////////// HLSL EXAMPLE FOR BACHELOR THESIS /////////////////////////
/////////////////////////////////////////////////////////////////////////////

//// Application (app) output structure
//struct appOutput
//{
//	float4 pos : POSITION;
//};
//
//// Vertex shader (vs) output structure
//struct vsOutput
//{
//	float4 pos : SV_Position;
//	float depth : TEXCOORD0;
//};
//
//// Pixel shader (ps) output structure
//struct psOutput
//{
//	float4 color : SV_Target;
//};
//
//// Vertex shader
//vsOutput testVS(appOutput input)
//{
//	vsOutput output;
//	// Transform the position from world space to clip space for output.
//	output.pos = mul(input.pos, gWVP);
//	// Normalize depth
//	output.depth = (output.pos.z / output.pos.w) / 1000000.0;
//	return output;
//}
//
//// Pixel shader
//psOutput testPS(vsOutput input)
//{
//	psOutput output;
//	// Return depth as color with an Alpha of 1.0
//	output.color = float4(input.depth, input.depth, input.depth, 1.0);
//	return output;
//}
//
//technique11 testTechnique {
//	pass p0 {
//		SetVertexShader(CompileShader(vs_5_0, testVS()));
//		SetGeometryShader(NULL);
//		SetPixelShader(CompileShader(ps_5_0, testPS()));
//	}
//}

/////////////////////////////////////////////////////////////////////////////
///////////////// SHAPING FUNCTIONS - BACHELOR THESIS ///////////////////////
/////////////////////////////////////////////////////////////////////////////

// Application (app) output structure
struct appOutput {
	float4 pos : POSITION;
	float2 texcoord : TEXCOORD0;
};

// Vertex shader (vs) output structure
struct vsOutput {
	float4 pos : SV_Position;
	float2 st : TEXCOORD0;
};

// Pixel shader (ps) output structure
struct psOutput {
	float4 color : SV_Target;
};

// Vertex shader
vsOutput testVS(appOutput input) {
	vsOutput output;
	output.pos = mul(input.pos, gWVP);
	output.st = input.texcoord;
	return output;
}

// Pixel shader
psOutput testPS(vsOutput input) {
	psOutput output;

	float width = 0.2;
	float softness = 0.05;

	float dist = abs(input.st.x - 0.5);

	float outter = width + (width * softness);
	float inner = width - (width * softness);
	float color = smoothstep(outter, inner, dist);

	output.color = float4(color, color, color, 1.0);

	return output;
}

technique11 testTechnique {
	pass p0 {
		SetVertexShader(CompileShader(vs_5_0, testVS()));
		SetGeometryShader(NULL);
		SetPixelShader(CompileShader(ps_5_0, testPS()));
	}
}

