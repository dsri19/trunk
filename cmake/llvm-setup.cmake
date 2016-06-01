# LLVM setup
#
# Input: LLVM_REQUIRED_VERSION (string)

if(NOT LLVM_REQUIRED_VERSION)
    message(FATAL " Please set LLVM_REQUIRED_VERSION")
endif()

file(TO_CMAKE_PATH "$ENV{THIRD_PARTY_ROOT}/llvm-${LLVM_REQUIRED_VERSION}" LLVM_ROOT)

if("${LLVM_REQUIRED_VERSION}" VERSION_LESS "3.1")
    list(APPEND CMAKE_MODULE_PATH "${LLVM_ROOT}/cmake")
    include(LLVM)

    if(MSVC)
        set(LLVM_LIBRARY_BASE "${LLVM_ROOT}/lib/${MSVC_COMPILER_NAME}/${MSVC_PLATFORM_NAME}_static")
    else()
        set(LLVM_LIBRARY_BASE "${LLVM_ROOT}/lib/gcc441/${LINUX_PLATFORM_NAME}_static")
    endif()

    set(LLVM_INCLUDE_DIR "${LLVM_ROOT}/include" CACHE STRING "LLVM include directory" )
else()
    if(MSVC)
        set(COMPILER_NAME "${MSVC_COMPILER_NAME}")
        set(PLATFORM_NAME "${MSVC_PLATFORM_NAME}")
    else()
        set(COMPILER_NAME "gcc445")
        set(PLATFORM_NAME "${LINUX_PLATFORM_NAME}")
    endif()

    list(APPEND CMAKE_MODULE_PATH "${LLVM_ROOT}/cmake/${COMPILER_NAME}/${PLATFORM_NAME}_static")
    include(LLVMConfig OPTIONAL RESULT_VARIABLE LLVMCONFIG_INCLUDED)

    set(LLVM_LIBRARY_BASE "${LLVM_ROOT}/lib/${COMPILER_NAME}/${PLATFORM_NAME}_static")
    set(LLVM_INCLUDE_DIR "${LLVM_ROOT}/include/${COMPILER_NAME}/${PLATFORM_NAME}_static" CACHE STRING "LLVM include directory" )
endif()

mark_as_advanced(LLVM_INCLUDE_DIR)

function(find_llvm_library LIBNAME COMPONENTS)
    llvm_map_components_to_libraries(LIBRARIES ${COMPONENTS})

    foreach(LIB ${LIBRARIES})
        find_library(${LIB}_DEBUG ${LIB} PATHS "${LLVM_LIBRARY_BASE}/Debug" NO_CMAKE_SYSTEM_PATH)
        find_library(${LIB}_RELEASE ${LIB} PATHS "${LLVM_LIBRARY_BASE}/Release" NO_CMAKE_SYSTEM_PATH)

        set(MSG "LLVM: Adding ${LIB}")
        if(${${LIB}_DEBUG} STREQUAL "${LIB}_DEBUG-NOTFOUND")
            set(MSG "${MSG} - DEBUG not found")
        else()
            list(APPEND LLVM_LIBRARY_DEBUG debug ${${LIB}_DEBUG})
        endif()

        if(${${LIB}_RELEASE} STREQUAL "${LIB}_RELEASE-NOTFOUND")
            set(MSG "${MSG} - RELEASE not found")
        else()
            list(APPEND LLVM_LIBRARY_RELEASE optimized ${${LIB}_RELEASE})
        endif()
        message(STATUS "${MSG}")
    endforeach()

    if(NOT WIN32)
        # On Linux, we need to explicitly add libdl to allow for dynamic linking.
        list(APPEND LLVM_LIBRARY_DEBUG debug dl)
        list(APPEND LLVM_LIBRARY_RELEASE optimized dl)
    endif(NOT WIN32)

    # check if we found the library
    if(NOT LLVM_LIBRARY_DEBUG OR NOT LLVM_LIBRARY_RELEASE)
        message(FATAL " no appropriate LLVM library found in ${LLVM_LIBRARY_BASE}")
    endif()

    # prepare the settings
    string(TOUPPER ${LIBNAME} LIBNAME_UPPER)
    set(LLVM_${LIBNAME_UPPER}_LIBRARY ${LLVM_LIBRARY_DEBUG} ${LLVM_LIBRARY_RELEASE} CACHE STRING "LLVM ${LIBNAME} library" )
    mark_as_advanced(LLVM_${LIBNAME_UPPER}_LIBRARY)
endfunction(find_llvm_library)

