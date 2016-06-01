function (DEBUG)
    __get_global_var(x "RTT_CMAKE_DEBUGGING")
    if (${x})
        message(STATUS "DEBUG: ${ARGN}")
    endif()
endfunction()

if (NOT RTT_BUILD_SET)
    set(RTT_BUILD_SET "default" CACHE STRING "Build set defining external dependencies and packages")
endif ()

SET(RTT_CMAKE_DIR ${CMAKE_CURRENT_LIST_DIR})

include("${RTT_BUILD_SET}_dependencies")

set_property(GLOBAL PROPERTY PREDEFINED_TARGETS_FOLDER "CMake Targets")

# are we 64 bitty?
IF(${CMAKE_SIZEOF_VOID_P} EQUAL 4)
    SET( HAVE_64_BIT FALSE CACHE BOOL "32 bit system" )
ELSE()
    SET( HAVE_64_BIT TRUE CACHE BOOL "64 bit system" )
ENDIF()
MARK_AS_ADVANCED(HAVE_64_BIT)

if(WIN32)
    set(SHELL_COMMENT "rem")
else(WIN32)
    set(SHELL_COMMENT "true")
endif(WIN32)

# What's our Name?
unset(RTT_COMPILER_NAME)
unset(RTT_PLATFORM_NAME)
IF(MSVC)
  # Remove RelWithMinSize configuration
  set(CMAKE_CONFIGURATION_TYPES Debug Release RelWithDebInfo CACHE TYPE INTERNAL FORCE )
  IF(MSVC80)
    SET(MSVC_COMPILER_NAME "vc80" CACHE INTERNAL "MSVC compiler name")
    SET(RTT_COMPILER_NAME "vc80" CACHE INTERNAL "Compiler name")
    ENDIF()
  IF(MSVC90)
    SET(MSVC_COMPILER_NAME "vc90" CACHE INTERNAL "MSVC compiler name")
    SET(RTT_COMPILER_NAME "vc90" CACHE INTERNAL "Compiler name")
    ENDIF()
  IF(MSVC11)
    SET(MSVC_COMPILER_NAME "vc110" CACHE INTERNAL "MSVC compiler name")
    SET(RTT_COMPILER_NAME "vc110" CACHE INTERNAL "Compiler name")
    ENDIF()
  IF(MSVC14)
    SET(MSVC_COMPILER_NAME "vc140" CACHE INTERNAL "MSVC compiler name")
    SET(RTT_COMPILER_NAME "vc140" CACHE INTERNAL "Compiler name")
    ENDIF()
  IF(NOT MSVC_COMPILER_NAME)
    MESSAGE(FATAL_ERROR " TOOLSET NOT SUPPORTED! Please use either vc80, vc90, vc11 or vc14")
  ENDIF()
  IF (HAVE_64_BIT)
    SET(RTT_PLATFORM_NAME "win64" CACHE INTERNAL "Compiler name")
    SET(MSVC_PLATFORM_NAME "x64" CACHE INTERNAL "Platform")
  ELSE()
    SET(RTT_PLATFORM_NAME "win32" CACHE INTERNAL "Compiler name")
    SET(MSVC_PLATFORM_NAME "Win32" CACHE INTERNAL "Platform")
  ENDIF()
ELSE()
  # Determine the Compiler name which is important to fetch the right artifacts
  # Not sure if this is the best way to do it but it seems to work :)
  if (${CMAKE_CXX_COMPILER_VERSION} VERSION_LESS 4.9.0
    AND (${CMAKE_CXX_COMPILER_VERSION} VERSION_GREATER 4.8.0
      OR ${CMAKE_CXX_COMPILER_VERSION} VERSION_EQUAL 4.8.0))
    set(RTT_COMPILER_NAME "gcc48" CACHE INTERNAL "RTT Compiler name")
    set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -std=c++11")
  elseif (${CMAKE_CXX_COMPILER_VERSION} VERSION_LESS 4.10.0
    AND (${CMAKE_CXX_COMPILER_VERSION} VERSION_GREATER 4.9.0
      OR ${CMAKE_CXX_COMPILER_VERSION} VERSION_EQUAL 4.9.0))
    set(RTT_COMPILER_NAME "gcc48" CACHE INTERNAL "RTT Compiler name")
    set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -std=c++11")
  elseif (${CMAKE_CXX_COMPILER_VERSION} VERSION_LESS 4.5.0
    AND (${CMAKE_CXX_COMPILER_VERSION} VERSION_GREATER 4.4.0
      OR ${CMAKE_CXX_COMPILER_VERSION} VERSION_EQUAL 4.4.0))
    set(RTT_COMPILER_NAME "gcc44" CACHE INTERNAL "RTT Compiler name")
  else()
    message(FATAL_ERROR "GCC Version ${CMAKE_CXX_COMPILER_VERSION} unknown - not supported")
  endif()
  SET(LINUX_COMPILER_NAME ${RTT_COMPILER_NAME} CACHE INTERNAL "Linux Compiler name")
  IF (HAVE_64_BIT)
    SET(RTT_PLATFORM_NAME "linux64" CACHE INTERNAL "Compiler name")
    SET(LINUX_PLATFORM_NAME "linux64" CACHE INTERNAL "Platform")
  ELSE()
    SET(RTT_PLATFORM_NAME "linux32" CACHE INTERNAL "Compiler name")
    SET(LINUX_PLATFORM_NAME "linux32" CACHE INTERNAL "Platform")
  ENDIF()
ENDIF(MSVC)

if (NOT RTT_PLATFORM_NAME OR NOT RTT_COMPILER_NAME)
    message(FATAL_ERROR "Unsupported target or platform")
endif()

MARK_AS_ADVANCED(MSVC_COMPILER_NAME)
MARK_AS_ADVANCED(MSVC_PLATFORM_NAME)
MARK_AS_ADVANCED(LINUX_COMPILER_NAME)
MARK_AS_ADVANCED(LINUX_PLATFORM_NAME)
MARK_AS_ADVANCED(RTT_COMPILER_NAME)
MARK_AS_ADVANCED(RTT_PLATFORM_NAME)

# TODO:
#   - transitive dependencies from system libraries do not work
#   - RUNTIME preparation
#   - PACKAGING
#   - VERSIONING
#include(CTest)
include("kitware")
include("rtt_packaging")
include("rtt_utilities")
include("rtt_resource")
include("python-setup")
SET(RTT_CMAKE_PYTHON_TOOLS_ROOT "${CMAKE_CURRENT_LIST_DIR}" CACHE INTERNAL "Directory containing the python utilities of the build system")
SET(RTT_CMAKE_TOOLS_ROOT "${CMAKE_CURRENT_LIST_DIR}" CACHE INTERNAL "Directory containing the python utilities of the build system")

include("rtt_artifactory")
set(RTT_ARTIFACTORY_SUPPORT True CACHE INTERNAL "Flag to indicate whether this version of the build utilities support artifactory")
mark_as_advanced(RTT_ARTIFACTORY_SUPPORT)

set(RTT_LIBRARY_FORWARD_DECLARATIONS)

#
# __handle_dependency(${name} ${dependency})
#

macro (__handle_dependency name dependency)
    set(syslib 0)
    list(FIND RTT_LIBRARY_FORWARD_DECLARATIONS ${dependency} forward_declaration_index)
    DEBUG("XXX Check if ${dependency} is already there")
    if (TARGET ${dependency})
        # added with cmake commands manually
        DEBUG("YYY Yes it is")
    elseif(forward_declaration_index GREATER -1)
        # forward declarded target
    else()
        DEBUG("NNN No it is not")
        if ("${dependency}" MATCHES "^.+\\.lib$")
            # TODO: Seems to be a windows library - what to do?
        else()
            # Artifactory Dependency Handling
            # where to get it from
            set(__dependency__ "${dependency}")
            if ("${__dependency__}" MATCHES "^sys-.+$")
                message(FATAL_ERROR "Resolving dependencies via sys-... is not supported anymore - please fix dependency ${__dependency__} of target ${name}")
                string(SUBSTRING "${dependency}" 4 -1 __dependency__)
                set(dependency ${__dependency__})
            endif()

            #if (NOT RTT_NSYS_${__dependency__}_LOCATION)
                __RTT_ARTIFACTORY_GET(${__dependency__})
            #endif ()
        endif()
    endif()
endmacro()

