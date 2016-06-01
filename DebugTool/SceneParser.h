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
//! \file  SceneParser.h
//! \brief Declaration of class SceneParser.
//!

#ifndef RTTSAMPLE_SCENEPARSER_H
#define RTTSAMPLE_SCENEPARSER_H

// Library dependencies
// Header dependencies
#include "rttSDK.h"
#include "UISceneWidget.h"
#include "rttSDKDispatchableInterfaceImpl.h"

class SceneParser;
typedef rtt::commons::IntrusivePtr<SceneParser> SceneParserPtr;

Q_DECLARE_METATYPE(RTT::SDK::IUnknownPtr)


//! \brief This class controls event handling from plug-in to Deltagen and vice versa. 
//! To handle events from Deltagen rttSDK::IEventSink interface is implemented.
//! To handle events from GUI components QObject interface is implemented with Qt slots;
//! This object acts as a controler conforming with the MVC pattern. rttPBMetaDataView and rttMetaDataModel are completing this concept.
class SceneParser : public RTT::SDK::DispatchableInterfaceImpl<RTT::SDK::IEventSink, &RTT::SDK::IIDs::IID_IEventSink>
{
public:
	//! \brief Factory method.
	static SceneParserPtr createInstance( RTT::SDK::IObjectRegistryPtr const& pInterfaceRegistry );

	//! \brief Inits event handling.
	//! This has to be called after object was created/requested.
	//! Accordingly before destruction/release finish() 
	//!  has to be called to release all relevant references to this object.
	void init();

	//! \brief Finishes event handling.
	//! Disconnects this object from all Deltagen events. 
	//! More important it releases all relevant references to this object.
	//! Call this before release of this object.
	void finish();

	//! \brief IEventSink implementation
	//! \todo parameter description
	virtual void OnEvent( RTT::GUID eventType,const RTT::SDK::IPropertyMapPtr& pData );

	//! \brief Parses the datamodel's hierarchy.
	void parseScene();

	RTT::SDK::IObjectFactoryPtr getObjectFactory() const;

private:
	// Not allowed:
	SceneParser( SceneParser const& );
	SceneParser& operator=( const SceneParser& );

	//! \brief Create event handler.
	//! \param	pApp				interface pointer to use Deltagen functionality.
	//! \param	pDataModel			interface pointer to use DataModel functionality.
	//! \param	pObjFactory		interface pointer to use the object factory.
	SceneParser( RTT::SDK::IDeltagenPtr const& pApp, RTT::SDK::IDataModelPtr const& pDataModel, RTT::SDK::IObjectFactoryPtr const& pObjFactory );

	//! \brief Adds and shows the dialog to the application.
	void initGUI();

	//! Destroy event handler
	virtual ~SceneParser();

private:
	//! Pointer to Deltagen interface
	RTT::SDK::IDeltagenPtr m_pApplication;

	//! Pointer to DataModel interface
	RTT::SDK::IDataModelPtr m_pDataModel;

	//! Pointer to utility interface
	RTT::SDK::IObjectFactoryPtr m_pObjectFactory;

	UISceneWidget* m_pSceneWidget;

	RTT::SDK::IDialogPtr m_pWidgetDialog;

	bool m_showFullTree;

	//! \brief Parses recursively a SceneObject and adds info to the TreeWidget.
	//! 
	//! \param	pObj				pointer to the object
	//! \param	pParentItem			pointer to the parent GUI treeWidget item
	void parseSceneObject(RTT::SDK::ISceneObjectPtr pObj, QTreeWidgetItem* pParentItem);

	//! \brief Helper function for adding items to the tree widget.
	//! \param pRoot parent item.
	//! \param qstrName name of the new item.
	//! \param qstrType type of the new item.
	//! \param nID ID of the new item.
	//! \return the added tree item.
	QTreeWidgetItem* addTreeItem(QTreeWidgetItem* pRoot, RTT::SDK::IUnknownPtr pObj, QString qstrName, QString qstrType, RTT::SDK::ID instanceId, RTT::SDK::ID sharedId = -1);

	//! Add all aspects for given object
	void addAspects(QTreeWidgetItem* pRoot, RTT::SDK::IUnknownPtr pObj);

	//! Get the scene object for the model root
	RTT::SDK::ISceneObjectPtr getModelSceneObject(RTT::SDK::IModelPtr model,
												  RTT::SDK::IScenePtr scene);
	//! Get the first top level parent
	RTT::SDK::ISceneObjectPtr getTopParent(RTT::SDK::ISceneObjectPtr obj );
};

#endif//RTTSAMPLE_SCENEPARSER_H
