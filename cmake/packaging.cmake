#
# RTT_PKG_CREATE package_name targetdir [ build_target_name ]
# 

function(RTT_PKG_CREATE package_name)
	# save properties of this package 
	# XXX still missing targetdir and build_target_name
	set_property(GLOBAL PROPERTY PKG_${package_name} TRUE)

	# register package in a list of packages
	set_property(GLOBAL APPEND PROPERTY PKG_ALL_REGISTERED_PACKAGES "${package_name}")
endfunction()

#
# files may be specialized by "debug ; ... ; optimized ; ..."
# 

function(RTT_PGK_REGISTER_FILES package_name targetdir files)
	set(package_exists)
	get_property(package_exists GLOBAL PKG_${package_name})

	if (package_exists) 
		set_property(GLOBAL APPEND PROPERTY PKG_${package_name}_FILES "DIRECTORY")
		set_property(GLOBAL APPEND PROPERTY PKG_${package_name}_FILES "${targetdir}")
		set_property(GLOBAL APPEND PROPERTY PKG_${package_name}_FILES "${files}")
		mark_as_advanced(PKG_${package_name}_FILES)
	else()
		message(FATAL " added file to package ${package_name} but package does not exist - call PKG_CREATE first")
	endif()
endfunction()

#
# 
#

function(RTT_PKG_FINALIZE package_name)
endfunction()

#
#
#

function(RTT_PKG_FINALIZE_ALL)
endfunction()