# Global Initialization of the Build System Environment
#
# Some of the functions depend on variables which have to be empty at the beginning or empty files which are used later
function (__RTT_INIT)
    __set_global_var("RTT_CMAKE_DEBUGGING" "FALSE" "Debugging enabled")

    # Clean internal variables
    #get_cmake_property(_variableNames VARIABLES)
    #foreach (_variableName ${_variableNames})
    #   if (_variableName MATCHES "^RTT_INTERNAL_.+$")
    #       #unset(${_variableName} CACHE)
    #   endif()
    #   if (_variableName MATCHES "^RTT_NSYS_.+$")
    #       #unset(${_variableName} CACHE)
    #   endif()
    #endforeach()

    DEBUG("Cleaning up SAVE_ADD_SUBDIRECTORY_ITEMS CACHE: ${SAVE_ADD_SUBDIRECTORY_ITEMS}")
    unset(SAVE_ADD_SUBDIRECTORY_ITEMS CACHE)

    __get_global_var(tmp SAVE_ADD_SUBDIRECTORY_PROTECTION_VARIABLES)
    DEBUG("Cleaning up SAVE_ADD_SUBDIRECTORY_PROTECTION_VARIABLES: ${tmp}")
    foreach(item ${tmp})
        DEBUG("-- Clean: ${item}")
        unset(${item} CACHE)
    endforeach()
    unset(SAVE_ADD_SUBDIRECTORY_PROTECTION_VARIABLES CACHE)

    set(DEPENDENCY_VERSIONS "${CMAKE_CURRENT_SOURCE_DIR}/dependency_versions.config")
    if (NOT EXISTS ${DEPENDENCY_VERSIONS})
        set(DEPENDENCY_VERSIONS "${CMAKE_CURRENT_SOURCE_DIR}/../dependency_versions.config")
    endif()
    if (NOT EXISTS ${DEPENDENCY_VERSIONS})
        set(DEPENDENCY_VERSIONS "${CMAKE_PROJECT_ROOT}/dependency_versions.config")
    endif()
    if (EXISTS "${DEPENDENCY_VERSIONS}")
        set(RTT_DEPENDENCY_VERSIONS "${DEPENDENCY_VERSIONS}" CACHE INTERNAL "Main Dependency Version Configuration")

        message(STATUS "Loading dependency versions from ${DEPENDENCY_VERSIONS}")
        __RTT_READ_PROPERTIES_FILE("${DEPENDENCY_VERSIONS}" "RTT_NSYS_VERSION_" IMPORTED_KEYS REPORT_CONFLICTS conflicts)
        if(conflicts)
          message(FATAL_ERROR "Dependency conflicts: " ${conflicts})
        endif()
    endif()

    set(ARTIFACT_ALIASES "${CMAKE_CURRENT_SOURCE_DIR}/artifact_aliases.config")
    if (NOT EXISTS ${ARTIFACT_ALIASES})
        set(ARTIFACT_ALIASES "${CMAKE_CURRENT_SOURCE_DIR}/../artifact_aliases.config")
    endif()
    if (NOT EXISTS ${ARTIFACT_ALIASES})
        set(ARTIFACT_ALIASES "${CMAKE_PROJECT_ROOT}/artifact_aliases.config")
    endif()
    if (EXISTS "${ARTIFACT_ALIASES}")
        set(RTT_ARTIFACT_ALIASES "${ARTIFACT_ALIASES}" CACHE INTERNAL "Main Artifact Aliases Configuration")

        message(STATUS "Loading aliases from ${ARTIFACT_ALIASES}")
        __RTT_READ_PROPERTIES_FILE("${ARTIFACT_ALIASES}" "RTT_NSYS_ALIAS_" IMPORTED_KEYS)
    endif()

    option(RTT_USE_RELWITHDEBINFO_LIBRARIES "When activated, linking to artifacts uses RelWithDebInfo instead of Release for non-debug configs" ON)
    option(RTT_SKIP_ALL_TESTS "When activated, all RTT_TEST targets will be skipped" OFF)

    #adds the configuration Coverage in VisualStudio
    if ( SQUISHCOCO_ENABLED )
        set(CMAKE_CONFIGURATION_TYPES ${CMAKE_CONFIGURATION_TYPES} Coverage CACHE TYPE INTERNAL FORCE )
        SET(COVERAGE_FLAGS "--cs-on --cs-line --cs-exclude-file-wildcard=*artifactory* --cs-libgen=-O2")
        SET( CMAKE_C_FLAGS_COVERAGE
        "${CMAKE_C_FLAGS_RELEASE} ${COVERAGE_FLAGS}" CACHE STRING
        "Flags used by the C++ compiler during coverage builds."
        FORCE )

        SET( CMAKE_CXX_FLAGS_COVERAGE
        "${CMAKE_CXX_FLAGS_RELEASE} ${COVERAGE_FLAGS}" CACHE STRING
        "Flags used by the C compiler during coverage builds."
        FORCE )

        SET( CMAKE_EXE_LINKER_FLAGS_COVERAGE
        "${CMAKE_EXE_LINKER_FLAGS_RELEASE} ${COVERAGE_FLAGS}" CACHE STRING
        "Flags used for linking binaries during coverage builds."
        FORCE )

        SET( CMAKE_SHARED_LINKER_FLAGS_COVERAGE
        "${CMAKE_SHARED_LINKER_FLAGS_RELEASE} ${COVERAGE_FLAGS}" CACHE STRING
        "Flags used by the shared libraries linker during coverage builds."
        FORCE )

        SET( CMAKE_STATIC_LINKER_FLAGS_COVERAGE
        "${CMAKE_STATIC_LINKER_FLAGS_RELEASE} ${COVERAGE_FLAGS}" CACHE STRING
        "Flags used by the static libraries linker during coverage builds."
        FORCE )

        MARK_AS_ADVANCED(
        CMAKE_CXX_FLAGS_COVERAGE
        CMAKE_C_FLAGS_COVERAGE
        CMAKE_EXE_LINKER_FLAGS_COVERAGE
        CMAKE_SHARED_LINKER_FLAGS_COVERAGE
        CMAKE_STATIC_LINKER_FLAGS_COVERAGE
        COMPILE_DEFINITIONS_COVERAGE
        )
    endif()
endfunction()

# Global Shutdown Function

function (__RTT_FINISH_CMAKELISTS)
    RTT_FINALIZE_PERFORMANCE_TESTS()
    RTT_PKG_FINALIZE_ALL()
endfunction()

macro (RTT_FINISH_CMAKELISTS)
    if (${CMAKE_CURRENT_SOURCE_DIR} STREQUAL ${PROJECT_SOURCE_DIR})
        __RTT_FINISH_CMAKELISTS()
    endif()
endmacro()

macro(RTT_DECLARE_TARGET name)
  list(APPEND RTT_LIBRARY_FORWARD_DECLARATIONS ${name})
endmacro(RTT_DECLARE_TARGET name)

#########################################################################################################################################
#
# This is the main function used to create targets in the RTT-style. Every function like RTT_EXECUTABLE or RTT_LIBRARY or ... uses
# this one given the type of the target as a parameter.
#
# __RTT_TARGET( name
#   EXECUTABLE | [IMPORTED] LIBRARY | STATIC_LIBRARY
#   SOURCES ...
#   HEADERS ...
#   DEPENDS ...
#   RUNTIME_DEPENDENCIES
#   PCH .. precompiled headers
#   DEFINES .. list of precompiler definitions
# )

