if (NOT CUDA_ROOT)
    message(STATUS "Getting CUDA")
    __RTT_ARTIFACTORY_GET(cuda)
    message(STATUS "DONE")
else()
    message(STATUS "CUDA = ${CUDA_ROOT}")
endif()

if (NOT CUDA_ROOT)
    message(FATAL_ERROR "Failed to load and initialize CUDA properly - CUDA_ROOT missing")
endif()

function (compile_cuda src_dir name arch bits registers dependencies)
    #message( STATUS "${name}_sm${arch}.h" )

    string( COMPARE LESS ${arch} 20 IS_SM1X )

    if( IS_SM1X )
        if(MSVC)
            set( nvcc_params -Xopencc -woffall -Xopencc -OPT:reuse_regs=true -m${bits} -maxrregcount=${registers} -arch sm_${arch} -I ${CUDA_INCLUDE_DIR} -I ${CMAKE_CURRENT_SOURCE_DIR} -I ${CMAKE_CURRENT_SOURCE_DIR}/cuda/rendering -cubin -Xopencc -OPT:Olimit=0 )
        else()
            set( nvcc_params "--ptxas-options=-v -maxrregcount=${registers} --opencc-options -woffall,-OPT:reuse_regs=true,-OPT:Olimit=0 -m${bits} -arch sm_${arch} -I ${CUDA_INCLUDE_DIR} -I ${CMAKE_CURRENT_SOURCE_DIR} -I ${CMAKE_CURRENT_SOURCE_DIR}/cuda/rendering -cubin" )
            separate_arguments(nvcc_params)
        endif()
    else()
        if(MSVC)
            set( nvcc_params -m${bits} -maxrregcount=${registers} -arch sm_${arch} -I ${CUDA_INCLUDE_DIR} -I ${CMAKE_CURRENT_SOURCE_DIR} -I ${CMAKE_CURRENT_SOURCE_DIR}/cuda/rendering -cubin )
        else()
            set( nvcc_params "--ptxas-options=-v -maxrregcount=${registers} -m${bits} -arch sm_${arch} -I ${CUDA_INCLUDE_DIR} -I ${CMAKE_CURRENT_SOURCE_DIR} -I ${CMAKE_CURRENT_SOURCE_DIR}/cuda/rendering -cubin" )
            separate_arguments(nvcc_params)
        endif()
    endif()
    string( COMPARE EQUAL ${arch} 10 IS_SM10 )
    if ( IS_SM10 )
        set( nvcc_params ${nvcc_params} -D SM11_compatibility )
    endif()
    #message( STATUS "${nvcc_params}" )

    # so we got a weird situation with this tool. We build it from
    # within "utils" but in order for this CMake time function to work it
    # must already be defined. Which requires me to enforce an error if it's not.
    # This is not exactly nice but the only way I can think of right now.
    # If you read this it probably means you have changed the order in which
    # utils and lib targets are initialized. So please consider to move this
    # executable to 3rd_party or someplace instead. Even better would be to
    # replace bin2h by a python script
    if(TARGET bin2h)
        get_target_property(bin2hexe bin2h LOCATION)
    else()
        message( FATAL_ERROR "bin2h not yet defined" )
    endif()

    set( cu_in_name "${CMAKE_CURRENT_SOURCE_DIR}/${src_dir}/${name}.cu" )
    set( cubin_out_name "${CMAKE_CURRENT_BINARY_DIR}/${name}_sm${arch}.cubin" )
    set( header_out_name "${CMAKE_CURRENT_BINARY_DIR}/${name}_sm${arch}.h" )
    add_custom_command(
        OUTPUT ${header_out_name}
        COMMAND ${CMAKE_COMMAND} -E echo "invoking nvcc: ${NVCC}  ${nvcc_params} ${cu_in_name} -o ${cubin_out_name}"
        COMMAND ${NVCC} ${nvcc_params} ${cu_in_name} -o ${cubin_out_name}
        COMMAND ${CMAKE_COMMAND} -E echo "invoking bin2h: ${bin2hexe} ${cubin_out_name} ${header_out_name} ${name}_sm${arch}"
        COMMAND ${bin2hexe} ${cubin_out_name} ${header_out_name} ${name}_sm${arch}
        DEPENDS bin2h ${dependencies}
        VERBATIM
    )
    return( ${header_out_name} )
endfunction(compile_cuda)

function( build_with_nvcc NVCC_PARAMS SOURCE_FILE OUTPUT_FILE )
    get_filename_component( OUTPUT_DIR ${OUTPUT_FILE} PATH )

    if(WIN32)
        set(CMD_PREFIX "")
    else()
        set(CMD_PREFIX "true")
    endif()

    add_custom_command(
        OUTPUT ${OUTPUT_FILE}

        COMMAND ${CMD_PREFIX} $<$<CONFIG:Coverage>:set>$<$<NOT:$<CONFIG:Coverage>>:rem> $<$<CONFIG:Coverage>:PATH=$(VSInstallDir)/VC/bin/x86_amd64>$<$<NOT:$<CONFIG:Coverage>>:build_with_nvcc>
        COMMAND ${CMAKE_COMMAND} -E make_directory ${OUTPUT_DIR}
        COMMAND ${CMAKE_COMMAND} -E echo "${NVCC} ${NVCC_PARAMS} ${SOURCE_FILE} -o ${OUTPUT_FILE}"
        COMMAND ${NVCC} ${NVCC_PARAMS} ${SOURCE_FILE} -o ${OUTPUT_FILE}
        DEPENDS ${SOURCE_FILE} ${ARGN}
        MAIN_DEPENDENCY ${SOURCE_FILE} ${ARGN}
        VERBATIM
    )
endfunction()
