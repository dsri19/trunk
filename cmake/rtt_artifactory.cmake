# For the artifacts we want to have some kind of alias mechanism
#
# e.g. the boost-filesystem library is part of the boost artifact because
# we do not want to have an artifact for each of the boost libraries including
# the headers and so on
#
# So the boost artifact registers all the contained dependencies automatically
# on download and we resolve boost-filesystem to download the boost artifact
#
# These aliases are configured by
#
# RTT_NSYS_ALIAS_boost-filesystem=boost
#
# variables which are read in RTT_INIT() from artifact_aliases.config

function (__SAVE_ADD_SUBDIRECTORY
    __directory__           # Directory Location
    __internal_path__       # Internal Location in the Project
    __protection_variable__ # Variable to protect this inclusion - will be deleted at the next CMake run
)

    __get_global_var(already_included_items SAVE_ADD_SUBDIRECTORY_ITEMS)
    DEBUG("Already included items = ${already_included_items}")
    
    LIST_CONTAINS(already_included ${__internal_path__} ${already_included_items})
    if (NOT already_included)
        list(APPEND already_included_items "${__internal_path__}")
        __set_global_var(SAVE_ADD_SUBDIRECTORY_ITEMS "${already_included_items}" "Automatically added subdirectories")
        DEBUG("Already included items = ${tmp}")
        
        add_subdirectory(${__directory__} ${__internal_path__})
        
        __get_global_var(tmp SAVE_ADD_SUBDIRECTORY_PROTECTION_VARIABLES)
        list(APPEND tmp "${__protection_variable__}")
        __set_global_var(SAVE_ADD_SUBDIRECTORY_PROTECTION_VARIABLES "${tmp}" "Variables used to protect subdirectory inclusions")
    endif()
endfunction ()

function (__RTT_ARTIFACTORY_HANDLE_ALIAS name OUTVAR)
    if (RTT_NSYS_ALIAS_${name})
        # message(STATUS "alias(${name}) = ${RTT_NSYS_ALIAS_${name}}")
        set(${OUTVAR} ${RTT_NSYS_ALIAS_${name}} PARENT_SCOPE)
    else()
        set(${OUTVAR} ${name} PARENT_SCOPE)
    endif()
endfunction()

function (__rtt_read_dependency_properties dependency_versions_file artifact_aliases_file)
    if(dependency_versions_file)
        message(STATUS "Loading dependency versions from ${dependency_versions_file}")
        __RTT_READ_PROPERTIES_FILE("${dependency_versions_file}" "RTT_NSYS_VERSION_" IMPORTED_KEYS REPORT_CONFLICTS conflicts)
        if(conflicts)
            foreach(conflict ${conflicts})
                message(STATUS "Version conflict ${conflict} (is: ${RTT_NSYS_VERSION_${conflict}})")
                unset(RTT_NSYS_VERSION_${conflict} CACHE)
            endforeach()
            unset(RTT_INTERNAL_INCLUDING_ARTIFACT_${name} CACHE)
            message(FATAL_ERROR "Dependency conflicts: " ${conflicts} " from artifact ${name} requested an incompatible artifact version")
        endif()
    endif()
    if(artifact_aliases_file)
        message(STATUS "Loading aliases from ${artifact_aliases_file}")
        __RTT_READ_PROPERTIES_FILE("${artifact_aliases_file}" "RTT_NSYS_ALIAS_" IMPORTED_KEYS)
        # Now, for any of the read aliases try to find out if we already have such an artifact
        # If so, this should be used - it is not allowed to "overwrite" an artifact which is
        # already loaded
        foreach(imported ${IMPORTED_KEYS})
            if (ARTIFACT_${imported}_ROOT)
                message(WARNING "It is not allowed to overwrite the already imported artifact ${imported} with an alias - Skipping new alias ${RTT_NSYS_ALIAS_${imported}}")
                unset(RTT_NSYS_ALIAS_${imported} CACHE)
            endif()
        endforeach()
    endif()
endfunction()