function (__RTT_TARGET name)

    parse_arguments(ARG
        "FOLDER;SOURCES;HEADERS;DEPENDS;INCLUDES;PCH;DEFINES;PRIVATE_DEFINES;RUNTIME_DEPENDENCIES;COMPILE_OPTIONS"
        "EXECUTABLE;IMPORTED;LIBRARY;MODULE;STATIC_LIBRARY;WIN32"
        ${ARGN})

    # set header files to 'not compile' for M$
    foreach (header ${ARG_HEADERS})
        set_source_files_properties (${header} PROPERTIES HEADER_FILE_ONLY true)
    endforeach ()

    ## create target
    if (ARG_EXECUTABLE)
        set(log_prefix "RTT-TARGET (EXE): ${name} -")
        message(STATUS "${log_prefix} created")

            set(PCH_SOURCE)
        set(PCH_HEADER)

        if (ARG_PCH)
            set(PCH_SOURCE)
            set(PCH_HEADER)
            # Turn on precompiled headers
            message (STATUS "${log_prefix} enabling precompiled headers: ${ARG_PCH}")
            enable_precompiled_headers(ARG_PCH ARG_SOURCES PCH_HEADER PCH_SOURCE ${name})
        endif ()

        # set WIN32 param to specify the window subsystem as window app
        if (ARG_WIN32)
            add_executable(${name} WIN32 ${ARG_SOURCES} ${ARG_HEADERS} ${PCH_HEADER} ${PCH_SOURCE})
        else ()
            add_executable(${name} ${ARG_SOURCES} ${ARG_HEADERS} ${PCH_HEADER} ${PCH_SOURCE})
        endif ()

        set (RTT_INTERNAL_${name}_TYPE "EXECUTABLE" CACHE STRING "artifact type" FORCE)
        mark_as_advanced (RTT_INTERNAL_${name}_TYPE)

        # disable incremental linking on /Z7
        # /Z7 should prevent incremental linking anyway and leaving it on appears to cause hangs
        # in some cases when linking large static libraries
        if (MSVC AND RTT_CONFIG_EMBED_DEBUG_INFO_IN_OBJECT_FILES)
            set_property(TARGET ${name} APPEND PROPERTY LINK_FLAGS "/INCREMENTAL:NO")
        endif()
    elseif (ARG_LIBRARY)
        if (ARG_IMPORTED)
            # Create CMake target for imported library - have to check first if has already been created
            message(STATUS "${log_prefix} importing ${name}")

            if (TARGET ${name})
                DEBUG("${name} is already there")
            else()
                set (log_prefix "IMPORTED LIBRARY: ${name} -")
                message (STATUS "${log_prefix} created")
                add_library (${name} SHARED IMPORTED)

                # remember that this is an imported library
                set (RTT_INTERNAL_${name}_IMPORTED TRUE CACHE STRING "imported library marker" FORCE)
                mark_as_advanced(RTT_INTERNAL_${name}_IMPORTED)
            endif ()

            set (RTT_INTERNAL_${name}_TYPE "SHARED_LIBRARY" CACHE STRING "artifact type" FORCE)
            mark_as_advanced (RTT_INTERNAL_${name}_TYPE)
        else()
            set (log_prefix "RTT-TARGET (LIB): ${name} -")
            message (STATUS "${log_prefix} created")

            set(PCH_SOURCE)
            set(PCH_HEADER)
            if (ARG_PCH)
                # Turn on precompiled headers
                message (STATUS "${log_prefix} enabling precompiled headers: ${ARG_PCH}")
                enable_precompiled_headers(ARG_PCH ARG_SOURCES PCH_HEADER PCH_SOURCE ${name})
            endif ()

            add_library (${name} SHARED ${ARG_SOURCES} ${ARG_HEADERS} ${PCH_HEADER} ${PCH_SOURCE})
            set (RTT_INTERNAL_${name}_TYPE "SHARED_LIBRARY" CACHE STRING "artifact type" FORCE)
            mark_as_advanced (RTT_INTERNAL_${name}_TYPE)
            if( DROP_LINK_LIBRARY_DEPENDENCIES )
                # avoid linking dependencies
                # http://www.cmake.org/Wiki/CMake_FAQ#Why_are_libraries_linked_to_my_shared_library_included_when_something_links_to_it.3F
                message(STATUS "${log_prefix} drop dependency libraries")
                set_target_properties(${name} PROPERTIES LINK_INTERFACE_LIBRARIES "" )
            endif()
        endif ()
    elseif (ARG_STATIC_LIBRARY)
        set (log_prefix "RTT-TARGET (LIB): ${name} -")
        message (STATUS "${log_prefix} created")

        # XXX TODO integration not yet very nice
        # are precompiled headers configured?
        set(PCH_SOURCE)
        set(PCH_HEADER)
        if (ARG_PCH)
            # Turn on precompiled headers
            message (STATUS "${log_prefix} enabling precompiled headers: ${ARG_PCH}")
            enable_precompiled_headers(ARG_PCH ARG_SOURCES PCH_HEADER PCH_SOURCE ${name})
        endif ()

        add_library (${name} STATIC ${ARG_SOURCES} ${ARG_HEADERS} ${PCH_HEADER} ${PCH_SOURCE})
        string(TOUPPER ${name} upper_name)
        target_compile_definitions (${name} PUBLIC RTT_${upper_name}_STATIC_BUILD)

        if (NOT ARG_SOURCES)
            set_target_properties(${name} PROPERTIES LINKER_LANGUAGE CXX)

            set (RTT_INTERNAL_${name}_TYPE "HEADER_ONLY_LIBRARY" CACHE STRING "artifact type" FORCE)
            mark_as_advanced (RTT_INTERNAL_${name}_TYPE)
        else()
            set (RTT_INTERNAL_${name}_TYPE "STATIC_LIBRARY" CACHE STRING "artifact type" FORCE)
            mark_as_advanced (RTT_INTERNAL_${name}_TYPE)
        endif()
    elseif (ARG_MODULE)
        set (log_prefix "RTT-TARGET (LIB): ${name} -")
        message (STATUS "${log_prefix} created")

        set(PCH_SOURCE)
        set(PCH_HEADER)
        if (ARG_PCH)
          # Turn on precompiled headers
          message (STATUS "${log_prefix} enabling precompiled headers: ${ARG_PCH}")
          enable_precompiled_headers(ARG_PCH ARG_SOURCES PCH_HEADER PCH_SOURCE ${name})
        endif ()

        add_library (${name} MODULE ${ARG_SOURCES} ${ARG_HEADERS} ${PCH_HEADER} ${PCH_SOURCE})
        set (RTT_INTERNAL_${name}_TYPE "MODULE" CACHE STRING "artifact type" FORCE)
        mark_as_advanced (RTT_INTERNAL_${name}_TYPE)
    else ()
        message (FATAL " -- unknown target ${name}: ${ARGN}")
    endif ()

    # set precompiler definitions
    # message(STATUS "TARGET: ${name} - DEFINES: ${ARG_DEFINES}")
    if (ARG_DEFINES)
        if(ARG_IMPORTED)
            set_property(TARGET ${name} APPEND PROPERTY INTERFACE_COMPILE_DEFINITIONS ${ARG_DEFINES})
        else()
            target_compile_definitions(${name} PUBLIC ${ARG_DEFINES})
        endif()
    endif()
    if(ARG_PRIVATE_DEFINES)
        if(NOT ARG_IMPORTED)
            target_compile_definitions(${name} PRIVATE ${ARG_PRIVATE_DEFINES})
        endif()
    endif()

    # set compile options
    # message(STATUS "TARGET: ${name} - DEFINES: ${ARG_DEFINES}")
    if (ARG_COMPILE_OPTIONS)
        if(ARG_IMPORTED)
            set_property(TARGET ${name} APPEND PROPERTY INTERFACE_COMPILE_OPTIONS ${ARG_COMPILE_OPTIONS})
        else()
            target_compile_options(${name} PUBLIC ${ARG_COMPILE_OPTIONS})
        endif()
    endif()

    ## remember settings of this target
    __set_global_target_var(${name} INCLUDES "${ARG_INCLUDES}" "Additional include directories for target ${name}")
    __set_global_target_var(${name} DEPENDS "${ARG_DEPENDS}" "Dependencies used to build, link and deploy target ${name} and all which depend on it")
    __set_global_target_var(${name} DEFINES "${ARG_DEFINES}" "Additional defines used to build ${name} and all targets which depend on it")
    __set_global_target_var(${name} COMPILE_OPTIONS "${ARG_COMPILE_OPTIONS}" "Additional compile options used to build ${name} and all targets which depend on it")
    __set_global_target_var(${name} RUNTIME_DEPENDENCIES "${ARG_RUNTIME_DEPENDENCIES}" "Runtime dependencies for target ${name}")

    ## handle dependencies
    # - create a list of include directories
    # - record a list of total dependencies

    set (includes)
    if (ARG_INCLUDES)
        foreach(dir ${ARG_INCLUDES})
            file(TO_CMAKE_PATH "${dir}" converted_dir)
            list(APPEND includes "${converted_dir}")
        endforeach()
    endif()

    # Go on and handle dependencies of the recently created target
    # - (normal) dependencies are handled - libraries will be linked and so on ...
    # - runtime dependencies are recorded for later use and a CMake dependency will be added
    #
    # Using the current implementation it is important to handle the normal dependencies
    # first and then the RUNTIME_DEPENDENCIES because runtime dependencies added while
    # handling the normal ones are added to ARG_RUNTIME_DEPENDENCIES and the total
    # (and unique) list of additional dependencies will be created afterwards.
    unset(total_dependencies)
    unset(total_runtime_dependencies)

    # (normal) dependencies will be handled
    # - libraries will be handled
    # - runtime dependencies of (normal) dependencies will be recorded
    # - ...
    if (ARG_DEPENDS)
        #message(STATUS "${log_prefix} handle dependencies ${ARG_DEPENDS}")
        foreach (dependency ${ARG_DEPENDS})
            if ("${dependency}" MATCHES "^[-/].+")
                # handle linker flags by just adding them
                target_link_libraries(${name} ${dependency})
            else()
                #message(STATUS "${log_prefix} check dependency: ${dependency}")

                # load dependency if necessary
                __handle_dependency(${name} ${dependency})

                # this is of course a dependency and all of its dependencies are too
                __get_global_target_var(tmp_total_dependencies ${dependency} TOTAL_DEPENDENCIES)
                list(APPEND total_dependencies ${dependency} ${tmp_total_dependencies})

                # get runtime dependencies
                __get_global_target_var(tmp_runtime_deps ${dependency} TOTAL_RUNTIME_DEPENDENCIES)
                list(APPEND ARG_RUNTIME_DEPENDENCIES ${tmp_runtime_deps})

                ## link to libraries

                # IMPORTED
                #   The boolean value of this property is true for targets created with the IMPORTED option to
                #   add_executable or add_library. It is false for targets built within the project.
                __get_global_target_var(imported ${dependency} IMPORTED)
                if (imported OR ARG_IMPORTED)
                    #message(STATUS "${log_prefix} ${dependency} imported = ${imported}")
                    ## handle imported targets

                    # IMPORTED_IMPLIB
                    #   Specifies the location of the ".lib" part of a windows DLL. Ignored for non-imported targets.
                    __get_global_target_var(imported_implib ${dependency} IMPORTED_IMPLIB)

                    # if the target itself is an imported target, add
                    # the imported dependencies to the list of link interface libraries
                    if (ARG_IMPORTED)
                    else()
                        # a local target depends on an imported library
                        if (imported_implib)
                            #message(STATUS "${log_prefix} depends on ${dependency} (${imported_implib})")
                            if ( SQUISHCOCO_ENABLED )
                                #link with libraries specific to each configuration
                                __get_global_target_var(RELEASE_LIB ${dependency} IMPORTED_IMPLIB_RELEASE)
                                __get_global_target_var(DEBUG_LIB ${dependency} IMPORTED_IMPLIB_DEBUG)
                                __get_global_target_var(COVERAGE_LIB ${dependency} IMPORTED_IMPLIB_COVERAGE)

                                target_link_libraries(${name} $<$<CONFIG:Debug>:${DEBUG_LIB}>$<$<CONFIG:Coverage>:${COVERAGE_LIB}>$<$<CONFIG:Release>:${RELEASE_LIB}>$<$<CONFIG:RelWithDebInfo>:${RELEASE_LIB}>$<$<CONFIG:MinSizeRel>:${RELEASE_LIB}>)
                            else()
                                target_link_libraries(${name} ${imported_implib})
                            endif()
                        endif()

                        # also link against dependencies of this imported library
                        if( NOT DROP_LINK_LIBRARY_DEPENDENCIES )
                            __get_global_target_var(imported_dependencies ${dependency} TOTAL_DEPENDENCIES)
                            foreach(imported_dependency ${imported_dependencies})
                                __get_global_target_var(imported_implib ${imported_dependency} IMPORTED_IMPLIB)

                                #message(STATUS "${log_prefix} link interface of ${dependency} requires to link ${name} against ${imported_dependency}: ${imported_implib}")

                                if (imported_implib)
                                    if ( SQUISHCOCO_ENABLED )
                                        #link with libraries specific to each configuration
                                        __get_global_target_var(RELEASE_LIB ${imported_dependency} IMPORTED_IMPLIB_RELEASE)
                                        __get_global_target_var(DEBUG_LIB ${imported_dependency} IMPORTED_IMPLIB_DEBUG)
                                        __get_global_target_var(COVERAGE_LIB ${imported_dependency} IMPORTED_IMPLIB_COVERAGE)

                                        target_link_libraries(${name} $<$<CONFIG:Debug>:${DEBUG_LIB}>$<$<CONFIG:Coverage>:${COVERAGE_LIB}>$<$<CONFIG:Release>:${RELEASE_LIB}>$<$<CONFIG:RelWithDebInfo>:${RELEASE_LIB}>$<$<CONFIG:MinSizeRel>:${RELEASE_LIB}>)
                                    else()
                                        target_link_libraries(${name} ${imported_implib})
                                    endif()
                                endif()
                            endforeach()
                        endif()
                    endif()
                else()
                    ## handle dependencies from locally created targets to local targets
                    if (NOT RTT_INTERNAL_${dependency}_TYPE STREQUAL "HEADER_ONLY_LIBRARY")
                        # RTT_UTILITY_PROJECT_ is set by the RTT_SET_UTILITY_PROJECT function
                        set(RTT_UTILITY_PROJECT_dependency RTT_UTILITY_PROJECT_${dependency})
                        if (${${RTT_UTILITY_PROJECT_dependency}})
                            # Do not add .lib file to inputs on windows. Just create project dependencies
                            add_dependencies(${name} ${dependency})
                        else()
                            set(DEPENDENCY_TARGET_TYPE "" )
                            __get_global_target_var(DEPENDENCY_TARGET_TYPE ${dependency} TARGET_TYPE)
                            # message("dependency type of ${dependency}: ${DEPENDENCY_TARGET_TYPE}")
                            if( ${dependency} MATCHES ".*\\.(lib|LIB)$" )
                                #  message( "linking imported ${dependency}" )
                                target_link_libraries(${name} ${dependency})
                            elseif( NOT DEPENDENCY_TARGET_TYPE)
                                add_dependencies(${name} ${dependency})
                            elseif ( (${DEPENDENCY_TARGET_TYPE} STREQUAL "EXECUTABLE") OR (${DEPENDENCY_TARGET_TYPE} STREQUAL "MODULE_LIBRARY") )
                                # Do not add .lib file to inputs on windows. Just create project dependencies
                                add_dependencies(${name} ${dependency})
                            else()
                                target_link_libraries(${name} ${dependency})
                            endif()
                        endif()
                    endif()
                endif()
            endif()
        endforeach()
    endif()

    # Runtime dependencies and the transitive ones will be recorded for later use
    # and a dependency is added using CMake
    if (ARG_RUNTIME_DEPENDENCIES)
        list(REMOVE_DUPLICATES ARG_RUNTIME_DEPENDENCIES)
        foreach (dependency ${ARG_RUNTIME_DEPENDENCIES})
            # Import the dependency if necessary
            __handle_dependency(${name} ${dependency})

            # Get all the transitive dependencies
            __get_global_target_var(tmp_total ${dependency} TOTAL_RUNTIME_DEPENDENCIES)
            list(APPEND total_runtime_dependencies ${dependency} ${tmp_total})
        endforeach()

        # make the list unique at the end
        list(REMOVE_DUPLICATES total_runtime_dependencies)
        __set_global_target_var(${name} TOTAL_RUNTIME_DEPENDENCIES "${total_runtime_dependencies}" "Expanded list of runtime dependencies")
    endif()

    # remember total dependencies
    if (total_dependencies)
        list(REMOVE_DUPLICATES total_dependencies)
#       message(STATUS "total dependencies of ${name} = ${total_dependencies}")
        __set_global_target_var(${name} TOTAL_DEPENDENCIES "${total_dependencies}" "Expanded list of dependencies")

        # create a list of include directories which consist of the include directories of
        # each of the dependencies
        # also add the defines from all the projects this target depends on
        foreach(dependency ${total_dependencies})

            # include directories
            set (include ${RTT_INTERNAL_${dependency}_INCLUDES})
