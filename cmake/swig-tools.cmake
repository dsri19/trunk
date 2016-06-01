if (NOT SWIG_EXECUTABLE)
	# message("fetching swig artefact...")
	__RTT_ARTIFACTORY_GET(swig)
endif()

if (NOT SWIG_EXECUTABLE)
	message(FATAL_ERROR "Failed to load and initialize swig properly - SWIG_EXECUTABLE missing")
endif()

#
# macro to run swig
# OUTPUT_FILE - generated files
# INPUT_FILE - swig interface file
# MODULE_NAME - name of script module
# PARAMS - swig command line params
# ADDITIONAL_DEPENDS - additional input dependencies

macro( RTT_SWIG OUTPUT_FILES INPUT_FILE MODULE_NAME )
	set(${OUTPUT_FILES})
  cmake_parse_arguments(ARG  "" "" "PARAMS;ADDITIONAL_DEPENDS" ${ARGN} )

	set(filename_we)
	get_filename_component(filename_we ${INPUT_FILE} NAME_WE)

	set(full_name)
	get_filename_component(full_name ${INPUT_FILE} ABSOLUTE)

	set(output_cpp_file "${CMAKE_CURRENT_BINARY_DIR}/${filename_we}.cpp")
	
	set(output_python_file "${CMAKE_CURRENT_BINARY_DIR}/${MODULE_NAME}.py")

	# message("inputfile: ${INPUT_FILE}" )
	# message("ARG_PARAMS: ${ARG_PARAMS}")
	# message("ARG_ADDITIONAL_DEPENDS: ${ARG_ADDITIONAL_DEPENDS}")
	
	list( APPEND ${OUTPUT_FILES} ${output_cpp_file} ${output_python_file} )
	 
	add_custom_command(
		OUTPUT ${${OUTPUT_FILES}}
		COMMAND ${SWIG_EXECUTABLE} ${ARG_PARAMS} -outdir ${CMAKE_CURRENT_BINARY_DIR} -o ${output_cpp_file} ${full_name}
		COMMENT "Swigging ${INPUT_FILE}"
		DEPENDS ${ARG_ADDITIONAL_DEPENDS}
		MAIN_DEPENDENCY ${INPUT_FILE}
 	)
	
	set_source_files_properties(${${OUTPUT_FILES}} PROPERTIES GENERATED TRUE)
	
endmacro()

