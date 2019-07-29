#pragma once
///////////////////////////////////////////////////////////////////////////////////
//              _     _                                                       _      
//    ___ _ __ (_) __| | ___ _ ____   _____ _ __ ___  ___     _ __   ___   __| | ___ 
//   / __| '_ \| |/ _` |/ _ \ '__\ \ / / _ \ '__/ __|/ _ \   | '_ \ / _ \ / _` |/ _ \
//   \__ \ |_) | | (_| |  __/ |   \ V /  __/ |  \__ \  __/   | | | | (_) | (_| |  __/
//   |___/ .__/|_|\__,_|\___|_|    \_/ \___|_|  |___/\___|   |_| |_|\___/ \__,_|\___|
//       |_|   
//
//	 \brief Sandbox config node
//	 Contains the attributes and node computation for the sandbox stylization
//
//   Developed by: You!
//
///////////////////////////////////////////////////////////////////////////////////
#include "mnpr_renderer.h"
#include "mnpr_nodes.h"

// stylization attributes
static MObject aZClipNear;
static MObject aZClipFar;
static MObject aSvZFocus;
static MObject aSvOffsetStrength;
static MObject aSvDepthBias;
static MObject aSvColorSepMix;
static MObject aSvDepthEffectMix;



namespace sv {
	void initializeParameters(FXParameters *mFxParams, EngineSettings *mEngSettings) {
		// adds parameters in the config node
		MStatus status;
		// MFn helpers
		MFnEnumAttribute eAttr;
		MFnTypedAttribute tAttr;
		MFnNumericAttribute nAttr;

		// zClip Near
		aZClipNear = nAttr.create("zClipNear", "zClipNear", MFnNumericData::kFloat, mFxParams->zClipNear[0], &status);
		MAKE_INPUT(nAttr);
		nAttr.setMin(0.0);
		nAttr.setSoftMax(100.0);
		ConfigNode::enableAttribute(aZClipNear);

		// zClip Far
		aZClipFar = nAttr.create("zClipFar", "zClipFar", MFnNumericData::kFloat, mFxParams->zClipFar[0], &status);
		MAKE_INPUT(nAttr);
		nAttr.setMin(0.0);
		nAttr.setSoftMax(100.0);
		ConfigNode::enableAttribute(aZClipFar);

		// svZFocus
		aSvZFocus = nAttr.create("svZFocus", "svZFocus", MFnNumericData::kFloat, mFxParams->svZFocus[0], &status);
		MAKE_INPUT(nAttr);
		nAttr.setMin(0.0);
		nAttr.setSoftMax(100.0);
		ConfigNode::enableAttribute(aSvZFocus);

		// svOffsetStrength
		aSvOffsetStrength = nAttr.create("svOffsetStrength", "svOffsetStrength", MFnNumericData::kFloat, mFxParams->svOffsetStrength[0], &status);
		MAKE_INPUT(nAttr);
		nAttr.setMin(0.0);
		nAttr.setSoftMax(30.0);
		ConfigNode::enableAttribute(aSvOffsetStrength);

		// svDepthBias
		aSvDepthBias = nAttr.create("svDepthBias", "svDepthBias", MFnNumericData::kFloat, mFxParams->svDepthBias[0], &status);
		MAKE_INPUT(nAttr);
		nAttr.setMin(0.0);
		nAttr.setSoftMax(1.0);
		ConfigNode::enableAttribute(aSvDepthBias);

		// svColorSepMix
		aSvColorSepMix = nAttr.create("svColorSepMix", "svColorSepMix", MFnNumericData::kFloat, mFxParams->svColorSepMix[0], &status);
		MAKE_INPUT(nAttr);
		nAttr.setMin(0.0);
		nAttr.setSoftMax(1.0);
		ConfigNode::enableAttribute(aSvColorSepMix);

		// svDepthEffectMix
		aSvDepthEffectMix = nAttr.create("svDepthEffectMix", "svDepthEffectMix", MFnNumericData::kFloat, mFxParams->svDepthEffectMix[0], &status);
		MAKE_INPUT(nAttr);
		nAttr.setMin(0.0);
		nAttr.setSoftMax(1.0);
		ConfigNode::enableAttribute(aSvDepthEffectMix);

	}


	void computeParameters(MNPROverride* mmnpr_renderer, MDataBlock data, FXParameters *mFxParams, EngineSettings *mEngSettings) {
		MStatus status;

		// READ PARAMETERS
		mFxParams->zClipNear[0] = data.inputValue(aZClipNear, &status).asFloat();
		mFxParams->zClipFar[0] = data.inputValue(aZClipFar, &status).asFloat();
		mFxParams->svZFocus[0] = data.inputValue(aSvZFocus, &status).asFloat();
		mFxParams->svOffsetStrength[0] = data.inputValue(aSvOffsetStrength, &status).asFloat();
		mFxParams->svDepthBias[0] = data.inputValue(aSvDepthBias, &status).asFloat() / 1000;		// maya only shows 3 fractional digits
		mFxParams->svColorSepMix[0] = data.inputValue(aSvColorSepMix, &status).asFloat();
		mFxParams->svDepthEffectMix[0] = data.inputValue(aSvDepthEffectMix, &status).asFloat();
	}

};