#           message(STATUS "${log_prefix} - add include paths of ${dependency}: ${include}")
            if (include)
                list(APPEND includes ${include})
            endif()

            # precompiler definitions
            set (defines ${RTT_INTERNAL_${dependency}_DEFINES})
            if (defines AND NOT ARG_IMPORTED)
                target_compile_definitions(${name} PUBLIC ${defines})
            endif()

            # compile options
            set (compile_options ${RTT_INTERNAL_${dependency}_COMPILE_OPTIONS})
            if (compile_options AND NOT ARG_IMPORTED)
                target_compile_options(${name} PUBLIC ${compile_options})
            endif()
        endforeach()
    endif()

    # set include directories
    if (includes)
        list(REMOVE_DUPLICATES includes)
        list(SORT includes)
        include_directories(${includes})
    endif()

    # Cannot set target properties for imported targets
    unset(already_imported)
    set(already_imported ${RTT_INTERNAL_${name}_IMPORTED})
    if (already_imported)
        return()
    endif()

    ## change some target specific settings

    # add a -d postfix to debug libraries
    if (ARG_LIBRARY OR ARG_STATIC_LIBRARY OR ARG_MODULE)
        set_target_properties(${name} PROPERTIES DEBUG_POSTFIX "-d")
    endif()

    if (ARG_FOLDER)
        set_target_properties(${name} PROPERTIES FOLDER ${ARG_FOLDER})
    endif()

    get_target_property(CURRENT_TARGET_TYPE ${name} TYPE)
    # message("Type of ${name}: ${CURRENT_TARGET_TYPE}")
    __set_global_target_var(${name} TARGET_TYPE "${CURRENT_TARGET_TYPE}" "Type of target ${name}")

    if(MSVC11)
        set_property(TARGET ${name} PROPERTY COMPILE_OPTIONS $<$<CONFIG:RelWithDebInfo>:/d2Zi+>$<$<CONFIG:Release>:/d2Zi+>)
    endif()
endfunction()

#
# __RTT_SYSTEM_LIBRARY( name
#   DEPENDS
#   INCLUDES
#   LOCATION
#   IMPLIB
#   DEFINES
#   RUNTIME_DEPENDENCIES
#
#

function (__RTT_SYSTEM_LIBRARY name)

#   ## does such a library exist?
#   set (imported ${RTT_INTERNAL_${name}_IMPORTED})
#   if (imported)
#   else()
        parse_arguments(ARG "DEPENDS;INCLUDES;LOCATION;IMPLIB;DEFINES;COMPILE_OPTIONS;RUNTIME_DEPENDENCIES" "" ${ARGN})

        if (ARG_IMPLIB)
            unset(RTT_INTERNAL_${name}_IMPORTED_IMPLIB CACHE)
            set(RTT_INTERNAL_${name}_IMPORTED_IMPLIB "${ARG_IMPLIB}" CACHE STRING "imported library interface" FORCE)
            mark_as_advanced(RTT_INTERNAL_${name}_IMPORTED_IMPLIB)

            if ( SQUISHCOCO_ENABLED )
                #parse the libraries specific to each configuration
                set(is_debug)
                set(is_release)
                set(is_coverage)
                set(is_general)
                set(DEBUG_LIB)
                set(RELEASE_LIB)
                set(COVERAGE_LIB)
                set(prevIsKeyword)
                set(thisIsKeyword)
                foreach(word ${ARG_IMPLIB})
                    if( NOT prevIsKeyword )
                        string(COMPARE EQUAL "${word}" "debug" is_debug)
                        string(COMPARE EQUAL "${word}" "optimized" is_release)
                        string(COMPARE EQUAL "${word}" "coverage" is_coverage)
                        string(COMPARE EQUAL "${word}" "general" is_general)
                        if ( is_debug OR is_release OR is_coverage OR is_general )
                            set(thisIsKeyword 1)
                        else()
                            set(thisIsKeyword)
                        endif()
                    else()
                        set(thisIsKeyword)
                    endif()
                    if( NOT thisIsKeyword )
                        if (is_debug)
                            list(APPEND DEBUG_LIB ${word})
                        elseif (is_release)
                            list(APPEND RELEASE_LIB ${word})
                        elseif (is_coverage)
                            list(APPEND COVERAGE_LIB ${word})
                        else()
                            list(APPEND DEBUG_LIB ${word})
                            list(APPEND RELEASE_LIB ${word})
                            list(APPEND COVERAGE_LIB ${word})
                        endif()
                    endif()
                    set(prevIsKeyword ${thisIsKeyword})
                endforeach()

                if(NOT COVERAGE_LIB)
                    set(COVERAGE_LIB ${RELEASE_LIB})
                endif()

                if(NOT DEBUG_LIB)
                    set(DEBUG_LIB ${RELEASE_LIB})
                endif()

                __set_global_target_var(${name} IMPORTED_IMPLIB_RELEASE "${RELEASE_LIB}" "imported library interface - release configuration")
                __set_global_target_var(${name} IMPORTED_IMPLIB_DEBUG "${DEBUG_LIB}" "imported library interface - debug configuration")
                __set_global_target_var(${name} IMPORTED_IMPLIB_COVERAGE "${COVERAGE_LIB}" "imported library interface - coverage configuration")
            endif()
        endif()

        if (ARG_LOCATION)
            if ( SQUISHCOCO_ENABLED )
                set(is_debug)
                set(is_release)
                set(is_coverage)
                set(is_general)
                set(RELEASE_LIB)
                set(COVERAGE_LIB)
                set(prevIsKeyword)
                set(thisIsKeyword)
                foreach(word ${ARG_LOCATION})
                    if( NOT prevIsKeyword )
                        string(COMPARE EQUAL "${word}" "debug" is_debug)
                        string(COMPARE EQUAL "${word}" "optimized" is_release)
                        string(COMPARE EQUAL "${word}" "coverage" is_coverage)
                        string(COMPARE EQUAL "${word}" "general" is_general)
                        if ( is_debug OR is_release OR is_coverage OR is_general )
                            set(thisIsKeyword 1)
                        else()
                            set(thisIsKeyword)
                        endif()
                    else()
                        set(thisIsKeyword)
                    endif()
                    if( NOT thisIsKeyword )
                        if (is_release)
                            list(APPEND RELEASE_LIB ${word})
                        elseif (is_coverage)
                            list(APPEND COVERAGE_LIB ${word})
                        elseif ( NOT is_debug )
                            list(APPEND RELEASE_LIB ${word})
                            list(APPEND COVERAGE_LIB ${word})
                        endif()
                    endif()
                    set(prevIsKeyword ${thisIsKeyword})
                endforeach()

                #if there is not dependency library specific to Coverage configuration, we use the one from Release configuration
                if(NOT COVERAGE_LIB AND RELEASE_LIB)
                    foreach(lib ${RELEASE_LIB})
                        list(APPEND ARG_LOCATION "coverage")
                        list(APPEND ARG_LOCATION "${lib}")
                    endforeach()
                endif()
            endif()

            unset(RTT_INTERNAL_${name}_IMPORTED_LOCATION CACHE)
            set(RTT_INTERNAL_${name}_IMPORTED_LOCATION "${ARG_LOCATION}" CACHE STRING "imported library location" FORCE)
            mark_as_advanced(RTT_INTERNAL_${name}_IMPORTED_LOCATION)
        endif()

        __RTT_TARGET(${name} IMPORTED LIBRARY
            DEPENDS ${ARG_DEPENDS}
            INCLUDES ${ARG_INCLUDES}
            DEFINES ${ARG_DEFINES}
            COMPILE_OPTIONS ${ARG_COMPILE_OPTIONS}
            RUNTIME_DEPENDENCIES ${ARG_RUNTIME_DEPENDENCIES}
        )
#   endif()
endfunction()

function (RTT_PYTHON_BINDING name)

    parse_arguments(ARG "SOURCES;DEPENDS;INCLUDES;PCH;DEFINES;RUNTIME_DEPENDENCIES;PUBLIC_HEADERS_BASE_DIR;OUTPUT_NAME;PUBLIC_HEADERS" "STATIC" ${ARGN})

    if (MSVC)
        set(FILE_SUFFIX ".pyd")
    else ()
        set(FILE_SUFFIX ".so")
        # set_target_properties(${name} PROPERTIES SUFFIX ".so" PREFIX "" DEBUG_POSTFIX "")
    endif()
    set(FILE_PREFIX "")
  set(NEW_OUTPUT_NAME ${name})

  if (ARG_OUTPUT_NAME)
    set(NEW_OUTPUT_NAME ${ARG_OUTPUT_NAME})
  endif()

    RTT_LIBRARY(${name}
        SOURCES ${ARG_SOURCES}
        DEPENDS ${ARG_DEPENDS}
        INCLUDES ${ARG_INCLUDES} ${CMAKE_SOURCE_DIR}/lib
        DEFINES ${ARG_DEFINES}
        RUNTIME_DEPENDENCIES ${ARG_RUNTIME_DEPENDENCIES}
        PUBLIC_HEADERS_BASE_DIR ${ARG_PUBLIC_HEADERS_BASE_DIR}
        PUBLIC_HEADERS ${ARG_PUBLIC_HEADERS}
        OUTPUT_NAME ${NEW_OUTPUT_NAME}
        DLL_SUFFIX "${FILE_SUFFIX}"
        SKIP_LIBRARY_PREFIX
        DLL_DEBUG_POSTFIX_OFF
    )

endfunction()

#
# RTT_LIBRARY( name
#   [ STATIC ]
#   SOURCES ...
#   DEPENDS ...
#   PCH ...
#   INCLUDES ...
#   HEADERS
#   FOLDER
#   [PUBLIC_HEADERS]
#   [NO_PUBLIC_HEADERS_DEFAULT_DIR]
#   [PUBLIC_HEADERS_BASE_DIR]
#   [RUNTIME_DEPENDENCIES]
#   [OUTPUT_NAME]
#   [DLL_SUFFIX]
#   [DLL_PREFIX]
#   [DLL_DEBUG_POSTFIX]
#   [SKIP_LIBRARY_PREFIX]