function (__RTT_ARTIFACTORY_GET raw_name)
    # Handle alias
    set(name ${raw_name})
    __RTT_ARTIFACTORY_HANDLE_ALIAS(${name} "name")
    DEBUG("ALIAS(${raw_name}) = ${name}")
    
    # Check version
    if (NOT RTT_NSYS_VERSION_${name})
        #message(FATAL_ERROR "Dependency ${name}: No version configured")
    endif()

    if((NOT RTT_INTERNAL_${name}_TYPE) AND (NOT RTT_INTERNAL_INCLUDING_ARTIFACT_${name}))
        set(RTT_INTERNAL_INCLUDING_ARTIFACT_${name} TRUE CACHE INTERNAL "")
        
        if((EXISTS ${RTT_NSYS_VERSION_${name}}) AND (EXISTS "${RTT_NSYS_VERSION_${name}}/CMakeLists.txt"))
            message(STATUS "Artifact found locally at " ${RTT_NSYS_VERSION_${name}})

            if(EXISTS "${RTT_NSYS_VERSION_${name}}/dependency_versions.config")
                set(versions_file "${RTT_NSYS_VERSION_${name}}/dependency_versions.config")
            elseif(EXISTS "${RTT_NSYS_VERSION_${name}}/BC/dependency_versions.config")
                set(versions_file "${RTT_NSYS_VERSION_${name}}/BC/dependency_versions.config")
            elseif(EXISTS "${RTT_NSYS_VERSION_${name}}/.build/dependency_versions.config")
                set(versions_file "${RTT_NSYS_VERSION_${name}}/.build/dependency_versions.config")
            else()
                message(FATAL_ERROR "Unable to locate dependency_versions.config for local artifact ${RTT_NSYS_VERSION_${name}}")
            endif()
            if(EXISTS "${RTT_NSYS_VERSION_${name}}/artifact_aliases.config")
                set(alias_file "${RTT_NSYS_VERSION_${name}}/artifact_aliases.config")
            elseif(EXISTS "${RTT_NSYS_VERSION_${name}}/BC/artifact_aliases.config")
                set(alias_file "${RTT_NSYS_VERSION_${name}}/BC/artifact_aliases.config")
            elseif(EXISTS "${RTT_NSYS_VERSION_${name}}/.build/artifact_aliases.config")
                set(alias_file "${RTT_NSYS_VERSION_${name}}/.build/artifact_aliases.config")
            else()
                message(FATAL_ERROR "Unable to locate artifact_aliases.config for local artifact ${RTT_NSYS_VERSION_${name}}")
            endif()
            __rtt_read_dependency_properties(${versions_file} ${alias_file})
              
            set(ARTIFACT_${name}_ROOT ${RTT_NSYS_VERSION_${name}} CACHE INTERNAL "Root of ${name} binary artifact")
            __SAVE_ADD_SUBDIRECTORY(${RTT_NSYS_VERSION_${name}} "${CMAKE_BINARY_DIR}/${name}" RTT_INTERNAL_${name}_TYPE)
            set(RTT_NSYS_${name}_BUILD_LOCAL TRUE CACHE INTERNAL "Artifact ${name} is built locally")
            if(NOT (raw_name STREQUAL name))
                set(RTT_NSYS_${raw_name}_BUILD_LOCAL TRUE CACHE INTERNAL "Artifact ${raw_name} is built locally")
            endif()
        else()
            unset(ARTIFACTORY_SEARCH_LIST)
            if ( RTT_NSYS_VERSION_${name} )
                list(APPEND ARTIFACTORY_SEARCH_LIST
                    "${name}-${RTT_PLATFORM_NAME}-${RTT_COMPILER_NAME}-${RTT_NSYS_VERSION_${name}}"
                    "${name}-${RTT_PLATFORM_NAME}-${RTT_NSYS_VERSION_${name}}"
                    "${name}-${RTT_NSYS_VERSION_${name}}"
                )
                
                rtt_determine_artifactory_temp_dir()
                
                if(NOT EXISTS "${ARTIFACTORY_TEMP_DIR}")
                    file(MAKE_DIRECTORY ${ARTIFACTORY_TEMP_DIR})
                endif()
                
                if(NOT EXISTS "${ARTIFACTORY_TEMP_DIR}")
                    message(FATAL_ERROR "Failed to create temporary directory ${ARTIFACTORY_TEMP_DIR}")
                endif()
                
                message(STATUS "Artifactory temporary directory: ${ARTIFACTORY_TEMP_DIR}")
                
                set(ARTIFACTORY_TARGET_DIR "${ARTIFACTORY_TEMP_DIR}")
                
                message(STATUS "ARTIFACTORY - searching for ${name} - ${ARTIFACTORY_SEARCH_LIST}")
                
        
                if (NOT DISABLE_ARTIFACTORY_SERVER)
                    set (ACCESS_SERVER_ARG "true")
                else()
                    set (ACCESS_SERVER_ARG "false")
                endif()
                
                if (NOT ARTIFACTORY_REPOSITORY)
                    set (ARTIFACTORY_REPOSITORY "http://art01.rtt.local/artifactory")
                endif()

                unset(DESTDIR)
                execute_process(COMMAND
                    ${PYTHON_EXECUTABLE}
                        ${RTT_CMAKE_PYTHON_TOOLS_ROOT}/fetch_artifact.py
                        ${ACCESS_SERVER_ARG}
                        ${ARTIFACTORY_TARGET_DIR}
                        ${ARTIFACTORY_TEMP_DIR}
                        ${ARTIFACTORY_REPOSITORY}
                        ${ARTIFACTORY_SEARCH_LIST}
                    OUTPUT_VARIABLE DESTDIR
                    RESULT_VARIABLE FETCH_ERRORS
                    ERROR_VARIABLE FETCH_ERROR_MESSAGES
                )
                if(NOT (FETCH_ERRORS EQUAL 0))
                    message(WARNING "Error while trying to fetch artifact " ${name} ": " ${FETCH_ERROR_MESSAGES})
                endif()

                string(STRIP "${DESTDIR}" DESTDIR)
                if (NOT DESTDIR)
                    message("Unresolved dependency: ${raw_name}")
                else()
                    message(STATUS "GOT: ${DESTDIR}")
                endif()

                if((NOT DEFINED DESTDIR) OR (NOT EXISTS ${DESTDIR}))
                    #message(FATAL_ERROR "Unable to fetch matching artifact for '" ${name} "'")
                else()
                    # load dependencies
                    if (EXISTS "${DESTDIR}/dependency_versions.config")
                        set(versions_file "${DESTDIR}/dependency_versions.config")
                    else()
                      set(versions_file FALSE)
                    endif()
                    if (EXISTS "${DESTDIR}/artifact_aliases.config")
                        set(alias_file "${DESTDIR}/artifact_aliases.config")
                    else()
                        set(alias_file FALSE)
                    endif()
                    __rtt_read_dependency_properties(${versions_file} ${alias_file})

                    set(ARTIFACT_${name}_ROOT ${DESTDIR} CACHE INTERNAL "Root of ${name} binary artifact")
                    add_subdirectory(${DESTDIR} "dependency/${name}")
                    
                    if(NOT RTT_INTERNAL_${name}_TYPE)
                        set(RTT_INTERNAL_${name}_TYPE ARTIFACT_ALIAS CACHE INTERNAL "")
                    endif()
                endif()
            endif()
        endif()
        unset(RTT_INTERNAL_INCLUDING_ARTIFACT_${name} CACHE)

    endif()
