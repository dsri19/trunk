# file searches the file system and stores the file names in the variable BACKEND_HDR BACKEND_SRC
file(GLOB DEBUGTOOL_SRC "*.cpp")
file(GLOB DEBUGTOOL_HDR "*.h")
SET(GUI_UI "${CMAKE_SOURCE_DIR}/DebugTool/GUI/SceneDialog.ui")

RTT_QT_MOC(MOCS
	MetaDataDlg.h
	UISceneWidget.h
	AttributeAccessDlg.h
)

RTT_QT_UIC(QT_UI
	${GUI_UI}
)

# this creates a VS filter(aka folder) that holds the above file names
SOURCE_GROUP("DebugTool" FILES ${DEBUGTOOL_SRC} ${DEBUGTOOL_HDR})
SOURCE_GROUP("Generated" FILES ${MOCS} ${QT_UI} )
SOURCE_GROUP("GUI" FILES ${GUI_UI})

INCLUDE_DIRECTORIES(${CMAKE_CURRENT_SOURCE_DIR} ${CMAKE_CURRENT_BINARY_DIR})
ADD_DEFINITIONS(-DNOMINMAX -DUNICODE -D_UNICODE -DINES_EXAMPLE2_EXPORTS)

# this creates the vcproj folder structure
# CMAKE_SOURCE_DIR variable that holds the current folder of the first cmakelists.txt file read
RTT_DELTAGEN_PLUGIN(DebugTool
	SOURCES
		${DEBUGTOOL_SRC}
		${MOCS}
		${GUI_UI}
	HEADERS
		${DEBUGTOOL_HDR}
		${QT_UI}
	DESCRIPTION
		${CMAKE_SOURCE_DIR}/DebugTool/DebugTool.xml
	DEPENDS
		qt-core
		qt-gui
		rttSDK
		rttSDKAuth
)
