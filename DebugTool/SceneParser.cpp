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
//! \file  SceneParser.cpp
//! \brief Implementation of class SceneParser.
//!

#include <assert.h>
#include "rttSDKUtils.h"
#include <QtGui/QTreeWidgetItem>

#include "SceneParser.h"

//
// Static initialization of dispatch table for IDeltagen.
//
RTT_DISPATCHTABLE_START(SceneParser)
RTT_DISPATCHTABLE_END

SceneParserPtr SceneParser::createInstance( RTT::SDK::IObjectRegistryPtr const& pInterfaceRegistry )
{
	RTT::SDK::IDeltagenPtr pApp = rtt::commons::dynamic_ptr_cast<RTT::SDK::IDeltagen>( pInterfaceRegistry->FindInterface( RTT::SDK::IID_IDeltagen ) );
	RTT::SDK::IObjectFactoryPtr pObjFactory = rtt::commons::dynamic_ptr_cast<RTT::SDK::IObjectFactory>( pInterfaceRegistry->FindInterface( RTT::SDK::IID_IObjectFactory ) );
	RTT::SDK::IDataModelPtr pDataModel = rtt::commons::dynamic_ptr_cast<RTT::SDK::IDataModel>( pInterfaceRegistry->FindInterface( RTT::SDK::IID_IDataModel ) );

	SceneParserPtr p = new SceneParser( pApp, pDataModel, pObjFactory );
	return p;
}

SceneParser::SceneParser( RTT::SDK::IDeltagenPtr const& pApp, RTT::SDK::IDataModelPtr const& pDataModel, RTT::SDK::IObjectFactoryPtr const& pObjFactory )
: m_pApplication( pApp )
, m_pObjectFactory( pObjFactory )
, m_pDataModel( pDataModel )
, m_showFullTree( true )
{
	assert( ( !m_pApplication.isEmpty() ) && ( !m_pDataModel.isEmpty() ) && ( !m_pObjectFactory.isEmpty() ) );
}

SceneParser::~SceneParser()
{
	delete m_pSceneWidget;
}

void SceneParser::init()
{
	SceneParserPtr pThis(this);

	//listen to scene creation and destruction
	m_pDataModel->RegisterForEventNotification( RTT::SDK::EVENT_SCENE_CREATED, pThis );
	m_pDataModel->RegisterForEventNotification( RTT::SDK::EVENT_SCENE_DESTROYED, pThis );

	//trigger GUI creation
	initGUI();
}

void SceneParser::finish()
{
	SceneParserPtr pThis(this);
	m_pDataModel->UnregisterForEventNotification( RTT::SDK::EVENT_SCENE_CREATED, pThis );
	m_pDataModel->UnregisterForEventNotification( RTT::SDK::EVENT_SCENE_DESTROYED, pThis );

	//destroy the GUI
	m_pWidgetDialog->Close();
	m_pSceneWidget->close();
}

void SceneParser::initGUI()
{
	//create UI
	m_pSceneWidget = new UISceneWidget(NULL, this);

	//add the dialog to the application 
	m_pWidgetDialog = m_pApplication->AddDialog( m_pSceneWidget->winId(), RTT::SDK::Utils::createStringUtf8( m_pObjectFactory,  "Sample Scene Parser" ) );
	m_pWidgetDialog->SetSize(700, 600);
	m_pWidgetDialog->Show(false);
}


RTT::SDK::ISceneObjectPtr SceneParser::getModelSceneObject(RTT::SDK::IModelPtr model,
														   RTT::SDK::IScenePtr scene)
{
	RTT::SDK::ID modelInstanceId = model->GetRootObjectInstanceID();
	return scene->GetSceneObjectInstance(modelInstanceId);
}

RTT::SDK::ISceneObjectPtr SceneParser::getTopParent(RTT::SDK::ISceneObjectPtr obj )
{
	RTT::SDK::IObjectEnumerationPtr parents = obj->GetParents();
	if ( parents.isEmpty() || parents->GetItemCount() == 0 )
	{
		return obj;
	}
	return getTopParent( RTT::SDK::interface_cast<RTT::SDK::ISceneObject>( parents->GetItem(0)) );
}

