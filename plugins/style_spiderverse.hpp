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

	void addTargets(MRenderTargetList &targetList) {
		// add style specific targets

		unsigned int tWidth = targetList[0]->width();
		unsigned int tHeight = targetList[0]->height();
		int MSAA = targetList[0]->multiSampleCount();
		unsigned arraySliceCount = 0;
		bool isCubeMap = false;
		MHWRender::MRasterFormat rgba8 = MHWRender::kR8G8B8A8_SNORM;
		MHWRender::MRasterFormat rgb8 = MHWRender::kR8G8B8X8;

		targetList.append(MHWRender::MRenderTargetDescription("offsetTarget", tWidth, tHeight, 1, rgba8, arraySliceCount, isCubeMap));
	}


	void addOperations(MHWRender::MRenderOperationList &mRenderOperations, MRenderTargetList &mRenderTargets,
		EngineSettings &mEngSettings, FXParameters &mFxParams) {
		MString opName = "";

		opName = "[quad] offset DoF";
		auto opShader = new MOperationShader("sv", "quadDoF", "offsetDoF");
		opShader->addTargetParameter("gColorTex", mRenderTargets.target(mRenderTargets.indexOf("stylizationTarget")));
		opShader->addTargetParameter("gDepthTex", mRenderTargets.target(mRenderTargets.indexOf("linearDepth")));
		opShader->addTargetParameter("gZBuffer", mRenderTargets.target(mRenderTargets.indexOf("depthTarget")));
		opShader->addTargetParameter("gControlTex", mRenderTargets.target(mRenderTargets.indexOf("abstractCtrlTarget")));  // testFx control in red channel
		opShader->addParameter("gClipNear", mFxParams.zClipNear);
		opShader->addParameter("gClipFar", mFxParams.zClipFar);
		auto quadOp = new QuadRender(opName,
			MHWRender::MClearOperation::kClearNone,
			mRenderTargets,
			*opShader);
		mRenderOperations.append(quadOp);
		mRenderTargets.setOperationOutputs(opName, { "stylizationTarget" });
	}
};
