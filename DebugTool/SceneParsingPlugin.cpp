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
//! \file  SceneParsingPlugin.cpp
//! \brief Implementation of class SceneParsingPlugin.
//!

// Project dependencies
#include "SceneParsingPlugin.h"
#include "SceneParser.h"
#include "rttSDKPlugInSkel.h"

namespace RTT
{
	namespace SDK
	{
		namespace PlugInSkel
		{
			//! The function that creates the module 
			//! must be implemented in user defined class file
			void intCreateInstance( const RTT::SDK::CLSID& clsid, RTT::SDK::IPlugInPtr& pPlugIn )
			{					
				pPlugIn = new SceneParsingPlugin();
			
			}
		}
	}
}

SceneParsingPlugin::SceneParsingPlugin()
:m_pRegistry( NULL )
{
	REFCOUNTABLEINIT;
}

SceneParsingPlugin::~SceneParsingPlugin()
{
	RTT::SDK::PlugInSkel::release();
}


// IUnknown implementation
RTT::SDK::IUnknownPtr RTTSDKAPICALL SceneParsingPlugin::QueryInterface(const RTT::SDK::IID& iid)
{
	if ( iid == RTT::SDK::IID_IUnknown       || 
		iid == RTT::SDK::IID_IPlugIn )
	{
		RTT::SDK::IPlugIn* pRes = static_cast<RTT::SDK::IPlugIn*>( this );
		return pRes;
	} 
	return RTT::SDK::IUnknownPtr();
}

// IPlugIn implementation
RTT::SDK::HRESULT RTTSDKAPICALL SceneParsingPlugin::Initialize(const RTT::SDK::IObjectRegistryVectPtr& vectRegistries )
{
	return RTT::SDK::S_OK;
}

RTT::SDK::HRESULT RTTSDKAPICALL SceneParsingPlugin::ResolveDependencies(const RTT::SDK::IObjectRegistryVectPtr& vectRegistries )
{
	m_pRegistry = vectRegistries->Get( RTT::SDK::TypeID_SDKObjectRegistry );

	//call factory method and receive a parser object
	m_pParser = SceneParser::createInstance( m_pRegistry );

	//do the event registration and init the GUI
	m_pParser->init();

	return RTT::SDK::S_OK;
}

RTT::SDK::HRESULT RTTSDKAPICALL SceneParsingPlugin::ReleaseDependencies()
{
	//unregister for events and destroy the GUI
	m_pParser->finish();

	return RTT::SDK::S_OK;
}

RTT::SDK::HRESULT RTTSDKAPICALL SceneParsingPlugin::Close(const RTT::SDK::IObjectRegistryVectPtr& vectRegistries )
{
	return RTT::SDK::S_OK;
}
