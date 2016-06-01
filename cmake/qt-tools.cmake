if (NOT QT_MOC)
	__RTT_ARTIFACTORY_GET(qt)
endif()

if (NOT QT_MOC)
	message(FATAL_ERROR "Failed to load and initialize Qt properly - QT_MOC missing")
endif()

if(WIN32)
	set(SHELL_COMMENT "rem")
else(WIN32)
	set(SHELL_COMMENT "true")
endif(WIN32)

#
# macro to run the Meta Object Compiler (moc)
#

macro(RTT_QT_MOC output)
	set(${output})

	foreach(item ${ARGN})
		# get filename without ending to construct output file
		set(filename_we)
		get_filename_component(filename_we ${item} NAME_WE)

		set(full_name)
		get_filename_component(full_name ${item} ABSOLUTE)

		set(output_file "${CMAKE_CURRENT_BINARY_DIR}/${filename_we}.moc.cpp")

		add_custom_command(
			OUTPUT ${output_file}
			COMMAND ${SHELL_COMMENT} IncrediBuild_AllowOverlap
			COMMAND ${SHELL_COMMENT} IncrediBuild_AllowRemote
			COMMAND ${SHELL_COMMENT} IncrediBuild_OutputFile ${output_file}
			COMMAND ${QT_MOC} ARGS -o ${output_file} ${full_name}
			DEPENDS ${QT_MOC} ${full_name}
			COMMENT "Running Qt Meta Object Compiler on ${item}"
			VERBATIM
		)

		set_source_files_properties(${output_file} PROPERTIES GENERATED TRUE)

		list(APPEND ${output} ${output_file})
	endforeach()
endmacro()

#
# macro to run the Resource Compiler (rcc)
#

macro(RTT_QT_RCC output)
	set(${output})

	foreach(item ${ARGN})
		# get filename without ending to construct output file
		set(filename_we)
		get_filename_component(filename_we ${item} NAME_WE)

		set(full_name)
		get_filename_component(full_name ${item} ABSOLUTE)

		set(output_file "${CMAKE_CURRENT_BINARY_DIR}/${RTT_QT_RCC_PREFIX}${filename_we}.rcc.cpp")

		add_custom_command(
			OUTPUT ${output_file}
			COMMAND ${SHELL_COMMENT} IncrediBuild_AllowOverlap
			COMMAND ${SHELL_COMMENT} IncrediBuild_AllowRemote
			COMMAND ${SHELL_COMMENT} IncrediBuild_OutputFile ${output_file}
			COMMAND ${QT_RCC} ARGS -name ${filename_we} -o ${output_file} ${full_name}
			DEPENDS ${QT_RCC} ${full_name}
			COMMENT "Running Qt Resource Compiler on ${item}"
			VERBATIM
		)

		set_source_files_properties(${output_file} PROPERTIES GENERATED TRUE)

		list(APPEND ${output} ${output_file})
	endforeach()
endmacro()

macro(RTT_QT_RCC_SINGLE_FILE output_file input_file)
	cmake_parse_arguments(ARG  "" "" "ADDITIONAL_DEPENDS" ${ARGN} )

	# get filename without ending to construct output file
	set(filename_we)
	get_filename_component(filename_we ${input_file} NAME_WE)

	set(full_name)
	get_filename_component(full_name ${input_file} ABSOLUTE)

	set(rcc_file "${CMAKE_CURRENT_BINARY_DIR}/${RTT_QT_RCC_PREFIX}${filename_we}.rcc.cpp")

	add_custom_command(
		OUTPUT ${rcc_file}
		COMMAND ${SHELL_COMMENT} IncrediBuild_AllowOverlap
		COMMAND ${SHELL_COMMENT} IncrediBuild_AllowRemote
		COMMAND ${SHELL_COMMENT} IncrediBuild_OutputFile ${output_file}
		COMMAND ${QT_RCC} ARGS -name ${filename_we} -o ${rcc_file} ${full_name}
		DEPENDS ${QT_RCC} ${full_name} ${ARG_ADDITIONAL_DEPENDS}
		COMMENT "Running Qt Resource Compiler on ${item}"
		VERBATIM
	)
	
	set_source_files_properties(${rcc_file} PROPERTIES GENERATED TRUE)	
	
	set(${output_file} ${rcc_file})
endmacro()

#
# macro to run the UI Compiler (uic)
#

macro(RTT_QT_UIC output)
	set(${output})

	foreach(item ${ARGN})
		# get filename without ending to construct output file
		set(filename_we)
		get_filename_component(filename_we ${item} NAME_WE)

		set(full_name)
		get_filename_component(full_name ${item} ABSOLUTE)

		set(output_file "${CMAKE_CURRENT_BINARY_DIR}/${filename_we}.uic.hpp")

		add_custom_command(
			OUTPUT ${output_file}
			COMMAND ${SHELL_COMMENT} IncrediBuild_AllowOverlap
			COMMAND ${SHELL_COMMENT} IncrediBuild_AllowRemote
			COMMAND ${SHELL_COMMENT} IncrediBuild_OutputFile ${output_file}
			COMMAND ${QT_UIC} ARGS -o ${output_file} ${full_name}
			DEPENDS ${QT_UIC} ${full_name}
			COMMENT "Running Qt UI Compiler on ${item}"
			VERBATIM
		)

		set_source_files_properties(${output_file} PROPERTIES GENERATED TRUE)

		list(APPEND ${output} ${output_file})
	endforeach()
endmacro()