void SceneParser::parseScene()
{
	//clear the UI Tree widget
	m_pSceneWidget->getTreeWidget()->clear();

	//from the data model, retrieve the scenes
	RTT::SDK::IObjectEnumerationPtr pScenes = m_pDataModel->GetScenes();

	size_t nSceneCount = pScenes->GetItemCount();
	for (size_t i=0; i<nSceneCount; ++i)
	{
		//for each scene, retrieve the models
		RTT::SDK::IScenePtr pScene = rtt::commons::dynamic_ptr_cast<RTT::SDK::IScene>( pScenes->GetItem( i )->QueryInterface( RTT::SDK::IID_IScene ) );
		RTT::SDK::IObjectEnumerationPtr pModels = pScene->GetModels();	
	
		//create the UI tree view item and add it
		size_t nID = pScene->GetID();
		QString qstrName = RTT_SDK_UTF8(pScene->GetName());
		QTreeWidgetItem* pSceneTreeItem = addTreeItem(NULL, pScene, qstrName, "Scene", nID);

		// There's a hack in the SDK, that  INT_MAX returns the top level scene
		// settings.
		addTreeItem(pSceneTreeItem, pScene->GetSettings(INT_MAX),
					"Scene settings", "Settings", RTT::SDK::INVALID_ID);

		// Add all cameras and viewers
		RTT::SDK::IObjectEnumerationPtr viewers = m_pApplication->GetAllViewers();
		{
			for(RTT::SDK::ULONG i=0; i<viewers->GetItemCount(); ++i)
			{
				RTT::SDK::IViewerPtr viewer =
					RTT::SDK::interface_cast<RTT::SDK::IViewer>(viewers->GetItem(i));
				if(viewer->GetScene()->GetID()!=pScene->GetID())
					continue;

				RTT::SDK::ISceneObjectPtr camera =
					RTT::SDK::interface_cast<RTT::SDK::ISceneObject>(viewer->GetCamera());
				QString qstrName = RTT_SDK_QSTRING(camera->GetName());

				QTreeWidgetItem* viewerItem =
					addTreeItem(pSceneTreeItem, viewer, qstrName, "Viewer", RTT::SDK::INVALID_ID);
				addTreeItem(viewerItem, camera, qstrName, "Camera", camera->GetInstanceID(), camera->GetSharedID());
			}
		}

		// Add the all models and scene hierarchy
		size_t nModelCount = pModels->GetItemCount();
		for(size_t j=0; j<nModelCount; ++j)
		{
			//for each model, retrieve all scene objects
			RTT::SDK::IModelPtr pModel = rtt::commons::dynamic_ptr_cast<RTT::SDK::IModel>( pModels->GetItem( j )->QueryInterface( RTT::SDK::IID_IModel ) );
			RTT::SDK::IObjectEnumerationPtr pSceneObjects = pModel->GetChildren();

			//create the UI tree view item and add it
			size_t nID = pModel->GetNameSpaceID();
			QString qstrName = RTT_SDK_UTF8(pModel->GetName());
			RTT::SDK::ISceneObjectPtr modelRoot = getModelSceneObject(pModel, pScene);
			QTreeWidgetItem* pSceneObjectTreeItem = addTreeItem(pSceneTreeItem, modelRoot, qstrName, "Model", nID);

			if ( m_showFullTree )
			{
				RTT::SDK::ISceneObjectPtr root = getTopParent( modelRoot );
				QTreeWidgetItem* pSceneObjectTreeItem = addTreeItem(pSceneTreeItem, root, "<Root>", "", 0);
				parseSceneObject(root, pSceneObjectTreeItem);
			}

			addAspects(pSceneObjectTreeItem, modelRoot);

			size_t nSceneObjectCount = pSceneObjects->GetItemCount();
			for(size_t k=0; k<nSceneObjectCount; ++k)
			{
				//each scene object can be either a group that can contain more scene objects, either a simple object
				//parse the scene object accordingly
				RTT::SDK::ISceneObjectPtr pSceneObject = rtt::commons::dynamic_ptr_cast<RTT::SDK::ISceneObject>(pSceneObjects->GetItem( k )->QueryInterface( RTT::SDK::IID_ISceneObject ));
				parseSceneObject(pSceneObject, pSceneObjectTreeItem);
			}
		}
	}	
}

