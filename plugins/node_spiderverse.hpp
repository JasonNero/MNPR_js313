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
static MObject anotherAwesomeParameter;


namespace sv {
	void initializeParameters(FXParameters *mFxParams, EngineSettings *mEngSettings) {
		// adds parameters in the config node
		MStatus status;
		// MFn helpers
		MFnEnumAttribute eAttr;
		MFnTypedAttribute tAttr;
		MFnNumericAttribute nAttr;

		// color bleeding threshold
		aAwesomeParameter = nAttr.create("awesomeParameter", "awesomeParameter", MFnNumericData::kFloat, mFxParams->awesomeParameter[0], &status);
		MAKE_INPUT(nAttr);
		nAttr.setMin(-5.0);
		nAttr.setSoftMax(5.0);
		nAttr.setMax(10.0);
		ConfigNode::enableAttribute(anotherAwesomeParameter);

	}


	void computeParameters(MNPROverride* mmnpr_renderer, MDataBlock data, FXParameters *mFxParams, EngineSettings *mEngSettings) {
		MStatus status;

		// READ PARAMETERS
		mFxParams->awesomeParameter[0] = data.inputValue(anotherAwesomeParameter, &status).asFloat();
	}

};