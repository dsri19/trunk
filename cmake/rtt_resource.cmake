#
# this adds Windows resource script handling
#
function(RTT_RESOURCE_GENERATE_SCRIPTS)

	if (MSVC)
		unset (ARG_LIBRARY)
		unset (ARG_MAJOR)
		unset (ARG_MINOR)
        unset (ARG_PATCH)
		unset (ARG_RESOURCES)
        unset (ARG_NO_VERSION_SUFFIX)
		parse_arguments(ARG "LIBRARY;MAJOR;MINOR;PATCH;NO_VERSION_SUFFIX;RESOURCES" "" ${ARGN})

		if(NOT DEFINED ARG_MAJOR)
			message(SEND_ERROR "Error: RTT_RESOURCE_GENERATE_SCRIPTS() called without MAJOR parameter")
			return()
		endif()
		if(NOT ARG_MINOR)
			set(ARG_MINOR "0")
		endif()
        set(FILE_VERSION_STRING "${ARG_MAJOR}.${ARG_MINOR}")
        if(ARG_PATCH)
            set(FILE_VERSION_STRING "${ARG_MAJOR}.${ARG_MINOR}.${ARG_PATCH}")
        else(ARG_PATCH)
            set(ARG_PATCH "0")
        endif(ARG_PATCH)
        if (NOT DEFINED ARG_NO_VERSION_SUFFIX)
            set(DLL_VERSION_SUFFIX "_${ARG_MAJOR}")
        endif()

		# Now the version must be placed in a resource file
		# We have a template based one ready to fill in
		set(RESOURCE_FILEDESCRIPTION  "3DEXCITE ${ARG_LIBRARY} Dynamic Link Library")
		set(RESOURCE_FILEVERSION      ${FILE_VERSION_STRING})
		set(RESOURCE_FILEVERSION_BIN  "${ARG_MAJOR},${ARG_MINOR},${ARG_PATCH},0")
		set(RESOURCE_COMPANYNAME      "Dassault Systemes 3DExcite GmbH")
		set(RESOURCE_INTERNALNAME     "${ARG_LIBRARY}")
		set(RESOURCE_ORIGINALFILENAME "${ARG_LIBRARY}${DLL_VERSION_SUFFIX}.dll")
		configure_file(${CMAKE_SOURCE_DIR}/cmake/resource_template.in ${CMAKE_CURRENT_BINARY_DIR}/${ARG_LIBRARY}.rc)
		configure_file(${CMAKE_SOURCE_DIR}/cmake/resource.h ${CMAKE_CURRENT_BINARY_DIR}/resource.h COPYONLY)

		# Now add the generated resource files to the library project
		set(${ARG_RESOURCES} ${CMAKE_CURRENT_BINARY_DIR}/${ARG_LIBRARY}.rc ${CMAKE_CURRENT_BINARY_DIR}/resource.h PARENT_SCOPE)
		
	endif(MSVC)

endfunction()
