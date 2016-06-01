#
# uses the following global variables
#
# PKG_name - package exists
# PKG_name_OPTIONS - [AS_POSTBUILD target]
# PKG_name_TARGETDIR - output directory
# PKG_name_LIBDIR
# PKG_name_BINDIR
# PKG_name_TARGETNAME - name of the build target
# PKG_name_TARGETS - targets to include
# PKG_name_FILES - files to install
# PKG_name_NSIS - nsi file to create an nsis installer
#
# PKG_ALL_REGISTERED_PACKAGES - list of all registered packages

include("rtt_utilities")
include("rtt_nsis")
include("rtt_rpm")

#
# RTT_PKG_CREATE package_name targetdir [ TARGETNAME build_target_name ] [ BINDIR bindir ] [ LIBDIR libdir ] [ AS_POSTBUILD target | PACKAGE_EXECUTABLE target ] [ SKIP_DEPENDENCIES ]
#
# If SKIP_DEPENDENCIES is set no dependencies for the registered targets are resolved automatically
#

function(RTT_PKG_CREATE package_name targetdir)
    parse_arguments(ARG "TARGETNAME;BINDIR;LIBDIR;AS_POSTBUILD;PACKAGE_EXECUTABLE" "SKIP_DEPENDENCIES" ${ARGN})

    # save properties of this package
    set_property(GLOBAL PROPERTY PKG_${package_name} TRUE)
    set_property(GLOBAL PROPERTY PKG_${package_name}_TARGETDIR "${targetdir}")

    if (ARG_TARGETNAME)
        set_property(GLOBAL PROPERTY PKG_${package_name}_TARGETNAME "${ARG_TARGETNAME}")
    else()
        set_property(GLOBAL PROPERTY PKG_${package_name}_TARGETNAME "PKG_${package_name}")
    endif()

    if (ARG_BINDIR)
        set_property(GLOBAL PROPERTY PKG_${package_name}_BINDIR "${ARG_BINDIR}")
    else()
        set_property(GLOBAL PROPERTY PKG_${package_name}_BINDIR "bin")
    endif()

    if (ARG_LIBDIR)
        set_property(GLOBAL PROPERTY PKG_${package_name}_LIBDIR "${ARG_LIBDIR}")
    else()
        if (MSVC)
            set_property(GLOBAL PROPERTY PKG_${package_name}_LIBDIR "bin")
        else ()
            set_property(GLOBAL PROPERTY PKG_${package_name}_LIBDIR "lib")
        endif()
    endif()

    if (ARG_SKIP_DEPENDENCIES)
        set_property(GLOBAL PROPERTY PKG_${package_name}_SKIP_DEPENDENCIES "True")
    endif()

    if (ARG_AS_POSTBUILD)
        set_property(GLOBAL PROPERTY PKG_${package_name}_OPTIONS "AS_POSTBUILD;${ARG_AS_POSTBUILD}")
    endif()
    if (ARG_PACKAGE_EXECUTABLE)
        set_property(GLOBAL PROPERTY PKG_${package_name}_OPTIONS "PACKAGE_EXECUTABLE;${ARG_PACKAGE_EXECUTABLE}")
    endif()

    # register package in a list of packages
    set_property(GLOBAL APPEND PROPERTY PKG_ALL_REGISTERED_PACKAGES "${package_name}")
endfunction()

#
# add a target to a package
#
# RTT_PKG_REGISTER_TARGET(package_name target)
#

function(RTT_PKG_REGISTER_TARGET package_name target)
    set(package_exists)
    get_property(package_exists GLOBAL PROPERTY PKG_${package_name})

    if (package_exists)
        set_property(GLOBAL APPEND PROPERTY PKG_${package_name}_TARGETS "${target}")
    else()
        message(FATAL " added target to package ${package_name} but package does not exist - call PKG_CREATE first")
    endif()
endfunction()

#
# files may be specialized by "debug ; ... ; optimized ; ..."
#

function(RTT_PKG_REGISTER_FILES package_name targetdir)
    set(package_exists)
    get_property(package_exists GLOBAL PROPERTY PKG_${package_name})

#   message(STATUS "RTT_PKG_REGISTER_FILES(${package_name},${targetdir}) - ${ARGN}")

    if (package_exists)
        set_property(GLOBAL APPEND PROPERTY PKG_${package_name}_FILES "DIRECTORY")
        set_property(GLOBAL APPEND PROPERTY PKG_${package_name}_FILES "${targetdir}")
        set_property(GLOBAL APPEND PROPERTY PKG_${package_name}_FILES "${ARGN}")
    else()
        message(FATAL " added file to package ${package_name} but package does not exist - call PKG_CREATE first")
    endif()

