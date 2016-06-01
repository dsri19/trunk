# CMAKE

cmake_minimum_required(VERSION 2.8.12)
cmake_policy(VERSION 2.8)
cmake_policy(SET CMP0000 OLD)  # "A minimum required CMake version must be specified."
cmake_policy(SET CMP0005 NEW)  # "Preprocessor definition values are now escaped automatically."
cmake_policy(SET CMP0010 NEW)  # "Bad variable reference syntax is an error."
if(${CMAKE_MAJOR_VERSION} GREATER 2)
    cmake_policy(SET CMP0026 OLD)  # "Disallow use of the LOCATION target property."
    if(${CMAKE_MINOR_VERSION} GREATER 0)
        cmake_policy(SET CMP0054 NEW)  # "Only interpret if() arguments as variables or keywords when unquoted."
    endif()
endif()

# PLATFORMS

if(MSVC)
    add_definitions(-DWIN32_LEAN_AND_MEAN)
    add_definitions(-D_WIN32_WINNT=0x601)  # Windows 7+

    # on windows we want to build to bin/x64/Release ...
    set(LIBRARY_OUTPUT_PATH ${PROJECT_BINARY_DIR}/bin/x64 CACHE PATH "Library target dir (x64).")
    set(EXECUTABLE_OUTPUT_PATH ${PROJECT_BINARY_DIR}/bin/x64 CACHE PATH "Executable target dir (x64).")
else()
    # on linux we want to have all the binaries in one place
    set(EXECUTABLE_OUTPUT_PATH ${PROJECT_BINARY_DIR}/bin CACHE PATH "Binary target dir.")
    set(LIBRARY_OUTPUT_PATH ${PROJECT_BINARY_DIR}/lib CACHE PATH "Library target dir (x64).")
endif()

# PACKAGES

set(BOOST_DO_NOT_DEFINE_ALL_DYN ON)  # we use static boost libs by default
set(PYTHON_REQUIRED_VERSION 2.7)  # no joy with 2.6 esp. when it comes to unittest module
