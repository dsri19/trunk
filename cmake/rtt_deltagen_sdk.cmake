# Use this function to compile a plugin
# The function allows all arguments, RTT_LIBRARY supports, but not the STATIC
# flag. Additionally an argument callsed DESCRIPTION is obligatory. It specifies
# the path to a prototype plugin.xml file. In that file the variables
#   ${ARG_BINARY} the name of the built plugin dll
#   ${ARG_MAJOR}  the major version number of the plugin
#   ${ARG_MINOR}  the minor version number of the plugin
FUNCTION(RTT_DELTAGEN_PLUGIN name)
  parse_arguments(ARG "SOURCES;HEADERS;DEPENDS;INCLUDES;PCH;DEFINES;MAJOR;MINOR;DESCRIPTION"
                  "" ${ARGN})

  if(NOT ARG_DESCRIPTION)
    message(FATAL_ERROR "No description for plugin given.")
  endif()
  
  RTT_LIBRARY(${name}
    SOURCES
        ${ARG_SOURCES} 
    HEADERS
        ${ARG_HEADERS}
    DEPENDS
        ${ARG_DEPENDS}
    INCLUDES
        ${ARG_INCLUDES}
    PCH
        ${ARG_PCH}
    DEFINES
        ${ARG_DEFINES}
    MAJOR
        ${ARG_MAJOR}
    MINOR
        ${ARG_MINOR}
  )
      
  # Copy the description xml file to the appropriate places
  if(NOT ARG_MAJOR)
      set(ARG_MAJOR 1)
  endif()

  if(NOT ARG_MINOR)
      set(ARG_MINOR 0)
  endif()
  
  if(MSVC)
    # For Visual Studio we need to copy 4 versions of the plugin.xml
    SET(ARG_BINARY ${name}-d.dll)
    FILE(MAKE_DIRECTORY "${EXECUTABLE_OUTPUT_PATH}/Debug")
    CONFIGURE_FILE("${ARG_DESCRIPTION}"
                   "${EXECUTABLE_OUTPUT_PATH}/Debug/${name}-d.xml")
    SET(ARG_BINARY ${name}.dll)
    foreach(buildType "MinSizeRel" "Release" "RelWithDebInfo")
        FILE(MAKE_DIRECTORY "${EXECUTABLE_OUTPUT_PATH}/${buildType}")
        CONFIGURE_FILE("${ARG_DESCRIPTION}"
                       "${EXECUTABLE_OUTPUT_PATH}/${buildType}/${name}.xml")
    endforeach()
  else()
    # Currently we don't support any other platforms than windows
    message(FATAL_ERROR "Platforms other than windows are currently not "
            "supported.")
  endif()
  
  UNSET(ARG_BINARY)
    
ENDFUNCTION()