function (RTT_LIBRARY name)

    parse_arguments(ARG "SOURCES;HEADERS;DEPENDS;INCLUDES;RESOURCES;PCH;DEFINES;PRIVATE_DEFINES;MAJOR;MINOR;PATCH;NO_VERSION_SUFFIX;FOLDER;PUBLIC_HEADERS;PUBLIC_HEADERS_BASE_DIR;RUNTIME_DEPENDENCIES;OUTPUT_NAME;DLL_SUFFIX;DLL_PREFIX" "STATIC;MODULE;DLL_DEBUG_POSTFIX_OFF;SKIP_LIBRARY_PREFIX;NO_PUBLIC_HEADERS_DEFAULT_DIR;PACKAGE" ${ARGN})

    set(ARG_INCLUDES ${ARG_INCLUDES} ${ARG_PUBLIC_HEADERS_BASE_DIR})

    if (VERBOSE)
        message(STATUS "RTT_LIBRARY(${name}) - POSTFIX_OFF: ${ARG_DLL_DEBUG_POSTFIX_OFF}, SUFFIX: ${ARG_DLL_SUFFIX}, PREFIX: ${ARG_DLL_PREFIX}")
    endif()

    if (ARG_STATIC)
        __RTT_TARGET(${name} STATIC_LIBRARY
            SOURCES ${ARG_SOURCES}
            DEPENDS ${ARG_DEPENDS}
            HEADERS ${ARG_HEADERS}
            PCH ${ARG_PCH}
            INCLUDES ${ARG_INCLUDES} ${CMAKE_SOURCE_DIR}/lib
            DEFINES ${ARG_DEFINES}
            PRIVATE_DEFINES ${ARG_PRIVATE_DEFINES}
            FOLDER ${ARG_FOLDER}
            RUNTIME_DEPENDENCIES ${ARG_RUNTIME_DEPENDENCIES}
        )
    elseif (ARG_MODULE)
        __RTT_TARGET(${name} MODULE
            SOURCES ${ARG_SOURCES}
            DEPENDS ${ARG_DEPENDS}
            HEADERS ${ARG_HEADERS}
            PCH ${ARG_PCH}
            INCLUDES ${ARG_INCLUDES} ${CMAKE_SOURCE_DIR}/lib
            DEFINES ${ARG_DEFINES}
            PRIVATE_DEFINES ${ARG_PRIVATE_DEFINES}
            FOLDER ${ARG_FOLDER}
            RUNTIME_DEPENDENCIES ${ARG_RUNTIME_DEPENDENCIES}
        )

        if(DEFINED ARG_OUTPUT_NAME)
            set_target_properties(${name} PROPERTIES OUTPUT_NAME ${ARG_OUTPUT_NAME} )
        endif()

        if(DEFINED ARG_DLL_SUFFIX)
            set_target_properties(${name} PROPERTIES SUFFIX ${ARG_DLL_SUFFIX})
        endif()

        # NOTE: Just checking if ARG_DLL_PREFIX has been defined or not is not enough
        # because for empty prefixes this is not enough. So I added another flag here
        #
        # Another option might be to have DLL_PREFIX in both - in argument names and
        # in option names - depending on the implementation of parse_arguments that
        # might do the trick
        if(DEFINED ARG_DLL_PREFIX OR ARG_SKIP_LIBRARY_PREFIX)
            if(VERBOSE)
                message(STATUS "RTT_LIBRARY(${name}): Set prefix to '${ARG_DLL_PREFIX}'")
            endif()
            set_target_properties(${name} PROPERTIES PREFIX "${ARG_DLL_PREFIX}")
        endif()

        if(ARG_DLL_DEBUG_POSTFIX_OFF)
            if(VERBOSE)
                message(STATUS "RTT_LIBRARY(${name}): Skipping debug postfix")
            endif()
            set_target_properties(${name} PROPERTIES DEBUG_POSTFIX "")
        endif()

    else ()
        # place the resource information files and add to the project
        # we only need this for dynamic linkage
        if (DEFINED ARG_MAJOR)
            if (MSVC)
                RTT_RESOURCE_GENERATE_SCRIPTS(
                        LIBRARY ${name}
                        MAJOR ${ARG_MAJOR}
                        MINOR ${ARG_MINOR}
                        PATCH ${ARG_PATCH}
                        NO_VERSION_SUFFIX ${ARG_NO_VERSION_SUFFIX}
                        RESOURCES Generated_Resources
                )
                list(APPEND ARG_SOURCES ${Generated_Resources})
            endif (MSVC)
        endif (DEFINED ARG_MAJOR)

        __RTT_TARGET(${name} LIBRARY
            SOURCES ${ARG_SOURCES}
            HEADERS ${ARG_HEADERS}
            DEPENDS ${ARG_DEPENDS}
            PCH ${ARG_PCH}
            INCLUDES ${ARG_INCLUDES} ${CMAKE_SOURCE_DIR}/lib
            DEFINES ${ARG_DEFINES}
            PRIVATE_DEFINES ${ARG_PRIVATE_DEFINES}
            FOLDER ${ARG_FOLDER}
            RUNTIME_DEPENDENCIES ${ARG_RUNTIME_DEPENDENCIES}
        )

        if(DEFINED ARG_OUTPUT_NAME)
            set_target_properties(${name} PROPERTIES OUTPUT_NAME ${ARG_OUTPUT_NAME} )
        endif()

        if(DEFINED ARG_DLL_SUFFIX)
            set_target_properties(${name} PROPERTIES SUFFIX ${ARG_DLL_SUFFIX})
        endif()

        # NOTE: Just checking if ARG_DLL_PREFIX has been defined or not is not enough
        # because for empty prefixes this is not enough. So I added another flag here
        #
        # Another option might be to have DLL_PREFIX in both - in argument names and
        # in option names - depending on the implementation of parse_arguments that
        # might do the trick
        if(DEFINED ARG_DLL_PREFIX OR ARG_SKIP_LIBRARY_PREFIX)
            if(VERBOSE)
                message(STATUS "RTT_LIBRARY(${name}): Set prefix to '${ARG_DLL_PREFIX}'")
            endif()
            set_target_properties(${name} PROPERTIES PREFIX "${ARG_DLL_PREFIX}")
        endif()

        if(ARG_DLL_DEBUG_POSTFIX_OFF)
            if(VERBOSE)
                message(STATUS "RTT_LIBRARY(${name}): Skipping debug postfix")
            endif()
            set_target_properties(${name} PROPERTIES DEBUG_POSTFIX "")
        endif()

        if (ARG_RESOURCES)
            # get output directory of target
            set(location)
            get_target_property(location ${name} LOCATION)

            set(targetdir)
            get_filename_component(targetdir "${location}" PATH)

			set(absolute_resources)
            foreach(resource ${ARG_RESOURCES})
                get_filename_component(abs_file "${resource}" ABSOLUTE)
				list(APPEND absolute_resources ${abs_file})
            endforeach()
			set_property( TARGET ${name} PROPERTY RESOURCE_FILES ${absolute_resources})
        endif()
		
        if (ARG_PACKAGE)
            RTT_PKG_CREATE("RUNTIME_${name}" "${targetdir}" TARGETNAME "ZZ_RUNTIME_${name}" BINDIR "." LIBDIR "." AS_POSTBUILD ${name})
            RTT_PKG_REGISTER_TARGET("RUNTIME_${name}" ${name})

            foreach(RESOURCE ${ARG_RESOURCES})
                get_filename_component(ABSOLUTE_RESOURCE "${RESOURCE}" ABSOLUTE)
                RTT_PKG_REGISTER_FILES("RUNTIME_${name}" "." ${ABSOLUTE_RESOURCE})
            endforeach()

            RTT_PKG_FINALIZE("RUNTIME_${name}")

            set_target_properties("ZZ_RUNTIME_${name}" PROPERTIES FOLDER "ZZ_Unit Test Runtime Creation")
        endif()
		
    endif ()

    if(ARG_PUBLIC_HEADERS_BASE_DIR)
      set(base_dir_raw ${ARG_PUBLIC_HEADERS_BASE_DIR})
    else()
      set(base_dir_raw ${PROJECT_SOURCE_DIR})
    endif()
    get_filename_component(base_dir ${base_dir_raw} ABSOLUTE)

    if(NOT ARG_PUBLIC_HEADERS)
        set(ARG_PUBLIC_HEADERS ${ARG_HEADERS})
    endif()

    set(header_list "")
    foreach(header_it ${ARG_PUBLIC_HEADERS})
        get_filename_component(abs_path ${header_it} ABSOLUTE)

        # Check if the base_dir is a prefix of abs_path
        string(FIND "${abs_path}" "${base_dir}" BASE_DIR_POS)
        #message(STATUS "HEADER ${abs_path} - POS or ${base_dir} = ${BASE_DIR_POS} ")
        if (NOT BASE_DIR_POS EQUAL 0)
            message(FATAL_ERROR "When creating target ${name} the PUBLIC_HEADERS_BASE_DIR (${base_dir}) must be a base of the public header ${abs_path}")
        endif()

        string(REPLACE "${base_dir}/" "" truncated_path ${abs_path})
        #message(STATUS "Truncated: ${truncated_path}")
        list(APPEND header_list ${truncated_path})
    endforeach()
    set_target_properties(${name} PROPERTIES PUBLIC_HEADERS "${header_list}")
    set_target_properties(${name} PROPERTIES PUBLIC_HEADERS_BASE_DIR "${base_dir}")

    if(ARG_NO_PUBLIC_HEADERS_DEFAULT_DIR)
     set_target_properties(${name} PROPERTIES NO_PUBLIC_HEADERS_DEFAULT_DIR TRUE)
    else()
      set_target_properties(${name} PROPERTIES NO_PUBLIC_HEADERS_DEFAULT_DIR FALSE)
    endif()
    
    # amend library target by version information
    if (DEFINED ARG_MAJOR)
        if (MSVC AND (NOT DEFINED ARG_NO_VERSION_SUFFIX) )
            # on windows, this unfortunately means we have to change the name of the very library.
            # Much the way boost does.
            # However, we try to be compatible within Majors, so unlike boost we only append the major
            # The Minor will at this point only placed into the files resource information
            # which is kinda like the manifest
            set(LIBSTRING "_${ARG_MAJOR}")

            get_target_property(location ${name} LOCATION)
            get_filename_component(location_we ${location} NAME_WE)
            get_filename_component(path ${location} PATH)
            set(pdbdname "${path}/${location_we}-d${LIBSTRING}.pdb")

            set_target_properties(${name} PROPERTIES SUFFIX "${LIBSTRING}.dll")
            set_target_properties(${name} PROPERTIES IMPORT_SUFFIX "${LIBSTRING}.lib")

            get_target_property(location ${name} LOCATION)
            get_filename_component(location_we ${location} NAME_WE)
            get_filename_component(path ${location} PATH)
            set(pdbname "${path}/${location_we}.pdb")
            # set(pdbdname "${path}/${location_we}_d.pdb")

            file(TO_NATIVE_PATH ${pdbname} result)
            file(TO_NATIVE_PATH ${pdbdname} dresult)
            set_target_properties(${name} PROPERTIES LINK_FLAGS_RELEASE "/PDB:\"${result}\"")
            set_target_properties(${name} PROPERTIES LINK_FLAGS_RELWITHDEBINFO "/PDB:\"${result}\"")
            set_target_properties(${name} PROPERTIES LINK_FLAGS_DEBUG "/PDB:\"${dresult}\"")
        endif ()
        set(LIB_VERSION_PROPERTY ${ARG_MAJOR})
        if (ARG_MINOR)
            set(LIB_VERSION_PROPERTY ${LIB_VERSION_PROPERTY}.${ARG_MINOR})
        endif ()
        if (ARG_PATCH)
            set(LIB_VERSION_PROPERTY ${LIB_VERSION_PROPERTY}.${ARG_PATCH})
        endif ()
        set_target_properties(${name} PROPERTIES VERSION ${LIB_VERSION_PROPERTY} SOVERSION ${LIB_VERSION_PROPERTY})
    endif ()
endfunction()

#
# RTT_EXECUTABLE( name
#   SOURCES ...
#   DEPENDS ...
#   INCLUDES ...
#   DEFINES ...
#   PACKAGE ...
#   HEADERS ...
#   RESOURCES ...
#   FOLDER ...
#   RUNTIME_DEPENDENCIES ...
#   OUTPUT_NAME ...

