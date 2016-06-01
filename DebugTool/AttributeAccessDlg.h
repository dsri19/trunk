#ifndef ATTRIBUTE_ACCESS_DLG_H
#define ATTRIBUTE_ACCESS_DLG_H

#include "rttSDK.h"

#include <QtGui/QDialog>
#include <QtGui/QTreeWidget>

class AttributeAccessDlg : public QDialog
{
	Q_OBJECT

public:
	AttributeAccessDlg( const QString& title, RTT::SDK::IAttributeAccessPtr attrAccess, RTT::SDK::IObjectFactoryPtr pObjFactory );

public slots:
	void onAttributeAccessClicked();
	void onMetaDataAccessClicked();
	void onItemEdited(QTreeWidgetItem * item, int column);

private:
	RTT::SDK::IAttributeAccessPtr m_attrAccess;
	QTreeWidget* m_tree;
	QPushButton *m_openAttrAccessDlg;
	QPushButton *m_openMetaDataDlg;
	RTT::SDK::IObjectFactoryPtr m_pObjFactory;
};

#endif // ATTRIBUTE_ACCESS_DLG_H