#   message(STATUS "${package_name} added: DIRECTORY ${targetdir} ${ARGN}")
endfunction()

#
# analyzes all the targets which belong to a package and creates a filelist
#
# RTT_PKG_ANALYZE_TARGETS(package_name)
#

function(RTT_PKG_ANALYZE_TARGETS package_name)
    parse_arguments(ARG "" "TO_ARTIFACT;NO_PUBLIC_HEADERS" ${ARGN})

    unset(package_exists)
    get_property(package_exists GLOBAL PROPERTY PKG_${package_name})

    if(NOT package_exists)
        message(FATAL " tried to analyze targets belonging to a package which does not exist")
    endif()

    # get target directories
    unset(bindir)
    unset(libdir)
    get_property(bindir GLOBAL PROPERTY PKG_${package_name}_BINDIR)
    get_property(libdir GLOBAL PROPERTY PKG_${package_name}_LIBDIR)

    # create a list of targets to install
    unset(targets)
    get_property(targets GLOBAL PROPERTY PKG_${package_name}_TARGETS)

    # flag if we should skip dependencies of the registered targets
    unset(skip_dependencies)
    get_property(skip_dependencies GLOBAL PROPERTY PKG_${package_name}_SKIP_DEPENDENCIES)

    #message(STATUS "DEBUG - targets to install for ${package_name}: ${targets}")

    unset(total)
    if(${skip_dependencies})
        set(total ${targets})
    else()
        foreach(item ${targets})
            __record_dependencies(${item})

            __get_global_target_var(dependencies ${item} TOTAL_DEPENDENCIES)
            list(APPEND total ${dependencies})

            __get_global_target_var(dependencies ${item} TOTAL_RUNTIME_DEPENDENCIES)
            list(APPEND total ${dependencies})

            list(APPEND total ${item})
        endforeach()
    endif()

    # now we have a list of targets which we must add to the package
    if(total)
        list(REMOVE_DUPLICATES total)

        #message(STATUS "DEBUG - total list of targets to install for ${package_name}: ${total}")
        foreach(item ${total})
            # set target directory depending on type of the target
            set(type ${RTT_INTERNAL_${item}_TYPE})

#           message(STATUS " type(${item}) = ${type}")

            string(COMPARE EQUAL "${type}" "EXECUTABLE" is_executable)
            string(COMPARE EQUAL "${type}" "SHARED_LIBRARY" is_shared_library)
            string(COMPARE EQUAL "${type}" "STATIC_LIBRARY" is_static_library)
            string(COMPARE EQUAL "${type}" "HEADER_ONLY_LIBRARY" is_header_only_library)
            string(COMPARE EQUAL "${type}" "ARTIFACT_ALIAS" is_artifact_alias)

            set(targetdir)
            if (MSVC)
                if (is_executable)
                    set(targetdir "${bindir}")
                elseif (is_static_library)
                    set(targetdir "${libdir}")
                elseif(is_shared_library)
                    set(targetdir "${bindir}")
                elseif(is_artifact_alias)
                elseif(is_header_only_library)
                else()
                    # TODO: handle .lib files as dependencies
                    set(targetdir "${bindir}")
                endif()
            else()
                if(is_executable)
                    set(targetdir "${bindir}")
                elseif(is_shared_library)
                    set(targetdir "${libdir}")
                elseif(is_static_library)
                    set(targetdir "${libdir}")
                elseif(is_artifact_alias)
                elseif(is_header_only_library)
                else()
                    message(WARNING "Build type " ${type} " for target " ${item} " not supported for packaging")
                endif()
            endif()

