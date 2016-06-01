#include "MetaDataDlg.h"
#include "AttributeAccessDlg.h"

#include <QtGui/QVBoxLayout>
#include <QtGui/QStandardItemModel>
#include <QtGui/QPushButton>

Q_DECLARE_METATYPE(RTT::SDK::IUnknownPtr)

MetaDataDlg::MetaDataDlg( const QString& title, RTT::SDK::IInternalMetaDataPtr metaData )
: m_metaData( metaData )
{
	setWindowTitle( title );
	using namespace RTT::SDK;
	QVBoxLayout *layout = new QVBoxLayout();
	m_tree = new QTreeWidget();

	QStringList headerLabels;

	headerLabels.push_back(QString("Name"));
	headerLabels.push_back(QString("Value"));

	m_tree->setHeaderLabels(headerLabels);

	IObjectEnumerationPtr names = metaData->GetBlockNames();
	for (size_t i=0; i<names->GetItemCount(); ++i)
	{
		RTT::SDK::IStringPtr blockname = rtt::commons::dynamic_ptr_cast<RTT::SDK::IString>( names->GetItem(i)->QueryInterface( RTT::SDK::IID_IString ) );
		QStringList columns;
		columns.push_back(RTT_SDK_UTF8(blockname));
		QTreeWidgetItem* pParent = new QTreeWidgetItem((QTreeWidget*)0, columns);

		IObjectEnumerationPtr keynames = metaData->GetKeyNames(blockname);
		for (size_t i=0; i<keynames->GetItemCount(); ++i)
		{
			RTT::SDK::IStringPtr keyname = rtt::commons::dynamic_ptr_cast<RTT::SDK::IString>( keynames->GetItem(i)->QueryInterface( RTT::SDK::IID_IString ) );
			
			QStringList columns;
			columns.push_back(RTT_SDK_UTF8(keyname));
			columns.push_back(RTT_SDK_UTF8(metaData->GetValue(blockname,keyname)));

			QTreeWidgetItem* pItem = new QTreeWidgetItem((QTreeWidget*)0, columns);

			pParent->addChild(pItem);
		}
		m_tree->addTopLevelItem(pParent);
	}

	layout->addWidget(m_tree);

	setLayout(layout);
}

