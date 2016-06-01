# http://www.cmake.org/Wiki/CMakeMacroListOperations#LIST_CONTAINS
macro(LIST_CONTAINS var value)
  SET(${var})
  FOREACH (value2 ${ARGN})
    IF (${value} STREQUAL ${value2})
      SET(${var} TRUE)
    ENDIF (${value} STREQUAL ${value2})
  ENDFOREACH (value2)
endmacro(LIST_CONTAINS)

# Own macros
macro (__set_global_var NAME VALUE DESCRIPTION)
	set(${NAME} "${VALUE}" CACHE INTERNAL "${DESCRIPTION}" FORCE)
endmacro()

macro (__get_global_var OUTPUT NAME)
	set(${OUTPUT} ${${NAME}})
endmacro()

macro (__set_global_target_var TARGET NAME VALUE DESCRIPTION)
	__set_global_var( "RTT_INTERNAL_${TARGET}_${NAME}" "${VALUE}" "${DESCRIPTION}" )
endmacro()

macro (__get_global_target_var OUTPUT TARGET NAME)
	set(${OUTPUT} ${RTT_INTERNAL_${TARGET}_${NAME}})
endmacro()

if(WIN32)
	set(SHELL_COMMENT "rem")
else(WIN32)
	set(SHELL_COMMENT "true")
endif(WIN32)

function (__RTT_READ_PROPERTIES_FILE name prefix OUTPUT_LIST)
	parse_arguments(ARG "REPORT_CONFLICTS" "" ${ARGN})
	unset(ENTRIES)
	unset(ENTRY)
	unset(KEYLIST)
	unset(CONFLICTS)
	
	file(STRINGS "${name}" ENTRIES)
	message(STATUS "Reading properties from ${name} - prefix: ${prefix}")
	
	foreach (ENTRY ${ENTRIES})
		string(FIND "${ENTRY}" "=" POS)
		string(SUBSTRING "${ENTRY}" 0 ${POS} KEY)
		math(EXPR NPOS "${POS} + 1")
		string(SUBSTRING "${ENTRY}" ${NPOS} -1 VALUE)
		

    # Replace Variable References like ${EXA_SPECIAL_VERSION} in a version string with
    # the proper variable values
    # Unfortunately I could not find a better regex which is non-greedy within the {}
    # So currently you are allowed to refer a single variable only
    while("${VALUE}" MATCHES "\\\${(.+)}")
      # If we find a regex which is non greedy within the {} please remove this check
      string(FIND ${CMAKE_MATCH_1} "{" TEMPVAR)
      if (TEMPVAR GREATER "-1")
         message(FATAL_ERROR "You may refer to only one variable within a key-value pair only: ${KEY} --> ${VALUE} (${TEMPVAR})")
      endif()

      string(REPLACE "\${${CMAKE_MATCH_1}}" "${${CMAKE_MATCH_1}}" VALUE "${VALUE}")
    endwhile()

    if(${prefix}${KEY})
      # we already have a value of that name
      if(NOT (${${prefix}${KEY}} STREQUAL ${VALUE}))
        # new value differs from existing one
        list(APPEND CONFLICTS " " ${KEY})
        message(STATUS "OLD: ${${prefix}${KEY}} - NEW: ${VALUE}")
      endif()
		else()
 		  message(STATUS "PROP: ${KEY} = ${VALUE}")
		  set(${prefix}${KEY} CACHE INTERNAL "Value read from property file" FORCE)
		  set(${prefix}${KEY} "${VALUE}" CACHE INTERNAL "Value read from property file")
		endif()
		
		list(APPEND KEYLIST "${KEY}")
	endforeach ()
	set(${OUTPUT_LIST} ${KEYLIST} PARENT_SCOPE)
	if(ARG_REPORT_CONFLICTS)
	  set(${ARG_REPORT_CONFLICTS} ${CONFLICTS} PARENT_SCOPE)
	endif()
endfunction ()

#
# split a filelist 
#

macro (__split_configuration_dependant_filelist PREFIX)
	set(INPUT ${ARGN})

#	message(STATUS "split configuration dependant filelist - INPUT = ${INPUT}")

	set (${PREFIX}_IN_DEBUG)
	set (${PREFIX}_IN_RELEASE)

	set (${PREFIX})
	set (${PREFIX}_RELEASE)
	set (${PREFIX}_DEBUG)

	foreach (item ${INPUT})
		string(TOUPPER "${item}" UPPER_ITEM)
		string(COMPARE EQUAL "${UPPER_ITEM}" "DEBUG" IN_DEBUG)
		string(COMPARE EQUAL "${UPPER_ITEM}" "OPTIMIZED" IN_RELEASE)

		if (IN_RELEASE) 
			set (${PREFIX}_IN_RELEASE TRUE)
			set (${PREFIX}_IN_DEBUG FALSE)
		elseif (IN_DEBUG)
			set (${PREFIX}_IN_DEBUG TRUE)
			set (${PREFIX}_IN_RELEASE FALSE)
		else()
			if (${PREFIX}_IN_RELEASE) 
				list(APPEND ${PREFIX}_RELEASE ${item})
			elseif (${PREFIX}_IN_DEBUG)
				list(APPEND ${PREFIX}_DEBUG ${item})
			else()
				list(APPEND ${PREFIX} ${item})
			endif()
		endif()
	endforeach()

#	message(STATUS "default: ${${PREFIX}}")
#	message(STATUS "release: ${${PREFIX}_RELEASE}")
#	message(STATUS "debug  : ${${PREFIX}_DEBUG}")
endmacro()