function (RTT_EXECUTABLE name)
    parse_arguments(ARG "HEADERS;SOURCES;DEPENDS;INCLUDES;DEFINES;RESOURCES;PCH;FOLDER;RUNTIME_DEPENDENCIES;OUTPUT_NAME" "PACKAGE;WIN32" ${ARGN})

    if (ARG_WIN32)
        set (W32PARAM "WIN32")
    else ()
        set (W32PARAM "")
    endif ()

    __RTT_TARGET(${name} EXECUTABLE
        ${W32PARAM}
        SOURCES ${ARG_SOURCES}
        DEPENDS ${ARG_DEPENDS}
        INCLUDES ${ARG_INCLUDES}
        DEFINES ${ARG_DEFINES}
        HEADERS ${ARG_HEADERS}
        PCH ${ARG_PCH}
        FOLDER ${ARG_FOLDER}
        RUNTIME_DEPENDENCIES ${ARG_RUNTIME_DEPENDENCIES}
    )

    if( ARG_OUTPUT_NAME )
        set_target_properties( ${name} PROPERTIES OUTPUT_NAME ${ARG_OUTPUT_NAME} )
    endif()

    # if desired create a RUNTIME package of the test target
    if ((MSVC AND ARG_PACKAGE) OR ARG_RESOURCES)
        # get output directory of target
        set(location)
        get_target_property(location ${name} LOCATION)

        set(targetdir)
        get_filename_component(targetdir "${location}" PATH)

        RTT_PKG_CREATE("RUNTIME_${name}" "${targetdir}" TARGETNAME "ZZ_RUNTIME_${name}" BINDIR "." LIBDIR "." AS_POSTBUILD ${name})
        RTT_PKG_REGISTER_TARGET("RUNTIME_${name}" ${name})

        foreach(RESOURCE ${ARG_RESOURCES})
            get_filename_component(ABSOLUTE_RESOURCE "${RESOURCE}" ABSOLUTE)
            RTT_PKG_REGISTER_FILES("RUNTIME_${name}" "." ${ABSOLUTE_RESOURCE})
        endforeach()

        RTT_PKG_FINALIZE("RUNTIME_${name}")

        set_target_properties("ZZ_RUNTIME_${name}" PROPERTIES FOLDER "ZZ_Unit Test Runtime Creation")
    endif()
endfunction()

#
# RTT_ARTIFACT( name
#   VERSION ...
#   TARGETS ...
#   [ADDITIONAL_FILES <targetdir> ...]
#   [CMAKE ...]
#   [NO_PUBLIC_HEADERS]
# If VERSION is not given, an artifact_version.config has to exist with at least MINOR and MAJOR version and optional PREFIX and SUFFIX.

function (RTT_ARTIFACT name)
    cmake_parse_arguments(ARG "CMAKE;NO_PUBLIC_HEADERS" "VERSION" "" ${ARGN})

    RTT_PKG_CREATE(${name} "${CMAKE_BINARY_DIR}/artifact-${name}" SKIP_DEPENDENCIES BINDIR bin LIBDIR lib)

    #message(STATUS "ARGN remaining = ${ARG_UNPARSED_ARGUMENTS}")
    unset(in_targets)
    unset(in_additional_files)
    unset(ARG_TARGETS)
    foreach(ARG ${ARG_UNPARSED_ARGUMENTS})
        if (ARG STREQUAL "TARGETS")
            set(in_targets True)
        elseif(ARG STREQUAL "ADDITIONAL_FILES")
            if (additional_files_target_dir)
                RTT_PKG_REGISTER_FILES(${name} ${additional_files_target_dir} ${additional_files})
            endif()

            unset(in_targets)
            unset(additional_files_target_dir)
            unset(additional_files)
            set(in_additional_files True)
        else()
            if (in_targets)
                list(APPEND ARG_TARGETS ${ARG})
            elseif (in_additional_files)
                if (additional_files_target_dir)
                    list(APPEND additional_files ${ARG})
                else()
                    set(additional_files_target_dir ${ARG})
                endif()
            else()
                message(FATAL_ERROR "Syntax Error calling RTT_ARTIFACT - error parsing ${ARG} (arguments: ${ARG_UNPARSED_ARGUMENTS})")
            endif()
        endif()
    endforeach()

    if (additional_files_target_dir)
        RTT_PKG_REGISTER_FILES(${name} ${additional_files_target_dir} ${additional_files})
    endif()

    foreach(TARGET_IT ${ARG_TARGETS})
      if(NOT RTT_INTERNAL_${TARGET_IT}_TYPE)
        message(WARNING "Artifact target " ${TARGET_IT} " is not an RTT_TARGET")
      endif()
      RTT_PKG_REGISTER_TARGET(${name} ${TARGET_IT})
    endforeach()

    if(EXISTS "${PROJECT_SOURCE_DIR}/dependency_versions.config")
        # project-specific dependency_versions overrides top-level one
        RTT_PKG_REGISTER_FILES(${name} . "${PROJECT_SOURCE_DIR}/dependency_versions.config")
    elseif(RTT_DEPENDENCY_VERSIONS)
        RTT_PKG_REGISTER_FILES(${name} . "${RTT_DEPENDENCY_VERSIONS}")
    endif()
    
    if(EXISTS "${PROJECT_SOURCE_DIR}/artifact_aliases.config")
        # project-specific artifact_aliases overrides top-level one
        RTT_PKG_REGISTER_FILES(${name} . "${PROJECT_SOURCE_DIR}/artifact_aliases.config")
    elseif (RTT_ARTIFACT_ALIASES)
        RTT_PKG_REGISTER_FILES(${name} . "${RTT_ARTIFACT_ALIASES}")
    endif()

    # dependencies per target
    unset(TARGET_DEPENDENCIES)

    if (ARG_CMAKE)
        foreach(TARGET ${ARG_TARGETS})
            #message(STATUS "Creating finder for ${TARGET}")
            # ARTIFACT_LIBS_DEBUG
            # ARTIFACT_LIBS_RELEASE
            # ARTIFACT_BINARIES_DEBUG
            # ARTIFACT_BINARIES_RELEASE
            # ARTIFACT_DEPENDENCIES
            set(ARTIFACT_NAME ${TARGET})
            # message(STATUS "Dependencies: ${ARTIFACT_DEPENDENCIES}")

            # TODO: STATIC / SHARED LIBRARIES
            get_target_property(ARTIFACT_BINARIES_DEBUG ${TARGET} LOCATION_DEBUG)
            get_target_property(ARTIFACT_BINARIES_RELEASE ${TARGET} LOCATION_Release)
            get_filename_component(ARTIFACT_BINARIES_DEBUG ${ARTIFACT_BINARIES_DEBUG} NAME)
            get_filename_component(ARTIFACT_BINARIES_RELEASE ${ARTIFACT_BINARIES_RELEASE} NAME)
            get_target_property(TARGET_DEBUG_POSTFIX ${TARGET} DEBUG_POSTFIX)
            # message(STATUS "${TARGET} DEBUG_POSTFIX: ${TARGET_DEBUG_POSTFIX}")

            set(ARTIFACT_LIBS_DEBUG ${TARGET}${TARGET_DEBUG_POSTFIX})
            set(ARTIFACT_LIBS_RELEASE ${TARGET})

            __get_global_target_var(ARTIFACT_TYPE ${TARGET} TYPE)
            __get_global_target_var(ARTIFACT_DEFINES ${TARGET} DEFINES)
            __get_global_target_var(ARTIFACT_DEPENDENCIES ${TARGET} DEPENDS)
            __get_global_target_var(ARTIFACT_RUNTIME_DEPENDENCIES ${TARGET} RUNTIME_DEPENDENCIES)

            # message(STATUS "Location: ${ARTIFACT_BINARIES_DEBUG} / ${ARTIFACT_BINARIES_RELEASE}")

            if( MSVC )
                # set_target_properties(${name} PROPERTIES IMPORT_SUFFIX "${LIBSTRING}.lib")
                get_target_property(LIB_IMPORT_SUFFIX ${TARGET} IMPORT_SUFFIX )
            else()
                set(LIB_IMPORT_SUFFIX "")
            endif()
            if (NOT LIB_IMPORT_SUFFIX)
                set(LIB_IMPORT_SUFFIX "")
            endif()
            # message(STATUS "lib import suffix: ${LIB_IMPORT_SUFFIX} ")


            configure_file("${RTT_CMAKE_TOOLS_ROOT}/GenericLibraryFinder.in" "${CMAKE_BINARY_DIR}/artifact-${name}/rtt_${TARGET}.cmake" @ONLY)
            RTT_PKG_REGISTER_FILES(${name} . "${CMAKE_BINARY_DIR}/artifact-${name}/rtt_${TARGET}.cmake")

            list(APPEND TARGET_DEPENDENCIES ${ARTIFACT_DEPENDENCIES} "---")
        endforeach()
        # RTT_PKG_REGISTER_FILES(${name} . ${ARG_CMAKE})

        execute_process(
            COMMAND
                ${PYTHON_EXECUTABLE} ${RTT_CMAKE_PYTHON_TOOLS_ROOT}/solve_dependencies.py
                    "${ARG_TARGETS}"
                    "${TARGET_DEPENDENCIES}"

            OUTPUT_VARIABLE
                SOLVED_DEPENDENCIES
        )
        separate_arguments(SOLVED_DEPENDENCIES)

        # uses SOLVED_DEPENDENCIES
        set(ARTIFACT_NAME ${name})
        configure_file("${RTT_CMAKE_TOOLS_ROOT}/GenericCMakeLists.in" "${CMAKE_BINARY_DIR}/artifact-${name}/CMakeLists.txt" @ONLY)
        RTT_PKG_REGISTER_FILES(${name} . "${CMAKE_BINARY_DIR}/artifact-${name}/CMakeLists.txt")
    endif()

    set(ARTIFACT_VERSION)
    if(ARG_VERSION)
        set(ARTIFACT_VERSION ${ARG_VERSION})
    else()
        if (EXISTS "${CMAKE_CURRENT_SOURCE_DIR}/artifact_version.config")
            message(STATUS "Loading artifact version from ${CMAKE_CURRENT_SOURCE_DIR}/artifact_version.config")
            unset(ARTIFACT_VERSION_PREFIX CACHE)
            unset(ARTIFACT_VERSION_MAJOR CACHE)
            unset(ARTIFACT_VERSION_MINOR CACHE)
            unset(ARTIFACT_VERSION_SUFFIX CACHE)

            __RTT_READ_PROPERTIES_FILE("${CMAKE_CURRENT_SOURCE_DIR}/artifact_version.config" "ARTIFACT_VERSION_" IMPORTED_KEYS)
            SET(ARTIFACT_VERSION "${ARTIFACT_VERSION_MAJOR}.${ARTIFACT_VERSION_MINOR}" )
            if(ARTIFACT_VERSION_PREFIX)
                set(ARTIFACT_VERSION ${ARTIFACT_VERSION_PREFIX}.${ARTIFACT_VERSION} )
            endif()
            if(ARTIFACT_VERSION_SUFFIX)
                set(ARTIFACT_VERSION ${ARTIFACT_VERSION}.${ARTIFACT_VERSION_SUFFIX} )
            endif()
            message( STATUS "Creating ARTIFACT VERSION ${ARTIFACT_VERSION}" )
        else()
            message(FATAL_ERROR "${CMAKE_CURRENT_SOURCE_DIR}/artifact_version.config not exist")
        endif()
    endif()

    if(ARG_NO_PUBLIC_HEADERS)
        RTT_PKG_FINALIZE_TO_ARTIFACT(${name} ${ARTIFACT_VERSION} NO_PUBLIC_HEADERS)
    else()
        RTT_PKG_FINALIZE_TO_ARTIFACT(${name} ${ARTIFACT_VERSION})
    endif()

    add_dependencies(PKG_${name} ${ARG_TARGETS})

endfunction()


#
# RTT_INSTALL( name
#   VERSION ...
#   [TARGET_FILES <targetdir> ...]
#   [NO_PUBLIC_HEADERS]

