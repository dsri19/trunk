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
//! \file  UISceneWidget.cpp
//! \brief Implementation of class UISceneWidget.
//!

#include "UISceneWidget.h"
#include "SceneParser.h"
#include "AttributeAccessDlg.h"
#include "MetaDataDlg.h"
#include <QtGui/QHeaderView>

UISceneWidget::UISceneWidget(QWidget *parent, SceneParser* pParser)
:	QDialog(parent)
,	m_pSceneParser(NULL)
,	m_pRootWidget(NULL)
{
	setupUi(this);
	m_pSceneParser = pParser;
	
	treeWidget->header()->setResizeMode(QHeaderView::Fixed);
	
	QStringList headerLabels;

	headerLabels.push_back(QString("Name"));
	headerLabels.push_back(QString("Type"));
	headerLabels.push_back(QString("Id"));
	headerLabels.push_back(QString("Shared Id"));

	treeWidget->setHeaderLabels(headerLabels);

	treeWidget->header()->resizeSection(0,350);
	treeWidget->header()->resizeSection(1,100);
	treeWidget->header()->resizeSection(2,30);
	treeWidget->header()->resizeSection(3,40);
	treeWidget->header()->setResizeMode( QHeaderView::Interactive );

	QObject::connect(refreshButton , SIGNAL(clicked(bool)), this, SLOT(onRefreshClicked()));
	QObject::connect(openAttrAccessDlg , SIGNAL(clicked(bool)), this, SLOT(onAttributeAccessClicked()));
	QObject::connect(metaDataAccess , SIGNAL(clicked(bool)), this, SLOT(onMetaDataAccessClicked()));
}


UISceneWidget::~UISceneWidget()
{
}

QTreeWidget* UISceneWidget::getTreeWidget()
{
	return treeWidget;
}

QTreeWidgetItem* UISceneWidget::createItemFromString(QString qstrItemText)
{
	return new QTreeWidgetItem((QTreeWidget*)0, QStringList(qstrItemText));
}

void UISceneWidget::onRefreshClicked()
{	
	m_pSceneParser->parseScene();
}

void UISceneWidget::onAttributeAccessClicked()
{
	QList<QTreeWidgetItem *> items = treeWidget->selectedItems();
	if ( !items.size() == 1 )
	{
		return;
	}
	RTT::SDK::IUnknownPtr item = items.first()->data(0, Qt::UserRole).value<RTT::SDK::IUnknownPtr>();
	if ( item.isEmpty() )
	{
		return;
	}
	RTT::SDK::IAttributeAccessPtr attrAccess = rtt::commons::dynamic_ptr_cast<RTT::SDK::IAttributeAccess>( item->QueryInterface( RTT::SDK::IID_IAttributeAccess ) );
	if ( !attrAccess.isEmpty() )
	{
		AttributeAccessDlg* dlg = new AttributeAccessDlg( "AttributeAccess " + items.first()->text(0), attrAccess, m_pSceneParser->getObjectFactory() );
		dlg->show();
	}
}

void UISceneWidget::onMetaDataAccessClicked()
{
	QList<QTreeWidgetItem *> items = treeWidget->selectedItems();
	if ( !items.size() == 1 )
	{
		return;
	}
	RTT::SDK::IUnknownPtr item = items.first()->data(0, Qt::UserRole).value<RTT::SDK::IUnknownPtr>();
	if ( item.isEmpty() )
	{
		return;
	}
	RTT::SDK::IInternalMetaDataPtr metaData = rtt::commons::dynamic_ptr_cast<RTT::SDK::IInternalMetaData>( item->QueryInterface( RTT::SDK::IID_IInternalMetaData) );
	if ( !metaData.isEmpty() )
	{
		MetaDataDlg* dlg = new MetaDataDlg( "MetaData " + items.first()->text(0), metaData );
		dlg->show();
	}

}