function (__record_dependencies name)
	set (total_dependencies ${RTT_INTERNAL_${name}_TOTAL_DEPENDENCIES})
	if (total_dependencies)
		return ()
	endif()

	#message(STATUS "__record_dependencies(${name})")

	set (total_dependencies)
	set (dependencies ${RTT_INTERNAL_${name}_DEPENDS})

	if (dependencies)
		foreach(item ${dependencies})
			__record_dependencies(${item})

			set (item_dependencies ${RTT_INTERNAL_${item}_TOTAL_DEPENDENCIES})
			if (item_dependencies)
				list(APPEND total_dependencies ${item_dependencies})
			endif()
			list(APPEND total_dependencies ${item})
		endforeach()
	endif()

	if (total_dependencies)
		list(REMOVE_DUPLICATES total_dependencies)
		set(RTT_INTERNAL_${name}_TOTAL_DEPENDENCIES "${total_dependencies}" CACHE INTERNAL "total dependencies of ${name}")
	endif()
endfunction()

# we have a python tool to create the pch.hpp and pch.cpp

include("python-setup")

# Instructs the MSVC toolset to use the precompiled header PRECOMPILED_HEADER
# for each source file given in the collection named by SOURCE_VARIABLE_NAME.

function (enable_precompiled_headers PRECOMPILED_HEADERS SOURCE_VARIABLE_NAME PCH_HEADER PCH_SOURCE PROJECT_NAME)
	if (MSVC)
		set (files ${${SOURCE_VARIABLE_NAME}})
		set (pcheaders ${${PRECOMPILED_HEADERS}})

		# If CMAKE_PCH_PATH is set, use that path to locate the pch files.
		# Also, use the project name as prefix in the name of pch.cpp and pch.hpp.
		if (CMAKE_PCH_PATH)
			set (pch_path ${CMAKE_PCH_PATH})
			set (pch_prefix ${PROJECT_NAME}_)
		else ()
			set (pch_path lib/pch)
			set (pch_prefix "")
		endif (CMAKE_PCH_PATH)

		# Generate precompiled header translation unit
		set (pch_unity ${CMAKE_CURRENT_BINARY_DIR}/${pch_prefix}pch.cpp)
		set (pch_abs ${CMAKE_CURRENT_BINARY_DIR}/${pch_prefix}pch.hpp)

		# create a list of files this one depends on
		set (deps)
		foreach (dep ${pcheaders})
			get_filename_component(dep_base ${dep} NAME)
			get_filename_component(dep_abs "${PROJECT_SOURCE_DIR}/${pch_path}/${dep_base}" ABSOLUTE)

			list(APPEND deps ${dep_abs})
		endforeach ()

		message(STATUS "RTT-PCH: dependencies ${deps}")
		message(STATUS "RTT-PCH: output ${pch_abs}")
		message(STATUS "RTT-PCH: output ${pch_unity}")

		# register a command which creates the pch-files
		add_custom_command(
			OUTPUT ${pch_prefix}pch.hpp ${pch_prefix}pch.cpp
			COMMAND ${PYTHON_EXECUTABLE} 
			ARGS ${PROJECT_SOURCE_DIR}/cmake/create_pch_files.py ${pch_unity} ${pch_abs} "${PROJECT_SOURCE_DIR}/${pch_path}" ${pcheaders}
			DEPENDS ${deps}
			COMMENT "Recreating PCH files - including ${deps}"
		)

		set_source_files_properties (${pch_unity}  PROPERTIES COMPILE_FLAGS "/Yc\"${pch_abs}\"")

		# Update properties of source files to use the precompiled header.
		# Additionally, force the inclusion of the precompiled header at beginning of each source file.
		foreach (source_file ${files})
			set_source_files_properties (
				${source_file}
				PROPERTIES COMPILE_FLAGS
				"/Yu\"${pch_abs}\" /FI\"${pch_abs}\""
				)
		endforeach (source_file)

		set(${PCH_HEADER} ${pch_abs} PARENT_SCOPE)
		set(${PCH_SOURCE} ${pch_unity} PARENT_SCOPE)
	endif (MSVC)
endfunction (enable_precompiled_headers)

function(RTT_COPY_FILE_TO_BIN_DIR targetname filename )

	get_filename_component( filename_without_path ${filename} NAME )

	ADD_CUSTOM_COMMAND( 
		TARGET ${targetname}
		POST_BUILD
		COMMAND ${SHELL_COMMENT} IncrediBuild_AllowOverlap
		COMMAND ${CMAKE_COMMAND} -E echo "copy ${filename} to ${EXECUTABLE_OUTPUT_PATH}/$(Configuration)/${filename_without_path}"
		COMMAND ${CMAKE_COMMAND} -E copy_if_different ${filename} ${EXECUTABLE_OUTPUT_PATH}/$(Configuration)/${filename_without_path}
		COMMENT "copy ${filename} to ${EXECUTABLE_OUTPUT_PATH}/$(Configuration)/${filename_without_path}"
	)

endfunction(RTT_COPY_FILE_TO_BIN_DIR)

# following taken from http://stackoverflow.com/questions/2368811/how-to-set-warning-level-in-cmake
macro(SET_WARNINGLEVEL level)
	if(MSVC)
	  # Force to always compile with W4
	  if(CMAKE_CXX_FLAGS MATCHES "/W[0-4]")
		string(REGEX REPLACE "/W[0-4]" "/W${level}" CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS}")
	  else()
		set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} /W4")
	  endif()
	endif()
endmacro()

macro(ENABLE_TREAT_WARNINGS_AS_ERRORS)
	if(MSVC)
	  # Force to treat all warnings as errors
	  if(CMAKE_CXX_FLAGS MATCHES "/WX-")
		string(REGEX REPLACE "/WX-" "/WX" CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS}")
	  elseif(NOT CMAKE_CXX_FLAGS MATCHES "/WX")
		set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} /WX")
	  endif()
	endif()
endmacro()