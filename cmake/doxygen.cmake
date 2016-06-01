#
# this handles API docs generation
#

include(FindDoxygen)

# the first one is the full monty, all docs
CONFIGURE_FILE(${CMAKE_SOURCE_DIR}/../doc/Doxyfile.in
	${CMAKE_BINARY_DIR}/api-docs/Doxyfile)

ADD_CUSTOM_TARGET(api-docs COMMAND ${DOXYGEN_EXECUTABLE}
	${CMAKE_BINARY_DIR}/api-docs/Doxyfile COMMENT "Generating
	documentation")

	# this is merely SDK docs. So only the stuff an external party would
	# need
	CONFIGURE_FILE(${CMAKE_SOURCE_DIR}/../doc/Doxyfile_public.in
		${CMAKE_BINARY_DIR}/sdk-docs/Doxyfile)
	ADD_CUSTOM_TARGET(sdk-docs ${DOXYGEN_EXECUTABLE}
		${CMAKE_BINARY_DIR}/sdk-docs/Doxyfile COMMENT "Generating SDK documentation")


