include("python-setup")

# Create an RPM package
#
# RTT_RPM_CREATE(target_name base_directory rpm_version package_version opt_dir)
#
# target_name: name of the target to create
# base_directory: base directory to include
# rpm_version: version of RPM (revision), e.g. "42"
# package_version: RPM package version, e.g. "2.0"
# opt_dir: Optional package RPM additionals directory
#          --> See makerpm.py and e.g. cpp/rpm_stuff/powerhouse/ for examples.

function(RTT_RPM_CREATE target_name base_directory rpm_version package_version opt_dir)

	# Only create RPMs on non-Windows platforms
	if (NOT MSVC)
		add_custom_target(${target_name}
			WORKING_DIRECTORY ${PROJECT_BINARY_DIR}
			COMMAND ${PYTHON_EXECUTABLE} ${PROJECT_SOURCE_DIR}/cmake/makerpm.py ${base_directory} ${rpm_version} ${package_version} ${opt_dir}
			COMMENT "Creating RPM ${target_name}"
		)
	endif()

endfunction()
