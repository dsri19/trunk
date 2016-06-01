#ifndef METADATA_DLG_H
#define METADATA_DLG_H

#include "rttSDK.h"
#include "rttSDKIInternalMetaData.hpp"

#include <QtGui/QDialog>
#include <QtGui/QTreeWidget>

class MetaDataDlg : public QDialog
{
	Q_OBJECT

public:
	MetaDataDlg( const QString& title, RTT::SDK::IInternalMetaDataPtr metaData );

private:
	RTT::SDK::IInternalMetaDataPtr m_metaData;
	QTreeWidget* m_tree;
};

#endif // METADATA_DLG_H