endfunction ()

# The functions below are used for retrieving files from the artifactory server without consulting the version or alias mechanism

# Fetches a file from artifactory.
#  ARTIFACT_DESCRIPTION String description of the artifact to be used in log messages
#  ARTIFACT_URL full URL to the file on the artifactory server.
#  ARCHIVE_TARGET_PATH path and filename where to save the downloaded artifact.
function(rtt_artifactory_fetch_artifact ARTIFACT_DESCRIPTION ARTIFACT_URL ARCHIVE_TARGET_PATH)
    message(STATUS "Fetching ${ARTIFACT_DESCRIPTION} artifact file from " ${ARTIFACT_URL})
    string(REPLACE "\\" "\\\\" ARCHIVE_TARGET_PATH_ESCAPED "${ARCHIVE_TARGET_PATH}")
    execute_process(
        COMMAND ${PYTHON_EXECUTABLE}
          ${RTT_CMAKE_PYTHON_TOOLS_ROOT}/fetch_file_from_artifactory.py
          "${ARTIFACT_URL}"
          "${ARCHIVE_TARGET_PATH_ESCAPED}"
        ERROR_VARIABLE FETCH_ERRORS
      )
      if (FETCH_ERRORS)
        execute_process(COMMAND ${CMAKE_COMMAND} -E remove ${ARCHIVE_TARGET_PATH})
        message(FATAL_ERROR "Failed to fetch ${ARTIFACT_DESCRIPTION} artifact file: ${FETCH_ERRORS}")
      endif()
endfunction()

