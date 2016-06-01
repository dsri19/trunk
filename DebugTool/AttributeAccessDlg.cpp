#include "AttributeAccessDlg.h"
#include "MetaDataDlg.h"
#include "rttSDKUtils.h"

#include <QtGui/QVBoxLayout>
#include <QtGui/QStandardItemModel>
#include <QtGui/QPushButton>
#include <QtGui/QHeaderView>

Q_DECLARE_METATYPE(RTT::SDK::IUnknownPtr)

//keep in sync with RTT::SDK::DispVariant::Type enum
QStringList typeNames = QStringList() << 
	"TP_NULL"<<    
	"TP_ULONG"<<   
	"TP_LONG"<<    
	"TP_STRING"<<  
	"TP_TEXTURE"<< 
	"TP_FLOAT"<<   
	"TP_FLOAT2"<<  
	"TP_FLOAT3"<<  
	"TP_FLOAT4"<<  
	"TP_MATF4"<<   
	"TP_BOOL"<<    
	"TP_IUNKNOWN"<<
	"TP_IID"<<     
	"TP_DOUBLE"<<
	"TP_HANDLE"<<
	"TP_ULONG64"<< 
	"TP_LONG64"<<  
	"TP_LONG2"<<   
	"TP_LONG3"<<   
	"TP_ULONG2"<<  
	"TP_ULONG3";


AttributeAccessDlg::AttributeAccessDlg( const QString& title, RTT::SDK::IAttributeAccessPtr attrAccess, RTT::SDK::IObjectFactoryPtr pObjFactory )
: m_attrAccess( attrAccess )
, m_pObjFactory( pObjFactory )
{
	setWindowTitle( title );
	resize( 600, 500);
	using namespace RTT::SDK;
	QVBoxLayout *layout = new QVBoxLayout();
	m_tree = new QTreeWidget();

	m_openAttrAccessDlg = new QPushButton("Attribute Access");
	m_openMetaDataDlg = new QPushButton("Metadata");

	QStringList headerLabels;

	headerLabels.push_back(QString("Name"));
	headerLabels.push_back(QString("Value"));
	headerLabels.push_back(QString("Type"));

	m_tree->setHeaderLabels(headerLabels);

	IObjectEnumerationPtr names = attrAccess->GetAttributeNames();
	if ( names.isEmpty() )
	{
		return;
	}
	for (size_t i=0; i<names->GetItemCount(); ++i)
	{
		RTT::SDK::IStringPtr name = rtt::commons::dynamic_ptr_cast<RTT::SDK::IString>( names->GetItem(i)->QueryInterface( RTT::SDK::IID_IString ) );
		DispVariant valVar = attrAccess->GetAttributeValue(name);
		QStringList columns;
		columns.push_back(RTT_SDK_UTF8(name));
		try
		{
			if ( valVar.m_type == RTT::SDK::DispVariant::TP_IUNKNOWN )
			{
				RTT::SDK::IVariantListPtr list = RTT::SDK::interface_cast<RTT::SDK::IVariantList>(valVar.m_pIUnknown);
				if ( !list.isEmpty() )
				{
					QString text;
					size_t numItems = list->GetItemCount();
					for( size_t n = 0; n<numItems; n++ )
					{
						DispVariant itemVal = list->GetItem( n );
						text += QString("%1;").arg(rttDispTypeConversion(itemVal).toCString());
					}
					columns.push_back( text );
				}
				else
				{
					columns.push_back("Unknown type");
				}
			}
			else
			{
				switch(valVar.m_type)
				{
				case DispVariant::TP_FLOAT2:
					{
						RTT::SDK::FVec2 v2 = rttDispTypeConversion(valVar);
						columns.push_back(QString("[%1,%2]").arg(v2[0]).arg(v2[1]));
					}
				case DispVariant::TP_FLOAT3:
					{
						RTT::SDK::FVec3 v3 = rttDispTypeConversion(valVar);
						columns.push_back(QString("[%1,%2,%3]").arg(v3[0]).arg(v3[1]).arg(v3[2]));
					}
				case DispVariant::TP_FLOAT4:
					{
						RTT::SDK::FVec4 v4 = rttDispTypeConversion(valVar);
						columns.push_back(QString("[%1,%2,%3,%4]").arg(v4[0]).arg(v4[1]).arg(v4[2]).arg(v4[3]));
					}
				default:
					columns.push_back(rttDispTypeConversion(valVar).toCString());
				}
			}
		}
		catch(...)
		{
			columns.push_back("Invalid type");
		}
		columns.push_back( typeNames[valVar.m_type] );

		QTreeWidgetItem* pItem = new QTreeWidgetItem((QTreeWidget*)0, columns);
		QVariant var;
		try
		{
			var.setValue(rttDispTypeConversion(valVar).toIUnknown());
		}
		catch(...)
		{
			var.setValue(IUnknownPtr());
		}
		pItem->setData(0,Qt::UserRole,var);
		RTT::SDK::DispVariant::Type valueType = RTT::SDK::rttDispTypeConversion( valVar ).getType();
		if( valueType == RTT::SDK::DispVariant::TP_FLOAT ||
			valueType == RTT::SDK::DispVariant::TP_DOUBLE ||
			valueType == RTT::SDK::DispVariant::TP_LONG ||
			valueType == RTT::SDK::DispVariant::TP_ULONG ||
			valueType == RTT::SDK::DispVariant::TP_BOOL )
		{
			pItem->setFlags(pItem->flags() | Qt::ItemIsEditable);
		}
		m_tree->addTopLevelItem(pItem);
	}

	m_tree->header()->resizeSection(0,300);
	m_tree->header()->resizeSection(2,60);

	layout->addWidget(m_tree);
	layout->addWidget(m_openAttrAccessDlg);
	layout->addWidget( m_openMetaDataDlg);

	QObject::connect(m_openAttrAccessDlg , SIGNAL(clicked(bool)), this, SLOT(onAttributeAccessClicked()));
	QObject::connect(m_openMetaDataDlg , SIGNAL(clicked(bool)), this, SLOT(onMetaDataAccessClicked()));
	QObject::connect(m_tree , SIGNAL(itemChanged(QTreeWidgetItem*,int)), this, SLOT(onItemEdited(QTreeWidgetItem*,int)));

	setLayout(layout);
}