#           # LOCATION_DEBUG
            set(location)
			set(resources)
            if(TARGET ${item})
                get_target_property(resources ${item} RESOURCE_FILES)
				if( resources )
					# message("RESOURCE_FILES for ${item}: ${resources}")
					foreach(file ${resources})
						# message("Register resource for ${item}: ${file}")
						RTT_PKG_REGISTER_FILES(${package_name} ${targetdir} debug ${file})
						RTT_PKG_REGISTER_FILES(${package_name} ${targetdir} optimized ${file})
						RTT_PKG_REGISTER_FILES(${package_name} ${targetdir} coverage ${file})
						if( MSVC AND ARG_TO_ARTIFACT )
							RTT_PKG_REGISTER_FILES(${package_name} ${targetdir} optimized_with_symbols ${file})
						endif()
					endforeach()
				endif()
				
                get_target_property(location ${item} LOCATION_DEBUG)
                # message(STATUS "LOCATION_DEBUG for ${item}: ${location}")
                if(location AND NOT is_header_only_library)
                    foreach(file ${location})
                        RTT_PKG_REGISTER_FILES(${package_name} ${targetdir} debug ${file})

                        # Add PDB file
                        unset(__NAME_WE)
                        unset(__PATH)
                        get_filename_component(__NAME_WE "${file}" NAME_WE)
                        get_filename_component(__PATH "${file}" PATH)

                        RTT_PKG_REGISTER_FILES(${package_name} ${targetdir} debug "${__PATH}/${__NAME_WE}.pdb")
                        if(MSVC AND ARG_TO_ARTIFACT AND is_shared_library)
                            RTT_PKG_REGISTER_FILES(${package_name} ${libdir} debug "${__PATH}/${__NAME_WE}.lib")
                        endif()
                    endforeach()
                endif()
            endif(TARGET ${item})

            # For artifact builds we always want to include fixed paths to RelWithDebInfo and Release
            # where for "normal" packages we just want to take what the user wants to have (by using the
            # LOCATION property which contains a reference to $(OutDir)
            if (ARG_TO_ARTIFACT)
#               # LOCATION_RelWithDebInfo
                set(location)
                get_target_property(location ${item} LOCATION_RelWithDebInfo)
#               message(STATUS "LOCATION_RelWithDebInfo for ${item}: ${location}")
                if(location AND NOT is_header_only_library)
                    foreach(file ${location})
                        RTT_PKG_REGISTER_FILES(${package_name} ${targetdir} optimized_with_symbols ${file})

                        # Add PDB file
                        unset(__NAME_WE)
                        unset(__PATH)
                        get_filename_component(__NAME_WE "${file}" NAME_WE)
                        get_filename_component(__PATH "${file}" PATH)

                        RTT_PKG_REGISTER_FILES(${package_name} ${targetdir} optimized_with_symbols "${__PATH}/${__NAME_WE}.pdb")
                        if(MSVC AND ARG_TO_ARTIFACT AND is_shared_library)
                            RTT_PKG_REGISTER_FILES(${package_name} ${libdir} optimized_with_symbols "${__PATH}/${__NAME_WE}.lib")
                        endif()
                    endforeach()
                endif()

                # LOCATION_Release
                set(location)
                get_target_property(location ${item} LOCATION_Release)
