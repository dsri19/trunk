# This is the cmake cross platform make file for the
# RTT software.
# Testing
# making some changes for testing
# To use it, please create a build directory in the dir
# this file your are now reading lives:

#changing the file in trunk and merging in the fork and down stream branches

modigying in downstream branches






#
#  $ mkdir build
#  $ cd build
#  $ cmake ../
#  $ make
# We want to have 2.8 available

making some more changes for testing

CMAKE_MINIMUM_REQUIRED (VERSION 2.8)
CMAKE_POLICY (VERSION 2.8)

PROJECT (DebugTool)

set(CMAKE_PROJECT_ROOT ${CMAKE_SOURCE_DIR})

IF (MSVC) 
	#Use solution folders.
	set_property(GLOBAL PROPERTY USE_FOLDERS ON) 
ENDIF()

###################################################################################################
# CMake settings
###################################################################################################


# Bad variable reference syntax is an error
CMAKE_POLICY (SET CMP0010 NEW)

# Preprocessor definition values are now escaped automatically.
CMAKE_POLICY (SET CMP0005 NEW)

# make sure we are writing into a build dircetory
IF (NOT ${CMAKE_CURRENT_BINARY_DIR} MATCHES .*build)
	MESSAGE (FATAL_ERROR "Not a 'build' directory ! Please run 'cmake ..' inside the top build directory. Halting.")
ENDIF (NOT ${CMAKE_CURRENT_BINARY_DIR} MATCHES .*build)

# Setup some common paths
file(TO_CMAKE_PATH "$ENV{RTT_SDK_ROOT}" SDK_ROOT_PATH)
IF (NOT SDK_ROOT_PATH)
	SET(ENV{RTT_SDK_ROOT} ${PROJECT_SOURCE_DIR}/../RTTSDK)
ENDIF()

###################################################################################################
# Configure
###################################################################################################

# include our own cmake utilities
SET(CMAKE_MODULE_PATH "${CMAKE_PROJECT_ROOT}/cmake")
#SET(ARTIFACTORY_DIR_OVERRIDE "${CMAKE_PROJECT_ROOT}/external")
SET(ARTIFACTORY_REPOSITORY "https://art01.rtt.local/artifactory")

# some global configuration
IF (MSVC) 
	SET(DISABLE_ARTIFACTORY_SERVER OFF)
	ADD_DEFINITIONS(-DWIN32_LEAN_AND_MEAN)
	ADD_DEFINITIONS(-D_WIN32_WINNT=0x502)
	ADD_DEFINITIONS( -D_SCL_SECURE_NO_DEPRECATE )
	ADD_DEFINITIONS( -D_WIN32 )
	
	IF (MSVC90)
		# for some reason projects fail to build using VC90 and IncrediBuild when using
		# the default command line settings provided by CMake
		#
		# http://www.ogre3d.org/forums/viewtopic.php?f=2&t=60015
		#
		UNSET(CMAKE_CXX_FLAGS)
		SET(CMAKE_CXX_FLAGS "/DWIN32 /D_WINDOWS /W3 /Zm500 /GX /GR ")
	ENDIF()