void AttributeAccessDlg::onAttributeAccessClicked()
{
	QList<QTreeWidgetItem *> items = m_tree->selectedItems();
	if ( !items.size() == 1 )
	{
		return;
	}
	RTT::SDK::IUnknownPtr item = items.first()->data(0, Qt::UserRole).value<RTT::SDK::IUnknownPtr>();
	if ( !item.isEmpty() )
	{
		RTT::SDK::IAttributeAccessPtr attrAccess = rtt::commons::dynamic_ptr_cast<RTT::SDK::IAttributeAccess>( item->QueryInterface( RTT::SDK::IID_IAttributeAccess ) );
		if ( !attrAccess.isEmpty() )
		{
			AttributeAccessDlg* dlg = new AttributeAccessDlg( windowTitle() + " | " + items.first()->text(0), attrAccess, m_pObjFactory );
			dlg->show();
		}
	}
}

void AttributeAccessDlg::onMetaDataAccessClicked()
{
	QList<QTreeWidgetItem *> items = m_tree->selectedItems();
	if ( !items.size() == 1 )
	{
		return;
	}
	RTT::SDK::IUnknownPtr item = items.first()->data(0, Qt::UserRole).value<RTT::SDK::IUnknownPtr>();
	if ( !item.isEmpty() )
	{
		RTT::SDK::IInternalMetaDataPtr metaData = rtt::commons::dynamic_ptr_cast<RTT::SDK::IInternalMetaData>( item->QueryInterface( RTT::SDK::IID_IInternalMetaData) );
		if ( !metaData.isEmpty() )
		{
			MetaDataDlg* dlg = new MetaDataDlg( "MetaData " + items.first()->text(0), metaData );
			dlg->show();
		}
	}
}

void AttributeAccessDlg::onItemEdited( QTreeWidgetItem * item, int column )
{
	if ( column == 1 )
	{
		QString name = item->data(0, Qt::DisplayRole).toString();
		QVariant val = item->data(1, Qt::DisplayRole);
		RTT::SDK::DispVariant value;
		RTT::SDK::IStringPtr attrName = RTT::SDK::Utils::createStringUtf8( m_pObjFactory, name.toUtf8());
		switch(m_attrAccess->GetAttributeValue(attrName).m_type)
		{
		case RTT::SDK::DispVariant::TP_FLOAT:
			value.fromFloat(val.value<float>()); break;
		case RTT::SDK::DispVariant::TP_DOUBLE:
			value.fromDouble(val.value<double>()); break;
		case RTT::SDK::DispVariant::TP_LONG:
			value.fromLong(val.value<int>()); break;
		case RTT::SDK::DispVariant::TP_ULONG:
			value.fromULong(val.value<unsigned>()); break;
		case RTT::SDK::DispVariant::TP_BOOL:
			value.fromBool(val.toBool()); break;
		default:
			value.fromString(RTT::SDK::Utils::createStringUtf8( m_pObjFactory, val.toString().toUtf8()));
			break;
		}
		m_attrAccess->SetAttributeValue( attrName, value );
	}
}