function (RTT_INSTALL name)
    cmake_parse_arguments(ARG "CMAKE;NO_PUBLIC_HEADERS" "VERSION" "" ${ARGN})

    RTT_PKG_CREATE(${name} "${CMAKE_BINARY_DIR}/artifact-${name}" SKIP_DEPENDENCIES BINDIR bin LIBDIR lib)

    unset(in_additional_files)
    unset(arg_is_glob_expression)
    unset(ARG_TARGETS)
    # files are flushed when encountering a TARGET_FILES in the arg list,
    # so add one to the end that will flush the final bunch of files
    list(APPEND ARG_UNPARSED_ARGUMENTS "TARGET_FILES")
    foreach(ARG ${ARG_UNPARSED_ARGUMENTS})
        if((ARG STREQUAL "TARGET_FILES") OR (ARG STREQUAL "TARGET_FILES_GLOB"))
            if (additional_files_target_dir)
                RTT_PKG_REGISTER_FILES(${name} ${additional_files_target_dir} ${additional_files})
            endif()

            unset(additional_files_target_dir)
            unset(additional_files)
            if(ARG STREQUAL "TARGET_FILES_GLOB")
                set(arg_is_glob_expression TRUE)
            else()
                set(arg_is_glob_expression FALSE)
            endif()
            set(in_additional_files True)
        else()
            if (in_additional_files)
                if (NOT additional_files_target_dir)
                    # first argument is the target directory
                    set(additional_files_target_dir ${ARG})
                else()
                    # subsequent arguments are files/glob expressions
                    if(arg_is_glob_expression)
                        file(GLOB globbed_files ${ARG})
                        list(APPEND additional_files ${globbed_files})
                    else()
                        list(APPEND additional_files ${ARG})
                    endif()
                endif()
            else()
                message(FATAL_ERROR "Syntax Error calling RTT_INSTALL - error parsing ${ARG} (arguments: ${ARG_UNPARSED_ARGUMENTS})")
            endif()
        endif()
    endforeach()
    if(ARG_NO_PUBLIC_HEADERS)
        RTT_PKG_FINALIZE_TO_ARTIFACT(${name} ${ARG_VERSION} NO_PUBLIC_HEADERS)
    else()
        RTT_PKG_FINALIZE_TO_ARTIFACT(${name} ${ARG_VERSION})
    endif()
endfunction()

#
# RTT_TEST( name
#   [BOOST.TEST | UNITTEST++ | PYUNIT] - type of the test
#   [NO_COPY] - prevents copying of PYUNIT source script; used for scripts generated at CMake configure time
#   INCLUDES ...
#   DEPENDS ...
#   SOURCES ...
#   CUSTOM_TARGET...
#

function (RTT_TEST name)
    if(NOT RTT_SKIP_ALL_TESTS)
        RTT_TEST_impl(${ARGV})
    endif(NOT RTT_SKIP_ALL_TESTS)
endfunction()

function (RTT_TEST_impl name)
    parse_arguments(ARG "SOURCES;HEADERS;DEPENDS;INCLUDES;RESOURCES;DEFINES;PRIVATE_DEFINES;PCH;FOLDER;TEST_ARGUMENTS;RUNTIME_DEPENDENCIES;CUSTOM_TARGET;TEST_SUITE;"
        "BOOST.TEST;UNITTEST++;PYUNIT;DISABLED;LEAK_CHECK_DISABLED;NO_COPY" ${ARGN})

    if (ARG_TEST_SUITE)
        set(ctest_test_name "${name}.${ARG_TEST_SUITE}_test")
        set(test_suites ${RTT_TEST_SUITE_LIST})
        list(APPEND test_suites ${ARG_TEST_SUITE})
        list(REMOVE_DUPLICATES test_suites)
        set(RTT_TEST_SUITE_LIST ${test_suites} CACHE "" INTERNAL)
    else()
        set(ctest_test_name "${name}.test")
    endif()

    if (ARG_BOOST.TEST)
        set(test_name "${name}")
        __RTT_TARGET(${test_name} EXECUTABLE
            SOURCES ${ARG_SOURCES}
            HEADERS ${ARG_HEADERS}
            DEPENDS ${ARG_DEPENDS} boost-test
            INCLUDES ${ARG_INCLUDES}
            PCH ${ARG_PCH}
            FOLDER ${ARG_FOLDER}
            RUNTIME_DEPENDENCIES ${ARG_RUNTIME_DEPENDENCIES}
            DEFINES ${ARG_DEFINES}
            PRIVATE_DEFINES ${ARG_PRIVATE_DEFINES}
        )

        # get output directory of target
        set(location)
        get_target_property(location ${name} LOCATION)

        set(targetdir)
        get_filename_component(targetdir "${location}" PATH)

        # create a RUNTIME package which consists of the test target
        # and has a dependency on it
        if (MSVC OR ARG_RESOURCES)
            RTT_PKG_CREATE("RUNTIME_${name}" "${targetdir}" TARGETNAME "ZZ_RUNTIME_${name}" BINDIR "." LIBDIR "." AS_POSTBUILD ${name})
        endif()

        if (MSVC)
            RTT_PKG_REGISTER_TARGET("RUNTIME_${name}" ${name})
        endif()

        foreach(RESOURCE ${ARG_RESOURCES})
            get_filename_component(ABSOLUTE_RESOURCE "${RESOURCE}" ABSOLUTE)
            RTT_PKG_REGISTER_FILES("RUNTIME_${name}" "." ${ABSOLUTE_RESOURCE})
        endforeach()

        if (MSVC OR ARG_RESOURCES)
            RTT_PKG_FINALIZE("RUNTIME_${name}")
            set_target_properties("ZZ_RUNTIME_${name}" PROPERTIES FOLDER "ZZ_Unit Test Runtime Creation")
        endif()

        if (RTT_DEFAULT_TEST_ARGUMENTS)
            string(REPLACE "@TEST_NAME@" "${name}" DEFAULT_TEST_ARGUMENTS ${RTT_DEFAULT_TEST_ARGUMENTS})
        endif()
        if (NOT ARG_DISABLED)
            if (MSVC)
                add_test(NAME ${ctest_test_name}
                         COMMAND ${CMAKE_COMMAND} -E chdir $<TARGET_FILE_DIR:${name}> ${name} ${DEFAULT_TEST_ARGUMENTS} ${ARG_TEST_ARGUMENTS})
            else ()
                add_test(NAME ${ctest_test_name}
                         COMMAND ${CMAKE_COMMAND} -E chdir ${targetdir} ${location} ${DEFAULT_TEST_ARGUMENTS} ${ARG_TEST_ARGUMENTS})
                if (NOT ARG_TEST_SUITE AND ENABLE_MEMORY_LEAK_CHECK) # global enable flag
                    if (NOT ARG_LEAK_CHECK_DISABLED) # disable on test level
                        add_test(NAME ${name}.leak_check
                                 COMMAND ${CMAKE_COMMAND} -E chdir ${targetdir}
                                         ${PYTHON_EXECUTABLE} ${CMAKE_SOURCE_DIR}/tools/valgrind/check_leaks.py -t ${location} -o ${name}.valgrind_output
                        )
                    endif()
                endif()
            endif()
        else ()
            # If the test is disabled we add the command to execute the test as a commandline property
            # to the target in order to run it from anywhere else
            if (MSVC)
                set_target_properties(${test_name} PROPERTIES COMMANDLINE
                   "${CMAKE_COMMAND} -E chdir $<TARGET_FILE_DIR:${name}> ${name} ${DEFAULT_TEST_ARGUMENTS}")
            else ()
                set_target_properties(${test_name} PROPERTIES COMMANDLINE
                   "${CMAKE_COMMAND} -E chdir ${targetdir} ${location} ${DEFAULT_TEST_ARGUMENTS}")
            endif()

        endif ()
    elseif (ARG_UNITTEST++)
        set(test_name "${name}")

        __RTT_TARGET(${name} EXECUTABLE
            SOURCES ${ARG_SOURCES}
            HEADERS ${ARG_HEADERS}
            DEPENDS ${ARG_DEPENDS} unittest++
            INCLUDES ${ARG_INCLUDES}
            PCH ${ARG_PCH}
            FOLDER ${ARG_FOLDER}
            RUNTIME_DEPENDENCIES ${ARG_RUNTIME_DEPENDENCIES}
            DEFINES ${ARG_DEFINES} "-DUNITTEST_NAME=${name}"
            PRIVATE_DEFINES ${ARG_PRIVATE_DEFINES}
        )

        set(location)
        get_target_property(location ${name} LOCATION)

        set(targetdir)
        get_filename_component(targetdir "${location}" PATH)

        # create a RUNTIME package which consists of the test target
        # and has a dependency on it
        if (MSVC OR ARG_RESOURCES)
            RTT_PKG_CREATE("RUNTIME_${name}" "${targetdir}" TARGETNAME "ZZ_RUNTIME_${name}" BINDIR "." LIBDIR "." AS_POSTBUILD ${name})
        endif()

        if(MSVC)
            RTT_PKG_REGISTER_TARGET("RUNTIME_${name}" ${name})
        endif()

        foreach(RESOURCE ${ARG_RESOURCES})
            get_filename_component(ABSOLUTE_RESOURCE "${RESOURCE}" ABSOLUTE)
            RTT_PKG_REGISTER_FILES("RUNTIME_${name}" "." ${ABSOLUTE_RESOURCE})
        endforeach()

        if (MSVC OR ARG_RESOURCES)
            RTT_PKG_FINALIZE("RUNTIME_${name}")
            set_target_properties("ZZ_RUNTIME_${name}" PROPERTIES FOLDER "ZZ_Unit Test Runtime Creation")
        endif()

        if (NOT ARG_DISABLED)
            if (MSVC)
                add_test(NAME ${ctest_test_name} COMMAND ${CMAKE_COMMAND} -E chdir $<TARGET_FILE_DIR:${name}> ${name} ${ARG_TEST_ARGUMENTS})
            else ()
                add_test(NAME ${ctest_test_name} COMMAND ${CMAKE_COMMAND} -E chdir ${targetdir} ${location} ${ARG_TEST_ARGUMENTS})
            endif()
        else()
            # If the test is disabled we add the command to execute the test as a commandline property
            # to the target in order to run it from anywhere else
            if (MSVC)
                set_target_properties(${name} PROPERTIES COMMANDLINE
                   "${CMAKE_COMMAND} -E chdir $<TARGET_FILE_DIR:${name}> ${name}")
            else ()
                set_target_properties(${name} PROPERTIES COMMANDLINE
                   "${CMAKE_COMMAND} -E chdir ${targetdir} ${location}")
            endif()
        endif ()
    elseif (ARG_PYUNIT)
        get_filename_component(abs_python_file "${ARG_SOURCES}" ABSOLUTE)
        get_filename_component(python_file "${ARG_SOURCES}" NAME)

        set(targetdir ${CMAKE_CURRENT_BINARY_DIR})

        if(NOT ARG_NO_COPY)
            message(STATUS "RTT-PYUNIT-TEST: copy ${abs_python_file} to ${targetdir}/${python_file}")
            # create a target which copies the python files mentioned in SOURCES to the output folder
            ADD_CUSTOM_COMMAND(
                    OUTPUT "${targetdir}/${python_file}"
                    COMMAND ${SHELL_COMMENT} IncrediBuild_AllowOverlap
                    COMMAND ${CMAKE_COMMAND} -E copy ${abs_python_file} ${targetdir}
                    DEPENDS "${abs_python_file}"
            )
        endif()
        ADD_CUSTOM_TARGET(${name} ALL DEPENDS "${targetdir}/${python_file}" ${ARG_DEPENDS})

        if (NOT ARG_DISABLED)
            # create the test
            add_test(NAME ${ctest_test_name} COMMAND ${PYTHON_EXECUTABLE} ${targetdir}/${name} ${ARG_TEST_ARGUMENTS})
        else()
            set_target_properties(${name} PROPERTIES COMMANDLINE "${PYTHON_EXECUTABLE} ${targetdir}/${name}")
        endif ()

        if (ARG_RESOURCES OR ARG_DEPENDS)
            RTT_PKG_CREATE("RUNTIME_${name}" "${targetdir}" TARGETNAME "ZZ_RUNTIME_${name}" BINDIR "." LIBDIR "." AS_POSTBUILD ${name})
        endif()

        foreach(RESOURCE ${ARG_RESOURCES})
            get_filename_component(ABSOLUTE_RESOURCE "${RESOURCE}" ABSOLUTE)
            RTT_PKG_REGISTER_FILES("RUNTIME_${name}" "." ${ABSOLUTE_RESOURCE})
        endforeach()

        foreach(DEPENDENCY ${ARG_DEPENDS})
            RTT_PKG_REGISTER_TARGET("RUNTIME_${name}" ${DEPENDENCY})
        endforeach()

        if (ARG_RESOURCES OR ARG_DEPENDS)
            RTT_PKG_FINALIZE("RUNTIME_${name}")
            set_target_properties("ZZ_RUNTIME_${name}" PROPERTIES FOLDER "ZZ_Unit Test Runtime Creation")
        endif()
    else()
        message(FATAL "Unknown test type ${name} : ${ARGN}")
    endif()

    if(ARG_CUSTOM_TARGET)
        # create the build target
        if(NOT TARGET ${ARG_CUSTOM_TARGET})
            # message("creating test custom target ${ARG_CUSTOM_TARGET}...")
            add_custom_target(${ARG_CUSTOM_TARGET} COMMAND cd . )
        endif()
        add_dependencies(${ARG_CUSTOM_TARGET} ${name})

        # create the RUN target
        if(NOT TARGET RUN_${ARG_CUSTOM_TARGET})
            # message("creating test custom target ${ARG_CUSTOM_TARGET}...")
            add_custom_target(RUN_${ARG_CUSTOM_TARGET} COMMAND cd . )
        endif()
        add_custom_target( RUN_${name}  COMMAND cd . )
        add_custom_command(TARGET RUN_${name}
            POST_BUILD
            COMMAND ${CMAKE_CTEST_COMMAND} --force-new-ctest-process -I ${name} -C $(Configuration) -VV --timeout 1500
            )
        # message( "adding test ${name} to ${ARG_CUSTOM_TARGET}")
        add_dependencies(RUN_${name} ${name})
        add_dependencies(RUN_${ARG_CUSTOM_TARGET} RUN_${name})
    endif()
