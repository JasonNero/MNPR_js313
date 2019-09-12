#pragma once
///////////////////////////////////////////////////////////////////////////////////
//              _     _                                   
//    ___ _ __ (_) __| | ___ _ ____   _____ _ __ ___  ___ 
//   / __| '_ \| |/ _` |/ _ \ '__\ \ / / _ \ '__/ __|/ _ \
//   \__ \ |_) | | (_| |  __/ |   \ V /  __/ |  \__ \  __/
//   |___/ .__/|_|\__,_|\___|_|    \_/ \___|_|  |___/\___|
//       |_|   
//
//	 \brief Sandbox stylization pipeline
//	 Contains the sandbox stylization pipeline with all necessary targets and operations
//	 Use this style to develop whatever stylization you'd like
//
//   Developed by: You!
//
///////////////////////////////////////////////////////////////////////////////////
#include "mnpr_renderer.h"

namespace sv {

	void addTargets(MRenderTargetList& targetList) {
		// add style specific targets

		unsigned int tWidth = targetList[0]->width();
		unsigned int tHeight = targetList[0]->height();
		int MSAA = targetList[0]->multiSampleCount();
		unsigned arraySliceCount = 0;
		bool isCubeMap = false;
		MHWRender::MRasterFormat rgba8 = MHWRender::kR8G8B8A8_SNORM;
		MHWRender::MRasterFormat rgb8 = MHWRender::kR8G8B8X8;
		MHWRender::MRasterFormat rg16f = MHWRender::kR16G16_FLOAT;
		MHWRender::MRasterFormat rgba16f = MHWRender::kR16G16B16A16_FLOAT;

		//targetList.append(MHWRender::MRenderTargetDescription("stylizationTarget", tWidth, tHeight, 1, rgba8, arraySliceCount, isCubeMap));
		targetList.append(MHWRender::MRenderTargetDescription("offsetTarget", tWidth, tHeight, 1, rgba16f, arraySliceCount, isCubeMap));
	}


	void addOperations(MHWRender::MRenderOperationList& mRenderOperations, MRenderTargetList& mRenderTargets,
		EngineSettings& mEngSettings, FXParameters& mFxParams) {
		MString opName = "";

		// Circle of Diffusion
		opName = "[quad] CoC";
		auto opShader = new MOperationShader("sv", "quadSpiderDepth", "spiderCoc");
		opShader->addTargetParameter("gColorTex", mRenderTargets.target(mRenderTargets.indexOf("stylizationTarget")));		// not used
		opShader->addTargetParameter("gDepthTex", mRenderTargets.target(mRenderTargets.indexOf("linearDepth")));
		opShader->addTargetParameter("gZBuffer", mRenderTargets.target(mRenderTargets.indexOf("depthTarget")));
		opShader->addParameter("gClipNear", mFxParams.zClipNear);	// not used
		opShader->addParameter("gClipFar", mFxParams.zClipFar);		// not used
		opShader->addParameter("gZFocus", mFxParams.svZFocus);
		opShader->addParameter("gOffsetStrength", mFxParams.svOffsetStrength);
		opShader->addParameter("gDepthBias", mFxParams.svDepthBias);
		auto quadOp = new QuadRender(opName,
			MHWRender::MClearOperation::kClearNone,
			mRenderTargets,
			*opShader);
		mRenderOperations.append(quadOp);
		mRenderTargets.setOperationOutputs(opName, { "offsetTarget" });

		opName = "[quad] offset DoF";
		opShader = new MOperationShader("sv", "quadSpiderDepth", "spiderDepth");
		opShader->addTargetParameter("gColorTex", mRenderTargets.target(mRenderTargets.indexOf("stylizationTarget")));
		opShader->addTargetParameter("gOffsetTex", mRenderTargets.target(mRenderTargets.indexOf("offsetTarget")));
		opShader->addTargetParameter("gDepthTex", mRenderTargets.target(mRenderTargets.indexOf("linearDepth")));
		opShader->addTargetParameter("gZBuffer", mRenderTargets.target(mRenderTargets.indexOf("depthTarget")));
		opShader->addParameter("gOffsetStrength", mFxParams.svOffsetStrength);
		opShader->addParameter("gColorSepA", mFxParams.svColorSepA);
		opShader->addParameter("gColorSepB", mFxParams.svColorSepB);
		opShader->addParameter("gColorSepMix", mFxParams.svColorSepMix);
		opShader->addParameter("gDepthEffectMix", mFxParams.svDepthEffectMix);
		quadOp = new QuadRender(opName,
			MHWRender::MClearOperation::kClearNone,
			mRenderTargets,
			*opShader);
		mRenderOperations.append(quadOp);
		mRenderTargets.setOperationOutputs(opName, { "stylizationTarget" });
		
		opName = "[quad] spiderverse test";
		opShader = new MOperationShader("sv", "quadTest", "testTechnique");
		opShader->addSamplerState("gSampler", MHWRender::MSamplerState::kTexClamp, MHWRender::MSamplerState::kMinMagMipPoint);
		opShader->addTargetParameter("gColorTex", mRenderTargets.target(mRenderTargets.indexOf("stylizationTarget")));
		quadOp = new QuadRender(opName,
			MHWRender::MClearOperation::kClearNone,
			mRenderTargets,
			*opShader);
		mRenderOperations.append(quadOp);
		mRenderTargets.setOperationOutputs(opName, { "stylizationTarget" });

	}
};