void SceneParser::addAspects(QTreeWidgetItem* pRoot, RTT::SDK::IUnknownPtr pObj)
{
	using namespace RTT::SDK;

	IGroupObjectPtr group = interface_cast<IGroupObject>(pObj);
	if(group.isEmpty())
		return;
	IObjectEnumerationPtr sharedGroups = m_pDataModel->GetSharedGroups(group);
	if(sharedGroups.isEmpty() || sharedGroups->GetItemCount()==0)
		return;

	QTreeWidgetItem* aspectsRoot = addTreeItem(pRoot, IUnknownPtr(), "<aspects>",
											   QString(), INVALID_ID, INVALID_ID);
	for(RTT::SDK::ULONG i=0; i<sharedGroups->GetItemCount(); ++i)
	{
		ISharedGroupPtr sharedGroup = interface_cast<ISharedGroup>(sharedGroups->GetItem(i));
		if(sharedGroup.isEmpty())
			continue;
		IObjectEnumerationPtr aspects = sharedGroup->GetAspectObjects();
		if(aspects.isEmpty())
			continue;
		for(RTT::SDK::ULONG j=0;j<aspects->GetItemCount(); ++j)
		{
			IAspectObjectPtr aspect = interface_cast<IAspectObject>(aspects->GetItem(j));
			QString aspectName = RTT_SDK_UTF8(aspect->GetName());
			QString aspectType = RTT_SDK_UTF8(aspect->GetType());
			addTreeItem(aspectsRoot, aspect, aspectName, aspectType, INVALID_ID, INVALID_ID);
		}
	}
}

void SceneParser::parseSceneObject(RTT::SDK::ISceneObjectPtr pObj, QTreeWidgetItem* pParentItem)
{
	//check to see if it's a group objects
	RTT::SDK::IGroupObjectPtr pGroupObject = rtt::commons::dynamic_ptr_cast<RTT::SDK::IGroupObject>( pObj->QueryInterface(RTT::SDK::IID_IGroupObject) );

	//create the treeWidget item with the appropriate text
	QString itemType("SceneObject");
	if(!pGroupObject.isEmpty())
	{
		itemType = "GroupObject";
	}
	RTT::SDK::ID instanceID = pObj->GetInstanceID();
	RTT::SDK::ID sharedID = pObj->GetSharedID();
	QString qstrName = RTT_SDK_UTF8( pObj->GetName() );
	QTreeWidgetItem* pSceneObjectTreeItem = addTreeItem(pParentItem, pObj, qstrName, itemType, instanceID, sharedID);
	addAspects(pSceneObjectTreeItem, pObj);
	if(!pGroupObject.isEmpty())
	{		
		//scene object is a group object, parse it's children
		RTT::SDK::IObjectEnumerationPtr pChildren = pGroupObject->GetChildren();
		size_t nChildCount = pGroupObject->GetChildCount();
		for(size_t i=0; i<nChildCount; ++i)
		{
			//recursively parse the sceneObject's children
			RTT::SDK::ISceneObjectPtr pSceneObject = rtt::commons::dynamic_ptr_cast<RTT::SDK::ISceneObject>( pChildren->GetItem( i )->QueryInterface( RTT::SDK::IID_ISceneObject ) );
			parseSceneObject(pSceneObject, pSceneObjectTreeItem);
		}
	}
}

QTreeWidgetItem* SceneParser::addTreeItem(QTreeWidgetItem* pRoot, RTT::SDK::IUnknownPtr pObj, QString qstrName, QString qstrType, RTT::SDK::ID instanceId, RTT::SDK::ID sharedId )
{
	QString qstrInstanceID = QString::number(instanceId);
	QString qstrSharedID = QString::number(sharedId);
	if ( sharedId < 0 )
	{
		qstrSharedID = "";
	}


	QStringList columns;
	columns.push_back(qstrName);
	columns.push_back(qstrType);
	columns.push_back(qstrInstanceID);
	columns.push_back(qstrSharedID);

	QTreeWidgetItem* pItem = new QTreeWidgetItem((QTreeWidget*)0, columns);
	QVariant var;
	var.setValue(pObj);
	pItem->setData(0,Qt::UserRole,var);
	pItem->setExpanded(true);

	if(pRoot == NULL)
	{
		//no root, add to top
		m_pSceneWidget->getTreeWidget()->addTopLevelItem(pItem);
	}
	else
	{
		pRoot->addChild(pItem);
	}

	return pItem;
}

void SceneParser::OnEvent( RTT::GUID eventType,const RTT::SDK::IPropertyMapPtr& pData )
{
	//trigger parsing then scene is created/destroyed
	parseScene();
}

RTT::SDK::IObjectFactoryPtr SceneParser::getObjectFactory() const
{
	return m_pObjectFactory;
}
