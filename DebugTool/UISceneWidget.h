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
//! \file  UISceneWidget.h
//! \brief Declaration of class UISceneWidget.
//!

#ifndef UISCENEWIDGET_H
#define UISCENEWIDGET_H

#include "SceneDialog.uic.hpp"

class SceneParser;

//! \brief \todo comment class description.
class UISceneWidget : public QDialog, public Ui_LogDialog
{
	Q_OBJECT

public:

	//! \brief Constructor.
	//! \param parent parent dialog.
	//! \param pParser scene parser.
	//! \todo review parameter descriptions.
	UISceneWidget(QWidget *parent, SceneParser* pParser);

	//! \brief Destructor.
	~UISceneWidget();

	//! \brief Returns the tree widget.
	//! \return the tree widget.
	QTreeWidget* getTreeWidget();

	//! \brief Creates a tree item from specified text.
	//! \param qstrItemText text of the new tree item.
	//! \return the new tree item.
	QTreeWidgetItem* createItemFromString(QString qstrItemText);

private slots:
	//! \brief User has clicked the refresh button.
	void onRefreshClicked();

	void onAttributeAccessClicked();

	void onMetaDataAccessClicked();
private:

	SceneParser* m_pSceneParser;
	QTreeWidgetItem* m_pRootWidget;
	
};

#endif // UISCENEWIDGET_H