#               message(STATUS "LOCATION_Release for ${item}: ${location}")
                if(location AND NOT is_header_only_library)
                    foreach(file ${location})
                        RTT_PKG_REGISTER_FILES(${package_name} ${targetdir} optimized ${file})

                        # Add PDB file
                        unset(__NAME_WE)
                        unset(__PATH)
                        get_filename_component(__NAME_WE "${file}" NAME_WE)
                        get_filename_component(__PATH "${file}" PATH)

                        if(MSVC AND ARG_TO_ARTIFACT AND is_shared_library)
                            RTT_PKG_REGISTER_FILES(${package_name} ${libdir} optimized "${__PATH}/${__NAME_WE}.lib")
                        endif()
                    endforeach()
                endif()

                if ( SQUISHCOCO_ENABLED )
                    # LOCATION_Coverage
                    set(location)
                    get_target_property(location ${item} LOCATION_Coverage)
                    if(location AND NOT is_header_only_library)
                        foreach(file ${location})
                            RTT_PKG_REGISTER_FILES(${package_name} ${targetdir} coverage ${file})

                            # Add PDB file
                            unset(__NAME_WE)
                            unset(__PATH)
                            get_filename_component(__NAME_WE "${file}" NAME_WE)
                            get_filename_component(__PATH "${file}" PATH)

                            if(MSVC AND ARG_TO_ARTIFACT AND is_shared_library)
                                RTT_PKG_REGISTER_FILES(${package_name} ${libdir} coverage "${__PATH}/${__NAME_WE}.lib")
                                RTT_PKG_REGISTER_FILES(${package_name} ${libdir} coverage "${__PATH}/${__NAME_WE}.lib.csmes")
                            endif()
                        endforeach()
                    endif()
                endif()
            else()
                if ( SQUISHCOCO_ENABLED )
                    set(location)
                    if(TARGET ${item})
                        get_target_property(location ${item} LOCATION_COVERAGE)
                        # message(STATUS "LOCATION_DEBUG for ${item}: ${location}")
                        if(location AND NOT is_header_only_library)
                            foreach(file ${location})
                                RTT_PKG_REGISTER_FILES(${package_name} ${targetdir} coverage ${file})

                                # Add PDB file
                                unset(__NAME_WE)
                                unset(__PATH)
                                get_filename_component(__NAME_WE "${file}" NAME_WE)
                                get_filename_component(__PATH "${file}" PATH)

                                if(MSVC)
                                    RTT_PKG_REGISTER_FILES(${package_name} ${targetdir} coverage "${__PATH}/${__NAME_WE}.pdb")
                                endif()

                                if(MSVC AND ARG_TO_ARTIFACT AND is_shared_library)
                                    RTT_PKG_REGISTER_FILES(${package_name} ${libdir} coverage "${__PATH}/${__NAME_WE}.lib")
                                    RTT_PKG_REGISTER_FILES(${package_name} ${libdir} coverage "${__PATH}/${__NAME_WE}.lib.csmes")
                                endif()
                            endforeach()
                        endif()
                    endif(TARGET ${item})
                endif()

                # For "normal builds we take the LOCATION property for all non-debug builds
                set(location)
                if(TARGET ${item})
                    get_target_property(location ${item} LOCATION)
                    # message(STATUS "LOCATION_Release for ${item}: ${location}")
                    if(location AND NOT is_header_only_library)
                        foreach(file ${location})
                            RTT_PKG_REGISTER_FILES(${package_name} ${targetdir} optimized ${file})

                            # Add PDB file
                            unset(__NAME_WE)
                            unset(__PATH)
                            get_filename_component(__NAME_WE "${file}" NAME_WE)
                            get_filename_component(__PATH "${file}" PATH)

                            if(MSVC)
                                RTT_PKG_REGISTER_FILES(${package_name} ${targetdir} optimized "${__PATH}/${__NAME_WE}.pdb")
                            endif()

                            if(MSVC AND ARG_TO_ARTIFACT AND is_shared_library)
                                RTT_PKG_REGISTER_FILES(${package_name} ${libdir} optimized "${__PATH}/${__NAME_WE}.lib")
                            endif()
                        endforeach()
                    endif()
                endif(TARGET ${item})
            endif()

            # add public headers
            if(ARG_TO_ARTIFACT AND NOT ARG_NO_PUBLIC_HEADERS)
                get_target_property(public_headers ${item} PUBLIC_HEADERS)
                get_target_property(base_dir ${item} PUBLIC_HEADERS_BASE_DIR)
                get_target_property(no_default_dir ${item} NO_PUBLIC_HEADERS_DEFAULT_DIR)
                file(RELATIVE_PATH generated_files_skip_dir ${base_dir} ${CMAKE_BINARY_DIR})
                if (public_headers)
                    foreach(header_it ${public_headers})
                        get_filename_component(rel_path ${header_it} PATH)
                        # Place generated files in the same relative directory as the original headers
                        string(REPLACE "${generated_files_skip_dir}/" "" rel_path ${rel_path})
                        if(no_default_dir)
                          RTT_PKG_REGISTER_FILES(${package_name} "include/" "${base_dir}/${header_it}")              
                        else()
                          RTT_PKG_REGISTER_FILES(${package_name} "include/${rel_path}" "${base_dir}/${header_it}")
                        endif()
                    endforeach()
                endif()
            endif()

            # IMPORTED_LOCATION
            set(location ${RTT_INTERNAL_${item}_IMPORTED_LOCATION})
#           message(STATUS "IMPORTED_LOCATION(${item}): ${location}")
            if(location AND NOT is_header_only_library)
                RTT_PKG_REGISTER_FILES(${package_name} ${targetdir} ${location})
            endif()

            # IMPORTED_LOCATION (global variable)
            set(location)
            get_property(location GLOBAL PROPERTY ${item}_LOCATION)
#           message(STATUS "IMPORTED_LOCATION (variable): ${location}")
            if(location AND NOT is_header_only_library)
                RTT_PKG_REGISTER_FILES(${package_name} ${targetdir} ${location})
            endif()
        endforeach()
    endif()
endfunction()

#
# Finalize a single package
#

