#
# this defines some methods to handle antlr files
#
# TODO: where to find MOC

# load some include files to have antlr available

if (NOT ANTLR_JAR)
	__RTT_ARTIFACTORY_GET(antlr)
endif()

if (NOT ANTLR_JAR)
	message(FATAL_ERROR "Failed to load and initialize ANTLR")
endif()

MACRO ( RTT_ANTLRPARSERLEXER outfiles )
	FOREACH (it ${ARGN})
		GET_FILENAME_COMPONENT(filename ${it} NAME_WE)

		GET_FILENAME_COMPONENT(infile ${it} ABSOLUTE)
		GET_FILENAME_COMPONENT(directory ${it} PATH)

		SET(parser_outfile_cpp ${CMAKE_CURRENT_BINARY_DIR}/${filename}Parser.cpp)
		SET(parser_outfile_hpp ${CMAKE_CURRENT_BINARY_DIR}/${filename}Parser.hpp)
		SET(lexer_outfile_cpp ${CMAKE_CURRENT_BINARY_DIR}/${filename}Lexer.cpp)
		SET(lexer_outfile_hpp ${CMAKE_CURRENT_BINARY_DIR}/${filename}Lexer.hpp)


		ADD_CUSTOM_COMMAND(OUTPUT  ${parser_outfile_cpp} ${parser_outfile_hpp} ${lexer_outfile_cpp} ${lexer_outfile_hpp}
			COMMAND java
			ARGS -jar "${ANTLR_JAR}" -lib "${directory}" -fo "${CMAKE_CURRENT_BINARY_DIR}" -message-format vs2005 -Xm 4 -Xmaxdfaedges 65534 -Xconversiontimeout 1000 "${infile}"
			MAIN_DEPENDENCY ${infile} VERBATIM
		)
		SET(${outfiles} ${${outfiles}} ${parser_outfile_cpp} ${parser_outfile_hpp} ${lexer_outfile_cpp} ${lexer_outfile_hpp} )
		
		SET_SOURCE_FILES_PROPERTIES(${parser_outfile_cpp} PROPERTIES GENERATED TRUE)
		SET_SOURCE_FILES_PROPERTIES(${parser_outfile_hpp} PROPERTIES GENERATED TRUE)
		SET_SOURCE_FILES_PROPERTIES(${lexer_outfile_cpp} PROPERTIES GENERATED TRUE)
		SET_SOURCE_FILES_PROPERTIES(${lexer_outfile_hpp} PROPERTIES GENERATED TRUE)
	ENDFOREACH (it)
ENDMACRO (RTT_ANTLRPARSERLEXER)