endfunction()

# RTT_PERFORMANCE_TEST
#
# Similar to RTT_TEST creates a test target which automatically creates a runtime target as postbuild step
# and (optional) links to the known test frameworks. But in contrast to the unit test target this
# target is not executed using the automatically created test target. Furthermore another target RUN_PERFORMANCE_TESTS
# or performance_test is created where these tests are registered automatically.
#
# This is due to performance tests taking really long sometimes which makes developers not executing tests
# when doing local builds.

function (RTT_PERFORMANCE_TEST name)
    # Create the target like a normal unit test but disable it which prevents automatic execution
    RTT_TEST(${name} TEST_SUITE performance ${ARGN})
endfunction()

# RTT_FINALIZE_PERFORMANCE_TESTS
#
# Creates a target which runs all the previously registered performance tests. If no tests have been registered so far
# there's no need to create such a target

function (RTT_FINALIZE_PERFORMANCE_TESTS)
    # we need escaping here else the '.' will be considered as 'any' character in regex
    if(MSVC)
        set(UNIT_TEST_REGEX "\\.test")
    else()
        set(UNIT_TEST_REGEX "\\\\.test")
    endif(MSVC)

    if (MSVC11)
        set(ctest_configuration "$(Configuration)")
    else()
        set(ctest_configuration "$(OutDir)")
    endif()

    add_custom_target(RUN_UNIT_TESTS
        COMMAND ${CMAKE_CTEST_COMMAND} --force-new-ctest-process -R ${UNIT_TEST_REGEX} -C ${ctest_configuration}
        COMMENT "Executing Unit Tests"
    )
    add_custom_target(RUN_LEAK_CHECKS
        COMMAND ${CMAKE_CTEST_COMMAND} --force-new-ctest-process -R .leak_check -C ${ctest_configuration}
        COMMENT "Executing Leak Checks"
    )
    foreach(test_suite ${RTT_TEST_SUITE_LIST})
        message(STATUS "Adding test suite '" ${test_suite} "'")
        string(TOUPPER ${test_suite} test_suite_upper)
        add_custom_target(RUN_${test_suite_upper}_TESTS
            COMMAND ${CMAKE_CTEST_COMMAND} --force-new-ctest-process -R .${test_suite}_test -C ${ctest_configuration}
            COMMENT "Executing ${test_suite} Tests"
        )
    endforeach()
    unset(RTT_TEST_SUITE_LIST CACHE)
endfunction()

function(RTT_SET_COMMON_COMPILER_FLAGS)
    parse_arguments(ARG "" "EMBED_DEBUG_INFO_IN_OBJECT_FILES" ${ARGN})
    set(RTT_CONFIG_EMBED_DEBUG_INFO_IN_OBJECT_FILES ${ARG_EMBED_DEBUG_INFO_IN_OBJECT_FILES} CACHE INTERNAL "" FORCE)
    IF (MSVC)
        ADD_DEFINITIONS(-D_SCL_SECURE_NO_WARNINGS)
        ADD_DEFINITIONS(-DWIN32_LEAN_AND_MEAN)
        ADD_DEFINITIONS(-D_WIN32_WINNT=0x601)   # target Windows 7 and higher
        ADD_DEFINITIONS(/W4)
        SET( TREAT_WARNINGS_AS_ERRORS TRUE CACHE BOOL "Warnings treated as errors" )
        IF( TREAT_WARNINGS_AS_ERRORS )
            ADD_DEFINITIONS(/WX)
        ENDIF()
        ADD_DEFINITIONS(/wd4503) # C4503: 'decorated name length exceeded'
        ADD_DEFINITIONS(/wd4505) # C4505: ''...': unreferenced local function has been removed'
        ADD_DEFINITIONS(/wd4714) # C4714: ''...' marked as __forceinline not inlined

        set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} /bigobj" PARENT_SCOPE)
        if(NOT RTT_CONFIG_EMBED_DEBUG_INFO_IN_OBJECT_FILES)
            set(CMAKE_CXX_FLAGS_DEBUG "/D_DEBUG /MDd /Zi /Ob0 /Od" PARENT_SCOPE)
        else()
            set(CMAKE_CXX_FLAGS_DEBUG "/D_DEBUG /MDd /Z7 /Ob0 /Od" PARENT_SCOPE)
            set(CMAKE_CXX_FLAGS_RELWITHDEBINFO "${CMAKE_CXX_FLAGS_RELWITHDEBINFO} /Z7" PARENT_SCOPE)
        endif()
    ELSE()
        ADD_DEFINITIONS(-DLINUX)
        SET(COMMON_CXX_FLAGS
            "-Wall -Wextra -Werror -Wunreachable-code -Wshadow -Wmissing-declarations -Wredundant-decls -Wswitch-default -Wswitch-enum -Wfloat-equal -Wundef -Wconversion -Wp,-Wunused-macros -Wl,--warn-common -pthread")
        # for non-msvc compilers, we still want the _DEBUG define for debug builds
        SET(CMAKE_CXX_FLAGS_DEBUG "${CMAKE_CXX_FLAGS_DEBUG} -g -D_DEBUG -gdwarf-2 -gstrict-dwarf ${COMMON_COMPILER_FLAGS} -pthread" CACHE STRING "" FORCE)
        SET(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} ${COMMON_COMPILER_FLAGS} -gdwarf-2 -gstrict-dwarf -pthread" CACHE STRING "" FORCE)
        SET(CMAKE_EXE_LINKER_FLAGS "${CMAKE_EXE_LINKER_FLAGS} -pthread -lrt -Wl,-rpath,'\$ORIGIN'" CACHE STRING "" FORCE)
        SET(CMAKE_SHARED_LINKER_FLAGS "${CMAKE_SHARED_LINKER_FLAGS} -pthread -lrt -Wl,-rpath,'\$ORIGIN'" CACHE STRING "" FORCE)
    ENDIF ()
endfunction()

# Initialize
__RTT_INIT()


# RTT_SET_UTILITY_PROJECT
#
# This can be called in from a project file with the project name as parameter when the project does not
# produce a linkable library and can't be linked to other projects. But by setting this it's still possible for
# other projects to have a dependency to this project.

function (RTT_SET_UTILITY_PROJECT name)
    SET(RTT_UTILITY_PROJECT_${name} ON CACHE BOOL "Utility project" FORCE)
endfunction()


# RTT_ENABLE_LINK_TIME_CODE_GENERATION
#
# This enables link time code generation for Release and ReleaseWithDebInfo configurations in visual studio
# for the given target.
# Can be globally switched off by setting 'ENABLE_LINK_TIME_CODE_GENERATION' to 'OFF'.

function(RTT_ENABLE_LINK_TIME_CODE_GENERATION target)
IF (MSVC)
	RTT_ENABLE_LINK_TIME_CODE_GENERATION_RELEASE_ONLY( ${target} )
    if (NOT DISABLE_GLOBAL_LINK_TIME_CODE_GENERATION)
        set_target_properties( ${target}
            PROPERTIES
                LINK_FLAGS_RELWITHDEBINFO "/LTCG" )

        target_compile_options( ${target}
                PRIVATE "$<$<CONFIG:RelWithDebInfo>:/Ox>"
                PRIVATE "$<$<CONFIG:RelWithDebInfo>:/GL>"
                PRIVATE "$<$<CONFIG:RelWithDebInfo>:/Ob2>"
        )
    endif()
endif()
endfunction()

# RTT_ENABLE_LINK_TIME_CODE_GENERATION_RELEASE_ONLY
#
# This enables link time code generation only for Release configurations in visual studio
# for the given target.
# Can be globally switched off by setting 'ENABLE_LINK_TIME_CODE_GENERATION' to 'OFF'.

function(RTT_ENABLE_LINK_TIME_CODE_GENERATION_RELEASE_ONLY target)
IF (MSVC)
    if (NOT DISABLE_GLOBAL_LINK_TIME_CODE_GENERATION)
        set_target_properties( ${target}
            PROPERTIES
                LINK_FLAGS_RELEASE "/LTCG" )

        target_compile_options( ${target}
                PRIVATE "$<$<CONFIG:Release>:/Ox>"
                PRIVATE "$<$<CONFIG:Release>:/GL>"
                PRIVATE "$<$<CONFIG:Release>:/Ob2>"
        )
    endif()
endif()
endfunction()