function(RTT_PKG_FINALIZE package_name)
    set(package_exists)
    get_property(package_exists GLOBAL PROPERTY PKG_${package_name})

    if(NOT package_exists)
        message(FATAL" finializing package ${package_name} but package does not exist - call PKG_CREATE first")
    endif()

    set(package_options)
    get_property(package_options GLOBAL PROPERTY PKG_${package_name}_OPTIONS)

    if(package_options)
        parse_arguments(PO "AS_POSTBUILD;PACKAGE_EXECUTABLE" "" ${package_options})
    endif()

    message(STATUS "PACKAGING: finalizing ${package_name}")

    ## get global package settings
    set(targetdir)
    set(targetname)
    get_property(targetdir GLOBAL PROPERTY PKG_${package_name}_TARGETDIR)
    get_property(targetname GLOBAL PROPERTY PKG_${package_name}_TARGETNAME)

    ## analyze added targets and convert them into a filelist
    RTT_PKG_ANALYZE_TARGETS(${package_name})

    ## get list of files
    set(files)
    get_property(files GLOBAL PROPERTY PKG_${package_name}_FILES)
    set(PKG_${package_name}_FILES ${files} CACHE INTERNAL "files belonging to this package")

    if(NOT files)
        message(FATAL " no files to install for package ${package_name}")
    endif()

    set(is_directory)
    set(is_debug)
    set(is_optimized)
    set(in_debug FALSE)
    set(in_optimized FALSE)
    set(in_directory FALSE)

    set(directory)
    set(is_coverage)
    set(in_coverage FALSE)

    set(target_package_dir)
    string(REPLACE $(OutDir) "" target_package_dir ${targetdir})

    set(package_file_debug "${PROJECT_BINARY_DIR}/.debug_${package_name}.pkg")
    set(package_file_release "${PROJECT_BINARY_DIR}/.release_${package_name}.pkg")
    set(package_file_coverage "${PROJECT_BINARY_DIR}/.coverage_${package_name}.pkg")

    unset(package_file_debug_contents)
    unset(package_file_release_contents)
    unset(package_file_coverage_contents)
    foreach(file ${files})
        string(COMPARE EQUAL "${file}" "DIRECTORY" is_directory)
        string(COMPARE EQUAL "${file}" "debug" is_debug)
        string(COMPARE EQUAL "${file}" "optimized" is_optimized)
        string(COMPARE EQUAL "${file}" "coverage" is_coverage)

        if(in_directory)
            set(directory ${file})
            set(in_directory)
        elseif(in_debug)
                list(APPEND package_file_debug_contents "${directory},${file}" "\n")
            set(in_debug)
        elseif(in_optimized)
                list(APPEND package_file_release_contents "${directory},${file}" "\n")
            set(in_optimized)
        elseif(in_coverage)
                list(APPEND package_file_coverage_contents "${directory},${file}" "\n")
            set(in_coverage)
        elseif(is_directory)
            set(in_directory TRUE)
            set(in_optimized)
            set(in_debug)
            set(in_coverage)
        elseif(is_optimized)
            set(in_directory)
            set(in_optimized TRUE)
            set(in_debug)
            set(in_coverage)
        elseif(is_debug)
            set(in_directory)
            set(in_optimized)
            set(in_debug TRUE)
            set(in_coverage)
        elseif(is_coverage)
            set(in_directory)
            set(in_optimized)
            set(in_debug)
            set(in_coverage TRUE)
        else()
            list(APPEND package_file_debug_contents "${directory},${file}" "\n")
            list(APPEND package_file_release_contents "${directory},${file}" "\n")
            list(APPEND package_file_coverage_contents "${directory},${file}" "\n")
        endif()
    endforeach()
    if(package_file_debug_contents)
        file(WRITE ${package_file_debug} ${package_file_debug_contents})
    endif()
    if(package_file_release_contents)
        file(WRITE ${package_file_release} ${package_file_release_contents})
    endif()
    if(package_file_coverage_contents)
        file(WRITE ${package_file_coverage} ${package_file_coverage_contents})
    endif()

    set_property(GLOBAL PROPERTY RTT_PKG_${package_name}_DEBUG_CONTENTS ${package_file_debug_contents})
    set_property(GLOBAL PROPERTY RTT_PKG_${package_name}_RELEASE_CONTENTS ${package_file_release_contents})
    set_property(GLOBAL PROPERTY RTT_PKG_${package_name}_COVERAGE_CONTENTS ${package_file_coverage_contents})

    #message(STATUS "PACKAGE ${package_name} TARGET ${targetname} TARGETDIR ${targetdir}")
    #message(STATUS "PACKAGE ${package_name} FILES_DEBUG  : ${filelist_debug}")
    #message(STATUS "PACKAGE ${package_name} FILES_RELEASE: ${filelist_optimized}")

    # now we have a list of files to install for each target

    set(buildtype_outdir)
    if (MSVC)
        if(MSVC10 OR MSVC11)
            set(buildtype_outdir "${CMAKE_CFG_INTDIR}:Configuration" )
        else()
            set(buildtype_outdir "${CMAKE_CFG_INTDIR}:OutDir" )
        endif()
    else()
        set(buildtype_outdir "'${CMAKE_BUILD_TYPE}':OutDir" )
    endif()

    set(commands "${PYTHON_EXECUTABLE}" "${RTT_CMAKE_PYTHON_TOOLS_ROOT}/copy_runtime_files_from_file.py" ${targetdir} ${buildtype_outdir} ${package_file_debug} ${package_file_release} ${package_file_coverage})
    if (PO_AS_POSTBUILD)
        add_custom_command(TARGET ${PO_AS_POSTBUILD} POST_BUILD
            COMMAND ${commands}
            COMMENT "Creating package ${package_name}"
        )
    endif()

    if(PO_PACKAGE_EXECUTABLE)
        get_target_property(executable_location ${PO_PACKAGE_EXECUTABLE} LOCATION)
        get_filename_component(executable_dir "${executable_location}" PATH)
        if(WIN32)
            set(archive_extension ".zip")
            set(archive_script "zip_wrapper.py")
        else()
            set(archive_extension ".tar.gz")
            set(archive_script "tar_wrapper.py")
        endif()
        set(buildType "$<$<CONFIG:Debug>:debug>$<$<NOT:$<CONFIG:Debug>>:release>")
        set(archive_output_file "${PO_PACKAGE_EXECUTABLE}-${RTT_PLATFORM_NAME}-${buildType}${archive_extension}")
        set(md5_output_file "${PO_PACKAGE_EXECUTABLE}-${RTT_PLATFORM_NAME}-${buildType}.md5")
        set(output_file_list "${executable_dir}/${archive_output_file}" "${executable_dir}/${md5_output_file}")

        add_custom_command(OUTPUT ${package_name}.out
            # copy files
            COMMAND ${commands}
            # zip them
            COMMAND "${PYTHON_EXECUTABLE}" "${RTT_CMAKE_PYTHON_TOOLS_ROOT}/${archive_script}" "\"${archive_output_file}\"" "${CMAKE_BINARY_DIR}/PKG_EXEC_${PO_PACKAGE_EXECUTABLE}/${CMAKE_CFG_INTDIR}"
            # calculate md5
            COMMAND ${CMAKE_COMMAND} -E md5sum ${archive_output_file} > ${md5_output_file}
            COMMAND ${CMAKE_COMMAND} -E touch ${CMAKE_CURRENT_BINARY_DIR}/${package_name}.out
            WORKING_DIRECTORY ${executable_dir}
            DEPENDS ${PO_PACKAGE_EXECUTABLE})
        add_custom_target(${targetname} DEPENDS ${package_name}.out)

        # save list of output files to global property
        set_property(GLOBAL PROPERTY ${targetname} ${output_file_list})
    else()
        add_custom_target(${targetname}
            COMMAND ${commands}
            COMMENT "Creating package ${package_name}"
        )
    endif()

    # add a dependency to all targets
    set(targets)
    get_property(targets GLOBAL PROPERTY PKG_${package_name}_TARGETS)

    if (targets)
        add_dependencies(${targetname} ${targets})
    endif()

    # check if the package defines a NSIS installer
    set(nsis)
    get_property(nsis GLOBAL PROPERTY PKG_${package_name}_NSIS)

    if (nsis)
        RTT_NSIS_CREATE(${targetname}_NSIS ${nsis} ${targetdir})
        if (MSVC)
            add_dependencies(${targetname}_NSIS ${targetname})
        endif ()
    endif()

    # check whether the package defines an RPM installer
    set(rpm)
    get_property(rpm GLOBAL PROPERTY PKG_${package_name}_RPM)

    if (rpm)
        set(rpm_version)
        set(rpm_pversion)
        set(rpm_optdir)

        get_property(rpm_version GLOBAL PROPERTY PKG_${package_name}_RPM_version)
        get_property(rpm_pversion GLOBAL PROPERTY PKG_${package_name}_RPM_pversion)
        get_property(rpm_optdir GLOBAL PROPERTY PKG_${package_name}_RPM_optdir)

        RTT_RPM_CREATE(${targetname}_RPM ${targetdir} ${rpm_version} ${rpm_pversion} ${rpm_optdir})

        if (NOT MSVC)
            add_dependencies(${targetname}_RPM ${targetname})
        endif()
    endif()

    # now remove the package from the list of packages to create
    set (packages)
    get_property(packages GLOBAL PROPERTY PKG_ALL_REGISTERED_PACKAGES)
    list(REMOVE_ITEM packages ${package_name})
    set_property(GLOBAL PROPERTY PKG_ALL_REGISTERED_PACKAGES ${packages})