ELSE ()
	SET(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -fPIC")
ENDIF ()

# are we 64 bitty?
IF(${CMAKE_SIZEOF_VOID_P} EQUAL 4)
	SET( HAVE_64_BIT FALSE CACHE BOOL "32 bit system" )
ELSE()
	SET( HAVE_64_BIT TRUE CACHE BOOL "64 bit system" )
ENDIF()
MARK_AS_ADVANCED(HAVE_64_BIT)

# What's our Name?
IF(MSVC)
	IF(MSVC80)
		SET(MSVC_COMPILER_NAME "vc80" CACHE STRING "MSVC compiler name")
		SET(RTT_COMPILER_NAME "vc80" CACHE INTERNAL "RTT compiler name")
	ENDIF()
	IF(MSVC90)
		SET(MSVC_COMPILER_NAME "vc90" CACHE STRING "MSVC compiler name")
		SET(RTT_COMPILER_NAME "vc90" CACHE INTERNAL "RTT compiler name")
	ENDIF()
	IF(MSVC11)
		SET(MSVC_COMPILER_NAME "vc110" CACHE STRING "MSVC compiler name")
		SET(RTT_COMPILER_NAME "vc110" CACHE INTERNAL "RTT compiler name")
	ENDIF()
	IF(NOT MSVC_COMPILER_NAME)
		MESSAGE(FATAL " TOOLSET NOT SUPPORTED! Please use either vc80, vc90 or vc110")
	ENDIF()
	IF (HAVE_64_BIT)
		SET(RTT_PLATFORM_NAME "win64" CACHE INTERNAL "RTT platform name")
		SET(MSVC_PLATFORM_NAME "x64")
	ELSE()
		SET(MSVC_PLATFORM_NAME "Win32")
	ENDIF()
ELSE()
	SET(LINUX_COMPILER_NAME "gcc4" CACHE STRING "Linux Compiler name")
	SET(RTT_COMPILER_NAME "gcc4" CACHE INTERNAL "RTT compiler name")
	IF (HAVE_64_BIT)
		SET(LINUX_PLATFORM_NAME "linux64")
	ELSE()
		SET(LINUX_PLATFORM_NAME "linux32")
	ENDIF()
ENDIF(MSVC)

MARK_AS_ADVANCED(MSVC_COMPILER_NAME)
MARK_AS_ADVANCED(MSVC_PLATFORM_NAME)
MARK_AS_ADVANCED(LINUX_COMPILER_NAME)
MARK_AS_ADVANCED(LINUX_PLATFORM_NAME)

# On Windows we want to build to bin/x64/Release ...
# On linux we want to have all the binaries in one place
IF (MSVC)
	IF (CMAKE_CL_64)
		SET (LIBRARY_OUTPUT_PATH ${${CMAKE_PROJECT_NAME}_BINARY_DIR}/bin/x64 CACHE PATH "Library target dir (x64).")
		SET (EXECUTABLE_OUTPUT_PATH ${${CMAKE_PROJECT_NAME}_BINARY_DIR}/bin/x64 CACHE PATH "Executable target dir (x64).")
	ELSE ()
		SET (LIBRARY_OUTPUT_PATH ${${CMAKE_PROJECT_NAME}_BINARY_DIR}/bin/Win32 CACHE PATH "Library target dir (win32).")
		SET (EXECUTABLE_OUTPUT_PATH ${${CMAKE_PROJECT_NAME}_BINARY_DIR}/bin/Win32 CACHE PATH "Executable target dir (win32).")
	ENDIF ()
ELSE ()
	SET (EXECUTABLE_OUTPUT_PATH ${${CMAKE_PROJECT_NAME}_BINARY_DIR}/bin/linux64 CACHE PATH "Binary target dir.")
	SET (LIBRARY_OUTPUT_PATH ${${CMAKE_PROJECT_NAME}_BINARY_DIR}/bin/linux64 CACHE PATH "Library target dir (linux64).")
ENDIF()

IF (NOT MSVC)
	SET (PREFER_SYSTEM_LIBS false CACHE BOOL "set to true if you
	want to prefer system installed libraries over 3rd party")
ELSE ()
	SET (PREFER_SYSTEM_LIBS false)
	MARK_AS_ADVANCED (PREFER_SYSTEM_LIBS)
ENDIF ()


# Some NVSG sources unfortunately assume some BS M$ only headers to be
# available everywhere except on Linux. The opposite is the case but they
# check for a LINUX define to be set. Very bad style. But to fix it I have to
# set this define or change the NVSG headers
IF (NOT WIN32)
	ADD_DEFINITIONS (-DLINUX)
	IF (NOT ${CMAKE_BUILD_TYPE} STREQUAL Debug)
		ADD_DEFINITIONS (-DNDEBUG)
	ENDIF ()
ENDIF (NOT WIN32)

# This tells QT to be compatible with boost signals
# ADD_DEFINITIONS(-DQT_NO_KEYWORDS)

#ENABLE_TESTING()

# Load the rtt cmake framework
SET(CMAKE_MODULE_PATH "${PROJECT_SOURCE_DIR}/cmake")
INCLUDE("rtt")
INCLUDE("qt-tools")
INCLUDE("rtt_deltagen_sdk")


###################################################################################################
# Add subdirectories here
#
# Please add the libraries in order of their dependencies here - this will support the
# packaging subsystem - otherwise binary files for libraries which are referenced by a target
# but defined lateron cannot be added to the RUNTIME-targets for Unit tests.
###################################################################################################
ADD_SUBDIRECTORY(DebugTool)

###################################################################################################
# Ok, now some packages
###################################################################################################

###################################################################################################
# LEAVE THIS UNTOUCHED, really dude, don't mess with this!
###################################################################################################

RTT_PKG_FINALIZE_ALL()

