//! \verbatim
//! ##############################################################################
//! # Copyright (c) 2008 RTT AG    
//! # All rights reserved.                    
//! # 
//! # RTT AG, Rosenheimer Str. 145, D-81671 Munich (Germany)                
//! ##############################################################################
//! 
//! created by : Radu Cristea raduc@fortech.ro
//! created on : 6-Jan-2010
//! additional docs : 
//! \endverbatim 
//! 
//! \file  SceneParsingPlugin.h
//! \brief Declaration of class SceneParsingPlugin.
//!

#ifndef RTT_SAMPLE_PLUGIN_H
#define RTT_SAMPLE_PLUGIN_H

// Header dependencies
#include "rttSDK.h"
#include "SceneParser.h"
#include "commons/RefCountable.hpp"


//! \class SceneParsingPlugin
//! \brief Plug-in implementation that monitors, parses the scene hierarchy
//! and displays it in a tree view.
class SceneParsingPlugin : public RTT::SDK::IPlugIn
{
	REFCOUNTABLEIMPL;

public:
	//! Constructor
	explicit SceneParsingPlugin();

	// IUnknown implementation
	virtual RTT::SDK::IUnknownPtr RTTSDKAPICALL QueryInterface(const RTT::SDK::IID&);

	// IPlugIn implementation
	virtual RTT::SDK::HRESULT RTTSDKAPICALL Initialize(const RTT::SDK::IObjectRegistryVectPtr& vectRegistries );
	virtual RTT::SDK::HRESULT RTTSDKAPICALL ResolveDependencies(const RTT::SDK::IObjectRegistryVectPtr& vectRegistries );
	virtual RTT::SDK::HRESULT RTTSDKAPICALL ReleaseDependencies();
	virtual RTT::SDK::HRESULT RTTSDKAPICALL Close(const RTT::SDK::IObjectRegistryVectPtr& vectRegistries);

protected:
	//! Destructor
	virtual ~SceneParsingPlugin();	

private:

	// Not allowed:
	SceneParsingPlugin( SceneParsingPlugin const& );
	SceneParsingPlugin& operator=( const SceneParsingPlugin& );

	//! Plugin members
	RTT::SDK::IObjectRegistryPtr m_pRegistry;

	SceneParserPtr m_pParser;
};


#endif//RTT_SAMPLE_PLUGIN_H