endfunction()

#
# Finalize a created package by turning it into an artifact
#

function(RTT_PKG_FINALIZE_TO_ARTIFACT package_name package_version)
    parse_arguments(ARG "" "NO_PUBLIC_HEADERS" ${ARGN})
    set(package_exists)
    get_property(package_exists GLOBAL PROPERTY PKG_${package_name})

    if(NOT package_exists)
        message(FATAL" finializing package ${package_name} but package does not exist - call PKG_CREATE first")
    endif()

    set(package_options)
    get_property(package_options GLOBAL PROPERTY PKG_${package_name}_OPTIONS)

    if(package_options)
        parse_arguments(PO "AS_POSTBUILD" "" ${package_options})
    endif()

    message(STATUS "PACKAGING ARTIFACT: finalizing ${package_name}")

    ## get global package settings
    unset(targetdir)
    unset(targetname)
    get_property(targetdir GLOBAL PROPERTY PKG_${package_name}_TARGETDIR)
    get_property(targetname GLOBAL PROPERTY PKG_${package_name}_TARGETNAME)

    ## analyze added targets and convert them into a filelist
    if(ARG_NO_PUBLIC_HEADERS)
        RTT_PKG_ANALYZE_TARGETS(${package_name} TO_ARTIFACT NO_PUBLIC_HEADERS)
    else()
        RTT_PKG_ANALYZE_TARGETS(${package_name} TO_ARTIFACT)
    endif()

    ## get list of files
    set(files)
    get_property(files GLOBAL PROPERTY PKG_${package_name}_FILES)
    set(PKG_${package_name}_FILES ${files} CACHE INTERNAL "files belonging to this package")

    if(NOT files)
        message(FATAL " no files to install for package ${package_name}")
    endif()

    set(is_directory)
    set(is_debug)
    set(is_optimized)
    set(in_debug FALSE)
    set(in_optimized FALSE)
    set(in_directory FALSE)
    set(is_coverage)
    set(in_coverage FALSE)

    set(directory)

    set(target_package_dir)
    string(REPLACE $(OutDir) "" target_package_dir ${targetdir})

    set(artifact_file "${PROJECT_BINARY_DIR}/.artifact_${package_name}.pkg")

    unset(artifact_file_contents)
    foreach(file ${files})
        string(COMPARE EQUAL "${file}" "DIRECTORY" is_directory)
        string(COMPARE EQUAL "${file}" "debug" is_debug)
        string(COMPARE EQUAL "${file}" "optimized" is_optimized)
        string(COMPARE EQUAL "${file}" "optimized_with_symbols" is_optimized_with_symbols)
        string(COMPARE EQUAL "${file}" "coverage" is_coverage)

        if(in_directory)
            set(directory ${file})
            set(in_directory)
        elseif(in_debug)
            list(APPEND artifact_file_contents "${directory}/Debug,${file}" "\n")
            set(in_debug)
        elseif(in_optimized)
            list(APPEND artifact_file_contents "${directory}/Release,${file}" "\n")
            set(in_optimized)
        elseif(in_optimized_with_symbols)
            if(MSVC)
                list(APPEND artifact_file_contents "${directory}/RelWithDebInfo,${file}" "\n")
            endif(MSVC)
            set(in_optimized_with_symbols)
        elseif(in_coverage)
            list(APPEND artifact_file_contents "${directory}/Coverage,${file}" "\n")
            set(in_coverage)
        elseif(is_directory)
            set(in_directory TRUE)
            set(in_optimized)
            set(in_debug)
            set(in_optimized_with_symbols)
            set(in_coverage)
        elseif(is_optimized)
            set(in_directory)
            set(in_optimized TRUE)
            set(in_debug)
            set(in_optimized_with_symbols)
            set(in_coverage)
        elseif(is_optimized_with_symbols)
            set(in_directory)
            set(in_optimized_with_symbols TRUE)
            set(in_debug)
            set(in_optimized)
            set(in_coverage)
        elseif(is_debug)
            set(in_directory)
            set(in_debug TRUE)
            set(in_optimized)
            set(in_optimized_with_symbols)
            set(in_coverage)
        elseif(is_coverage)
            set(in_directory)
            set(in_debug)
            set(in_optimized)
            set(in_optimized_with_symbols)
            set(in_coverage TRUE)
        else()
			list(APPEND artifact_file_contents "${directory},${file}" "\n")
        endif()
    endforeach()
    if(artifact_file_contents)
        file(WRITE ${artifact_file} ${artifact_file_contents})
    endif()