# Extracts a local artifact archive file to a local directory.
#  ARTIFACT_DESCRIPTION String description of the artifact to be used in log messages
#  ARCHIVE_PATH path to a local artifact archive file.
#  TARGET_PATH path where to extract the archive artifact to.
function(rtt_artifactory_extract_artifact_archive ARTIFACT_DESCRIPTION ARCHIVE_PATH TARGET_PATH)
    execute_process(COMMAND ${CMAKE_COMMAND} -E remove_directory ${TARGET_PATH})

    message(STATUS "Unzipping ${ARTIFACT_DESCRIPTION} artifact file to ${TARGET_PATH}")
    string(REPLACE "\\" "\\\\" ARCHIVE_PATH_ESCAPED "${ARCHIVE_PATH}")
    execute_process(COMMAND ${CMAKE_COMMAND} -E make_directory ${TARGET_PATH})
    if(ARCHIVE_PATH MATCHES ".zip$")
        if(WIN32)
            execute_process(COMMAND
                ${PYTHON_EXECUTABLE}
                    ${RTT_CMAKE_PYTHON_TOOLS_ROOT}/unzip.py
                    ${ARCHIVE_PATH_ESCAPED}
                    ${TARGET_PATH}
                ERROR_VARIABLE FETCH_ERROR_MESSAGES
            )
        else(WIN32)
            execute_process(
                    COMMAND ${PYTHON_EXECUTABLE} -c "from subprocess import call; call(['unzip', '-q', '-o', '${ARCHIVE_PATH_ESCAPED}', '-d', '${TARGET_PATH}']);"
                    WORKING_DIRECTORY ${RTT_CMAKE_DIR}
                    ERROR_VARIABLE UNZIP_ARTIFACT_ERRORS
            )
        endif(WIN32)
    else()
        execute_process(
            COMMAND ${CMAKE_COMMAND} -E tar xzf ${ARCHIVE_PATH_ESCAPED}
            WORKING_DIRECTORY ${TARGET_PATH}
            ERROR_VARIABLE UNZIP_ARTIFACT_ERRORS
        )
    endif()
    if (UNZIP_ARTIFACT_ERRORS)
        message(FATAL_ERROR "Failed to extract ${ARTIFACT_DESCRIPTION}: ${UNZIP_ARTIFACT_ERRORS}")
    endif()
endfunction()

# Fetches a file from artifactory and extracts it to a local directory.
# The artifact will only be fetched if it does not exist on disk.
# The artifact will only be extracted if it is newer than the files that are already on disk.
#  ARTIFACT_DESCRIPTION String description of the artifact to be used in log messages
#  ARTIFACT_URL full URL to the file on the artifactory server.
#  ARCHIVE_TARGET_PATH path and filename where to save the downloaded artifact.
#  EXTRACT_TARGET_PATH path where to extract the downloaded artifact to.
function(rtt_artifactory_fetch_and_extract ARTIFACT_DESCRIPTION ARTIFACT_URL ARCHIVE_TARGET_PATH EXTRACT_TARGET_PATH)
    if(NOT EXISTS ${ARCHIVE_TARGET_PATH})
        rtt_artifactory_fetch_artifact(${ARTIFACT_DESCRIPTION} ${ARTIFACT_URL} ${ARCHIVE_TARGET_PATH})
        set(WAS_FETCHED TRUE)
    else()
        message(STATUS "Using existing ${ARTIFACT_DESCRIPTION} artifact ${ARCHIVE_TARGET_PATH}")
        set(WAS_FETCHED FALSE)
    endif()
    if(WAS_FETCHED OR (${ARCHIVE_TARGET_PATH} IS_NEWER_THAN "${EXTRACT_TARGET_PATH}/.artifact_timestamp"))
        rtt_artifactory_extract_artifact_archive(${ARTIFACT_DESCRIPTION} ${ARCHIVE_TARGET_PATH} ${EXTRACT_TARGET_PATH})
        execute_process(COMMAND ${CMAKE_COMMAND} -E touch "${EXTRACT_TARGET_PATH}/.artifact_timestamp")
    else()
        message(STATUS "Artifact ${ARTIFACT_DESCRIPTION} target directory ${EXTRACT_TARGET_PATH} is up-to-date.")
    endif()
endfunction()

# sets ARTIFACTORY_TEMP_DIR variable,
# depending on ARTIFACTORY_DIR_OVERRIDE and ARTIFACTORY_DIR or TMPDIR environment variables
function(rtt_determine_artifactory_temp_dir)
	if (NOT  ARTIFACTORY_DIR_OVERRIDE )
		if (DEFINED ENV{ARTIFACTORY_DIR})
			file(TO_CMAKE_PATH "$ENV{ARTIFACTORY_DIR}" ARTIFACTORY_TEMP_DIR_HELPER )
			set(ARTIFACTORY_TEMP_DIR ${ARTIFACTORY_TEMP_DIR_HELPER} PARENT_SCOPE )
		else (DEFINED ENV{ARTIFACTORY_DIR})
			if (NOT TMPDIR)
				if (WIN32)
					file (TO_CMAKE_PATH "$ENV{TEMP}" TMPDIR)
				else()
					set(TMPDIR "$ENV{TMPDIR}")
				endif()
			endif()

			if(NOT EXISTS "${TMPDIR}")
				message(FATAL_ERROR "Temp directory ${TMPDIR} does not exist.")
			endif()

			# Artifactory TEMP DIR
			set(ARTIFACTORY_TEMP_DIR "${TMPDIR}/artifactory" PARENT_SCOPE )
		endif (DEFINED ENV{ARTIFACTORY_DIR})
	else()
		set(ARTIFACTORY_TEMP_DIR "${ARTIFACTORY_DIR_OVERRIDE}" PARENT_SCOPE )
	endif()
endfunction()                

