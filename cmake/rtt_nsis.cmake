include("python-setup")

# Call NSIS to create an NSIS installer which combines all the
# files in a given directory
#
# RTT_NSIS_CREATE(target_name nsis_name base_directory)
#
# target_name: name of the target to create
# nsis_name: where to find the nsis configuration file
# base_directory: base directory to include

function(RTT_NSIS_CREATE target_name nsis_name base_directory)

	# creating installers is only possible on Windows machines
	if (MSVC)
		# check for the NSIS executable
		find_program(MakeNSIS_PROGRAM "makensis.exe" PATHS "C:\\Programme\\NSIS" "C:\\Program Files\\NSIS" "C:\\Program Files (x86)\\NSIS")
	
		message(STATUS "Currently this one copies defines.nsh hardcoded")
		get_filename_component(nsis_basedir "${nsis_name}" PATH)
		get_filename_component(nsis_filename "${nsis_name}" NAME)

		add_custom_target(${target_name}
			WORKING_DIRECTORY ${PROJECT_BINARY_DIR}

			COMMAND ${PYTHON_EXECUTABLE} ${PROJECT_SOURCE_DIR}/cmake/gen_list_files_for_nsis.py ${base_directory}
			COMMAND ${PYTHON_EXECUTABLE} ${PROJECT_SOURCE_DIR}/cmake/gen_platform_name.py ${MSVC_PLATFORM_NAME}

			# we also have to copy the NSI-File and all if its includes here
			COMMAND ${CMAKE_COMMAND} -E echo "Copy ${nsis_name} to ${PWH_BINARY_DIR}"
			COMMAND ${CMAKE_COMMAND} -E copy ${nsis_name} ${PWH_BINARY_DIR}

			COMMAND ${CMAKE_COMMAND} -E echo "Copy ${nsis_basedir}/defines.nsh to ${PWH_BINARY_DIR}"
			COMMAND ${CMAKE_COMMAND} -E copy ${nsis_basedir}/defines.nsh ${PWH_BINARY_DIR}

			COMMAND ${CMAKE_COMMAND} -E echo "Running NSIS on ${nsis_filename}"
			COMMAND ${MakeNSIS_PROGRAM} /X"SetCompressor /FINAL /SOLID lzma" ${nsis_filename}

			COMMENT "Creating NSIS installer ${target_name} - based on ${nsis_name}"
		)
	endif ()

endfunction()