#   message(STATUS "PACKAGE ${package_name} TARGET ${targetname} TARGETDIR ${targetdir}")
#   message(STATUS "PACKAGE ${package_name} FILES_DEBUG  : ${filelist_debug}")
#   message(STATUS "PACKAGE ${package_name} FILES_RELEASE: ${filelist_optimized}")

    set(buildtype_outdir)
    if(MSVC10 OR MSVC11)
        set(buildtype_outdir "debug:Configuration" )
    else()
        set(buildtype_outdir "debug:OutDir" )
    endif()

    set(fetch_command COMMAND "${PYTHON_EXECUTABLE}" "${RTT_CMAKE_PYTHON_TOOLS_ROOT}/copy_runtime_files_from_file.py" ${targetdir} ${buildtype_outdir} ${artifact_file} "dummy")
    file(TO_NATIVE_PATH ${targetdir} native_targetdir)
    set(zip_command COMMAND "${PYTHON_EXECUTABLE}" "${RTT_CMAKE_PYTHON_TOOLS_ROOT}/zip_wrapper.py" "${CMAKE_BINARY_DIR}/${package_name}-${RTT_PLATFORM_NAME}-${RTT_COMPILER_NAME}-${package_version}.zip" ${native_targetdir})

    add_custom_target(${targetname}
                      ${fetch_command}
                      ${zip_command}
                      COMMENT "Creating artifact ${package_name}"
                     )

    # now remove the package from the list of packages to create
    set (packages)
    get_property(packages GLOBAL PROPERTY PKG_ALL_REGISTERED_PACKAGES)
    list(REMOVE_ITEM packages ${package_name})
    set_property(GLOBAL PROPERTY PKG_ALL_REGISTERED_PACKAGES ${packages})
endfunction()

#
#
#

function(RTT_PKG_FINALIZE_ALL)

    set (packages)
    get_property(packages GLOBAL PROPERTY PKG_ALL_REGISTERED_PACKAGES)

    if (NOT packages)
        message(STATUS "PACKAGING: no packages to create")
        return()
    endif()

    foreach (package ${packages})
        RTT_PKG_FINALIZE(${package})
    endforeach()

endfunction()

#
# mark a target to become an NSIS installer with the given nsis
# configuration file
#
# RTT_PKG_NSIS(package_name nsis_file)
#

function(RTT_PKG_NSIS package_name nsis_file)
    set(package_exists)
    get_property(package_exists GLOBAL PROPERTY PKG_${package_name})

    if (package_exists)
        set_property(GLOBAL APPEND PROPERTY PKG_${package_name}_NSIS "${nsis_file}")
    else()
        message(FATAL " cannot create NSIS installer for a package (${package_name}) which has not been created yet - call RTT_PKG_CREATE() first")
    endif()
endfunction()

#
# Mark a target to become an RPM package
#
# RTT_PKG_RPM(package_name rpm_version package_version opt_dir)
#

function(RTT_PKG_RPM package_name rpm_version package_version opt_dir)
    set(package_exists)
    get_property(package_exists GLOBAL PROPERTY PKG_${package_name})

    if (package_exists)
        set_property(GLOBAL APPEND PROPERTY PKG_${package_name}_RPM "YES")
        set_property(GLOBAL APPEND PROPERTY PKG_${package_name}_RPM_version ${rpm_version})
        set_property(GLOBAL APPEND PROPERTY PKG_${package_name}_RPM_pversion ${package_version})
        set_property(GLOBAL APPEND PROPERTY PKG_${package_name}_RPM_optdir ${opt_dir})
    else()
        message(FATAL " cannot create RPM installer for a package (${package_name}) which has not been created yet - call RTT_PKG_CREATE() first")
    endif()
endfunction()


function(RTT_PKG_Executable target_name)
    parse_arguments(ARG "ADDITIONAL_FILES" "" ${ARGN})

    if (NOT TARGET ${target_name})
        message(FATAL_ERROR "Cannot package executable " ${target_name} " - not a target.")
    endif()
    if (NOT TARGET PKG_EXEC_BUILD_ALL)
        add_custom_target(PKG_EXEC_BUILD_ALL)
    endif()
    RTT_PKG_CREATE(EXEC_${target_name} ${CMAKE_BINARY_DIR}/PKG_EXEC_${target_name}
        BINDIR ${CMAKE_CFG_INTDIR}
        LIBDIR ${CMAKE_CFG_INTDIR}
        PACKAGE_EXECUTABLE ${target_name}
    )
    RTT_PKG_REGISTER_TARGET(EXEC_${target_name} ${target_name})
    foreach(file ${ARG_ADDITIONAL_FILES})
      RTT_PKG_REGISTER_FILES(EXEC_${target_name} ${CMAKE_CFG_INTDIR}
          ${file}
      )
    endforeach()
    RTT_PKG_FINALIZE(EXEC_${target_name})

    add_dependencies(PKG_EXEC_BUILD_ALL PKG_EXEC_${target_name})
endfunction()
